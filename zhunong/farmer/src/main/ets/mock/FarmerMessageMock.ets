/**
 * FarmerMessageMock - 卖家端消息域 Mock 数据（spec 4.1.10）
 * 与用户端消息互通（买卖家一对一聊天）
 */

import { ChatSession, ChatMessage, SessionListResult } from '../model/FarmerMessageModels';

/** 当前卖家ID（与 FarmerMock 一致） */
const SELF_FARMER_ID: string = 'f001';

/** 会话列表 Mock（扩展至10条，含更多买家会话和系统通知） */
export const MOCK_SESSIONS: ChatSession[] = [
  {
    sessionId: 's001', type: 'private', userAId: 'u001', userBId: SELF_FARMER_ID,
    lastMessage: '好嘞，下午就给您发出去', lastMessageAt: 1737180800000,
    unreadCountA: 0, unreadCountB: 2,
    peerNickname: '小马哥', peerAvatar: 'avatar_user_1'
  },
  {
    sessionId: 's002', type: 'private', userAId: 'u002', userBId: SELF_FARMER_ID,
    lastMessage: '好的，谢谢老板', lastMessageAt: 1737170000000,
    unreadCountA: 0, unreadCountB: 0,
    peerNickname: '阿芳', peerAvatar: 'avatar_user_2'
  },
  {
    sessionId: 's003', type: 'private', userAId: 'u003', userBId: SELF_FARMER_ID,
    lastMessage: '土猪肉什么时候有货', lastMessageAt: 1737160000000,
    unreadCountA: 0, unreadCountB: 1,
    peerNickname: '阿强', peerAvatar: 'avatar_user_3'
  },
  {
    sessionId: 's_sys_001', type: 'system', userAId: 'system', userBId: SELF_FARMER_ID,
    lastMessage: '您的商品"有机青菜"已通过审核', lastMessageAt: 1737150000000,
    unreadCountA: 0, unreadCountB: 0,
    peerNickname: '系统通知', peerAvatar: 'avatar_system'
  },
  {
    sessionId: 's_sys_002', type: 'system', userAId: 'system', userBId: SELF_FARMER_ID,
    lastMessage: '您有一条新的提现处理完成通知', lastMessageAt: 1737140000000,
    unreadCountA: 0, unreadCountB: 0,
    peerNickname: '提现通知', peerAvatar: 'avatar_system'
  },
  {
    sessionId: 's004', type: 'private', userAId: 'u004', userBId: SELF_FARMER_ID,
    lastMessage: '大米5kg还有库存吗', lastMessageAt: 1737130000000,
    unreadCountA: 0, unreadCountB: 0,
    peerNickname: '小雨', peerAvatar: 'avatar_user_4'
  },
  // 新增：老客户王姐
  {
    sessionId: 's005', type: 'private', userAId: 'u005', userBId: SELF_FARMER_ID,
    lastMessage: '这周的鸡蛋给我留两盒', lastMessageAt: 1737120000000,
    unreadCountA: 0, unreadCountB: 3,
    peerNickname: '王姐', peerAvatar: 'avatar_user_5'
  },
  // 新增：新客户李先生
  {
    sessionId: 's006', type: 'private', userAId: 'u006', userBId: SELF_FARMER_ID,
    lastMessage: '请问你们家苹果怎么卖', lastMessageAt: 1737110000000,
    unreadCountA: 0, unreadCountB: 1,
    peerNickname: '李先生', peerAvatar: 'avatar_user_6'
  },
  // 新增：订单通知
  {
    sessionId: 's_sys_003', type: 'system', userAId: 'system', userBId: SELF_FARMER_ID,
    lastMessage: '您有新的订单待发货（订单号：ZN20260725001）', lastMessageAt: 1737100000000,
    unreadCountA: 0, unreadCountB: 1,
    peerNickname: '订单通知', peerAvatar: 'avatar_system'
  },
  // 新增：客户张阿姨
  {
    sessionId: 's007', type: 'private', userAId: 'u007', userBId: SELF_FARMER_ID,
    lastMessage: '上次买的茶叶不错，再来一斤', lastMessageAt: 1737090000000,
    unreadCountA: 0, unreadCountB: 0,
    peerNickname: '张阿姨', peerAvatar: 'avatar_user_7'
  }
];

/** 聊天消息 Mock（按会话ID分组） */
export const MOCK_MESSAGES: Record<string, ChatMessage[]> = {
  's001': [
    {
      messageId: 'm011', sessionId: 's001', senderId: 'u001', receiverId: SELF_FARMER_ID,
      contentType: 'text', content: '老板，青菜还有货吗', isRead: true, createdAt: 1737179900000,
      senderNickname: '小马哥', senderAvatar: 'avatar_user_1'
    },
    {
      messageId: 'm012', sessionId: 's001', senderId: SELF_FARMER_ID, receiverId: 'u001',
      contentType: 'text', content: '有的，今天刚摘的，特别新鲜', isRead: true, createdAt: 1737180000000,
      senderNickname: '青禾农庄', senderAvatar: 'avatar_farmer_1'
    },
    {
      messageId: 'm013', sessionId: 's001', senderId: 'u001', receiverId: SELF_FARMER_ID,
      contentType: 'text', content: '想买2斤', isRead: true, createdAt: 1737180100000,
      senderNickname: '小马哥', senderAvatar: 'avatar_user_1'
    },
    {
      messageId: 'm014', sessionId: 's001', senderId: SELF_FARMER_ID, receiverId: 'u001',
      contentType: 'text', content: '好的，2斤一共24元', isRead: true, createdAt: 1737180200000,
      senderNickname: '青禾农庄', senderAvatar: 'avatar_farmer_1'
    },
    {
      messageId: 'm015', sessionId: 's001', senderId: 'u001', receiverId: SELF_FARMER_ID,
      contentType: 'text', content: '能便宜点吗', isRead: true, createdAt: 1737180300000,
      senderNickname: '小马哥', senderAvatar: 'avatar_user_1'
    },
    {
      messageId: 'm016', sessionId: 's001', senderId: SELF_FARMER_ID, receiverId: 'u001',
      contentType: 'text', content: '已经是产地价啦，给您包邮吧', isRead: true, createdAt: 1737180400000,
      senderNickname: '青禾农庄', senderAvatar: 'avatar_farmer_1'
    },
    {
      messageId: 'm017', sessionId: 's001', senderId: 'u001', receiverId: SELF_FARMER_ID,
      contentType: 'text', content: '那行，怎么付款', isRead: false, createdAt: 1737180500000,
      senderNickname: '小马哥', senderAvatar: 'avatar_user_1'
    },
    {
      messageId: 'm018', sessionId: 's001', senderId: SELF_FARMER_ID, receiverId: 'u001',
      contentType: 'text', content: '您下单后我这边改价', isRead: false, createdAt: 1737180600000,
      senderNickname: '青禾农庄', senderAvatar: 'avatar_farmer_1'
    },
    {
      messageId: 'm019', sessionId: 's001', senderId: 'u001', receiverId: SELF_FARMER_ID,
      contentType: 'text', content: '已下单，麻烦尽快发货', isRead: false, createdAt: 1737180700000,
      senderNickname: '小马哥', senderAvatar: 'avatar_user_1'
    },
    {
      messageId: 'm020', sessionId: 's001', senderId: SELF_FARMER_ID, receiverId: 'u001',
      contentType: 'text', content: '好嘞，下午就给您发出去', isRead: false, createdAt: 1737180800000,
      senderNickname: '青禾农庄', senderAvatar: 'avatar_farmer_1'
    }
  ],
  's002': [
    {
      messageId: 'm003', sessionId: 's002', senderId: 'u002', receiverId: SELF_FARMER_ID,
      contentType: 'text', content: '大米怎么卖的', isRead: true, createdAt: 1737169000000,
      senderNickname: '阿芳', senderAvatar: 'avatar_user_2'
    },
    {
      messageId: 'm004', sessionId: 's002', senderId: SELF_FARMER_ID, receiverId: 'u002',
      contentType: 'text', content: '59元5kg 包邮', isRead: true, createdAt: 1737169500000,
      senderNickname: '青禾农庄', senderAvatar: 'avatar_farmer_1'
    },
    {
      messageId: 'm005', sessionId: 's002', senderId: 'u002', receiverId: SELF_FARMER_ID,
      contentType: 'text', content: '好的，谢谢老板', isRead: true, createdAt: 1737170000000,
      senderNickname: '阿芳', senderAvatar: 'avatar_user_2'
    }
  ],
  's003': [
    {
      messageId: 'm006', sessionId: 's003', senderId: 'u003', receiverId: SELF_FARMER_ID,
      contentType: 'text', content: '土猪肉什么时候有货', isRead: false, createdAt: 1737160000000,
      senderNickname: '阿强', senderAvatar: 'avatar_user_3'
    }
  ],
  's004': [
    {
      messageId: 'm007', sessionId: 's004', senderId: 'u004', receiverId: SELF_FARMER_ID,
      contentType: 'text', content: '大米5kg还有库存吗', isRead: true, createdAt: 1737130000000,
      senderNickname: '小雨', senderAvatar: 'avatar_user_4'
    },
    {
      messageId: 'm008', sessionId: 's004', senderId: SELF_FARMER_ID, receiverId: 'u004',
      contentType: 'text', content: '有的，东北五常大米，59元5kg包邮', isRead: true, createdAt: 1737130100000,
      senderNickname: '青禾农庄', senderAvatar: 'avatar_farmer_1'
    },
    {
      messageId: 'm009', sessionId: 's004', senderId: 'u004', receiverId: SELF_FARMER_ID,
      contentType: 'text', content: '好的，我要一袋', isRead: true, createdAt: 1737130200000,
      senderNickname: '小雨', senderAvatar: 'avatar_user_4'
    }
  ],
  // 新增：老客户王姐的会话消息
  's005': [
    {
      messageId: 'm021', sessionId: 's005', senderId: 'u005', receiverId: SELF_FARMER_ID,
      contentType: 'text', content: '老板好，这周的土鸡蛋给我留两盒', isRead: false, createdAt: 1737119000000,
      senderNickname: '王姐', senderAvatar: 'avatar_user_5'
    },
    {
      messageId: 'm022', sessionId: 's005', senderId: SELF_FARMER_ID, receiverId: 'u005',
      contentType: 'text', content: '没问题王姐，还是老价格35元一盒', isRead: false, createdAt: 1737119100000,
      senderNickname: '青禾农庄', senderAvatar: 'avatar_farmer_1'
    },
    {
      messageId: 'm023', sessionId: 's005', senderId: 'u005', receiverId: SELF_FARMER_ID,
      contentType: 'text', content: '这周的鸡蛋给我留两盒', isRead: false, createdAt: 1737120000000,
      senderNickname: '王姐', senderAvatar: 'avatar_user_5'
    }
  ],
  // 新增：新客户李先生的会话消息
  's006': [
    {
      messageId: 'm024', sessionId: 's006', senderId: 'u006', receiverId: SELF_FARMER_ID,
      contentType: 'text', content: '请问你们家苹果怎么卖', isRead: false, createdAt: 1737110000000,
      senderNickname: '李先生', senderAvatar: 'avatar_user_6'
    }
  ],
  // 新增：客户张阿姨的会话消息
  's007': [
    {
      messageId: 'm025', sessionId: 's007', senderId: 'u007', receiverId: SELF_FARMER_ID,
      contentType: 'text', content: '上次买的茶叶不错，再来一斤', isRead: true, createdAt: 1737090000000,
      senderNickname: '张阿姨', senderAvatar: 'avatar_user_7'
    },
    {
      messageId: 'm026', sessionId: 's007', senderId: SELF_FARMER_ID, receiverId: 'u007',
      contentType: 'text', content: '谢谢张阿姨捧场，明前茶128元/斤，给您优惠价120元', isRead: true, createdAt: 1737090100000,
      senderNickname: '青禾农庄', senderAvatar: 'avatar_farmer_1'
    },
    {
      messageId: 'm027', sessionId: 's007', senderId: 'u007', receiverId: SELF_FARMER_ID,
      contentType: 'text', content: '好的，还是那个价，给我寄过来吧', isRead: true, createdAt: 1737090200000,
      senderNickname: '张阿姨', senderAvatar: 'avatar_user_7'
    }
  ]
};

/**
 * 会话列表 Mock（含未读数）
 */
export function getMockSessions(): SessionListResult {
  const totalUnread: number = MOCK_SESSIONS.reduce((sum: number, s: ChatSession): number => sum + s.unreadCountB, 0);
  const result: SessionListResult = { list: MOCK_SESSIONS.slice(), totalUnread: totalUnread };
  return result;
}

/**
 * 根据 sessionId 查询消息列表
 */
export function getMockMessagesBySessionId(sessionId: string): ChatMessage[] {
  const list: ChatMessage[] | undefined = MOCK_MESSAGES[sessionId];
  return list ? list.slice() : [];
}

/**
 * Mock 发送消息（将消息存入 MOCK_MESSAGES 使其持久化，解决消息无法插入的问题）
 */
export function mockSendMessage(
  sessionId: string,
  content: string,
  senderId: string,
  receiverId: string = 'peer',
  senderNickname: string = '青禾农庄',
  senderAvatar: string = 'avatar_farmer_1'
): ChatMessage {
  const now: number = Date.now();
  const msg: ChatMessage = {
    messageId: `m_${now}`,
    sessionId,
    senderId,
    receiverId,
    contentType: 'text',
    content,
    isRead: true,
    createdAt: now,
    senderNickname,
    senderAvatar
  };
  // 将消息持久化到 MOCK_MESSAGES 中
  if (!MOCK_MESSAGES[sessionId]) {
    MOCK_MESSAGES[sessionId] = [];
  }
  MOCK_MESSAGES[sessionId].push(msg);
  // 更新会话的最后消息
  const session: ChatSession | undefined = MOCK_SESSIONS.find((s: ChatSession): boolean => s.sessionId === sessionId);
  if (session) {
    session.lastMessage = content;
    session.lastMessageAt = now;
  }
  return msg;
}
