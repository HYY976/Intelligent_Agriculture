/**
 * history_list - 浏览历史页
 * 遵循 spec 3.1.3.5：浏览过的商品列表
 *
 * spec 10.11.4 Step 2：ForEach → LazyForEach + keyGenerator + cachedCount
 */

import { AppConstants, UserRoutes, RouteName, NavigationHelper, ListStateView } from 'common';
import { HistoryItem } from '../../model/ProfileModels';
import { HistoryListDataSource } from '../../viewmodel/HistoryListDataSource';
import { ImageUtil } from '../../utils/ImageUtil';

/** 跳转商品详情的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface ProductDetailParam {
  productId: string;
}

@ComponentV2
export struct HistoryList {
  /** 浏览历史数据源（spec 10.11.4：LazyForEach 替代 ForEach） */
  private dataSource: HistoryListDataSource = new HistoryListDataSource();
  /** 列表是否为空 */
  @Local isEmpty: boolean = true;

  async aboutToAppear(): Promise<void> {
    await this.refresh();
  }

  /** 刷新列表（spec 10.13：4 态状态机） */
  private async refresh(): Promise<void> {
    await this.dataSource.refresh();
    this.isEmpty = this.dataSource.totalCount() === 0;
  }

  private gotoProductDetail(productId: string): void {
    const param: ProductDetailParam = { productId: productId };
    NavigationHelper.push(RouteName.USER_PRODUCT_DETAIL, param);
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Text('‹').fontSize(28).fontColor($r('app.color.color_text_primary')).onClick(() => { NavigationHelper.pop(); })
          Text('浏览历史').fontSize(18).fontColor($r('app.color.color_text_primary')).fontWeight(FontWeight.Medium).layoutWeight(1).textAlign(TextAlign.Center)
          Text('').width(28)
        }
        .width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor($r('app.color.color_bg_card')).alignItems(VerticalAlign.Center)

        // 浏览历史列表（spec 10.11.4 Step 4：4 态状态机 error / loading / empty / list）
        if (this.dataSource.getLoadFailed()) {
          ListStateView({ state: 'error', onRefresh: () => this.refresh() })
        } else if (this.dataSource.getIsFirstLoad()) {
          ListStateView({ state: 'loading' })
        } else if (this.dataSource.totalCount() === 0) {
          ListStateView({ state: 'empty', emptyText: '暂无浏览记录', emptyDesc: '逛逛农产品吧' })
        } else {
          // 双列瀑布流
          WaterFlow() {
            LazyForEach(this.dataSource, (item: HistoryItem, _i: number) => {
              FlowItem() {
                Column() {
                  Image(ImageUtil.get(item.image)).width('100%').aspectRatio(1).borderRadius({ topLeft: 12, topRight: 12 }).objectFit(ImageFit.Cover)
                  Column({ space: 4 }) {
                    Text(item.title).fontSize(12).fontColor($r('app.color.color_text_primary')).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(`🏪 ${item.farmerName}`).fontSize(10).fontColor($r('app.color.color_text_secondary')).maxLines(1)
                    Row() {
                      Text(`¥${item.price.toFixed(2)}`).fontSize(14).fontColor($r('app.color.color_price')).fontWeight(FontWeight.Bold)
                      Blank()
                      Text(this.formatTime(item.viewedAt)).fontSize(9).fontColor($r('app.color.color_text_hint'))
                    }.width('100%')
                  }.width('100%').padding(8).alignItems(HorizontalAlign.Start)
                }.width('100%').backgroundColor($r('app.color.color_bg_card')).borderRadius(12).clip(true)
                .onClick(() => { this.gotoProductDetail(item.productId); })
              }.margin({ bottom: 8 })
            }, (item: HistoryItem) => item.historyId + `_${item.viewedAt}`)
          }
          .columnsTemplate('1fr 1fr').columnsGap(8).rowsGap(8).padding({ left: 12, right: 12, top: 12 })
          .layoutWeight(1).width('100%')
          .cachedCount(AppConstants.LIST_CACHED_COUNT)
        }
      }
      .width('100%').height('100%').backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  private formatTime(ts: number): string {
    const d: Date = new Date(ts);
    const now: Date = new Date();
    const diff: number = now.getTime() - ts;
    if (diff < 3600000) { return `${Math.floor(diff / 60000)}分钟前`; }
    if (diff < 86400000) { return `${Math.floor(diff / 3600000)}小时前`; }
    return `${d.getMonth() + 1}-${d.getDate()}`;
  }

}
