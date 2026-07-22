/**
 * MessageRepository - 卖家端消息域 Repository（spec 3.2.4.4：与用户端消息互通）
 * 走 BaseRepository.fetchWithFallback：先 REST 后 Mock 兜底
 * 实时通信仍走 WsClient（长连接），本 Repository 仅负责会话列表与历史消息查询
 */

import { BaseRepository, AppConstants } from 'common';
import { ChatSession, ChatMessage, SessionListResult } from '../model/FarmerMessageModels';
import { getMockSessions, getMockMessagesBySessionId } from '../mock/FarmerMessageMock';

/** 会话列表查询参数 */
interface SessionListQuery {
  farmerId: string;
}

/** 历史消息查询参数 */
interface MessageListQuery {
  sessionId: string;
  page: number;
  size: number;
}

/** 发送消息请求体 */
interface SendMessageBody {
  sessionId: string;
  senderId: string;
  receiverId: string;
  content: string;
  contentType: 'text' | 'image' | 'emoji';
}

class MessageRepositoryImpl {
  /**
   * 会话列表（spec 3.1.3.3：私信会话 + 系统通知会话）
   * GET /api/message/sessions?farmerId=
   */
  async getSessions(farmerId: string): Promise<SessionListResult> {
    const params: SessionListQuery = { farmerId };
    return BaseRepository.fetchWithFallback<SessionListResult>(
      'message/sessions',
      params,
      async (): Promise<SessionListResult> => getMockSessions(),
      AppConstants.SCENE_FARMER
    );
  }

  /**
   * 历史消息列表（spec 3.1.3.3：离线消息缓存，上线后推送未读消息）
   * GET /api/message/history?sessionId=&page=&size=
   */
  async getMessageHistory(sessionId: string, page: number = 1, size: number = 50): Promise<ChatMessage[]> {
    const params: MessageListQuery = { sessionId, page, size };
    return BaseRepository.fetchWithFallback<ChatMessage[]>(
      'message/history',
      params,
      async (): Promise<ChatMessage[]> => getMockMessagesBySessionId(sessionId),
      AppConstants.SCENE_FARMER
    );
  }

  /**
   * 发送消息（spec 3.1.3.3：实时通信 WebSocket 长连接，离线时由本接口兜底）
   * POST /api/message/send
   */
  async sendMessage(
    sessionId: string,
    senderId: string,
    receiverId: string,
    content: string,
    contentType: 'text' | 'image' | 'emoji' = 'text'
  ): Promise<boolean> {
    const body: SendMessageBody = { sessionId, senderId, receiverId, content, contentType };
    const result: boolean = await BaseRepository.postWithFallback<boolean>(
      'message/send',
      body,
      async (): Promise<boolean> => true,
      AppConstants.SCENE_FARMER
    );
    return result;
  }
}

/** 消息域 Repository 单例 */
export const MessageRepository: MessageRepositoryImpl = new MessageRepositoryImpl();
