/**
 * AppRouter - 公共路由表与命名规范
 * 遵循 spec 2.2.3 / 5.1 / 5.2 / 5.3：
 *  - 路由路径小写下划线 pages/<模块>/<页面>
 *  - 统一管理三端路由常量，避免硬编码字符串
 *  - 各端可按需引用对应模块的路由
 */

export class UserRoutes {
  /** 首页Tab */
  static readonly HOME: string = 'pages/home/home_page';
  /** 社区Tab */
  static readonly COMMUNITY_LIST: string = 'pages/community/community_list';
  /** 帖子详情 */
  static readonly POST_DETAIL: string = 'pages/community/post_detail';
  /** 发帖页 */
  static readonly POST_CREATE: string = 'pages/community/post_create';
  /** 消息Tab */
  static readonly MESSAGE_LIST: string = 'pages/message/message_list';
  /** 会话详情 */
  static readonly CHAT_DETAIL: string = 'pages/message/chat_detail';
  /** 购物车Tab */
  static readonly CART: string = 'pages/cart/cart_page';
  /** 个人中心Tab */
  static readonly PROFILE: string = 'pages/profile/profile_page';
  /** 设置 */
  static readonly SETTING: string = 'pages/profile/setting';
  /** 地址管理 */
  static readonly ADDRESS_LIST: string = 'pages/profile/address_list';
  /** 地址编辑 */
  static readonly ADDRESS_EDIT: string = 'pages/profile/address_edit';
  /** 我的收藏 */
  static readonly FAVORITE_LIST: string = 'pages/profile/favorite_list';
  /** 我的关注 */
  static readonly FOLLOW_LIST: string = 'pages/profile/follow_list';
  /** 浏览历史 */
  static readonly HISTORY_LIST: string = 'pages/profile/history_list';
  /** 优惠券 */
  static readonly COUPON_LIST: string = 'pages/profile/coupon_list';
  /** 我的钱包 */
  static readonly WALLET: string = 'pages/profile/wallet';
  /** 搜索页 */
  static readonly SEARCH_PAGE: string = 'pages/search/search_page';
  /** 搜索结果页 */
  static readonly SEARCH_RESULT: string = 'pages/search/search_result';
  /** 分类页 */
  static readonly CATEGORY_LIST: string = 'pages/mall/category_list';
  /** 商品列表 */
  static readonly PRODUCT_LIST: string = 'pages/mall/product_list';
  /** 商品详情 */
  static readonly PRODUCT_DETAIL: string = 'pages/mall/product_detail';
  /** 确认订单 */
  static readonly ORDER_CONFIRM: string = 'pages/mall/order_confirm';
  /** 收银台（支付页） */
  static readonly PAYMENT: string = 'pages/mall/payment';
  /** 订单列表 */
  static readonly ORDER_LIST: string = 'pages/mall/order_list';
  /** 订单详情 */
  static readonly ORDER_DETAIL: string = 'pages/mall/order_detail';
  /** 评价提交 */
  static readonly REVIEW_CREATE: string = 'pages/mall/review_create';
  /** 卖家店铺主页 */
  static readonly SHOP_HOME: string = 'pages/mall/shop_home';
  /** 直播浏览页 */
  static readonly LIVE_LIST: string = 'pages/live/live_list';
  /** 直播间 */
  static readonly LIVE_ROOM: string = 'pages/live/live_room';
  /** 文旅地图 */
  static readonly TRAVEL_MAP: string = 'pages/travel/travel_map';
  /** POI详情 */
  static readonly POI_DETAIL: string = 'pages/travel/poi_detail';
  /** 开屏广告 */
  static readonly SPLASH_AD: string = 'pages/splash/splash_ad';
}

export class FarmerRoutes {
  /** 首页Tab（营收面板） */
  static readonly HOME: string = 'pages/home/home_page';
  /** 营收明细 */
  static readonly REVENUE_DETAIL: string = 'pages/home/revenue_detail';
  /** 商城页（顶部导航） */
  static readonly SELLER_MALL: string = 'pages/mall/seller_mall_page';
  /** 商品上架发布 */
  static readonly PRODUCT_PUBLISH: string = 'pages/mall/product_publish';
  /** 商品编辑 */
  static readonly PRODUCT_EDIT: string = 'pages/mall/product_edit';
  /** 直播浏览（顶导） */
  static readonly LIVE_BROWSE: string = 'pages/live/live_browse';
  /** 开播表单 */
  static readonly LIVE_CREATE: string = 'pages/live/live_create';
  /** 直播间（主播端） */
  static readonly LIVE_ROOM: string = 'pages/live/live_room';
  /** 智能体页 */
  static readonly AGENT_PAGE: string = 'pages/agent/agent_page';
  /** 搜索页（同用户端） */
  static readonly SEARCH_PAGE: string = 'pages/search/search_page';
  /** 社区Tab */
  static readonly COMMUNITY_LIST: string = 'pages/community/community_list';
  /** 帖子详情 */
  static readonly POST_DETAIL: string = 'pages/community/post_detail';
  /** 发帖 */
  static readonly POST_CREATE: string = 'pages/community/post_create';
  /** 消息Tab */
  static readonly MESSAGE_LIST: string = 'pages/message/message_list';
  /** 会话详情 */
  static readonly CHAT_DETAIL: string = 'pages/message/chat_detail';
  /** 卖家个人中心 */
  static readonly SELLER_PROFILE: string = 'pages/profile/seller_profile';
  /** 商品管理 */
  static readonly PRODUCT_MANAGE: string = 'pages/profile/product_manage';
  /** 直播管理 */
  static readonly LIVE_MANAGE: string = 'pages/profile/live_manage';
  /** 提现 */
  static readonly WITHDRAW: string = 'pages/profile/withdraw';
  /** 营收统计 */
  static readonly REVENUE_STATS: string = 'pages/profile/revenue_stats';
  /** 粉丝列表 */
  static readonly FANS_LIST: string = 'pages/profile/fans_list';
  /** 资质认证 */
  static readonly CERTIFICATION: string = 'pages/profile/certification';
  /** 设置 */
  static readonly SETTING: string = 'pages/profile/setting';
  /** 开屏广告 */
  static readonly SPLASH_AD: string = 'pages/splash/splash_ad';
}

export class AdminRoutes {
  /** 管理员登录 */
  static readonly LOGIN: string = 'pages/login/admin_login';
  /** 管理员注册 */
  static readonly REGISTER: string = 'pages/login/admin_register';
  /** 后台首页（侧边栏） */
  static readonly HOME: string = 'pages/home/admin_home';
  /** 用户列表 */
  static readonly USER_LIST: string = 'pages/user_manage/user_list';
  /** 用户详情 */
  static readonly USER_DETAIL: string = 'pages/user_manage/user_detail';
  /** API列表 */
  static readonly API_LIST: string = 'pages/api_manage/api_list';
  /** API详情 */
  static readonly API_DETAIL: string = 'pages/api_manage/api_detail';
  /** 限流配置 */
  static readonly RATE_LIMIT: string = 'pages/api_manage/rate_limit';
  /** 密钥管理 */
  static readonly API_KEY: string = 'pages/api_manage/api_key';
  /** 审核列表 */
  static readonly REVIEW_LIST: string = 'pages/content_review/review_list';
  /** 审核详情 */
  static readonly REVIEW_DETAIL: string = 'pages/content_review/review_detail';
  /** 广告管理列表 */
  static readonly ADS_LIST: string = 'pages/ads_manage/ads_list';
}

/**
 * 路由跳转参数类型
 * ArkTS 规则适配（arkts-no-indexed-signatures）：
 *  - 禁止使用 interface 中的索引签名 [key: string]: T
 *  - 改用 Record 工具类型，ArkTS 内建支持
 */
export type RouterParam = Record<string, string | number | boolean>;

/**
 * RouteName - Navigation 声明式路由名常量
 * 遵循 spec 10.9.2：router.pushUrl/replaceUrl/back/getParams → NavPathStack 声明式路由
 *
 * 1) 此处的 name 字符串对应各端 route_map.json 中的 name 字段；
 * 2) 同一 name 字符串可在不同端复用（route_map.json 按 module 注册，互不冲突）；
 * 3) 三端 EntryAbility 加载 root_page，root_page 内部持有 NavPathStack 实例并注册 @Builder；
 * 4) 调用方通过 NavigationHelper.push(RouteName.XXX, param) 跳转；
 *
 * 设计原则：
 *  - 保留 UserRoutes/FarmerRoutes/AdminRoutes 原路径常量（用于 main_pages.json 兼容与回退兜底）；
 *  - RouteName 仅用于声明式路由跳转；
 *  - name 字符串与页面文件名一致（去 pages/ 前缀，去 _page 后缀，但保留语义）。
 */
export class RouteName {
  // ===== User 端路由名（对应 user 模块 route_map.json 中的 name） =====
  /** 开屏广告 */
  static readonly USER_SPLASH: string = 'splash_ad';
  /** 用户登录 */
  static readonly USER_LOGIN: string = 'user_login';
  /** 用户注册 */
  static readonly USER_REGISTER: string = 'user_register';
  /** 首页Tab */
  static readonly USER_HOME: string = 'home_page';
  /** 社区Tab */
  static readonly USER_COMMUNITY_LIST: string = 'community_list';
  /** 帖子详情 */
  static readonly USER_POST_DETAIL: string = 'post_detail';
  /** 发帖页 */
  static readonly USER_POST_CREATE: string = 'post_create';
  /** 消息Tab */
  static readonly USER_MESSAGE_LIST: string = 'message_list';
  /** 会话详情 */
  static readonly USER_CHAT_DETAIL: string = 'chat_detail';
  /** 购物车Tab */
  static readonly USER_CART: string = 'cart_page';
  /** 个人中心Tab */
  static readonly USER_PROFILE: string = 'profile_page';
  /** 设置 */
  static readonly USER_SETTING: string = 'setting';
  /** 地址管理 */
  static readonly USER_ADDRESS_LIST: string = 'address_list';
  /** 地址编辑 */
  static readonly USER_ADDRESS_EDIT: string = 'address_edit';
  /** 我的收藏 */
  static readonly USER_FAVORITE_LIST: string = 'favorite_list';
  /** 我的关注 */
  static readonly USER_FOLLOW_LIST: string = 'follow_list';
  /** 浏览历史 */
  static readonly USER_HISTORY_LIST: string = 'history_list';
  /** 优惠券 */
  static readonly USER_COUPON_LIST: string = 'coupon_list';
  /** 我的钱包 */
  static readonly USER_WALLET: string = 'wallet';
  /** 搜索页 */
  static readonly USER_SEARCH_PAGE: string = 'search_page';
  /** 搜索结果页 */
  static readonly USER_SEARCH_RESULT: string = 'search_result';
  /** 分类页 */
  static readonly USER_CATEGORY_LIST: string = 'category_list';
  /** 商品列表 */
  static readonly USER_PRODUCT_LIST: string = 'product_list';
  /** 商品详情 */
  static readonly USER_PRODUCT_DETAIL: string = 'product_detail';
  /** 确认订单 */
  static readonly USER_ORDER_CONFIRM: string = 'order_confirm';
  /** 收银台（支付页） */
  static readonly USER_PAYMENT: string = 'payment';
  /** 订单列表 */
  static readonly USER_ORDER_LIST: string = 'order_list';
  /** 订单详情 */
  static readonly USER_ORDER_DETAIL: string = 'order_detail';
  /** 评价提交 */
  static readonly USER_REVIEW_CREATE: string = 'review_create';
  /** 卖家店铺主页 */
  static readonly USER_SHOP_HOME: string = 'shop_home';
  /** 直播浏览页 */
  static readonly USER_LIVE_LIST: string = 'live_list';
  /** 直播间 */
  static readonly USER_LIVE_ROOM: string = 'live_room';
  /** 文旅地图 */
  static readonly USER_TRAVEL_MAP: string = 'travel_map';
  /** POI详情 */
  static readonly USER_POI_DETAIL: string = 'poi_detail';
  /** 体验预约 */
  static readonly USER_BOOKING: string = 'user_booking';

  // ===== Farmer 端路由名（对应 farmer 模块 route_map.json 中的 name） =====
  /** 开屏广告 */
  static readonly FARMER_SPLASH: string = 'splash_ad';
  /** 农户登录 */
  static readonly FARMER_LOGIN: string = 'farmer_login';
  /** 农户注册 */
  static readonly FARMER_REGISTER: string = 'farmer_register';
  /** 首页Tab（营收面板） */
  static readonly FARMER_HOME: string = 'home_page';
  /** 营收明细 */
  static readonly FARMER_REVENUE_DETAIL: string = 'revenue_detail';
  /** 商城页（顶部导航） */
  static readonly FARMER_SELLER_MALL: string = 'seller_mall_page';
  /** 商品上架发布 */
  static readonly FARMER_PRODUCT_PUBLISH: string = 'product_publish';
  /** 商品编辑 */
  static readonly FARMER_PRODUCT_EDIT: string = 'product_edit';
  /** 直播浏览（顶导） */
  static readonly FARMER_LIVE_BROWSE: string = 'live_browse';
  /** 开播表单 */
  static readonly FARMER_LIVE_CREATE: string = 'live_create';
  /** 直播间（主播端） */
  static readonly FARMER_LIVE_ROOM: string = 'live_room';
  /** 智能体页 */
  static readonly FARMER_AGENT_PAGE: string = 'agent_page';
  /** 搜索页 */
  static readonly FARMER_SEARCH_PAGE: string = 'search_page';
  /** 社区Tab */
  static readonly FARMER_COMMUNITY_LIST: string = 'community_list';
  /** 帖子详情 */
  static readonly FARMER_POST_DETAIL: string = 'post_detail';
  /** 发帖 */
  static readonly FARMER_POST_CREATE: string = 'post_create';
  /** 消息Tab */
  static readonly FARMER_MESSAGE_LIST: string = 'message_list';
  /** 会话详情 */
  static readonly FARMER_CHAT_DETAIL: string = 'chat_detail';
  /** 卖家个人中心 */
  static readonly FARMER_SELLER_PROFILE: string = 'seller_profile';
  /** 商品管理 */
  static readonly FARMER_PRODUCT_MANAGE: string = 'product_manage';
  /** 直播管理 */
  static readonly FARMER_LIVE_MANAGE: string = 'live_manage';
  /** 提现 */
  static readonly FARMER_WITHDRAW: string = 'withdraw';
  /** 营收统计 */
  static readonly FARMER_REVENUE_STATS: string = 'revenue_stats';
  /** 粉丝列表 */
  static readonly FARMER_FANS_LIST: string = 'fans_list';
  /** 资质认证 */
  static readonly FARMER_CERTIFICATION: string = 'certification';
  /** 设置 */
  static readonly FARMER_SETTING: string = 'setting';
  /** 市场行情 */
  static readonly FARMER_MARKET_QUOTE: string = 'market_quote';

  // ===== Admin 端路由名（对应 admin 模块 route_map.json 中的 name） =====
  /** 管理员登录 */
  static readonly ADMIN_LOGIN: string = 'admin_login';
  /** 管理员注册 */
  static readonly ADMIN_REGISTER: string = 'admin_register';
  /** 后台首页（侧边栏） */
  static readonly ADMIN_HOME: string = 'admin_home';
  /** 用户列表 */
  static readonly ADMIN_USER_LIST: string = 'user_list';
  /** 用户详情 */
  static readonly ADMIN_USER_DETAIL: string = 'user_detail';
  /** API列表 */
  static readonly ADMIN_API_LIST: string = 'api_list';
  /** API详情 */
  static readonly ADMIN_API_DETAIL: string = 'api_detail';
  /** 限流配置 */
  static readonly ADMIN_RATE_LIMIT: string = 'rate_limit';
  /** 密钥管理 */
  static readonly ADMIN_API_KEY: string = 'api_key';
  /** 审核列表 */
  static readonly ADMIN_REVIEW_LIST: string = 'review_list';
  /** 审核详情 */
  static readonly ADMIN_REVIEW_DETAIL: string = 'review_detail';
  /** 广告管理列表 */
  static readonly ADMIN_ADS_LIST: string = 'ads_list';
}
