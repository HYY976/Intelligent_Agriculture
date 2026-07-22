/**
 * LiveModels - 用户端直播域数据模型
 * 遵循 spec 4.1.4 直播实体定义、3.1.4.2 直播模块交互规范
 * 含直播/SKU商品袋/评论/礼物/礼物记录
 */

import { LiveStatus } from 'common';

/** 直播分类（spec 3.2.4.3 开播表单分类） */
export type LiveCategory = 'fresh' | 'grain' | 'meat' | 'tea' | 'other';

/** 直播评论（弹幕式） */
export interface LiveComment {
  commentId: string;
  liveId: string;
  /** 评论人 ID */
  userId: string;
  /** 评论人昵称 */
  nickname: string;
  /** 评论人头像 key */
  avatar: string;
  /** 评论内容（仅文字+表情） */
  content: string;
  /** 是否为自己发送（用于气泡左右区分） */
  isSelf: boolean;
  createdAt: number;
}

/** 直播礼物（spec 4.1.14 Gift） */
export interface LiveGift {
  giftId: string;
  /** 礼物名 */
  name: string;
  /** 礼物 emoji 图标（沿用现有 emoji 风格） */
  icon: string;
  /** 金币价格 */
  price: number;
  /** 特效动画类型 */
  animation: 'rose' | 'heart' | 'star' | 'splash' | 'firework';
}

/** 直播礼物记录（spec 4.1.14 GiftRecord） */
export interface LiveGiftRecord {
  recordId: string;
  liveId: string;
  senderId: string;
  senderNickname: string;
  receiverId: string;
  giftId: string;
  count: number;
  totalAmount: number;
  createdAt: number;
}

/** 直播间商品袋项（精简自 ProductListItem） */
export interface LiveBagItem {
  productId: string;
  title: string;
  mainImage: string;
  price: number;
  /** 在直播间的序号（1-based） */
  seq: number;
}

/** 直播实体（spec 4.1.4 Live） */
export interface LiveInfo {
  liveId: string;
  /** 主播卖家 ID */
  farmerId: string;
  /** 主播昵称 */
  anchorName: string;
  /** 主播头像 key */
  anchorAvatar: string;
  /** 是否已关注该主播 */
  isFollowing: boolean;
  /** 直播标题 */
  title: string;
  /** 封面图 key */
  coverImage: string;
  /** 直播分类 */
  category: LiveCategory;
  /** 开播介绍 */
  intro: string;
  /** 商品袋商品 ID 数组 */
  productBag: string[];
  /** 直播状态 */
  status: LiveStatus;
  /** 开始时间戳 */
  startTime?: number;
  /** 结束时间戳 */
  endTime?: number;
  /** 在线观看人数（living）/累计 UV（ended） */
  onlineCount: number;
  /** 累计观看 UV */
  totalViewUv: number;
  /** 累计礼物收入 */
  totalGiftIncome: number;
  /** 累计订单收入 */
  totalOrderIncome: number;
  /** 当月收入（榜单指标） */
  monthlyIncome: number;
  /** 点赞数 */
  likeCount: number;
  createdAt: number;
}

/** 直播列表项（与 LiveInfo 字段一致，用于列表渲染） */
export type LiveListItem = LiveInfo;

/** 直播列表查询参数 */
export interface LiveListParam {
  /** 状态筛选（undefined=全部） */
  status?: LiveStatus;
  /** 分类筛选 */
  category?: LiveCategory;
  /** 关键字 */
  keyword?: string;
  page: number;
  size: number;
}

/** 直播分类显示名（arkts-no-untyped-obj-literals：用 switch 函数替代 Record 字面量） */
export function getLiveCategoryLabel(category: LiveCategory): string {
  switch (category) {
    case 'fresh':
      return '生鲜';
    case 'grain':
      return '粮油';
    case 'meat':
      return '肉禽';
    case 'tea':
      return '茶饮';
    case 'other':
      return '其他';
    default:
      return '其他';
  }
}

/** 直播状态显示名 */
export function getLiveStatusLabel(status: LiveStatus): string {
  switch (status) {
    case 'preview':
      return '预告';
    case 'living':
      return '直播中';
    case 'ended':
      return '已结束';
    default:
      return '';
  }
}
