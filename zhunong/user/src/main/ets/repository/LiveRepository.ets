/**
 * LiveRepository - 直播域 Repository（spec 10.3）
 * 封装直播列表取数，统一走 BaseRepository「先 REST 后 Mock」兜底
 * 后端部署后无需改代码，Repository 自动切真实数据
 */

import { BaseRepository, AppConstants, PageResult, SharedLiveStore, SharedLive } from 'common';
import { LiveListItem, LiveListParam, LiveCategory } from '../model/LiveModels';
import { getMockLiveList } from '../mock/LiveMock';

/** 直播列表查询参数（显式 interface，无索引签名，规避 arkts-no-untyped-obj-literals） */
interface LiveListQuery {
  page: number;
  size: number;
  status?: string;
  category?: string;
  keyword?: string;
}

class LiveRepositoryImpl {
  /**
   * 直播列表：GET /api/live/list?status=&category=&keyword=&page=&size=
   * 失败回退 Mock（getMockLiveList）
   * 合并 SharedLiveStore 中农户开播的直播到列表头部（实时同步）
   */
  async getLiveList(param: LiveListParam): Promise<PageResult<LiveListItem>> {
    const params: LiveListQuery = {
      page: param.page,
      size: param.size
    };
    if (param.status !== undefined) {
      params.status = param.status;
    }
    if (param.category !== undefined) {
      params.category = param.category;
    }
    if (param.keyword !== undefined && param.keyword.length > 0) {
      params.keyword = param.keyword;
    }
    const result: PageResult<LiveListItem> = await BaseRepository.fetchWithFallback<PageResult<LiveListItem>>(
      'live/list',
      params,
      async (): Promise<PageResult<LiveListItem>> => {
        const mockResult = getMockLiveList(param);
        const result: PageResult<LiveListItem> = {
          list: mockResult.list,
          total: mockResult.list.length,
          page: param.page,
          size: param.size,
          hasMore: mockResult.hasMore
        };
        return result;
      },
      AppConstants.SCENE_USER
    );
    // 合并共享直播池到列表头部（仅第一页，按 status/category 过滤）
    if (param.page === 1) {
      const sharedLives: SharedLive[] = await SharedLiveStore.getAll();
      let filtered: SharedLive[] = sharedLives;
      if (param.status !== undefined) {
        filtered = filtered.filter((l: SharedLive): boolean => l.status === param.status);
      }
      if (param.category !== undefined) {
        filtered = filtered.filter((l: SharedLive): boolean => l.category === param.category);
      }
      const sharedItems: LiveListItem[] = filtered.map((l: SharedLive): LiveListItem => {
        return {
          liveId: l.liveId,
          farmerId: l.farmerId,
          anchorName: l.farmerName,
          anchorAvatar: l.farmerAvatar,
          isFollowing: false,
          title: l.title,
          coverImage: l.coverImage,
          category: l.category as LiveCategory,
          intro: '',
          productBag: [],
          status: l.status,
          onlineCount: l.onlineCount,
          totalViewUv: l.totalViewUv,
          totalGiftIncome: 0,
          totalOrderIncome: 0,
          monthlyIncome: 0,
          likeCount: 0,
          createdAt: l.createdAt
        };
      });
      if (sharedItems.length > 0) {
        const mockIds: Set<string> = new Set<string>(result.list.map((it: LiveListItem): string => it.liveId));
        const dedup: LiveListItem[] = sharedItems.filter(
          (it: LiveListItem): boolean => !mockIds.has(it.liveId)
        );
        const merged: LiveListItem[] = dedup.concat(result.list);
        const mergedResult: PageResult<LiveListItem> = {
          list: merged,
          total: merged.length,
          page: result.page,
          size: result.size,
          hasMore: result.hasMore
        };
        return mergedResult;
      }
    }
    return result;
  }
}

/** 直播域 Repository 单例 */
export const LiveRepository: LiveRepositoryImpl = new LiveRepositoryImpl();
