/**
 * FarmerMessageMock - 卖家端消息域 Mock 数据（spec 4.1.10）
 * 与用户端消息互通（买卖家一对一聊天）
 */

import { ChatSession, ChatMessage, SessionListResult } from '../model/FarmerMessageModels';

/** 当前卖家ID（与 FarmerMock 一致） */
const SELF_FARMER_ID: string = 'f001';

/** 会话列表 Mock */
export const MOCK_SESSIONS: ChatSession[] = [
  {
    sessionId: 's001', type: 'private', userAId: 'u001', userBId: SELF_FARMER_ID,
    lastMessage: '老板，青菜还有货吗', lastMessageAt: 1737180000000,
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
  }
];

/** 聊天消息 Mock（按会话ID分组） */
export const MOCK_MESSAGES: Record<string, ChatMessage[]> = {
  's001': [
    {
      messageId: 'm001', sessionId: 's001', senderId: 'u001', receiverId: SELF_FARMER_ID,
      contentType: 'text', content: '老板，青菜还有货吗', isRead: true, createdAt: 1737179900000,
      senderNickname: '小马哥', senderAvatar: 'avatar_user_1'
    },
    {
      messageId: 'm002', sessionId: 's001', senderId: 'u001', receiverId: SELF_FARMER_ID,
      contentType: 'text', content: '想买2斤', isRead: false, createdAt: 1737180000000,
      senderNickname: '小马哥', senderAvatar: 'avatar_user_1'
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
 * Mock 发送消息（本地回声，spec Phase 6 联调时由 WsClient 接管）
 */
export function mockSendMessage(sessionId: string, content: string, senderId: string): ChatMessage {
  const now: number = Date.now();
  return {
    messageId: `m_${now}`,
    sessionId,
    senderId,
    receiverId: 'peer',
    contentType: 'text',
    content,
    isRead: true,
    createdAt: now,
    senderNickname: '青禾农庄',
    senderAvatar: 'avatar_farmer_1'
  };
}
