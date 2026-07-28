/**
 * TravelMock - 文旅地图域 Mock 数据
 * 遵循 spec 3.1.4.3：百度地图 POI 检索（农家乐/乡村文旅/农庄/采摘园/民宿/景点/市集）
 * 设计稿对齐（travel-map.html / poi-detail.html / user-booking.html）：
 *  - POI 列表 6 条覆盖设计稿卡片展示
 *  - POI 详情包含 tags + bookable 字段
 *  - 新增体验预约 Mock（阳光采摘乐园 ¥58/人）
 * 现阶段前端 Mock，后端预留空接口（Phase 6 联调替换为真实 PoiSearch）
 */

import {
  PoiInfo,
  PoiCategory,
  PoiListParam,
  PoiListResult,
  BookingExperience,
  BookingDate,
  BookingSlot,
  BookingInclude,
  TravelRoute
} from '../model/TravelModels';

/** 支持的城市列表（Mock） */
export const MOCK_CITIES: string[] = ['北京', '上海', '杭州', '成都', '昆明', '西安'];

/**
 * POI Mock 数据（对齐设计稿 travel-map.html 6 个 POI Marker + poi-detail.html 详情）
 *  - coordinate.x/y 为 0-1 归一化坐标，渲染时乘以画布尺寸
 *  - images 引用本地资源 key（ImageUtil 解析）
 *  - tags 为详情页/预约页绿色 pill 标签
 */
export const MOCK_POIS: PoiInfo[] = [
  {
    poiId: 'poi001',
    name: '山田农庄',
    category: 'farm',
    coordinate: { x: 0.18, y: 0.30, lat: 30.3255, lng: 119.9520 },
    city: '杭州',
    district: '余杭区',
    address: '浙江省杭州市余杭区径山镇山田路1号',
    phone: '0571-88560001',
    rating: 4.8,
    ratingCount: 128,
    avgPrice: 88,
    distance: 2300,
    businessHours: '08:00-18:00',
    intro: '山田农庄占地200亩，集采摘、农事体验、民宿于一体，是余杭区重点扶持的助农示范项目。园内种植有草莓、番茄、茶叶等十余种应季果蔬，全程生态种植，可现采现摘。\n园区提供亲子农事课堂、手工制茶、田园餐桌等特色体验，支持团队定制与研学活动。所有收益按比例反哺当地农户，助力乡村振兴。',
    images: ['farm_picking', 'prod_fruit_1', 'prod_vegetable_1', 'prod_tea_1'],
    isFeatured: true,
    tags: ['农庄', '助农推荐'],
    bookable: true
  },
  {
    poiId: 'poi002',
    name: '金穗民宿',
    category: 'homestay',
    coordinate: { x: 0.72, y: 0.34, lat: 30.1860, lng: 120.0980 },
    city: '杭州',
    district: '西湖区',
    address: '浙江省杭州市西湖区龙坞茶镇金穗路8号',
    phone: '0571-87970002',
    rating: 4.9,
    ratingCount: 86,
    avgPrice: 128,
    distance: 3100,
    businessHours: '全天营业',
    intro: '金穗民宿坐落于龙井茶原产地龙坞茶镇，是茶文化主题精品民宿。提供茶园观光、采茶制茶体验、茶道课程等深度项目，让住客在茶香中感受宋韵文化。\n民宿共 12 间客房，均带独立茶席，含早晚餐。可定制茶艺沙龙、宋韵点茶、宋代服饰体验等增值服务。',
    images: ['hero_harvest', 'prod_tea_1', 'prod_vegetable_2', 'prod_honey_1'],
    isFeatured: true,
    tags: ['民宿', '茶文化'],
    bookable: true
  },
  {
    poiId: 'poi003',
    name: '桃源采摘园',
    category: 'picking_garden',
    coordinate: { x: 0.43, y: 0.48, lat: 30.1650, lng: 120.2880 },
    city: '杭州',
    district: '萧山区',
    address: '浙江省杭州市萧山区所前镇桃源基地',
    phone: '0571-82710003',
    rating: 4.7,
    ratingCount: 102,
    avgPrice: 68,
    distance: 4500,
    businessHours: '08:00-17:00',
    intro: '百亩桃园，6-9 月水蜜桃采摘季。入园免费，按斤计价。提供冷藏包装，可快递到家。\n园内还可采摘草莓、樱桃、葡萄等时令水果，配套农家午餐与儿童游乐区，是亲子出行的好去处。',
    images: ['live_orchard', 'prod_fruit_1', 'prod_fruit_2', 'prod_nut_1'],
    isFeatured: false,
    tags: ['采摘园', '亲子'],
    bookable: true
  },
  {
    poiId: 'poi004',
    name: '茶山人家',
    category: 'rural_tourism',
    coordinate: { x: 0.26, y: 0.60, lat: 30.2180, lng: 120.0750 },
    city: '杭州',
    district: '西湖区',
    address: '浙江省杭州市西湖区龙坞茶镇茶山路',
    phone: '0571-87970004',
    rating: 4.6,
    ratingCount: 64,
    avgPrice: 168,
    distance: 6800,
    businessHours: '08:30-20:00',
    intro: '茶山人家位于龙井茶原产地核心产区，可参观茶园、体验采茶制茶全过程，品鉴正宗西湖龙井。\n保留传统手工炒茶工艺，提供茶农民宿住宿与茶园餐厅，让游客深度体验宋代茶文化。',
    images: ['prod_tea_1', 'prod_vegetable_2', 'prod_honey_1', 'prod_dried_1'],
    isFeatured: false,
    tags: ['乡村文旅', '茶文化'],
    bookable: false
  },
  {
    poiId: 'poi005',
    name: '阳光生态农庄',
    category: 'farm',
    coordinate: { x: 0.67, y: 0.58, lat: 30.3520, lng: 119.9680 },
    city: '杭州',
    district: '余杭区',
    address: '浙江省杭州市余杭区径山镇阳光大道8号',
    phone: '0571-88560005',
    rating: 4.5,
    ratingCount: 56,
    avgPrice: 98,
    distance: 9200,
    businessHours: '09:00-18:00',
    intro: '集种植、养殖、餐饮、住宿于一体的综合农庄。主打有机蔬菜套餐，可认购菜地、亲子农耕体验。\n提供 CSA 社区支持农业会员服务，月度配送应季有机蔬菜到家，全程可追溯。',
    images: ['prod_vegetable_1', 'prod_rice_1', 'prod_egg_1', 'prod_corn_1'],
    isFeatured: false,
    tags: ['农庄', '有机'],
    bookable: true
  },
  {
    poiId: 'poi006',
    name: '古城农耕文化村',
    category: 'rural_tourism',
    coordinate: { x: 0.50, y: 0.66, lat: 30.2480, lng: 119.7250 },
    city: '杭州',
    district: '临安区',
    address: '浙江省杭州市临安区天目山镇古城村',
    phone: '0571-63720006',
    rating: 4.7,
    ratingCount: 71,
    avgPrice: 158,
    distance: 12500,
    businessHours: '08:00-19:00',
    intro: '千年古村落，保留传统农耕文化。可参观古农具展、体验传统酿酒、制茶工艺，入住明清古宅民宿。\n村落依山傍水，环境清幽，是远离都市喧嚣、感受乡愁文化的理想之地。',
    images: ['prod_tea_1', 'prod_dried_1', 'prod_mushroom_1', 'hero_harvest'],
    isFeatured: false,
    tags: ['乡村文旅', '古村'],
    bookable: false
  }
];

/**
 * 推荐路线 Mock 数据（spec 5.3.1：3 条主题路线演示）
 */
export const MOCK_ROUTES: TravelRoute[] = [
  {
    routeId: 'route001',
    title: '余杭生态采摘一日游',
    coverImage: 'farm_picking',
    poiIds: ['poi001', 'poi003', 'poi005'],
    poiNames: ['山田农庄', '桃源采摘园', '阳光生态农庄'],
    duration: '1天',
    price: 168,
    tags: ['采摘', '亲子', '生态'],
    description: '余杭径山生态采摘路线，串联山田农庄、桃源采摘园与阳光生态农庄，一日内体验有机采摘、农事课堂与田园午餐，适合亲子家庭出行。'
  },
  {
    routeId: 'route002',
    title: '龙坞茶文化体验游',
    coverImage: 'prod_tea_1',
    poiIds: ['poi002', 'poi004'],
    poiNames: ['金穗民宿', '茶山人家'],
    duration: '2天1夜',
    price: 388,
    tags: ['茶文化', '民宿', '深度体验'],
    description: '龙坞茶镇深度茶文化体验，入住金穗民宿品鉴龙井，次日探访茶山人家体验采茶制茶全过程，感受宋韵点茶与茶道课程。'
  },
  {
    routeId: 'route003',
    title: '临安古村落文化游',
    coverImage: 'hero_harvest',
    poiIds: ['poi006'],
    poiNames: ['古城农耕文化村'],
    duration: '1天',
    price: 128,
    tags: ['古村', '文化', '助农'],
    description: '临安天目山千年古村落文化游，参观古农具展、体验传统酿酒与制茶工艺，入住明清古宅民宿，助力乡村振兴。'
  }
];

/**
 * 体验预约 Mock 数据（对齐设计稿 user-booking.html：阳光采摘乐园 ¥58/人）
 */
export const MOCK_BOOKING: BookingExperience = {
  poiId: 'poi001',
  poiName: '阳光采摘乐园',
  coverImage: 'farm_picking',
  distanceText: '12km',
  tags: ['采摘', '亲子', '天然'],
  rating: 4.8,
  bookingCountText: '已预约 1.2万人次',
  pricePerPerson: 58,
  priceSubtitle: '含采摘体验+带走2斤',
  dateList: buildMockDateList(),
  slotList: [
    { slotId: 'morning', name: '上午', timeRange: '9:00-12:00' },
    { slotId: 'afternoon', name: '下午', timeRange: '14:00-17:00' },
    { slotId: 'fullday', name: '全天', timeRange: '9:00-17:00' }
  ],
  includeList: [
    { text: '草莓 / 小番茄自由采摘（限2斤）' },
    { text: '亲子农事体验课程' },
    { text: '农家特色午餐' },
    { text: '专属农场导览' }
  ],
  tips: '温馨提示：请穿着便装和运动鞋，建议自带防晒用品。如遇恶劣天气，农场将提前联系您改期或退款。'
};

/**
 * 构建未来 7 天的可选日期列表（对齐设计稿 qn-date-list 7 项）
 * 注：mock 数据动态生成，使用 2026-07-23 起的固定序列以保持与设计稿一致
 */
function buildMockDateList(): BookingDate[] {
  const list: BookingDate[] = [
    { dateId: '2026-07-23', weekLabel: '周四', dayLabel: '23', isToday: true },
    { dateId: '2026-07-24', weekLabel: '周五', dayLabel: '24', isToday: false },
    { dateId: '2026-07-25', weekLabel: '周六', dayLabel: '25', isToday: false },
    { dateId: '2026-07-26', weekLabel: '周日', dayLabel: '26', isToday: false },
    { dateId: '2026-07-27', weekLabel: '周一', dayLabel: '27', isToday: false },
    { dateId: '2026-07-28', weekLabel: '周二', dayLabel: '28', isToday: false },
    { dateId: '2026-07-29', weekLabel: '周三', dayLabel: '29', isToday: false }
  ];
  return list;
}

/**
 * 根据 ID 获取 POI 详情
 */
export function getMockPoiById(poiId: string): PoiInfo | null {
  const target: PoiInfo | undefined = MOCK_POIS.find((p: PoiInfo) => p.poiId === poiId);
  return target ?? null;
}

/**
 * 获取体验预约 Mock（按 POI ID）
 * 注：当前所有可预约 POI 共用同一份 Mock 数据；Phase 6 联调时按 poiId 拉取
 */
export function getMockBookingByPoiId(poiId: string): BookingExperience | null {
  const poi: PoiInfo | null = getMockPoiById(poiId);
  if (!poi || !poi.bookable) {
    return null;
  }
  // 复用统一 Mock 模板，按 POI 信息覆盖关键字段
  const booking: BookingExperience = {
    poiId: poi.poiId,
    poiName: poi.name,
    coverImage: poi.images.length > 0 ? poi.images[0] : 'farm_picking',
    distanceText: formatDistanceText(poi.distance),
    tags: poi.tags,
    rating: poi.rating,
    bookingCountText: `已预约 ${Math.floor(poi.ratingCount * 0.8)} 人次`,
    pricePerPerson: poi.avgPrice,
    priceSubtitle: '含采摘体验+带走2斤',
    dateList: buildMockDateList(),
    slotList: [
      { slotId: 'morning', name: '上午', timeRange: '9:00-12:00' },
      { slotId: 'afternoon', name: '下午', timeRange: '14:00-17:00' },
      { slotId: 'fullday', name: '全天', timeRange: '9:00-17:00' }
    ],
    includeList: MOCK_BOOKING.includeList,
    tips: MOCK_BOOKING.tips
  };
  return booking;
}

/** 格式化距离文案（米 → km） */
function formatDistanceText(distance: number): string {
  if (distance >= 1000) {
    return `${(distance / 1000).toFixed(1)}km`;
  }
  return `${distance}m`;
}

/**
 * 获取 POI 列表（Mock 分页）
 * 支持城市/类型/关键字筛选 + 多种排序
 */
export function getMockPoiList(param: PoiListParam): PoiListResult {
  let filtered: PoiInfo[] = MOCK_POIS.slice();
  if (param.city) {
    filtered = filtered.filter((p: PoiInfo) => p.city === param.city);
  }
  if (param.category) {
    filtered = filtered.filter((p: PoiInfo) => p.category === param.category);
  }
  if (param.keyword) {
    const kw: string = param.keyword;
    filtered = filtered.filter((p: PoiInfo) =>
      p.name.includes(kw) || p.district.includes(kw) || p.intro.includes(kw)
    );
  }
  // 排序
  switch (param.sortBy) {
    case 'distance':
      filtered.sort((a: PoiInfo, b: PoiInfo) => a.distance - b.distance);
      break;
    case 'rating':
      filtered.sort((a: PoiInfo, b: PoiInfo) => b.rating - a.rating);
      break;
    case 'price_asc':
      filtered.sort((a: PoiInfo, b: PoiInfo) => a.avgPrice - b.avgPrice);
      break;
    case 'price_desc':
      filtered.sort((a: PoiInfo, b: PoiInfo) => b.avgPrice - a.avgPrice);
      break;
    default:
      // 精选优先
      filtered.sort((a: PoiInfo, b: PoiInfo) => (b.isFeatured ? 1 : 0) - (a.isFeatured ? 1 : 0));
      break;
  }
  const start: number = (param.page - 1) * param.size;
  const end: number = start + param.size;
  const pageList: PoiInfo[] = filtered.slice(start, end);
  return {
    list: pageList,
    hasMore: end < filtered.length
  };
}
