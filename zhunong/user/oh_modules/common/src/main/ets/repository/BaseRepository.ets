/**
 * BaseRepository - Repository 基础设施（spec 10.3）
 * 通用取数模式：先真实 REST，失败回退 Mock
 * 后端部署后无需改代码，Repository 自动切真实数据
 *
 * 策略：
 *  1. 调 HttpUtil.get/post 真实 REST（baseUrl 由 ConfigUtil 管理）
 *  2. 若返回 code !== 200 或 data 为空 或网络异常 → 回退 Mock
 *  3. 回退时通过 Logger.warn 记录 fallback_to_mock 事件，便于联调阶段定位后端缺口
 */

import { HttpUtil } from '../utils/HttpUtil';
import { Logger } from '../utils/Logger';
import { ApiResponse } from '../model/CommonModels';

class BaseRepositoryImpl {
  /**
   * GET 取数：先真实 REST，失败回退 Mock
   * @param path REST 路径（不含 /api 前缀，由 HttpUtil 拼接）
   * @param params query 参数（可为 undefined）
   * @param mockProvider Mock 数据提供函数（REST 失败时调用）
   * @param scene 日志场景名（AppConstants.SCENE_USER 等）
   * @returns REST 成功返回 REST 数据，失败返回 Mock 数据
   */
  async fetchWithFallback<T>(
    path: string,
    params: object | undefined,
    mockProvider: () => Promise<T>,
    scene: string
  ): Promise<T> {
    try {
      const resp: ApiResponse<T> = await HttpUtil.get<T>(path, params, { showErrorToast: false });
      if (resp.code === 200 && resp.data !== null) {
        return resp.data;
      }
      // REST 返回非 200 或 data 为空，回退 Mock
      Logger.warn(scene, { action: 'fallback_to_mock', url: path, code: resp.code });
      return await mockProvider();
    } catch (err) {
      // 网络异常，回退 Mock
      Logger.warn(scene, { action: 'fallback_to_mock', url: path, error: (err as Error).message });
      return await mockProvider();
    }
  }

  /**
   * POST 取数：先真实 REST，失败回退 Mock
   * @param path REST 路径
   * @param body 请求体（可为 undefined）
   * @param mockProvider Mock 数据提供函数
   * @param scene 日志场景名
   */
  async postWithFallback<T>(
    path: string,
    body: object | undefined,
    mockProvider: () => Promise<T>,
    scene: string
  ): Promise<T> {
    try {
      const resp: ApiResponse<T> = await HttpUtil.post<T>(path, body, { showErrorToast: false });
      if (resp.code === 200 && resp.data !== null) {
        return resp.data;
      }
      Logger.warn(scene, { action: 'fallback_to_mock', url: path, code: resp.code });
      return await mockProvider();
    } catch (err) {
      Logger.warn(scene, { action: 'fallback_to_mock', url: path, error: (err as Error).message });
      return await mockProvider();
    }
  }
}

/** 全局 Repository 基础设施单例 */
export const BaseRepository: BaseRepositoryImpl = new BaseRepositoryImpl();
