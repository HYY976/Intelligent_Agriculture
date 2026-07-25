/**
 * coupon_list - 优惠券页
 * 遵循 spec 3.1.3.5 + 设计稿 coupon.html 1:1 复刻：
 *  - 顶栏：白色圆形返回按钮 + 居中标题"优惠券"
 *  - Tab 栏（3 项等分，44px 高，激活态 28×3 黄色下划线）：可使用 / 已使用 / 已过期
 *  - 优惠券卡（票券样式）：左侧色块（红/黄/绿/灰，金额+条件）+ 撕边缺口 + 虚线穿孔 + 右侧信息（标题+规则+日期+立即使用/已使用/已过期标签）
 *  - 已过期卡整体 opacity 0.5
 *
 * spec 10.11.4 Step 2：ForEach → LazyForEach + keyGenerator + cachedCount
 */

import { ToastUtil, NavigationHelper, AppConstants, ListStateView, Logger } from 'common';
import { Coupon, CouponStatus } from '../../model/ProfileModels';
import { CouponListDataSource } from '../../viewmodel/CouponListDataSource';

/** 优惠券 Tab 配置 */
interface CouponTab {
  status: CouponStatus;
  label: string;
}

/** 色块主题色 */
type StubTheme = 'red' | 'yellow' | 'green' | 'gray';

@ComponentV2
export struct CouponList {
  /** 当前 Tab 索引 */
  @Local currentTab: number = 0;
  /** 列表是否为空（驱动空状态切换） */
  @Local isEmpty: boolean = true;
  /** 优惠券数据源（spec 10.11.4：LazyForEach 替代 ForEach） */
  private dataSource: CouponListDataSource = new CouponListDataSource();
  /** Tab 配置（对齐设计稿 coupon.html: 可使用 / 已使用 / 已过期） */
  private tabs: CouponTab[] = [
    { status: 'unused', label: '可使用' },
    { status: 'used', label: '已使用' },
    { status: 'expired', label: '已过期' }
  ];

  async aboutToAppear(): Promise<void> {
    await this.refreshList();
  }

  /** 刷新列表（spec 10.11.4：异步 refresh + 空状态同步） */
  private async refreshList(): Promise<void> {
    this.dataSource.setStatus(this.tabs[this.currentTab].status);
    await this.dataSource.refresh();
    this.isEmpty = this.dataSource.totalCount() === 0;
  }

  /** 切换 Tab */
  private async onTabChange(index: number): Promise<void> {
    this.currentTab = index;
    await this.refreshList();
    Logger.info(AppConstants.SCENE_USER, { action: 'coupon_tab_switch', tab: this.tabs[index].status });
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
          Text('优惠券')
            .fontSize(17)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          // 右侧占位（保持标题居中）
          Row().width(32).height(32)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 4, bottom: 10 })
        .alignItems(VerticalAlign.Center)

        // ===== Tab 栏（对齐设计稿 qn-coupon-tabs，44px 高 + 底部 1px 分割线） =====
        Row() {
          ForEach(this.tabs, (tab: CouponTab, index: number) => {
            Stack({ alignContent: Alignment.Bottom }) {
              Text(tab.label)
                .fontSize(14)
                .fontColor(this.currentTab === index ? $r('app.color.color_ink') : $r('app.color.color_text_3'))
                .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Medium)
                .height(44)
                .textAlign(TextAlign.Center)

              // 激活态下划线（28×3 黄色，对齐设计稿 qn-coupon-tab.is-active::after）
              if (this.currentTab === index) {
                Column()
                  .width(28)
                  .height(3)
                  .borderRadius(AppConstants.RADIUS_PILL)
                  .backgroundColor($r('app.color.color_yellow'))
                  .margin({ bottom: 0 })
              }
            }
            .layoutWeight(1)
            .height(44)
            .onClick(() => { this.onTabChange(index); })
          }, (tab: CouponTab, i: number) => `${tab.status}_${i}`)
        }
        .width('100%')
        .backgroundColor($r('app.color.color_bg_card'))
        .border({ width: { bottom: 1 }, color: $r('app.color.color_line') })

        // ===== 优惠券列表（spec 10.11.4 Step 4：4 态状态机 error / loading / empty / list） =====
        if (this.dataSource.getLoadFailed()) {
          ListStateView({ state: 'error', onRefresh: () => this.refreshList() })
        } else if (this.dataSource.getIsFirstLoad()) {
          ListStateView({ state: 'loading' })
        } else if (this.dataSource.totalCount() === 0) {
          // 空状态（对齐设计稿 qn-coupon-empty）
          Column() {
            Text('📭').fontSize(48).margin({ bottom: 8 })
            Text(this.tabs[this.currentTab].status === 'unused' ? '暂无可用优惠券' : '暂无记录')
              .fontSize(13)
              .fontColor($r('app.color.color_text_4'))
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else {
          List({ space: 12 }) {
            LazyForEach(this.dataSource, (coupon: Coupon, idx: number) => {
              ListItem() {
                this.CouponCard(coupon, idx)
              }
            }, (coupon: Coupon) => coupon.couponId + `_${coupon.status}`)
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 16, right: 16, top: 16, bottom: 24 })
          .scrollBar(BarState.Off)
          .cachedCount(AppConstants.LIST_CACHED_COUNT)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 优惠券卡（票券样式，对齐设计稿 qn-coupon） */
  @Builder
  CouponCard(coupon: Coupon, idx: number) {
    Stack({ alignContent: Alignment.Start }) {
      // 主卡片（左侧色块 + 右侧信息）
      Row() {
        // ===== 左侧色块（对齐设计稿 qn-coupon-stub，90px 宽） =====
        Column({ space: 5 }) {
          // 金额（28px Bold）
          if (coupon.type === 'discount') {
            Text(`${Math.round((coupon.discountRate ?? 1) * 10)}折`)
              .fontSize(28)
              .fontColor(this.getStubTextColor(coupon, idx))
              .fontWeight(FontWeight.Bold)
          } else {
            Row({ space: 1 }) {
              Text('¥')
                .fontSize(16)
                .fontColor(this.getStubTextColor(coupon, idx))
                .fontWeight(FontWeight.Bold)
                .baselineOffset(4)
              Text(`${coupon.cutAmount ?? 0}`)
                .fontSize(28)
                .fontColor(this.getStubTextColor(coupon, idx))
                .fontWeight(FontWeight.Bold)
            }
            .alignItems(VerticalAlign.Bottom)
          }
          // 条件（11px）
          Text(this.getConditionText(coupon))
            .fontSize(11)
            .fontColor(this.getStubTextColor(coupon, idx))
            .opacity(0.95)
        }
        .width(90)
        .height(98)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(this.getStubBgColor(coupon, idx))
        .borderRadius({ topLeft: AppConstants.RADIUS_LG, bottomLeft: AppConstants.RADIUS_LG })

        // ===== 右侧信息区（对齐设计稿 qn-coupon-info） =====
        Column({ space: 4 }) {
          // 标题（16px Bold）
          Text(coupon.name)
            .fontSize(16)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
          // 规则（12px text_2）
          Text(this.getRuleText(coupon))
            .fontSize(12)
            .fontColor($r('app.color.color_text_2'))
            .maxLines(1)
          // 有效期（11px text_3）
          Text(`有效期 ${this.formatDate(coupon.validFrom)} - ${this.formatDate(coupon.validTo)}`)
            .fontSize(11)
            .fontColor($r('app.color.color_text_3'))
            .margin({ top: 2 })

          Blank()

          // 底部右下角操作按钮区
          Row() {
            Blank()
            if (coupon.status === 'unused') {
              // 立即使用按钮（对齐设计稿 qn-coupon-use，黄色 pill 28px）
              Text('立即使用')
                .fontSize(12)
                .fontColor($r('app.color.color_ink'))
                .fontWeight(FontWeight.Bold)
                .height(28)
                .padding({ left: 14, right: 14 })
                .borderRadius(AppConstants.RADIUS_PILL)
                .backgroundColor($r('app.color.color_yellow'))
                .textAlign(TextAlign.Center)
                .onClick(() => {
                  ToastUtil.success('已选中该优惠券');
                  NavigationHelper.pop();
                  Logger.info(AppConstants.SCENE_USER, { action: 'coupon_use_click', couponId: coupon.couponId });
                })
            } else if (coupon.status === 'used') {
              // 已使用标签（对齐设计稿 qn-coupon-expired 灰底）
              Text('已使用')
                .fontSize(12)
                .fontColor($r('app.color.color_text_3'))
                .fontWeight(FontWeight.Medium)
                .height(28)
                .padding({ left: 12, right: 12 })
                .borderRadius(AppConstants.RADIUS_PILL)
                .backgroundColor($r('app.color.color_fill'))
                .textAlign(TextAlign.Center)
            } else {
              // 已过期标签
              Text('已过期')
                .fontSize(12)
                .fontColor($r('app.color.color_text_3'))
                .fontWeight(FontWeight.Medium)
                .height(28)
                .padding({ left: 12, right: 12 })
                .borderRadius(AppConstants.RADIUS_PILL)
                .backgroundColor($r('app.color.color_fill'))
                .textAlign(TextAlign.Center)
            }
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .layoutWeight(1)
        .height(98)
        .padding({ left: 16, right: 14, top: 14, bottom: 14 })
        .backgroundColor($r('app.color.color_bg_card'))
        .borderRadius({ topRight: AppConstants.RADIUS_LG, bottomRight: AppConstants.RADIUS_LG })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .opacity(coupon.status === 'expired' ? 0.5 : 1.0)
      .shadow(AppConstants.SHADOW_CARD)

      // ===== 撕边缺口（上） - 14×14 圆形奶油底，对齐设计稿 qn-coupon::before =====
      Column()
        .width(14)
        .height(14)
        .borderRadius(7)
        .backgroundColor($r('app.color.color_bg_page'))
        .position({ x: 83, y: -7 })

      // ===== 撕边缺口（下） - 14×14 圆形奶油底，对齐设计稿 qn-coupon::after =====
      Column()
        .width(14)
        .height(14)
        .borderRadius(7)
        .backgroundColor($r('app.color.color_bg_page'))
        .position({ x: 83, y: 91 })

      // ===== 撕边虚线（穿孔线，对齐设计稿 qn-coupon-perf） =====
      Column()
        .width(0)
        .height(74)
        .border({ width: { left: 1.5 }, color: 'rgba(26,26,26,0.14)', style: BorderStyle.Dashed })
        .position({ x: 90, y: 12 })
    }
    .width('100%')
    .height(98)
  }

  /** 获取色块背景色（对齐设计稿 qn-stub-red / yellow / green / gray） */
  private getStubBgColor(coupon: Coupon, idx: number): ResourceColor {
    if (coupon.status !== 'unused') {
      return '#CFCFCF';
    }
    const theme: StubTheme = this.getStubTheme(idx);
    switch (theme) {
      case 'red': return $r('app.color.color_live');
      case 'yellow': return $r('app.color.color_yellow');
      case 'green': return $r('app.color.color_green');
      default: return '#CFCFCF';
    }
  }

  /** 获取色块文字色（对齐设计稿：红/绿/灰为白字，黄为黑字） */
  private getStubTextColor(coupon: Coupon, idx: number): ResourceColor {
    if (coupon.status !== 'unused') {
      return Color.White;
    }
    const theme: StubTheme = this.getStubTheme(idx);
    if (theme === 'yellow') {
      return $r('app.color.color_ink');
    }
    return Color.White;
  }

  /** 色块主题轮换（对齐设计稿 卡1红 / 卡2黄 / 卡3绿 循环） */
  private getStubTheme(idx: number): StubTheme {
    const cycle: StubTheme[] = ['red', 'yellow', 'green'];
    return cycle[idx % cycle.length];
  }

  /** 获取条件文案（色块下方，对齐设计稿 qn-stub-cond） */
  private getConditionText(coupon: Coupon): string {
    if (coupon.type === 'full_cut') { return `满${coupon.threshold}可用`; }
    if (coupon.type === 'no_threshold') { return '无门槛'; }
    return `${Math.round((coupon.discountRate ?? 1) * 10)}折`; // 折扣券
  }

  /** 获取规则文案（右侧信息区，对齐设计稿 qn-coupon-rule） */
  private getRuleText(coupon: Coupon): string {
    if (coupon.type === 'full_cut') { return `满${coupon.threshold}元可用 · ${coupon.scope}`; }
    if (coupon.type === 'no_threshold') { return `无门槛 · ${coupon.scope}`; }
    return `${coupon.scope}享${Math.round((coupon.discountRate ?? 1) * 10)}折`;
  }

  /** 格式化日期（对齐设计稿 2024.06.01） */
  private formatDate(ts: number): string {
    const d: Date = new Date(ts);
    return `${d.getFullYear()}.${String(d.getMonth() + 1).padStart(2, '0')}.${String(d.getDate()).padStart(2, '0')}`;
  }
}
