/**
 * CommonModels - 公共数据模型接口
 * 定义 API 响应、分页结果、通用枚举等共享类型
 * 遵循 spec 2.2.6：所有自定义对象必须先 interface 定义类型再使用，禁止 any/unknown
 */

/** 统一 API 响应结构（spec 2.5.2） */
export interface ApiResponse<T> {
  code: number;
  msg: string;
  data: T | null;
}

/** 分页结果 */
export interface PageResult<T> {
  list: T[];
  total: number;
  page: number;
  size: number;
  hasMore: boolean;
}

/**
 * 单页取数结果（spec 10.11.3：BaseDataSource.fetchPage 返回类型）
 * 仅包含当前页数据列表 + 是否还有更多，不含 total/page/size 等元信息
 */
export interface FetchPageResult<T> {
  /** 当前页数据列表 */
  list: T[];
  /** 是否还有更多数据 */
  hasMore: boolean;
}

/** 分页请求参数 */
export interface PageParam {
  page: number;
  size: number;
  keyword?: string;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

/** JWT Token 解析后的载荷 */
export interface JwtPayload {
  userId: string;
  userType: 'user' | 'farmer' | 'admin';
  role?: string;
  exp: number;
  iat: number;
}

/** 用户基础信息（登录后缓存） */
export interface UserInfo {
  userId: string;
  phone: string;
  nickname: string;
  avatar: string;
  userType: 'user' | 'farmer';
  status: 'active' | 'banned';
  createdAt: number;
  lastLoginAt: number;
}

/** 管理员基础信息 */
export interface AdminInfo {
  adminId: string;
  username: string;
  nickname: string;
  role: 'super_admin' | 'user_admin' | 'content_reviewer' | 'api_admin';
  lastLoginAt: number;
}

/** 订单状态枚举（spec 4.1.6） */
export type OrderStatus =
  | 'pending_payment'
  | 'pending_shipment'
  | 'pending_receipt'
  | 'pending_review'
  | 'completed'
  | 'cancelled'
  | 'refunding'
  | 'refunded';

/** 商品状态枚举（spec 4.1.3） */
export type ProductStatus =
  | 'draft'
  | 'pending_review'
  | 'approved'
  | 'rejected'
  | 'off_shelf';

/** 直播状态枚举（spec 4.1.4） */
export type LiveStatus = 'preview' | 'living' | 'ended';

/** 内容审核状态（spec 4.1.15） */
export type ReviewStatus = 'pending' | 'approved' | 'rejected';

/** 帖子状态（spec 4.1.5） */
export type PostStatus = 'normal' | 'reviewing' | 'rejected' | 'deleted';

/** 用户类型 */
export type UserType = 'user' | 'farmer';

/** 账号状态 */
export type AccountStatus = 'active' | 'banned';

/** 排序方向 */
export type SortOrder = 'asc' | 'desc';

/** 通用 Key-Value 对 */
export interface KeyValue {
  key: string;
  value: string;
}

/**
 * AppStorageV2 Key 类型定义（spec 10.9.3）
 * AppStorageV2.connect 第一个参数需要 class 构造函数（TypeConstructorWithArgs<T>），
 * interface 只能作为类型不能作为值传入，故所有 Key 必须用 class 定义。
 * 用法：AppStorageV2.connect(AuthTokenKey, 'auth_token', () => new AuthTokenKey())
 */
/** JWT Token（字符串） */
export class AuthTokenKey {
  value: string = '';
}

/** 用户信息（用户端/卖家端，null 表示未登录）— @ObservedV2 + @Trace 实现设置页修改后全端同步 */
@ObservedV2
export class UserInfoKey {
  @Trace value: UserInfo | null = null;
}

/** 管理员信息（null 表示未登录） */
export class AdminInfoKey {
  value: AdminInfo | null = null;
}

/** 当前模式（user/farmer，双角色切换）— spec 10.18：@ObservedV2 + @Trace 实现响应式广播 */
@ObservedV2
export class CurrentModeKey {
  @Trace value: string = '';
}

/** 当前主题（light/dark/auto）— spec 10.18：@ObservedV2 + @Trace 实现响应式广播 */
@ObservedV2
export class CurrentThemeKey {
  @Trace value: string = '';
}

/** 鉴权过期时间戳（HttpUtil 401 时广播，由各端 EntryAbility 监听并跳转登录） */
export class AuthExpiredKey {
  value: number = 0;
}
