/**
 * common/Index.ets - HAR 库统一导出入口
 * 遵循 spec 2.2.3：HAR 库通过 Index.ets 统一对外暴露 API
 * 三端 entry 模块通过 import { ... } from 'common' 引用
 * spec 10.9：Phase 6 任务1 新增 NavigationHelper / RouteName / AppStorageV2 Key 类型
 * spec 10.16（v2.8）：ConfirmDialog V1 组件已删除，自定义弹窗统一方案 C 自建模态
 */

// ===== 常量 =====
export { AppConstants } from './src/main/ets/constants/AppConstants';

// ===== 工具类 =====
export { Logger } from './src/main/ets/utils/Logger';
export type { LogInfo } from './src/main/ets/utils/Logger';
export { ConfigUtil } from './src/main/ets/utils/ConfigUtil';
export { PreferencesUtil } from './src/main/ets/utils/PreferencesUtil';
export { HttpUtil } from './src/main/ets/utils/HttpUtil';
/** 本地 Mock 鉴权工具（无后端时使用，spec 11.x：账号密码登录注册） */
export { MockAuthUtil } from './src/main/ets/utils/MockAuthUtil';
export { ToastUtil } from './src/main/ets/utils/ToastUtil';
/** spec 10.9.2：声明式路由跳转工具（替代 router.pushUrl/replaceUrl/back/getParams） */
export { NavigationHelper } from './src/main/ets/utils/NavigationHelper';
/** spec 16.6：老人模式全局字体放大工具 */
export { FontUtil } from './src/main/ets/utils/FontUtil';

// ===== Repository 基础设施（spec 10.3：先 REST 后 Mock 兜底） =====
export { BaseRepository } from './src/main/ets/repository/BaseRepository';
/** spec 16.3：共享商品池（农户端发布 → 用户端读取，跨端同步） */
export { SharedProductStore } from './src/main/ets/repository/SharedProductStore';
export type { SharedProduct } from './src/main/ets/repository/SharedProductStore';
/** 共享直播池（农户端开播 → 用户端读取，跨端同步） */
export { SharedLiveStore } from './src/main/ets/repository/SharedLiveStore';
export type { SharedLive } from './src/main/ets/repository/SharedLiveStore';
/** 共享帖子池（农户端发帖 → 用户端读取，跨端同步） */
export { SharedPostStore } from './src/main/ets/repository/SharedPostStore';
export type { SharedPost } from './src/main/ets/repository/SharedPostStore';

// ===== ViewModel 基础设施（spec 10.11.3：LazyForEach 通用数据源基类） =====
export { BaseDataSource } from './src/main/ets/viewmodel/BaseDataSource';

// ===== 状态管理 =====
export { ModeStore } from './src/main/ets/store/ModeStore';
export { ThemeStore } from './src/main/ets/store/ThemeStore';
export { TokenStore } from './src/main/ets/store/TokenStore';

// ===== 路由表 =====
export { UserRoutes, FarmerRoutes, AdminRoutes } from './src/main/ets/router/AppRouter';
export type { RouterParam } from './src/main/ets/router/AppRouter';
/** spec 10.9.2：声明式路由名常量（NavPathStack.pushPath 使用的 name） */
export { RouteName } from './src/main/ets/router/AppRouter';

// ===== 数据模型 =====
export type {
  ApiResponse,
  PageResult,
  /** spec 10.11.3：BaseDataSource.fetchPage 返回类型 */
  FetchPageResult,
  PageParam,
  JwtPayload,
  UserInfo,
  AdminInfo,
  OrderStatus,
  ProductStatus,
  LiveStatus,
  ReviewStatus,
  PostStatus,
  UserType,
  AccountStatus,
  SortOrder,
  KeyValue
} from './src/main/ets/model/CommonModels';
/** spec 10.9.3：AppStorageV2 Key 类（class 既是类型也是值，需用 export 导出） */
export {
  AuthTokenKey,
  UserInfoKey,
  AdminInfoKey,
  CurrentModeKey,
  CurrentThemeKey,
  AuthExpiredKey
} from './src/main/ets/model/CommonModels';

// ===== 兜底组件 =====
/** spec 10.14（v2.6）：4 态状态机统一状态视图（loading/error/empty），替代各页内联 @Builder */
/** spec 10.17（v2.9）：empty 态增强为 image/emoji 双模式，删除 EmptyState(死代码)+EmptyStateCard(被吸收) */
export { ListStateView } from './src/main/ets/components/ListStateView';
export type { ListState } from './src/main/ets/components/ListStateView';
export { ErrorToast } from './src/main/ets/components/ErrorToast';

// ===== UI 复刻公共组件（spec 15.4.1：13 个 Qn* 组件，对齐 colors_and_type.css） =====
export { QnStatusBar } from './src/main/ets/components/QnStatusBar';
export { QnTopBar } from './src/main/ets/components/QnTopBar';
export { QnTabBar } from './src/main/ets/components/QnTabBar';
export type { QnTabBarRole } from './src/main/ets/components/QnTabBar';
export { QnCard } from './src/main/ets/components/QnCard';
export type { QnCardVariant } from './src/main/ets/components/QnCard';
export { QnButton } from './src/main/ets/components/QnButton';
export type { QnButtonVariant, QnButtonSize } from './src/main/ets/components/QnButton';
export { QnPill } from './src/main/ets/components/QnPill';
export type { QnPillVariant } from './src/main/ets/components/QnPill';
export { QnSearchBar } from './src/main/ets/components/QnSearchBar';
export { QnInput } from './src/main/ets/components/QnInput';
export type { QnInputType } from './src/main/ets/components/QnInput';
export { QnAvatar } from './src/main/ets/components/QnAvatar';
export { QnPrice } from './src/main/ets/components/QnPrice';
export { QnStatRow } from './src/main/ets/components/QnStatRow';
export { QnSectionHead } from './src/main/ets/components/QnSectionHead';
export { QnSheet } from './src/main/ets/components/QnSheet';
