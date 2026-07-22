/**
 * CommunityDataSource - 社区帖子列表数据源
 * 遵循 spec 3.1.3.2：单列卡片流 + LazyForEach + IDataSource + 分页加载
 * spec 10.11.3：重构继承 BaseDataSource<T>，仅保留过滤字段 + fetchPage 单一职责
 * 取数走 CommunityRepository（spec 10.3：先 REST 后 Mock 兜底），接口 GET /api/community/posts
 */

import { PostListItem, PostListParam, PostSortBy } from '../model/CommunityModels';
import { CommunityRepository } from '../repository/CommunityRepository';
import { AppConstants, BaseDataSource, FetchPageResult } from 'common';

export class CommunityDataSource extends BaseDataSource<PostListItem> {
  /** 日志场景名（spec 10.11.3：注入基类） */
  protected readonly scene: string = AppConstants.SCENE_USER;
  /** 日志动作前缀（spec 10.11.3：注入基类） */
  protected readonly actionPrefix: string = 'community_list';

  /** 当前话题筛选 */
  private topicId?: string;
  /** 当前关键字 */
  private keyword?: string;
  /** 当前排序 */
  private sortBy: PostSortBy = 'latest';

  constructor() {
    super();
    // spec 10.11.3：覆盖基类默认 pageSize 20 → 10（社区卡片单列，每页 10 项）
    this.pageSize = 10;
  }

  /** 设置筛选条件（话题 / 关键字 / 排序），refresh 后生效 */
  setFilter(topicId?: string, keyword?: string, sortBy?: PostSortBy): void {
    if (topicId !== undefined) {
      this.topicId = topicId;
    }
    if (keyword !== undefined) {
      this.keyword = keyword;
    }
    if (sortBy !== undefined) {
      this.sortBy = sortBy;
    }
  }

  /**
   * 单页取数（spec 10.11.3：基类 refresh / loadMore 调用）
   * @param page 页码（从 1 开始）
   * @param size 每页条数
   */
  protected async fetchPage(page: number, size: number): Promise<FetchPageResult<PostListItem>> {
    const param: PostListParam = {
      topicId: this.topicId,
      keyword: this.keyword,
      sortBy: this.sortBy,
      page: page,
      size: size
    };
    const result = await CommunityRepository.getPostList(param);
    return { list: result.list, hasMore: result.hasMore };
  }
}
