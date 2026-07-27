/**
 * FansRepository - 粉丝域 Repository（spec 3.2.4.5：粉丝管理）
 * spec 16.8：直接返回 Mock 数据，避免网络请求失败导致"加载中"卡住
 */

import { AppConstants, PageResult, Logger } from 'common';
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
   * spec 16.8：直接使用 Mock 数据，确保粉丝列表正常显示
   */
  async getFansList(farmerId: string, page: number, size: number): Promise<PageResult<FanInfo>> {
    try {
      // 直接使用 Mock 数据，避免网络请求导致加载失败
      const mockResult = getMockFansList(page, size);
      Logger.info(AppConstants.SCENE_FARMER, {
        action: 'fans_list_mock_success',
        page: page,
        count: mockResult.list.length,
        total: mockResult.total
      });
      const result: PageResult<FanInfo> = {
        list: mockResult.list,
        total: mockResult.total,
        page: page,
        size: size,
        hasMore: mockResult.hasMore
      };
      return result;
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, {
        action: 'fans_list_fail',
        error: (err as Error).message
      });
      return { list: [], total: 0, page: page, size: size, hasMore: false };
    }
  }
}

/** 粉丝域 Repository 单例 */
export const FansRepository: FansRepositoryImpl = new FansRepositoryImpl();
