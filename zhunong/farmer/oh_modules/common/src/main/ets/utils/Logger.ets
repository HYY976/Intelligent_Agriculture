/**
 * Logger - 统一日志工具（封装 hilog）
 * 遵循 spec 2.2.5：
 *  - 三端独立 Logger 工具类
 *  - 场景名固定 ZhuNongUser/ZhuNongFarmer/ZhuNongAdmin/ZhuNongCommon
 *  - 日志参数统一 JSON.stringify 序列化对象
 *  - 禁止直接使用 console.*
 *  - 发布构建屏蔽 debug 级别日志
 *
 * ArkTS 规则适配（arkts-no-untyped-obj-literals）：
 *  - 所有结构化日志参数必须使用 LogInfo 接口显式声明类型
 *  - LogInfo 包含项目中所有日志字段的并集（均为可选字段，除 action 必填外）
 */

import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0501;

/**
 * 结构化日志信息接口
 * 收集项目中所有日志字段并集，所有字段均可选（除 action 必填）
 * 新增日志字段时需同步扩展此接口
 */
export interface LogInfo {
  /** 业务动作标识（必填） */
  action: string;
  /** 错误信息 */
  error?: string;
  /** Preferences / 缓存键名 */
  key?: string;
  /** 当前模式（standard/elder） */
  mode?: string;
  /** HTTP 方法（GET/POST/PUT/DELETE） */
  method?: string;
  /** 请求 URL */
  url?: string;
  /** HTTP 状态码 */
  status?: number;
  /** 广告 ID */
  adId?: string;
  /** 广告跳转 URL */
  targetUrl?: string;
  /** Toast / 提示文案 */
  msg?: string;
  /** 用户 ID */
  userId?: string;
  /** 管理员 ID */
  adminId?: string;
  /** 角色（super_admin/user_admin/content_reviewer/api_admin） */
  role?: string;
  /** 数量统计 */
  count?: number;
  /** 主题（light/dark/system） */
  theme?: string;
  /** 系统色彩模式常量值 */
  colorMode?: number;
  /** 顶部导航标签 */
  nav?: string;
  /** Tab 标签 */
  tab?: string;
  /** 营收时间范围（today/month/year/total） */
  range?: string;
  /** 商品 ID */
  productId?: string;
  /** SKU ID（商品规格标识） */
  skuId?: string;
  /** 模式切换：源模式 */
  from?: string;
  /** 模式切换：目标模式 */
  to?: string;
  /** 资质认证状态（pending/approved/rejected） */
  certStatus?: string;
  /** 菜单 ID */
  menu?: string;
  /** 收货地址 ID（用户地址管理） */
  addressId?: string;
  /** POI 点位 ID（文旅） */
  poiId?: string;
  /** 城市（文旅/定位） */
  city?: string;
  /** 直播 ID */
  liveId?: string;
  /** 帖子 ID（社区） */
  postId?: string;
  /** 攻略 ID（社区/搜索榜单） */
  guideId?: string;
  /** 会话 ID（消息/WebSocket） */
  sessionId?: string;
  /** 重连尝试次数（WebSocket） */
  attempt?: number;
  /** 重连延迟毫秒（WebSocket） */
  delay?: number;
  /** WebSocket 关闭码 */
  code?: number;
  /** WebSocket 关闭原因 / 举报原因 */
  reason?: string;
  /** 消息数量 */
  msgCount?: number;
  /** 会话是否有聊天记录（消息列表点击日志） */
  hasChat?: boolean;
  /** 离线消息是否从缓存恢复 */
  cacheRestored?: boolean;
  /** 消息内容类型（text/image 等） */
  contentType?: string;
  /** WebSocket 消息类型（chat/notification） */
  type?: string;
  /** 原始数据（解析失败时记录截断串） */
  raw?: string;
  /** WebSocket 连接状态 */
  state?: string;
  /** 列表筛选 Tab */
  filter?: string;
  /** 是否关注主播 */
  following?: boolean;
  /** 索引（列表/轮播切换） */
  index?: number;
  /** 长度/数量（消息列表、直播列表等） */
  length?: number;
  /** 总数（榜单/统计） */
  total?: number;
  /** 消息 ID（聊天/WebSocket 消息标识） */
  messageId?: string;
  /** 礼物 ID（直播送礼） */
  giftId?: string;
  /** 礼物收入金额（直播主播收入推送） */
  giftIncome?: number;
  /** 搜索关键词 */
  keyword?: string;
  /** 搜索结果数量 */
  resultCount?: number;
  /** 是否已点赞（社区帖子） */
  liked?: boolean;
  /** 是否已收藏（社区帖子） */
  favorited?: boolean;
  /** 话题 ID（社区） */
  topicId?: string;
  /** 跳转路由（导航点击日志） */
  route?: string;
  /** 金额（提现/营收） */
  amount?: number;
  /** 数量/容量（通用，区别于 count 的"数量统计"语义） */
  quantity?: number;
  /** 角色类型（直播间角色：host/viewer，区别于 role 的"管理员角色"语义） */
  liveRole?: string;
  /** 路由名（NavigationHelper 跳转/失败日志） */
  name?: string;
  /** 是否还有更多（分页加载） */
  hasMore?: boolean;
  /** 当前页码（分页加载） */
  page?: number;
  /** 本次新增数量（分页加载更多） */
  added?: number;
  /** 接口 ID（admin API 管理） */
  apiId?: string;
  /** 审核 ID（admin 内容审核） */
  reviewId?: string;
  /** API Key ID（admin 密钥管理） */
  keyId?: string;
  /** QPS 阈值（admin 限流配置） */
  qps?: number;
  /** 并发数限制（admin 限流配置） */
  concurrent?: number;
  /** 熔断阈值（admin 限流配置，0~1） */
  threshold?: number;
  /** 恢复时间秒数（admin 限流配置） */
  recovery?: number;
  /** 营收记录 ID（farmer 营收明细） */
  recordId?: string;
  /** AI 文案亮点数量（farmer AI 文案生成） */
  highlightsCount?: number;
  /** 是否立即发布（farmer 商品发布） */
  publishNow?: boolean;
  /** AI 文案生成消息（farmer AI 错误回调） */
  message?: string;
  /** 海报 URL（farmer AI 海报生成） */
  posterUrl?: string;
  /** 持续时长毫秒（farmer AI 语音合成） */
  duration?: number;
  /** 商品状态（productStatus 字符串，区别于 status 的 HTTP 状态码） */
  productStatus?: string;
  /** 商品标题（AI 文案/海报生成入参） */
  title?: string;
  /** 商品类目（AI 文案生成入参） */
  category?: string;
  /** 海报风格（清新/复古/国风，AI 海报生成入参） */
  style?: string;
  /** AI 海报任务 ID */
  taskId?: string;
  /** TTS 音色（男声/女声/方言） */
  voiceType?: string;
  /** 卖家 ID（farmer 模块） */
  farmerId?: string;
  /** 推荐上下文（开场/促销，AI 推荐入参） */
  context?: string;
  /** Banner 链接类型（category/live/travel/rank/none） */
  linkType?: string;
  /** 路由名（NavigationHelper 跳转日志，区别于 route 的"路由"语义） */
  routeName?: string;
  /** 优惠券 ID（用户优惠券使用） */
  couponId?: string;
}

class LoggerImpl {
  private enabled: boolean = true;

  /** 设置日志总开关（发布构建可通过 BuildProfile 注入关闭） */
  setEnabled(enabled: boolean): void {
    this.enabled = enabled;
  }

  /** Debug 级别（仅 debug 构建输出） */
  debug(scene: string, msg: string | LogInfo): void {
    if (!this.enabled) {
      return;
    }
    const content: string = typeof msg === 'string' ? msg : JSON.stringify(msg);
    hilog.debug(DOMAIN, scene, '%{public}s', content);
  }

  /** Info 级别 */
  info(scene: string, msg: string | LogInfo): void {
    if (!this.enabled) {
      return;
    }
    const content: string = typeof msg === 'string' ? msg : JSON.stringify(msg);
    hilog.info(DOMAIN, scene, '%{public}s', content);
  }

  /** Warn 级别 */
  warn(scene: string, msg: string | LogInfo): void {
    if (!this.enabled) {
      return;
    }
    const content: string = typeof msg === 'string' ? msg : JSON.stringify(msg);
    hilog.warn(DOMAIN, scene, '%{public}s', content);
  }

  /** Error 级别（始终输出） */
  error(scene: string, msg: string | LogInfo): void {
    const content: string = typeof msg === 'string' ? msg : JSON.stringify(msg);
    hilog.error(DOMAIN, scene, '%{public}s', content);
  }
}

/** 全局 Logger 单例 */
export const Logger: LoggerImpl = new LoggerImpl();
