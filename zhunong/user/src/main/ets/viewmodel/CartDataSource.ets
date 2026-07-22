/**
 * CartDataSource - 购物车分组数据源
 * 遵循 spec 3.1.3.4：按卖家分组展示，全量加载（非分页，hasMore=false）
 * spec 10.11.3：继承 BaseDataSource<T>，仅保留 fetchPage 单一职责
 * 取数走 CartMock（购物车为本地态，无需 Repository 兜底）
 */

import { CartGroup } from '../model/CartModels';
import { getMockCartGroups } from '../mock/CartMock';
import { AppConstants, BaseDataSource, FetchPageResult, Logger } from 'common';

export class CartDataSource extends BaseDataSource<CartGroup> {
  /** 日志场景名（spec 10.11.3：注入基类） */
  protected readonly scene: string = AppConstants.SCENE_USER;
  /** 日志动作前缀（spec 10.11.3：注入基类） */
  protected readonly actionPrefix: string = 'cart_list';

  /** 加载失败标志（4 态状态机：fetchPage 内部捕获异常后设置） */
  private loadFailed: boolean = false;

  /** 获取加载失败标志（4 态状态机：供页面判断 error 视图） */
  getLoadFailed(): boolean {
    return this.loadFailed;
  }

  /**
   * 单页取数（spec 10.11.3：基类 refresh / loadMore 调用）
   * 购物车为本地全量数据，page 参数仅用于日志，hasMore 恒为 false
   * @param page 页码（从 1 开始，购物车忽略）
   * @param size 每页条数（购物车忽略）
   */
  protected async fetchPage(_page: number, _size: number): Promise<FetchPageResult<CartGroup>> {
    this.loadFailed = false;
    try {
      const groups: CartGroup[] = getMockCartGroups();
      return { list: groups, hasMore: false };
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

  /**
   * 获取当前全量分组数据（供页面计算汇总：全选状态/选中数/合计金额）
   * BaseDataSource.items 为 protected，子类可访问，对外提供只读视图
   */
  getGroups(): CartGroup[] {
    return this.items;
  }
}
