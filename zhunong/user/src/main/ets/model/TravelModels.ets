/**
 * TravelModels - 用户端文旅地图域数据模型
 * 遵循 spec 3.1.4.3 文旅地图推荐模块、2.4.6.4 文旅地图页视觉规范
 * 含 POI 点位/图片/评分/坐标/营业信息 + 体验预约模型
 *
 * 设计稿对齐（qunong-harmony-app/pages/travel-map.html + poi-detail.html + user-booking.html）：
 *  - POI 分类扩展为 6 类（农庄/民宿/景点/采摘园/市集 + 农家乐兜底）
 *  - POI 卡片字段对齐设计稿：rating/dist/price 元信息行
 *  - 新增 BookingExperience 体验预约模型（日期/时段/人数/联系人/体验包含）
 *
 * 说明：百度地图 SDK（@bdmap/map + @bdmap/search）未在 oh_modules 中安装，
 * Phase 3 采用前端 Mock POI 数据 + 自绘地图视图，
 * 在 travel_map.ets 中预留 SDK 集成点，Phase 6 联调时替换为真实 MapComponent + PoiSearch。
 */

/** POI 类型（spec 3.1.4.3 检索关键字 + 设计稿 6 类胶囊） */
export type PoiCategory =
  | 'farmhouse'      // 农家乐
  | 'rural_tourism'  // 乡村文旅
  | 'farm'           // 农庄
  | 'picking_garden' // 采摘园
  | 'homestay'       // 民宿
  | 'sightspot'      // 景点
  | 'market';        // 市集

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
  /** 标签文案数组（对齐设计稿 qn-pill-green 多标签：采摘/亲子/天然 等） */
  tags: string[];
  /** 是否提供体验预约（true 时 POI 详情显示"立即预约"按钮） */
  bookable: boolean;
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

/** 时段选项（对齐设计稿 qn-slot-row：上午/下午/全天） */
export interface BookingSlot {
  /** 时段 key */
  slotId: 'morning' | 'afternoon' | 'fullday';
  /** 时段名称 */
  name: string;
  /** 时段时间范围 */
  timeRange: string;
}

/** 体验包含项（对齐设计稿 qn-include-item） */
export interface BookingInclude {
  /** 包含项文案 */
  text: string;
}

/** 体验预约实体（对齐设计稿 user-booking.html） */
export interface BookingExperience {
  /** 关联 POI ID */
  poiId: string;
  /** 关联 POI 名称（英雄卡显示） */
  poiName: string;
  /** 封面图 key */
  coverImage: string;
  /** 距离文案（如 "12km"，对齐设计稿 qn-hero-dist） */
  distanceText: string;
  /** 标签数组（如 采摘/亲子/天然） */
  tags: string[];
  /** 评分（如 4.8） */
  rating: number;
  /** 已预约次数文案（如 "1.2万人次"） */
  bookingCountText: string;
  /** 起步单价（元/人） */
  pricePerPerson: number;
  /** 价格副标题（如 "含采摘体验+带走2斤"） */
  priceSubtitle: string;
  /** 可选日期列表（对齐设计稿 qn-date-list 未来 7 天） */
  dateList: BookingDate[];
  /** 可选时段列表 */
  slotList: BookingSlot[];
  /** 体验包含项列表 */
  includeList: BookingInclude[];
  /** 温馨提示（对齐设计稿 qn-tip-text） */
  tips: string;
}

/** 预约日期（对齐设计稿 qn-date） */
export interface BookingDate {
  /** 日期 key（如 '2026-07-25'） */
  dateId: string;
  /** 星期短名（如 "周五"） */
  weekLabel: string;
  /** 日号（如 "25"） */
  dayLabel: string;
  /** 是否今天 */
  isToday: boolean;
}

/** 预约提交参数 */
export interface BookingSubmitParam {
  poiId: string;
  dateId: string;
  slotId: 'morning' | 'afternoon' | 'fullday';
  peopleCount: number;
  contactName: string;
  contactPhone: string;
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
    case 'homestay':
      return '民宿';
    case 'sightspot':
      return '景点';
    case 'market':
      return '市集';
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
    case 'homestay':
      return '🏠';
    case 'sightspot':
      return '🏔️';
    case 'market':
      return '🛒';
    default:
      return '📍';
  }
}
