/**
 * AdRepository - 广告管理域 Repository（spec 3.3.4）
 * 走 BaseRepository.fetchWithFallback / postWithFallback：先 REST 后 Mock 兜底
 * 含广告列表（广告位筛选）/ 概览统计 / 切换启用 / 创建广告
 */

import { BaseRepository, AppConstants, PageResult } from 'common';
import {
  AdRecord,
  AdListQuery,
  AdOverviewStats,
  AdCreateRequest
} from '../model/AdminModels';
import {
  getMockAds,
  getMockAdOverviewStats,
  toggleMockAdEnabled,
  createMockAd,
  MOCK_ADS
} from '../mock/AdminMock';

/** 广告列表查询参数（HTTP GET query） */
interface AdListHttpQuery {
  slot?: string;
  page: number;
  size: number;
}

/** 广告创建请求体（HTTP POST body） */
interface AdCreateBody {
  slot: string;
  title: string;
  coverKey: string;
  startAt: number;
  endAt: number;
  budget: number;
  audiences: string[];
}

class AdRepositoryImpl {
  /**
   * 广告列表（spec 3.3.4：广告位筛选 + 分页）
   * GET /api/admin/ads
   */
  async getAds(query: AdListQuery): Promise<PageResult<AdRecord>> {
    const params: AdListHttpQuery = {
      page: query.page,
      size: query.size
    };
    if (query.slot) {
      params.slot = query.slot;
    }
    return BaseRepository.fetchWithFallback<PageResult<AdRecord>>(
      'admin/ads',
      params,
      async (): Promise<PageResult<AdRecord>> => getMockAds(query),
      AppConstants.SCENE_ADMIN
    );
  }

  /**
   * 广告概览统计（spec 3.3.4：投放中/待审核/已暂停）
   * GET /api/admin/ads/overview-stats
   */
  async getOverviewStats(): Promise<AdOverviewStats> {
    return BaseRepository.fetchWithFallback<AdOverviewStats>(
      'admin/ads/overview-stats',
      undefined,
      async (): Promise<AdOverviewStats> => getMockAdOverviewStats(),
      AppConstants.SCENE_ADMIN
    );
  }

  /**
   * 切换广告启用状态（spec 3.3.4：开关切换）
   * PUT /api/admin/ads/{adId}/toggle
   */
  async toggleAdEnabled(adId: string): Promise<AdRecord | null> {
    // Mock 模式下直接更新本地状态
    toggleMockAdEnabled(adId);
    const result: AdRecord | null = await BaseRepository.postWithFallback<AdRecord | null>(
      `admin/ads/${adId}/toggle`,
      undefined,
      async (): Promise<AdRecord | null> => {
        const ad: AdRecord | undefined = MOCK_ADS.find((a: AdRecord): boolean => a.adId === adId);
        return ad ? ad : null;
      },
      AppConstants.SCENE_ADMIN
    );
    return result;
  }

  /**
   * 创建广告（spec 3.3.4：新建广告表单提交）
   * POST /api/admin/ads
   */
  async createAd(req: AdCreateRequest): Promise<AdRecord> {
    const audiencesBody: string[] = req.audiences.map((a: string): string => a);
    const body: AdCreateBody = {
      slot: req.slot,
      title: req.title,
      coverKey: req.coverKey,
      startAt: req.startAt,
      endAt: req.endAt,
      budget: req.budget,
      audiences: audiencesBody
    };
    const result: AdRecord = await BaseRepository.postWithFallback<AdRecord>(
      'admin/ads',
      body,
      async (): Promise<AdRecord> => createMockAd(req),
      AppConstants.SCENE_ADMIN
    );
    return result;
  }
}

/** 广告管理域 Repository 单例 */
export const AdRepository: AdRepositoryImpl = new AdRepositoryImpl();
