/**
 * CommunityRepository - 社区域 Repository（spec 10.3）
 * 封装社区帖子列表取数，统一走 BaseRepository「先 REST 后 Mock」兜底
 * 后端部署后无需改代码，Repository 自动切真实数据
 */

import { BaseRepository, AppConstants, PageResult } from 'common';
import { PostListItem, PostListParam } from '../model/CommunityModels';
import { getMockPostList } from '../mock/CommunityMock';

/** 社区帖子列表查询参数（显式 interface，无索引签名，规避 arkts-no-untyped-obj-literals） */
interface PostListQuery {
  sortBy: string;
  page: number;
  size: number;
  topicId?: string;
  keyword?: string;
}

class CommunityRepositoryImpl {
  /**
   * 社区帖子列表：GET /api/community/posts?topicId=&keyword=&sortBy=&page=&size=
   * 失败回退 Mock（getMockPostList）
   */
  async getPostList(param: PostListParam): Promise<PageResult<PostListItem>> {
    const params: PostListQuery = {
      sortBy: param.sortBy,
      page: param.page,
      size: param.size
    };
    if (param.topicId !== undefined && param.topicId.length > 0) {
      params.topicId = param.topicId;
    }
    if (param.keyword !== undefined && param.keyword.length > 0) {
      params.keyword = param.keyword;
    }
    return BaseRepository.fetchWithFallback<PageResult<PostListItem>>(
      'community/posts',
      params,
      async (): Promise<PageResult<PostListItem>> => {
        const mockResult = getMockPostList(param);
        const result: PageResult<PostListItem> = {
          list: mockResult.list,
          total: mockResult.list.length,
          page: param.page,
          size: param.size,
          hasMore: mockResult.hasMore
        };
        return result;
      },
      AppConstants.SCENE_USER
    );
  }
}

/** 社区域 Repository 单例 */
export const CommunityRepository: CommunityRepositoryImpl = new CommunityRepositoryImpl();
