/**
 * TravelModels - 用户端文旅地图域数据模型
 * 遵循 spec 3.1.4.3 文旅地图推荐模块、2.4.6.4 文旅地图页视觉规范
 * 含 POI 点位/图片/评分/坐标/营业信息
 *
 * 说明：百度地图 SDK（@bdmap/map + @bdmap/search）未在 oh_modules 中安装，
 * Phase 3 采用前端 Mock POI 数据 + 自绘地图视图，
 * 在 travel_map.ets 中预留 SDK 集成点，Phase 6 联调时替换为真实 MapComponent + PoiSearch。
 */

/** POI 类型（spec 3.1.4.3 检索关键字） */
export type PoiCategory = 'farmhouse' | 'rural_tourism' | 'farm' | 'picking_garden';

/** POI 坐标（mock 用归一化 x/y，0-1 区间；真实环境替换为经纬度） */
export interface PoiCoordinate {
  /** 经度（真实环境） / 归一化 x（mock 环境 0-1） */
  x: number;
  /** 纬度（真实环境） / 归一化 y（mock 环境 0-1） */
  y: number;
}

/** POI 点位实体 */
export interface PoiInfo {
  poiId: string;
  /** 点位名称 */
  name: string;
  /** 点位类型 */
  category: PoiCategory;
  /** 坐标 */
  coordinate: PoiCoordinate;
  /** 所在城市 */
  city: string;
  /** 所在区县 */
  district: string;
  /** 详细地址 */
  address: string;
  /** 电话 */
  phone: string;
  /** 评分（1-5） */
  rating: number;
  /** 评分人数 */
  ratingCount: number;
  /** 人均消费（元） */
  avgPrice: number;
  /** 距离当前位置（米） */
  distance: number;
  /** 营业时间 */
  businessHours: string;
  /** 简介 */
  intro: string;
  /** 图片 key 数组（轮播） */
  images: string[];
  /** 是否精选（推荐流置顶） */
  isFeatured: boolean;
}

/** POI 列表查询参数 */
export interface PoiListParam {
  /** 城市 */
  city: string;
  /** 类型筛选（undefined=全部） */
  category?: PoiCategory;
  /** 关键字 */
  keyword?: string;
  /** 排序方式 */
  sortBy: 'distance' | 'rating' | 'price_asc' | 'price_desc';
  page: number;
  size: number;
}

/** POI 列表分页结果 */
export interface PoiListResult {
  list: PoiInfo[];
  hasMore: boolean;
}

/** POI 分类显示名（arkts-no-untyped-obj-literals：用 switch 函数替代 Record 字面量） */
export function getPoiCategoryLabel(category: PoiCategory): string {
  switch (category) {
    case 'farmhouse':
      return '农家乐';
    case 'rural_tourism':
      return '乡村文旅';
    case 'farm':
      return '农庄';
    case 'picking_garden':
      return '采摘园';
    default:
      return '其他';
  }
}

/** POI 分类图标（emoji 风格，沿用现有约定） */
export function getPoiCategoryIcon(category: PoiCategory): string {
  switch (category) {
    case 'farmhouse':
      return '🏡';
    case 'rural_tourism':
      return '🏞️';
    case 'farm':
      return '🌾';
    case 'picking_garden':
      return '🍎';
    default:
      return '📍';
  }
}
