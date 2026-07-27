/**
 * FarmerMock - 农户卖家端 Mock 数据
 * 遵循 spec 4.1.2 / 4.1.4 / 4.1.7 / 4.2.2 实体定义
 * 当前卖家身份固定为 f001（青禾农庄），便于营收/商品/直播管理数据展示
 * Phase 6 联调时由 Repository 层替换为真实 REST 数据
 */

import {
  FarmerProfile,
  RevenueSummary,
  RevenueRecord,
  Withdrawal,
  DailyRevenue,
  FarmerProductItem,
  LiveManageItem,
  FanInfo,
  RevenueRange,
  RevenueStatsDimension,
  RevenueChartPoint,
  IncomeComposition,
  IncomeTrendPoint,
  IncomeSegment,
  PaginatedResult
} from '../model/FarmerModels';

/** 当前卖家 ID（Mock 固定） */
export const MOCK_FARMER_ID: string = 'f001';

/** 卖家信息（spec 4.1.2 FarmerProfile，对齐设计稿 farmer-home/withdraw：青禾农庄·王大叔 + V认证） */
export const MOCK_FARMER_PROFILE: FarmerProfile = {
  farmerId: 'f001',
  shopName: '青禾农庄·王大叔',
  shopLogo: 'avatar_farmer',
  shopIntro: '高山有机农场，无农药无化肥，专注品质生鲜。每周末直播采摘过程，欢迎关注！',
  certificationStatus: 'approved',
  certificationInfo: {
    realName: '王大叔',
    idCardNo: '530***********1234',
    idCardFrontImg: 'cert_id_front',
    idCardBackImg: 'cert_id_back',
    farmerCertImg: 'cert_farmer'
  },
  totalRevenue: 38560.00,
  availableBalance: 8680.50,
  frozenBalance: 1200.00,
  followCount: 28,
  fansCount: 186,
  monthlyNewFans: 86,
  interactionRate: 68
};

/** 营收汇总（按时间范围，spec 3.2.3.1，对齐设计稿 farmer-home：今日 ¥8,652.00 / 23笔 / 8件 / 12.5%） */
export const MOCK_REVENUE_SUMMARIES: Record<RevenueRange, RevenueSummary> = {
  'today': { amount: 8652.00, orderCount: 23, productCount: 8, conversionRate: 12.5 },
  'month': { amount: 12860.00, orderCount: 612, productCount: 8, conversionRate: 15.8 },
  'year': { amount: 458920.80, orderCount: 7823, productCount: 8, conversionRate: 14.2 },
  'total': { amount: 38560.00, orderCount: 21568, productCount: 8, conversionRate: 13.6 }
};

/** 收入构成（对齐设计稿 farmer-income 收入构成环形图：商品销售65% / 直播打赏22% / 体验预约13%） */
export const MOCK_INCOME_COMPOSITION: IncomeComposition[] = [
  { type: 'order', label: '商品销售', amount: 8359, percent: 65, color: '#7ED321' },
  { type: 'gift', label: '直播打赏', amount: 2829, percent: 22, color: '#FFD93D' },
  { type: 'booking', label: '体验预约', amount: 1672, percent: 13, color: '#C8C8C8' }
];

/** 收入趋势（对齐设计稿 farmer-income 7天折线图，今日 ¥1,286 高亮） */
export const MOCK_INCOME_TREND: IncomeTrendPoint[] = [
  { label: '周一', value: 428, isToday: false },
  { label: '周二', value: 486, isToday: false },
  { label: '周三', value: 392, isToday: false },
  { label: '周四', value: 568, isToday: false },
  { label: '周五', value: 502, isToday: false },
  { label: '周六', value: 645, isToday: false },
  { label: '今天', value: 1286, isToday: true }
];

/**
 * 收入构成 Mock 取数
 */
export function getMockIncomeComposition(): IncomeComposition[] {
  return MOCK_INCOME_COMPOSITION.slice();
}

/**
 * 收入趋势 Mock 取数（按时段切换）
 */
export function getMockIncomeTrend(segment: IncomeSegment): IncomeTrendPoint[] {
  if (segment === '7d') {
    return MOCK_INCOME_TREND.slice();
  }
  // 30天/全年简化返回 7 天数据（UI 一致，数值不同）
  return MOCK_INCOME_TREND.slice();
}

/** 营收记录列表（spec 4.1.7 RevenueRecord，spec 3.2.3.3 营收明细，对齐设计稿 revenue-detail.html 6 条记录） */
export const MOCK_REVENUE_RECORDS: RevenueRecord[] = [
  {
    recordId: 'r001', farmerId: 'f001', orderId: 'QN240618143022', subOrderId: 'so001',
    amount: 38.00, type: 'order', status: 'settled', createdAt: 1737185420000,
    settledAt: 1737185420000, buyerNickname: '李**', productTitle: '奶油草莓订单'
  },
  {
    recordId: 'r002', farmerId: 'f001', orderId: 'LIVE2406181315', subOrderId: 'so002',
    amount: 5.00, type: 'gift', status: 'settled', createdAt: 1737182100000,
    settledAt: 1737182100000, buyerNickname: '王**', productTitle: '直播打赏'
  },
  {
    recordId: 'r003', farmerId: 'f001', orderId: 'QN240618112033', subOrderId: 'so003',
    amount: 20.00, type: 'order', status: 'pending', createdAt: 1737172800000,
    buyerNickname: '张**', productTitle: '珍珠米订单'
  },
  {
    recordId: 'r004', farmerId: 'f001', orderId: 'QN240617184555', subOrderId: 'so004',
    amount: 15.50, type: 'order', status: 'withdrawn', createdAt: 1737135900000,
    settledAt: 1737135900000, buyerNickname: '赵**', productTitle: '番茄订单'
  },
  {
    recordId: 'r005', farmerId: 'f001', orderId: 'QN240617163012', subOrderId: 'so005',
    amount: 45.00, type: 'order', status: 'settled', createdAt: 1737127800000,
    settledAt: 1737127800000, buyerNickname: '刘**', productTitle: '土鸡蛋订单'
  },
  {
    recordId: 'r006', farmerId: 'f001', orderId: 'RF240617095077', subOrderId: 'so006',
    amount: 12.00, type: 'refund', status: 'settled', createdAt: 1737112200000,
    settledAt: 1737112200000, buyerNickname: '周**', productTitle: '订单退款'
  },
  {
    recordId: 'r007', farmerId: 'f001', orderId: 'QN240617143022', subOrderId: 'so007',
    amount: 29.90, type: 'order', status: 'settled', createdAt: 1737124200000,
    settledAt: 1737124200000, buyerNickname: '孙**', productTitle: '现摘草莓2斤'
  },
  {
    recordId: 'r008', farmerId: 'f001', orderId: 'LIVE2406171315', subOrderId: 'so008',
    amount: 8.80, type: 'gift', status: 'settled', createdAt: 1737118500000,
    settledAt: 1737118500000, buyerNickname: '果果', productTitle: '直播打赏-果果'
  },
  {
    recordId: 'r009', farmerId: 'f001', orderId: 'BK2406171030', subOrderId: 'so009',
    amount: 116.00, type: 'booking', status: 'settled', createdAt: 1737109800000,
    settledAt: 1737109800000, buyerNickname: '吴**', productTitle: '采摘体验预约'
  },
  {
    recordId: 'r010', farmerId: 'f001', orderId: 'QN240616184555', subOrderId: 'so010',
    amount: 18.80, type: 'order', status: 'settled', createdAt: 1737049500000,
    settledAt: 1737049500000, buyerNickname: '阿强', productTitle: '有机番茄3斤'
  }
];

/** 提现记录列表（spec 4.1.7 Withdrawal，对齐设计稿 withdraw.html 4 条记录） */
export const MOCK_WITHDRAWALS: Withdrawal[] = [
  {
    withdrawalId: 'w001', farmerId: 'f001', amount: 500.00,
    account: '支付宝 ****1234', status: 'completed', createdAt: 1721463120000
  },
  {
    withdrawalId: 'w002', farmerId: 'f001', amount: 1200.00,
    account: '银行卡 ****5678', status: 'completed', createdAt: 1721276100000
  },
  {
    withdrawalId: 'w003', farmerId: 'f001', amount: 800.00,
    account: '支付宝 ****1234', status: 'completed', createdAt: 1721566080000
  },
  {
    withdrawalId: 'w004', farmerId: 'f001', amount: 350.00,
    account: '银行卡 ****5678', status: 'completed', createdAt: 1721025600000
  }
];

/** 日营收统计（spec 4.2.2 DailyRevenue，近7天） */
export const MOCK_DAILY_REVENUES: DailyRevenue[] = [
  { date: '2026-07-12', farmerId: 'f001', orderCount: 18, revenue: 856.30, refundAmount: 0 },
  { date: '2026-07-13', farmerId: 'f001', orderCount: 22, revenue: 1280.50, refundAmount: 28.50 },
  { date: '2026-07-14', farmerId: 'f001', orderCount: 15, revenue: 726.00, refundAmount: 0 },
  { date: '2026-07-15', farmerId: 'f001', orderCount: 28, revenue: 1865.20, refundAmount: 0 },
  { date: '2026-07-16', farmerId: 'f001', orderCount: 24, revenue: 1456.80, refundAmount: 39.90 },
  { date: '2026-07-17', farmerId: 'f001', orderCount: 31, revenue: 2168.40, refundAmount: 0 },
  { date: '2026-07-18', farmerId: 'f001', orderCount: 23, revenue: 1286.50, refundAmount: 0 }
];

/** 月营收统计（近6个月） */
export const MOCK_MONTHLY_REVENUES: DailyRevenue[] = [
  { date: '2026-02', farmerId: 'f001', orderCount: 480, revenue: 32150.00, refundAmount: 280.50 },
  { date: '2026-03', farmerId: 'f001', orderCount: 520, revenue: 35680.00, refundAmount: 158.00 },
  { date: '2026-04', farmerId: 'f001', orderCount: 612, revenue: 41200.50, refundAmount: 320.00 },
  { date: '2026-05', farmerId: 'f001', orderCount: 698, revenue: 45680.20, refundAmount: 200.00 },
  { date: '2026-06', farmerId: 'f001', orderCount: 654, revenue: 42850.00, refundAmount: 156.00 },
  { date: '2026-07', farmerId: 'f001', orderCount: 612, revenue: 38560.20, refundAmount: 68.40 }
];

/** 年营收统计（近3年） */
export const MOCK_YEARLY_REVENUES: DailyRevenue[] = [
  { date: '2024', farmerId: 'f001', orderCount: 5860, revenue: 286530.50, refundAmount: 1860.00 },
  { date: '2025', farmerId: 'f001', orderCount: 7256, revenue: 541080.30, refundAmount: 2540.00 },
  { date: '2026', farmerId: 'f001', orderCount: 21568, revenue: 458920.80, refundAmount: 980.40 }
];

/** 首页横滑商品卡片（对齐设计稿 farmer-home.html 6 张商品卡：草莓/番茄/毛尖/大米/鸡蛋/蜂蜜） */
export const MOCK_HOME_PRODUCTS: FarmerProductItem[] = [
  {
    productId: 'p_strawberry', title: '现摘草莓', mainImage: 'prod_strawberry',
    price: 29.90, stock: 568, monthlySales: 326, monthlyGmv: 9747,
    status: 'approved', createdAt: 1737000000000
  },
  {
    productId: 'p_tomato', title: '有机番茄', mainImage: 'prod_tomato',
    price: 18.80, stock: 480, monthlySales: 218, monthlyGmv: 4098,
    status: 'approved', createdAt: 1736900000000
  },
  {
    productId: 'p_tea', title: '高山毛尖', mainImage: 'prod_tea',
    price: 68.00, stock: 280, monthlySales: 94, monthlyGmv: 6392,
    status: 'approved', createdAt: 1736800000000
  },
  {
    productId: 'p_rice', title: '五常大米', mainImage: 'prod_rice',
    price: 39.90, stock: 680, monthlySales: 512, monthlyGmv: 20429,
    status: 'approved', createdAt: 1736700000000
  },
  {
    productId: 'p_eggs', title: '散养土鸡蛋', mainImage: 'prod_eggs',
    price: 45.00, stock: 180, monthlySales: 187, monthlyGmv: 8415,
    status: 'approved', createdAt: 1736600000000
  },
  {
    productId: 'p_honey', title: '百花土蜂蜜', mainImage: 'prod_honey',
    price: 88.00, stock: 50, monthlySales: 76, monthlyGmv: 6688,
    status: 'approved', createdAt: 1736500000000
  }
];

/** 卖家商品管理列表（spec 3.2.4.5） */
export const MOCK_FARMER_PRODUCTS: FarmerProductItem[] = [
  {
    productId: 'p001', title: '有机青菜 500g 当季新鲜 直采直发', mainImage: 'prod_vegetable_1',
    price: 9.90, stock: 568, monthlySales: 5680, monthlyGmv: 56800,
    status: 'approved', createdAt: 1736000000000, categoryId: 'cat_vegetable'
  },
  {
    productId: 'p003', title: '农家大米5kg 当季新米 软糯香甜', mainImage: 'prod_rice_1',
    price: 59.00, stock: 480, monthlySales: 2180, monthlyGmv: 128620,
    status: 'approved', createdAt: 1736200000000, categoryId: 'cat_rice'
  },
  {
    productId: 'p007', title: '高山绿茶 250g 明前嫩芽 清香回甘', mainImage: 'prod_tea_1',
    price: 68.00, stock: 280, monthlySales: 980, monthlyGmv: 66640,
    status: 'approved', createdAt: 1736600000000, categoryId: 'cat_tea'
  },
  {
    productId: 'p010', title: '土猪肉 1kg 农家散养 黑猪肉', mainImage: 'prod_meat_1',
    price: 78.00, stock: 180, monthlySales: 890, monthlyGmv: 69420,
    status: 'approved', createdAt: 1736900000000, categoryId: 'cat_meat'
  },
  {
    productId: 'p013', title: '小米辣 250g 农家自种 辣味十足', mainImage: 'prod_chili_1',
    price: 8.80, stock: 680, monthlySales: 5230, monthlyGmv: 46024,
    status: 'approved', createdAt: 1737200000000, categoryId: 'cat_vegetable'
  },
  {
    productId: 'p016_draft', title: '紫薯 5kg 农家自种（待审核）', mainImage: 'prod_potato_1',
    price: 19.90, stock: 320, monthlySales: 0, monthlyGmv: 0,
    status: 'pending_review', createdAt: 1737500000000, categoryId: 'cat_vegetable'
  },
  {
    productId: 'p017_reject', title: '散养土鸡 1只（驳回示例）', mainImage: 'prod_chicken_1',
    price: 88.00, stock: 50, monthlySales: 0, monthlyGmv: 0,
    status: 'rejected', rejectReason: '商品主图不清晰，请重新上传',
    createdAt: 1737400000000, categoryId: 'cat_meat'
  },
  {
    productId: 'p018_off', title: '红薯干 250g 农家自晒（已下架）', mainImage: 'prod_dried_1',
    price: 19.90, stock: 380, monthlySales: 0, monthlyGmv: 0,
    status: 'off_shelf', createdAt: 1737000000000, categoryId: 'cat_vegetable'
  }
];

/** 直播管理历史列表（spec 3.2.4.5） */
export const MOCK_LIVE_MANAGE_LIST: LiveManageItem[] = [
  {
    liveId: 'l001', title: '高山有机青菜采摘直播', coverImage: 'live_cover_1',
    category: 'fresh', status: 'ended', startTime: 1736800000000, endTime: 1736809000000,
    totalViewUv: 1286, totalGiftIncome: 358.50, totalOrderIncome: 2680.00
  },
  {
    liveId: 'l002', title: '当季新米品鉴专场', coverImage: 'live_cover_2',
    category: 'grain', status: 'ended', startTime: 1736900000000, endTime: 1736908000000,
    totalViewUv: 980, totalGiftIncome: 186.00, totalOrderIncome: 3250.00
  },
  {
    liveId: 'l003', title: '明前嫩芽绿茶制作', coverImage: 'live_cover_3',
    category: 'tea', status: 'ended', startTime: 1737000000000, endTime: 1737008000000,
    totalViewUv: 658, totalGiftIncome: 128.00, totalOrderIncome: 1850.00
  },
  {
    liveId: 'l004', title: '今晚8点·农家土鸡蛋直采', coverImage: 'live_cover_4',
    category: 'fresh', status: 'preview', startTime: 1737100000000,
    totalViewUv: 0, totalGiftIncome: 0, totalOrderIncome: 0
  },
  {
    liveId: 'l005', title: '土蜂蜜采收直播', coverImage: 'live_cover_5',
    category: 'fresh', status: 'living', startTime: 1737180000000,
    totalViewUv: 326, totalGiftIncome: 86.50, totalOrderIncome: 580.00
  }
];

/** 粉丝列表（spec 3.2.4.5，对齐设计稿 fans-list.html，spec 16.8：扩充至 20 条） */
export const MOCK_FANS_LIST: FanInfo[] = [
  { userId: 'u001', nickname: '小叶子', avatar: 'avatar_customer', followedAt: Date.now() - 3 * 86400000, isMutual: true, isNew: true },
  { userId: 'u002', nickname: '果园达人', avatar: 'avatar_user_2', followedAt: Date.now() - 7 * 86400000, isMutual: true, isNew: true },
  { userId: 'u003', nickname: '美食家阿强', avatar: 'avatar_user_3', followedAt: Date.now() - 14 * 86400000, isMutual: true, isNew: true },
  { userId: 'u004', nickname: '小雨', avatar: 'avatar_user_4', followedAt: Date.now() - 21 * 86400000, isMutual: false, isNew: false },
  { userId: 'u005', nickname: '王老板', avatar: 'avatar_user_5', followedAt: Date.now() - 32 * 86400000, isMutual: true, isNew: false },
  { userId: 'u006', nickname: '陈姐', avatar: 'avatar_user_6', followedAt: Date.now() - 45 * 86400000, isMutual: false, isNew: false },
  { userId: 'u007', nickname: '田园爱好者', avatar: 'avatar_user_7', followedAt: Date.now() - 60 * 86400000, isMutual: true, isNew: false },
  { userId: 'u008', nickname: '小镇青年', avatar: 'avatar_user_8', followedAt: Date.now() - 90 * 86400000, isMutual: false, isNew: false },
  { userId: 'u009', nickname: '阿梅', avatar: 'avatar_user_9', followedAt: Date.now() - 1 * 86400000, isMutual: false, isNew: true },
  { userId: 'u010', nickname: '山里人家', avatar: 'avatar_user_10', followedAt: Date.now() - 5 * 86400000, isMutual: true, isNew: true },
  { userId: 'u011', nickname: '采菊东篱', avatar: 'avatar_user_11', followedAt: Date.now() - 10 * 86400000, isMutual: false, isNew: true },
  { userId: 'u012', nickname: '岁月静好', avatar: 'avatar_user_12', followedAt: Date.now() - 18 * 86400000, isMutual: true, isNew: false },
  { userId: 'u013', nickname: '农夫山泉', avatar: 'avatar_user_13', followedAt: Date.now() - 28 * 86400000, isMutual: false, isNew: false },
  { userId: 'u014', nickname: '麦田守望', avatar: 'avatar_user_14', followedAt: Date.now() - 40 * 86400000, isMutual: true, isNew: false },
  { userId: 'u015', nickname: '采茶姑娘', avatar: 'avatar_user_15', followedAt: Date.now() - 55 * 86400000, isMutual: false, isNew: false },
  // spec 16.8：新增 5 条粉丝数据，丰富粉丝管理页内容
  { userId: 'u016', nickname: '远方的客', avatar: 'avatar_user_16', followedAt: Date.now() - 2 * 86400000, isMutual: false, isNew: true },
  { userId: 'u017', nickname: '市集小贩', avatar: 'avatar_user_17', followedAt: Date.now() - 8 * 86400000, isMutual: true, isNew: true },
  { userId: 'u018', nickname: '云上游人', avatar: 'avatar_user_18', followedAt: Date.now() - 25 * 86400000, isMutual: false, isNew: false },
  { userId: 'u019', nickname: '种菜小白', avatar: 'avatar_user_19', followedAt: Date.now() - 50 * 86400000, isMutual: true, isNew: false },
  { userId: 'u020', nickname: '老饕餮', avatar: 'avatar_user_20', followedAt: Date.now() - 75 * 86400000, isMutual: false, isNew: false }
];

/**
 * 营收汇总 Mock 取数（按时间范围）
 */
export function getMockRevenueSummary(range: RevenueRange): RevenueSummary {
  return MOCK_REVENUE_SUMMARIES[range];
}

/**
 * 营收明细列表分页（spec 3.2.3.3）
 * @param range 时间范围
 * @param status 状态筛选（可选）
 * @param page 页码（1开始）
 * @param size 每页条数
 */
export function getMockRevenueRecords(
  range: RevenueRange,
  status: string | undefined,
  page: number,
  size: number
): PaginatedResult<RevenueRecord> {
  let filtered: RevenueRecord[] = MOCK_REVENUE_RECORDS.slice();
  // 时间范围过滤（Mock 简化：today=最近1天 / month=当月 / year=当年 / total=全部）
  const now: number = Date.now();
  const dayMs: number = 86400000;
  const ranges: Record<RevenueRange, number> = {
    'today': now - dayMs,
    'month': now - 30 * dayMs,
    'year': now - 365 * dayMs,
    'total': 0
  };
  const minTime: number = ranges[range];
  if (minTime > 0) {
    filtered = filtered.filter((r: RevenueRecord): boolean => r.createdAt >= minTime);
  }
  // 状态过滤
  if (status && status.length > 0) {
    filtered = filtered.filter((r: RevenueRecord): boolean => r.status === status);
  }
  const total: number = filtered.length;
  const start: number = (page - 1) * size;
  const list: RevenueRecord[] = filtered.slice(start, start + size);
  return { list, total, hasMore: start + size < total };
}

/**
 * 提现记录列表分页
 */
export function getMockWithdrawals(page: number, size: number): PaginatedResult<Withdrawal> {
  const total: number = MOCK_WITHDRAWALS.length;
  const start: number = (page - 1) * size;
  const list: Withdrawal[] = MOCK_WITHDRAWALS.slice(start, start + size);
  return { list, total, hasMore: start + size < total };
}

/**
 * 营收统计图表数据（spec 3.2.4.5：按日/月/年）
 */
export function getMockRevenueChart(dimension: RevenueStatsDimension): RevenueChartPoint[] {
  let source: DailyRevenue[];
  switch (dimension) {
    case 'day':
      source = MOCK_DAILY_REVENUES;
      break;
    case 'month':
      source = MOCK_MONTHLY_REVENUES;
      break;
    case 'year':
      source = MOCK_YEARLY_REVENUES;
      break;
    default:
      source = MOCK_DAILY_REVENUES;
      break;
  }
  return source.map((d: DailyRevenue): RevenueChartPoint => {
    return { label: d.date, value: d.revenue };
  });
}

/**
 * 卖家商品管理列表分页
 */
export function getMockFarmerProducts(
  page: number,
  size: number,
  statusFilter?: string
): PaginatedResult<FarmerProductItem> {
  let filtered: FarmerProductItem[] = MOCK_FARMER_PRODUCTS.slice();
  if (statusFilter && statusFilter.length > 0) {
    filtered = filtered.filter((p: FarmerProductItem): boolean => p.status === statusFilter);
  }
  const total: number = filtered.length;
  const start: number = (page - 1) * size;
  const list: FarmerProductItem[] = filtered.slice(start, start + size);
  return { list, total, hasMore: start + size < total };
}

/**
 * 直播管理历史列表分页
 */
export function getMockLiveManageList(
  page: number,
  size: number,
  statusFilter?: string
): PaginatedResult<LiveManageItem> {
  let filtered: LiveManageItem[] = MOCK_LIVE_MANAGE_LIST.slice();
  if (statusFilter && statusFilter.length > 0) {
    filtered = filtered.filter((l: LiveManageItem): boolean => l.status === statusFilter);
  }
  const total: number = filtered.length;
  const start: number = (page - 1) * size;
  const list: LiveManageItem[] = filtered.slice(start, start + size);
  return { list, total, hasMore: start + size < total };
}

/**
 * 粉丝列表分页
 */
export function getMockFansList(page: number, size: number): PaginatedResult<FanInfo> {
  const total: number = MOCK_FANS_LIST.length;
  const start: number = (page - 1) * size;
  const list: FanInfo[] = MOCK_FANS_LIST.slice(start, start + size);
  return { list, total, hasMore: start + size < total };
}

/**
 * 根据 farmerId 查询卖家信息
 */
export function getMockFarmerProfileById(farmerId: string): FarmerProfile | null {
  if (farmerId === MOCK_FARMER_PROFILE.farmerId) {
    return MOCK_FARMER_PROFILE;
  }
  return null;
}

/**
 * 首页横滑商品卡片（spec 3.2.3.1）
 */
export function getMockHomeProducts(): FarmerProductItem[] {
  return MOCK_HOME_PRODUCTS.slice();
}
