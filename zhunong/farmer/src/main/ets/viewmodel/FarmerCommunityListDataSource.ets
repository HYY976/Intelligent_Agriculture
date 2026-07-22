/**
 * FarmerCommunityListDataSource - 卖家端社区帖子列表数据源
 * 遵循 spec 3.2.4.2：与用户端社区互通，话题Tab + 最新/最热排序 + 分页
 * spec 10.11.3：继承 BaseDataSource<T>，仅保留过滤字段 + fetchPage 单一职责
 * 取数走 CommunityRepository（spec 10.3：先 REST 后 Mock 兜底），接口 GET /api/community/posts
 */

import { Post, PostSortBy } from '../model/FarmerCommunityModels';
import { CommunityRepository } from '../repository/CommunityRepository';
import { AppConstants, BaseDataSource, FetchPageResult, Logger } from 'common';

export class FarmerCommunityListDataSource extends BaseDataSource<Post> {
  /** 日志场景名（spec 10.11.3：注入基类） */
  protected readonly scene: string = AppConstants.SCENE_FARMER;
  /** 日志动作前缀（spec 10.11.3：注入基类） */
  protected readonly actionPrefix: string = 'farmer_community_list';

  /** 当前话题筛选（'t0' = 全部） */
  private topicId: string = 't0';
  /** 当前排序 */
  private sortBy: PostSortBy = 'latest';
  /** 加载失败标志（4 态状态机：fetchPage 内部捕获异常后设置） */
  private loadFailed: boolean = false;

  constructor() {
    super();
    // spec 10.11.3：覆盖基类默认 pageSize 20 → 10（社区卡片单列，每页 10 项）
    this.pageSize = 10;
  }

  /** 设置筛选条件（话题 / 排序），refresh 后生效 */
  setFilter(topicId?: string, sortBy?: PostSortBy): void {
    if (topicId !== undefined) {
      this.topicId = topicId;
    }
    if (sortBy !== undefined) {
      this.sortBy = sortBy;
    }
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
  protected async fetchPage(page: number, size: number): Promise<FetchPageResult<Post>> {
    this.loadFailed = false;
    try {
      const topicId: string | undefined = this.topicId === 't0' ? undefined : this.topicId;
      const result = await CommunityRepository.getPostList(page, size, topicId, this.sortBy);
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
