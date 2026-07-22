/**
 * OrderModels - 用户端订单域数据模型
 * 遵循 spec 4.1.6 订单实体定义
 * 含主订单/子订单/订单项
 */

import { OrderStatus } from 'common';

/** 订单商品规格项 */
export interface OrderItemSpec {
  name: string;
  value: string;
}

/** 订单商品项（spec 4.1.6 OrderItem） */
export interface OrderItem {
  productId: string;
  skuId?: string;
  title: string;
  /** 商品主图 */
  image: string;
  /** 规格描述 */
  specs?: OrderItemSpec[];
  /** 单价（元） */
  price: number;
  /** 购买数量 */
  quantity: number;
}

/** 子订单（按卖家拆分，spec 4.1.6 SubOrder） */
export interface SubOrder {
  subOrderId: string;
  /** 主订单 ID */
  orderId: string;
  /** 卖家 ID */
  farmerId: string;
  /** 卖家昵称 */
  farmerName: string;
  /** 商品项列表 */
  items: OrderItem[];
  /** 子订单金额（商品小计） */
  subtotal: number;
  /** 运费 */
  freight: number;
  /** 子订单状态 */
  status: OrderStatus;
  /** 收货地址 ID */
  addressId: string;
  /** 支付时间 */
  paidAt?: number;
  /** 结算时间（确认收货后） */
  settledAt?: number;
}

/** 主订单（spec 4.1.6 Order） */
export interface Order {
  orderId: string;
  /** 买家 ID */
  buyerId: string;
  /** 总金额（含运费） */
  totalAmount: number;
  /** 主订单状态 */
  status: OrderStatus;
  /** 子订单列表（按卖家拆分） */
  subOrders: SubOrder[];
  /** 使用的优惠券 ID */
  couponId?: string;
  /** 优惠券减免金额 */
  couponDiscount?: number;
  /** 买家留言 */
  remark?: string;
  createdAt: number;
  /** 支付时间 */
  paidAt?: number;
  /** 物流单号（Mock） */
  trackingNo?: string;
  /** 物流公司（Mock） */
  logisticsCompany?: string;
}

/** 订单列表项（精简，用于列表展示） */
export interface OrderListItem {
  orderId: string;
  status: OrderStatus;
  /** 主图（取第一个商品项） */
  mainImage: string;
  /** 商品项总数 */
  itemCount: number;
  /** 总金额 */
  totalAmount: number;
  /** 卖家昵称（单卖家时显示，多卖家显示"N个店铺"） */
  sellerDisplay: string;
  createdAt: number;
}

/** 订单状态分组（个人中心5状态 Tab） */
export type OrderStatusTab = 'all' | 'pending_payment' | 'pending_shipment' | 'pending_receipt' | 'pending_review';

/** Mock 支付方式 */
export type PaymentMethod = 'alipay_mock' | 'wechat_mock' | 'balance_mock';

/** Mock 支付结果 */
export interface PaymentResult {
  success: boolean;
  paymentNo: string;
  paidAmount: number;
  paidAt: number;
  method: PaymentMethod;
}

/** 订单状态中文标签映射 */
export function getOrderStatusLabel(status: OrderStatus): string {
  switch (status) {
    case 'pending_payment': return '待付款';
    case 'pending_shipment': return '待发货';
    case 'pending_receipt': return '待收货';
    case 'pending_review': return '待评价';
    case 'completed': return '已完成';
    case 'cancelled': return '已取消';
    case 'refunding': return '退款中';
    case 'refunded': return '已退款';
    default: return '未知';
  }
}

/** 订单状态颜色资源名 */
export function getOrderStatusColor(status: OrderStatus): string {
  switch (status) {
    case 'pending_payment': return 'color_error';
    case 'pending_shipment': return 'color_secondary';
    case 'pending_receipt': return 'color_primary';
    case 'pending_review': return 'color_accent_gold';
    case 'completed': return 'color_primary';
    case 'cancelled': return 'color_text_hint';
    case 'refunding': return 'color_error';
    case 'refunded': return 'color_text_hint';
    default: return 'color_text_secondary';
  }
}
