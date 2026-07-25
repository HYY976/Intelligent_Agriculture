/**
 * AdminModels - 管理后台数据模型（spec 3.3 / 4.1.15 / 4.2.3 / 10.8.6）
 * 遵循 spec 2.2.6：所有自定义对象必须先 interface 定义类型再使用，禁止 any/unknown
 * 遵循 spec 10.6.4 / 10.7.5：export type 字符串联合类型 ≠ enum，不能 .XXX 属性访问
 */

/** 管理员角色（与 common/AdminInfo.role 对齐） */
export type AdminRole = 'super_admin' | 'user_admin' | 'content_reviewer' | 'api_admin';

/** 用户类型（spec 4.1.1） */
export type UserRecordType = 'user' | 'farmer';

/** 账号状态（spec 4.1.1） */
export type UserRecordStatus = 'active' | 'banned';

/** 封禁时长（spec 3.3.1） */
export type BanDuration = '1d' | '7d' | '30d' | 'permanent';

/** 内容审核状态（spec 4.1.15，与 common/ReviewStatus 对齐） */
export type AdminReviewStatus = 'pending' | 'approved' | 'rejected';

/** 内容审核类型（spec 4.1.15） */
export type ReviewContentType = 'product' | 'live' | 'post' | 'report';

/** 举报目标类型（spec 4.1.15） */
export type ReportTargetType = 'post' | 'comment' | 'product' | 'live';

/** HTTP 方法（spec 4.2.3） */
export type HttpMethod = 'GET' | 'POST' | 'PUT' | 'DELETE';

/** 密钥状态（spec 4.2.3） */
export type ApiKeyStatus = 'active' | 'revoked';

/** 广告位类型（spec 3.3.4：首页Banner / 开屏 / 直播贴片 / 社区推荐） */
export type AdSlot = 'home_banner' | 'splash' | 'live_patch' | 'community';

/** 广告状态（spec 3.3.4：投放中 / 待审核 / 已暂停 / 已结束） */
export type AdStatus = 'running' | 'pending' | 'paused' | 'ended';

/** 目标人群标签（spec 3.3.4：多选） */
export type AdAudience = 'all' | 'new_user' | 'old_user' | 'high_freq';

/**
 * 用户记录（spec 4.1.1 / 3.3.1）
 * 用于管理后台用户列表与详情展示
 */
export interface UserRecord {
  userId: string;
  phone: string;
  nickname: string;
  avatar: string;
  userType: UserRecordType;
  status: UserRecordStatus;
  banReason?: string;
  banUntil?: number;
  createdAt: number;
  lastLoginAt: number;
  lastLoginIp?: string;
}

/** 用户列表查询参数（spec 3.3.1：多条件搜索） */
export interface UserListQuery {
  keyword?: string;
  phone?: string;
  nickname?: string;
  startTime?: number;
  endTime?: number;
  userType?: UserRecordType;
  status?: UserRecordStatus;
  page: number;
  size: number;
}

/** 用户封禁请求体（spec 3.3.1） */
export interface UserBanRequest {
  reason: string;
  description?: string;
  duration: BanDuration;
}

/** 用户详情聚合数据（spec 3.3.1：基本信息 + 订单/内容/设备历史） */
export interface UserDetailAggregate {
  user: UserRecord;
  buyerOrderCount: number;
  farmerOrderCount: number;
  publishedProducts: number;
  publishedPosts: number;
  publishedLives: number;
  loginDevices: LoginDeviceRecord[];
}

/** 登录设备记录（spec 3.3.1：登录设备/IP 记录） */
export interface LoginDeviceRecord {
  deviceName: string;
  ipAddress: string;
  loginAt: number;
  location?: string;
}

/**
 * 控制台统计数据（spec 10.8.4：admin_home Dashboard 数据）
 */
export interface DashboardStats {
  totalUsers: number;
  totalFarmers: number;
  pendingReviews: number;
  todayOrders: number;
}

/**
 * API 接口信息（spec 4.2.3）
 */
export interface ApiInfo {
  apiId: string;
  path: string;
  method: HttpMethod;
  description: string;
  todayRequestCount: number;
  errorRate: number;
  avgResponseTime: number;
  createdAt: number;
}

/** API 列表查询参数 */
export interface ApiListQuery {
  keyword?: string;
  page: number;
  size: number;
}

/** API 请求量趋势点（spec 3.3.2：折线图数据） */
export interface ApiRequestTrendPoint {
  date: string;
  requestCount: number;
  errorCount: number;
}

/** API 错误日志（spec 3.3.2） */
export interface ApiErrorLog {
  logId: string;
  apiId: string;
  statusCode: number;
  errorMessage: string;
  clientIp: string;
  occurredAt: number;
}

/** API 详情聚合数据 */
export interface ApiDetailAggregate {
  apiInfo: ApiInfo;
  trend: ApiRequestTrendPoint[];
  recentErrors: ApiErrorLog[];
}

/** 限流配置（spec 4.2.3） */
export interface RateLimitConfig {
  configId: string;
  apiId: string;
  qpsLimit: number;
  concurrentLimit: number;
  circuitBreakThreshold: number;
  /** 熔断恢复时间（秒） */
  recoveryTime: number;
  /** 当前峰值 QPS（用于展示"当前峰值 N QPS"） */
  currentQps: number;
  /** 当前状态（normal / circuit_breaking） */
  status: RateLimitStatus;
}

/** 限流状态（spec 4.2.3） */
export type RateLimitStatus = 'normal' | 'circuit_breaking';

/** 限流配置更新请求体 */
export interface RateLimitUpdateRequest {
  apiId: string;
  qpsLimit: number;
  concurrentLimit: number;
  circuitBreakThreshold: number;
  recoveryTime: number;
}

/** API 密钥（spec 4.2.3） */
export interface ApiKey {
  keyId: string;
  appKey: string;
  appSecret?: string;
  status: ApiKeyStatus;
  createdAt: number;
  /** 最后使用时间（0 表示从未使用） */
  lastUsedAt: number;
  revokedAt?: number;
}

/** 创建密钥响应（spec 3.3.2：仅展示一次 Secret） */
export interface CreateApiKeyResponse {
  keyId: string;
  appKey: string;
  appSecret: string;
  createdAt: number;
}

/**
 * 内容审核记录（spec 4.1.15）
 */
export interface ContentReview {
  reviewId: string;
  contentType: ReviewContentType;
  contentId: string;
  contentTitle: string;
  contentPreview?: string;
  contentImages?: string[];
  submitterId: string;
  submitterNickname: string;
  submitterAvatar?: string;
  status: AdminReviewStatus;
  reviewerId?: string;
  reviewerNickname?: string;
  rejectReason?: string;
  rejectDescription?: string;
  submittedAt: number;
  reviewedAt?: number;
}

/** 审核历史记录项（同一内容多次提交流转） */
export interface ReviewHistoryItem {
  reviewId: string;
  status: AdminReviewStatus;
  reviewerNickname?: string;
  rejectReason?: string;
  rejectDescription?: string;
  reviewedAt: number;
  note: string;
}

/** 审核详情聚合数据（含历史） */
export interface ReviewDetailAggregate {
  review: ContentReview;
  history: ReviewHistoryItem[];
}

/** 审核列表查询参数（spec 3.3.3） */
export interface ReviewListQuery {
  contentType?: ReviewContentType;
  status?: AdminReviewStatus;
  page: number;
  size: number;
}

/** 审核驳回请求体（spec 3.3.3） */
export interface ReviewRejectRequest {
  reason: string;
  description?: string;
}

/**
 * 举报记录（spec 4.1.15，作为审核内容的一种）
 */
export interface ReportRecord {
  reportId: string;
  reporterId: string;
  reporterNickname: string;
  targetType: ReportTargetType;
  targetId: string;
  reason: string;
  description?: string;
  status: 'pending' | 'reviewed';
  createdAt: number;
}

// ===== 文案映射常量（spec 10.7.4：与 FarmerModels 一致的模式） =====

/** 用户类型文案 */
export const USER_TYPE_LABELS: Record<UserRecordType, string> = {
  'user': '用户',
  'farmer': '卖家'
};

/** 账号状态文案 */
export const USER_STATUS_LABELS: Record<UserRecordStatus, string> = {
  'active': '正常',
  'banned': '已封禁'
};

/** 封禁时长文案 */
export const BAN_DURATION_LABELS: Record<BanDuration, string> = {
  '1d': '1 天',
  '7d': '7 天',
  '30d': '30 天',
  'permanent': '永久'
};

/** 审核状态文案 */
export const REVIEW_STATUS_LABELS: Record<AdminReviewStatus, string> = {
  'pending': '待审核',
  'approved': '已通过',
  'rejected': '已驳回'
};

/** 审核内容类型文案 */
export const REVIEW_CONTENT_TYPE_LABELS: Record<ReviewContentType, string> = {
  'product': '商品',
  'live': '直播',
  'post': '帖子',
  'report': '举报'
};

/** HTTP 方法文案（用于 Tag 配色映射） */
export const HTTP_METHOD_LABELS: Record<HttpMethod, string> = {
  'GET': 'GET',
  'POST': 'POST',
  'PUT': 'PUT',
  'DELETE': 'DELETE'
};

/** 密钥状态文案 */
export const API_KEY_STATUS_LABELS: Record<ApiKeyStatus, string> = {
  'active': '生效中',
  'revoked': '已吊销'
};

/** 预设封禁原因（spec 3.3.1） */
export const PRESET_BAN_REASONS: string[] = [
  '发布违规内容',
  '恶意刷单',
  '虚假交易',
  '骚扰他人',
  '侵犯知识产权',
  '其他'
];

/** 预设驳回原因（spec 3.3.3 / 10.8.3.3） */
export const PRESET_REJECT_REASONS: string[] = [
  '涉嫌违规',
  '图片不清晰',
  '描述不符',
  '敏感词',
  '其他'
];

// ===== 广告管理模型（spec 3.3.4） =====

/**
 * 广告记录（spec 3.3.4）
 * 用于管理后台广告配置列表展示
 */
export interface AdRecord {
  adId: string;
  title: string;
  slot: AdSlot;
  status: AdStatus;
  /** 启用开关（true=投放中开关开 / false=已暂停开关关） */
  enabled: boolean;
  /** 封面图 key（ImageUtil 映射） */
  coverKey: string;
  /** 曝光数（待审核状态为预估曝光） */
  impressions: number;
  /** 点击数（待审核状态为 0，展示 — ） */
  clicks: number;
  /** 点击率（0-1，待审核状态为 0） */
  ctr: number;
  /** 花费/预算（元） */
  cost: number;
  /** 投放开始时间戳 */
  startAt: number;
  /** 投放结束时间戳 */
  endAt: number;
  /** 目标人群（多选） */
  audiences: AdAudience[];
  /** 是否待排期（无具体时间） */
  isScheduled: boolean;
  createdAt: number;
}

/** 广告列表查询参数（spec 3.3.4：广告位筛选 + 分页） */
export interface AdListQuery {
  slot?: AdSlot;
  page: number;
  size: number;
}

/** 广告概览统计（spec 3.3.4：投放中/待审核/已暂停 数量） */
export interface AdOverviewStats {
  running: number;
  pending: number;
  paused: number;
}

/** 广告创建请求体（spec 3.3.4） */
export interface AdCreateRequest {
  slot: AdSlot;
  title: string;
  coverKey: string;
  startAt: number;
  endAt: number;
  budget: number;
  audiences: AdAudience[];
}

/** 广告位文案 */
export const AD_SLOT_LABELS: Record<AdSlot, string> = {
  'home_banner': '首页Banner',
  'splash': '开屏广告',
  'live_patch': '直播贴片',
  'community': '社区推荐'
};

/** 广告状态文案 */
export const AD_STATUS_LABELS: Record<AdStatus, string> = {
  'running': '投放中',
  'pending': '待审核',
  'paused': '已暂停',
  'ended': '已结束'
};

/** 目标人群文案 */
export const AD_AUDIENCE_LABELS: Record<AdAudience, string> = {
  'all': '全部用户',
  'new_user': '新用户',
  'old_user': '老用户',
  'high_freq': '高频用户'
};
