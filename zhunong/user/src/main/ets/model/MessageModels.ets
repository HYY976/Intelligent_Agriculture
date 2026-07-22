/**
 * MessageModels - 用户端消息域数据模型
 * 遵循 spec 4.1.10 消息实体定义、3.1.3.3 消息Tab规范
 * 含会话（私信/系统通知）/消息（文字/图片/表情）
 */

/** 会话类型（spec 4.1.10 ChatSession） */
export type SessionType = 'private' | 'system';

/** 消息内容类型（spec 4.1.10 ChatMessage） */
export type MessageContentType = 'text' | 'image' | 'emoji';

/** 系统通知子类型 */
export type SystemNoticeType = 'order' | 'logistics' | 'activity' | 'review';

/** 聊天会话（spec 4.1.10 ChatSession） */
export interface ChatSession {
  sessionId: string;
  /** 会话类型：私信/系统通知 */
  type: SessionType;
  /** 用户 A（买家，自己） */
  userAId: string;
  /** 用户 B（卖家；系统通知时为系统账号） */
  userBId: string;
  /** 对端显示昵称（卖家昵称/系统通知标题） */
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
}

/** 聊天消息（spec 4.1.10 ChatMessage） */
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
