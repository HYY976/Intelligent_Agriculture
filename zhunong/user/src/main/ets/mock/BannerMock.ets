/**
 * BannerMock - 首页 Banner 轮播 Mock 数据
 * 遵循 spec 2.4.6.6 / 10.2：首页 Banner 轮播（营销活动 / 榜单入口）
 * 现阶段纯 Mock，Phase 6 联调时由 Repository 层替换为 GET /api/home/banner
 */

/** Banner 主题色（对应全局配色规范 spec 2.3.2，仅使用资源调色板内色值，禁止硬编码） */
export type BannerTheme = 'green' | 'orange' | 'gold' | 'red' | 'lightgreen';

/** Banner 跳转类型 */
export type BannerLinkType = 'category' | 'live' | 'travel' | 'rank' | 'none';

/** Banner 数据项 */
export interface BannerItem {
  /** Banner 唯一 ID */
  bannerId: string;
  /** 主标题 */
  title: string;
  /** 副标题 */
  subtitle: string;
  /** 主题色（映射到资源调色板） */
  theme: BannerTheme;
  /** 跳转类型 */
  linkType: BannerLinkType;
  /** 跳转目标路由（含 query 参数） */
  linkUrl: string;
  /** 角标标签 */
  tag: string;
}

/** 首页 Banner Mock 数据（5 张：营销活动 + 榜单入口） */
const MOCK_BANNERS: BannerItem[] = [
  {
    bannerId: 'b001',
    title: '时令生鲜直采',
    subtitle: '田间到餐桌 24 小时直达',
    theme: 'green',
    linkType: 'category',
    linkUrl: 'pages/mall/category_list?categoryId=fresh',
    tag: '热销'
  },
  {
    bannerId: 'b002',
    title: '月度热销商品榜',
    subtitle: '榜单 #1 享免费开屏广告',
    theme: 'orange',
    linkType: 'rank',
    linkUrl: 'pages/search/search_result?rank=product',
    tag: '榜单'
  },
  {
    bannerId: 'b003',
    title: '智农直播季',
    subtitle: '原产地直播 限时特价',
    theme: 'red',
    linkType: 'live',
    linkUrl: 'pages/live/live_list',
    tag: '直播'
  },
  {
    bannerId: 'b004',
    title: '乡村文旅精选',
    subtitle: '农家乐 · 采摘园 · 乡村游',
    theme: 'lightgreen',
    linkType: 'travel',
    linkUrl: 'pages/travel/travel_map',
    tag: '文旅'
  },
  {
    bannerId: 'b005',
    title: '粮油调味专区',
    subtitle: '生态粮油 健康好味道',
    theme: 'gold',
    linkType: 'category',
    linkUrl: 'pages/mall/category_list?categoryId=grain',
    tag: '专区'
  }
];

/** 获取首页 Banner Mock 数据 */
export function getMockBanners(): BannerItem[] {
  return MOCK_BANNERS;
}
