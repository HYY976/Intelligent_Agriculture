/**
 * LiveManageDataSource - 卖家端直播管理列表数据源
 * 遵循 spec 3.2.4.5：历史直播列表 + 状态筛选（全部/直播中/预告/已结束）+ 分页
 * spec 10.11.3：继承 BaseDataSource<T>，仅保留过滤字段 + fetchPage 单一职责
 * 取数走 LiveManageRepository（spec 10.3：先 REST 后 Mock 兜底），接口 GET /api/farmer/lives
 */

import { LiveManageItem } from '../model/FarmerModels';
import { LiveManageRepository } from '../repository/LiveManageRepository';
import { MOCK_FARMER_ID } from '../mock/FarmerMock';
import { AppConstants, BaseDataSource, FetchPageResult, Logger } from 'common';

export class LiveManageDataSource extends BaseDataSource<LiveManageItem> {
  /** 日志场景名（spec 10.11.3：注入基类） */
  protected readonly scene: string = AppConstants.SCENE_FARMER;
  /** 日志动作前缀（spec 10.11.3：注入基类） */
  protected readonly actionPrefix: string = 'live_manage';

  /** 当前状态筛选（'all' = 全部） */
  private statusFilter: string = 'all';
  /** 加载失败标志（4 态状态机：fetchPage 内部捕获异常后设置） */
  private loadFailed: boolean = false;

  constructor() {
    super();
    // spec 10.11.3：覆盖基类默认 pageSize 20 → 20（直播管理单列，每页 20 项，与原页面一致）
    this.pageSize = 20;
  }

  /** 设置状态筛选，refresh 后生效 */
  setStatus(status: string): void {
    this.statusFilter = status;
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
  protected async fetchPage(page: number, size: number): Promise<FetchPageResult<LiveManageItem>> {
    this.loadFailed = false;
    try {
      const status: string | undefined = this.statusFilter === 'all' ? undefined : this.statusFilter;
      const result = await LiveManageRepository.getMyLives(MOCK_FARMER_ID, page, size, status);
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
