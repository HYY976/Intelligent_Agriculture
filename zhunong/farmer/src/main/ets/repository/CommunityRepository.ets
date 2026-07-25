/**
 * CommunityRepository - 卖家端社区域 Repository（spec 3.2.4.2：与用户端社区互通）
 * 走 BaseRepository.fetchWithFallback：先 REST 后 Mock 兜底
 */

import { BaseRepository, AppConstants, PageResult } from 'common';
import { Post, Comment, Topic, PostSortBy } from '../model/FarmerCommunityModels';
import {
  getMockPostList,
  getMockPostById,
  getMockCommentsByPostId,
  getMockTopics,
  mockCreatePost
} from '../mock/FarmerCommunityMock';

/** 帖子列表查询参数 */
interface PostListQuery {
  topicId?: string;
  sortBy: PostSortBy;
  page: number;
  size: number;
}

/** 帖子详情查询参数 */
interface PostDetailQuery {
  postId: string;
}

/** 发帖请求体 */
interface CreatePostBody {
  authorId: string;
  authorType: 'farmer';
  topicId: string;
  title: string;
  content: string;
  images: string[];
}

/** 评论请求体 */
interface CreateCommentBody {
  postId: string;
  parentId: string | null;
  authorId: string;
  authorType: 'farmer';
  content: string;
}

class CommunityRepositoryImpl {
  /**
   * 帖子列表（spec 3.1.3.2 / 3.2.4.2：话题Tab + 最新/最热排序）
   * GET /api/community/posts?topicId=&sortBy=&page=&size=
   */
  async getPostList(
    page: number,
    size: number,
    topicId: string | undefined,
    sortBy: PostSortBy = 'latest'
  ): Promise<PageResult<Post>> {
    const params: PostListQuery = { sortBy, page, size };
    if (topicId && topicId.length > 0) {
      params.topicId = topicId;
    }
    return BaseRepository.fetchWithFallback<PageResult<Post>>(
      'community/posts',
      params,
      async (): Promise<PageResult<Post>> => {
        const mockResult = getMockPostList(page, size, topicId, sortBy);
        const result: PageResult<Post> = {
          list: mockResult.list,
          total: mockResult.total,
          page: page,
          size: size,
          hasMore: mockResult.hasMore
        };
        return result;
      },
      AppConstants.SCENE_FARMER
    );
  }

  /**
   * 帖子详情
   * GET /api/community/post?postId=
   */
  async getPostDetail(postId: string): Promise<Post | null> {
    const params: PostDetailQuery = { postId };
    return BaseRepository.fetchWithFallback<Post | null>(
      'community/post',
      params,
      async (): Promise<Post | null> => getMockPostById(postId),
      AppConstants.SCENE_FARMER
    );
  }

  /**
   * 帖子评论列表（无限嵌套，spec 9.9.2）
   * GET /api/community/comments?postId=
   */
  async getComments(postId: string): Promise<Comment[]> {
    const params: PostDetailQuery = { postId };
    return BaseRepository.fetchWithFallback<Comment[]>(
      'community/comments',
      params,
      async (): Promise<Comment[]> => getMockCommentsByPostId(postId),
      AppConstants.SCENE_FARMER
    );
  }

  /**
   * 话题列表（spec 9.16.3：5个预设话题）
   * GET /api/community/topics
   */
  async getTopics(): Promise<Topic[]> {
    return BaseRepository.fetchWithFallback<Topic[]>(
      'community/topics',
      undefined,
      async (): Promise<Topic[]> => getMockTopics(),
      AppConstants.SCENE_FARMER
    );
  }

  /**
   * 发帖（spec 3.2.4.2：卖家发帖昵称带"卖家"V标）
   * POST /api/community/post/create
   */
  async createPost(
    authorId: string,
    topicId: string,
    title: string,
    content: string,
    images: string[]
  ): Promise<string> {
    const body: CreatePostBody = {
      authorId,
      authorType: 'farmer',
      topicId,
      title,
      content,
      images
    };
    const result: string = await BaseRepository.postWithFallback<string>(
      'community/post/create',
      body,
      async (): Promise<string> => mockCreatePost(authorId, topicId, title, content, images),
      AppConstants.SCENE_FARMER
    );
    return result;
  }

  /**
   * 发表评论（spec 3.1.3.2：评论仅文字+表情，无限嵌套）
   * POST /api/community/comment/create
   */
  async createComment(
    postId: string,
    parentId: string | null,
    authorId: string,
    content: string
  ): Promise<string> {
    const body: CreateCommentBody = {
      postId,
      parentId,
      authorId,
      authorType: 'farmer',
      content
    };
    const result: string = await BaseRepository.postWithFallback<string>(
      'community/comment/create',
      body,
      async (): Promise<string> => {
        return `c_${Date.now()}`;
      },
      AppConstants.SCENE_FARMER
    );
    return result;
  }
}

/** 社区域 Repository 单例 */
export const CommunityRepository: CommunityRepositoryImpl = new CommunityRepositoryImpl();
