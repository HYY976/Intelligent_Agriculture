/**
 * AiAgentClient - AI 智能体接口客户端（spec 8.3）
 *
 * 现阶段仅搭建接口调用层 + Mock 兜底，不实现具体 AI 逻辑（spec 8.3.3）
 * 含两个场景：
 *  - 智能商品介绍 TTS 语音合成（spec 8.3.1）：POST /api/ai/agent/tts
 *  - 智能商品顺序推荐（spec 8.3.2）：POST /api/ai/agent/product_recommend
 *
 * 现阶段 Mock 策略：
 *  - TTS：返回预设音频文件 URL
 *  - 商品推荐：返回该卖家销量 Top5 商品
 */

import { Logger, AppConstants, HttpUtil, BaseRepository } from 'common';
import { ApiResponse } from 'common';
import { AiTtsRequest, AiTtsResponse, AiRecommendRequest, AiRecommendResponse, AiRecommendItem } from '../model/AiModels';
import { getMockFarmerProducts } from '../mock/FarmerMock';

/** TTS 接口路径 */
const PATH_TTS: string = '/ai/agent/tts';
/** 商品推荐接口路径 */
const PATH_RECOMMEND: string = '/ai/agent/product_recommend';

/** Mock 音频 URL */
const MOCK_AUDIO_URL: string = 'mock_tts_audio_default';
/** Mock 音频时长（秒） */
const MOCK_AUDIO_DURATION_SEC: number = 30;

/** TTS 请求体 */
interface TtsRequestBody {
  productId: string;
  text: string;
  voiceType?: string;
}

/** 商品推荐请求体 */
interface RecommendRequestBody {
  farmerId: string;
  liveId?: string;
  context?: string;
}

class AiAgentClientImpl {
  /**
   * 智能商品介绍 TTS 语音合成（spec 8.3.1）
   * @param request 入参（productId / text / voiceType）
   * @returns 音频 URL + 时长
   */
  async tts(request: AiTtsRequest): Promise<AiTtsResponse> {
    Logger.info(AppConstants.SCENE_FARMER, {
      action: 'ai_tts_call',
      productId: request.productId,
      voiceType: request.voiceType ?? 'default'
    });
    const body: TtsRequestBody = {
      productId: request.productId,
      text: request.text,
      voiceType: request.voiceType
    };
    return BaseRepository.postWithFallback<AiTtsResponse>(
      PATH_TTS,
      body,
      async (): Promise<AiTtsResponse> => {
        // Mock：返回预设音频文件
        return {
          audioUrl: MOCK_AUDIO_URL,
          duration: MOCK_AUDIO_DURATION_SEC
        };
      },
      AppConstants.SCENE_FARMER
    );
  }

  /**
   * 智能商品顺序推荐（spec 8.3.2）
   * @param request 入参（farmerId / liveId? / context?）
   * @returns 推荐商品列表（含理由+优先级）
   */
  async recommend(request: AiRecommendRequest): Promise<AiRecommendResponse> {
    Logger.info(AppConstants.SCENE_FARMER, {
      action: 'ai_recommend_call',
      farmerId: request.farmerId,
      context: request.context ?? ''
    });
    const body: RecommendRequestBody = {
      farmerId: request.farmerId,
      liveId: request.liveId,
      context: request.context
    };
    return BaseRepository.postWithFallback<AiRecommendResponse>(
      PATH_RECOMMEND,
      body,
      async (): Promise<AiRecommendResponse> => {
        // Mock：返回该卖家销量 Top5 商品（spec 8.3.2 现阶段 Mock 策略）
        const mockResult = getMockFarmerProducts(1, 5);
        const sorted = mockResult.list.slice().sort((a, b) => b.monthlySales - a.monthlySales);
        const top5 = sorted.slice(0, 5);
        const recommendations: AiRecommendItem[] = top5.map((p, idx): AiRecommendItem => {
          return {
            productId: p.productId,
            reason: `月销 ${p.monthlySales} 件，销量稳定，适合${idx === 0 ? '开场主推' : '中场衔接'}`,
            priority: idx + 1
          };
        });
        return { recommendations };
      },
      AppConstants.SCENE_FARMER
    );
  }
}

/** AI 智能体客户端单例 */
export const AiAgentClient: AiAgentClientImpl = new AiAgentClientImpl();
