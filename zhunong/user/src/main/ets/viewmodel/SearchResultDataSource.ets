/**
 * SearchResultDataSource - 搜索结果（商品）数据源
 * 遵循 spec 3.1.1：双列瀑布流 + LazyForEach + IDataSource + 关键字分页
 * spec 10.11.3：继承 BaseDataSource<T>，仅保留过滤字段 + fetchPage 单一职责
 * 取数走 ProductMock（spec 10.3：商品列表已通过 ProductRepository 兜底，此处直接复用 Mock 分页）
 */

import { ProductListItem } from '../model/ProductModels';
import { getMockProductList } from '../mock/ProductMock';
import { AppConstants, BaseDataSource, FetchPageResult, Logger } from 'common';

export class SearchResultDataSource extends BaseDataSource<ProductListItem> {
  /** 日志场景名（spec 10.11.3：注入基类） */
  protected readonly scene: string = AppConstants.SCENE_USER;
  /** 日志动作前缀（spec 10.11.3：注入基类） */
  protected readonly actionPrefix: string = 'search_result';

  /** 当前搜索关键词 */
  private keyword: string = '';
  /** 加载失败标志（4 态状态机：fetchPage 内部捕获异常后设置） */
  private loadFailed: boolean = false;

  /** 设置搜索关键词，refresh 后生效 */
  setKeyword(keyword: string): void {
    this.keyword = keyword;
  }

  /** 获取加载失败标志（4 态状态机：供页面判断 error 视图） */
  getLoadFailed(): boolean {
    return this.loadFailed;
  }

  /**
   * 单页取数（spec 10.11.3：基类 refresh / loadMore 调用）
   * 复用 ProductMock 的分页能力（getMockProductList 已支持 page/size/keyword）
   * @param page 页码（从 1 开始）
   * @param size 每页条数
   */
  protected async fetchPage(page: number, size: number): Promise<FetchPageResult<ProductListItem>> {
    this.loadFailed = false;
    try {
      const result = getMockProductList(page, size, undefined, this.keyword, 'comprehensive');
      return { list: result.list, hasMore: result.hasMore };
    } catch (err) {
      this.loadFailed = true;
      Logger.error(this.scene, {
        action: `${this.actionPrefix}_fetch_fail`,
        page: page,
        error: (err as Error).message
      });
      return { list: [], hasMore: false };
    }
  }
}
