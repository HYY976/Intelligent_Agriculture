/**
 * ProductManageRepository - 卖家商品管理域 Repository（spec 3.2.4.5）
 * 走 BaseRepository.fetchWithFallback：先 REST 后 Mock 兜底
 * 含商品列表 / 上下架 / 编辑 / 删除 / 上架发布
 */

import { BaseRepository, AppConstants, PageResult, ProductStatus } from 'common';
import { FarmerProductItem, ProductPublishForm } from '../model/FarmerModels';
import { getMockFarmerProducts } from '../mock/FarmerMock';

/** 商品管理列表查询参数 */
interface ProductManageQuery {
  farmerId: string;
  status?: string;
  page: number;
  size: number;
}

/** 上下架请求体 */
interface SetStatusBody {
  productId: string;
  status: ProductStatus;
}

/** 删除商品请求体 */
interface DeleteProductBody {
  productId: string;
}

class ProductManageRepositoryImpl {
  /**
   * 卖家商品管理列表（spec 3.2.4.5：商品列表+上下架+编辑+删除）
   * GET /api/farmer/products?farmerId=&status=&page=&size=
   */
  async getMyProducts(
    farmerId: string,
    page: number,
    size: number,
    statusFilter?: string
  ): Promise<PageResult<FarmerProductItem>> {
    const params: ProductManageQuery = { farmerId, page, size };
    if (statusFilter && statusFilter.length > 0) {
      params.status = statusFilter;
    }
    return BaseRepository.fetchWithFallback<PageResult<FarmerProductItem>>(
      'farmer/products',
      params,
      async (): Promise<PageResult<FarmerProductItem>> => {
        const mockResult = getMockFarmerProducts(page, size, statusFilter);
        const result: PageResult<FarmerProductItem> = {
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
   * 商品上架/下架/放入仓库
   * PUT /api/farmer/product/status
   */
  async setProductStatus(productId: string, status: ProductStatus): Promise<boolean> {
    const body: SetStatusBody = { productId, status };
    const result: boolean = await BaseRepository.postWithFallback<boolean>(
      'farmer/product/status',
      body,
      async (): Promise<boolean> => true,
      AppConstants.SCENE_FARMER
    );
    return result;
  }

  /**
   * 删除商品
   * DELETE /api/farmer/product
   */
  async deleteProduct(productId: string): Promise<boolean> {
    const body: DeleteProductBody = { productId };
    const result: boolean = await BaseRepository.postWithFallback<boolean>(
      'farmer/product/delete',
      body,
      async (): Promise<boolean> => true,
      AppConstants.SCENE_FARMER
    );
    return result;
  }

  /**
   * 商品上架发布（spec 3.2.2 + spec 16.2：去审核，直接发布）
   * POST /api/farmer/product/publish
   * 商品状态直接变为 approved（无需管理员审核）
   */
  async publishProduct(farmerId: string, form: ProductPublishForm): Promise<string> {
    const body: PublishProductBody = { farmerId, form };
    const result: string = await BaseRepository.postWithFallback<string>(
      'farmer/product/publish',
      body,
      async (): Promise<string> => {
        // Mock：返回新生成的 productId
        return `p_${Date.now()}`;
      },
      AppConstants.SCENE_FARMER
    );
    return result;
  }

  /**
   * 商品编辑提交
   * PUT /api/farmer/product
   */
  async updateProduct(productId: string, form: ProductPublishForm): Promise<boolean> {
    const body: UpdateProductBody = { productId, form };
    const result: boolean = await BaseRepository.postWithFallback<boolean>(
      'farmer/product/update',
      body,
      async (): Promise<boolean> => true,
      AppConstants.SCENE_FARMER
    );
    return result;
  }
}

/** 商品上架请求体 */
interface PublishProductBody {
  farmerId: string;
  form: ProductPublishForm;
}

/** 商品编辑请求体 */
interface UpdateProductBody {
  productId: string;
  form: ProductPublishForm;
}

/** 商品管理域 Repository 单例 */
export const ProductManageRepository: ProductManageRepositoryImpl = new ProductManageRepositoryImpl();
