/**
 * CommunityRepository - 社区域 Repository（spec 10.3）
 * 封装社区帖子列表取数，统一走 BaseRepository「先 REST 后 Mock」兜底
 * 后端部署后无需改代码，Repository 自动切真实数据
 */

import { BaseRepository, AppConstants, PageResult, SharedPostStore, SharedPost } from 'common';
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
   * 合并 SharedPostStore 中农户发布的帖子到列表头部（实时同步）
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
    const result: PageResult<PostListItem> = await BaseRepository.fetchWithFallback<PageResult<PostListItem>>(
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
    // 合并共享帖子池到列表头部（仅第一页，按 topicId 过滤）
    if (param.page === 1) {
      const sharedPosts: SharedPost[] = await SharedPostStore.getAll();
      let filtered: SharedPost[] = sharedPosts;
      if (param.topicId !== undefined && param.topicId.length > 0 && param.topicId !== 'all') {
        filtered = sharedPosts.filter((p: SharedPost): boolean => p.topicId === param.topicId);
      }
      const sharedItems: PostListItem[] = filtered.map((p: SharedPost): PostListItem => {
        return {
          postId: p.postId,
          authorId: p.authorId,
          authorType: p.authorType,
          authorNickname: p.authorNickname,
          authorAvatar: p.authorAvatar,
          topicId: p.topicId,
          topicName: p.topicName,
          title: p.title,
          contentPreview: p.content.length > 60 ? p.content.substring(0, 60) + '...' : p.content,
          images: p.images,
          likeCount: p.likeCount,
          commentCount: p.commentCount,
          favoriteCount: p.favoriteCount,
          isLiked: false,
          isFavorited: false,
          createdAt: p.createdAt
        };
      });
      if (sharedItems.length > 0) {
        const mockIds: Set<string> = new Set<string>(result.list.map((it: PostListItem): string => it.postId));
        const dedup: PostListItem[] = sharedItems.filter(
          (it: PostListItem): boolean => !mockIds.has(it.postId)
        );
        // latest 排序：共享帖子置顶；hottest 排序：按 likeCount 合并后排序
        let merged: PostListItem[];
        if (param.sortBy === 'hottest') {
          merged = dedup.concat(result.list).sort((a: PostListItem, b: PostListItem): number => {
            return b.likeCount - a.likeCount;
          });
        } else {
          merged = dedup.concat(result.list);
        }
        const mergedResult: PageResult<PostListItem> = {
          list: merged,
          total: merged.length,
          page: result.page,
          size: result.size,
          hasMore: result.hasMore
        };
        return mergedResult;
      }
    }
    return result;
  }
}

/** 社区域 Repository 单例 */
export const CommunityRepository: CommunityRepositoryImpl = new CommunityRepositoryImpl();
