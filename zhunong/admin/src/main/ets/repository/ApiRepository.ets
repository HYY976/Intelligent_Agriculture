/**
 * ApiRepository - API 管理域 Repository（spec 3.3.2 / 10.8.3.2）
 * 走 BaseRepository.fetchWithFallback / postWithFallback：先 REST 后 Mock 兜底
 * 含 API 列表 / API 详情 / 限流配置 / 密钥管理
 * 现阶段后端未实现监控逻辑，全部 Mock 数据
 */

import { BaseRepository, AppConstants, PageResult } from 'common';
import {
  ApiInfo,
  ApiListQuery,
  ApiDetailAggregate,
  RateLimitConfig,
  RateLimitUpdateRequest,
  ApiKey,
  CreateApiKeyResponse
} from '../model/AdminModels';
import {
  getMockApis,
  getMockApiDetail,
  getMockRateLimitConfig,
  getMockApiKeys,
  getMockCreatedApiKey,
  MOCK_API_KEYS
} from '../mock/AdminMock';

/** API 列表查询参数（HTTP GET query） */
interface ApiListHttpQuery {
  keyword?: string;
  page: number;
  size: number;
}

/** 限流配置更新请求体 */
interface RateLimitUpdateBody {
  apiId: string;
  qpsLimit: number;
  concurrentLimit: number;
  circuitBreakThreshold: number;
}

class ApiRepositoryImpl {
  /**
   * API 列表（spec 3.3.2：路径搜索 + 分页）
   * GET /api/admin/apis
   */
  async getApis(query: ApiListQuery): Promise<PageResult<ApiInfo>> {
    const params: ApiListHttpQuery = {
      page: query.page,
      size: query.size
    };
    if (query.keyword) {
      params.keyword = query.keyword;
    }
    return BaseRepository.fetchWithFallback<PageResult<ApiInfo>>(
      'admin/apis',
      params,
      async (): Promise<PageResult<ApiInfo>> => getMockApis(query),
      AppConstants.SCENE_ADMIN
    );
  }

  /**
   * API 详情聚合（spec 3.3.2：基本信息 + 趋势图 + 错误日志）
   * GET /api/admin/apis/{apiId}
   */
  async getApiDetail(apiId: string): Promise<ApiDetailAggregate | null> {
    return BaseRepository.fetchWithFallback<ApiDetailAggregate | null>(
      `admin/apis/${apiId}`,
      undefined,
      async (): Promise<ApiDetailAggregate | null> => getMockApiDetail(apiId),
      AppConstants.SCENE_ADMIN
    );
  }

  /**
   * 获取限流配置（spec 3.3.2）
   * GET /api/admin/apis/{apiId}/rate-limit
   */
  async getRateLimitConfig(apiId: string): Promise<RateLimitConfig | null> {
    return BaseRepository.fetchWithFallback<RateLimitConfig | null>(
      `admin/apis/${apiId}/rate-limit`,
      undefined,
      async (): Promise<RateLimitConfig | null> => getMockRateLimitConfig(apiId),
      AppConstants.SCENE_ADMIN
    );
  }

  /**
   * 更新限流配置（spec 3.3.2）
   * PUT /api/admin/apis/{apiId}/rate-limit
   */
  async updateRateLimit(req: RateLimitUpdateRequest): Promise<boolean> {
    const body: RateLimitUpdateBody = {
      apiId: req.apiId,
      qpsLimit: req.qpsLimit,
      concurrentLimit: req.concurrentLimit,
      circuitBreakThreshold: req.circuitBreakThreshold
    };
    const result: boolean = await BaseRepository.postWithFallback<boolean>(
      `admin/apis/${req.apiId}/rate-limit`,
      body,
      async (): Promise<boolean> => true,
      AppConstants.SCENE_ADMIN
    );
    return result;
  }

  /**
   * 密钥列表（spec 3.3.2）
   * GET /api/admin/api-keys
   */
  async listApiKeys(): Promise<ApiKey[]> {
    return BaseRepository.fetchWithFallback<ApiKey[]>(
      'admin/api-keys',
      undefined,
      async (): Promise<ApiKey[]> => getMockApiKeys(),
      AppConstants.SCENE_ADMIN
    );
  }

  /**
   * 创建密钥（spec 3.3.2：仅展示一次 Secret）
   * POST /api/admin/api-keys
   */
  async createApiKey(): Promise<CreateApiKeyResponse> {
    return BaseRepository.postWithFallback<CreateApiKeyResponse>(
      'admin/api-keys',
      undefined,
      async (): Promise<CreateApiKeyResponse> => getMockCreatedApiKey(),
      AppConstants.SCENE_ADMIN
    );
  }

  /**
   * 吊销密钥（spec 3.3.2）
   * PUT /api/admin/api-keys/{keyId}/revoke
   */
  async revokeApiKey(keyId: string): Promise<boolean> {
    // Mock 模式下直接更新本地状态
    const key: ApiKey | undefined = MOCK_API_KEYS.find(
      (k: ApiKey): boolean => k.keyId === keyId
    );
    if (key) {
      key.status = 'revoked';
      key.revokedAt = Date.now();
    }
    const result: boolean = await BaseRepository.postWithFallback<boolean>(
      `admin/api-keys/${keyId}/revoke`,
      undefined,
      async (): Promise<boolean> => true,
      AppConstants.SCENE_ADMIN
    );
    return result;
  }
}

/** API 管理域 Repository 单例 */
export const ApiRepository: ApiRepositoryImpl = new ApiRepositoryImpl();
