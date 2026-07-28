/**
 * ProfileMock - 个人中心域 Mock 数据
 * 遵循 spec 3.1.3.5：地址/收藏/关注/优惠券/钱包/浏览历史
 */

import { Address, FavoriteItem, FollowItem, Coupon, WalletInfo, WalletTransaction, HistoryItem, ProfileStats, ProfileLevel } from '../model/ProfileModels';

/** 收货地址 Mock（spec 3.1.3.5） */
export const MOCK_ADDRESSES: Address[] = [
  {
    addressId: 'addr001', receiverName: '张三', phone: '138****8888',
    province: '广东省', city: '深圳市', district: '南山区',
    detail: '科技园粤海街道xx大厦1801室', isDefault: true, tag: '公司'
  },
  {
    addressId: 'addr002', receiverName: '张三', phone: '138****8888',
    province: '广东省', city: '深圳市', district: '福田区',
    detail: '华强北赛格广场32楼', isDefault: false, tag: '家'
  },
  {
    addressId: 'addr003', receiverName: '李四', phone: '139****6666',
    province: '北京市', city: '北京市', district: '海淀区',
    detail: '中关村大街1号院', isDefault: false, tag: '学校'
  }
];

/** 收藏商品 Mock（spec 3.1.3.5） */
export const MOCK_FAVORITES: FavoriteItem[] = [
  { favoriteId: 'fav001', productId: 'p001', title: '有机青菜 500g 当季新鲜 直采直发', image: 'prod_vegetable_1', price: 9.90, farmerName: '青禾农庄', createdAt: 1737900000000, offShelf: false },
  { favoriteId: 'fav002', productId: 'p005', title: '冰糖橙 5斤 当季鲜果 甜度高', image: 'prod_fruit_1', price: 29.90, farmerName: '田园牧歌', createdAt: 1737800000000, offShelf: false },
  { favoriteId: 'fav003', productId: 'p007', title: '高山绿茶 250g 明前嫩芽 清香回甘', image: 'prod_tea_1', price: 68.00, farmerName: '青禾农庄', createdAt: 1737700000000, offShelf: false },
  { favoriteId: 'fav004', productId: 'p009', title: '土蜂蜜 500g 百花蜜 农家自酿', image: 'prod_honey_1', price: 89.00, farmerName: '田园牧歌', createdAt: 1737600000000, offShelf: false },
  { favoriteId: 'fav005', productId: 'p008', title: '山核桃 250g 临安特产 香酥脆', image: 'prod_nut_1', price: 45.90, farmerName: '山野好物', createdAt: 1737500000000, offShelf: false }
];

/** 关注卖家 Mock（spec 3.1.3.5） */
export const MOCK_FOLLOWS: FollowItem[] = [
  { followId: 'fol001', farmerId: 'f001', farmerName: '青禾农庄', avatar: 'avatar_farmer_1', shopIntro: '专注有机蔬菜种植，自有高山农场', fansCount: 12560, productCount: 18, certified: true, createdAt: 1737900000000 },
  { followId: 'fol002', farmerId: 'f003', farmerName: '田园牧歌', avatar: 'avatar_farmer_3', shopIntro: '深山好物，从田间到餐桌', fansCount: 28690, productCount: 24, certified: true, createdAt: 1737800000000 },
  { followId: 'fol003', farmerId: 'f002', farmerName: '山野好物', avatar: 'avatar_farmer_2', shopIntro: '山间野味，农家直发', fansCount: 8920, productCount: 12, certified: false, createdAt: 1737700000000 }
];

/** 优惠券 Mock（spec 3.1.3.5） */
export const MOCK_COUPONS: Coupon[] = [
  { couponId: 'cp001', name: '新人专享满50减10', type: 'full_cut', threshold: 50, cutAmount: 10, validFrom: 1736000000000, validTo: 1739600000000, status: 'unused', scope: '全场通用' },
  { couponId: 'cp002', name: '生鲜满100减20', type: 'full_cut', threshold: 100, cutAmount: 20, validFrom: 1737000000000, validTo: 1739600000000, status: 'unused', scope: '生鲜水果分类' },
  { couponId: 'cp003', name: '粮油9折券', type: 'discount', discountRate: 0.9, validFrom: 1737000000000, validTo: 1739600000000, status: 'unused', scope: '粮油调味分类' },
  { couponId: 'cp004', name: '无门槛5元券', type: 'no_threshold', cutAmount: 5, validFrom: 1737000000000, validTo: 1738000000000, status: 'used', scope: '全场通用' },
  { couponId: 'cp005', name: '满200减50', type: 'full_cut', threshold: 200, cutAmount: 50, validFrom: 1736000000000, validTo: 1736600000000, status: 'expired', scope: '全场通用' }
];

/** 钱包信息 Mock（对齐设计稿 wallet.html qn-hero: 余额1,288.50 + qn-stat-card: 本月支出328/累计优惠156/积分2,880/优惠券6张） */
export const MOCK_WALLET: WalletInfo = {
  balance: 1288.50,
  monthSpent: 328,
  totalDiscount: 156,
  points: 2880,
  couponCount: 6
};

/** 钱包交易明细 Mock（对齐设计稿 wallet.html qn-tx-list: 草莓订单/充值/订单退款/购物积分/珍珠米） */
export const MOCK_WALLET_TRANSACTIONS: WalletTransaction[] = [
  { txId: 'tx001', iconTheme: 'red', icon: '🛍️', title: '草莓订单', time: '今天 10:24', amount: -29.9, isInt: false },
  { txId: 'tx002', iconTheme: 'green', icon: '⬇️', title: '充值', time: '昨天 18:30', amount: 200.00, isInt: false },
  { txId: 'tx003', iconTheme: 'blue', icon: '↩️', title: '订单退款', time: '07-20 14:15', amount: 15.00, isInt: false },
  { txId: 'tx004', iconTheme: 'yellow', icon: '🎁', title: '购物积分', time: '07-19 09:42', amount: 288, isInt: true },
  { txId: 'tx005', iconTheme: 'red', icon: '🛍️', title: '珍珠米', time: '07-18 16:08', amount: -20.0, isInt: false }
];

/** 个人中心统计 Mock（对齐设计稿 user-profile.html qn-stat-row: 关注128/粉丝56/订单23/积分860） */
export const MOCK_PROFILE_STATS: ProfileStats = {
  followCount: 128,
  fansCount: 56,
  orderCount: 23,
  points: 860
};

/** 个人中心等级 Mock（对齐设计稿 qn-level-pill: Lv.3 智农达人） */
export const MOCK_PROFILE_LEVEL: ProfileLevel = {
  level: 3,
  title: '智农达人'
};

/** 用户 ID Mock（对齐设计稿 qn-profile-id: ID: QN20231234） */
export const MOCK_USER_ID: string = 'QN20231234';

/** 购物车商品件数 Mock（对齐设计稿 qn-cart-right: 3件商品） */
export const MOCK_CART_ITEM_COUNT: number = 3;

/** 浏览历史 Mock（对齐设计稿 history.html: 今天3条 + 昨天3条 + 更早1条，时间相对 Date.now() 动态计算） */
const HOUR_MS: number = 3600 * 1000;
const DAY_MS: number = 24 * HOUR_MS;
export const MOCK_HISTORIES: HistoryItem[] = [
  { historyId: 'h001', productId: 'p001', title: '丹东红颜草莓 新鲜采摘 2斤装', image: 'prod_fruit_1', price: 39.9, farmerName: '王大姐果园', viewedAt: Date.now() - 2 * HOUR_MS },
  { historyId: 'h002', productId: 'p005', title: '普罗旺斯沙瓤番茄 5斤箱装', image: 'prod_vegetable_1', price: 29.9, farmerName: '老李家菜园', viewedAt: Date.now() - 5 * HOUR_MS },
  { historyId: 'h003', productId: 'p007', title: '明前龙井新茶 礼盒装250g', image: 'prod_tea_1', price: 128.00, farmerName: '云雾茶庄', viewedAt: Date.now() - 8 * HOUR_MS },
  { historyId: 'h004', productId: 'p010', title: '东北五常稻花香大米 10斤', image: 'prod_meat_1', price: 89.00, farmerName: '黑土农场', viewedAt: Date.now() - 27 * HOUR_MS },
  { historyId: 'h005', productId: 'p009', title: '散养土鸡蛋 30枚装', image: 'prod_honey_1', price: 49.9, farmerName: '山间农舍', viewedAt: Date.now() - 31 * HOUR_MS },
  { historyId: 'h006', productId: 'p014', title: '秦岭土蜂蜜 纯天然500g', image: 'prod_corn_1', price: 69.00, farmerName: '老蜂农赵叔', viewedAt: Date.now() - 37 * HOUR_MS },
  { historyId: 'h007', productId: 'p012', title: '香菇 500g 山珍鲜菇 肉厚味鲜', image: 'prod_mushroom_1', price: 32.00, farmerName: '田园牧歌', viewedAt: Date.now() - 3 * DAY_MS }
];

/** 查询地址（按 ID） */
export function getMockAddressById(addressId: string): Address | null {
  const found: Address | undefined = MOCK_ADDRESSES.find((a: Address) => a.addressId === addressId);
  return found ?? null;
}

/** 获取默认地址 */
export function getMockDefaultAddress(): Address | null {
  const found: Address | undefined = MOCK_ADDRESSES.find((a: Address) => a.isDefault);
  return found ?? (MOCK_ADDRESSES.length > 0 ? MOCK_ADDRESSES[0] : null);
}

/** 设置默认地址 */
export function setMockDefaultAddress(addressId: string): void {
  MOCK_ADDRESSES.forEach((a: Address) => {
    a.isDefault = a.addressId === addressId;
  });
}

/** 删除地址 */
export function deleteMockAddress(addressId: string): void {
  const idx: number = MOCK_ADDRESSES.findIndex((a: Address) => a.addressId === addressId);
  if (idx >= 0) {
    MOCK_ADDRESSES.splice(idx, 1);
  }
}

/** 新增/编辑地址 */
export function saveMockAddress(address: Address): void {
  const idx: number = MOCK_ADDRESSES.findIndex((a: Address) => a.addressId === address.addressId);
  if (idx >= 0) {
    MOCK_ADDRESSES[idx] = address;
  } else {
    MOCK_ADDRESSES.unshift(address);
  }
  if (address.isDefault) {
    setMockDefaultAddress(address.addressId);
  }
}

/** 获取可用优惠券数 */
export function getMockAvailableCouponCount(): number {
  return MOCK_COUPONS.filter((c: Coupon) => c.status === 'unused').length;
}

/** 取消收藏 */
export function removeMockFavorite(favoriteId: string): void {
  const idx: number = MOCK_FAVORITES.findIndex((f: FavoriteItem) => f.favoriteId === favoriteId);
  if (idx >= 0) {
    MOCK_FAVORITES.splice(idx, 1);
  }
}

/** 取消关注 */
export function removeMockFollow(followId: string): void {
  const idx: number = MOCK_FOLLOWS.findIndex((f: FollowItem) => f.followId === followId);
  if (idx >= 0) {
    MOCK_FOLLOWS.splice(idx, 1);
  }
}

/** 删除单条浏览历史 */
export function removeMockHistory(historyId: string): void {
  const idx: number = MOCK_HISTORIES.findIndex((h: HistoryItem) => h.historyId === historyId);
  if (idx >= 0) {
    MOCK_HISTORIES.splice(idx, 1);
  }
}

/** 清空所有浏览历史 */
export function clearMockHistories(): void {
  MOCK_HISTORIES.splice(0, MOCK_HISTORIES.length);
}
