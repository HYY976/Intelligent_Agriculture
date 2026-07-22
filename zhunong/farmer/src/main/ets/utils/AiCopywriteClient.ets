/**
 * AiCopywriteClient - AI 文案生成接口客户端（spec 8.1）
 *
 * 协议：WebSocket 流式返回（类似 ChatGPT 体验）
 * 接口：ws://server/api/ai/copywrite/stream?token=<jwt>
 *
 * 现阶段 Mock 策略（spec 8.1.4）：
 *  - 后端 WebSocket 服务未部署时，连接失败自动切本地 Mock 流式输出
 *  - Mock 实现：5秒内逐字返回预设文案（chunk）→ 完成信号（done）
 *  - Phase 6 联调：后端部署 ws 服务后，自动恢复真实流式
 *
 * 入参（spec 8.1.2 AiCopywriteRequest）：
 *  - productId?: 商品ID
 *  - title: 商品标题
 *  - category: 商品类目
 *  - images[]: 商品图片URL
 *  - keyPoints?: 关键卖点
 *
 * 出参流式（spec 8.1.3）：
 *  - { type: 'chunk', content } 文案片段
 *  - { type: 'done', description, highlights[] } 完成信号
 *  - { type: 'error', message } 错误
 */

import { webSocket } from '@kit.NetworkKit';
import { Logger, AppConstants, ConfigUtil, PreferencesUtil } from 'common';
import {
  AiCopywriteRequest,
  AiCopywriteMessage,
  AiCopywriteListeners
} from '../model/AiModels';

/** 流式文案 Mock 预设模板（spec 8.1.4：5秒内逐字返回） */
const MOCK_CHUNK_TEMPLATE: string[] = [
  '【产地直采】',
  '产自',
  '高山',
  '有机',
  '农场',
  '，',
  '海拔',
  '1800',
  '米',
  '，',
  '昼夜',
  '温差',
  '大',
  '，',
  '口感',
  '清甜',
  '。\n',
  '【',
  '品质',
  '保证',
  '】',
  '无',
  '农药',
  '无',
  '化肥',
  '，',
  '每',
  '日',
  '清晨',
  '采摘',
  '，',
  '冷链',
  '配送',
  '，',
  '新鲜',
  '到家',
  '。'
];

/** Mock 完成信号数据 */
const MOCK_DONE_DESCRIPTION: string = '产自高山有机农场，海拔1800米，昼夜温差大，叶色翠绿，口感清甜。每日清晨采摘，冷链配送，保证新鲜到家。建议清炒或做汤，保留原汁原味。';

/** Mock 亮点数组 */
const MOCK_DONE_HIGHLIGHTS: string[] = [
  '高山有机农场直采',
  '海拔1800米昼夜温差大',
  '无农药无化肥',
  '清晨采摘冷链配送',
  '口感清甜营养丰富'
];

/** Mock 流式发送间隔（毫秒） */
const MOCK_CHUNK_INTERVAL_MS: number = 150;

class AiCopywriteClientImpl {
  /** WebSocket 实例 */
  private ws: webSocket.WebSocket | null = null;
  /** Mock 流式定时器 */
  private mockTimer: number = -1;
  /** 当前 Mock 流式发送索引 */
  private mockChunkIndex: number = 0;
  /** 当前请求的预设文案（拼接后） */
  private mockFullChunks: string[] = MOCK_CHUNK_TEMPLATE;
  /** 当前监听器 */
  private currentListeners: AiCopywriteListeners | null = null;
  /** 是否主动取消 */
  private manualCancel: boolean = false;

  /**
   * 启动 AI 文案生成（流式）
   * @param request 入参
   * @param listeners 流式监听器（onChunk / onDone / onError）
   */
  async stream(request: AiCopywriteRequest, listeners: AiCopywriteListeners): Promise<void> {
    this.manualCancel = false;
    this.currentListeners = listeners;
    Logger.info(AppConstants.SCENE_FARMER, {
      action: 'ai_copywrite_start',
      title: request.title,
      category: request.category
    });

    // 尝试真实 WebSocket 连接
    const token: string = await PreferencesUtil.getString(AppConstants.KEY_TOKEN, '');
    const wsUrl: string = ConfigUtil.wsUrl(`api/ai/copywrite/stream?token=${token}`);

    try {
      this.ws = webSocket.createWebSocket();
      this.ws.on('open', () => {
        Logger.info(AppConstants.SCENE_FARMER, { action: 'ai_copywrite_ws_open' });
        // 发送请求体
        const reqStr: string = JSON.stringify(request);
        this.ws!.send(reqStr, (err: Error) => {
          if (err) {
            Logger.error(AppConstants.SCENE_FARMER, { action: 'ai_copywrite_ws_send_fail', error: err.message });
            this.enterMockMode();
          }
        });
      });
      this.ws.on('message', (err: Error, data: string | ArrayBuffer) => {
        if (err) {
          Logger.error(AppConstants.SCENE_FARMER, { action: 'ai_copywrite_ws_msg_err', error: err.message });
          return;
        }
        this.handleMessage(data);
      });
      this.ws.on('close', () => {
        Logger.info(AppConstants.SCENE_FARMER, { action: 'ai_copywrite_ws_close' });
      });
      this.ws.on('error', (err: Error) => {
        Logger.error(AppConstants.SCENE_FARMER, { action: 'ai_copywrite_ws_err', error: err.message });
        this.enterMockMode();
      });
      await this.ws.connect(wsUrl);
    } catch (err) {
      Logger.warn(AppConstants.SCENE_FARMER, {
        action: 'ai_copywrite_ws_connect_fail',
        error: (err as Error).message
      });
      this.enterMockMode();
    }
  }

  /** 取消生成 */
  cancel(): void {
    this.manualCancel = true;
    this.stopMock();
    if (this.ws) {
      try {
        this.ws.close((err: Error) => {
          if (err) {
            Logger.error(AppConstants.SCENE_FARMER, { action: 'ai_copywrite_ws_close_fail', error: err.message });
          }
        });
      } catch (err) {
        // 忽略
      }
      this.ws = null;
    }
    Logger.info(AppConstants.SCENE_FARMER, { action: 'ai_copywrite_cancel' });
  }

  /** 处理收到的 WebSocket 消息 */
  private handleMessage(data: string | ArrayBuffer): void {
    if (typeof data !== 'string') {
      return;
    }
    try {
      const msg: AiCopywriteMessage = JSON.parse(data) as AiCopywriteMessage;
      if (msg.type === 'chunk' && msg.content) {
        this.currentListeners?.onChunk(msg.content);
      } else if (msg.type === 'done') {
        this.currentListeners?.onDone(msg.description ?? '', msg.highlights ?? []);
        this.cleanup();
      } else if (msg.type === 'error') {
        this.currentListeners?.onError(msg.message ?? '生成失败');
        this.cleanup();
      }
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, {
        action: 'ai_copywrite_parse_fail',
        error: (err as Error).message
      });
    }
  }

  /** 进入 Mock 模式（spec 8.1.4：后端未部署时使用） */
  private enterMockMode(): void {
    if (this.manualCancel) {
      return;
    }
    Logger.info(AppConstants.SCENE_FARMER, { action: 'ai_copywrite_enter_mock' });
    this.mockChunkIndex = 0;
    this.mockFullChunks = MOCK_CHUNK_TEMPLATE;
    this.mockTimer = setInterval(() => {
      if (this.manualCancel) {
        this.stopMock();
        return;
      }
      if (this.mockChunkIndex < this.mockFullChunks.length) {
        const chunk: string = this.mockFullChunks[this.mockChunkIndex];
        this.currentListeners?.onChunk(chunk);
        this.mockChunkIndex++;
      } else {
        // 全部 chunk 发送完毕，发送 done 信号
        this.stopMock();
        this.currentListeners?.onDone(MOCK_DONE_DESCRIPTION, MOCK_DONE_HIGHLIGHTS);
        this.cleanup();
      }
    }, MOCK_CHUNK_INTERVAL_MS);
  }

  /** 停止 Mock 定时器 */
  private stopMock(): void {
    if (this.mockTimer !== -1) {
      clearInterval(this.mockTimer);
      this.mockTimer = -1;
    }
  }

  /** 清理状态 */
  private cleanup(): void {
    this.stopMock();
    this.ws = null;
    this.currentListeners = null;
  }
}

/** AI 文案生成客户端单例 */
export const AiCopywriteClient: AiCopywriteClientImpl = new AiCopywriteClientImpl();
