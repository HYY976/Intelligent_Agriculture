/**
 * TravelMock - 文旅地图域 Mock 数据
 * 遵循 spec 3.1.4.3：百度地图 POI 检索（农家乐/乡村文旅/农庄/采摘园）
 * 现阶段前端 Mock，后端预留空接口（Phase 6 联调替换为真实 PoiSearch）
 */

import { PoiInfo, PoiCategory, PoiListParam, PoiListResult } from '../model/TravelModels';

/** 支持的城市列表（Mock） */
export const MOCK_CITIES: string[] = ['北京', '上海', '杭州', '成都', '昆明', '西安'];

/** POI Mock 数据（覆盖4类型，含坐标/评分/图片） */
export const MOCK_POIS: PoiInfo[] = [
  {
    poiId: 'poi001',
    name: '云栖竹径农家乐',
    category: 'farmhouse',
    coordinate: { x: 0.25, y: 0.35 },
    city: '杭州',
    district: '西湖区',
    address: '杭州市西湖区梅灵南路云栖竹径内',
    phone: '0571-87969691',
    rating: 4.7,
    ratingCount: 1286,
    avgPrice: 128,
    distance: 3200,
    businessHours: '09:00-21:00',
    intro: '依山傍水的农家小院，主打土鸡煲、笋干烧肉、溪鱼三吃。可在果园采摘时令水果，体验农耕乐趣。',
    images: ['prod_fruit_1', 'prod_vegetable_1', 'prod_corn_1'],
    isFeatured: true
  },
  {
    poiId: 'poi002',
    name: '茶山人家乡村文旅',
    category: 'rural_tourism',
    coordinate: { x: 0.55, y: 0.22 },
    city: '杭州',
    district: '西湖区',
    address: '杭州市西湖区龙坞茶镇',
    phone: '0571-87970001',
    rating: 4.8,
    ratingCount: 856,
    avgPrice: 198,
    distance: 5800,
    businessHours: '08:30-20:00',
    intro: '龙井茶原产地，可参观茶园、体验采茶制茶全过程，品鉴正宗西湖龙井。提供茶文化主题民宿。',
    images: ['prod_tea_1', 'prod_fruit_2', 'prod_vegetable_2'],
    isFeatured: true
  },
  {
    poiId: 'poi003',
    name: '阳光生态农庄',
    category: 'farm',
    coordinate: { x: 0.72, y: 0.58 },
    city: '杭州',
    district: '余杭区',
    address: '杭州市余杭区径山镇阳光大道8号',
    phone: '0571-88560002',
    rating: 4.5,
    ratingCount: 632,
    avgPrice: 88,
    distance: 12500,
    businessHours: '09:00-18:00',
    intro: '集种植、养殖、餐饮、住宿于一体的综合农庄。主打有机蔬菜套餐，可认购菜地、亲子农耕体验。',
    images: ['prod_vegetable_1', 'prod_rice_1', 'prod_egg_1'],
    isFeatured: false
  },
  {
    poiId: 'poi004',
    name: '蜜桃采摘园',
    category: 'picking_garden',
    coordinate: { x: 0.38, y: 0.68 },
    city: '杭州',
    district: '萧山区',
    address: '杭州市萧山区所前镇蜜桃基地',
    phone: '0571-82710003',
    rating: 4.6,
    ratingCount: 1024,
    avgPrice: 60,
    distance: 18500,
    businessHours: '08:00-17:00',
    intro: '百亩桃园，6-9月水蜜桃采摘季。入园免费，按斤计价。提供冷藏包装，可快递到家。',
    images: ['prod_fruit_1', 'prod_fruit_2', 'prod_honey_1'],
    isFeatured: true
  },
  {
    poiId: 'poi005',
    name: '稻香村田园农家',
    category: 'farmhouse',
    coordinate: { x: 0.15, y: 0.55 },
    city: '杭州',
    district: '富阳区',
    address: '杭州市富阳区新登镇稻香村路',
    phone: '0571-63250004',
    rating: 4.4,
    ratingCount: 428,
    avgPrice: 108,
    distance: 25600,
    businessHours: '10:00-22:00',
    intro: '稻田环绕的农家餐厅，主打柴火饭、土灶炖菜。秋季可参与割稻体验，感受农耕文化。',
    images: ['prod_rice_1', 'prod_vegetable_2', 'prod_corn_1'],
    isFeatured: false
  },
  {
    poiId: 'poi006',
    name: '古城农耕文化文旅',
    category: 'rural_tourism',
    coordinate: { x: 0.62, y: 0.75 },
    city: '杭州',
    district: '临安区',
    address: '杭州市临安区天目山镇古城村',
    phone: '0571-63720005',
    rating: 4.7,
    ratingCount: 712,
    avgPrice: 168,
    distance: 38200,
    businessHours: '08:00-19:00',
    intro: '千年古村落，保留传统农耕文化。可参观古农具展、体验传统酿酒、制茶工艺，入住明清古宅民宿。',
    images: ['prod_tea_1', 'prod_dried_1', 'prod_mushroom_1'],
    isFeatured: false
  },
  {
    poiId: 'poi007',
    name: '山林生态采摘园',
    category: 'picking_garden',
    coordinate: { x: 0.82, y: 0.42 },
    city: '杭州',
    district: '桐庐县',
    address: '杭州市桐庐县分水镇山林路',
    phone: '0571-64330006',
    rating: 4.5,
    ratingCount: 386,
    avgPrice: 75,
    distance: 45800,
    businessHours: '08:30-17:30',
    intro: '山林果园，四季可采摘：春草莓、夏蓝莓、秋板栗、冬柑橘。提供农家午餐，可住宿过夜。',
    images: ['prod_fruit_2', 'prod_nut_1', 'prod_chili_1'],
    isFeatured: false
  },
  {
    poiId: 'poi008',
    name: '黑土有机农庄',
    category: 'farm',
    coordinate: { x: 0.45, y: 0.85 },
    city: '杭州',
    district: '建德市',
    address: '杭州市建德市杨村桥镇黑土农场',
    phone: '0571-64720007',
    rating: 4.6,
    ratingCount: 524,
    avgPrice: 98,
    distance: 52300,
    businessHours: '09:00-18:00',
    intro: '有机认证农场，主打有机蔬菜礼盒、散养土鸡蛋。可现场采购，可参观现代化大棚种植。',
    images: ['prod_vegetable_1', 'prod_egg_1', 'prod_bean_1'],
    isFeatured: true
  }
];

/**
 * 根据 ID 获取 POI 详情
 */
export function getMockPoiById(poiId: string): PoiInfo | null {
  const target: PoiInfo | undefined = MOCK_POIS.find((p: PoiInfo) => p.poiId === poiId);
  return target ?? null;
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
