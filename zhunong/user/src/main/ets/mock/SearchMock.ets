/**
 * SearchMock - 搜索/榜单/开屏广告 Mock 数据
 * 遵循 spec 3.1.1 搜索 / 3.1.2 双榜单 + 开屏广告规范
 */

import { HotWord, RankItem, SplashAd, SearchLiveItem, SearchPostItem, SearchFarmerItem,
  FarmerRankItem, GuideRankItem } from '../model/SearchModels';
import { MOCK_PRODUCTS, MOCK_FARMER_NAMES, MOCK_FARMER_AVATARS } from './ProductMock';

/** 热门搜索词 Top10（spec 3.1.1.2） */
export const MOCK_HOT_WORDS: HotWord[] = [
  { word: '有机蔬菜', hotScore: 9860, isNew: false },
  { word: '冰糖橙', hotScore: 8520, isNew: false },
  { word: '土鸡蛋', hotScore: 7890, isNew: false },
  { word: '五常大米', hotScore: 7260, isNew: true },
  { word: '土蜂蜜', hotScore: 6530, isNew: false },
  { word: '山核桃', hotScore: 5890, isNew: false },
  { word: '高山绿茶', hotScore: 5230, isNew: true },
  { word: '甜糯玉米', hotScore: 4860, isNew: false },
  { word: '红薯干', hotScore: 4320, isNew: false },
  { word: '小米辣', hotScore: 3890, isNew: true }
];

/** 月热销商品榜 Top10（spec 3.1.2.1，按 monthlyGmv 排序） */
export const MOCK_PRODUCT_RANK: RankItem[] = MOCK_PRODUCTS
  .slice()
  .sort((a, b) => b.monthlyGmv - a.monthlyGmv)
  .slice(0, 10)
  .map((p, idx): RankItem => ({
    rank: idx + 1,
    type: 'product',
    targetId: p.productId,
    title: p.title,
    coverImage: p.mainImages[0],
    sellerName: MOCK_FARMER_NAMES[p.farmerId] ?? '未知卖家',
    monthlyAmount: p.monthlyGmv,
    monthlyCount: p.monthlySales,
    followed: p.farmerId === 'f001' || p.farmerId === 'f003'
  }));

/** 月热销直播榜 Top10（spec 3.1.2.1，按月收入排序） */
export const MOCK_LIVE_RANK: RankItem[] = [
  { rank: 1, type: 'live', targetId: 'l001', title: '山间田园直播间·秋季丰收季', coverImage: 'splash_ad_2', sellerName: '田园牧歌', monthlyAmount: 128560, monthlyCount: 86420, followed: true },
  { rank: 2, type: 'live', targetId: 'l002', title: '青禾农场实地直播·蔬菜采摘', coverImage: 'prod_vegetable_1', sellerName: '青禾农庄', monthlyAmount: 98630, monthlyCount: 65820, followed: true },
  { rank: 3, type: 'live', targetId: 'l003', title: '高山茶艺直播·明前采茶', coverImage: 'prod_tea_1', sellerName: '青禾农庄', monthlyAmount: 78920, monthlyCount: 45630, followed: false },
  { rank: 4, type: 'live', targetId: 'l004', title: '海南果园直播·香蕉采摘', coverImage: 'prod_fruit_2', sellerName: '田园牧歌', monthlyAmount: 65230, monthlyCount: 38960, followed: false },
  { rank: 5, type: 'live', targetId: 'l005', title: '山野好物·土鸡蛋专场', coverImage: 'prod_egg_1', sellerName: '山野好物', monthlyAmount: 52360, monthlyCount: 32150, followed: false },
  { rank: 6, type: 'live', targetId: 'l006', title: '五常大米田头直播·新米上市', coverImage: 'prod_rice_1', sellerName: '青禾农庄', monthlyAmount: 45890, monthlyCount: 28960, followed: false },
  { rank: 7, type: 'live', targetId: 'l007', title: '临安山核桃采摘直播', coverImage: 'prod_nut_1', sellerName: '山野好物', monthlyAmount: 38620, monthlyCount: 23560, followed: false },
  { rank: 8, type: 'live', targetId: 'l008', title: '深山土蜂蜜采集纪实', coverImage: 'prod_honey_1', sellerName: '田园牧歌', monthlyAmount: 32560, monthlyCount: 19850, followed: false },
  { rank: 9, type: 'live', targetId: 'l009', title: '农家猪肉分割直播', coverImage: 'prod_meat_1', sellerName: '青禾农庄', monthlyAmount: 28960, monthlyCount: 16320, followed: false },
  { rank: 10, type: 'live', targetId: 'l010', title: '香菇采摘·神农架深山', coverImage: 'prod_mushroom_1', sellerName: '田园牧歌', monthlyAmount: 23560, monthlyCount: 12630, followed: false }
];

/** 农户榜 Top10（对齐设计稿 qn-rank-list[data-rank="farmer"]，按粉丝数排序） */
export const MOCK_FARMER_RANK: FarmerRankItem[] = [
  { rank: 1, farmerId: 'f003', farmerName: '田园牧歌 · 深山好物种植户', avatar: 'avatar_farmer_3', fansCount: 28690, goodRate: 99, followed: true },
  { rank: 2, farmerId: 'f001', farmerName: '青禾农庄 · 高山有机果蔬', avatar: 'avatar_farmer_1', fansCount: 12560, goodRate: 98, followed: true },
  { rank: 3, farmerId: 'f002', farmerName: '山野好物 · 农家散养户', avatar: 'avatar_farmer_2', fansCount: 8920, goodRate: 97, followed: false },
  { rank: 4, farmerId: 'f004', farmerName: '黑土地米业 · 五常稻农', avatar: 'avatar_default', fansCount: 6320, goodRate: 98, followed: false },
  { rank: 5, farmerId: 'f005', farmerName: '云雾山茶庄 · 高山茶农', avatar: 'avatar_default', fansCount: 4860, goodRate: 99, followed: false }
];

/** 攻略榜 Top10（对齐设计稿 qn-rank-list[data-rank="guide"]，按阅读数排序） */
export const MOCK_GUIDE_RANK: GuideRankItem[] = [
  { rank: 1, guideId: 'g001', title: '如何挑选新鲜草莓 · 产地老农教你三招', readCount: 12860, favoriteCount: 856 },
  { rank: 2, guideId: 'g002', title: '有机蔬菜种植指南 · 从零开始的家庭菜园', readCount: 8560, favoriteCount: 642 },
  { rank: 3, guideId: 'g003', title: '农家土鸡蛋辨别技巧 · 一看二摸三照', readCount: 6420, favoriteCount: 523 },
  { rank: 4, guideId: 'g004', title: '五常大米选购攻略 · 辨别真假稻花香', readCount: 4320, favoriteCount: 386 },
  { rank: 5, guideId: 'g005', title: '深山土蜂蜜冲泡指南 · 水温与禁忌', readCount: 3210, favoriteCount: 268 }
];

/** 开屏广告 Mock（spec 3.1.2.2：双榜#1 获得 1 个月免费开屏广告） */
export const MOCK_SPLASH_ADS: SplashAd[] = [
  {
    adId: 'ad001', rankType: 'product', targetId: 'p005',
    posterUrl: 'splash_ad_1', badge: '月热销商品榜 #1',
    sellerName: '田园牧歌', title: '冰糖橙 5斤'
  },
  {
    adId: 'ad002', rankType: 'live', targetId: 'l001',
    posterUrl: 'splash_ad_2', badge: '月热销直播榜 #1',
    sellerName: '田园牧歌', title: '山间田园直播间'
  }
];

/** 搜索联想词 Mock（spec 3.1.1.2：输入框防抖联想） */
export function getMockSearchSuggestions(keyword: string): string[] {
  if (keyword.length === 0) {
    return [];
  }
  const kw: string = keyword.toLowerCase();
  const allWords: string[] = MOCK_HOT_WORDS.map((h: HotWord) => h.word);
  allWords.push('有机青菜', '土猪肉', '红薯干', '甜糯玉米', '毛豆', '香菇');
  const matched: string[] = allWords.filter((w: string) => w.toLowerCase().indexOf(kw) >= 0);
  return matched.slice(0, 8);
}

/** 搜索直播结果 Mock（spec 3.1.1.2：直播 Tab） */
export function getMockSearchLiveResults(keyword: string): SearchLiveItem[] {
  const kw: string = keyword.toLowerCase();
  return MOCK_LIVE_RANK
    .filter((r: RankItem) => r.title.toLowerCase().indexOf(kw) >= 0 || r.sellerName.toLowerCase().indexOf(kw) >= 0)
    .slice(0, 5)
    .map((r: RankItem): SearchLiveItem => ({
      liveId: r.targetId,
      title: r.title,
      coverImage: r.coverImage,
      farmerName: r.sellerName,
      status: 'ended',
      totalViewUv: r.monthlyCount
    }));
}

/** 搜索帖子结果 Mock（spec 3.1.1.2：帖子 Tab） */
export function getMockSearchPostResults(keyword: string): SearchPostItem[] {
  const kw: string = keyword.toLowerCase();
  const allPosts: SearchPostItem[] = [
    { postId: 'post001', title: '有机蔬菜种植经验分享', authorName: '田园小厨', authorAvatar: 'avatar_default', likeCount: 856, commentCount: 124, coverImage: 'prod_vegetable_1', createdAt: 1737900000000 },
    { postId: 'post002', title: '冰糖橙的选购技巧', authorName: '水果控', authorAvatar: 'avatar_default', likeCount: 632, commentCount: 89, coverImage: 'prod_fruit_1', createdAt: 1737800000000 },
    { postId: 'post003', title: '五常大米真假辨别方法', authorName: '米饭爱好者', authorAvatar: 'avatar_default', likeCount: 523, commentCount: 76, coverImage: 'prod_rice_1', createdAt: 1737700000000 },
    { postId: 'post004', title: '土蜂蜜冲泡最佳水温', authorName: '健康饮食家', authorAvatar: 'avatar_default', likeCount: 421, commentCount: 58, coverImage: 'prod_honey_1', createdAt: 1737600000000 }
  ];
  return allPosts.filter((p: SearchPostItem) => p.title.toLowerCase().indexOf(kw) >= 0 || p.authorName.toLowerCase().indexOf(kw) >= 0);
}

/** 搜索农户结果 Mock（spec 3.1.1.2：农户 Tab） */
export function getMockSearchFarmerResults(keyword: string): SearchFarmerItem[] {
  const kw: string = keyword.toLowerCase();
  const allFarmers: SearchFarmerItem[] = [
    { farmerId: 'f001', farmerName: '青禾农庄', avatar: 'avatar_farmer_1', shopIntro: '专注有机蔬菜种植，自有高山农场', fansCount: 12560, productCount: 18, certified: true, followed: true },
    { farmerId: 'f002', farmerName: '山野好物', avatar: 'avatar_farmer_2', shopIntro: '山间野味，农家直发', fansCount: 8920, productCount: 12, certified: false, followed: false },
    { farmerId: 'f003', farmerName: '田园牧歌', avatar: 'avatar_farmer_3', shopIntro: '深山好物，从田间到餐桌', fansCount: 28690, productCount: 24, certified: true, followed: true }
  ];
  return allFarmers.filter((f: SearchFarmerItem) => f.farmerName.toLowerCase().indexOf(kw) >= 0 || f.shopIntro.toLowerCase().indexOf(kw) >= 0);
}
