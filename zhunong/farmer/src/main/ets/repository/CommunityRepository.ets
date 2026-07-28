/**
 * CommunityRepository - 卖家端社区域 Repository（spec 3.2.4.2：与用户端社区互通）
 * 走 BaseRepository.fetchWithFallback：先 REST 后 Mock 兜底
 */

import { BaseRepository, AppConstants, PageResult, SharedPostStore } from 'common';
import { Post, Comment, Topic, PostSortBy, PRESET_TOPICS } from '../model/FarmerCommunityModels';
import {
  getMockPostList,
  getMockPostById,
  getMockCommentsByPostId,
  getMockTopics,
  mockCreatePost,
  mockCreateComment,
  mockDeletePost
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

/** 发帖请求体（spec 16.4：携带 authorNickname/authorAvatar 同步注册身份） */
interface CreatePostBody {
  authorId: string;
  authorType: 'farmer';
  topicId: string;
  title: string;
  content: string;
  images: string[];
  authorNickname: string;
  authorAvatar: string;
}

/** 评论请求体（spec 16.4：携带 authorNickname/authorAvatar 同步注册身份） */
interface CreateCommentBody {
  postId: string;
  parentId: string | null;
  authorId: string;
  authorType: 'farmer';
  content: string;
  authorNickname: string;
  authorAvatar: string;
}

/** 删除帖子请求体 */
interface DeletePostBody {
  postId: string;
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
    try {
      // 先尝试后端 REST 接口
      const resp = await BaseRepository.fetchWithFallback<PageResult<Post>>(
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
      // 后端返回空列表时回退 Mock（确保有演示数据）
      let finalList: Post[] = resp.list;
      let finalTotal: number = resp.total;
      if (resp.list.length === 0) {
        const mockResult = getMockPostList(page, size, topicId, sortBy);
        finalList = mockResult.list;
        finalTotal = mockResult.total;
      }
      // spec 16.5：移除 getLocallyCreatedPosts 合并逻辑（getMockPostList 已包含 MOCK_POSTS 全部，
      // 含 mockCreatePost 新增的 p_ 帖子，再合并会重复）
      const finalResult: PageResult<Post> = {
        list: finalList,
        total: finalTotal,
        page: resp.page,
        size: resp.size,
        hasMore: resp.hasMore
      };
      return finalResult;
    } catch (err) {
      // 异常时完全回退到 Mock
      const mockResult = getMockPostList(page, size, topicId, sortBy);
      return {
        list: mockResult.list,
        total: mockResult.total,
        page: page,
        size: size,
        hasMore: mockResult.hasMore
      };
    }
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
   * 发帖（spec 3.2.4.2 + spec 16.4：卖家发帖昵称带"卖家"V标，使用注册身份信息）
   * POST /api/community/post/create
   */
  async createPost(
    authorId: string,
    topicId: string,
    title: string,
    content: string,
    images: string[],
    authorNickname: string,
    authorAvatar: string
  ): Promise<string> {
    const body: CreatePostBody = {
      authorId,
      authorType: 'farmer',
      topicId,
      title,
      content,
      images,
      authorNickname,
      authorAvatar
    };
    const result: string = await BaseRepository.postWithFallback<string>(
      'community/post/create',
      body,
      async (): Promise<string> => mockCreatePost(authorId, topicId, title, content, images, authorNickname, authorAvatar),
      AppConstants.SCENE_FARMER
    );
    // 同步到共享帖子池，用户端可实时看到农户发布的帖子
    const topic: Topic | undefined = PRESET_TOPICS.find((t: Topic): boolean => t.topicId === topicId);
    const topicName: string = topic ? topic.name : '种植技术';
    SharedPostStore.publish({
      postId: result,
      authorId: authorId,
      authorType: 'farmer',
      authorNickname: authorNickname,
      authorAvatar: authorAvatar,
      topicId: topicId,
      topicName: topicName,
      title: title,
      content: content,
      images: images,
      likeCount: 0,
      commentCount: 0,
      favoriteCount: 0,
      isSeller: true,
      createdAt: Date.now()
    });
    return result;
  }

  /**
   * 发表评论（spec 3.1.3.2 + spec 16.4：评论仅文字+表情，无限嵌套，使用注册身份）
   * POST /api/community/comment/create
   */
  async createComment(
    postId: string,
    parentId: string | null,
    authorId: string,
    content: string,
    authorNickname: string,
    authorAvatar: string
  ): Promise<string> {
    const body: CreateCommentBody = {
      postId,
      parentId,
      authorId,
      authorType: 'farmer',
      content,
      authorNickname,
      authorAvatar
    };
    const result: string = await BaseRepository.postWithFallback<string>(
      'community/comment/create',
      body,
      async (): Promise<string> => mockCreateComment(postId, parentId, authorId, content, authorNickname, authorAvatar),
      AppConstants.SCENE_FARMER
    );
    return result;
  }

  /**
   * 删除帖子（spec 3.2.4.2：卖家可删除自己的帖子）
   * POST /api/community/post/delete
   */
  async deletePost(postId: string): Promise<boolean> {
    const body: DeletePostBody = { postId };
    const result: boolean = await BaseRepository.postWithFallback<boolean>(
      'community/post/delete',
      body,
      async (): Promise<boolean> => mockDeletePost(postId),
      AppConstants.SCENE_FARMER
    );
    // 同步删除共享帖子池中的帖子
    SharedPostStore.remove(postId);
    return result;
  }
}

/** 社区域 Repository 单例 */
export const CommunityRepository: CommunityRepositoryImpl = new CommunityRepositoryImpl();
