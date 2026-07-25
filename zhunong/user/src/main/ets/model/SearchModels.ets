/**
 * SearchModels - 用户端搜索/榜单/开屏广告域数据模型
 * 遵循 spec 3.1.1 搜索 / 3.1.2 双榜单 + 开屏广告规范
 */

/** 搜索历史项 */
export interface SearchHistoryItem {
  keyword: string;
  /** 搜索时间 */
  searchedAt: number;
}

/** 热门搜索词 */
export interface HotWord {
  word: string;
  /** 热度（用于排序） */
  hotScore: number;
  /** 是否新晋热词 */
  isNew: boolean;
}

/** 榜单类型（对齐设计稿 search.html：4 Tab 商品榜/直播榜/农户榜/攻略榜） */
export type RankType = 'product' | 'live' | 'farmer' | 'guide';

/** 榜单项（商品榜/直播榜通用） */
export interface RankItem {
  /** 排名（1-10） */
  rank: number;
  /** 榜单类型 */
  type: RankType;
  /** 关联 ID（productId 或 liveId） */
  targetId: string;
  /** 商品/直播标题 */
  title: string;
  /** 主图（商品首图或直播封面） */
  coverImage: string;
  /** 卖家/主播名 */
  sellerName: string;
  /** 月销售额（商品榜）/ 月收入（直播榜） */
  monthlyAmount: number;
  /** 月销量（商品榜）/ 累计观看 UV（直播榜） */
  monthlyCount: number;
  /** 是否当前用户关注 */
  followed?: boolean;
}

/** 农户榜单项（对齐设计稿 qn-rank-list[data-rank="farmer"]） */
export interface FarmerRankItem {
  /** 排名（1-10） */
  rank: number;
  /** 农户 ID */
  farmerId: string;
  /** 农户昵称（含品类描述，如 "王大姐 · 丹东草莓种植户"） */
  farmerName: string;
  /** 头像资源 key */
  avatar: string;
  /** 粉丝数 */
  fansCount: number;
  /** 好评率（0-100） */
  goodRate: number;
  /** 是否已关注 */
  followed: boolean;
}

/** 攻略榜单项（对齐设计稿 qn-rank-list[data-rank="guide"]） */
export interface GuideRankItem {
  /** 排名（1-10） */
  rank: number;
  /** 帖子/攻略 ID */
  guideId: string;
  /** 攻略标题 */
  title: string;
  /** 阅读数 */
  readCount: number;
  /** 收藏数 */
  favoriteCount: number;
}

/** 开屏广告 */
export interface SplashAd {
  adId: string;
  /** 榜单类型（决定点击跳转目标） */
  rankType: RankType;
  /** 关联 ID（productId 或 liveId） */
  targetId: string;
  /** 海报图 URL（优先 AI 海报，兜底商品首图） */
  posterUrl: string;
  /** 肩带文案（如：月热销#1） */
  badge: string;
  /** 卖家昵称 */
  sellerName: string;
  /** 商品/直播标题 */
  title: string;
}

/** 搜索结果 Tab */
export type SearchResultTab = 'product' | 'live' | 'post' | 'farmer';

/** 搜索结果中的直播项（Phase 2 仅 Mock，直播模块 Phase 3 实现） */
export interface SearchLiveItem {
  liveId: string;
  title: string;
  coverImage: string;
  farmerName: string;
  status: 'preview' | 'living' | 'ended';
  totalViewUv: number;
}

/** 搜索结果中的帖子项（Phase 2 仅 Mock，社区模块 Phase 3 实现） */
export interface SearchPostItem {
  postId: string;
  title: string;
  authorName: string;
  authorAvatar: string;
  likeCount: number;
  commentCount: number;
  coverImage?: string;
  createdAt: number;
}

/** 搜索结果中的农户项 */
export interface SearchFarmerItem {
  farmerId: string;
  farmerName: string;
  avatar: string;
  shopIntro: string;
  fansCount: number;
  productCount: number;
  certified: boolean;
  followed: boolean;
}
