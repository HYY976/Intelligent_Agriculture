/**
 * ProductRepository - 商品域 Repository（spec 10.3 + spec 16.3 共享商品池）
 * 封装商品列表取数，统一走 BaseRepository「先 REST 后 Mock」兜底
 * Mock 兜底时合并 SharedProductStore（农户端发布的商品），实现双端同步
 * 后端部署后无需改代码，Repository 自动切真实数据
 */

import { BaseRepository, AppConstants, PageResult, SharedProductStore, SharedProduct } from 'common';
import { ProductListItem, ProductSortBy, Product, ProductSku } from '../model/ProductModels';
import { getMockProductList, getMockProductById } from '../mock/ProductMock';

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
   * 失败回退 Mock（getMockProductList + 合并 SharedProductStore）
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
        let list: ProductListItem[] = mockResult.list;

        // spec 16.3：page=1 时合并共享池商品到列表头部
        if (page === 1) {
          const sharedProducts: SharedProduct[] = await SharedProductStore.getAll();
          let sharedItems: ProductListItem[] = sharedProducts
            .filter((p: SharedProduct): boolean => p.status === 'approved')
            .filter((p: SharedProduct): boolean => {
              // 应用与 mock 列表相同的过滤条件
              if (categoryId !== undefined && categoryId.length > 0 && p.categoryId !== categoryId) {
                return false;
              }
              if (keyword !== undefined && keyword.length > 0) {
                const kw: string = keyword.toLowerCase();
                if (p.title.toLowerCase().indexOf(kw) < 0 && p.description.toLowerCase().indexOf(kw) < 0) {
                  return false;
                }
              }
              return true;
            })
            .map((p: SharedProduct): ProductListItem => {
              return {
                productId: p.productId,
                title: p.title,
                mainImage: p.mainImages[0] ?? '',
                price: p.price,
                monthlySales: p.monthlySales,
                farmerName: p.farmerName,
                shipFrom: p.shipFrom,
                monthlyGmv: p.monthlyGmv
              };
            });
          // 去重：共享池商品优先，排除 mock 列表中同 ID 的商品
          const sharedIds: Set<string> = new Set<string>(sharedItems.map((it: ProductListItem): string => it.productId));
          list = sharedItems.concat(list.filter((it: ProductListItem): boolean => !sharedIds.has(it.productId)));
        }

        const result: PageResult<ProductListItem> = {
          list: list,
          total: list.length,
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
   * 商品详情：GET /api/product/:productId
   * 失败回退 Mock（getMockProductById + 优先查 SharedProductStore）
   * spec 16.3：先查共享池（农户端发布的新品），未命中再查 mock
   */
  async getProductById(productId: string): Promise<Product | null> {
    // 优先查共享池
    const shared: SharedProduct | null = await SharedProductStore.getById(productId);
    if (shared !== null) {
      // 共享池商品无 SKU 数据，构造默认 SKU（用商品价格作为 SKU 价格）
      const defaultSku: ProductSku = {
        skuId: `${shared.productId}_default`,
        productId: shared.productId,
        specs: [{ name: '规格', value: '默认' }],
        price: shared.price,
        stock: shared.stock,
        skuCode: `${shared.productId}_DEFAULT`
      };
      return {
        productId: shared.productId,
        farmerId: shared.farmerId,
        title: shared.title,
        categoryId: shared.categoryId,
        mainImages: shared.mainImages,
        aiPosterUrl: shared.aiPosterUrl,
        description: shared.description,
        price: shared.price,
        stock: shared.stock,
        skuList: [defaultSku],
        shipFrom: shared.shipFrom,
        freightTemplate: shared.freightTemplate,
        monthlySales: shared.monthlySales,
        monthlyGmv: shared.monthlyGmv,
        totalSales: shared.totalSales,
        status: shared.status,
        createdAt: shared.createdAt,
        updatedAt: shared.updatedAt
      };
    }
    // 回退 mock
    return getMockProductById(productId);
  }
}

/** 商品域 Repository 单例 */
export const ProductRepository: ProductRepositoryImpl = new ProductRepositoryImpl();
