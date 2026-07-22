/**
 * ProductRepository - 商品域 Repository（spec 10.3）
 * 封装商品列表取数，统一走 BaseRepository「先 REST 后 Mock」兜底
 * 后端部署后无需改代码，Repository 自动切真实数据
 */

import { BaseRepository, AppConstants, PageResult } from 'common';
import { ProductListItem, ProductSortBy } from '../model/ProductModels';
import { getMockProductList } from '../mock/ProductMock';

/** 商品列表查询参数（显式 interface，无索引签名，规避 arkts-no-untyped-obj-literals） */
interface ProductListQuery {
  sortBy: string;
  page: number;
  size: number;
  categoryId?: string;
  keyword?: string;
}

class ProductRepositoryImpl {
  /**
   * 商品列表：GET /api/product/list?categoryId=&keyword=&sortBy=&page=&size=
   * 失败回退 Mock（getMockProductList）
   */
  async getProductList(
    page: number,
    size: number,
    categoryId?: string,
    keyword?: string,
    sortBy: ProductSortBy = 'comprehensive'
  ): Promise<PageResult<ProductListItem>> {
    const params: ProductListQuery = {
      sortBy: sortBy,
      page: page,
      size: size
    };
    if (categoryId !== undefined && categoryId.length > 0) {
      params.categoryId = categoryId;
    }
    if (keyword !== undefined && keyword.length > 0) {
      params.keyword = keyword;
    }
    return BaseRepository.fetchWithFallback<PageResult<ProductListItem>>(
      'product/list',
      params,
      async (): Promise<PageResult<ProductListItem>> => {
        const mockResult = getMockProductList(page, size, categoryId, keyword, sortBy);
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
}

/** 商品域 Repository 单例 */
export const ProductRepository: ProductRepositoryImpl = new ProductRepositoryImpl();
