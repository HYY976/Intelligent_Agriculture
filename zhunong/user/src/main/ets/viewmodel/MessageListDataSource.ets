/**
 * MessageListDataSource - 消息会话列表数据源
 * 遵循 spec 3.1.3.3：按类型筛选 + 全量加载（Mock 端未分页，hasMore=false）
 * spec 10.11.3：继承 BaseDataSource<T>，仅保留过滤字段 + fetchPage 单一职责
 * 取数走 MessageMock（spec 10.3：Repository 未覆盖会话列表，直接走 Mock）
 */

import { ChatSession, SessionType } from '../model/MessageModels';
import { getMockSessions } from '../mock/MessageMock';
import { AppConstants, BaseDataSource, FetchPageResult, Logger } from 'common';

/** 筛选 Tab 类型（与页面 FilterTab 一致） */
export type MessageFilterTab = 'all' | SessionType;

export class MessageListDataSource extends BaseDataSource<ChatSession> {
  /** 日志场景名（spec 10.11.3：注入基类） */
  protected readonly scene: string = AppConstants.SCENE_USER;
  /** 日志动作前缀（spec 10.11.3：注入基类） */
  protected readonly actionPrefix: string = 'message_list';

  /** 当前筛选 Tab（'all' / 'private' / 'system'） */
  private currentFilter: MessageFilterTab = 'all';
  /** 加载失败标志（4 态状态机：fetchPage 内部捕获异常后设置） */
  private loadFailed: boolean = false;

  /** 设置筛选 Tab，refresh 后生效 */
  setFilter(filter: MessageFilterTab): void {
    this.currentFilter = filter;
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
  protected async fetchPage(_page: number, _size: number): Promise<FetchPageResult<ChatSession>> {
    this.loadFailed = false;
    try {
      const filterType: SessionType | undefined = this.currentFilter === 'all' ? undefined : this.currentFilter;
      const sessions: ChatSession[] = getMockSessions(filterType);
      return { list: sessions, hasMore: false };
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
