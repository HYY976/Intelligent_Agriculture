/**
 * AdminMock - 管理后台 Mock 数据源（spec 3.3 / 10.8.6）
 * 提供 user/api/review/dashboard 等 Mock 数据与分页查询函数
 * 后端未部署时由 Repository 层回退调用
 */

import {
  UserRecord,
  UserListQuery,
  UserDetailAggregate,
  LoginDeviceRecord,
  DashboardStats,
  ApiInfo,
  ApiListQuery,
  ApiDetailAggregate,
  ApiRequestTrendPoint,
  ApiErrorLog,
  RateLimitConfig,
  ApiKey,
  CreateApiKeyResponse,
  ContentReview,
  ReviewListQuery,
  ReviewDetailAggregate,
  ReviewHistoryItem,
  AdRecord,
  AdListQuery,
  AdOverviewStats,
  AdCreateRequest,
  AdSlot,
  AdStatus,
  AdAudience
} from '../model/AdminModels';
import { PageResult } from 'common';

// ===== 时间戳辅助（基于 2026-07-18 计算） =====
const NOW: number = 1752883200000; // 2026-07-18 16:00:00
const DAY: number = 86400000;

// ===== Mock 用户数据（20 条，混合 user/farmer + active/banned） =====
export const MOCK_USERS: UserRecord[] = [
  {
    userId: 'u_001', phone: '13800138001', nickname: '张三', avatar: '',
    userType: 'user', status: 'active',
    createdAt: NOW - 90 * DAY, lastLoginAt: NOW - 2 * DAY,
    lastLoginIp: '192.168.1.101'
  },
  {
    userId: 'u_002', phone: '13800138002', nickname: '李四', avatar: '',
    userType: 'user', status: 'active',
    createdAt: NOW - 60 * DAY, lastLoginAt: NOW - 1 * DAY,
    lastLoginIp: '192.168.1.102'
  },
  {
    userId: 'u_003', phone: '13800138003', nickname: '王五', avatar: '',
    userType: 'user', status: 'banned',
    banReason: '发布违规内容', banUntil: NOW + 5 * DAY,
    createdAt: NOW - 30 * DAY, lastLoginAt: NOW - 7 * DAY,
    lastLoginIp: '192.168.1.103'
  },
  {
    userId: 'u_004', phone: '13800138004', nickname: '赵六', avatar: '',
    userType: 'user', status: 'active',
    createdAt: NOW - 15 * DAY, lastLoginAt: NOW - 3 * DAY,
    lastLoginIp: '192.168.1.104'
  },
  {
    userId: 'u_005', phone: '13800138005', nickname: '孙七', avatar: '',
    userType: 'user', status: 'active',
    createdAt: NOW - 5 * DAY, lastLoginAt: NOW - 1 * DAY,
    lastLoginIp: '192.168.1.105'
  },
  {
    userId: 'f_001', phone: '13900139001', nickname: '阿强果园', avatar: '',
    userType: 'farmer', status: 'active',
    createdAt: NOW - 120 * DAY, lastLoginAt: NOW - 1 * DAY,
    lastLoginIp: '192.168.2.201'
  },
  {
    userId: 'f_002', phone: '13900139002', nickname: '田园直供', avatar: '',
    userType: 'farmer', status: 'active',
    createdAt: NOW - 100 * DAY, lastLoginAt: NOW - 2 * DAY,
    lastLoginIp: '192.168.2.202'
  },
  {
    userId: 'f_003', phone: '13900139003', nickname: '丰收之家', avatar: '',
    userType: 'farmer', status: 'banned',
    banReason: '恶意刷单', banUntil: 0, // 0 表示永久封禁
    createdAt: NOW - 80 * DAY, lastLoginAt: NOW - 15 * DAY,
    lastLoginIp: '192.168.2.203'
  },
  {
    userId: 'f_004', phone: '13900139004', nickname: '绿色农场', avatar: '',
    userType: 'farmer', status: 'active',
    createdAt: NOW - 70 * DAY, lastLoginAt: NOW - 1 * DAY,
    lastLoginIp: '192.168.2.204'
  },
  {
    userId: 'f_005', phone: '13900139005', nickname: '阳光农户', avatar: '',
    userType: 'farmer', status: 'active',
    createdAt: NOW - 50 * DAY, lastLoginAt: NOW - 3 * DAY,
    lastLoginIp: '192.168.2.205'
  },
  {
    userId: 'u_006', phone: '13800138006', nickname: '周八', avatar: '',
    userType: 'user', status: 'active',
    createdAt: NOW - 20 * DAY, lastLoginAt: NOW - 4 * DAY,
    lastLoginIp: '192.168.1.106'
  },
  {
    userId: 'u_007', phone: '13800138007', nickname: '吴九', avatar: '',
    userType: 'user', status: 'banned',
    banReason: '骚扰他人', banUntil: NOW + 25 * DAY,
    createdAt: NOW - 45 * DAY, lastLoginAt: NOW - 10 * DAY,
    lastLoginIp: '192.168.1.107'
  },
  {
    userId: 'u_008', phone: '13800138008', nickname: '郑十', avatar: '',
    userType: 'user', status: 'active',
    createdAt: NOW - 25 * DAY, lastLoginAt: NOW - 1 * DAY,
    lastLoginIp: '192.168.1.108'
  },
  {
    userId: 'f_006', phone: '13900139006', nickname: '稻香村', avatar: '',
    userType: 'farmer', status: 'active',
    createdAt: NOW - 65 * DAY, lastLoginAt: NOW - 2 * DAY,
    lastLoginIp: '192.168.2.206'
  },
  {
    userId: 'f_007', phone: '13900139007', nickname: '茶韵人家', avatar: '',
    userType: 'farmer', status: 'active',
    createdAt: NOW - 40 * DAY, lastLoginAt: NOW - 1 * DAY,
    lastLoginIp: '192.168.2.207'
  },
  {
    userId: 'u_009', phone: '13800138009', nickname: '李雷', avatar: '',
    userType: 'user', status: 'active',
    createdAt: NOW - 10 * DAY, lastLoginAt: NOW - 1 * DAY,
    lastLoginIp: '192.168.1.109'
  },
  {
    userId: 'u_010', phone: '13800138010', nickname: '韩梅梅', avatar: '',
    userType: 'user', status: 'active',
    createdAt: NOW - 8 * DAY, lastLoginAt: NOW - 2 * DAY,
    lastLoginIp: '192.168.1.110'
  },
  {
    userId: 'f_008', phone: '13900139008', nickname: '禽蛋之家', avatar: '',
    userType: 'farmer', status: 'banned',
    banReason: '虚假交易', banUntil: NOW + 12 * DAY,
    createdAt: NOW - 35 * DAY, lastLoginAt: NOW - 5 * DAY,
    lastLoginIp: '192.168.2.208'
  },
  {
    userId: 'u_011', phone: '13800138011', nickname: '小红', avatar: '',
    userType: 'user', status: 'active',
    createdAt: NOW - 3 * DAY, lastLoginAt: NOW - 1 * DAY,
    lastLoginIp: '192.168.1.111'
  },
  {
    userId: 'f_009', phone: '13900139009', nickname: '果园直发', avatar: '',
    userType: 'farmer', status: 'active',
    createdAt: NOW - 18 * DAY, lastLoginAt: NOW - 1 * DAY,
    lastLoginIp: '192.168.2.209'
  }
];

// ===== Mock 登录设备记录 =====
export const MOCK_LOGIN_DEVICES: LoginDeviceRecord[] = [
  {
    deviceName: 'HUAWEI Mate 60 Pro', ipAddress: '192.168.1.101',
    loginAt: NOW - 2 * DAY, location: '广东省深圳市'
  },
  {
    deviceName: 'HUAWEI Pura 70', ipAddress: '192.168.1.101',
    loginAt: NOW - 5 * DAY, location: '广东省深圳市'
  },
  {
    deviceName: 'Honor Magic6', ipAddress: '10.0.0.5',
    loginAt: NOW - 12 * DAY, location: '广东省广州市'
  }
];

// ===== Mock 控制台统计数据 =====
export const MOCK_DASHBOARD_STATS: DashboardStats = {
  totalUsers: 12568,
  totalFarmers: 1256,
  pendingReviews: 38,
  todayOrders: 892
};

// ===== Mock API 接口列表（12 条，覆盖 GET/POST/PUT/DELETE） =====
export const MOCK_APIS: ApiInfo[] = [
  {
    apiId: 'api_001', path: '/api/user/login', method: 'POST', description: '用户登录',
    todayRequestCount: 5680, errorRate: 0.12, avgResponseTime: 85,
    createdAt: NOW - 100 * DAY
  },
  {
    apiId: 'api_002', path: '/api/user/register', method: 'POST', description: '用户注册',
    todayRequestCount: 320, errorRate: 0.05, avgResponseTime: 120,
    createdAt: NOW - 100 * DAY
  },
  {
    apiId: 'api_003', path: '/api/home/recommend', method: 'GET', description: '首页推荐流',
    todayRequestCount: 18650, errorRate: 0.08, avgResponseTime: 95,
    createdAt: NOW - 95 * DAY
  },
  {
    apiId: 'api_004', path: '/api/product/list', method: 'GET', description: '商品列表',
    todayRequestCount: 9820, errorRate: 0.03, avgResponseTime: 78,
    createdAt: NOW - 90 * DAY
  },
  {
    apiId: 'api_005', path: '/api/product/detail', method: 'GET', description: '商品详情',
    todayRequestCount: 12340, errorRate: 0.02, avgResponseTime: 65,
    createdAt: NOW - 90 * DAY
  },
  {
    apiId: 'api_006', path: '/api/cart/add', method: 'POST', description: '加入购物车',
    todayRequestCount: 4520, errorRate: 0.15, avgResponseTime: 110,
    createdAt: NOW - 85 * DAY
  },
  {
    apiId: 'api_007', path: '/api/order/create', method: 'POST', description: '创建订单',
    todayRequestCount: 892, errorRate: 0.25, avgResponseTime: 230,
    createdAt: NOW - 80 * DAY
  },
  {
    apiId: 'api_008', path: '/api/order/list', method: 'GET', description: '订单列表',
    todayRequestCount: 3210, errorRate: 0.04, avgResponseTime: 105,
    createdAt: NOW - 80 * DAY
  },
  {
    apiId: 'api_009', path: '/api/order/cancel', method: 'PUT', description: '取消订单',
    todayRequestCount: 156, errorRate: 0.18, avgResponseTime: 145,
    createdAt: NOW - 75 * DAY
  },
  {
    apiId: 'api_010', path: '/api/live/list', method: 'GET', description: '直播列表',
    todayRequestCount: 2100, errorRate: 0.06, avgResponseTime: 88,
    createdAt: NOW - 70 * DAY
  },
  {
    apiId: 'api_011', path: '/api/community/posts', method: 'GET', description: '社区帖子列表',
    todayRequestCount: 5430, errorRate: 0.04, avgResponseTime: 72,
    createdAt: NOW - 65 * DAY
  },
  {
    apiId: 'api_012', path: '/api/admin/user/ban', method: 'PUT', description: '封禁用户',
    todayRequestCount: 12, errorRate: 0.0, avgResponseTime: 95,
    createdAt: NOW - 60 * DAY
  }
];

// ===== Mock API 请求量趋势（近 7 天） =====
export const MOCK_API_TREND_7D: ApiRequestTrendPoint[] = [
  { date: '2026-07-12', requestCount: 52000, errorCount: 65 },
  { date: '2026-07-13', requestCount: 48500, errorCount: 52 },
  { date: '2026-07-14', requestCount: 55300, errorCount: 78 },
  { date: '2026-07-15', requestCount: 61200, errorCount: 89 },
  { date: '2026-07-16', requestCount: 58800, errorCount: 71 },
  { date: '2026-07-17', requestCount: 63500, errorCount: 95 },
  { date: '2026-07-18', requestCount: 42100, errorCount: 48 }
];

// ===== Mock API 错误日志（最近 20 条） =====
export const MOCK_API_ERROR_LOGS: ApiErrorLog[] = [
  {
    logId: 'log_001', apiId: 'api_007', statusCode: 500,
    errorMessage: 'Database connection timeout',
    clientIp: '192.168.1.55', occurredAt: NOW - 1 * 3600000
  },
  {
    logId: 'log_002', apiId: 'api_006', statusCode: 429,
    errorMessage: 'Rate limit exceeded',
    clientIp: '192.168.1.88', occurredAt: NOW - 2 * 3600000
  },
  {
    logId: 'log_003', apiId: 'api_001', statusCode: 401,
    errorMessage: 'Invalid token',
    clientIp: '10.0.0.12', occurredAt: NOW - 3 * 3600000
  },
  {
    logId: 'log_004', apiId: 'api_007', statusCode: 400,
    errorMessage: 'Missing required field: addressId',
    clientIp: '192.168.1.92', occurredAt: NOW - 5 * 3600000
  },
  {
    logId: 'log_005', apiId: 'api_009', statusCode: 500,
    errorMessage: 'Order status transition invalid',
    clientIp: '192.168.1.77', occurredAt: NOW - 8 * 3600000
  }
];

// ===== Mock 限流配置 =====
export const MOCK_RATE_LIMIT_CONFIGS: RateLimitConfig[] = MOCK_APIS.map((api: ApiInfo, index: number): RateLimitConfig => {
  // 根据接口路径差异化配置（对齐 rate-limit.html 设计稿：QPS 200 / 并发 50 / 熔断 500 / 恢复 30s）
  const qps: number = index === 0 ? 200 : 100;
  const currentQps: number = index === 0 ? 156 : Math.floor(qps * 0.6);
  return {
    configId: `rl_${index + 1}`,
    apiId: api.apiId,
    qpsLimit: qps,
    concurrentLimit: 50,
    circuitBreakThreshold: 0.05,
    recoveryTime: 30,
    currentQps: currentQps,
    status: 'normal'
  };
});

// ===== Mock API 密钥（3 条，对齐 api-key.html 设计稿） =====
export const MOCK_API_KEYS: ApiKey[] = [
  {
    keyId: 'key_001', appKey: 'qn_app_8f3a9b2c', status: 'active',
    createdAt: NOW - 50 * DAY, lastUsedAt: NOW - 5 * DAY
  },
  {
    keyId: 'key_002', appKey: 'qn_app_4d7e1f90', status: 'active',
    createdAt: NOW - 68 * DAY, lastUsedAt: NOW - 3 * DAY
  },
  {
    keyId: 'key_003', appKey: 'qn_app_2c5b8a13', status: 'revoked',
    createdAt: NOW - 100 * DAY, lastUsedAt: NOW - 50 * DAY, revokedAt: NOW - 40 * DAY
  }
];

// ===== Mock 内容审核记录（15 条，覆盖 4 类型 + 3 状态） =====
export const MOCK_REVIEWS: ContentReview[] = [
  {
    reviewId: 'r_001', contentType: 'product', contentId: 'p_101',
    contentTitle: '新鲜红富士苹果 5斤装', contentPreview: '当季新摘红富士，脆甜多汁...',
    contentImages: ['mock://product_101_1.jpg'],
    submitterId: 'f_001', submitterNickname: '阿强果园',
    status: 'pending', submittedAt: NOW - 2 * 3600000
  },
  {
    reviewId: 'r_002', contentType: 'product', contentId: 'p_102',
    contentTitle: '农家自种大米 10斤', contentPreview: '自家稻田种植，无农药...',
    submitterId: 'f_002', submitterNickname: '田园直供',
    status: 'pending', submittedAt: NOW - 5 * 3600000
  },
  {
    reviewId: 'r_003', contentType: 'live', contentId: 'l_201',
    contentTitle: '果园采摘直播专场', contentPreview: '带您走进果园，亲眼见证采摘过程...',
    submitterId: 'f_001', submitterNickname: '阿强果园',
    status: 'pending', submittedAt: NOW - 8 * 3600000
  },
  {
    reviewId: 'r_004', contentType: 'post', contentId: 'post_301',
    contentTitle: '分享我的种植经验', contentPreview: '今年尝试了新的有机种植法...',
    submitterId: 'u_004', submitterNickname: '赵六',
    status: 'pending', submittedAt: NOW - 12 * 3600000
  },
  {
    reviewId: 'r_005', contentType: 'report', contentId: 'rep_401',
    contentTitle: '举报：涉嫌虚假宣传', contentPreview: '该商品描述与实际不符...',
    submitterId: 'u_005', submitterNickname: '孙七',
    status: 'pending', submittedAt: NOW - 18 * 3600000
  },
  {
    reviewId: 'r_006', contentType: 'product', contentId: 'p_103',
    contentTitle: '土鸡蛋 30枚装', contentPreview: '散养土鸡蛋，新鲜直达...',
    submitterId: 'f_008', submitterNickname: '禽蛋之家',
    status: 'approved', reviewerId: 'admin_001', reviewerNickname: '超级管理员',
    submittedAt: NOW - 2 * DAY, reviewedAt: NOW - 1 * DAY
  },
  {
    reviewId: 'r_007', contentType: 'product', contentId: 'p_104',
    contentTitle: '新茶龙井 250g', contentPreview: '明前龙井，清香回甘...',
    submitterId: 'f_007', submitterNickname: '茶韵人家',
    status: 'approved', reviewerId: 'admin_001', reviewerNickname: '超级管理员',
    submittedAt: NOW - 3 * DAY, reviewedAt: NOW - 2 * DAY
  },
  {
    reviewId: 'r_008', contentType: 'live', contentId: 'l_202',
    contentTitle: '茶艺直播专场', contentPreview: '品鉴龙井，分享茶艺文化...',
    submitterId: 'f_007', submitterNickname: '茶韵人家',
    status: 'approved', reviewerId: 'admin_001', reviewerNickname: '超级管理员',
    submittedAt: NOW - 5 * DAY, reviewedAt: NOW - 4 * DAY
  },
  {
    reviewId: 'r_009', contentType: 'post', contentId: 'post_302',
    contentTitle: '乡村生活记录', contentPreview: '记录在乡村的日常生活...',
    submitterId: 'u_008', submitterNickname: '郑十',
    status: 'approved', reviewerId: 'admin_002', reviewerNickname: '内容审核员',
    submittedAt: NOW - 4 * DAY, reviewedAt: NOW - 3 * DAY
  },
  {
    reviewId: 'r_010', contentType: 'product', contentId: 'p_105',
    contentTitle: '某商品含违规词', contentPreview: '商品描述含敏感词...',
    submitterId: 'f_003', submitterNickname: '丰收之家',
    status: 'rejected', reviewerId: 'admin_002', reviewerNickname: '内容审核员',
    rejectReason: '敏感词', rejectDescription: '商品描述中包含敏感词，请修改后重新提交',
    submittedAt: NOW - 6 * DAY, reviewedAt: NOW - 5 * DAY
  },
  {
    reviewId: 'r_011', contentType: 'product', contentId: 'p_106',
    contentTitle: '图片不清晰商品', contentPreview: '商品主图模糊...',
    submitterId: 'f_003', submitterNickname: '丰收之家',
    status: 'rejected', reviewerId: 'admin_001', reviewerNickname: '超级管理员',
    rejectReason: '图片不清晰', rejectDescription: '商品主图分辨率不足，请重新拍摄上传',
    submittedAt: NOW - 7 * DAY, reviewedAt: NOW - 6 * DAY
  },
  {
    reviewId: 'r_012', contentType: 'live', contentId: 'l_203',
    contentTitle: '描述不符直播', contentPreview: '直播标题与内容不符...',
    submitterId: 'f_003', submitterNickname: '丰收之家',
    status: 'rejected', reviewerId: 'admin_002', reviewerNickname: '内容审核员',
    rejectReason: '描述不符', rejectDescription: '直播标题宣传果园采摘，实际为录制视频',
    submittedAt: NOW - 8 * DAY, reviewedAt: NOW - 7 * DAY
  },
  {
    reviewId: 'r_013', contentType: 'post', contentId: 'post_303',
    contentTitle: '涉嫌违规帖子', contentPreview: '帖子内容含违规信息...',
    submitterId: 'u_003', submitterNickname: '王五',
    status: 'rejected', reviewerId: 'admin_002', reviewerNickname: '内容审核员',
    rejectReason: '涉嫌违规', rejectDescription: '帖子内容涉及违规信息，已驳回处理',
    submittedAt: NOW - 9 * DAY, reviewedAt: NOW - 8 * DAY
  },
  {
    reviewId: 'r_014', contentType: 'report', contentId: 'rep_402',
    contentTitle: '举报：恶意刷单', contentPreview: '该卖家涉嫌刷单...',
    submitterId: 'u_006', submitterNickname: '周八',
    status: 'approved', reviewerId: 'admin_001', reviewerNickname: '超级管理员',
    submittedAt: NOW - 10 * DAY, reviewedAt: NOW - 9 * DAY
  },
  {
    reviewId: 'r_015', contentType: 'product', contentId: 'p_107',
    contentTitle: '坚果大礼包', contentPreview: '精选多种坚果组合装...',
    submitterId: 'f_004', submitterNickname: '绿色农场',
    status: 'pending', submittedAt: NOW - 30 * 60000
  }
];

// ===== Mock 审核历史（针对同一内容的多次提交流转） =====
/** 审核历史条目（reviewId 关联审核记录，history 该审核的历史流转） */
interface ReviewHistoryEntry {
  reviewId: string;
  history: ReviewHistoryItem[];
}

const MOCK_REVIEW_HISTORY_LIST: ReviewHistoryEntry[] = [
  {
    reviewId: 'r_010',
    history: [
      {
        reviewId: 'r_010', status: 'pending',
        reviewedAt: NOW - 6 * DAY, note: '内容首次提交审核'
      },
      {
        reviewId: 'r_010', status: 'rejected', reviewerNickname: '内容审核员',
        rejectReason: '敏感词', rejectDescription: '商品描述中包含敏感词，请修改后重新提交',
        reviewedAt: NOW - 5 * DAY, note: '首次审核驳回，等待卖家修改'
      }
    ]
  },
  {
    reviewId: 'r_011',
    history: [
      {
        reviewId: 'r_011', status: 'pending',
        reviewedAt: NOW - 7 * DAY, note: '商品提交审核'
      },
      {
        reviewId: 'r_011', status: 'rejected', reviewerNickname: '超级管理员',
        rejectReason: '图片不清晰', rejectDescription: '商品主图分辨率不足，请重新拍摄上传',
        reviewedAt: NOW - 6 * DAY, note: '图片质量问题，等待重新提交'
      }
    ]
  }
];

// ===== 分页查询函数 =====

/**
 * Mock 用户列表分页查询（spec 3.3.1：支持账号/手机号/昵称/类型/状态筛选）
 */
export function getMockUsers(query: UserListQuery): PageResult<UserRecord> {
  let filtered: UserRecord[] = MOCK_USERS.slice();
  if (query.keyword && query.keyword.length > 0) {
    const kw: string = query.keyword.toLowerCase();
    filtered = filtered.filter((u: UserRecord): boolean => {
      return u.userId.toLowerCase().indexOf(kw) >= 0 ||
        u.nickname.toLowerCase().indexOf(kw) >= 0 ||
        u.phone.indexOf(kw) >= 0;
    });
  }
  if (query.phone && query.phone.length > 0) {
    filtered = filtered.filter((u: UserRecord): boolean => u.phone.indexOf(query.phone!) >= 0);
  }
  if (query.nickname && query.nickname.length > 0) {
    filtered = filtered.filter((u: UserRecord): boolean => u.nickname.indexOf(query.nickname!) >= 0);
  }
  if (query.userType) {
    filtered = filtered.filter((u: UserRecord): boolean => u.userType === query.userType);
  }
  if (query.status) {
    filtered = filtered.filter((u: UserRecord): boolean => u.status === query.status);
  }
  if (query.startTime) {
    filtered = filtered.filter((u: UserRecord): boolean => u.createdAt >= query.startTime!);
  }
  if (query.endTime) {
    filtered = filtered.filter((u: UserRecord): boolean => u.createdAt <= query.endTime!);
  }
  return paginate(filtered, query.page, query.size);
}

/**
 * Mock 用户详情聚合数据（spec 3.3.1：基本信息 + 订单/内容/设备历史）
 */
export function getMockUserDetail(userId: string): UserDetailAggregate | null {
  const user: UserRecord | undefined = MOCK_USERS.find((u: UserRecord): boolean => u.userId === userId);
  if (!user) {
    return null;
  }
  const aggregate: UserDetailAggregate = {
    user: user,
    buyerOrderCount: user.userType === 'user' ? 12 : 0,
    farmerOrderCount: user.userType === 'farmer' ? 358 : 0,
    publishedProducts: user.userType === 'farmer' ? 24 : 0,
    publishedPosts: 8,
    publishedLives: user.userType === 'farmer' ? 12 : 0,
    loginDevices: MOCK_LOGIN_DEVICES
  };
  return aggregate;
}

/**
 * Mock API 列表分页查询（spec 3.3.2：支持路径搜索）
 */
export function getMockApis(query: ApiListQuery): PageResult<ApiInfo> {
  let filtered: ApiInfo[] = MOCK_APIS.slice();
  if (query.keyword && query.keyword.length > 0) {
    const kw: string = query.keyword.toLowerCase();
    filtered = filtered.filter((a: ApiInfo): boolean => {
      return a.path.toLowerCase().indexOf(kw) >= 0 ||
        a.description.toLowerCase().indexOf(kw) >= 0;
    });
  }
  return paginate(filtered, query.page, query.size);
}

/**
 * Mock API 详情聚合数据（spec 3.3.2：基本信息 + 趋势 + 错误日志）
 */
export function getMockApiDetail(apiId: string): ApiDetailAggregate | null {
  const apiInfo: ApiInfo | undefined = MOCK_APIS.find((a: ApiInfo): boolean => a.apiId === apiId);
  if (!apiInfo) {
    return null;
  }
  const aggregate: ApiDetailAggregate = {
    apiInfo: apiInfo,
    trend: MOCK_API_TREND_7D,
    recentErrors: MOCK_API_ERROR_LOGS.filter((log: ApiErrorLog): boolean => log.apiId === apiId)
  };
  // 若该 API 没有专属错误日志，返回全部 Mock 错误日志作为兜底展示
  if (aggregate.recentErrors.length === 0) {
    aggregate.recentErrors = MOCK_API_ERROR_LOGS;
  }
  return aggregate;
}

/**
 * Mock 限流配置（spec 3.3.2）
 */
export function getMockRateLimitConfig(apiId: string): RateLimitConfig | null {
  const cfg: RateLimitConfig | undefined = MOCK_RATE_LIMIT_CONFIGS.find(
    (c: RateLimitConfig): boolean => c.apiId === apiId
  );
  return cfg ? cfg : null;
}

/**
 * Mock API 密钥列表（spec 3.3.2）
 */
export function getMockApiKeys(): ApiKey[] {
  return MOCK_API_KEYS.slice();
}

/**
 * Mock 创建 API 密钥（spec 3.3.2：仅展示一次 Secret）
 */
export function getMockCreatedApiKey(): CreateApiKeyResponse {
  const response: CreateApiKeyResponse = {
    keyId: `key_${Date.now()}`,
    appKey: `ZN_APP_${generateRandomString(15)}`,
    appSecret: `secret_${generateRandomString(24)}`,
    createdAt: Date.now()
  };
  return response;
}

/**
 * Mock 审核列表分页查询（spec 3.3.3：支持类型/状态筛选）
 */
export function getMockReviews(query: ReviewListQuery): PageResult<ContentReview> {
  let filtered: ContentReview[] = MOCK_REVIEWS.slice();
  if (query.contentType) {
    filtered = filtered.filter((r: ContentReview): boolean => r.contentType === query.contentType);
  }
  if (query.status) {
    filtered = filtered.filter((r: ContentReview): boolean => r.status === query.status);
  }
  return paginate(filtered, query.page, query.size);
}

/**
 * Mock 审核详情聚合数据（spec 3.3.3：含历史记录）
 */
export function getMockReviewDetail(reviewId: string): ReviewDetailAggregate | null {
  const review: ContentReview | undefined = MOCK_REVIEWS.find(
    (r: ContentReview): boolean => r.reviewId === reviewId
  );
  if (!review) {
    return null;
  }
  const historyEntry: ReviewHistoryEntry | undefined = MOCK_REVIEW_HISTORY_LIST.find(
    (e: ReviewHistoryEntry): boolean => e.reviewId === reviewId
  );
  const history: ReviewHistoryItem[] = historyEntry ? historyEntry.history : [
    {
      reviewId: review.reviewId,
      status: review.status,
      reviewerNickname: review.reviewerNickname,
      rejectReason: review.rejectReason,
      rejectDescription: review.rejectDescription,
      reviewedAt: review.reviewedAt || review.submittedAt,
      note: review.status === 'pending' ? '内容已提交，等待审核' : '审核完成'
    }
  ];
  const aggregate: ReviewDetailAggregate = {
    review: review,
    history: history
  };
  return aggregate;
}

/**
 * Mock 待审核数量（spec 3.3.3：admin_home 红点数字）
 */
export function getMockPendingReviewCount(): number {
  return MOCK_REVIEWS.filter((r: ContentReview): boolean => r.status === 'pending').length;
}

// ===== Mock 广告数据（spec 3.3.4，对齐 admin-ads.html 设计稿） =====

/**
 * Mock 广告列表（4 条，覆盖 4 种广告位 × 4 种状态）
 * 数据对齐 admin-ads.html：
 *  - 丰收节大促（首页Banner · 投放中）
 *  - 新茶上市（开屏广告 · 投放中）
 *  - 草莓季（直播贴片 · 已暂停）
 *  - 助农故事（社区推荐 · 待审核）
 */
export const MOCK_ADS: AdRecord[] = [
  {
    adId: 'ad_001',
    title: '丰收节大促',
    slot: 'home_banner',
    status: 'running',
    enabled: true,
    coverKey: 'hero_harvest',
    impressions: 125000,
    clicks: 3860,
    ctr: 0.031,
    cost: 2580,
    startAt: NOW + 2 * DAY, // 7/20
    endAt: NOW + 12 * DAY,  // 7/30
    audiences: ['all'],
    isScheduled: false,
    createdAt: NOW - 5 * DAY
  },
  {
    adId: 'ad_002',
    title: '新茶上市',
    slot: 'splash',
    status: 'running',
    enabled: true,
    coverKey: 'hero_harvest',
    impressions: 82000,
    clicks: 2140,
    ctr: 0.026,
    cost: 1640,
    startAt: NOW,           // 7/18
    endAt: NOW + 7 * DAY,   // 7/25
    audiences: ['all', 'new_user'],
    isScheduled: false,
    createdAt: NOW - 6 * DAY
  },
  {
    adId: 'ad_003',
    title: '草莓季',
    slot: 'live_patch',
    status: 'paused',
    enabled: false,
    coverKey: 'hero_harvest',
    impressions: 56000,
    clicks: 1820,
    ctr: 0.033,
    cost: 1120,
    startAt: NOW - 3 * DAY, // 7/15
    endAt: NOW + 4 * DAY,   // 7/22
    audiences: ['old_user', 'high_freq'],
    isScheduled: false,
    createdAt: NOW - 10 * DAY
  },
  {
    adId: 'ad_004',
    title: '助农故事',
    slot: 'community',
    status: 'pending',
    enabled: true,
    coverKey: 'hero_harvest',
    impressions: 30000, // 预估曝光
    clicks: 0,
    ctr: 0,
    cost: 800, // 预算
    startAt: 0,
    endAt: 0,
    audiences: ['all'],
    isScheduled: true, // 待排期
    createdAt: NOW - 1 * DAY
  }
];

/**
 * Mock 广告列表查询（spec 3.3.4：广告位筛选 + 分页）
 */
export function getMockAds(query: AdListQuery): PageResult<AdRecord> {
  let list: AdRecord[] = MOCK_ADS;
  if (query.slot) {
    list = list.filter((ad: AdRecord): boolean => ad.slot === query.slot);
  }
  return paginate<AdRecord>(list, query.page, query.size);
}

/**
 * Mock 广告概览统计（spec 3.3.4：投放中/待审核/已暂停）
 */
export function getMockAdOverviewStats(): AdOverviewStats {
  const stats: AdOverviewStats = {
    running: MOCK_ADS.filter((a: AdRecord): boolean => a.status === 'running').length,
    pending: MOCK_ADS.filter((a: AdRecord): boolean => a.status === 'pending').length,
    paused: MOCK_ADS.filter((a: AdRecord): boolean => a.status === 'paused').length
  };
  return stats;
}

/**
 * Mock 切换广告启用状态（spec 3.3.4：开关切换）
 */
export function toggleMockAdEnabled(adId: string): AdRecord | null {
  const ad: AdRecord | undefined = MOCK_ADS.find((a: AdRecord): boolean => a.adId === adId);
  if (!ad) {
    return null;
  }
  ad.enabled = !ad.enabled;
  // 投放中 ↔ 已暂停 联动（待审核不变）
  if (ad.status === 'running') {
    ad.status = 'paused';
  } else if (ad.status === 'paused') {
    ad.status = 'running';
  }
  return ad;
}

/**
 * Mock 创建广告（spec 3.3.4：新建广告表单提交）
 */
export function createMockAd(req: AdCreateRequest): AdRecord {
  const adId: string = `ad_${String(MOCK_ADS.length + 1).padStart(3, '0')}`;
  const newAd: AdRecord = {
    adId,
    title: req.title,
    slot: req.slot,
    status: 'pending',
    enabled: false,
    coverKey: req.coverKey,
    impressions: 0,
    clicks: 0,
    ctr: 0,
    cost: req.budget,
    startAt: req.startAt,
    endAt: req.endAt,
    audiences: req.audiences,
    isScheduled: req.startAt === 0,
    createdAt: Date.now()
  };
  MOCK_ADS.unshift(newAd);
  return newAd;
}

// ===== 内部工具函数 =====

/** 通用分页工具 */
function paginate<T>(list: T[], page: number, size: number): PageResult<T> {
  const total: number = list.length;
  const start: number = (page - 1) * size;
  const end: number = Math.min(start + size, total);
  const pageList: T[] = list.slice(start, end);
  const result: PageResult<T> = {
    list: pageList,
    total: total,
    page: page,
    size: size,
    hasMore: end < total
  };
  return result;
}

/** 生成随机字符串（用于 Mock AppKey/AppSecret） */
function generateRandomString(length: number): string {
  const chars: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result: string = '';
  for (let i = 0; i < length; i++) {
    const idx: number = Math.floor(Math.random() * chars.length);
    result += chars.charAt(idx);
  }
  return result;
}
