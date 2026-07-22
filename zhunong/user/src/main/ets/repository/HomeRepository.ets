/**
 * HomeRepository - 首页域 Repository（spec 10.3）
 * 封装首页推荐流 + Banner 取数，统一走 BaseRepository「先 REST 后 Mock」兜底
 * 后端部署后无需改代码，Repository 自动切真实数据
 */

import { BaseRepository, AppConstants, PageResult } from 'common';
import { ProductListItem } from '../model/ProductModels';
import { getMockProductList } from '../mock/ProductMock';
import { getMockBanners, BannerItem } from '../mock/BannerMock';

/** 首页推荐流查询参数（显式 interface，无索引签名，规避 arkts-no-untyped-obj-literals） */
interface RecommendQuery {
  page: number;
  size: number;
}

class HomeRepositoryImpl {
  /**
   * 首页推荐流：GET /api/home/recommend?page=&size=
   * 失败回退 Mock（getMockProductList）
   */
  async getRecommendList(page: number, size: number): Promise<PageResult<ProductListItem>> {
    const params: RecommendQuery = { page: page, size: size };
    return BaseRepository.fetchWithFallback<PageResult<ProductListItem>>(
      'home/recommend',
      params,
      async (): Promise<PageResult<ProductListItem>> => {
        const mockResult = getMockProductList(page, size, undefined, undefined, 'comprehensive');
        const result: PageResult<ProductListItem> = {
          list: mockResult.list,
          total: mockResult.list.length,
          page: page,
          size: size,
          hasMore: mockResult.hasMore
        };
        return result;
      },
      AppConstants.SCENE_USER
    );
  }

  /**
   * 首页 Banner：GET /api/home/banner
   * 失败回退 Mock（getMockBanners）
   */
  async getBanners(): Promise<BannerItem[]> {
    return BaseRepository.fetchWithFallback<BannerItem[]>(
      'home/banner',
      undefined,
      async (): Promise<BannerItem[]> => {
        return getMockBanners();
      },
      AppConstants.SCENE_USER
    );
  }
}

/** 首页域 Repository 单例 */
export const HomeRepository: HomeRepositoryImpl = new HomeRepositoryImpl();
