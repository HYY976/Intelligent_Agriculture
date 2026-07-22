/**
 * FansRepository - 粉丝域 Repository（spec 3.2.4.5：粉丝管理）
 * 走 BaseRepository.fetchWithFallback：先 REST 后 Mock 兜底
 */

import { BaseRepository, AppConstants, PageResult } from 'common';
import { FanInfo } from '../model/FarmerModels';
import { getMockFansList } from '../mock/FarmerMock';

/** 粉丝列表查询参数 */
interface FansListQuery {
  farmerId: string;
  page: number;
  size: number;
}

class FansRepositoryImpl {
  /**
   * 粉丝列表（spec 3.2.4.5：粉丝头像+昵称+关注时间）
   * GET /api/farmer/fans?farmerId=&page=&size=
   */
  async getFansList(farmerId: string, page: number, size: number): Promise<PageResult<FanInfo>> {
    const params: FansListQuery = { farmerId, page, size };
    return BaseRepository.fetchWithFallback<PageResult<FanInfo>>(
      'farmer/fans',
      params,
      async (): Promise<PageResult<FanInfo>> => {
        const mockResult = getMockFansList(page, size);
        const result: PageResult<FanInfo> = {
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
}

/** 粉丝域 Repository 单例 */
export const FansRepository: FansRepositoryImpl = new FansRepositoryImpl();
