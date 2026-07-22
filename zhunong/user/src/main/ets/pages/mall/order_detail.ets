/**
 * order_detail - 订单详情页
 * 遵循 spec 3.1.4.1：订单信息 + 商品信息 + 物流信息（Mock）+ 操作按钮
 * 操作：取消/付款/确认收货/评价/申请退款
 */

import { UserRoutes, RouteName, NavigationHelper, Logger, AppConstants, ToastUtil } from 'common';
import { Order, SubOrder, OrderItem, OrderItemSpec } from '../../model/OrderModels';
import { getOrderStatusLabel, getOrderStatusColor } from '../../model/OrderModels';
import { getMockOrderById, updateMockOrderStatus } from '../../mock/OrderMock';
import { getMockAddressById } from '../../mock/ProfileMock';
import { Address } from '../../model/ProfileModels';
import { ImageUtil } from '../../utils/ImageUtil';

/** 跳转评价创建的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface ReviewCreateParam {
  orderId: string;
}

@ComponentV2
export struct OrderDetail {
  @Local orderId: string = '';
  @Local order: Order | null = null;
  @Local address: Address | null = null;

  aboutToAppear(): void {
    const params: Record<string, string> = NavigationHelper.getParam<Record<string, string>>() as Record<string, string>;
    if (params) {
      this.orderId = params.orderId ?? '';
    }
    this.loadOrder();
  }

  private loadOrder(): void {
    this.order = getMockOrderById(this.orderId);
    if (this.order && this.order.subOrders.length > 0) {
      this.address = getMockAddressById(this.order.subOrders[0].addressId);
    }
  }

  /** 取消订单 */
  private cancelOrder(): void {
    updateMockOrderStatus(this.orderId, 'cancelled');
    ToastUtil.success('订单已取消');
    this.loadOrder();
  }

  /** 付款 */
  private payOrder(): void {
    updateMockOrderStatus(this.orderId, 'pending_shipment');
    ToastUtil.success('支付成功');
    this.loadOrder();
  }

  /** 确认收货 */
  private confirmReceipt(): void {
    updateMockOrderStatus(this.orderId, 'pending_review');
    ToastUtil.success('确认收货成功');
    this.loadOrder();
  }

  /** 去评价 */
  private gotoReview(): void {
    const param: ReviewCreateParam = { orderId: this.orderId };
    NavigationHelper.push(RouteName.USER_REVIEW_CREATE, param);
  }

  /** 申请退款 */
  private requestRefund(): void {
    updateMockOrderStatus(this.orderId, 'refunding');
    ToastUtil.success('退款申请已提交');
    this.loadOrder();
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部栏
        Row() {
          Text('‹').fontSize(28).fontColor($r('app.color.color_text_primary')).onClick(() => { NavigationHelper.pop(); })
          Text('订单详情').fontSize(18).fontColor($r('app.color.color_text_primary')).fontWeight(FontWeight.Medium).layoutWeight(1).textAlign(TextAlign.Center)
          Text('').width(28)
        }
        .width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor($r('app.color.color_bg_card')).alignItems(VerticalAlign.Center)

        if (this.order) {
          Scroll() {
            Column({ space: 12 }) {
              // 订单状态
              this.StatusCard()
              // 收货地址
              this.AddressCard()
              // 商品信息（按卖家分组）
              ForEach(this.order.subOrders, (so: SubOrder, _i: number) => {
                this.SubOrderCard(so)
              }, (so: SubOrder) => so.subOrderId)
              // 物流信息
              this.LogisticsCard()
              // 订单信息
              this.OrderInfoCard()
            }
            .width('100%').padding({ bottom: 80 })
          }
          .layoutWeight(1).width('100%').backgroundColor($r('app.color.color_bg_page')).scrollBar(BarState.Off)

          // 底部操作栏
          this.BottomActionBar()
        }
      }
      .width('100%').height('100%').backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 状态卡片 */
  @Builder
  StatusCard() {
    Row() {
      Text(getOrderStatusLabel(this.order!.status))
        .fontSize(18).fontColor($r(`app.color.${getOrderStatusColor(this.order!.status)}`)).fontWeight(FontWeight.Bold)
      Blank()
      Text(`订单号：${this.order!.orderId}`).fontSize(11).fontColor($r('app.color.color_text_hint'))
    }
    .width('100%').padding(16).backgroundColor($r('app.color.color_bg_card')).borderRadius(12).margin({ left: 12, right: 12, top: 12 }).alignItems(VerticalAlign.Center)
  }

  /** 地址卡片 */
  @Builder
  AddressCard() {
    Row({ space: 12 }) {
      Text('📍').fontSize(22)
      if (this.address) {
        Column({ space: 4 }) {
          Row({ space: 8 }) {
            Text(this.address.receiverName).fontSize(13).fontColor($r('app.color.color_text_primary')).fontWeight(FontWeight.Medium)
            Text(this.address.phone).fontSize(12).fontColor($r('app.color.color_text_secondary'))
          }
          Text(`${this.address.province}${this.address.city}${this.address.district} ${this.address.detail}`)
            .fontSize(11).fontColor($r('app.color.color_text_secondary')).maxLines(2)
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
      } else {
        Text('地址信息缺失').fontSize(13).fontColor($r('app.color.color_text_hint')).layoutWeight(1)
      }
    }
    .width('100%').padding(16).backgroundColor($r('app.color.color_bg_card')).borderRadius(12).margin({ left: 12, right: 12 }).alignItems(VerticalAlign.Top)
  }

  /** 子订单卡片 */
  @Builder
  SubOrderCard(so: SubOrder) {
    Column({ space: 10 }) {
      Row({ space: 4 }) {
        Text('🏪').fontSize(13)
        Text(so.farmerName).fontSize(13).fontColor($r('app.color.color_text_primary')).fontWeight(FontWeight.Medium)
      }
      ForEach(so.items, (item: OrderItem, _j: number) => {
        Row({ space: 10 }) {
          Image(ImageUtil.get(item.image)).width(64).height(64).borderRadius(8).objectFit(ImageFit.Cover)
          Column({ space: 4 }) {
            Text(item.title).fontSize(12).fontColor($r('app.color.color_text_primary')).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.formatSpecs(item.specs)).fontSize(11).fontColor($r('app.color.color_text_secondary'))
            Row() {
              Text(`¥${item.price.toFixed(2)}`).fontSize(13).fontColor($r('app.color.color_price')).fontWeight(FontWeight.Bold)
              Blank()
              Text(`x${item.quantity}`).fontSize(12).fontColor($r('app.color.color_text_secondary'))
            }.width('100%')
          }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        }.width('100%')
      }, (item: OrderItem) => item.productId + (item.skuId ?? ''))
      Divider().color($r('app.color.color_divider'))
      Row() {
        Text('商品小计').fontSize(12).fontColor($r('app.color.color_text_secondary'))
        Blank()
        Text(`¥${so.subtotal.toFixed(2)}`).fontSize(13).fontColor($r('app.color.color_text_primary'))
      }.width('100%')
      Row() {
        Text('运费').fontSize(12).fontColor($r('app.color.color_text_secondary'))
        Blank()
        Text(so.freight === 0 ? '包邮' : `¥${so.freight.toFixed(2)}`).fontSize(12).fontColor($r('app.color.color_text_primary'))
      }.width('100%')
    }
    .width('100%').padding(16).backgroundColor($r('app.color.color_bg_card')).borderRadius(12).margin({ left: 12, right: 12 })
  }

  /** 物流信息卡片 */
  @Builder
  LogisticsCard() {
    Column({ space: 8 }) {
      Text('物流信息').fontSize(14).fontColor($r('app.color.color_text_primary')).fontWeight(FontWeight.Medium).alignSelf(ItemAlign.Start)
      if (this.order!.trackingNo) {
        Row() {
          Text('物流公司').fontSize(12).fontColor($r('app.color.color_text_secondary')).width(72)
          Text(this.order!.logisticsCompany ?? '').fontSize(12).fontColor($r('app.color.color_text_primary'))
        }.width('100%')
        Row() {
          Text('运单号').fontSize(12).fontColor($r('app.color.color_text_secondary')).width(72)
          Text(this.order!.trackingNo ?? '').fontSize(12).fontColor($r('app.color.color_text_primary'))
        }.width('100%')
        Text('📦 您的包裹正在路上，预计 2-3 天送达').fontSize(12).fontColor($r('app.color.color_primary')).margin({ top: 4 })
      } else {
        Text('暂无物流信息').fontSize(12).fontColor($r('app.color.color_text_hint'))
      }
    }
    .width('100%').padding(16).backgroundColor($r('app.color.color_bg_card')).borderRadius(12).margin({ left: 12, right: 12 }).alignItems(HorizontalAlign.Start)
  }

  /** 订单信息卡片 */
  @Builder
  OrderInfoCard() {
    Column({ space: 8 }) {
      Text('订单信息').fontSize(14).fontColor($r('app.color.color_text_primary')).fontWeight(FontWeight.Medium).alignSelf(ItemAlign.Start)
      Row() {
        Text('下单时间').fontSize(12).fontColor($r('app.color.color_text_secondary')).width(72)
        Text(this.formatTime(this.order!.createdAt)).fontSize(12).fontColor($r('app.color.color_text_primary'))
      }.width('100%')
      if (this.order!.paidAt) {
        Row() {
          Text('付款时间').fontSize(12).fontColor($r('app.color.color_text_secondary')).width(72)
          Text(this.formatTime(this.order!.paidAt)).fontSize(12).fontColor($r('app.color.color_text_primary'))
        }.width('100%')
      }
      if (this.order!.remark) {
        Row() {
          Text('买家留言').fontSize(12).fontColor($r('app.color.color_text_secondary')).width(72)
          Text(this.order!.remark).fontSize(12).fontColor($r('app.color.color_text_primary')).layoutWeight(1)
        }.width('100%')
      }
      Divider().color($r('app.color.color_divider')).margin({ top: 4, bottom: 4 })
      Row() {
        Text('商品总额').fontSize(12).fontColor($r('app.color.color_text_secondary'))
        Blank()
        Text(`¥${(this.order!.totalAmount - (this.order!.couponDiscount ?? 0)).toFixed(2)}`).fontSize(12).fontColor($r('app.color.color_text_primary'))
      }.width('100%')
      if (this.order!.couponDiscount && this.order!.couponDiscount > 0) {
        Row() {
          Text('优惠减免').fontSize(12).fontColor($r('app.color.color_text_secondary'))
          Blank()
          Text(`-¥${this.order!.couponDiscount.toFixed(2)}`).fontSize(12).fontColor($r('app.color.color_error'))
        }.width('100%')
      }
      Row() {
        Text('实付款').fontSize(13).fontColor($r('app.color.color_text_primary')).fontWeight(FontWeight.Medium)
        Blank()
        Text(`¥${this.order!.totalAmount.toFixed(2)}`).fontSize(16).fontColor($r('app.color.color_price')).fontWeight(FontWeight.Bold)
      }.width('100%')
    }
    .width('100%').padding(16).backgroundColor($r('app.color.color_bg_card')).borderRadius(12).margin({ left: 12, right: 12 }).alignItems(HorizontalAlign.Start)
  }

  /** 底部操作栏 */
  @Builder
  BottomActionBar() {
    Row() {
      Blank()
      if (this.order!.status === 'pending_payment') {
        Button('取消订单').height(36).borderRadius(18).backgroundColor($r('app.color.color_bg_card')).fontColor($r('app.color.color_text_primary')).fontSize(13).border({ width: 1, color: $r('app.color.color_divider') }).padding({ left: 16, right: 16 }).margin({ right: 8 }).onClick(() => { this.cancelOrder(); })
        Button('立即支付').height(36).borderRadius(18).backgroundColor($r('app.color.color_secondary')).fontColor(Color.White).fontSize(13).padding({ left: 20, right: 20 }).onClick(() => { this.payOrder(); })
      } else if (this.order!.status === 'pending_receipt') {
        Button('确认收货').height(36).borderRadius(18).backgroundColor($r('app.color.color_primary')).fontColor(Color.White).fontSize(13).padding({ left: 20, right: 20 }).onClick(() => { this.confirmReceipt(); })
      } else if (this.order!.status === 'pending_review') {
        Button('去评价').height(36).borderRadius(18).backgroundColor($r('app.color.color_secondary')).fontColor(Color.White).fontSize(13).padding({ left: 20, right: 20 }).onClick(() => { this.gotoReview(); })
      } else if (this.order!.status === 'pending_shipment') {
        Button('申请退款').height(36).borderRadius(18).backgroundColor($r('app.color.color_bg_card')).fontColor($r('app.color.color_error')).fontSize(13).border({ width: 1, color: $r('app.color.color_error') }).padding({ left: 16, right: 16 }).onClick(() => { this.requestRefund(); })
      }
    }
    .width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor($r('app.color.color_bg_card')).border({ width: { top: 0.5 }, color: $r('app.color.color_divider') }).alignItems(VerticalAlign.Center)
  }

  /** 格式化规格 */
  private formatSpecs(specs?: OrderItemSpec[]): string {
    if (!specs || specs.length === 0) {
      return '';
    }
    return specs.map((s: OrderItemSpec) => s.value).join(' / ');
  }

  /** 格式化时间 */
  private formatTime(ts: number): string {
    const d: Date = new Date(ts);
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')} ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
  }
}
