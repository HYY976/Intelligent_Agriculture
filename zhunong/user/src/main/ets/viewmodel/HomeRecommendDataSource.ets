/**
 * HomeRecommendDataSource - 首页推荐流数据源
 * 遵循 spec 3.1.3.1：双列瀑布流 + LazyForEach + IDataSource + 分页加载
 * spec 10.11.3：重构继承 BaseDataSource<T>，仅保留 fetchPage 单一职责
 * 取数走 HomeRepository（spec 10.3：先 REST 后 Mock 兜底），接口 GET /api/home/recommend
 */

import { ProductListItem } from '../model/ProductModels';
import { HomeRepository } from '../repository/HomeRepository';
import { AppConstants, BaseDataSource, FetchPageResult } from 'common';

export class HomeRecommendDataSource extends BaseDataSource<ProductListItem> {
  /** 日志场景名（spec 10.11.3：注入基类） */
  protected readonly scene: string = AppConstants.SCENE_USER;
  /** 日志动作前缀（spec 10.11.3：注入基类） */
  protected readonly actionPrefix: string = 'home_recommend';

  /**
   * 单页取数（spec 10.11.3：基类 refresh / loadMore 调用）
   * @param page 页码（从 1 开始）
   * @param size 每页条数
   */
  protected async fetchPage(page: number, size: number): Promise<FetchPageResult<ProductListItem>> {
    const result = await HomeRepository.getRecommendList(page, size);
    return { list: result.list, hasMore: result.hasMore };
  }
}
