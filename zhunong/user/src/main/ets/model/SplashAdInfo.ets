/**
 * SplashAdInfo - 开屏广告数据模型（spec 4.1.9）
 * 用于 splash_ad.ets 局部引用，避免直接依赖 common 包外模型
 */

export interface SplashAdInfo {
  adId: string;
  month: string;
  rankType: 'product' | 'live';
  farmerId: string;
  productId?: string;
  liveId?: string;
  posterUrl: string;
  targetUrl: string;
  rank: number;
  startDate: number;
  endDate: number;
}
