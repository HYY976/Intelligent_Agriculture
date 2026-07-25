/**
 * ProfileModels - 用户端个人中心域数据模型
 * 遵循 spec 3.1.3.5 个人中心 Tab 规范
 * 含地址/收藏/关注/优惠券/钱包/浏览历史
 */

/** 收货地址 */
export interface Address {
  addressId: string;
  /** 收货人姓名 */
  receiverName: string;
  /** 联系电话 */
  phone: string;
  /** 省份 */
  province: string;
  /** 城市 */
  city: string;
  /** 区/县 */
  district: string;
  /** 详细地址 */
  detail: string;
  /** 是否默认地址 */
  isDefault: boolean;
  /** 标签（家/学校/公司等） */
  tag?: string;
}

/** 收藏的商品 */
export interface FavoriteItem {
  favoriteId: string;
  productId: string;
  title: string;
  image: string;
  price: number;
  /** 卖家昵称 */
  farmerName: string;
  /** 收藏时间 */
  createdAt: number;
  /** 商品是否已下架 */
  offShelf: boolean;
}

/** 关注的卖家 */
export interface FollowItem {
  followId: string;
  farmerId: string;
  /** 卖家昵称 */
  farmerName: string;
  /** 店铺头像 */
  avatar: string;
  /** 店铺简介 */
  shopIntro: string;
  /** 粉丝数 */
  fansCount: number;
  /** 在售商品数 */
  productCount: number;
  /** 是否认证 */
  certified: boolean;
  /** 关注时间 */
  createdAt: number;
}

/** 优惠券状态 */
export type CouponStatus = 'unused' | 'used' | 'expired';

/** 优惠券 */
export interface Coupon {
  couponId: string;
  /** 优惠券名称 */
  name: string;
  /** 优惠类型：满减/折扣/无门槛 */
  type: 'full_cut' | 'discount' | 'no_threshold';
  /** 满减门槛（满 X 元，type=full_cut 时有效） */
  threshold?: number;
  /** 优惠金额（满减/无门槛，单位元） */
  cutAmount?: number;
  /** 折扣率（type=discount 时有效，0.1-0.99） */
  discountRate?: number;
  /** 有效期开始 */
  validFrom: number;
  /** 有效期结束 */
  validTo: number;
  /** 状态 */
  status: CouponStatus;
  /** 适用范围描述 */
  scope: string;
}

/** 钱包信息（对齐设计稿 wallet.html qn-hero + qn-stat-card） */
export interface WalletInfo {
  /** 账户余额（元） */
  balance: number;
  /** 本月支出（元） */
  monthSpent: number;
  /** 累计优惠（元） */
  totalDiscount: number;
  /** 积分 */
  points: number;
  /** 可用优惠券数 */
  couponCount: number;
}

/** 钱包交易明细类型（对齐设计稿 qn-ico-* 彩色底） */
export type WalletTxIconTheme = 'red' | 'green' | 'blue' | 'yellow';

/** 钱包交易明细项（对齐设计稿 wallet.html qn-tx-row） */
export interface WalletTransaction {
  /** 交易 ID */
  txId: string;
  /** 图标主题色（红=消费/绿=充值/蓝=退款/黄=积分） */
  iconTheme: WalletTxIconTheme;
  /** 图标 emoji */
  icon: string;
  /** 交易标题 */
  title: string;
  /** 交易时间文案 */
  time: string;
  /** 金额（负数=支出，正数=收入） */
  amount: number;
  /** 是否整数（积分等无小数） */
  isInt: boolean;
}

/** 浏览历史项 */
export interface HistoryItem {
  historyId: string;
  productId: string;
  title: string;
  image: string;
  price: number;
  farmerName: string;
  /** 浏览时间 */
  viewedAt: number;
}

/** 个人中心功能项图标主题色（对齐设计稿 qn-ico-* 彩色底） */
export type ProfileIconTheme = 'yellow' | 'green' | 'blue' | 'red' | 'orange' | 'soft';

/** 个人中心功能项 */
export interface ProfileFunction {
  /** 功能 ID */
  funcId: string;
  /** 显示名称 */
  label: string;
  /** 图标 emoji */
  icon: string;
  /** 图标主题色（对齐设计稿 qn-ico-* 彩色底） */
  iconTheme: ProfileIconTheme;
  /** 跳转路由 */
  route: string;
  /** 角标数量（如优惠券数） */
  badge?: number;
}

/** 个人中心悬浮卡统计项（对齐设计稿 qn-stat-row） */
export interface ProfileStatItem {
  /** 数值 */
  num: number;
  /** 标签 */
  lab: string;
}

/** 个人中心统计信息（对齐设计稿 qn-profile-card） */
export interface ProfileStats {
  /** 关注数 */
  followCount: number;
  /** 粉丝数 */
  fansCount: number;
  /** 订单数 */
  orderCount: number;
  /** 积分 */
  points: number;
}

/** 个人中心等级信息（对齐设计稿 qn-level-pill） */
export interface ProfileLevel {
  /** 等级数字 */
  level: number;
  /** 等级名称 */
  title: string;
}

/** 设置项 */
export interface SettingItem {
  /** 设置项 ID */
  settingId: string;
  /** 显示名称 */
  label: string;
  /** 当前值文案 */
  valueText?: string;
  /** 跳转路由（无路由则纯展示） */
  route?: string;
  /** 是否带箭头 */
  hasArrow: boolean;
}
