/**
 * CartMock - 购物车 Mock 数据
 * 遵循 spec 3.1.3.4：按卖家分组，支持多卖家合并结算
 */

import { CartItem, CartGroup } from '../model/CartModels';
import { getMockProductById } from './ProductMock';
import { MOCK_FARMER_NAMES } from './ProductMock';

/** 购物车商品项 Mock（按卖家分两组，覆盖多卖家场景） */
export const MOCK_CART_ITEMS: CartItem[] = [
  {
    cartItemId: 'ci001', productId: 'p001', skuId: 's0012',
    title: '有机青菜 500g 当季新鲜 直采直发',
    image: 'prod_vegetable_1', price: 9.90, quantity: 2, stock: 188,
    specText: '500g', selected: true
  },
  {
    cartItemId: 'ci002', productId: 'p004', skuId: 's0042',
    title: '新鲜番茄 1kg 沙瓤多汁 沙漠日光温室',
    image: 'prod_vegetable_2', price: 12.80, quantity: 3, stock: 200,
    specText: '1kg', selected: true
  },
  {
    cartItemId: 'ci003', productId: 'p013', skuId: 's0132',
    title: '小米辣 250g 农家自种 辣味十足',
    image: 'prod_chili_1', price: 8.80, quantity: 1, stock: 200,
    specText: '250g', selected: false
  },
  {
    cartItemId: 'ci004', productId: 'p009', skuId: 's0092',
    title: '土蜂蜜 500g 百花蜜 农家自酿',
    image: 'prod_honey_1', price: 89.00, quantity: 1, stock: 120,
    specText: '500g', selected: true
  },
  {
    cartItemId: 'ci005', productId: 'p005', skuId: 's0051',
    title: '冰糖橙 5斤 当季鲜果 甜度高',
    image: 'prod_fruit_1', price: 29.90, quantity: 2, stock: 380,
    specText: '5斤', selected: true
  },
  {
    cartItemId: 'ci006', productId: 'p008', skuId: 's0082',
    title: '山核桃 250g 临安特产 香酥脆',
    image: 'prod_nut_1', price: 45.90, quantity: 1, stock: 150,
    specText: '250g', selected: false
  }
];

/** 购物车内存态（运行时可读写） */
let cartItems: CartItem[] = MOCK_CART_ITEMS.slice();

/** 获取购物车分组（按卖家聚合） */
export function getMockCartGroups(): CartGroup[] {
  const groupMap: Record<string, CartItem[]> = {};
  cartItems.forEach((item: CartItem) => {
    const product = getMockProductById(item.productId);
    const farmerId: string = product ? product.farmerId : 'f001';
    if (!groupMap[farmerId]) {
      groupMap[farmerId] = [];
    }
    groupMap[farmerId].push(item);
  });
  const groups: CartGroup[] = [];
  Object.keys(groupMap).forEach((farmerId: string) => {
    const items: CartItem[] = groupMap[farmerId];
    const allSelected: boolean = items.every((it: CartItem) => it.selected);
    groups.push({
      farmerId: farmerId,
      farmerName: MOCK_FARMER_NAMES[farmerId] ?? '未知卖家',
      items: items,
      allSelected: allSelected
    });
  });
  return groups;
}

/** 更新购物车项选中状态 */
export function updateCartItemSelected(cartItemId: string, selected: boolean): void {
  const item: CartItem | undefined = cartItems.find((it: CartItem) => it.cartItemId === cartItemId);
  if (item) {
    item.selected = selected;
  }
}

/** 切换某卖家分组全选 */
export function toggleGroupSelect(farmerId: string, selected: boolean): void {
  cartItems.forEach((item: CartItem) => {
    const product = getMockProductById(item.productId);
    if (product && product.farmerId === farmerId) {
      item.selected = selected;
    }
  });
}

/** 切换全选 */
export function toggleAllSelect(selected: boolean): void {
  cartItems.forEach((item: CartItem) => {
    item.selected = selected;
  });
}

/** 更新购物车项数量 */
export function updateCartItemQuantity(cartItemId: string, quantity: number): void {
  const item: CartItem | undefined = cartItems.find((it: CartItem) => it.cartItemId === cartItemId);
  if (item) {
    item.quantity = Math.max(1, Math.min(quantity, item.stock));
  }
}

/** 删除购物车项 */
export function deleteCartItem(cartItemId: string): void {
  cartItems = cartItems.filter((it: CartItem) => it.cartItemId !== cartItemId);
}

/** 添加商品到购物车 */
export function addToMockCart(productId: string, skuId?: string, quantity: number = 1): void {
  const product = getMockProductById(productId);
  if (!product) {
    return;
  }
  const skuIdx: number = skuId
    ? product.skuList.findIndex((s) => s.skuId === skuId)
    : 0;
  const sku = product.skuList[skuIdx >= 0 ? skuIdx : 0];
  // 已存在同 SKU 则累加数量
  const exist: CartItem | undefined = cartItems.find((it: CartItem) =>
    it.productId === productId && it.skuId === sku.skuId
  );
  if (exist) {
    exist.quantity = Math.min(exist.quantity + quantity, exist.stock);
  } else {
    const specText: string = sku.specs.map((s) => s.value).join(' / ');
    cartItems.unshift({
      cartItemId: `ci${Date.now()}`,
      productId: productId,
      skuId: sku.skuId,
      title: product.title,
      image: product.mainImages[0],
      price: sku.price,
      quantity: quantity,
      stock: sku.stock,
      specText: specText,
      selected: true
    });
  }
}

/** 清空已选中的购物车项（下单后调用） */
export function clearSelectedCartItems(): void {
  cartItems = cartItems.filter((it: CartItem) => !it.selected);
}

/** 获取购物车总数量（角标） */
export function getMockCartCount(): number {
  return cartItems.length;
}
