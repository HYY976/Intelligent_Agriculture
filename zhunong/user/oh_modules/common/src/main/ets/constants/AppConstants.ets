/**
 * AppConstants - 智农平台全局常量定义
 * 集中管理场景名、Preferences键名、HTTP超时、错误码等常量，避免硬编码
 */

export class AppConstants {
  /** 三端 Logger 场景名（spec 2.2.5） */
  static readonly SCENE_USER: string = 'ZhuNongUser';
  static readonly SCENE_FARMER: string = 'ZhuNongFarmer';
  static readonly SCENE_ADMIN: string = 'ZhuNongAdmin';
  static readonly SCENE_COMMON: string = 'ZhuNongCommon';

  /** Preferences 键名（spec 2.1.3 / 2.3.1） */
  static readonly KEY_MODE: string = 'mode_setting';
  static readonly KEY_THEME: string = 'theme_setting';
  static readonly KEY_TOKEN: string = 'jwt_token';
  static readonly KEY_USER_INFO: string = 'user_info';
  static readonly KEY_SEARCH_HISTORY: string = 'search_history';

  /** 模式枚举（spec 2.1.3） */
  static readonly MODE_STANDARD: string = 'standard';
  static readonly MODE_ELDER: string = 'elder';

  /** 主题枚举（spec 2.3.1） */
  static readonly THEME_LIGHT: string = 'light';
  static readonly THEME_DARK: string = 'dark';
  static readonly THEME_SYSTEM: string = 'system';

  /** HTTP 超时（毫秒，spec 2.2.4） */
  static readonly HTTP_TIMEOUT_DEFAULT: number = 15000;
  /** spec 16.7：AI 智能体调用首请求可能涉及冷启动 + LLM 推理，超时放宽至 120s */
  static readonly HTTP_TIMEOUT_AI: number = 120000;

  /** 分页默认值（spec 3.1.3.1） */
  static readonly PAGE_SIZE_DEFAULT: number = 20;
  static readonly LIST_CACHED_COUNT: number = 5;
  static readonly LIST_LOAD_MORE_THRESHOLD: number = 100;

  /** 错误码（spec 2.5.2 / 8.4） */
  static readonly CODE_SUCCESS: number = 200;
  static readonly CODE_PARAM_ERROR: number = 400;
  static readonly CODE_UNAUTHORIZED: number = 401;
  static readonly CODE_RATE_LIMIT: number = 429;
  static readonly CODE_SERVER_ERROR: number = 500;
  static readonly CODE_AI_TIMEOUT: number = 504;

  /** WebSocket 心跳与重连（spec 3.1.3.3） */
  static readonly WS_HEARTBEAT_INTERVAL: number = 30000;
  static readonly WS_RECONNECT_DELAYS: number[] = [1000, 2000, 4000, 8000, 16000, 30000];
  static readonly WS_MAX_RECONNECT_INDEX: number = 5;

  /** 开屏广告（spec 3.1.2.2） */
  static readonly SPLASH_DISPLAY_MS: number = 5000;
  static readonly SPLASH_MAX_AD_COUNT: number = 2;

  /** 三端 bundleName（spec 1.3.2） */
  static readonly BUNDLE_USER: string = 'com.zhunong.user';
  static readonly BUNDLE_FARMER: string = 'com.zhunong.farmer';
  static readonly BUNDLE_ADMIN: string = 'com.zhunong.admin';

  /** AI 轮询配置（spec 8.2.3） */
  static readonly AI_POSTER_POLL_INTERVAL: number = 3000;
  static readonly AI_POSTER_POLL_MAX_TIMES: number = 20;

  /** 页面背景色（spec 15.2.2：恢复奶油白主背景，对齐 --qn-cream #FFFEF5） */
  static readonly GRADIENT_TOP: string = '#FFFEF5';
  static readonly GRADIENT_BOTTOM: string = '#FFFEF5';

  /** UI 复刻阴影令牌（spec 15.2.2，对齐 colors_and_type.css --qn-shadow-*） */
  static readonly SHADOW_CARD: ShadowOptions = { radius: 16, color: 'rgba(26,26,26,0.06)', offsetX: 0, offsetY: 4 };
  static readonly SHADOW_FLOAT: ShadowOptions = { radius: 24, color: 'rgba(26,26,26,0.12)', offsetX: 0, offsetY: 8 };
  static readonly SHADOW_NAV: ShadowOptions = { radius: 12, color: 'rgba(26,26,26,0.05)', offsetX: 0, offsetY: -2 };
  static readonly SHADOW_FAB: ShadowOptions = { radius: 12, color: 'rgba(26,26,26,0.28)', offsetX: 0, offsetY: 4 };
  static readonly SHADOW_YELLOW: ShadowOptions = { radius: 18, color: 'rgba(255,217,61,0.35)', offsetX: 0, offsetY: 6 };

  /** UI 复刻圆角尺度（spec 15.2.3，对齐 --qn-r-*） */
  static readonly RADIUS_XS: number = 6;
  static readonly RADIUS_SM: number = 10;
  static readonly RADIUS_MD: number = 14;
  static readonly RADIUS_LG: number = 18;
  static readonly RADIUS_XL: number = 24;
  static readonly RADIUS_PILL: number = 999;

  /** UI 复刻尺寸常量（spec 15.2.3） */
  static readonly STATUSBAR_HEIGHT: number = 44;
  static readonly TABBAR_HEIGHT: number = 64;
  static readonly TABBAR_BOTTOM_PADDING: number = 76;
  static readonly FAB_WIDTH: number = 52;
  static readonly FAB_HEIGHT: number = 36;
}
