/**
 * order_list - 订单列表页
 * 遵循 spec 3.1.4.1：订单列表按状态筛选
 * 路由参数：status（all/pending_payment/pending_shipment/pending_receipt/pending_review）
 *
 * spec 10.11.4 Step 2：ForEach → LazyForEach + keyGenerator + cachedCount
 */

import { UserRoutes, RouteName, NavigationHelper, Logger, AppConstants, ToastUtil, ListStateView } from 'common';
import { OrderStatus } from 'common';
import { OrderListItem } from '../../model/OrderModels';
import { getOrderStatusLabel, getOrderStatusColor } from '../../model/OrderModels';
import { updateMockOrderStatus } from '../../mock/OrderMock';
import { OrderListDataSource } from '../../viewmodel/OrderListDataSource';
import { ImageUtil } from '../../utils/ImageUtil';

/** 状态 Tab 配置 */
interface StatusTab {
  status: string;
  label: string;
}

/** 跳转订单详情的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface OrderDetailParam {
  orderId: string;
}

/** 跳转评价创建的路由参数 */
interface ReviewCreateParam {
  orderId: string;
}

@ComponentV2
export struct OrderList {
  /** 当前状态筛选 */
  @Local currentStatus: string = 'all';
  /** 列表是否为空（驱动空状态切换） */
  @Local isEmpty: boolean = true;
  /** 订单列表数据源（spec 10.11.4：LazyForEach 替代 ForEach） */
  private dataSource: OrderListDataSource = new OrderListDataSource();
  /** 状态 Tab 配置 */
  private statusTabs: StatusTab[] = [
    { status: 'all', label: '全部' },
    { status: 'pending_payment', label: '待付款' },
    { status: 'pending_shipment', label: '待发货' },
    { status: 'pending_receipt', label: '待收货' },
    { status: 'pending_review', label: '待评价' }
  ];

  async aboutToAppear(): Promise<void> {
    const params: Record<string, string> = NavigationHelper.getParam<Record<string, string>>() as Record<string, string>;
    if (params && params.status) {
      this.currentStatus = params.status;
    }
    await this.refreshList();
  }

  /** 刷新订单列表（spec 10.11.4：异步 refresh + 空状态同步） */
  private async refreshList(): Promise<void> {
    this.dataSource.setStatus(this.currentStatus);
    await this.dataSource.refresh();
    this.isEmpty = this.dataSource.totalCount() === 0;
  }

  /** 切换状态 Tab */
  private async onStatusChange(status: string): Promise<void> {
    this.currentStatus = status;
    await this.refreshList();
  }

  /** 跳转订单详情 */
  private gotoOrderDetail(orderId: string): void {
    const param: OrderDetailParam = { orderId: orderId };
    NavigationHelper.push(RouteName.USER_ORDER_DETAIL, param);
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部栏
        Row() {
          Text('‹').fontSize(28).fontColor($r('app.color.color_text_primary')).onClick(() => { NavigationHelper.pop(); })
          Text('我的订单').fontSize(18).fontColor($r('app.color.color_text_primary')).fontWeight(FontWeight.Medium).layoutWeight(1).textAlign(TextAlign.Center)
          Text('').width(28)
        }
        .width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor($r('app.color.color_bg_card')).alignItems(VerticalAlign.Center)

        // 状态 Tab
        Scroll() {
          Row({ space: 4 }) {
            ForEach(this.statusTabs, (tab: StatusTab, _i: number) => {
              Text(tab.label)
                .fontSize(13)
                .fontColor(this.currentStatus === tab.status ? $r('app.color.color_primary') : $r('app.color.color_text_secondary'))
                .fontWeight(this.currentStatus === tab.status ? FontWeight.Bold : FontWeight.Normal)
                .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                .backgroundColor(this.currentStatus === tab.status ? 'rgba(76,175,80,0.1)' : Color.Transparent)
                .borderRadius(16)
                .onClick(() => { this.onStatusChange(tab.status); })
            }, (tab: StatusTab) => tab.status)
          }
          .padding({ left: 12, right: 12 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%').height(44).backgroundColor($r('app.color.color_bg_card')).align(Alignment.Start)

        // 订单列表（spec 10.11.4 Step 4：4 态状态机 error / loading / empty / list）
        if (this.dataSource.getLoadFailed()) {
          ListStateView({ state: 'error', onRefresh: () => this.refreshList() })
        } else if (this.dataSource.getIsFirstLoad()) {
          ListStateView({ state: 'loading' })
        } else if (this.dataSource.totalCount() === 0) {
          ListStateView({ state: 'empty', emptyText: '暂无订单', emptyDesc: '快去挑选心仪的农产品吧' })
        } else {
          List({ space: 12 }) {
            LazyForEach(this.dataSource, (order: OrderListItem, _i: number) => {
              ListItem() {
                this.OrderCard(order)
              }
            }, (order: OrderListItem) => order.orderId + `_${order.status}`)
          }
          .width('100%').layoutWeight(1).padding({ left: 12, right: 12, top: 12 }).scrollBar(BarState.Off)
          .cachedCount(AppConstants.LIST_CACHED_COUNT)
        }
      }
      .width('100%').height('100%').backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 订单卡片 */
  @Builder
  OrderCard(order: OrderListItem) {
    Column({ space: 10 }) {
      // 卖家 + 状态
      Row() {
        Text('🏪').fontSize(13)
        Text(order.sellerDisplay).fontSize(13).fontColor($r('app.color.color_text_primary')).fontWeight(FontWeight.Medium).layoutWeight(1)
        Text(getOrderStatusLabel(order.status)).fontSize(13).fontColor($r(`app.color.${getOrderStatusColor(order.status)}`)).fontWeight(FontWeight.Medium)
      }.width('100%')

      // 商品信息
      Row({ space: 10 }) {
        Image(ImageUtil.get(order.mainImage)).width(64).height(64).borderRadius(8).objectFit(ImageFit.Cover)
        Column({ space: 4 }) {
          Text(`共${order.itemCount}件商品`).fontSize(12).fontColor($r('app.color.color_text_secondary'))
          Text(this.formatTime(order.createdAt)).fontSize(11).fontColor($r('app.color.color_text_hint'))
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        Column({ space: 2 }) {
          Text('合计').fontSize(11).fontColor($r('app.color.color_text_secondary'))
          Text(`¥${order.totalAmount.toFixed(2)}`).fontSize(15).fontColor($r('app.color.color_price')).fontWeight(FontWeight.Bold)
        }.alignItems(HorizontalAlign.End)
      }.width('100%')

      // 操作按钮
      Row() {
        Blank()
        if (order.status === 'pending_payment') {
          this.ActionButton('取消订单', () => { this.cancelOrder(order.orderId); })
          this.ActionButton('去支付', () => { this.payOrder(order.orderId); })
        } else if (order.status === 'pending_receipt') {
          this.ActionButton('查看物流', () => { ToastUtil.show('物流信息见订单详情'); })
          this.ActionButton('确认收货', () => { this.confirmReceipt(order.orderId); })
        } else if (order.status === 'pending_review') {
          this.ActionButton('去评价', () => { const reviewParam: ReviewCreateParam = { orderId: order.orderId }; NavigationHelper.push(RouteName.USER_REVIEW_CREATE, reviewParam); })
        }
      }.width('100%')
    }
    .width('100%').padding(16).backgroundColor($r('app.color.color_bg_card')).borderRadius(12)
    .onClick(() => { this.gotoOrderDetail(order.orderId); })
  }

  /** 操作按钮 */
  @Builder
  ActionButton(label: string, action: () => void) {
    Button(label)
      .height(30).borderRadius(15).backgroundColor($r('app.color.color_bg_card')).fontColor($r('app.color.color_text_primary')).fontSize(12)
      .border({ width: 1, color: $r('app.color.color_divider') }).padding({ left: 14, right: 14 }).margin({ left: 8 })
      .onClick(() => { action(); })
  }

  /** 取消订单 */
  private async cancelOrder(orderId: string): Promise<void> {
    updateMockOrderStatus(orderId, 'cancelled');
    ToastUtil.success('订单已取消');
    await this.refreshList();
  }

  /** 支付订单 */
  private async payOrder(orderId: string): Promise<void> {
    updateMockOrderStatus(orderId, 'pending_shipment');
    ToastUtil.success('支付成功');
    await this.refreshList();
  }

  /** 确认收货 */
  private async confirmReceipt(orderId: string): Promise<void> {
    updateMockOrderStatus(orderId, 'pending_review');
    ToastUtil.success('确认收货成功');
    await this.refreshList();
  }

  /** 格式化时间 */
  private formatTime(ts: number): string {
    const d: Date = new Date(ts);
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')} ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
  }

}
