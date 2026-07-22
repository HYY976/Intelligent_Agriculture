/**
 * LiveRepository - 直播域 Repository（spec 10.3）
 * 封装直播列表取数，统一走 BaseRepository「先 REST 后 Mock」兜底
 * 后端部署后无需改代码，Repository 自动切真实数据
 */

import { BaseRepository, AppConstants, PageResult } from 'common';
import { LiveListItem, LiveListParam } from '../model/LiveModels';
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
    return BaseRepository.fetchWithFallback<PageResult<LiveListItem>>(
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
  }
}

/** 直播域 Repository 单例 */
export const LiveRepository: LiveRepositoryImpl = new LiveRepositoryImpl();
