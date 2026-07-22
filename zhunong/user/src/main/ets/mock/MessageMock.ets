/**
 * MessageMock - 消息域 Mock 数据
 * 遵循 spec 4.1.10 / 3.1.3.3：会话（私信/系统通知）+ 消息（文字/图片/表情）
 *  - 私信会话：买卖家一对一（覆盖多卖家）
 *  - 系统通知会话：订单/物流/活动/评价 4 子类型
 *  - 消息按 sessionId 分组，含发送/接收双向记录
 *
 * 现阶段前端纯 Mock，后端预留空接口（Phase 6 联调替换为 REST + WebSocket）
 */

import { ChatSession, ChatMessage, SessionType, SystemNoticeType, MessageContentType } from '../model/MessageModels';

/** 自己的用户 ID（Mock 当前登录用户） */
export const MOCK_SELF_USER_ID: string = 'u_self';

/** 会话列表 Mock 数据（覆盖私信 + 系统通知两类） */
export const MOCK_SESSIONS: ChatSession[] = [
  // ===== 私信会话（买卖家一对一） =====
  {
    sessionId: 's001',
    type: 'private',
    userAId: 'u_self',
    userBId: 'f001',
    peerNickname: '云南有机菜园',
    peerAvatar: 'avatar_farmer_1',
    lastMessage: '好的，明天一早就发货，注意查收',
    lastMessageAt: Date.now() - 1800000,
    unreadCount: 2,
    isPinned: true
  },
  {
    sessionId: 's002',
    type: 'private',
    userAId: 'u_self',
    userBId: 'f002',
    peerNickname: '湖南土鸡蛋直供',
    peerAvatar: 'avatar_farmer_2',
    lastMessage: '可以发图给您看看包装',
    lastMessageAt: Date.now() - 7200000,
    unreadCount: 1,
    isPinned: false
  },
  {
    sessionId: 's003',
    type: 'private',
    userAId: 'u_self',
    userBId: 'f003',
    peerNickname: '海南热带果园',
    peerAvatar: 'avatar_farmer_3',
    lastMessage: '香蕉还有 3 斤装的，更划算哦',
    lastMessageAt: Date.now() - 86400000,
    unreadCount: 0,
    isPinned: false
  },
  {
    sessionId: 's004',
    type: 'private',
    userAId: 'u_self',
    userBId: 'f004',
    peerNickname: '东北黑土米业',
    peerAvatar: 'avatar_default',
    lastMessage: '已收到您的订单，正在打包',
    lastMessageAt: Date.now() - 172800000,
    unreadCount: 0,
    isPinned: false
  },

  // ===== 系统通知会话（订单/物流/活动/评价 4 子类型） =====
  {
    sessionId: 'sys_order',
    type: 'system',
    userAId: 'u_self',
    userBId: 'system',
    peerNickname: '订单通知',
    peerAvatar: 'avatar_default',
    noticeType: 'order',
    lastMessage: '您的订单 o20260716001 已支付成功，等待卖家发货',
    lastMessageAt: Date.now() - 3600000,
    unreadCount: 1,
    isPinned: false
  },
  {
    sessionId: 'sys_logistics',
    type: 'system',
    userAId: 'u_self',
    userBId: 'system',
    peerNickname: '物流通知',
    peerAvatar: 'avatar_default',
    noticeType: 'logistics',
    lastMessage: '您的包裹已到达【杭州转运中心】，预计明日送达',
    lastMessageAt: Date.now() - 10800000,
    unreadCount: 0,
    isPinned: false
  },
  {
    sessionId: 'sys_activity',
    type: 'system',
    userAId: 'u_self',
    userBId: 'system',
    peerNickname: '活动通知',
    peerAvatar: 'avatar_default',
    noticeType: 'activity',
    lastMessage: '【限时秒杀】云南青菜 5.9 元起，仅限今日',
    lastMessageAt: Date.now() - 21600000,
    unreadCount: 0,
    isPinned: false
  },
  {
    sessionId: 'sys_review',
    type: 'system',
    userAId: 'u_self',
    userBId: 'system',
    peerNickname: '评价通知',
    peerAvatar: 'avatar_default',
    noticeType: 'review',
    lastMessage: '您购买的土鸡蛋已确认收货，快来评价分享心得吧',
    lastMessageAt: Date.now() - 43200000,
    unreadCount: 0,
    isPinned: false
  }
];

/**
 * 消息记录 Mock 数据（按 sessionId 分组）
 * 含双向消息：isSelf=true 表示自己发送（右侧气泡），false 表示对方/系统发送（左侧气泡）
 */
const MOCK_MESSAGE_DATA: Record<string, ChatMessage[]> = {
  's001': [
    {
      messageId: 'm001_1',
      sessionId: 's001',
      senderId: 'u_self',
      receiverId: 'f001',
      contentType: 'text',
      content: '老板，有机青菜还有货吗？',
      isSelf: true,
      isRead: true,
      createdAt: Date.now() - 5400000
    },
    {
      messageId: 'm001_2',
      sessionId: 's001',
      senderId: 'f001',
      receiverId: 'u_self',
      contentType: 'text',
      content: '有的，今早刚采摘的，特别新鲜',
      isSelf: false,
      isRead: true,
      createdAt: Date.now() - 5280000
    },
    {
      messageId: 'm001_3',
      sessionId: 's001',
      senderId: 'u_self',
      receiverId: 'f001',
      contentType: 'text',
      content: '那来 2 份 500g 的，多久能发货？',
      isSelf: true,
      isRead: true,
      createdAt: Date.now() - 3000000
    },
    {
      messageId: 'm001_4',
      sessionId: 's001',
      senderId: 'f001',
      receiverId: 'u_self',
      contentType: 'image',
      content: 'prod_vegetable_1',
      isSelf: false,
      isRead: true,
      createdAt: Date.now() - 2880000
    },
    {
      messageId: 'm001_5',
      sessionId: 's001',
      senderId: 'f001',
      receiverId: 'u_self',
      contentType: 'text',
      content: '这是刚拍的照片，您看看',
      isSelf: false,
      isRead: true,
      createdAt: Date.now() - 2820000
    },
    {
      messageId: 'm001_6',
      sessionId: 's001',
      senderId: 'u_self',
      receiverId: 'f001',
      contentType: 'text',
      content: '看着不错，下单了',
      isSelf: true,
      isRead: true,
      createdAt: Date.now() - 2400000
    },
    {
      messageId: 'm001_7',
      sessionId: 's001',
      senderId: 'f001',
      receiverId: 'u_self',
      contentType: 'text',
      content: '好的，明天一早就发货，注意查收',
      isSelf: false,
      isRead: false,
      createdAt: Date.now() - 1800000
    },
    {
      messageId: 'm001_8',
      sessionId: 's001',
      senderId: 'f001',
      receiverId: 'u_self',
      contentType: 'emoji',
      content: '🙏',
      isSelf: false,
      isRead: false,
      createdAt: Date.now() - 1790000
    }
  ],
  's002': [
    {
      messageId: 'm002_1',
      sessionId: 's002',
      senderId: 'u_self',
      receiverId: 'f002',
      contentType: 'text',
      content: '鸡蛋包装结实吗？之前买过别家碎了好几个',
      isSelf: true,
      isRead: true,
      createdAt: Date.now() - 14400000
    },
    {
      messageId: 'm002_2',
      sessionId: 's002',
      senderId: 'f002',
      receiverId: 'u_self',
      contentType: 'text',
      content: '放心，我们用珍珠棉防震包装，破损包赔',
      isSelf: false,
      isRead: true,
      createdAt: Date.now() - 13800000
    },
    {
      messageId: 'm002_3',
      sessionId: 's002',
      senderId: 'f002',
      receiverId: 'u_self',
      contentType: 'text',
      content: '可以发图给您看看包装',
      isSelf: false,
      isRead: false,
      createdAt: Date.now() - 7200000
    }
  ],
  's003': [
    {
      messageId: 'm003_1',
      sessionId: 's003',
      senderId: 'u_self',
      receiverId: 'f003',
      contentType: 'text',
      content: '香蕉 5 斤装多少钱？',
      isSelf: true,
      isRead: true,
      createdAt: Date.now() - 100000000
    },
    {
      messageId: 'm003_2',
      sessionId: 's003',
      senderId: 'f003',
      receiverId: 'u_self',
      contentType: 'text',
      content: '19.9 元包邮，树上自然熟，无催熟剂',
      isSelf: false,
      isRead: true,
      createdAt: Date.now() - 99000000
    },
    {
      messageId: 'm003_3',
      sessionId: 's003',
      senderId: 'f003',
      receiverId: 'u_self',
      contentType: 'text',
      content: '香蕉还有 3 斤装的，更划算哦',
      isSelf: false,
      isRead: true,
      createdAt: Date.now() - 86400000
    }
  ],
  's004': [
    {
      messageId: 'm004_1',
      sessionId: 's004',
      senderId: 'u_self',
      receiverId: 'f004',
      contentType: 'text',
      content: '5kg 大米下单了，什么时候发货？',
      isSelf: true,
      isRead: true,
      createdAt: Date.now() - 200000000
    },
    {
      messageId: 'm004_2',
      sessionId: 's004',
      senderId: 'f004',
      receiverId: 'u_self',
      contentType: 'text',
      content: '已收到您的订单，正在打包',
      isSelf: false,
      isRead: true,
      createdAt: Date.now() - 172800000
    }
  ],
  'sys_order': [
    {
      messageId: 'mso_1',
      sessionId: 'sys_order',
      senderId: 'system',
      receiverId: 'u_self',
      contentType: 'text',
      content: '您的订单 o20260716001 已创建，待支付',
      isSelf: false,
      isRead: true,
      createdAt: Date.now() - 7200000
    },
    {
      messageId: 'mso_2',
      sessionId: 'sys_order',
      senderId: 'system',
      receiverId: 'u_self',
      contentType: 'text',
      content: '您的订单 o20260716001 已支付成功，等待卖家发货',
      isSelf: false,
      isRead: false,
      createdAt: Date.now() - 3600000
    }
  ],
  'sys_logistics': [
    {
      messageId: 'msl_1',
      sessionId: 'sys_logistics',
      senderId: 'system',
      receiverId: 'u_self',
      contentType: 'text',
      content: '【云南有机菜园】您的订单已发货，运单号 SF1234567890',
      isSelf: false,
      isRead: true,
      createdAt: Date.now() - 14400000
    },
    {
      messageId: 'msl_2',
      sessionId: 'sys_logistics',
      senderId: 'system',
      receiverId: 'u_self',
      contentType: 'text',
      content: '您的包裹已到达【昆明转运中心】',
      isSelf: false,
      isRead: true,
      createdAt: Date.now() - 12600000
    },
    {
      messageId: 'msl_3',
      sessionId: 'sys_logistics',
      senderId: 'system',
      receiverId: 'u_self',
      contentType: 'text',
      content: '您的包裹已到达【杭州转运中心】，预计明日送达',
      isSelf: false,
      isRead: true,
      createdAt: Date.now() - 10800000
    }
  ],
  'sys_activity': [
    {
      messageId: 'msa_1',
      sessionId: 'sys_activity',
      senderId: 'system',
      receiverId: 'u_self',
      contentType: 'text',
      content: '【新人专享】首单立减 10 元，下单即享',
      isSelf: false,
      isRead: true,
      createdAt: Date.now() - 86400000
    },
    {
      messageId: 'msa_2',
      sessionId: 'sys_activity',
      senderId: 'system',
      receiverId: 'u_self',
      contentType: 'text',
      content: '【限时秒杀】云南青菜 5.9 元起，仅限今日',
      isSelf: false,
      isRead: true,
      createdAt: Date.now() - 21600000
    }
  ],
  'sys_review': [
    {
      messageId: 'msr_1',
      sessionId: 'sys_review',
      senderId: 'system',
      receiverId: 'u_self',
      contentType: 'text',
      content: '您购买的土鸡蛋已确认收货，快来评价分享心得吧',
      isSelf: false,
      isRead: true,
      createdAt: Date.now() - 43200000
    }
  ]
};

/**
 * 获取全部会话列表（按置顶 + 最新时间排序）
 * @param type 可选筛选：'private' 私信 / 'system' 系统通知 / undefined 全部
 */
export function getMockSessions(type?: SessionType): ChatSession[] {
  let list: ChatSession[] = MOCK_SESSIONS.slice();
  if (type) {
    list = list.filter((s: ChatSession) => s.type === type);
  }
  // 置顶优先，同级别按最新消息时间倒序
  list.sort((a: ChatSession, b: ChatSession) => {
    if (a.isPinned !== b.isPinned) {
      return a.isPinned ? -1 : 1;
    }
    return b.lastMessageAt - a.lastMessageAt;
  });
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
    session.lastMessage = contentType === 'image' ? '[图片]' : (contentType === 'emoji' ? '[表情]' : content);
    session.lastMessageAt = newMsg.createdAt;
  }
  return newMsg;
}

/**
 * 模拟对方回复消息（Mock 自动应答）
 * 仅私信会话有效，系统通知不自动回复
 */
export function simulateMockReply(sessionId: string): ChatMessage | null {
  const session: ChatSession | null = getMockSessionById(sessionId);
  if (!session || session.type !== 'private') {
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
  // arkts-no-delete：用空数组替代 delete（Mock 场景功能等价）
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
