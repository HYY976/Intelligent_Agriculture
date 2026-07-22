/**
 * SplashAdInfo - 开屏广告信息模型
 * 遵循 spec 4.1.9：
 *  - 双榜#1同时获得时，左右滑动方式展示两个海报
 *  - rankType: product=月热销商品榜#1, live=月热销直播榜#1
 */

export interface SplashAdInfo {
  /** 广告ID */
  adId: string;
  /** 海报图片URL（AI海报URL，未生成时使用商品首图+肩带兜底） */
  posterUrl: string;
  /** 榜单类型：product=商品榜 / live=直播榜 */
  rankType: 'product' | 'live';
  /** 跳转目标URL（商品详情/直播间） */
  targetUrl: string;
  /** 关联商品ID（rankType=product时） */
  productId?: string;
  /** 关联直播ID（rankType=live时） */
  liveId?: string;
}
