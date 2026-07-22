/**
 * ProductListDataSource - 商品列表数据源
 * 遵循 spec 3.1.4.1：商品列表页支持分类过滤 + 排序 + 分页
 * spec 10.11.3：重构继承 BaseDataSource<T>，仅保留过滤字段 + fetchPage 单一职责
 * 取数走 ProductRepository（spec 10.3：先 REST 后 Mock 兜底），接口 GET /api/product/list
 */

import { ProductListItem, ProductSortBy } from '../model/ProductModels';
import { ProductRepository } from '../repository/ProductRepository';
import { AppConstants, BaseDataSource, FetchPageResult } from 'common';

export class ProductListDataSource extends BaseDataSource<ProductListItem> {
  /** 日志场景名（spec 10.11.3：注入基类） */
  protected readonly scene: string = AppConstants.SCENE_USER;
  /** 日志动作前缀（spec 10.11.3：注入基类） */
  protected readonly actionPrefix: string = 'product_list';

  /** 当前分类 ID */
  private categoryId: string = '';
  /** 当前关键词 */
  private keyword: string = '';
  /** 当前排序 */
  private sortBy: ProductSortBy = 'comprehensive';

  /** 设置筛选条件（分类 / 关键字），refresh 后生效 */
  setFilter(categoryId: string, keyword: string): void {
    this.categoryId = categoryId;
    this.keyword = keyword;
  }

  /** 设置排序方式 */
  setSortBy(sortBy: ProductSortBy): void {
    this.sortBy = sortBy;
  }

  /**
   * 单页取数（spec 10.11.3：基类 refresh / loadMore 调用）
   * @param page 页码（从 1 开始）
   * @param size 每页条数
   */
  protected async fetchPage(page: number, size: number): Promise<FetchPageResult<ProductListItem>> {
    const result = await ProductRepository.getProductList(
      page, size,
      this.categoryId.length > 0 ? this.categoryId : undefined,
      this.keyword.length > 0 ? this.keyword : undefined,
      this.sortBy
    );
    return { list: result.list, hasMore: result.hasMore };
  }
}
