/**
 * history_list - 浏览历史页
 * 遵循 spec 3.1.3.5 + 设计稿 history.html 1:1 复刻：
 *  - 顶栏：白色圆形返回按钮 + 居中标题"浏览历史" + 右侧"清空"文字按钮
 *  - 日期分组（今天 / 昨天 / MM-DD）：组标题(13px Bold text_3) + 商品行卡(10px 间距)
 *  - 商品行卡：商品图(64×64, radius 14) + 信息(标题+卖家+价格+时间) + 删除图标(26×26)
 *  - 底部"清空历史"全宽按钮（线框样式 + 垃圾桶图标）
 *
 * spec 10.11.4 Step 2：ForEach → LazyForEach + keyGenerator + cachedCount
 */

import { AppConstants, RouteName, NavigationHelper, ListStateView, ToastUtil, Logger } from 'common';
import { HistoryItem } from '../../model/ProfileModels';
import { HistoryListDataSource } from '../../viewmodel/HistoryListDataSource';
import { removeMockHistory, clearMockHistories } from '../../mock/ProfileMock';
import { ImageUtil } from '../../utils/ImageUtil';

/** 跳转商品详情的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface ProductDetailParam {
  productId: string;
}

/** 日期分组 */
interface HistoryGroup {
  /** 分组标题（今天 / 昨天 / MM-DD） */
  title: string;
  /** 该组下的历史项 */
  items: HistoryItem[];
}

@ComponentV2
export struct HistoryList {
  /** 浏览历史数据源（spec 10.11.4：LazyForEach 替代 ForEach） */
  private dataSource: HistoryListDataSource = new HistoryListDataSource();
  /** 列表是否为空 */
  @Local isEmpty: boolean = true;
  /** 日期分组后的数据（驱动 ForEach 渲染） */
  @Local groups: HistoryGroup[] = [];

  async aboutToAppear(): Promise<void> {
    await this.refresh();
  }

  /** 刷新列表（spec 10.13：4 态状态机） */
  private async refresh(): Promise<void> {
    await this.dataSource.refresh();
    this.isEmpty = this.dataSource.totalCount() === 0;
    this.groups = this.groupByDate(this.getAllItems());
  }

  /** 从数据源获取全部数据（基类 totalCount + getData 实现） */
  private getAllItems(): HistoryItem[] {
    const items: HistoryItem[] = [];
    const count: number = this.dataSource.totalCount();
    for (let i = 0; i < count; i++) {
      items.push(this.dataSource.getData(i));
    }
    return items;
  }

  /** 按日期分组（对齐设计稿 今天 / 昨天 / MM-DD） */
  private groupByDate(items: HistoryItem[]): HistoryGroup[] {
    const result: HistoryGroup[] = [];
    const todayStart: number = this.getStartOfToday();
    const yesterdayStart: number = todayStart - 24 * 3600 * 1000;

    const todayItems: HistoryItem[] = [];
    const yesterdayItems: HistoryItem[] = [];
    const olderMap: Map<string, HistoryItem[]> = new Map<string, HistoryItem[]>();
    const olderOrder: string[] = [];

    items.forEach((item: HistoryItem) => {
      if (item.viewedAt >= todayStart) {
        todayItems.push(item);
      } else if (item.viewedAt >= yesterdayStart) {
        yesterdayItems.push(item);
      } else {
        const d: Date = new Date(item.viewedAt);
        const key: string = `${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
        if (!olderMap.has(key)) {
          olderMap.set(key, []);
          olderOrder.push(key);
        }
        olderMap.get(key)!.push(item);
      }
    });

    // 按时间倒序排列每组内的项目
    todayItems.sort((a: HistoryItem, b: HistoryItem) => b.viewedAt - a.viewedAt);
    yesterdayItems.sort((a: HistoryItem, b: HistoryItem) => b.viewedAt - a.viewedAt);

    if (todayItems.length > 0) {
      result.push({ title: '今天', items: todayItems });
    }
    if (yesterdayItems.length > 0) {
      result.push({ title: '昨天', items: yesterdayItems });
    }
    olderOrder.forEach((key: string) => {
      const olderItems: HistoryItem[] = olderMap.get(key)!.slice();
      olderItems.sort((a: HistoryItem, b: HistoryItem) => b.viewedAt - a.viewedAt);
      result.push({ title: key, items: olderItems });
    });

    return result;
  }

  /** 获取今天 0 点的时间戳 */
  private getStartOfToday(): number {
    const d: Date = new Date();
    d.setHours(0, 0, 0, 0);
    return d.getTime();
  }

  private gotoProductDetail(productId: string): void {
    const param: ProductDetailParam = { productId: productId };
    NavigationHelper.push(RouteName.USER_PRODUCT_DETAIL, param);
  }

  /** 删除单条历史 */
  private async onDelete(item: HistoryItem): Promise<void> {
    removeMockHistory(item.historyId);
    ToastUtil.success('已删除');
    await this.refresh();
    Logger.info(AppConstants.SCENE_USER, { action: 'history_delete', productId: item.productId });
  }

  /** 清空全部历史 */
  private async onClearAll(): Promise<void> {
    if (this.dataSource.totalCount() === 0) {
      ToastUtil.info('暂无历史记录');
      return;
    }
    clearMockHistories();
    ToastUtil.success('已清空历史记录');
    await this.refresh();
    Logger.info(AppConstants.SCENE_USER, { action: 'history_clear_all' });
  }

  build() {
    NavDestination() {
      Column() {
        // ===== 顶部导航栏（对齐设计稿 qn-topbar） =====
        Row() {
          // 白色圆形返回按钮
          Row() {
            Text('‹').fontSize(22).fontColor($r('app.color.color_ink')).fontWeight(FontWeight.Bold)
          }
          .width(32)
          .height(32)
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_bg_card'))
          .shadow(AppConstants.SHADOW_CARD)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .onClick(() => { NavigationHelper.pop(); })

          // 居中标题
          Text('浏览历史')
            .fontSize(17)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          // 右侧"清空"文字按钮（对齐设计稿 qn-hist-clear）
          Text('清空')
            .fontSize(13)
            .fontColor($r('app.color.color_text_3'))
            .fontWeight(FontWeight.Medium)
            .padding({ left: 8, right: 4, top: 6, bottom: 6 })
            .onClick(() => { this.onClearAll(); })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 4, bottom: 10 })
        .alignItems(VerticalAlign.Center)

        // ===== 浏览历史列表（spec 10.11.4 Step 4：4 态状态机 error / loading / empty / list） =====
        if (this.dataSource.getLoadFailed()) {
          ListStateView({ state: 'error', onRefresh: () => this.refresh() })
        } else if (this.dataSource.getIsFirstLoad()) {
          ListStateView({ state: 'loading' })
        } else if (this.dataSource.totalCount() === 0) {
          ListStateView({ state: 'empty', emptyText: '暂无浏览记录', emptyDesc: '逛逛农产品吧' })
        } else {
          Scroll() {
            Column({ space: 10 }) {
              // 日期分组列表
              ForEach(this.groups, (group: HistoryGroup, gi: number) => {
                Column({ space: 10 }) {
                  // 组标题（对齐设计稿 qn-hist-group-title）
                  Text(group.title)
                    .fontSize(13)
                    .fontColor($r('app.color.color_text_3'))
                    .fontWeight(FontWeight.Bold)
                    .margin({ left: 2, top: 4, bottom: 0 })

                  // 该组下的商品行卡
                  ForEach(group.items, (item: HistoryItem) => {
                    this.HistoryItemCard(item)
                  }, (item: HistoryItem) => `${group.title}_${item.historyId}`)
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
              }, (group: HistoryGroup, gi: number) => `${group.title}_${gi}`)

              // 底部"清空历史"按钮（对齐设计稿 qn-hist-clear2，全宽线框）
              Row({ space: 6 }) {
                Text('🗑️').fontSize(16)
                Text('清空历史')
                  .fontSize(15)
                  .fontColor($r('app.color.color_ink'))
                  .fontWeight(FontWeight.Bold)
              }
              .width('100%')
              .height(46)
              .borderRadius(AppConstants.RADIUS_MD)
              .backgroundColor($r('app.color.color_bg_card'))
              .border({ width: 1, color: $r('app.color.color_line_2') })
              .justifyContent(FlexAlign.Center)
              .alignItems(VerticalAlign.Center)
              .margin({ top: 6 })
              .onClick(() => { this.onClearAll(); })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 4, bottom: 24 })
          }
          .layoutWeight(1)
          .width('100%')
          .scrollBar(BarState.Off)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 商品行卡（对齐设计稿 qn-hist-item） */
  @Builder
  HistoryItemCard(item: HistoryItem) {
    Row({ space: 12 }) {
      // 商品图（64×64，radius 14，对齐设计稿 qn-hist-img）
      Image(ImageUtil.get(item.image))
        .width(64)
        .height(64)
        .borderRadius(AppConstants.RADIUS_MD)
        .objectFit(ImageFit.Cover)
        .backgroundColor($r('app.color.color_fill'))

      // 中间信息（对齐设计稿 qn-hist-info）
      Column({ space: 3 }) {
        // 标题（14px Medium，1 行，对齐设计稿 qn-hist-title）
        Text(item.title)
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 卖家（11px text_3，1 行，对齐设计稿 qn-hist-seller）
        Text(item.farmerName)
          .fontSize(11)
          .fontColor($r('app.color.color_text_3'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 底部行：价格 + 时间（对齐设计稿 qn-hist-bottom）
        Row() {
          // 价格（16px live red Bold，对齐设计稿 qn-hist-price）
          Row({ space: 1 }) {
            Text('¥')
              .fontSize(11)
              .fontColor($r('app.color.color_live'))
              .fontWeight(FontWeight.Bold)
              .baselineOffset(3)
            Text(item.price.toFixed(1))
              .fontSize(16)
              .fontColor($r('app.color.color_live'))
              .fontWeight(FontWeight.Bold)
          }
          .alignItems(VerticalAlign.Bottom)

          Blank()

          // 时间（11px text_3，对齐设计稿 qn-hist-time）
          Text(this.formatTime(item.viewedAt))
            .fontSize(11)
            .fontColor($r('app.color.color_text_3'))
        }
        .width('100%')
        .margin({ top: 4 })
        .alignItems(VerticalAlign.Bottom)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)

      // 行内小删除图标（对齐设计稿 qn-hist-del，26×26）
      Row() {
        Text('✕').fontSize(14).fontColor($r('app.color.color_text_4'))
      }
      .width(26)
      .height(26)
      .borderRadius(AppConstants.RADIUS_PILL)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { this.onDelete(item); })
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(VerticalAlign.Center)
    .onClick(() => { this.gotoProductDetail(item.productId); })
  }

  /** 格式化时间（HH:MM） */
  private formatTime(ts: number): string {
    const d: Date = new Date(ts);
    return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
  }
}
