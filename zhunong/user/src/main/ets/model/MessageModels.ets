/**
 * MessageModels - 用户端消息域数据模型
 * 遵循 spec 4.1.10 消息实体定义、3.1.3.3 消息Tab规范
 * 含会话（私信/系统通知）/消息（文字/图片/表情）
 */

/** 会话类型（spec 4.1.10 ChatSession） */
export type SessionType = 'private' | 'system';

/** 消息内容类型（spec 4.1.10 ChatMessage + 设计稿 chat-detail.html 商品卡片） */
export type MessageContentType = 'text' | 'image' | 'emoji' | 'product';

/** 系统通知子类型 */
export type SystemNoticeType = 'order' | 'logistics' | 'activity' | 'review';

/**
 * 消息分类（对齐设计稿 message.html 5 Tab + 4 快捷入口）
 * - order: 订单消息
 * - logistics: 物流通知
 * - live: 直播提醒
 * - coupon: 优惠通知
 * - interact: 互动消息
 * - system: 系统公告
 * - service: 客服
 */
export type MessageCategory = 'order' | 'logistics' | 'live' | 'coupon' | 'interact' | 'system' | 'service';

/**
 * 消息分类标签颜色主题（对齐设计稿 qn-msg-tag.t-* / qn-msg-ico.c-*）
 * - yellow: 订单（黄底 #FFF6B8 / #B8860B）
 * - green: 物流/优惠（绿底 #EAF7D8 / #5BB315）
 * - red: 直播（红底 #FFE7E7 / #FF4D4F）
 * - blue: 互动/系统（蓝底 #E8F2FE / #4A90E2）
 * - gray: 客服（灰底 #F6F6F4 / #666666）
 */
export type MessageTagTheme = 'yellow' | 'green' | 'red' | 'blue' | 'gray';

/**
 * 消息筛选 Tab（对齐设计稿 qn-msg-tab 5 项：全部/系统/订单/互动/客服）
 * - all: 全部
 * - system: 系统公告
 * - order: 订单消息（含物流）
 * - interact: 互动消息（含直播/优惠）
 * - service: 客服
 */
export type MessageFilterTab = 'all' | 'system' | 'order' | 'interact' | 'service';

/** 聊天会话（spec 4.1.10 ChatSession + 设计稿 message.html 扩展字段） */
export interface ChatSession {
  sessionId: string;
  /** 会话类型：私信/系统通知 */
  type: SessionType;
  /** 用户 A（买家，自己） */
  userAId: string;
  /** 用户 B（卖家；系统通知时为系统账号） */
  userBId: string;
  /** 对端显示昵称（卖家昵称/系统通知标题，chat_detail 头部使用） */
  peerNickname: string;
  /** 对端头像 key */
  peerAvatar: string;
  /** 系统通知子类型（type=system 时有效） */
  noticeType?: SystemNoticeType;
  /** 最新消息预览 */
  lastMessage: string;
  /** 最新消息时间戳 */
  lastMessageAt: number;
  /** 自己未读数 */
  unreadCount: number;
  /** 是否置顶 */
  isPinned: boolean;
  // ===== 设计稿 message.html 扩展字段 =====
  /** 消息分类（列表筛选 + 图标显示，对齐设计稿 qn-msg-row） */
  category: MessageCategory;
  /** 列表显示标题（区别于 peerNickname，如"您的订单已发货"） */
  title: string;
  /** 图标 emoji（对齐设计稿 qn-msg-ico 内 SVG，用 emoji 替代） */
  icon: string;
  /** 图标底色主题（对齐设计稿 qn-msg-ico.c-*） */
  iconTheme: MessageTagTheme;
  /** 分类标签文案（订单/直播/优惠/互动/系统/客服，对齐设计稿 qn-msg-tag） */
  tagLabel: string;
  /** 分类标签颜色主题（对齐设计稿 qn-msg-tag.t-*） */
  tagTheme: MessageTagTheme;
  /** 是否有聊天记录（false 时点击行不跳转 chat_detail，对齐设计稿通知类消息） */
  hasChat: boolean;
}

/** 聊天消息（spec 4.1.10 ChatMessage + 设计稿 chat-detail.html 商品卡片） */
export interface ChatMessage {
  messageId: string;
  sessionId: string;
  /** 发送者 ID */
  senderId: string;
  /** 接收者 ID */
  receiverId: string;
  /** 内容类型 */
  contentType: MessageContentType;
  /** 消息内容（文字/图片 key/表情） */
  content: string;
  /** 是否为自己发送（用于气泡左右区分） */
  isSelf: boolean;
  /** 是否已读 */
  isRead: boolean;
  createdAt: number;
  /** 商品卡片名称（contentType='product' 时有效，对齐设计稿 qn-msg-card-name） */
  productName?: string;
  /** 商品卡片图片 key（contentType='product' 时有效，对齐设计稿 qn-msg-card-img） */
  productImage?: string;
  /** 商品卡片价格（contentType='product' 时有效，对齐设计稿 qn-price） */
  productPrice?: number;
}

/** WebSocket 消息格式（spec 3.1.3.3） */
export interface WsMessage {
  /** 消息类型：chat 私信 / notification 系统通知 */
  type: 'chat' | 'notification';
  /** 会话 ID */
  sessionId: string;
  /** 发送者 ID */
  fromUserId: string;
  /** 接收者 ID */
  toUserId: string;
  /** 消息内容 */
  content: string;
  /** 内容类型 */
  contentType?: MessageContentType;
  /** 时间戳 */
  timestamp: number;
}

/** WebSocket 连接状态 */
export type WsConnectionState = 'disconnected' | 'connecting' | 'connected' | 'reconnecting' | 'mock';

/** 会话列表项（与 ChatSession 字段一致，列表渲染用） */
export type SessionListItem = ChatSession;
