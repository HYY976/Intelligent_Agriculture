/**
 * CategoryListDataSource - 商品分类（一级分类）数据源
 * 遵循 spec 3.1.4.1：左侧一级分类 Tab 列表，全量加载（静态数据，hasMore=false）
 * spec 10.11.3：继承 BaseDataSource<T>，仅保留 fetchPage 单一职责
 * 取数走 ProductMock（分类树为静态数据，无需 Repository 兜底）
 */

import { Category } from '../model/ProductModels';
import { MOCK_CATEGORIES } from '../mock/ProductMock';
import { AppConstants, BaseDataSource, FetchPageResult, Logger } from 'common';

export class CategoryListDataSource extends BaseDataSource<Category> {
  /** 日志场景名（spec 10.11.3：注入基类） */
  protected readonly scene: string = AppConstants.SCENE_USER;
  /** 日志动作前缀（spec 10.11.3：注入基类） */
  protected readonly actionPrefix: string = 'category_list';

  /** 加载失败标志（4 态状态机：fetchPage 内部捕获异常后设置） */
  private loadFailed: boolean = false;

  /** 获取加载失败标志（4 态状态机：供页面判断 error 视图） */
  getLoadFailed(): boolean {
    return this.loadFailed;
  }

  /**
   * 单页取数（spec 10.11.3：基类 refresh / loadMore 调用）
   * 一级分类为静态数据，hasMore 恒为 false
   * @param page 页码（从 1 开始）
   * @param size 每页条数
   */
  protected async fetchPage(_page: number, _size: number): Promise<FetchPageResult<Category>> {
    this.loadFailed = false;
    try {
      const categories: Category[] = MOCK_CATEGORIES.slice();
      return { list: categories, hasMore: false };
    } catch (err) {
      this.loadFailed = true;
      Logger.error(this.scene, {
        action: `${this.actionPrefix}_fetch_fail`,
        page: _page,
        error: (err as Error).message
      });
      return { list: [], hasMore: false };
    }
  }
}
