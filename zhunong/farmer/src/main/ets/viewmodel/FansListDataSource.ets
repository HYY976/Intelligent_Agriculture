/**
 * FansListDataSource - 卖家端粉丝列表数据源
 * 遵循 spec 3.2.4.5：粉丝头像+昵称+关注时间，分页加载
 * spec 10.11.3：继承 BaseDataSource<T>，仅保留过滤字段 + fetchPage 单一职责
 * 取数走 FansRepository（spec 10.3：先 REST 后 Mock 兜底），接口 GET /api/farmer/fans
 */

import { FanInfo } from '../model/FarmerModels';
import { FansRepository } from '../repository/FansRepository';
import { MOCK_FARMER_ID } from '../mock/FarmerMock';
import { AppConstants, BaseDataSource, FetchPageResult, Logger } from 'common';

export class FansListDataSource extends BaseDataSource<FanInfo> {
  /** 日志场景名（spec 10.11.3：注入基类） */
  protected readonly scene: string = AppConstants.SCENE_FARMER;
  /** 日志动作前缀（spec 10.11.3：注入基类） */
  protected readonly actionPrefix: string = 'fans_list';
  /** 加载失败标志（4 态状态机：fetchPage 内部捕获异常后设置） */
  private loadFailed: boolean = false;

  constructor() {
    super();
    // spec 10.11.3：覆盖基类默认 pageSize 20 → 20（粉丝列表单列，每页 20 项，与原页面一致）
    this.pageSize = 20;
  }

  /** 4 态状态机：是否加载失败（spec 10.13：fetchPage try-catch 暴露错误态） */
  getLoadFailed(): boolean {
    return this.loadFailed;
  }

  /**
   * 单页取数（spec 10.11.3：基类 refresh / loadMore 调用）
   * @param page 页码（从 1 开始）
   * @param size 每页条数
   */
  protected async fetchPage(page: number, size: number): Promise<FetchPageResult<FanInfo>> {
    this.loadFailed = false;
    try {
      const result = await FansRepository.getFansList(MOCK_FARMER_ID, page, size);
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
