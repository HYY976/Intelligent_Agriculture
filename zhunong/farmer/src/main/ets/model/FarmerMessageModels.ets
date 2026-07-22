/**
 * FarmerMessageModels - 卖家端消息域数据模型（spec 4.1.10）
 * 与用户端消息模型结构对齐，便于买卖家互通
 */

/** 会话类型（spec 4.1.10） */
export type SessionType = 'private' | 'system';

/** 消息内容类型 */
export type MessageContentType = 'text' | 'image' | 'emoji';

/** 会话实体（spec 4.1.10 ChatSession） */
export interface ChatSession {
  sessionId: string;
  type: SessionType;
  /** 用户A（买家） */
  userAId: string;
  /** 用户B（卖家，系统通知时为系统账号） */
  userBId: string;
  /** 最新消息预览 */
  lastMessage?: string;
  lastMessageAt?: number;
  unreadCountA: number;
  unreadCountB: number;
  /** 对方昵称（列表展示用） */
  peerNickname?: string;
  /** 对方头像 key */
  peerAvatar?: string;
}

/** 会话列表查询结果（spec 10.12：ArkTS 严格模式要求命名 interface） */
export interface SessionListResult {
  list: ChatSession[];
  totalUnread: number;
}

/** 聊天消息实体（spec 4.1.10 ChatMessage） */
export interface ChatMessage {
  messageId: string;
  sessionId: string;
  senderId: string;
  receiverId: string;
  contentType: MessageContentType;
  content: string;
  isRead: boolean;
  createdAt: number;
  /** 发送者昵称 */
  senderNickname?: string;
  /** 发送者头像 */
  senderAvatar?: string;
}

/** WebSocket 连接状态 */
export type WsConnectionState = 'disconnected' | 'connecting' | 'connected' | 'reconnecting' | 'mock';

/** WebSocket 消息（spec 3.1.3.3 协议格式） */
export interface WsMessage {
  type: 'chat' | 'notification';
  sessionId: string;
  fromUserId: string;
  toUserId: string;
  content: string;
  contentType: MessageContentType;
  timestamp: number;
}
