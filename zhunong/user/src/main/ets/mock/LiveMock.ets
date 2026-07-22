/**
 * LiveMock - 直播域 Mock 数据
 * 遵循 spec 4.1.4 / 3.1.4.2：直播浏览/直播间/商品袋/评论/礼物
 * 现阶段前端纯 Mock，后端预留空接口（spec 8.x）
 */

import { LiveInfo, LiveListItem, LiveComment, LiveGift, LiveGiftRecord, LiveBagItem, LiveCategory, LiveListParam } from '../model/LiveModels';
import { LiveStatus } from 'common';
import { ProductListItem } from '../model/ProductModels';

/** 直播列表分页结果 */
export interface LiveListResult {
  list: LiveListItem[];
  hasMore: boolean;
}

/** 主播昵称池 */
const ANCHOR_NAMES: string[] = ['山间农庄老李', '果园小妹', '稻香村阿强', '茶山姑娘', '草原牧人', '渔家大嫂'];

/** 直播 Mock 数据（8 个直播间，覆盖三状态+各分类） */
export const MOCK_LIVES: LiveInfo[] = [
  {
    liveId: 'l001',
    farmerId: 'f001',
    anchorName: ANCHOR_NAMES[0],
    anchorAvatar: 'avatar_farmer_1',
    isFollowing: false,
    title: '高山有机蔬菜直采 现摘现发',
    coverImage: 'prod_vegetable_1',
    category: 'fresh',
    intro: '今日清晨采摘，全程冷链，新鲜到家！下单立享9折。',
    productBag: ['p001', 'p004'],
    status: 'living',
    startTime: Date.now() - 1800000,
    onlineCount: 1286,
    totalViewUv: 5680,
    totalGiftIncome: 268.5,
    totalOrderIncome: 4520.8,
    monthlyIncome: 4789.3,
    likeCount: 8650,
    createdAt: Date.now() - 2000000
  },
  {
    liveId: 'l002',
    farmerId: 'f002',
    anchorName: ANCHOR_NAMES[1],
    anchorAvatar: 'avatar_farmer_2',
    isFollowing: true,
    title: '自家果园蜜桃开园啦 又大又甜',
    coverImage: 'prod_fruit_1',
    category: 'fresh',
    intro: '自家果园现摘蜜桃，皮薄汁多，5斤装限时特价。',
    productBag: ['p001'],
    status: 'living',
    startTime: Date.now() - 3600000,
    onlineCount: 856,
    totalViewUv: 3260,
    totalGiftIncome: 156.0,
    totalOrderIncome: 2860.0,
    monthlyIncome: 3016.0,
    likeCount: 4320,
    createdAt: Date.now() - 3800000
  },
  {
    liveId: 'l003',
    farmerId: 'f001',
    anchorName: ANCHOR_NAMES[2],
    anchorAvatar: 'avatar_farmer_3',
    isFollowing: false,
    title: '东北黑土地新米上市 软糯香甜',
    coverImage: 'prod_rice_1',
    category: 'grain',
    intro: '当季新稻，颗粒饱满，今晚8点准时开播，预约有礼！',
    productBag: ['p003'],
    status: 'preview',
    onlineCount: 0,
    totalViewUv: 0,
    totalGiftIncome: 0,
    totalOrderIncome: 0,
    monthlyIncome: 0,
    likeCount: 320,
    createdAt: Date.now() - 86400000
  },
  {
    liveId: 'l004',
    farmerId: 'f002',
    anchorName: ANCHOR_NAMES[3],
    anchorAvatar: 'avatar_farmer_1',
    isFollowing: true,
    title: '武夷山岩茶品鉴 老茶客专场',
    coverImage: 'prod_tea_1',
    category: 'tea',
    intro: '品鉴大红袍、肉桂、水仙，直播间专享8折。',
    productBag: ['p001', 'p004'],
    status: 'living',
    startTime: Date.now() - 900000,
    onlineCount: 432,
    totalViewUv: 1820,
    totalGiftIncome: 88.8,
    totalOrderIncome: 1280.0,
    monthlyIncome: 1368.8,
    likeCount: 2180,
    createdAt: Date.now() - 1100000
  },
  {
    liveId: 'l005',
    farmerId: 'f001',
    anchorName: ANCHOR_NAMES[4],
    anchorAvatar: 'avatar_farmer_2',
    isFollowing: false,
    title: '散养土鸡土鸡蛋专场 营养丰富',
    coverImage: 'prod_egg_1',
    category: 'meat',
    intro: '散养土鸡所产，蛋黄金黄饱满，破损包赔。',
    productBag: ['p002'],
    status: 'ended',
    startTime: Date.now() - 86400000,
    endTime: Date.now() - 79200000,
    onlineCount: 0,
    totalViewUv: 8650,
    totalGiftIncome: 520.0,
    totalOrderIncome: 8960.0,
    monthlyIncome: 9480.0,
    likeCount: 12680,
    createdAt: Date.now() - 90000000
  },
  {
    liveId: 'l006',
    farmerId: 'f002',
    anchorName: ANCHOR_NAMES[5],
    anchorAvatar: 'avatar_farmer_3',
    isFollowing: false,
    title: '长白山野生菌菇干货特产',
    coverImage: 'prod_mushroom_1',
    category: 'other',
    intro: '长白山野生采摘，自然晒干，炖汤鲜美。',
    productBag: ['p001'],
    status: 'living',
    startTime: Date.now() - 600000,
    onlineCount: 268,
    totalViewUv: 980,
    totalGiftIncome: 42.0,
    totalOrderIncome: 680.0,
    monthlyIncome: 722.0,
    likeCount: 860,
    createdAt: Date.now() - 800000
  },
  {
    liveId: 'l007',
    farmerId: 'f001',
    anchorName: ANCHOR_NAMES[0],
    anchorAvatar: 'avatar_farmer_1',
    isFollowing: true,
    title: '农家自榨菜籽油 古法压榨原香',
    coverImage: 'prod_dried_1',
    category: 'grain',
    intro: '自家菜籽古法压榨，无添加无勾兑，5L装限时特价。',
    productBag: ['p003', 'p004'],
    status: 'preview',
    onlineCount: 0,
    totalViewUv: 0,
    totalGiftIncome: 0,
    totalOrderIncome: 0,
    monthlyIncome: 0,
    likeCount: 180,
    createdAt: Date.now() - 43200000
  },
  {
    liveId: 'l008',
    farmerId: 'f002',
    anchorName: ANCHOR_NAMES[1],
    anchorAvatar: 'avatar_farmer_2',
    isFollowing: false,
    title: '秦岭土蜂蜜专场 百花蜜限时秒杀',
    coverImage: 'prod_honey_1',
    category: 'other',
    intro: '秦岭百花蜜，自然成熟，无浓缩无添加。',
    productBag: ['p001'],
    status: 'ended',
    startTime: Date.now() - 172800000,
    endTime: Date.now() - 165600000,
    onlineCount: 0,
    totalViewUv: 6320,
    totalGiftIncome: 380.0,
    totalOrderIncome: 5680.0,
    monthlyIncome: 6060.0,
    likeCount: 9860,
    createdAt: Date.now() - 180000000
  }
];

/** 礼物 Mock 数据（spec 4.1.14） */
export const MOCK_GIFTS: LiveGift[] = [
  { giftId: 'g001', name: '玫瑰', icon: '🌹', price: 1, animation: 'rose' },
  { giftId: 'g002', name: '爱心', icon: '❤️', price: 5, animation: 'heart' },
  { giftId: 'g003', name: '星星', icon: '⭐', price: 10, animation: 'star' },
  { giftId: 'g004', name: '烟花', icon: '🎆', price: 50, animation: 'firework' },
  { giftId: 'g005', name: '彩带', icon: '🎉', price: 20, animation: 'splash' },
  { giftId: 'g006', name: '麦穗', icon: '🌾', price: 8, animation: 'splash' }
];

/** 评论 Mock 模板 */
const COMMENT_TEMPLATES: string[] = [
  '主播讲得很详细，已下单！',
  '这个菜看起来很新鲜，多少钱一斤？',
  '关注啦，下次开播提醒我',
  '已收到货，质量很好，好评！',
  '主播发货快吗？',
  '直播间价格比店里便宜不少',
  '这米煮饭香不香？',
  '求链接，想买给爸妈',
  '主播声音真好听',
  '已加购物车，等下次活动下单'
];

/** 评论人昵称池 */
const COMMENT_NICKNAMES: string[] = ['小明', '阿芳', '老王', '吃货一枚', '乡下人', '城里客', '宝妈小李', '养生达人'];

/**
 * 生成本直播间 Mock 评论
 * @param liveId 直播 ID
 * @param count 评论数量
 */
export function getMockLiveComments(liveId: string, count: number): LiveComment[] {
  const comments: LiveComment[] = [];
  for (let i: number = 0; i < count; i++) {
    const nickname: string = COMMENT_NICKNAMES[i % COMMENT_NICKNAMES.length];
    const avatarKey: string = i % 2 === 0 ? 'avatar_farmer_1' : 'avatar_farmer_2';
    comments.push({
      commentId: `${liveId}_c${i + 1}`,
      liveId: liveId,
      userId: `u_mock_${i}`,
      nickname: nickname,
      avatar: avatarKey,
      content: COMMENT_TEMPLATES[i % COMMENT_TEMPLATES.length],
      isSelf: false,
      createdAt: Date.now() - (count - i) * 60000
    });
  }
  return comments;
}

/**
 * 根据直播 ID 获取详情
 */
export function getMockLiveById(liveId: string): LiveInfo | null {
  const target: LiveInfo | undefined = MOCK_LIVES.find((live: LiveInfo) => live.liveId === liveId);
  return target ?? null;
}

/**
 * 获取直播间商品袋（Mock：从 productBag 数组映射为 LiveBagItem）
 * 商品基础信息沿用商品 Mock 的少量字段（避免循环依赖 ProductMock，此处用最小字段）
 */
export function getMockLiveBag(liveId: string): LiveBagItem[] {
  const live: LiveInfo | null = getMockLiveById(liveId);
  if (!live) {
    return [];
  }
  const bag: LiveBagItem[] = [];
  live.productBag.forEach((pid: string, idx: number) => {
    // 简化 Mock：根据 pid 末位映射不同的商品图与价格
    const imageKey: string = `prod_${['vegetable_1', 'fruit_1', 'rice_1', 'egg_1', 'tea_1'][idx % 5]}`;
    const price: number = 9.9 + (idx % 5) * 10;
    bag.push({
      productId: pid,
      title: `直播间推荐商品 ${idx + 1}`,
      mainImage: imageKey,
      price: price,
      seq: idx + 1
    });
  });
  return bag;
}

/**
 * 切换关注状态（Mock 本地修改）
 */
export function toggleMockFollow(liveId: string): boolean {
  const live: LiveInfo | undefined = MOCK_LIVES.find((l: LiveInfo) => l.liveId === liveId);
  if (live) {
    live.isFollowing = !live.isFollowing;
    return live.isFollowing;
  }
  return false;
}

/**
 * 模拟送礼：增加礼物收入与当月收入
 * @returns 礼物记录
 */
export function sendMockGift(liveId: string, gift: LiveGift, count: number, senderNickname: string): LiveGiftRecord {
  const live: LiveInfo | null = getMockLiveById(liveId);
  const totalAmount: number = gift.price * count;
  if (live) {
    live.totalGiftIncome += totalAmount;
    live.monthlyIncome += totalAmount;
  }
  const record: LiveGiftRecord = {
    recordId: `gr_${Date.now()}`,
    liveId: liveId,
    senderId: 'u_self',
    senderNickname: senderNickname,
    receiverId: live ? live.farmerId : '',
    giftId: gift.giftId,
    count: count,
    totalAmount: totalAmount,
    createdAt: Date.now()
  };
  return record;
}

/**
 * 模拟点赞：累加点赞数
 */
export function likeMockLive(liveId: string): number {
  const live: LiveInfo | undefined = MOCK_LIVES.find((l: LiveInfo) => l.liveId === liveId);
  if (live) {
    live.likeCount += 1;
    return live.likeCount;
  }
  return 0;
}

/**
 * 获取直播列表（Mock 分页）
 * 优先返回 living 状态，其次 preview，最后 ended
 */
export function getMockLiveList(param: LiveListParam): LiveListResult {
  let filtered: LiveInfo[] = MOCK_LIVES.slice();
  if (param.status) {
    filtered = filtered.filter((l: LiveInfo) => l.status === param.status);
  }
  if (param.category) {
    filtered = filtered.filter((l: LiveInfo) => l.category === param.category);
  }
  if (param.keyword) {
    const kw: string = param.keyword;
    filtered = filtered.filter((l: LiveInfo) => l.title.includes(kw) || l.anchorName.includes(kw));
  }
  // 排序：living > preview > ended，同状态按 onlineCount/createdAt 降序
  const statusWeight = (status: LiveStatus): number => {
    switch (status) {
      case 'living': return 0;
      case 'preview': return 1;
      case 'ended': return 2;
      default: return 9;
    }
  };
  filtered.sort((a: LiveInfo, b: LiveInfo) => {
    const wa: number = statusWeight(a.status);
    const wb: number = statusWeight(b.status);
    if (wa !== wb) {
      return wa - wb;
    }
    return b.createdAt - a.createdAt;
  });
  const start: number = (param.page - 1) * param.size;
  const end: number = start + param.size;
  const pageList: LiveInfo[] = filtered.slice(start, end);
  return {
    list: pageList,
    hasMore: end < filtered.length
  };
}

/**
 * 获取直播榜 Top N（spec 3.1.2.1 月热销直播榜，按 monthlyIncome 降序）
 */
export function getMockLiveRank(topN: number): LiveListItem[] {
  const sorted: LiveInfo[] = MOCK_LIVES.slice().sort((a: LiveInfo, b: LiveInfo) => b.monthlyIncome - a.monthlyIncome);
  return sorted.slice(0, topN);
}
