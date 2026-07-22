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
  PaginatedResult
} from '../model/FarmerModels';

/** 当前卖家 ID（Mock 固定） */
export const MOCK_FARMER_ID: string = 'f001';

/** 卖家信息（spec 4.1.2 FarmerProfile） */
export const MOCK_FARMER_PROFILE: FarmerProfile = {
  farmerId: 'f001',
  shopName: '青禾农庄',
  shopLogo: 'avatar_farmer_1',
  shopIntro: '高山有机农场，无农药无化肥，专注品质生鲜。每周末直播采摘过程，欢迎关注！',
  certificationStatus: 'approved',
  certificationInfo: {
    realName: '李青禾',
    idCardNo: '530***********1234',
    idCardFrontImg: 'cert_id_front',
    idCardBackImg: 'cert_id_back',
    farmerCertImg: 'cert_farmer'
  },
  totalRevenue: 1286530.60,
  availableBalance: 8652.40,
  frozenBalance: 3200.00,
  followCount: 28,
  fansCount: 186
};

/** 营收汇总（按时间范围，spec 3.2.3.1） */
export const MOCK_REVENUE_SUMMARIES: Record<RevenueRange, RevenueSummary> = {
  'today': { amount: 1286.50, orderCount: 23, productCount: 8, conversionRate: 12.5 },
  'month': { amount: 38560.20, orderCount: 612, productCount: 8, conversionRate: 15.8 },
  'year': { amount: 458920.80, orderCount: 7823, productCount: 8, conversionRate: 14.2 },
  'total': { amount: 1286530.60, orderCount: 21568, productCount: 8, conversionRate: 13.6 }
};

/** 营收记录列表（spec 4.1.7 RevenueRecord，spec 3.2.3.3 营收明细） */
export const MOCK_REVENUE_RECORDS: RevenueRecord[] = [
  {
    recordId: 'r001', farmerId: 'f001', orderId: 'o20260718001', subOrderId: 'so001',
    amount: 28.50, type: 'order', status: 'settled', createdAt: 1737000000000,
    settledAt: 1737086400000, buyerNickname: '小马哥', productTitle: '有机青菜 500g'
  },
  {
    recordId: 'r002', farmerId: 'f001', orderId: 'o20260718002', subOrderId: 'so002',
    amount: 59.00, type: 'order', status: 'settled', createdAt: 1737010000000,
    settledAt: 1737092800000, buyerNickname: '阿芳', productTitle: '农家大米5kg'
  },
  {
    recordId: 'r003', farmerId: 'f001', orderId: 'o20260718003', subOrderId: 'so003',
    amount: 9.90, type: 'order', status: 'pending', createdAt: 1737020000000,
    buyerNickname: '阿强', productTitle: '有机青菜 500g'
  },
  {
    recordId: 'r004', farmerId: 'f001', orderId: 'o20260718004', subOrderId: 'so004',
    amount: 18.80, type: 'order', status: 'settled', createdAt: 1737030000000,
    settledAt: 1737116400000, buyerNickname: '小雨', productTitle: '有机青菜 1kg'
  },
  {
    recordId: 'r005', farmerId: 'f001', orderId: 'o20260718005', subOrderId: 'so005',
    amount: 6.60, type: 'gift', status: 'settled', createdAt: 1737040000000,
    settledAt: 1737040000000, buyerNickname: '路人甲', productTitle: '直播间礼物'
  },
  {
    recordId: 'r006', farmerId: 'f001', orderId: 'o20260717006', subOrderId: 'so006',
    amount: 128.00, type: 'order', status: 'withdrawn', createdAt: 1736900000000,
    settledAt: 1736986400000, buyerNickname: '王老板', productTitle: '高山绿茶 500g礼盒'
  },
  {
    recordId: 'r007', farmerId: 'f001', orderId: 'o20260717007', subOrderId: 'so007',
    amount: 78.00, type: 'order', status: 'withdrawn', createdAt: 1736910000000,
    settledAt: 1736992800000, buyerNickname: '陈姐', productTitle: '土猪肉 1kg'
  },
  {
    recordId: 'r008', farmerId: 'f001', orderId: 'o20260716008', subOrderId: 'so008',
    amount: 39.90, type: 'order', status: 'withdrawn', createdAt: 1736800000000,
    settledAt: 1736886400000, buyerNickname: '阿强', productTitle: '土鸡蛋30枚'
  },
  {
    recordId: 'r009', farmerId: 'f001', orderId: 'o20260716009', subOrderId: 'so009',
    amount: 19.90, type: 'order', status: 'withdrawn', createdAt: 1736810000000,
    settledAt: 1736892800000, buyerNickname: '小马哥', productTitle: '甜糯玉米 8根'
  },
  {
    recordId: 'r010', farmerId: 'f001', orderId: 'o20260715010', subOrderId: 'so010',
    amount: 89.00, type: 'order', status: 'withdrawn', createdAt: 1736700000000,
    settledAt: 1736786400000, buyerNickname: '阿芳', productTitle: '土蜂蜜 500g'
  }
];

/** 提现记录列表（spec 4.1.7 Withdrawal） */
export const MOCK_WITHDRAWALS: Withdrawal[] = [
  {
    withdrawalId: 'w001', farmerId: 'f001', amount: 2000.00,
    account: '6228****1234', status: 'completed', createdAt: 1736800000000
  },
  {
    withdrawalId: 'w002', farmerId: 'f001', amount: 3500.00,
    account: '6228****1234', status: 'completed', createdAt: 1736900000000
  },
  {
    withdrawalId: 'w003', farmerId: 'f001', amount: 1500.00,
    account: '6228****1234', status: 'completed', createdAt: 1736950000000
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

/** 卖家商品管理列表（spec 3.2.4.5） */
export const MOCK_FARMER_PRODUCTS: FarmerProductItem[] = [
  {
    productId: 'p001', title: '有机青菜 500g 当季新鲜 直采直发', mainImage: 'prod_vegetable_1',
    price: 9.90, stock: 568, monthlySales: 5680, monthlyGmv: 56800,
    status: 'approved', createdAt: 1736000000000
  },
  {
    productId: 'p003', title: '农家大米5kg 当季新米 软糯香甜', mainImage: 'prod_rice_1',
    price: 59.00, stock: 480, monthlySales: 2180, monthlyGmv: 128620,
    status: 'approved', createdAt: 1736200000000
  },
  {
    productId: 'p007', title: '高山绿茶 250g 明前嫩芽 清香回甘', mainImage: 'prod_tea_1',
    price: 68.00, stock: 280, monthlySales: 980, monthlyGmv: 66640,
    status: 'approved', createdAt: 1736600000000
  },
  {
    productId: 'p010', title: '土猪肉 1kg 农家散养 黑猪肉', mainImage: 'prod_meat_1',
    price: 78.00, stock: 180, monthlySales: 890, monthlyGmv: 69420,
    status: 'approved', createdAt: 1736900000000
  },
  {
    productId: 'p013', title: '小米辣 250g 农家自种 辣味十足', mainImage: 'prod_chili_1',
    price: 8.80, stock: 680, monthlySales: 5230, monthlyGmv: 46024,
    status: 'approved', createdAt: 1737200000000
  },
  {
    productId: 'p016_draft', title: '紫薯 5kg 农家自种（待审核）', mainImage: 'prod_potato_1',
    price: 19.90, stock: 320, monthlySales: 0, monthlyGmv: 0,
    status: 'pending_review', createdAt: 1737500000000
  },
  {
    productId: 'p017_reject', title: '散养土鸡 1只（驳回示例）', mainImage: 'prod_chicken_1',
    price: 88.00, stock: 50, monthlySales: 0, monthlyGmv: 0,
    status: 'rejected', rejectReason: '商品主图不清晰，请重新上传',
    createdAt: 1737400000000
  },
  {
    productId: 'p018_off', title: '红薯干 250g 农家自晒（已下架）', mainImage: 'prod_dried_1',
    price: 19.90, stock: 380, monthlySales: 0, monthlyGmv: 0,
    status: 'off_shelf', createdAt: 1737000000000
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

/** 粉丝列表（spec 3.2.4.5） */
export const MOCK_FANS_LIST: FanInfo[] = [
  { userId: 'u001', nickname: '小马哥', avatar: 'avatar_user_1', followedAt: 1736800000000 },
  { userId: 'u002', nickname: '阿芳', avatar: 'avatar_user_2', followedAt: 1736900000000 },
  { userId: 'u003', nickname: '阿强', avatar: 'avatar_user_3', followedAt: 1737000000000 },
  { userId: 'u004', nickname: '小雨', avatar: 'avatar_user_4', followedAt: 1737100000000 },
  { userId: 'u005', nickname: '王老板', avatar: 'avatar_user_5', followedAt: 1737200000000 },
  { userId: 'u006', nickname: '陈姐', avatar: 'avatar_user_6', followedAt: 1737300000000 },
  { userId: 'u007', nickname: '路人甲', avatar: 'avatar_user_7', followedAt: 1737400000000 },
  { userId: 'u008', nickname: '田园爱好者', avatar: 'avatar_user_8', followedAt: 1737500000000 }
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
