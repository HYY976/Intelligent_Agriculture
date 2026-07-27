/**
 * LiveManageRepository - 卖家直播管理域 Repository（spec 3.2.4.5）
 * 走 BaseRepository.fetchWithFallback：先 REST 后 Mock 兜底
 * 含直播管理历史 / 开播创建 / 结束直播 / 直播浏览列表 / 礼物 / 评论
 */

import { BaseRepository, AppConstants, PageResult } from 'common';
import { LiveManageItem, LiveCreateForm } from '../model/FarmerModels';
import { LiveListItem, LiveComment, Gift, LiveSortBy } from '../model/FarmerLiveModels';
import { getMockLiveManageList } from '../mock/FarmerMock';
import { getMockLiveList, getMockLiveComments, getMockGifts } from '../mock/FarmerLiveMock';

/** 直播管理历史查询参数 */
interface LiveManageQuery {
  farmerId: string;
  status?: string;
  page: number;
  size: number;
}

/** 直播浏览列表查询参数 */
interface LiveListQuery {
  sortBy: LiveSortBy;
  page: number;
  size: number;
}

/** 开播请求体（spec 16.4：携带 anchorName/anchorAvatar 同步注册身份） */
interface CreateLiveBody {
  farmerId: string;
  form: LiveCreateForm;
  anchorName: string;
  anchorAvatar: string;
}

/** 结束直播请求体 */
interface EndLiveBody {
  liveId: string;
}

class LiveManageRepositoryImpl {
  /**
   * 卖家直播管理历史列表（spec 3.2.4.5：历史直播列表+数据统计）
   * GET /api/farmer/lives?farmerId=&status=&page=&size=
   */
  async getMyLives(
    farmerId: string,
    page: number,
    size: number,
    statusFilter?: string
  ): Promise<PageResult<LiveManageItem>> {
    const params: LiveManageQuery = { farmerId, page, size };
    if (statusFilter && statusFilter.length > 0) {
      params.status = statusFilter;
    }
    return BaseRepository.fetchWithFallback<PageResult<LiveManageItem>>(
      'farmer/lives',
      params,
      async (): Promise<PageResult<LiveManageItem>> => {
        const mockResult = getMockLiveManageList(page, size, statusFilter);
        const result: PageResult<LiveManageItem> = {
          list: mockResult.list,
          total: mockResult.total,
          page: page,
          size: size,
          hasMore: mockResult.hasMore
        };
        return result;
      },
      AppConstants.SCENE_FARMER
    );
  }

  /**
   * 开播创建（spec 3.2.4.3 + spec 16.4：开始直播 → 直播状态变为 living，使用注册身份）
   * POST /api/farmer/live/create
   */
  async createLive(
    farmerId: string,
    form: LiveCreateForm,
    anchorName: string,
    anchorAvatar: string
  ): Promise<string> {
    const body: CreateLiveBody = { farmerId, form, anchorName, anchorAvatar };
    const result: string = await BaseRepository.postWithFallback<string>(
      'farmer/live/create',
      body,
      async (): Promise<string> => {
        return `l_${Date.now()}`;
      },
      AppConstants.SCENE_FARMER
    );
    return result;
  }

  /**
   * 结束直播（spec 3.2.4.3：主播端结束直播按钮）
   * POST /api/farmer/live/end
   */
  async endLive(liveId: string): Promise<boolean> {
    const body: EndLiveBody = { liveId };
    const result: boolean = await BaseRepository.postWithFallback<boolean>(
      'farmer/live/end',
      body,
      async (): Promise<boolean> => true,
      AppConstants.SCENE_FARMER
    );
    return result;
  }

  /**
   * 直播浏览列表（spec 3.2.1：与用户端相同的直播浏览页，仿抖音架构）
   * GET /api/live/list?sortBy=&page=&size=
   */
  async getLiveList(page: number, size: number, sortBy: LiveSortBy = 'hot'): Promise<PageResult<LiveListItem>> {
    const params: LiveListQuery = { sortBy, page, size };
    return BaseRepository.fetchWithFallback<PageResult<LiveListItem>>(
      'live/list',
      params,
      async (): Promise<PageResult<LiveListItem>> => {
        const mockResult = getMockLiveList(page, size, sortBy);
        const result: PageResult<LiveListItem> = {
          list: mockResult.list,
          total: mockResult.total,
          page: page,
          size: size,
          hasMore: mockResult.hasMore
        };
        return result;
      },
      AppConstants.SCENE_FARMER
    );
  }

  /**
   * 直播评论列表（spec 3.1.4.2 实时评论气泡滚动）
   * GET /api/live/comments?liveId=
   */
  async getLiveComments(liveId: string): Promise<LiveComment[]> {
    const params: LiveCommentsQuery = { liveId };
    return BaseRepository.fetchWithFallback<LiveComment[]>(
      'live/comments',
      params,
      async (): Promise<LiveComment[]> => getMockLiveComments(liveId),
      AppConstants.SCENE_FARMER
    );
  }

  /**
   * 礼物列表（spec 4.1.14）
   * GET /api/live/gifts
   */
  async getGifts(): Promise<Gift[]> {
    return BaseRepository.fetchWithFallback<Gift[]>(
      'live/gifts',
      undefined,
      async (): Promise<Gift[]> => getMockGifts(),
      AppConstants.SCENE_FARMER
    );
  }
}

/** 直播评论查询参数 */
interface LiveCommentsQuery {
  liveId: string;
}

/** 直播管理域 Repository 单例 */
export const LiveManageRepository: LiveManageRepositoryImpl = new LiveManageRepositoryImpl();
