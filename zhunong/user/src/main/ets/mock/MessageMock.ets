/**
 * MessageMock - 消息域 Mock 数据
 * 遵循 spec 4.1.10 / 3.1.3.3 + 设计稿 message.html / chat-detail.html：
 *  - 消息列表（通知中心式）：订单/直播/优惠/互动/系统/客服 6 条
 *  - 快捷入口 4 圆形图标：订单消息(3)/物流通知(1)/直播提醒(2)/系统公告(1)
 *  - 5 Tab 筛选：全部/系统/订单/互动/客服
 *  - 聊天消息：私信会话 + 客服会话 + 商品卡片消息
 *
 * 现阶段前端纯 Mock，后端预留空接口（Phase 6 联调替换为 REST + WebSocket）
 */

import { ChatSession, ChatMessage, MessageContentType, MessageCategory, MessageTagTheme } from '../model/MessageModels';

/** 自己的用户 ID（Mock 当前登录用户） */
export const MOCK_SELF_USER_ID: string = 'u_self';

/** 快捷入口配置项（对齐设计稿 qn-quick-grid 4 项） */
export interface QuickEntry {
  category: MessageCategory;
  label: string;
  icon: string;
  iconTheme: MessageTagTheme;
  badge: number;
}

/** 快捷入口 Mock（对齐设计稿 message.html: 订单3/物流1/直播2/系统1） */
export const MOCK_QUICK_ENTRIES: QuickEntry[] = [
  { category: 'order', label: '订单消息', icon: '📦', iconTheme: 'yellow', badge: 3 },
  { category: 'logistics', label: '物流通知', icon: '🚚', iconTheme: 'green', badge: 1 },
  { category: 'live', label: '直播提醒', icon: '📺', iconTheme: 'red', badge: 2 },
  { category: 'system', label: '系统公告', icon: '📢', iconTheme: 'blue', badge: 1 }
];

/**
 * 会话列表 Mock 数据（对齐设计稿 message.html 6 条消息行）
 * - 订单/直播/优惠/互动/系统/客服 6 类通知
 * - hasChat=true 的会话有聊天记录（点击进入 chat_detail）
 * - hasChat=false 的会话仅通知（点击显示 Toast 或跳转对应页）
 */
export const MOCK_SESSIONS: ChatSession[] = [
  // 1. [订单] 未读 — 对齐设计稿 msg-item-order
  {
    sessionId: 'msg_order',
    type: 'system',
    userAId: 'u_self',
    userBId: 'system',
    peerNickname: '订单通知',
    peerAvatar: 'avatar_default',
    noticeType: 'order',
    lastMessage: '红颜草莓已由顺丰揽收，预计明日送达',
    lastMessageAt: Date.now() - 10 * 60 * 1000,
    unreadCount: 1,
    isPinned: false,
    category: 'order',
    title: '您的订单已发货',
    icon: '📦',
    iconTheme: 'yellow',
    tagLabel: '订单',
    tagTheme: 'yellow',
    hasChat: true
  },
  // 2. [直播] 未读 — 对齐设计稿 msg-item-live
  {
    sessionId: 'msg_live',
    type: 'private',
    userAId: 'u_self',
    userBId: 'f_wang',
    peerNickname: '王大叔的果园',
    peerAvatar: 'avatar_farmer_1',
    lastMessage: '正在直播：现摘草莓专场，快来围观',
    lastMessageAt: Date.now() - 25 * 60 * 1000,
    unreadCount: 1,
    isPinned: false,
    category: 'live',
    title: '王大叔的果园 开始直播啦',
    icon: '📺',
    iconTheme: 'red',
    tagLabel: '直播',
    tagTheme: 'red',
    hasChat: false
  },
  // 3. [优惠] — 对齐设计稿 msg-item-coupon
  {
    sessionId: 'msg_coupon',
    type: 'system',
    userAId: 'u_self',
    userBId: 'system',
    peerNickname: '优惠通知',
    peerAvatar: 'avatar_default',
    noticeType: 'activity',
    lastMessage: '限时3天，下单立减',
    lastMessageAt: Date.now() - 60 * 60 * 1000,
    unreadCount: 0,
    isPinned: false,
    category: 'coupon',
    title: '满50减5优惠券到账',
    icon: '🎫',
    iconTheme: 'green',
    tagLabel: '优惠',
    tagTheme: 'green',
    hasChat: false
  },
  // 4. [互动] — 对齐设计稿 msg-item-interact
  {
    sessionId: 'msg_interact',
    type: 'private',
    userAId: 'u_self',
    userBId: 'u_li',
    peerNickname: '李婶',
    peerAvatar: 'avatar_default',
    lastMessage: '草莓真的很甜，下次还买',
    lastMessageAt: Date.now() - 2 * 60 * 60 * 1000,
    unreadCount: 0,
    isPinned: false,
    category: 'interact',
    title: '李婶 回复了你的评论',
    icon: '💬',
    iconTheme: 'blue',
    tagLabel: '互动',
    tagTheme: 'blue',
    hasChat: false
  },
  // 5. [系统] — 对齐设计稿 msg-item-system
  {
    sessionId: 'msg_system',
    type: 'system',
    userAId: 'u_self',
    userBId: 'system',
    peerNickname: '系统通知',
    peerAvatar: 'avatar_default',
    noticeType: 'review',
    lastMessage: '感谢您支持智农',
    lastMessageAt: Date.now() - 26 * 60 * 60 * 1000,
    unreadCount: 0,
    isPinned: false,
    category: 'system',
    title: '实名认证已通过',
    icon: '🛡️',
    iconTheme: 'gray',
    tagLabel: '系统',
    tagTheme: 'gray',
    hasChat: false
  },
  // 6. [客服] — 对齐设计稿 msg-item-service
  {
    sessionId: 'msg_service',
    type: 'private',
    userAId: 'u_self',
    userBId: 'cs_xiaoqu',
    peerNickname: '客服小趣',
    peerAvatar: 'avatar_default',
    lastMessage: '有什么可以帮您？',
    lastMessageAt: Date.now() - 26 * 60 * 60 * 1000,
    unreadCount: 0,
    isPinned: false,
    category: 'service',
    title: '客服小趣',
    icon: '🎧',
    iconTheme: 'gray',
    tagLabel: '客服',
    tagTheme: 'gray',
    hasChat: true
  }
];

/**
 * 消息记录 Mock 数据（按 sessionId 分组）
 * 含双向消息：isSelf=true 表示自己发送（右侧气泡），false 表示对方/系统发送（左侧气泡）
 * 对齐设计稿 chat-detail.html: 白色入气泡 + 黄色出气泡 + 商品卡片消息
 */
const MOCK_MESSAGE_DATA: Record<string, ChatMessage[]> = {
  // 订单通知会话（系统消息，单方向）
  'msg_order': [
    {
      messageId: 'mo_1',
      sessionId: 'msg_order',
      senderId: 'system',
      receiverId: 'u_self',
      contentType: 'text',
      content: '您的订单 o20260725001 已创建，待支付',
      isSelf: false,
      isRead: true,
      createdAt: Date.now() - 30 * 60 * 1000
    },
    {
      messageId: 'mo_2',
      sessionId: 'msg_order',
      senderId: 'system',
      receiverId: 'u_self',
      contentType: 'text',
      content: '您的订单 o20260725001 已支付成功，等待卖家发货',
      isSelf: false,
      isRead: true,
      createdAt: Date.now() - 20 * 60 * 1000
    },
    {
      messageId: 'mo_3',
      sessionId: 'msg_order',
      senderId: 'system',
      receiverId: 'u_self',
      contentType: 'text',
      content: '红颜草莓已由顺丰揽收，预计明日送达',
      isSelf: false,
      isRead: false,
      createdAt: Date.now() - 10 * 60 * 1000
    }
  ],
  // 客服会话（双向对话 + 商品卡片，对齐设计稿 chat-detail.html）
  'msg_service': [
    {
      messageId: 'ms_1',
      sessionId: 'msg_service',
      senderId: 'cs_xiaoqu',
      receiverId: 'u_self',
      contentType: 'text',
      content: '您好，欢迎来到智农客服中心，有什么可以帮您？',
      isSelf: false,
      isRead: true,
      createdAt: Date.now() - 26 * 60 * 60 * 1000
    },
    {
      messageId: 'ms_2',
      sessionId: 'msg_service',
      senderId: 'u_self',
      receiverId: 'cs_xiaoqu',
      contentType: 'text',
      content: '我想咨询一下红颜草莓的发货时间',
      isSelf: true,
      isRead: true,
      createdAt: Date.now() - 25 * 60 * 60 * 1000
    },
    {
      messageId: 'ms_3',
      sessionId: 'msg_service',
      senderId: 'cs_xiaoqu',
      receiverId: 'u_self',
      contentType: 'product',
      content: '红颜草莓 500g',
      productName: '红颜草莓 500g',
      productImage: 'prod_fruit_1',
      productPrice: 39.90,
      isSelf: false,
      isRead: true,
      createdAt: Date.now() - 24 * 60 * 60 * 1000
    },
    {
      messageId: 'ms_4',
      sessionId: 'msg_service',
      senderId: 'cs_xiaoqu',
      receiverId: 'u_self',
      contentType: 'text',
      content: '这款草莓是今天早上刚采摘的，下午发货，顺丰冷链明天到',
      isSelf: false,
      isRead: true,
      createdAt: Date.now() - 24 * 60 * 60 * 1000 + 60000
    },
    {
      messageId: 'ms_5',
      sessionId: 'msg_service',
      senderId: 'u_self',
      receiverId: 'cs_xiaoqu',
      contentType: 'text',
      content: '好的，了解了，谢谢',
      isSelf: true,
      isRead: true,
      createdAt: Date.now() - 23 * 60 * 60 * 1000
    },
    {
      messageId: 'ms_6',
      sessionId: 'msg_service',
      senderId: 'cs_xiaoqu',
      receiverId: 'u_self',
      contentType: 'text',
      content: '有什么可以帮您？',
      isSelf: false,
      isRead: true,
      createdAt: Date.now() - 22 * 60 * 60 * 1000
    }
  ]
};

/**
 * 获取全部会话列表（按最新时间倒序，对齐设计稿 message.html 6 条）
 * @param filter 筛选 Tab：'all' / 'system' / 'order' / 'interact' / 'service'
 */
export function getMockSessions(filter?: string): ChatSession[] {
  let list: ChatSession[] = MOCK_SESSIONS.slice();
  if (filter && filter !== 'all') {
    list = list.filter((s: ChatSession) => {
      if (filter === 'order') {
        return s.category === 'order' || s.category === 'logistics';
      }
      if (filter === 'interact') {
        return s.category === 'interact' || s.category === 'live' || s.category === 'coupon';
      }
      return s.category === filter;
    });
  }
  list.sort((a: ChatSession, b: ChatSession) => b.lastMessageAt - a.lastMessageAt);
  return list;
}

/**
 * 根据 sessionId 获取会话信息
 */
export function getMockSessionById(sessionId: string): ChatSession | null {
  const target: ChatSession | undefined = MOCK_SESSIONS.find((s: ChatSession) => s.sessionId === sessionId);
  return target ?? null;
}

/**
 * 获取会话消息列表（按时间正序）
 */
export function getMockMessagesBySessionId(sessionId: string): ChatMessage[] {
  const messages: ChatMessage[] = MOCK_MESSAGE_DATA[sessionId] ?? [];
  return messages.slice().sort((a: ChatMessage, b: ChatMessage) => a.createdAt - b.createdAt);
}

/**
 * 发送消息（Mock 本地追加，isSelf=true）
 * 同步更新会话的 lastMessage / lastMessageAt
 */
export function sendMockMessage(
  sessionId: string,
  content: string,
  contentType: MessageContentType = 'text'
): ChatMessage {
  const session: ChatSession | null = getMockSessionById(sessionId);
  const receiverId: string = session ? session.userBId : 'system';
  const newMsg: ChatMessage = {
    messageId: `local_${Date.now()}_${Math.floor(Math.random() * 1000)}`,
    sessionId: sessionId,
    senderId: MOCK_SELF_USER_ID,
    receiverId: receiverId,
    contentType: contentType,
    content: content,
    isSelf: true,
    isRead: true,
    createdAt: Date.now()
  };
  if (!MOCK_MESSAGE_DATA[sessionId]) {
    MOCK_MESSAGE_DATA[sessionId] = [];
  }
  MOCK_MESSAGE_DATA[sessionId].push(newMsg);

  // 同步更新会话
  if (session) {
    if (contentType === 'image') {
      session.lastMessage = '[图片]';
    } else if (contentType === 'emoji') {
      session.lastMessage = '[表情]';
    } else if (contentType === 'product') {
      session.lastMessage = '[商品]';
    } else {
      session.lastMessage = content;
    }
    session.lastMessageAt = newMsg.createdAt;
  }
  return newMsg;
}

/**
 * 模拟对方回复消息（Mock 自动应答）
 * 仅 hasChat=true 的会话有效
 */
export function simulateMockReply(sessionId: string): ChatMessage | null {
  const session: ChatSession | null = getMockSessionById(sessionId);
  if (!session || !session.hasChat) {
    return null;
  }
  const replies: string[] = [
    '好的，收到',
    '我这边马上处理',
    '稍等一下，我看看库存',
    '感谢您的支持',
    '有什么问题随时联系我',
    '欢迎下次再来'
  ];
  const replyIdx: number = Math.floor(Math.random() * replies.length);
  const newMsg: ChatMessage = {
    messageId: `reply_${Date.now()}_${Math.floor(Math.random() * 1000)}`,
    sessionId: sessionId,
    senderId: session.userBId,
    receiverId: MOCK_SELF_USER_ID,
    contentType: 'text',
    content: replies[replyIdx],
    isSelf: false,
    isRead: false,
    createdAt: Date.now()
  };
  if (!MOCK_MESSAGE_DATA[sessionId]) {
    MOCK_MESSAGE_DATA[sessionId] = [];
  }
  MOCK_MESSAGE_DATA[sessionId].push(newMsg);

  // 同步更新会话
  session.lastMessage = newMsg.content;
  session.lastMessageAt = newMsg.createdAt;
  session.unreadCount += 1;
  return newMsg;
}

/**
 * 标记会话所有消息已读 + 清零未读数
 */
export function markSessionRead(sessionId: string): void {
  const session: ChatSession | null = getMockSessionById(sessionId);
  if (!session) {
    return;
  }
  session.unreadCount = 0;
  const messages: ChatMessage[] = MOCK_MESSAGE_DATA[sessionId] ?? [];
  messages.forEach((m: ChatMessage) => {
    m.isRead = true;
  });
}

/**
 * 标记全部会话已读（对齐设计稿 qn-msg-readall "全部已读"）
 */
export function markAllSessionsRead(): void {
  MOCK_SESSIONS.forEach((s: ChatSession) => {
    s.unreadCount = 0;
    const messages: ChatMessage[] = MOCK_MESSAGE_DATA[s.sessionId] ?? [];
    messages.forEach((m: ChatMessage) => {
      m.isRead = true;
    });
  });
}

/**
 * 切换会话置顶
 */
export function toggleMockSessionPinned(sessionId: string): boolean {
  const session: ChatSession | null = getMockSessionById(sessionId);
  if (!session) {
    return false;
  }
  session.isPinned = !session.isPinned;
  return session.isPinned;
}

/**
 * 删除会话（同时删除消息记录）
 */
export function deleteMockSession(sessionId: string): boolean {
  const idx: number = MOCK_SESSIONS.findIndex((s: ChatSession) => s.sessionId === sessionId);
  if (idx < 0) {
    return false;
  }
  MOCK_SESSIONS.splice(idx, 1);
  MOCK_MESSAGE_DATA[sessionId] = [];
  return true;
}

/**
 * 获取未读消息总数（供 Tab 红点角标使用）
 */
export function getMockTotalUnread(): number {
  let total: number = 0;
  MOCK_SESSIONS.forEach((s: ChatSession) => {
    total += s.unreadCount;
  });
  return total;
}
