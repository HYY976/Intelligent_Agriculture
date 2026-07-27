/**
 * FarmerModels - 农户卖家端数据模型
 * 遵循 spec 4.1.2 / 4.1.7 / 4.2.2 数据实体定义
 * 含卖家扩展信息/营收记录/提现/粉丝/直播管理/AI任务等
 */

import { ProductStatus, LiveStatus } from 'common';

/** 资质认证信息（spec 4.1.2 CertificationInfo） */
export interface CertificationInfo {
  /** 真实姓名 */
  realName: string;
  /** 身份证号 */
  idCardNo: string;
  /** 身份证正面图 key */
  idCardFrontImg: string;
  /** 身份证反面图 key */
  idCardBackImg: string;
  /** 农户资质图 key */
  farmerCertImg: string;
}

/** 资质认证状态（spec 4.1.2） */
export type CertificationStatus = 'pending' | 'approved' | 'rejected';

/** 卖家扩展信息（spec 4.1.2 FarmerProfile） */
export interface FarmerProfile {
  /** 卖家ID（关联 User.userId） */
  farmerId: string;
  /** 店铺名 */
  shopName: string;
  /** 店铺 Logo key */
  shopLogo: string;
  /** 店铺介绍 */
  shopIntro: string;
  /** 认证状态 */
  certificationStatus: CertificationStatus;
  /** 认证信息（已认证时返回） */
  certificationInfo?: CertificationInfo;
  /** 累计营收（元） */
  totalRevenue: number;
  /** 可提现余额（元） */
  availableBalance: number;
  /** 冻结金额（元） */
  frozenBalance: number;
  /** 关注数 */
  followCount: number;
  /** 粉丝数 */
  fansCount: number;
  /** 本月新增粉丝数（对齐设计稿 fans-list.html 顶部统计条） */
  monthlyNewFans: number;
  /** 粉丝互动率（百分比，0-100，对齐设计稿 fans-list.html 顶部统计条） */
  interactionRate: number;
}

/** 营收时间范围（spec 3.2.3.1） */
export type RevenueRange = 'today' | 'month' | 'year' | 'total';

/** 营收汇总（spec 3.2.3.1：今日/月/年/累计切换） */
export interface RevenueSummary {
  /** 营收金额（元） */
  amount: number;
  /** 订单数 */
  orderCount: number;
  /** 商品数 */
  productCount: number;
  /** 转化率（百分比） */
  conversionRate: number;
}

/** 营收记录类型（spec 4.1.7，对齐设计稿 revenue-detail/farmer-income：商品销售/直播打赏/体验预约/退款） */
export type RevenueType = 'order' | 'gift' | 'booking' | 'refund';

/** 营收记录状态（spec 4.1.7） */
export type RevenueRecordStatus = 'pending' | 'settled' | 'withdrawn';

/** 营收记录（spec 4.1.7 RevenueRecord） */
export interface RevenueRecord {
  recordId: string;
  farmerId: string;
  /** 关联订单ID */
  orderId: string;
  /** 子订单ID */
  subOrderId: string;
  /** 营收金额（元） */
  amount: number;
  /** 类型：订单/礼物 */
  type: RevenueType;
  /** 状态：待结算/已结算/已提现 */
  status: RevenueRecordStatus;
  /** 创建时间戳 */
  createdAt: number;
  /** 结算时间戳（确认收货后） */
  settledAt?: number;
  /** 买家昵称（明细列表展示用） */
  buyerNickname?: string;
  /** 商品名（明细列表展示用） */
  productTitle?: string;
}

/** 提现记录（spec 4.1.7 Withdrawal） */
export interface Withdrawal {
  withdrawalId: string;
  farmerId: string;
  /** 提现金额（元） */
  amount: number;
  /** 收款账号（Mock） */
  account: string;
  /** 状态（spec 9.3：确认收货即可提现，无审核） */
  status: 'completed';
  /** 创建时间戳 */
  createdAt: number;
}

/** 日营收统计（spec 4.2.2 DailyRevenue，营收统计页折线图用） */
export interface DailyRevenue {
  /** 日期 YYYY-MM-DD */
  date: string;
  farmerId: string;
  /** 订单数 */
  orderCount: number;
  /** 营收金额（元） */
  revenue: number;
  /** 退款金额（元） */
  refundAmount: number;
}

/** 卖家商品管理项（spec 3.2.4.5：商品列表+上下架+编辑+删除） */
export interface FarmerProductItem {
  productId: string;
  title: string;
  /** 主图 key */
  mainImage: string;
  /** 价格（元） */
  price: number;
  /** 库存 */
  stock: number;
  /** 月销量 */
  monthlySales: number;
  /** 月销售额（元） */
  monthlyGmv: number;
  /** 商品状态（spec 4.1.3） */
  status: ProductStatus;
  /** 驳回原因（rejected 时返回） */
  rejectReason?: string;
  /** 创建时间戳 */
  createdAt: number;
  /** spec 16.10：类目 ID（用于搜索精准匹配） */
  categoryId?: string;
}

/** 直播管理项（spec 3.2.4.5：历史直播列表+数据统计） */
export interface LiveManageItem {
  liveId: string;
  /** 直播标题 */
  title: string;
  /** 封面图 key */
  coverImage: string;
  /** 分类（生鲜/粮油/肉禽/茶饮/其他） */
  category: string;
  /** 直播状态（spec 4.1.4） */
  status: LiveStatus;
  /** 开始时间戳 */
  startTime?: number;
  /** 结束时间戳 */
  endTime?: number;
  /** 累计观看 UV */
  totalViewUv: number;
  /** 累计礼物收入（元） */
  totalGiftIncome: number;
  /** 累计订单收入（元） */
  totalOrderIncome: number;
}

/** 粉丝信息（spec 3.2.4.5：粉丝列表） */
export interface FanInfo {
  /** 粉丝用户ID */
  userId: string;
  /** 粉丝昵称 */
  nickname: string;
  /** 粉丝头像 key */
  avatar: string;
  /** 关注时间戳 */
  followedAt: number;
  /** 是否互相关注（卖家也关注了该粉丝） */
  isMutual: boolean;
  /** 是否本月新增（用于本月新增统计） */
  isNew: boolean;
}

/** 直播分类枚举（spec 3.2.4.3 开播表单） */
export type LiveCategory = 'fresh' | 'grain' | 'meat' | 'tea' | 'other';

/** 开播表单字段（spec 3.2.4.3） */
export interface LiveCreateForm {
  /** 直播标题（必填） */
  title: string;
  /** 直播封面图 key（必填） */
  coverImage: string;
  /** 商品袋商品ID数组（可选） */
  productBag: string[];
  /** 直播分类（必填） */
  category: LiveCategory;
  /** 开播介绍（可选，200字内） */
  intro: string;
}

/** 商品上架表单（spec 3.2.2） */
export interface ProductPublishForm {
  /** 商品标题（5-60字） */
  title: string;
  /** 末级分类ID */
  categoryId: string;
  /** 主图 key 数组（最多9张） */
  mainImages: string[];
  /** 价格（元） */
  price: number;
  /** 库存 */
  stock: number;
  /** SKU 列表（可选） */
  skuList: FarmerSkuInput[];
  /** 商品详情富文本 */
  description: string;
  /** 发货地（省/市/区） */
  shipFrom: string;
  /** 运费模板 */
  freightTemplate: string;
  /** 上架状态：立即上架/放入仓库 */
  publishNow: boolean;
  /** AI 海报 URL（生成后填充） */
  aiPosterUrl?: string;
}

/** SKU 规格项（规格名 + 规格值） */
export interface FarmerSkuSpec {
  /** 规格名（如：重量） */
  name: string;
  /** 规格值（如：500g） */
  value: string;
}

/** 分页结果通用结构（列表 + 总数 + 是否还有更多） */
export interface PaginatedResult<T> {
  /** 当前页数据列表 */
  list: T[];
  /** 总记录数 */
  total: number;
  /** 是否还有更多数据 */
  hasMore: boolean;
}

/** SKU 输入项（商品上架表单） */
export interface FarmerSkuInput {
  /** 规格组合 */
  specs: FarmerSkuSpec[];
  /** SKU 价格 */
  price: number;
  /** SKU 库存 */
  stock: number;
  /** SKU 编码 */
  skuCode: string;
}

/** 运费模板枚举（spec 3.2.2） */
export type FreightTemplate = 'free' | 'by_piece' | 'by_weight';

/** 商品上架可选项 */
export interface PublishOption {
  /** 运费模板 */
  freight: FreightTemplate;
  /** 立即上架/放入仓库 */
  publishNow: boolean;
}

/** 营收明细筛选条件（spec 3.2.3.3） */
export interface RevenueFilter {
  /** 时间范围 */
  range: RevenueRange;
  /** 状态筛选（已付款/已结算/提现中/已提现） */
  status?: RevenueRecordStatus;
  /** 页码 */
  page: number;
  /** 每页条数 */
  size: number;
}

/** 营收统计图表点（折线图） */
export interface RevenueChartPoint {
  /** X 轴标签（日期/月份） */
  label: string;
  /** Y 轴值（金额） */
  value: number;
}

/** 收入构成项（对齐设计稿 farmer-income 收入构成环形图） */
export interface IncomeComposition {
  /** 类型 key */
  type: RevenueType;
  /** 类型文案 */
  label: string;
  /** 金额（元） */
  amount: number;
  /** 百分比（0-100） */
  percent: number;
  /** 图例色（#RRGGBB） */
  color: string;
}

/** 收入趋势点（对齐设计稿 farmer-income 7天折线图） */
export interface IncomeTrendPoint {
  /** X 轴标签（周一/周二...） */
  label: string;
  /** 金额（元） */
  value: number;
  /** 是否今日（高亮） */
  isToday: boolean;
}

/** 营收统计维度（spec 3.2.4.5：按日/月/年） */
export type RevenueStatsDimension = 'day' | 'month' | 'year';

/** 时段切换（对齐设计稿 farmer-income：7天/30天/全年） */
export type IncomeSegment = '7d' | '30d' | 'year';

/** 直播分类文案映射 */
export const LIVE_CATEGORY_LABELS: Record<LiveCategory, string> = {
  'fresh': '生鲜',
  'grain': '粮油',
  'meat': '肉禽',
  'tea': '茶饮',
  'other': '其他'
};

/** 营收时间范围文案映射 */
export const REVENUE_RANGE_LABELS: Record<RevenueRange, string> = {
  'today': '今日营收',
  'month': '本月营收',
  'year': '本年营收',
  'total': '累计营收'
};

/** 营收记录状态文案映射 */
export const REVENUE_STATUS_LABELS: Record<RevenueRecordStatus, string> = {
  'pending': '待结算',
  'settled': '已结算',
  'withdrawn': '已提现'
};

/** 营收类型文案映射（对齐设计稿：商品销售/直播打赏/体验预约/退款） */
export const REVENUE_TYPE_LABELS: Record<RevenueType, string> = {
  'order': '商品销售',
  'gift': '直播打赏',
  'booking': '体验预约',
  'refund': '退款'
};

/** 商品状态文案映射 */
export const PRODUCT_STATUS_LABELS: Record<ProductStatus, string> = {
  'draft': '仓库中',
  'pending_review': '待审核',
  'approved': '已上架',
  'rejected': '已驳回',
  'off_shelf': '已下架'
};

/** 直播状态文案映射 */
export const LIVE_STATUS_LABELS: Record<LiveStatus, string> = {
  'preview': '预告',
  'living': '直播中',
  'ended': '已结束'
};
