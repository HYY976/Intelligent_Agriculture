/**
 * RevenueDetailDataSource - 卖家端营收明细列表数据源
 * 遵循 spec 3.2.3.3：时间范围筛选 + 状态筛选 + 分页 + 汇总金额计算
 * spec 10.11.3：继承 BaseDataSource<T>，仅保留过滤字段 + fetchPage 单一职责
 * 取数走 RevenueRepository（spec 10.3：先 REST 后 Mock 兜底），接口 GET /api/revenue/records
 *
 * 特殊设计：参考 user 端 CartDataSource.getGroups()，暴露 getRecords() 供页面计算 totalAmount 汇总
 */

import { RevenueRecord, RevenueRange, RevenueRecordStatus } from '../model/FarmerModels';
import { RevenueRepository } from '../repository/RevenueRepository';
import { MOCK_FARMER_ID } from '../mock/FarmerMock';
import { AppConstants, BaseDataSource, FetchPageResult, Logger } from 'common';

export class RevenueDetailDataSource extends BaseDataSource<RevenueRecord> {
  /** 日志场景名（spec 10.11.3：注入基类） */
  protected readonly scene: string = AppConstants.SCENE_FARMER;
  /** 日志动作前缀（spec 10.11.3：注入基类） */
  protected readonly actionPrefix: string = 'revenue_detail';

  /** 当前时间范围筛选 */
  private range: RevenueRange = 'today';
  /** 当前状态筛选（'all' = 全部） */
  private statusFilter: RevenueRecordStatus | 'all' = 'all';
  /** 加载失败标志（4 态状态机：fetchPage 内部捕获异常后设置） */
  private loadFailed: boolean = false;

  constructor() {
    super();
    // spec 10.11.3：覆盖基类默认 pageSize 20 → 20（营收明细单列，每页 20 项，与原页面一致）
    this.pageSize = 20;
  }

  /** 设置时间范围筛选，refresh 后生效 */
  setRange(range: RevenueRange): void {
    this.range = range;
  }

  /** 设置状态筛选，refresh 后生效 */
  setStatus(status: RevenueRecordStatus | 'all'): void {
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
  protected async fetchPage(page: number, size: number): Promise<FetchPageResult<RevenueRecord>> {
    this.loadFailed = false;
    try {
      const status: RevenueRecordStatus | undefined = this.statusFilter === 'all' ? undefined : this.statusFilter;
      const result = await RevenueRepository.getRevenueRecords(MOCK_FARMER_ID, this.range, status, page, size);
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

  /**
   * 获取当前已加载的记录（spec 3.2.3.3：列表头部汇总金额计算）
   * items 为 protected，子类可访问；与 user 端 CartDataSource.getGroups() 同模式
   */
  getRecords(): RevenueRecord[] {
    return this.items;
  }
}
