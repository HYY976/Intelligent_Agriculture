/**
 * AiPosterClient - AI 海报生成接口客户端（spec 8.2）
 *
 * 协议：异步任务式（创建 + 轮询）
 *  - 创建接口：POST /api/ai/poster/task → 返回 taskId
 *  - 轮询接口：GET /api/ai/poster/task/{taskId} → 状态 pending → done（posterUrl）/ failed
 *  - 轮询策略（spec 8.2.3 / AppConstants.AI_POSTER_POLL_*）：每3秒一次，最多20次（60秒超时）
 *
 * 现阶段 Mock 策略（spec 8.2.3）：
 *  - 后端未部署时，创建任务后5秒返回商品首图作为 posterUrl
 *  - Phase 6 联调：后端部署后，自动恢复真实异步任务
 *
 * 入参（spec 8.2.1 AiPosterTaskRequest）：
 *  - productId?: 商品ID
 *  - images[]: 商品图片URL
 *  - title: 商品标题
 *  - style?: 风格（清新/复古/国风）
 */

import { Logger, AppConstants, HttpUtil } from 'common';
import { ApiResponse } from 'common';
import {
  AiPosterTaskRequest,
  AiPosterTaskResponse,
  AiPosterTaskResult,
  AiPosterListeners
} from '../model/AiModels';

/** 创建任务接口路径 */
const PATH_CREATE: string = '/ai/poster/task';
/** 查询任务接口路径模板 */
const PATH_QUERY_TEMPLATE: string = '/ai/poster/task/';

/** Mock 海报生成延迟（毫秒，spec 8.2.3：5秒后返回） */
const MOCK_POSTER_DELAY_MS: number = 5000;

/** Mock 海报 URL（spec 16.12：使用资源管理器中的图片作为海报结果，统一 key 便于各页面 ImageUtil 映射） */
const MOCK_POSTER_URL: string = 'ai_poster_result';
const MOCK_THUMBNAIL_URL: string = 'ai_poster_result';

class AiPosterClientImpl {
  /** 当前轮询定时器 */
  private pollTimer: number = -1;
  /** 当前轮询次数 */
  private pollCount: number = 0;
  /** 当前 taskId */
  private currentTaskId: string = '';
  /** 当前监听器 */
  private currentListeners: AiPosterListeners | null = null;
  /** Mock 模式标记 */
  private isMockMode: boolean = false;
  /** Mock 完成定时器 */
  private mockCompleteTimer: number = -1;

  /**
   * 创建海报生成任务并开始轮询
   * @param request 入参
   * @param listeners 监听器（onProgress / onDone / onError）
   */
  async createAndPoll(request: AiPosterTaskRequest, listeners: AiPosterListeners): Promise<void> {
    this.currentListeners = listeners;
    this.pollCount = 0;
    Logger.info(AppConstants.SCENE_FARMER, {
      action: 'ai_poster_start',
      title: request.title,
      style: request.style ?? ''
    });

    // 调用创建任务接口
    try {
      const resp: ApiResponse<AiPosterTaskResponse> = await HttpUtil.post<AiPosterTaskResponse>(
        PATH_CREATE,
        request,
        { timeout: AppConstants.HTTP_TIMEOUT_AI, showErrorToast: false }
      );
      if (resp.code === AppConstants.CODE_SUCCESS && resp.data) {
        this.currentTaskId = resp.data.taskId;
        this.isMockMode = false;
        this.startPolling();
        return;
      }
      // REST 失败，进入 Mock 模式
      Logger.warn(AppConstants.SCENE_FARMER, { action: 'ai_poster_create_fail_switch_mock', code: resp.code });
      this.enterMockMode(request);
    } catch (err) {
      Logger.warn(AppConstants.SCENE_FARMER, {
        action: 'ai_poster_create_err_switch_mock',
        error: (err as Error).message
      });
      this.enterMockMode(request);
    }
  }

  /** 取消任务（停止轮询） */
  cancel(): void {
    this.stopPolling();
    this.stopMockComplete();
    this.currentListeners = null;
    Logger.info(AppConstants.SCENE_FARMER, { action: 'ai_poster_cancel', taskId: this.currentTaskId });
  }

  /** 启动轮询（spec 8.2.3：每3秒一次，最多20次） */
  private startPolling(): void {
    this.stopPolling();
    this.pollTimer = setInterval(() => {
      this.pollOnce();
    }, AppConstants.AI_POSTER_POLL_INTERVAL);
  }

  /** 停止轮询 */
  private stopPolling(): void {
    if (this.pollTimer !== -1) {
      clearInterval(this.pollTimer);
      this.pollTimer = -1;
    }
  }

  /** 单次轮询 */
  private async pollOnce(): Promise<void> {
    this.pollCount++;
    if (this.pollCount > AppConstants.AI_POSTER_POLL_MAX_TIMES) {
      // 超时（spec 8.2.3：60秒超时）
      this.stopPolling();
      this.currentListeners?.onError('AI生成超时，请重试');
      this.currentListeners = null;
      Logger.warn(AppConstants.SCENE_FARMER, { action: 'ai_poster_poll_timeout', taskId: this.currentTaskId });
      return;
    }
    try {
      const url: string = `${PATH_QUERY_TEMPLATE}${this.currentTaskId}`;
      const resp: ApiResponse<AiPosterTaskResult> = await HttpUtil.get<AiPosterTaskResult>(
        url,
        undefined,
        { timeout: AppConstants.HTTP_TIMEOUT_DEFAULT, showErrorToast: false }
      );
      if (resp.code === AppConstants.CODE_SUCCESS && resp.data) {
        const result: AiPosterTaskResult = resp.data;
        this.currentListeners?.onProgress(result.status);
        if (result.status === 'done') {
          this.stopPolling();
          this.currentListeners?.onDone(result.posterUrl ?? '', result.thumbnailUrl ?? '');
          this.currentListeners = null;
        } else if (result.status === 'failed') {
          this.stopPolling();
          this.currentListeners?.onError(result.errorMessage ?? '生成失败');
          this.currentListeners = null;
        }
        // pending 状态继续轮询
      }
    } catch (err) {
      Logger.warn(AppConstants.SCENE_FARMER, {
        action: 'ai_poster_poll_err',
        attempt: this.pollCount,
        error: (err as Error).message
      });
      // 单次轮询错误不中止，继续下次
    }
  }

  /** 进入 Mock 模式（spec 8.2.3：5秒后返回商品首图作为海报） */
  private enterMockMode(request: AiPosterTaskRequest): void {
    this.isMockMode = true;
    this.currentTaskId = `mock_task_${Date.now()}`;
    this.currentListeners?.onProgress('pending');
    Logger.info(AppConstants.SCENE_FARMER, { action: 'ai_poster_enter_mock', taskId: this.currentTaskId });

    this.mockCompleteTimer = setTimeout(() => {
      // spec 16.12：5 秒后返回 done + 资源图片作为海报
      this.currentListeners?.onProgress('done');
      this.currentListeners?.onDone(MOCK_POSTER_URL, MOCK_THUMBNAIL_URL);
      this.currentListeners = null;
      this.mockCompleteTimer = -1;
    }, MOCK_POSTER_DELAY_MS);
  }

  /** 停止 Mock 完成定时器 */
  private stopMockComplete(): void {
    if (this.mockCompleteTimer !== -1) {
      clearTimeout(this.mockCompleteTimer);
      this.mockCompleteTimer = -1;
    }
  }
}

/** AI 海报生成客户端单例 */
export const AiPosterClient: AiPosterClientImpl = new AiPosterClientImpl();
