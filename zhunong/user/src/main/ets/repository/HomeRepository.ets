/**
 * HomeRepository - 首页域 Repository（spec 10.3）
 * 封装首页推荐流 + Banner 取数，统一走 BaseRepository「先 REST 后 Mock」兜底
 * 后端部署后无需改代码，Repository 自动切真实数据
 */

import { BaseRepository, AppConstants, PageResult, SharedProductStore, SharedProduct } from 'common';
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
   * 合并 SharedProductStore 中 status='approved' 的农户发布商品到列表头部（实时同步）
   */
  async getRecommendList(page: number, size: number): Promise<PageResult<ProductListItem>> {
    const params: RecommendQuery = { page: page, size: size };
    const result: PageResult<ProductListItem> = await BaseRepository.fetchWithFallback<PageResult<ProductListItem>>(
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
    // 合并共享商品池中 approved 状态的农户商品到列表头部（仅第一页）
    if (page === 1) {
      const sharedProducts: SharedProduct[] = await SharedProductStore.getAll();
      const sharedItems: ProductListItem[] = sharedProducts
        .filter((p: SharedProduct): boolean => p.status === 'approved')
        .map((p: SharedProduct): ProductListItem => {
          return {
            productId: p.productId,
            title: p.title,
            mainImage: p.mainImages.length > 0 ? p.mainImages[0] : '',
            price: p.price,
            monthlySales: p.monthlySales,
            farmerName: p.farmerName,
            shipFrom: p.shipFrom,
            monthlyGmv: p.monthlyGmv
          };
        });
      if (sharedItems.length > 0) {
        const mockIds: Set<string> = new Set<string>(result.list.map((it: ProductListItem): string => it.productId));
        const dedup: ProductListItem[] = sharedItems.filter(
          (it: ProductListItem): boolean => !mockIds.has(it.productId)
        );
        const merged: ProductListItem[] = dedup.concat(result.list);
        const mergedResult: PageResult<ProductListItem> = {
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
