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

/** spec 16.10：内存中保存用户已创建的直播（封面图/标题/状态等同步到列表） */
class CreatedLiveStore {
  static items: LiveListItem[] = [];
  static add(item: LiveListItem): void {
    // 去重：相同 liveId 不重复添加
    const exists: boolean = CreatedLiveStore.items.some(
      (it: LiveListItem): boolean => it.liveId === item.liveId
    );
    if (!exists) {
      CreatedLiveStore.items.unshift(item);
    }
  }
  static markEnded(liveId: string): void {
    CreatedLiveStore.items = CreatedLiveStore.items.map((it: LiveListItem): LiveListItem => {
      if (it.liveId === liveId) {
        return {
          liveId: it.liveId,
          title: it.title,
          coverImage: it.coverImage,
          farmerName: it.farmerName,
          farmerAvatar: it.farmerAvatar,
          status: 'ended',
          onlineCount: it.onlineCount,
          totalViewUv: it.totalViewUv,
          category: it.category
        };
      }
      return it;
    });
  }
  static getAll(): LiveListItem[] {
    return CreatedLiveStore.items;
  }
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
    // spec 16.10：内存保存新建直播，同步封面图到浏览列表
    const newItem: LiveListItem = {
      liveId: result,
      title: form.title,
      coverImage: form.coverImage,
      farmerName: anchorName,
      farmerAvatar: anchorAvatar,
      status: 'living',
      onlineCount: 1,
      totalViewUv: 0,
      category: form.category
    };
    CreatedLiveStore.add(newItem);
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
    // spec 16.10：同步内存中已创建直播的状态为 ended
    CreatedLiveStore.markEnded(liveId);
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
        // spec 16.10：将内存中已创建的直播合并到列表头部（封面图/标题/状态实时同步）
        const createdItems: LiveListItem[] = CreatedLiveStore.getAll();
        let merged: LiveListItem[];
        if (page === 1 && createdItems.length > 0) {
          const mockIds: Set<string> = new Set<string>(mockResult.list.map(
            (it: LiveListItem): string => it.liveId
          ));
          const dedup: LiveListItem[] = createdItems.filter(
            (it: LiveListItem): boolean => !mockIds.has(it.liveId)
          );
          merged = dedup.concat(mockResult.list);
        } else {
          merged = mockResult.list;
        }
        const result: PageResult<LiveListItem> = {
          list: merged,
          total: mockResult.total + createdItems.length,
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
