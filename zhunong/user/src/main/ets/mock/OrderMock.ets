/**
 * OrderMock - 订单 Mock 数据
 * 遵循 spec 4.1.6 Order/SubOrder/OrderItem 实体定义
 * 覆盖 8 种订单状态（spec 3.1.3.5）
 */

import { Order, SubOrder, OrderItem, OrderListItem } from '../model/OrderModels';
import { OrderStatus } from 'common';
import { MOCK_FARMER_NAMES } from './ProductMock';
import { getMockProductById } from './ProductMock';

/** 创建订单入参项 */
export interface CreateOrderItem {
  productId: string;
  skuId?: string;
  quantity: number;
}

/** 构造订单商品项（从商品 Mock 取） */
function buildOrderItem(productId: string, skuIndex: number, quantity: number): OrderItem {
  const product = getMockProductById(productId);
  if (!product) {
    const item: OrderItem = {
      productId: productId, skuId: '', title: '已下架商品', image: 'prod_vegetable_1',
      price: 0, quantity: quantity
    };
    return item;
  }
  const sku = product.skuList[skuIndex] ?? product.skuList[0];
  const item: OrderItem = {
    productId: product.productId,
    skuId: sku.skuId,
    title: product.title,
    image: product.mainImages[0],
    specs: sku.specs,
    price: sku.price,
    quantity: quantity
  };
  return item;
}

/** 构造子订单（确保类型化对象字面量） */
function buildSubOrder(input: SubOrder): SubOrder {
  return input;
}

/** 子订单 Mock 数据（覆盖 8 种状态，预先构造以保证类型化） */
const SO_001: SubOrder = {
  subOrderId: 'so001', orderId: 'o001', farmerId: 'f001',
  farmerName: MOCK_FARMER_NAMES['f001'],
  items: [buildOrderItem('p001', 1, 2), buildOrderItem('p004', 1, 2)],
  subtotal: 45.40, freight: 4.30, status: 'pending_payment', addressId: 'addr001'
};
const SO_002: SubOrder = {
  subOrderId: 'so002', orderId: 'o002', farmerId: 'f003',
  farmerName: MOCK_FARMER_NAMES['f003'],
  items: [buildOrderItem('p009', 1, 1)],
  subtotal: 89.00, freight: 0, status: 'pending_shipment', addressId: 'addr001',
  paidAt: 1737800000000
};
const SO_003: SubOrder = {
  subOrderId: 'so003', orderId: 'o003', farmerId: 'f001',
  farmerName: MOCK_FARMER_NAMES['f001'],
  items: [buildOrderItem('p003', 1, 1)],
  subtotal: 59.00, freight: 0, status: 'pending_receipt', addressId: 'addr001',
  paidAt: 1737700000000
};
const SO_004: SubOrder = {
  subOrderId: 'so004', orderId: 'o004', farmerId: 'f001',
  farmerName: MOCK_FARMER_NAMES['f001'],
  items: [buildOrderItem('p001', 2, 5), buildOrderItem('p013', 2, 4)],
  subtotal: 154.50, freight: 14.30, status: 'pending_review', addressId: 'addr001',
  paidAt: 1737600000000, settledAt: 1737700000000
};
const SO_005: SubOrder = {
  subOrderId: 'so005', orderId: 'o005', farmerId: 'f003',
  farmerName: MOCK_FARMER_NAMES['f003'],
  items: [buildOrderItem('p005', 0, 1)],
  subtotal: 29.90, freight: 0, status: 'completed', addressId: 'addr001',
  paidAt: 1737400000000, settledAt: 1737500000000
};
const SO_006: SubOrder = {
  subOrderId: 'so006', orderId: 'o006', farmerId: 'f002',
  farmerName: MOCK_FARMER_NAMES['f002'],
  items: [buildOrderItem('p004', 1, 1)],
  subtotal: 12.80, freight: 0, status: 'cancelled', addressId: 'addr001'
};
const SO_007: SubOrder = {
  subOrderId: 'so007', orderId: 'o007', farmerId: 'f001',
  farmerName: MOCK_FARMER_NAMES['f001'],
  items: [buildOrderItem('p010', 1, 1)],
  subtotal: 78.00, freight: 0, status: 'refunding', addressId: 'addr001',
  paidAt: 1737200000000
};
const SO_008: SubOrder = {
  subOrderId: 'so008', orderId: 'o008', farmerId: 'f002',
  farmerName: MOCK_FARMER_NAMES['f002'],
  items: [buildOrderItem('p008', 1, 1)],
  subtotal: 45.90, freight: 0, status: 'refunded', addressId: 'addr001',
  paidAt: 1737100000000, settledAt: 1737150000000
};

/** 主订单 Mock 数据（覆盖 8 种状态） */
export const MOCK_ORDERS: Order[] = [
  {
    orderId: 'o001', buyerId: 'u_current', totalAmount: 49.70, status: 'pending_payment',
    subOrders: [SO_001],
    createdAt: 1737900000000
  },
  {
    orderId: 'o002', buyerId: 'u_current', totalAmount: 89.00, status: 'pending_shipment',
    subOrders: [SO_002],
    couponId: 'cp001', couponDiscount: 10.00,
    createdAt: 1737800000000, paidAt: 1737801000000
  },
  {
    orderId: 'o003', buyerId: 'u_current', totalAmount: 59.00, status: 'pending_receipt',
    subOrders: [SO_003],
    createdAt: 1737700000000, paidAt: 1737701000000,
    trackingNo: 'SF1234567890', logisticsCompany: '顺丰速运'
  },
  {
    orderId: 'o004', buyerId: 'u_current', totalAmount: 168.80, status: 'pending_review',
    subOrders: [SO_004],
    createdAt: 1737600000000, paidAt: 1737601000000,
    trackingNo: 'YT9876543210', logisticsCompany: '圆通速递'
  },
  {
    orderId: 'o005', buyerId: 'u_current', totalAmount: 29.90, status: 'completed',
    subOrders: [SO_005],
    createdAt: 1737400000000, paidAt: 1737401000000,
    trackingNo: 'ZT1111222233', logisticsCompany: '中通快递'
  },
  {
    orderId: 'o006', buyerId: 'u_current', totalAmount: 12.80, status: 'cancelled',
    subOrders: [SO_006],
    createdAt: 1737300000000
  },
  {
    orderId: 'o007', buyerId: 'u_current', totalAmount: 78.00, status: 'refunding',
    subOrders: [SO_007],
    createdAt: 1737200000000, paidAt: 1737201000000,
    trackingNo: 'JD5555666677', logisticsCompany: '京东物流'
  },
  {
    orderId: 'o008', buyerId: 'u_current', totalAmount: 45.90, status: 'refunded',
    subOrders: [SO_008],
    createdAt: 1737100000000, paidAt: 1737101000000
  }
];

/** 按 orderId 查询订单详情 */
export function getMockOrderById(orderId: string): Order | null {
  const found: Order | undefined = MOCK_ORDERS.find((o: Order) => o.orderId === orderId);
  return found ?? null;
}

/** 按状态查询订单列表（all = 全部；completed 合并 pending_review + completed，对齐设计稿 order.html） */
export function getMockOrderList(status: string): OrderListItem[] {
  let filtered: Order[] = MOCK_ORDERS.slice();
  if (status === 'completed') {
    // 设计稿"已完成" Tab 包含待评价 + 已完成
    filtered = filtered.filter((o: Order) => o.status === 'pending_review' || o.status === 'completed');
  } else if (status === 'all') {
    // 全部 Tab 排除已取消/退款（仅展示活跃订单，对齐设计稿计数）
    filtered = filtered.filter((o: Order) =>
      o.status !== 'cancelled' && o.status !== 'refunded'
    );
  } else {
    filtered = filtered.filter((o: Order) => o.status === status);
  }
  // 按创建时间倒序
  filtered.sort((a: Order, b: Order) => b.createdAt - a.createdAt);
  return filtered.map((o: Order): OrderListItem => {
    let itemCount: number = 0;
    let mainImage: string = 'prod_vegetable_1';
    let firstImage: boolean = true;
    const allItems: OrderItem[] = [];
    o.subOrders.forEach((so: SubOrder) => {
      so.items.forEach((item: OrderItem) => {
        itemCount += item.quantity;
        if (firstImage) {
          mainImage = item.image;
          firstImage = false;
        }
        allItems.push(item);
      });
    });
    const farmerName: string = o.subOrders.length === 1
      ? o.subOrders[0].farmerName
      : o.subOrders[0].farmerName;
    const sellerDisplay: string = o.subOrders.length === 1
      ? o.subOrders[0].farmerName
      : `${o.subOrders.length}个店铺`;
    return {
      orderId: o.orderId,
      status: o.status,
      mainImage: mainImage,
      itemCount: itemCount,
      totalAmount: o.totalAmount,
      sellerDisplay: sellerDisplay,
      farmerName: farmerName,
      items: allItems,
      createdAt: o.createdAt
    };
  });
}

/** 统计各状态订单数（用于个人中心 Tab 角标，对齐设计稿 5 Tab 计数） */
export function getMockOrderCountByStatus(): Record<string, number> {
  const counts: Record<string, number> = {
    'all': 0,
    'pending_payment': 0,
    'pending_shipment': 0,
    'pending_receipt': 0,
    'completed': 0
  };
  MOCK_ORDERS.forEach((o: Order) => {
    if (o.status === 'cancelled' || o.status === 'refunded') {
      return;
    }
    counts['all']++;
    if (o.status === 'pending_payment') {
      counts['pending_payment']++;
    } else if (o.status === 'pending_shipment') {
      counts['pending_shipment']++;
    } else if (o.status === 'pending_receipt') {
      counts['pending_receipt']++;
    } else if (o.status === 'pending_review' || o.status === 'completed') {
      counts['completed']++;
    }
  });
  return counts;
}

/** 创建新订单（Mock，返回订单 ID） */
export function createMockOrder(
  items: CreateOrderItem[],
  addressId: string,
  couponId?: string,
  remark?: string
): Order {
  const orderId: string = `o${Date.now()}`;
  // 按卖家分组
  const groupMap: Record<string, CreateOrderItem[]> = {};
  items.forEach((it: CreateOrderItem) => {
    const product = getMockProductById(it.productId);
    const farmerId: string = product ? product.farmerId : 'f001';
    if (!groupMap[farmerId]) {
      groupMap[farmerId] = [];
    }
    groupMap[farmerId].push(it);
  });
  const subOrders: SubOrder[] = [];
  let totalAmount: number = 0;
  Object.keys(groupMap).forEach((farmerId: string) => {
    const subItems: OrderItem[] = [];
    let subtotal: number = 0;
    groupMap[farmerId].forEach((it: CreateOrderItem) => {
      const product = getMockProductById(it.productId);
      if (!product) {
        return;
      }
      const skuIdx: number = it.skuId
        ? product.skuList.findIndex((s) => s.skuId === it.skuId)
        : 0;
      const sku = product.skuList[skuIdx >= 0 ? skuIdx : 0];
      const itemTotal: number = sku.price * it.quantity;
      subtotal += itemTotal;
      const newItem: OrderItem = {
        productId: product.productId,
        skuId: sku.skuId,
        title: product.title,
        image: product.mainImages[0],
        specs: sku.specs,
        price: sku.price,
        quantity: it.quantity
      };
      subItems.push(newItem);
    });
    const freight: number = subtotal >= 39 ? 0 : 5;
    totalAmount += subtotal + freight;
    const newSubOrder: SubOrder = {
      subOrderId: `so${Date.now()}_${farmerId}`,
      orderId: orderId,
      farmerId: farmerId,
      farmerName: MOCK_FARMER_NAMES[farmerId] ?? '未知卖家',
      items: subItems,
      subtotal: subtotal,
      freight: freight,
      status: 'pending_payment',
      addressId: addressId
    };
    subOrders.push(newSubOrder);
  });
  // 优惠券减免
  let couponDiscount: number = 0;
  if (couponId) {
    couponDiscount = 10;
    totalAmount -= couponDiscount;
  }
  const order: Order = {
    orderId: orderId,
    buyerId: 'u_current',
    totalAmount: Math.max(0, totalAmount),
    status: 'pending_payment',
    subOrders: subOrders,
    couponId: couponId,
    couponDiscount: couponDiscount,
    remark: remark,
    createdAt: Date.now()
  };
  // 插入到 Mock 列表头部
  MOCK_ORDERS.unshift(order);
  return order;
}

/** 更新订单状态（Mock：付款/确认收货/取消/退款） */
export function updateMockOrderStatus(orderId: string, newStatus: OrderStatus): void {
  const order: Order | undefined = MOCK_ORDERS.find((o: Order) => o.orderId === orderId);
  if (order) {
    order.status = newStatus;
    order.subOrders.forEach((so: SubOrder) => {
      so.status = newStatus;
    });
    if (newStatus === 'pending_shipment') {
      order.paidAt = Date.now();
    }
    if (newStatus === 'completed') {
      order.subOrders.forEach((so: SubOrder) => {
        so.settledAt = Date.now();
      });
    }
  }
}
