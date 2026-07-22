/**
 * LiveDataSource - 直播列表数据源
 * 遵循 spec 3.1.4.2：仿抖音短视频直播架构 + LazyForEach + IDataSource + 分页加载
 * spec 10.11.3：重构继承 BaseDataSource<T>，仅保留过滤字段 + fetchPage 单一职责
 * 取数走 LiveRepository（spec 10.3：先 REST 后 Mock 兜底），接口 GET /api/live/list
 */

import { LiveListItem, LiveListParam, LiveCategory } from '../model/LiveModels';
import { LiveStatus, AppConstants, BaseDataSource, FetchPageResult } from 'common';
import { LiveRepository } from '../repository/LiveRepository';

export class LiveDataSource extends BaseDataSource<LiveListItem> {
  /** 日志场景名（spec 10.11.3：注入基类） */
  protected readonly scene: string = AppConstants.SCENE_USER;
  /** 日志动作前缀（spec 10.11.3：注入基类） */
  protected readonly actionPrefix: string = 'live_list';

  /** 当前状态筛选 */
  private statusFilter?: LiveStatus;
  /** 当前分类筛选 */
  private categoryFilter?: LiveCategory;
  /** 当前关键字 */
  private keyword?: string;

  constructor() {
    super();
    // spec 10.11.3：覆盖基类默认 pageSize 20 → 10（直播卡片单列，每页 10 项）
    this.pageSize = 10;
  }

  /** 设置筛选条件（状态 / 分类 / 关键字），refresh 后生效 */
  setFilter(status?: LiveStatus, category?: LiveCategory, keyword?: string): void {
    this.statusFilter = status;
    this.categoryFilter = category;
    this.keyword = keyword;
  }

  /**
   * 单页取数（spec 10.11.3：基类 refresh / loadMore 调用）
   * @param page 页码（从 1 开始）
   * @param size 每页条数
   */
  protected async fetchPage(page: number, size: number): Promise<FetchPageResult<LiveListItem>> {
    const param: LiveListParam = {
      status: this.statusFilter,
      category: this.categoryFilter,
      keyword: this.keyword,
      page: page,
      size: size
    };
    const result = await LiveRepository.getLiveList(param);
    return { list: result.list, hasMore: result.hasMore };
  }
}
