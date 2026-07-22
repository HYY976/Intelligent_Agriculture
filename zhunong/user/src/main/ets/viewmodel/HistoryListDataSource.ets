/**
 * HistoryListDataSource - 浏览历史列表数据源
 * 遵循 spec 3.1.3.5：全量加载（本地态，hasMore=false）
 * spec 10.11.3：继承 BaseDataSource<T>，仅保留 fetchPage 单一职责
 * 取数走 ProfileMock（浏览历史为本地态，无需 Repository 兜底）
 */

import { HistoryItem } from '../model/ProfileModels';
import { MOCK_HISTORIES } from '../mock/ProfileMock';
import { AppConstants, BaseDataSource, FetchPageResult, Logger } from 'common';

export class HistoryListDataSource extends BaseDataSource<HistoryItem> {
  /** 日志场景名（spec 10.11.3：注入基类） */
  protected readonly scene: string = AppConstants.SCENE_USER;
  /** 日志动作前缀（spec 10.11.3：注入基类） */
  protected readonly actionPrefix: string = 'history_list';

  /** 加载失败标志（4 态状态机：fetchPage 内部捕获异常后设置） */
  private loadFailed: boolean = false;

  /** 获取加载失败标志（4 态状态机：供页面判断 error 视图） */
  getLoadFailed(): boolean {
    return this.loadFailed;
  }

  /**
   * 单页取数（spec 10.11.3：基类 refresh / loadMore 调用）
   * 浏览历史为本地全量数据，hasMore 恒为 false
   * @param page 页码（从 1 开始）
   * @param size 每页条数
   */
  protected async fetchPage(_page: number, _size: number): Promise<FetchPageResult<HistoryItem>> {
    this.loadFailed = false;
    try {
      const histories: HistoryItem[] = MOCK_HISTORIES.slice();
      return { list: histories, hasMore: false };
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
