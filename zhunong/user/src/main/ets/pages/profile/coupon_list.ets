/**
 * coupon_list - 优惠券页
 * 遵循 spec 3.1.3.5：优惠券列表（未使用/已使用/已过期）
 *
 * spec 10.11.4 Step 2：ForEach → LazyForEach + keyGenerator + cachedCount
 */

import { ToastUtil, NavigationHelper, AppConstants, ListStateView } from 'common';
import { Coupon, CouponStatus } from '../../model/ProfileModels';
import { CouponListDataSource } from '../../viewmodel/CouponListDataSource';

/** 优惠券 Tab 配置 */
interface CouponTab {
  status: CouponStatus;
  label: string;
}

@ComponentV2
export struct CouponList {
  /** 当前 Tab 索引 */
  @Local currentTab: number = 0;
  /** 列表是否为空（驱动空状态切换） */
  @Local isEmpty: boolean = true;
  /** 优惠券数据源（spec 10.11.4：LazyForEach 替代 ForEach） */
  private dataSource: CouponListDataSource = new CouponListDataSource();
  /** Tab 配置（spec 10.11.4：status 改为 CouponStatus，去掉 'all'） */
  private tabs: CouponTab[] = [
    { status: 'unused', label: '未使用' },
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
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Text('‹').fontSize(28).fontColor($r('app.color.color_text_primary')).onClick(() => { NavigationHelper.pop(); })
          Text('我的优惠券').fontSize(18).fontColor($r('app.color.color_text_primary')).fontWeight(FontWeight.Medium).layoutWeight(1).textAlign(TextAlign.Center)
          Text('').width(28)
        }
        .width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor($r('app.color.color_bg_card')).alignItems(VerticalAlign.Center)

        // Tab
        Row() {
          ForEach(this.tabs, (tab: CouponTab, index: number) => {
            Text(tab.label).fontSize(13).fontColor(this.currentTab === index ? $r('app.color.color_primary') : $r('app.color.color_text_secondary'))
              .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Normal).layoutWeight(1).textAlign(TextAlign.Center).padding({ top: 12, bottom: 12 })
              .border({ width: { bottom: 2 }, color: this.currentTab === index ? $r('app.color.color_primary') : Color.Transparent })
              .onClick(() => { this.onTabChange(index); })
          }, (tab: CouponTab, i: number) => `${tab.status}_${i}`)
        }
        .width('100%').backgroundColor($r('app.color.color_bg_card'))

        // 优惠券列表（spec 10.11.4 Step 4：4 态状态机 error / loading / empty / list）
        if (this.dataSource.getLoadFailed()) {
          ListStateView({ state: 'error', onRefresh: () => this.refreshList() })
        } else if (this.dataSource.getIsFirstLoad()) {
          ListStateView({ state: 'loading' })
        } else if (this.dataSource.totalCount() === 0) {
          ListStateView({ state: 'empty', emptyText: '暂无优惠券', emptyDesc: '关注活动获取更多优惠' })
        } else {
          List({ space: 12 }) {
            LazyForEach(this.dataSource, (coupon: Coupon, _i: number) => {
              ListItem() {
                this.CouponCard(coupon)
              }
            }, (coupon: Coupon) => coupon.couponId + `_${coupon.status}`)
          }
          .width('100%').layoutWeight(1).padding({ left: 12, right: 12, top: 12 }).scrollBar(BarState.Off)
          .cachedCount(AppConstants.LIST_CACHED_COUNT)
        }
      }
      .width('100%').height('100%').backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  @Builder
  CouponCard(coupon: Coupon) {
    Row() {
      // 左侧金额
      Column({ space: 2 }) {
        if (coupon.type === 'discount') {
          Text(`${Math.round((coupon.discountRate ?? 1) * 10)}折`).fontSize(28).fontColor(Color.White).fontWeight(FontWeight.Bold)
        } else {
          Row({ space: 2 }) {
            Text('¥').fontSize(14).fontColor(Color.White)
            Text(`${coupon.cutAmount ?? 0}`).fontSize(32).fontColor(Color.White).fontWeight(FontWeight.Bold)
          }.alignItems(VerticalAlign.Bottom)
        }
        Text(this.getConditionText(coupon)).fontSize(10).fontColor('rgba(255,255,255,0.85)')
      }
      .width(110).height(100).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      .backgroundColor(coupon.status === 'unused' ? $r('app.color.color_secondary') : $r('app.color.color_button_disabled'))
      .borderRadius({ topLeft: 12, bottomLeft: 12 })

      // 右侧信息
      Column({ space: 4 }) {
        Text(coupon.name).fontSize(14).fontColor($r('app.color.color_text_primary')).fontWeight(FontWeight.Medium).maxLines(1)
        Text(`适用：${coupon.scope}`).fontSize(11).fontColor($r('app.color.color_text_secondary')).maxLines(1)
        Text(`有效期：${this.formatDate(coupon.validFrom)} - ${this.formatDate(coupon.validTo)}`).fontSize(10).fontColor($r('app.color.color_text_hint'))
        if (coupon.status === 'unused') {
          Text('去使用 ›').fontSize(11).fontColor($r('app.color.color_secondary')).margin({ top: 2 }).onClick(() => { NavigationHelper.pop(); })
        } else if (coupon.status === 'used') {
          Text('已使用').fontSize(11).fontColor($r('app.color.color_text_hint')).margin({ top: 2 })
        } else {
          Text('已过期').fontSize(11).fontColor($r('app.color.color_text_hint')).margin({ top: 2 })
        }
      }
      .layoutWeight(1).height(100).padding({ left: 12, right: 12 }).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Start)
      .backgroundColor($r('app.color.color_bg_card')).borderRadius({ topRight: 12, bottomRight: 12 })
    }
    .width('100%').borderRadius(12)
  }

  private getConditionText(coupon: Coupon): string {
    if (coupon.type === 'full_cut') { return `满${coupon.threshold}元可用`; }
    if (coupon.type === 'no_threshold') { return '无门槛'; }
    return '';
  }

  private formatDate(ts: number): string {
    const d: Date = new Date(ts);
    return `${d.getFullYear()}.${String(d.getMonth() + 1).padStart(2, '0')}.${String(d.getDate()).padStart(2, '0')}`;
  }

}
