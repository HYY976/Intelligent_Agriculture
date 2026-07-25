/**
 * order_list - 订单列表页
 * 遵循 spec 3.1.4.1 + UI 复刻 order.html：
 *  - 顶部栏：返回（白圆）+ 居中标题 + 搜索（白圆）
 *  - 状态 Tab 栏（可横滑）：全部/待付款/待发货/待收货/已完成 + 计数徽标 + 黄色下划线
 *  - 订单卡：店铺头（黄底小图标 + 店名 + 箭头）+ 状态胶囊 + 商品行（48×48 缩略图）+ 分隔线 + 实付 + 操作按钮
 *  - 操作按钮：取消订单/去支付/查看物流/确认收货/再次购买/评价/提醒发货
 *
 * spec 10.11.4 Step 2：ForEach → LazyForEach + keyGenerator + cachedCount
 * 路由参数：status（all/pending_payment/pending_shipment/pending_receipt/completed）
 */

import { RouteName, NavigationHelper, Logger, AppConstants, ToastUtil, ListStateView } from 'common';
import { OrderStatus } from 'common';
import { OrderListItem, OrderItem, OrderItemSpec } from '../../model/OrderModels';
import { getOrderStatusLabel } from '../../model/OrderModels';
import { updateMockOrderStatus, getMockOrderCountByStatus } from '../../mock/OrderMock';
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

/** 状态胶囊配色（对齐设计稿 qn-pill-*） */
interface StatusPillStyle {
  bgColor: ResourceColor;
  textColor: ResourceColor;
}

@ComponentV2
export struct OrderList {
  /** 当前状态筛选 */
  @Local currentStatus: string = 'all';
  /** 列表是否为空（驱动空状态切换） */
  @Local isEmpty: boolean = true;
  /** 各状态订单计数（对齐设计稿 qn-tab-count） */
  @Local orderCounts: Record<string, number> = {} as Record<string, number>;
  /** 订单列表数据源（spec 10.11.4：LazyForEach 替代 ForEach） */
  private dataSource: OrderListDataSource = new OrderListDataSource();
  /** 状态 Tab 配置（对齐设计稿 5 Tab：全部/待付款/待发货/待收货/已完成） */
  private statusTabs: StatusTab[] = [
    { status: 'all', label: '全部' },
    { status: 'pending_payment', label: '待付款' },
    { status: 'pending_shipment', label: '待发货' },
    { status: 'pending_receipt', label: '待收货' },
    { status: 'completed', label: '已完成' }
  ];

  async aboutToAppear(): Promise<void> {
    const params: Record<string, string> = NavigationHelper.getParam<Record<string, string>>() as Record<string, string>;
    if (params && params.status) {
      this.currentStatus = params.status;
    }
    this.orderCounts = getMockOrderCountByStatus();
    await this.refreshList();
  }

  /** 刷新订单列表（spec 10.11.4：异步 refresh + 空状态同步） */
  private async refreshList(): Promise<void> {
    this.dataSource.setStatus(this.currentStatus);
    await this.dataSource.refresh();
    this.isEmpty = this.dataSource.totalCount() === 0;
    this.orderCounts = getMockOrderCountByStatus();
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

  /** 获取状态胶囊配色（对齐设计稿 qn-pill-*） */
  private getStatusPillStyle(status: OrderStatus): StatusPillStyle {
    switch (status) {
      case 'pending_payment':
        return { bgColor: $r('app.color.color_live_soft'), textColor: $r('app.color.color_live') };
      case 'pending_shipment':
        return { bgColor: 'rgba(74,144,226,0.14)', textColor: $r('app.color.color_info') };
      case 'pending_receipt':
      case 'pending_review':
        return { bgColor: $r('app.color.color_yellow_soft'), textColor: '#B8860B' };
      case 'completed':
        return { bgColor: $r('app.color.color_green_soft'), textColor: $r('app.color.color_green_deep') };
      case 'cancelled':
      case 'refunded':
        return { bgColor: $r('app.color.color_fill'), textColor: $r('app.color.color_text_3') };
      default:
        return { bgColor: $r('app.color.color_fill'), textColor: $r('app.color.color_text_2') };
    }
  }

  /** 格式化规格 */
  private formatSpecs(specs?: OrderItemSpec[]): string {
    if (!specs || specs.length === 0) {
      return '';
    }
    return `规格：${specs.map((s: OrderItemSpec) => s.value).join(' / ')}`;
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部栏（对齐设计稿 qn-topbar）
        Row() {
          // 返回键（白圆 32×32）
          Text('‹')
            .fontSize(22)
            .fontColor($r('app.color.color_ink'))
            .width(32)
            .height(32)
            .textAlign(TextAlign.Center)
            .borderRadius(AppConstants.RADIUS_PILL)
            .backgroundColor($r('app.color.color_bg_card'))
            .shadow(AppConstants.SHADOW_CARD)
            .onClick(() => { NavigationHelper.pop(); })

          Text('我的订单')
            .fontSize(17)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          // 搜索键（白圆 32×32）
          Text('🔍')
            .fontSize(14)
            .width(32)
            .height(32)
            .textAlign(TextAlign.Center)
            .borderRadius(AppConstants.RADIUS_PILL)
            .backgroundColor($r('app.color.color_bg_card'))
            .shadow(AppConstants.SHADOW_CARD)
            .onClick(() => { ToastUtil.show('订单搜索功能开发中'); })
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor($r('app.color.color_bg_page'))
        .alignItems(VerticalAlign.Center)

        // 状态 Tab 栏（对齐设计稿 qn-status-tabs）
        Scroll() {
          Row({ space: 4 }) {
            ForEach(this.statusTabs, (tab: StatusTab, _i: number) => {
              this.StatusTabItem(tab)
            }, (tab: StatusTab) => tab.status)
          }
          .padding({ left: 16, right: 16 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
        .height(52)
        .backgroundColor($r('app.color.color_bg_page'))
        .align(Alignment.Start)
        .border({ width: { bottom: 1 }, color: { bottom: $r('app.color.color_line') } })

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
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
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

  /** 状态 Tab 项（对齐设计稿 qn-status-tab） */
  @Builder
  StatusTabItem(tab: StatusTab) {
    Column({ space: 2 }) {
      // 标签文字（14px 600 / 800 active）
      Text(tab.label)
        .fontSize(14)
        .fontColor(this.currentStatus === tab.status ? $r('app.color.color_ink') : $r('app.color.color_text_2'))
        .fontWeight(this.currentStatus === tab.status ? FontWeight.Bold : FontWeight.Medium)

      // 计数（11px 700，红色 if >0 else 灰）
      Text(`${this.orderCounts[tab.status] ?? 0}`)
        .fontSize(11)
        .fontColor((this.orderCounts[tab.status] ?? 0) > 0
          ? $r('app.color.color_live')
          : $r('app.color.color_text_4'))
        .fontWeight(FontWeight.Bold)
    }
    .padding({ left: 12, right: 12, top: 8, bottom: 10 })
    .alignItems(HorizontalAlign.Center)
    .border(this.currentStatus === tab.status
      ? { width: { bottom: 3 }, color: { bottom: $r('app.color.color_yellow_deep') } }
      : {})
    .onClick(() => { this.onStatusChange(tab.status); })
  }

  /** 订单卡片（对齐设计稿 qn-card + qn-order-card） */
  @Builder
  OrderCard(order: OrderListItem) {
    Column({ space: 0 }) {
      // 店铺头行（对齐设计稿 qn-order-head）
      Row() {
        Row({ space: 8 }) {
          // 店铺小图标（22×22 黄底 圆角6）
          Text('🏪')
            .fontSize(11)
            .width(22)
            .height(22)
            .textAlign(TextAlign.Center)
            .borderRadius(6)
            .backgroundColor($r('app.color.color_yellow_tint'))

          // 店铺名（15px 800）
          Text(order.farmerName)
            .fontSize(15)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 右箭头
          Text('›')
            .fontSize(14)
            .fontColor($r('app.color.color_text_4'))
        }
        .layoutWeight(1)
        .alignItems(VerticalAlign.Center)

        // 状态胶囊（对齐设计稿 qn-pill）
        Text(getOrderStatusLabel(order.status))
          .fontSize(11)
          .fontColor(this.getStatusPillStyle(order.status).textColor)
          .fontWeight(FontWeight.Bold)
          .padding({ left: 10, right: 10, top: 3, bottom: 3 })
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor(this.getStatusPillStyle(order.status).bgColor)
      }
      .width('100%')
      .padding({ bottom: 10 })
      .alignItems(VerticalAlign.Center)

      // 商品行列表（对齐设计稿 qn-prod-row）
      ForEach(order.items, (item: OrderItem, idx: number) => {
        this.ProductRow(item, idx > 0)
      }, (item: OrderItem, idx: number) => `${order.orderId}_${item.productId}_${idx}`)

      // 分隔线
      Divider()
        .color($r('app.color.color_line'))
        .strokeWidth(1)
        .margin({ top: 10, bottom: 10 })

      // 底部：件数 + 实付（对齐设计稿 qn-order-foot）
      Row({ space: 10 }) {
        Text(`共${order.itemCount}件`)
          .fontSize(13)
          .fontColor($r('app.color.color_text_3'))
        Text('实付')
          .fontSize(13)
          .fontColor($r('app.color.color_text_2'))
        Text(`¥${order.totalAmount.toFixed(2)}`)
          .fontSize(15)
          .fontColor(order.status === 'pending_payment'
            ? $r('app.color.color_live')
            : $r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
      .alignItems(VerticalAlign.Bottom)

      // 操作按钮行（对齐设计稿 qn-order-actions）
      Row({ space: 8 }) {
        Blank()
        this.ActionButtons(order)
      }
      .width('100%')
      .margin({ top: 12 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 14, bottom: 12 })
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .onClick(() => { this.gotoOrderDetail(order.orderId); })
  }

  /** 商品行（对齐设计稿 qn-prod-row） */
  @Builder
  ProductRow(item: OrderItem, showDashedTop: boolean) {
    Row({ space: 10 }) {
      // 商品缩略图（48×48 RADIUS_SM）
      Image(ImageUtil.get(item.image))
        .width(48)
        .height(48)
        .borderRadius(AppConstants.RADIUS_SM)
        .objectFit(ImageFit.Cover)
        .backgroundColor($r('app.color.color_fill'))

      // 商品信息
      Column({ space: 4 }) {
        Text(item.title)
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.formatSpecs(item.specs))
          .fontSize(12)
          .fontColor($r('app.color.color_text_3'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 价格 + 数量
      Column({ space: 3 }) {
        Text(`¥${item.price.toFixed(2)}`)
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        Text(`×${item.quantity}`)
          .fontSize(12)
          .fontColor($r('app.color.color_text_3'))
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .border(showDashedTop ? { width: { top: 1 }, color: { top: $r('app.color.color_line') }, style: { top: BorderStyle.Dashed } } : {})
    .alignItems(VerticalAlign.Center)
  }

  /** 操作按钮组（对齐设计稿 qn-order-actions） */
  @Builder
  ActionButtons(order: OrderListItem) {
    if (order.status === 'pending_payment') {
      this.LineButton('取消订单', () => { this.cancelOrder(order.orderId); })
      this.PrimaryButton('去支付', () => { this.payOrder(order.orderId); })
    } else if (order.status === 'pending_shipment') {
      this.LineButton('提醒发货', () => { ToastUtil.show('已提醒卖家尽快发货'); })
    } else if (order.status === 'pending_receipt') {
      this.LineButton('查看物流', () => { ToastUtil.show('物流信息见订单详情'); })
      this.YellowButton('确认收货', () => { this.confirmReceipt(order.orderId); })
    } else if (order.status === 'pending_review') {
      this.LineButton('再次购买', () => { ToastUtil.show('已加入购物车'); })
      this.YellowButton('评价', () => {
        const reviewParam: ReviewCreateParam = { orderId: order.orderId };
        NavigationHelper.push(RouteName.USER_REVIEW_CREATE, reviewParam);
      })
    } else if (order.status === 'completed') {
      this.LineButton('再次购买', () => { ToastUtil.show('已加入购物车'); })
    }
  }

  /** 线框按钮（对齐设计稿 qn-btn-line） */
  @Builder
  LineButton(label: string, action: () => void) {
    Text(label)
      .fontSize(13)
      .fontColor($r('app.color.color_ink'))
      .fontWeight(FontWeight.Bold)
      .height(32)
      .padding({ left: 14, right: 14 })
      .borderRadius(AppConstants.RADIUS_SM)
      .backgroundColor($r('app.color.color_bg_card'))
      .border({ width: 1, color: $r('app.color.color_line_2') })
      .textAlign(TextAlign.Center)
      .onClick(() => { action(); })
  }

  /** 墨黑主按钮（对齐设计稿 qn-btn-primary） */
  @Builder
  PrimaryButton(label: string, action: () => void) {
    Text(label)
      .fontSize(13)
      .fontColor(Color.White)
      .fontWeight(FontWeight.Bold)
      .height(32)
      .padding({ left: 14, right: 14 })
      .borderRadius(AppConstants.RADIUS_SM)
      .backgroundColor($r('app.color.color_cta_black'))
      .textAlign(TextAlign.Center)
      .onClick(() => { action(); })
  }

  /** 黄色按钮（对齐设计稿 qn-btn-yellow） */
  @Builder
  YellowButton(label: string, action: () => void) {
    Text(label)
      .fontSize(13)
      .fontColor($r('app.color.color_ink'))
      .fontWeight(FontWeight.Bold)
      .height(32)
      .padding({ left: 14, right: 14 })
      .borderRadius(AppConstants.RADIUS_SM)
      .backgroundColor($r('app.color.color_primary'))
      .textAlign(TextAlign.Center)
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
}
