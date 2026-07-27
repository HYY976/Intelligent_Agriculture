/**
 * FarmerLiveMock - 卖家端直播域 Mock 数据（spec 4.1.4）
 * 与用户端 LiveMock 结构对齐，便于业务互通
 */

import { Live, LiveListItem, LiveComment, Gift, LiveSortBy } from '../model/FarmerLiveModels';
import { PaginatedResult } from '../model/FarmerModels';

/** 直播列表 Mock（含 living/preview/ended 三种状态） */
export const MOCK_LIVE_LIST: LiveListItem[] = [
  {
    liveId: 'l001', title: '高山有机青菜采摘直播', coverImage: 'live_cover_1',
    farmerName: '青禾农庄', farmerAvatar: 'avatar_farmer_1', status: 'ended',
    totalViewUv: 1286, category: 'fresh'
  },
  {
    liveId: 'l002', title: '当季新米品鉴专场', coverImage: 'live_cover_2',
    farmerName: '青禾农庄', farmerAvatar: 'avatar_farmer_1', status: 'ended',
    totalViewUv: 980, category: 'grain'
  },
  {
    liveId: 'l003', title: '明前嫩芽绿茶制作', coverImage: 'live_cover_3',
    farmerName: '青禾农庄', farmerAvatar: 'avatar_farmer_1', status: 'ended',
    totalViewUv: 658, category: 'tea'
  },
  {
    liveId: 'l004', title: '今晚8点·农家土鸡蛋直采', coverImage: 'live_cover_4',
    farmerName: '青禾农庄', farmerAvatar: 'avatar_farmer_1', status: 'preview',
    totalViewUv: 0, category: 'fresh'
  },
  {
    liveId: 'l005', title: '土蜂蜜采收直播', coverImage: 'live_cover_5',
    farmerName: '青禾农庄', farmerAvatar: 'avatar_farmer_1', status: 'living',
    onlineCount: 326, totalViewUv: 326, category: 'fresh'
  },
  {
    liveId: 'l006', title: '山野好物·散养土猪直播', coverImage: 'live_cover_6',
    farmerName: '山野好物', farmerAvatar: 'avatar_farmer_2', status: 'living',
    onlineCount: 186, totalViewUv: 568, category: 'meat'
  },
  {
    liveId: 'l007', title: '田园牧歌·果园采摘', coverImage: 'live_cover_7',
    farmerName: '田园牧歌', farmerAvatar: 'avatar_farmer_3', status: 'preview',
    totalViewUv: 0, category: 'fresh'
  },
  {
    liveId: 'l008', title: '山野好物·蜂蜜采收', coverImage: 'live_cover_8',
    farmerName: '山野好物', farmerAvatar: 'avatar_farmer_2', status: 'ended',
    totalViewUv: 856, category: 'tea'
  },
  // spec 16.5：扩充直播 Mock 数据，丰富浏览页内容
  {
    liveId: 'l009', title: '现磨面粉·古法石磨工艺展示', coverImage: 'live_cover_9',
    farmerName: '麦香坊', farmerAvatar: 'avatar_farmer_4', status: 'living',
    onlineCount: 412, totalViewUv: 412, category: 'grain'
  },
  {
    liveId: 'l010', title: '高山散养土鸡·林间觅食实况', coverImage: 'live_cover_10',
    farmerName: '田园牧歌', farmerAvatar: 'avatar_farmer_3', status: 'living',
    onlineCount: 258, totalViewUv: 258, category: 'meat'
  },
  {
    liveId: 'l011', title: '雨前龙井·手工炒制直播', coverImage: 'live_cover_11',
    farmerName: '云雾茶舍', farmerAvatar: 'avatar_farmer_5', status: 'preview',
    totalViewUv: 0, category: 'tea'
  },
  {
    liveId: 'l012', title: '时令草莓园·亲子采摘体验', coverImage: 'live_cover_12',
    farmerName: '红果乐园', farmerAvatar: 'avatar_farmer_6', status: 'living',
    onlineCount: 528, totalViewUv: 528, category: 'fresh'
  },
  {
    liveId: 'l013', title: '深山野生菌·采摘过程全纪录', coverImage: 'live_cover_13',
    farmerName: '山野好物', farmerAvatar: 'avatar_farmer_2', status: 'ended',
    totalViewUv: 1432, category: 'other'
  },
  {
    liveId: 'l014', title: '有机蔬菜礼盒·产地直发专场', coverImage: 'live_cover_14',
    farmerName: '青禾农庄', farmerAvatar: 'avatar_farmer_1', status: 'preview',
    totalViewUv: 0, category: 'fresh'
  },
  {
    liveId: 'l015', title: '古法红糖·甘蔗熬制工艺', coverImage: 'live_cover_15',
    farmerName: '甜蜜坊', farmerAvatar: 'avatar_farmer_7', status: 'ended',
    totalViewUv: 720, category: 'other'
  },
  {
    liveId: 'l016', title: '生态大米·稻田收割直播', coverImage: 'live_cover_16',
    farmerName: '金穗农场', farmerAvatar: 'avatar_farmer_8', status: 'living',
    onlineCount: 196, totalViewUv: 196, category: 'grain'
  }
];

/** 礼物列表 Mock（spec 4.1.14 Gift） */
export const MOCK_GIFTS: Gift[] = [
  { giftId: 'g001', name: '小红花', icon: '🌹', price: 1 },
  { giftId: 'g002', name: '麦穗', icon: '🌾', price: 5 },
  { giftId: 'g003', name: '胡萝卜', icon: '🥕', price: 10 },
  { giftId: 'g004', name: '玉米', icon: '🌽', price: 20 },
  { giftId: 'g005', name: '南瓜', icon: '🎃', price: 50 },
  { giftId: 'g006', name: '果篮', icon: '🧺', price: 99 },
  { giftId: 'g007', name: '田园', icon: '🏡', price: 188 },
  { giftId: 'g008', name: '丰收', icon: '🏆', price: 520 }
];

/** 直播评论 Mock（spec 4.1.5 评论） */
export const MOCK_LIVE_COMMENTS: LiveComment[] = [
  {
    commentId: 'c001', liveId: 'l005', userId: 'u001', nickname: '小马哥', avatar: 'avatar_user_1',
    content: '主播这蜂蜜看起来真不错', createdAt: 1737180000000
  },
  {
    commentId: 'c002', liveId: 'l005', userId: 'u002', nickname: '阿芳', avatar: 'avatar_user_2',
    content: '想买一罐尝尝', createdAt: 1737180060000
  },
  {
    commentId: 'c003', liveId: 'l005', userId: 'u003', nickname: '阿强', avatar: 'avatar_user_3',
    content: '蜂巢看着好新鲜', createdAt: 1737180120000
  },
  {
    commentId: 'c004', liveId: 'l005', userId: 'u004', nickname: '小雨', avatar: 'avatar_user_4',
    content: '什么时候发货呢', createdAt: 1737180180000
  },
  {
    commentId: 'c005', liveId: 'l005', userId: 'u005', nickname: '王老板', avatar: 'avatar_user_5',
    content: '产地是哪里呀', createdAt: 1737180240000
  }
];

/**
 * 直播列表分页 Mock
 */
export function getMockLiveList(
  page: number,
  size: number,
  sortBy: LiveSortBy = 'hot'
): PaginatedResult<LiveListItem> {
  let sorted: LiveListItem[] = MOCK_LIVE_LIST.slice();
  if (sortBy === 'hot') {
    sorted.sort((a: LiveListItem, b: LiveListItem): number => b.totalViewUv - a.totalViewUv);
  } else {
    sorted.sort((a: LiveListItem, b: LiveListItem): number => {
      // 简化：living > preview > ended
      const order: Record<string, number> = { 'living': 0, 'preview': 1, 'ended': 2 };
      return order[a.status] - order[b.status];
    });
  }
  const total: number = sorted.length;
  const start: number = (page - 1) * size;
  const list: LiveListItem[] = sorted.slice(start, start + size);
  return { list, total, hasMore: start + size < total };
}

/**
 * 直播评论 Mock 取数
 */
export function getMockLiveComments(liveId: string): LiveComment[] {
  return MOCK_LIVE_COMMENTS.filter((c: LiveComment): boolean => c.liveId === liveId);
}

/**
 * 礼物列表 Mock
 */
export function getMockGifts(): Gift[] {
  return MOCK_GIFTS;
}
