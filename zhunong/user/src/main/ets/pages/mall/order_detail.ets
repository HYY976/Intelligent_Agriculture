/**
 * order_detail - 订单详情页
 * 遵循 spec 3.1.4.1 + UI 复刻 order-detail.html：
 *  - 顶部栏：返回（白圆）+ 居中标题
 *  - 订单状态卡（渐变底 + 状态文案 + 副标题 + 圆形勾选图标）
 *  - 收货地址卡（黄底定位图标 + 姓名/电话/默认标 + 地址）
 *  - 商品清单卡（60×60 缩略图 + 名称 + 规格 + 价格 + 数量）
 *  - 物流信息卡（时间轴：圆点 + 竖线 + 节点标题/时间）
 *  - 金额明细卡（商品金额/运费/优惠券 + 实付款）
 *  - 底部操作栏：联系客服 + 状态相关操作按钮（评价/再次购买/立即支付/确认收货等）
 */

import { RouteName, NavigationHelper, Logger, AppConstants, ToastUtil } from 'common';
import { Order, SubOrder, OrderItem, OrderItemSpec } from '../../model/OrderModels';
import { getOrderStatusLabel } from '../../model/OrderModels';
import { getMockOrderById, updateMockOrderStatus } from '../../mock/OrderMock';
import { getMockAddressById } from '../../mock/ProfileMock';
import { Address } from '../../model/ProfileModels';
import { ImageUtil } from '../../utils/ImageUtil';
import { OrderStatus } from 'common';

/** 跳转评价创建的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface ReviewCreateParam {
  orderId: string;
}

/** 物流时间轴节点 */
interface TimelineNode {
  title: string;
  time: string;
  isCurrent: boolean;
}

/** 状态卡配色（渐变 + 文案） */
interface StatusCardStyle {
  startColor: ResourceColor;
  endColor: ResourceColor;
  title: string;
  subtitle: string;
  iconBg: ResourceColor;
  icon: string;
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

  /** 再次购买（加入购物车） */
  private rebuy(): void {
    ToastUtil.show('已加入购物车');
  }

  /** 联系客服 */
  private contactService(): void {
    ToastUtil.show('客服功能开发中');
  }

  /** 提醒发货 */
  private remindShipment(): void {
    ToastUtil.show('已提醒卖家尽快发货');
  }

  /** 获取状态卡配色 + 文案（对齐设计稿 od-status-card） */
  private getStatusCardStyle(status: OrderStatus): StatusCardStyle {
    switch (status) {
      case 'pending_payment':
        return {
          startColor: $r('app.color.color_live'),
          endColor: '#E53935',
          title: '待付款',
          subtitle: '请尽快完成支付，超时订单将自动取消',
          iconBg: '#C62828',
          icon: '💰'
        };
      case 'pending_shipment':
        return {
          startColor: $r('app.color.color_info'),
          endColor: '#357ABD',
          title: '待发货',
          subtitle: '卖家正在为您备货，请耐心等待',
          iconBg: '#2A5F94',
          icon: '📦'
        };
      case 'pending_receipt':
        return {
          startColor: $r('app.color.color_yellow_deep'),
          endColor: '#F5A623',
          title: '待收货',
          subtitle: '包裹正在路上，预计 2-3 天送达',
          iconBg: '#D68910',
          icon: '🚚'
        };
      case 'pending_review':
        return {
          startColor: $r('app.color.color_yellow_deep'),
          endColor: '#F5A623',
          title: '待评价',
          subtitle: '分享您的使用体验，评价赢积分',
          iconBg: '#D68910',
          icon: '✍️'
        };
      case 'completed':
        return {
          startColor: $r('app.color.color_green'),
          endColor: $r('app.color.color_green_deep'),
          title: '交易完成',
          subtitle: '您的订单已签收，感谢支持智农',
          iconBg: '#3D8A0A',
          icon: '✓'
        };
      case 'cancelled':
        return {
          startColor: $r('app.color.color_text_3'),
          endColor: '#666666',
          title: '已取消',
          subtitle: '订单已取消',
          iconBg: '#4D4D4D',
          icon: '✕'
        };
      case 'refunding':
        return {
          startColor: $r('app.color.color_warn'),
          endColor: '#E67E22',
          title: '退款中',
          subtitle: '退款申请处理中，请耐心等待',
          iconBg: '#B9770E',
          icon: '↩'
        };
      case 'refunded':
        return {
          startColor: $r('app.color.color_text_3'),
          endColor: '#666666',
          title: '已退款',
          subtitle: '退款已完成',
          iconBg: '#4D4D4D',
          icon: '✓'
        };
      default:
        return {
          startColor: $r('app.color.color_text_3'),
          endColor: '#666666',
          title: '未知状态',
          subtitle: '',
          iconBg: '#4D4D4D',
          icon: '?'
        };
    }
  }

  /** 构造物流时间轴节点（Mock） */
  private getTimelineNodes(order: Order): TimelineNode[] {
    const nodes: TimelineNode[] = [];
    if (order.status === 'pending_payment' || order.status === 'cancelled') {
      nodes.push({ title: '订单已提交', time: this.formatTime(order.createdAt), isCurrent: true });
      return nodes;
    }
    if (order.status === 'pending_shipment') {
      nodes.push({ title: '订单已支付', time: this.formatTime(order.paidAt ?? order.createdAt), isCurrent: true });
      nodes.push({ title: '等待卖家发货', time: '待发货', isCurrent: false });
      return nodes;
    }
    // 待收货/待评价/已完成：完整物流轨迹
    if (order.paidAt) {
      nodes.push({ title: '已发货', time: this.formatTime(order.paidAt + 3600000), isCurrent: false });
    }
    nodes.push({ title: '运输中', time: this.formatTime((order.paidAt ?? order.createdAt) + 86400000), isCurrent: false });
    if (order.status === 'pending_receipt') {
      nodes.push({ title: '派送中', time: this.formatTime((order.paidAt ?? order.createdAt) + 172800000), isCurrent: true });
    } else {
      // pending_review / completed：已签收
      nodes.push({ title: '包裹已签收', time: this.formatTime((order.paidAt ?? order.createdAt) + 172800000), isCurrent: true });
    }
    return nodes;
  }

  /** 格式化规格 */
  private formatSpecs(specs?: OrderItemSpec[]): string {
    if (!specs || specs.length === 0) {
      return '';
    }
    return `规格：${specs.map((s: OrderItemSpec) => s.value).join(' / ')}`;
  }

  /** 格式化时间 */
  private formatTime(ts: number): string {
    const d: Date = new Date(ts);
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')} ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部栏（对齐设计稿 qn-topbar）
        Row() {
          Text('‹')
            .fontSize(20)
            .fontColor($r('app.color.color_ink'))
            .width(32)
            .height(32)
            .textAlign(TextAlign.Center)
            .borderRadius(AppConstants.RADIUS_PILL)
            .backgroundColor($r('app.color.color_bg_card'))
            .shadow(AppConstants.SHADOW_CARD)
            .onClick(() => { NavigationHelper.pop(); })

          Text('订单详情')
            .fontSize(17)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Text('')
            .width(32)
            .height(32)
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor($r('app.color.color_bg_page'))
        .alignItems(VerticalAlign.Center)

        if (this.order) {
          Scroll() {
            Column({ space: 10 }) {
              // 1. 订单状态卡（渐变底）
              this.StatusCard()
              // 2. 收货地址卡
              this.AddressCard()
              // 3. 商品清单卡（按卖家分组）
              ForEach(this.order.subOrders, (so: SubOrder, _i: number) => {
                this.SubOrderCard(so)
              }, (so: SubOrder) => so.subOrderId)
              // 4. 物流信息卡
              this.LogisticsCard()
              // 5. 金额明细卡
              this.AmountDetailCard()
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 4, bottom: 100 })
          }
          .layoutWeight(1)
          .width('100%')
          .backgroundColor($r('app.color.color_bg_page'))
          .scrollBar(BarState.Off)

          // 底部固定操作栏
          this.BottomActionBar()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 订单状态卡（对齐设计稿 od-status-card） */
  @Builder
  StatusCard() {
    Row({ space: 12 }) {
      Column({ space: 6 }) {
        Text(this.getStatusCardStyle(this.order!.status).title)
          .fontSize(22)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
        if (this.getStatusCardStyle(this.order!.status).subtitle.length > 0) {
          Text(this.getStatusCardStyle(this.order!.status).subtitle)
            .fontSize(12)
            .fontColor('rgba(255,255,255,0.92)')
            .lineHeight(17)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 圆形勾选图标（48×48 深色底）
      Text(this.getStatusCardStyle(this.order!.status).icon)
        .fontSize(22)
        .fontColor(Color.White)
        .width(48)
        .height(48)
        .textAlign(TextAlign.Center)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor(this.getStatusCardStyle(this.order!.status).iconBg)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 18, bottom: 18 })
    .borderRadius(AppConstants.RADIUS_LG)
    .linearGradient({
      angle: 135,
      colors: [[this.getStatusCardStyle(this.order!.status).startColor, 0.0],
        [this.getStatusCardStyle(this.order!.status).endColor, 1.0]]
    })
    .shadow({ radius: 18, color: 'rgba(91,179,21,0.30)', offsetX: 0, offsetY: 6 })
    .alignItems(VerticalAlign.Center)
  }

  /** 收货地址卡（对齐设计稿 qn-card + od-addr-card） */
  @Builder
  AddressCard() {
    Row({ space: 12 }) {
      // 黄底定位图标（36×36 RADIUS_SM）
      Text('📍')
        .fontSize(18)
        .width(36)
        .height(36)
        .textAlign(TextAlign.Center)
        .borderRadius(AppConstants.RADIUS_SM)
        .backgroundColor($r('app.color.color_yellow_soft'))

      if (this.address) {
        Column({ space: 6 }) {
          // 姓名 + 电话 + 默认标
          Row({ space: 8 }) {
            Text(this.address.receiverName)
              .fontSize(15)
              .fontColor($r('app.color.color_ink'))
              .fontWeight(FontWeight.Bold)
            Text(this.address.phone)
              .fontSize(13)
              .fontColor($r('app.color.color_text_2'))
            if (this.address.isDefault) {
              Text('默认')
                .fontSize(11)
                .fontColor($r('app.color.color_green_deep'))
                .fontWeight(FontWeight.Bold)
                .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                .borderRadius(AppConstants.RADIUS_PILL)
                .backgroundColor($r('app.color.color_green_soft'))
            }
          }
          .alignItems(VerticalAlign.Center)

          // 地址详文
          Text(`${this.address.province}${this.address.city}${this.address.district} ${this.address.detail}`)
            .fontSize(13)
            .fontColor($r('app.color.color_text_2'))
            .lineHeight(20)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      } else {
        Text('地址信息缺失')
          .fontSize(14)
          .fontColor($r('app.color.color_text_3'))
          .layoutWeight(1)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(VerticalAlign.Top)
  }

  /** 子订单 / 商品清单卡（对齐设计稿 qn-card + od-prod-*） */
  @Builder
  SubOrderCard(so: SubOrder) {
    Column({ space: 0 }) {
      // 卡片头：店铺名 + 共X件
      Row() {
        Text(so.farmerName)
          .fontSize(15)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text(`共${so.items.reduce((sum: number, it: OrderItem) => sum + it.quantity, 0)}件`)
          .fontSize(12)
          .fontColor($r('app.color.color_text_3'))
      }
      .width('100%')
      .padding({ bottom: 12 })
      .alignItems(VerticalAlign.Center)

      // 商品行列表
      ForEach(so.items, (item: OrderItem, idx: number) => {
        this.ProductRow(item, idx > 0)
      }, (item: OrderItem, idx: number) => `${so.subOrderId}_${item.productId}_${idx}`)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 商品行（对齐设计稿 od-prod-row） */
  @Builder
  ProductRow(item: OrderItem, showTopBorder: boolean) {
    Row({ space: 12 }) {
      // 商品图（60×60 RADIUS_MD）
      Image(ImageUtil.get(item.image))
        .width(60)
        .height(60)
        .borderRadius(AppConstants.RADIUS_MD)
        .objectFit(ImageFit.Cover)
        .backgroundColor($r('app.color.color_fill'))

      Column({ space: 5 }) {
        Text(item.title)
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.formatSpecs(item.specs))
          .fontSize(12)
          .fontColor($r('app.color.color_text_3'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 价格 + 数量
      Column({ space: 5 }) {
        Text(`¥${item.price.toFixed(2)}`)
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        Text(`x${item.quantity}`)
          .fontSize(12)
          .fontColor($r('app.color.color_text_3'))
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .border(showTopBorder ? { width: { top: 1 }, color: { top: $r('app.color.color_line') } } : {})
    .alignItems(VerticalAlign.Center)
  }

  /** 物流信息卡（对齐设计稿 qn-card + od-tl 时间轴） */
  @Builder
  LogisticsCard() {
    Column({ space: 0 }) {
      // 卡片头
      Text('物流信息')
        .fontSize(15)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .padding({ bottom: 14 })
        .alignSelf(ItemAlign.Start)

      // 物流公司 + 运单号（如有）
      if (this.order!.trackingNo) {
        Row({ space: 6 }) {
          Text('物流公司：')
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
          Text(this.order!.logisticsCompany ?? '')
            .fontSize(12)
            .fontColor($r('app.color.color_text_2'))
        }
        .width('100%')
        .padding({ bottom: 8 })

        Row({ space: 6 }) {
          Text('运单号：')
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
          Text(this.order!.trackingNo ?? '')
            .fontSize(12)
            .fontColor($r('app.color.color_text_2'))
        }
        .width('100%')
        .padding({ bottom: 14 })
      }

      // 时间轴
      ForEach(this.getTimelineNodes(this.order!), (node: TimelineNode, idx: number) => {
        this.TimelineNode(node, idx, this.getTimelineNodes(this.order!).length)
      }, (node: TimelineNode, idx: number) => `${node.title}_${idx}`)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 时间轴节点（对齐设计稿 od-tl-item） */
  @Builder
  TimelineNode(node: TimelineNode, idx: number, total: number) {
    Row({ space: 12 }) {
      // 圆点 + 竖线列
      Stack({ alignContent: Alignment.Top }) {
        if (idx < total - 1) {
          // 竖线
          Column()
            .width(2)
            .height(28)
            .backgroundColor($r('app.color.color_green_soft'))
            .position({ x: 6, y: 14 })
        }
        // 圆点
        Text('')
          .width(node.isCurrent ? 14 : 10)
          .height(node.isCurrent ? 14 : 10)
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_green'))
          .margin({ top: node.isCurrent ? 3 : 5 })
      }
      .width(14)
      .height(node.isCurrent ? 14 : 10)

      // 内容
      Column({ space: 4 }) {
        Text(node.title)
          .fontSize(node.isCurrent ? 15 : 14)
          .fontColor(node.isCurrent ? $r('app.color.color_ink') : $r('app.color.color_text_2'))
          .fontWeight(node.isCurrent ? FontWeight.Bold : FontWeight.Medium)
        Text(node.time)
          .fontSize(12)
          .fontColor(node.isCurrent ? $r('app.color.color_green_deep') : $r('app.color.color_text_3'))
          .fontWeight(node.isCurrent ? FontWeight.Bold : FontWeight.Normal)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ bottom: idx < total - 1 ? 18 : 0 })
    .alignItems(VerticalAlign.Top)
  }

  /** 金额明细卡（对齐设计稿 qn-card + od-amt-*） */
  @Builder
  AmountDetailCard() {
    Column({ space: 0 }) {
      // 卡片头
      Text('金额明细')
        .fontSize(15)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .padding({ bottom: 12 })
        .alignSelf(ItemAlign.Start)

      // 商品金额
      this.AmountRow('商品金额', `¥${(this.order!.totalAmount - (this.order!.couponDiscount ?? 0) - this.getFreightTotal()).toFixed(2)}`, 'normal')

      // 运费
      this.AmountRow('运费', this.getFreightTotal() === 0 ? '¥0.00（包邮）' : `¥${this.getFreightTotal().toFixed(2)}`, this.getFreightTotal() === 0 ? 'free' : 'normal')

      // 优惠券
      if (this.order!.couponDiscount && this.order!.couponDiscount > 0) {
        this.AmountRow('优惠券', `-¥${this.order!.couponDiscount.toFixed(2)}`, 'coupon')
      }

      // 实付款
      Row() {
        Text('实付款')
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Medium)
        Blank()
        Text(`¥${this.order!.totalAmount.toFixed(2)}`)
          .fontSize(20)
          .fontColor($r('app.color.color_live'))
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .padding({ top: 14 })
      .margin({ top: 10 })
      .border({ width: { top: 1 }, color: { top: $r('app.color.color_line') } })
      .alignItems(VerticalAlign.Bottom)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 金额明细行（对齐设计稿 od-amt-row） */
  @Builder
  AmountRow(label: string, value: string, valueStyle: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor($r('app.color.color_text_2'))
      Blank()
      Text(value)
        .fontSize(14)
        .fontColor(valueStyle === 'free'
          ? $r('app.color.color_green_deep')
          : valueStyle === 'coupon'
            ? $r('app.color.color_live')
            : $r('app.color.color_ink'))
        .fontWeight(valueStyle === 'normal' ? FontWeight.Medium : FontWeight.Bold)
    }
    .width('100%')
    .padding({ top: 7, bottom: 7 })
    .alignItems(VerticalAlign.Center)
  }

  /** 获取运费总额 */
  private getFreightTotal(): number {
    if (!this.order) {
      return 0;
    }
    return this.order.subOrders.reduce((sum: number, so: SubOrder) => sum + so.freight, 0);
  }

  /** 底部固定操作栏（对齐设计稿 od-actionbar） */
  @Builder
  BottomActionBar() {
    Row() {
      // 左侧：联系客服
      Row({ space: 5 }) {
        Text('💬')
          .fontSize(14)
        Text('联系客服')
          .fontSize(13)
          .fontColor($r('app.color.color_text_2'))
          .fontWeight(FontWeight.Medium)
      }
      .height(40)
      .padding({ left: 18, right: 18 })
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor($r('app.color.color_bg_card'))
      .border({ width: 1, color: $r('app.color.color_line_2') })
      .alignItems(VerticalAlign.Center)
      .onClick(() => { this.contactService(); })

      Blank()

      // 右侧：状态相关操作按钮
      Row({ space: 8 }) {
        if (this.order!.status === 'pending_payment') {
          this.PillLineButton('取消订单', () => { this.cancelOrder(); })
          this.PillBlackButton('立即支付', () => { this.payOrder(); })
        } else if (this.order!.status === 'pending_shipment') {
          this.PillLineButton('提醒发货', () => { this.remindShipment(); })
          this.PillLineButton('申请退款', () => { this.requestRefund(); })
        } else if (this.order!.status === 'pending_receipt') {
          this.PillYellowButton('确认收货', () => { this.confirmReceipt(); })
        } else if (this.order!.status === 'pending_review') {
          this.PillYellowButton('评价', () => { this.gotoReview(); })
          this.PillBlackButton('再次购买', () => { this.rebuy(); })
        } else if (this.order!.status === 'completed') {
          this.PillYellowButton('再次购买', () => { this.rebuy(); })
        } else if (this.order!.status === 'refunding' || this.order!.status === 'refunded') {
          this.PillLineButton('再次购买', () => { this.rebuy(); })
        }
      }
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_NAV)
    .alignItems(VerticalAlign.Center)
  }

  /** 胶囊线框按钮（对齐设计稿 od-btn-service） */
  @Builder
  PillLineButton(label: string, action: () => void) {
    Text(label)
      .fontSize(13)
      .fontColor($r('app.color.color_text_2'))
      .fontWeight(FontWeight.Medium)
      .height(40)
      .padding({ left: 18, right: 18 })
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor($r('app.color.color_bg_card'))
      .border({ width: 1, color: $r('app.color.color_line_2') })
      .textAlign(TextAlign.Center)
      .onClick(() => { action(); })
  }

  /** 胶囊黄色按钮（对齐设计稿 od-btn-review） */
  @Builder
  PillYellowButton(label: string, action: () => void) {
    Text(label)
      .fontSize(14)
      .fontColor($r('app.color.color_ink'))
      .fontWeight(FontWeight.Bold)
      .height(40)
      .padding({ left: 20, right: 20 })
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor($r('app.color.color_primary'))
      .textAlign(TextAlign.Center)
      .onClick(() => { action(); })
  }

  /** 胶囊墨黑按钮（对齐设计稿 od-btn-rebuy） */
  @Builder
  PillBlackButton(label: string, action: () => void) {
    Text(label)
      .fontSize(14)
      .fontColor(Color.White)
      .fontWeight(FontWeight.Bold)
      .height(40)
      .padding({ left: 20, right: 20 })
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor($r('app.color.color_cta_black'))
      .textAlign(TextAlign.Center)
      .onClick(() => { action(); })
  }
}
