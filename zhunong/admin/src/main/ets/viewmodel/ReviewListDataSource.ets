/**
 * ReviewListDataSource - 管理后台内容审核列表数据源
 * 遵循 spec 3.3.3 / 10.8.3.3：类型筛选（全部/商品/直播/帖子/举报）+ 状态筛选（待审核/已通过/已驳回）+ 分页
 * spec 10.11.3：继承 BaseDataSource<T>，仅保留过滤字段 + fetchPage 单一职责
 * 取数走 ReviewRepository（spec 10.3：先 REST 后 Mock 兜底），接口 GET /api/admin/reviews
 *
 * spec 10.11.11（v2.2 新增）：4 态状态机扩展设计
 *  - fetchPage 内部 try-catch，失败时不抛异常，而是设置 loadFailed=true 并返回空数组
 *  - 通过 getLoadFailed() 暴露错误状态供页面 4 态判断（loading / empty / list / error）
 *  - 不修改 BaseDataSource 基类契约（保持 Step 2/3 既有决策）
 *
 * 注意：pendingCount 红点数（spec 10.8.3.3）由 ReviewRepository.getPendingCount() 独立加载，
 *      不在 DataSource 范围内（页面 aboutToAppear 中并行加载）
 */

import {
  ContentReview,
  ReviewListQuery,
  ReviewContentType,
  AdminReviewStatus
} from '../model/AdminModels';
import { ReviewRepository } from '../repository/ReviewRepository';
import { AppConstants, BaseDataSource, FetchPageResult, Logger } from 'common';

export class ReviewListDataSource extends BaseDataSource<ContentReview> {
  /** 日志场景名（spec 10.11.3：注入基类） */
  protected readonly scene: string = AppConstants.SCENE_ADMIN;
  /** 日志动作前缀（spec 10.11.3：注入基类） */
  protected readonly actionPrefix: string = 'review_list';

  /** 类型筛选（'all' = 全部） */
  private typeFilter: 'all' | ReviewContentType = 'all';
  /** 状态筛选（默认待审核） */
  private statusFilter: AdminReviewStatus = 'pending';
  /** 加载失败标志（4 态状态机：fetchPage 内部捕获异常后设置） */
  private loadFailed: boolean = false;

  constructor() {
    super();
    // spec 10.11.3：覆盖基类默认 pageSize 20 → 20（审核列表单列，每页 20 项，与原页面一致）
    this.pageSize = 20;
  }

  /** 设置类型筛选，refresh 后生效 */
  setType(type: 'all' | ReviewContentType): void {
    this.typeFilter = type;
  }

  /** 设置状态筛选，refresh 后生效 */
  setStatus(status: AdminReviewStatus): void {
    this.statusFilter = status;
  }

  /** 获取加载失败标志（4 态状态机：供页面判断 error 视图） */
  getLoadFailed(): boolean {
    return this.loadFailed;
  }

  /**
   * 单页取数（spec 10.11.3：基类 refresh / loadMore 调用）
   * @param page 页码（从 1 开始）
   * @param size 每页条数
   */
  protected async fetchPage(page: number, size: number): Promise<FetchPageResult<ContentReview>> {
    // 每次取数前重置错误状态
    this.loadFailed = false;
    try {
      const query: ReviewListQuery = {
        page,
        size,
        status: this.statusFilter
      };
      if (this.typeFilter !== 'all') {
        query.contentType = this.typeFilter;
      }
      const result = await ReviewRepository.getReviews(query);
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
