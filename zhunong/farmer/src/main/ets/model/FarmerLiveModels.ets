/**
 * FarmerLiveModels - 卖家端直播域数据模型（spec 4.1.4 / 4.1.14）
 * 与用户端直播模型结构对齐，便于后续业务互通
 */

import { LiveStatus } from 'common';

/** 直播实体（spec 4.1.4 Live） */
export interface Live {
  liveId: string;
  /** 主播卖家ID */
  farmerId: string;
  /** 直播标题 */
  title: string;
  /** 封面图 key */
  coverImage: string;
  /** 分类（生鲜/粮油/肉禽/茶饮/其他） */
  category: string;
  /** 开播介绍 */
  intro: string;
  /** 商品袋商品ID数组 */
  productBag: string[];
  /** 直播状态 */
  status: LiveStatus;
  /** 开始时间戳 */
  startTime?: number;
  /** 结束时间戳 */
  endTime?: number;
  /** 累计观看 UV */
  totalViewUv: number;
  /** 累计礼物收入（元） */
  totalGiftIncome: number;
  /** 累计订单收入（元） */
  totalOrderIncome: number;
  /** 当月收入（用于榜单） */
  monthlyIncome: number;
  createdAt: number;
}

/** 直播列表项（精简，用于浏览页） */
export interface LiveListItem {
  liveId: string;
  title: string;
  coverImage: string;
  /** 主播昵称 */
  farmerName: string;
  /** 主播头像 key */
  farmerAvatar: string;
  status: LiveStatus;
  /** 当前在线人数（living 时） */
  onlineCount?: number;
  /** 累计观看 UV */
  totalViewUv: number;
  /** 直播分类 */
  category: string;
}

/** 直播评论消息 */
export interface LiveComment {
  commentId: string;
  liveId: string;
  userId: string;
  nickname: string;
  avatar: string;
  content: string;
  createdAt: number;
}

/** 礼物（spec 4.1.14 Gift） */
export interface Gift {
  giftId: string;
  name: string;
  /** 礼物图标 emoji */
  icon: string;
  /** 金币价格 */
  price: number;
}

/** 送礼记录（spec 4.1.14 GiftRecord） */
export interface GiftRecord {
  recordId: string;
  liveId: string;
  senderId: string;
  receiverId: string;
  giftId: string;
  count: number;
  totalAmount: number;
  createdAt: number;
}

/** 直播列表排序方式 */
export type LiveSortBy = 'hot' | 'newest';
