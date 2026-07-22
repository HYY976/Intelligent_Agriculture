/**
 * OrderListDataSource - 订单列表数据源
 * 遵循 spec 3.1.4.1：按状态筛选 + 全量加载（Mock 端未分页，hasMore=false）
 * spec 10.11.3：继承 BaseDataSource<T>，仅保留过滤字段 + fetchPage 单一职责
 * 取数走 OrderMock（spec 10.3：Repository 未覆盖订单列表，直接走 Mock）
 */

import { OrderListItem } from '../model/OrderModels';
import { getMockOrderList } from '../mock/OrderMock';
import { AppConstants, BaseDataSource, FetchPageResult, Logger } from 'common';

export class OrderListDataSource extends BaseDataSource<OrderListItem> {
  /** 日志场景名（spec 10.11.3：注入基类） */
  protected readonly scene: string = AppConstants.SCENE_USER;
  /** 日志动作前缀（spec 10.11.3：注入基类） */
  protected readonly actionPrefix: string = 'order_list';

  /** 当前状态筛选（'all' / 'pending_payment' / 'pending_shipment' / 'pending_receipt' / 'pending_review'） */
  private currentStatus: string = 'all';
  /** 加载失败标志（4 态状态机：fetchPage 内部捕获异常后设置） */
  private loadFailed: boolean = false;

  /** 设置状态筛选，refresh 后生效 */
  setStatus(status: string): void {
    this.currentStatus = status;
  }

  /** 获取加载失败标志（4 态状态机：供页面判断 error 视图） */
  getLoadFailed(): boolean {
    return this.loadFailed;
  }

  /**
   * 单页取数（spec 10.11.3：基类 refresh / loadMore 调用）
   * Mock 端为全量返回，hasMore 恒为 false
   * @param page 页码（从 1 开始）
   * @param size 每页条数
   */
  protected async fetchPage(_page: number, _size: number): Promise<FetchPageResult<OrderListItem>> {
    this.loadFailed = false;
    try {
      const orders: OrderListItem[] = getMockOrderList(this.currentStatus);
      return { list: orders, hasMore: false };
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
