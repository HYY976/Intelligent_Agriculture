/**
 * FarmerCommunityMock - 卖家端社区域 Mock 数据（spec 4.1.5）
 * 与用户端社区数据互通（共用同一套社区数据）
 */

import { Post, Comment, PostSortBy } from '../model/FarmerCommunityModels';
import { PRESET_TOPICS } from '../model/FarmerCommunityModels';
import { PaginatedResult } from '../model/FarmerModels';

/** 社区帖子 Mock（卖家发帖带"卖家"V标） */
export const MOCK_POSTS: Post[] = [
  {
    postId: 'p001', authorId: 'f001', authorType: 'farmer', topicId: 't1',
    title: '分享：高山有机青菜的种植心得',
    content: '我们在云南昆明的高山农场种植有机青菜已5年，海拔1800米，昼夜温差大，青菜口感特别清甜。\n关键要点：\n1. 土壤：选用富含腐殖质的山地红壤，pH值6.0-6.5\n2. 灌溉：山泉水滴灌，避免叶面长期湿润\n3. 施肥：自制堆肥+草木灰，绝不使用化肥\n4. 病虫害：物理诱杀+轮作，无需农药\n欢迎交流！',
    images: ['post_farm_1', 'post_vegetable_1', 'post_soil_1'],
    likeCount: 286, commentCount: 32, favoriteCount: 58, shareCount: 12,
    status: 'normal', createdAt: 1736800000000,
    authorNickname: '青禾农庄', authorAvatar: 'avatar_farmer_1', isSeller: true
  },
  {
    postId: 'p002', authorId: 'u001', authorType: 'user', topicId: 't2',
    title: '销路讨论：今年的柑橘怎么卖才好？',
    content: '家里种了20亩柑橘，今年产量不错，但是销路一直打不开。大家有什么好建议吗？',
    images: ['post_orange_1'],
    likeCount: 158, commentCount: 56, favoriteCount: 28, shareCount: 8,
    status: 'normal', createdAt: 1736810000000,
    authorNickname: '小马哥', authorAvatar: 'avatar_user_1', isSeller: false
  },
  {
    postId: 'p003', authorId: 'f002', authorType: 'farmer', topicId: 't3',
    title: '乡村生活：清晨的山野好物农场',
    content: '清晨5点半起床喂鸡，6点开始采收土鸡蛋。山里的空气真的太好了，推荐大家来体验乡村生活！',
    images: ['post_farm_2', 'post_chicken_1', 'post_morning_1'],
    likeCount: 423, commentCount: 28, favoriteCount: 86, shareCount: 35,
    status: 'normal', createdAt: 1736820000000,
    authorNickname: '山野好物', authorAvatar: 'avatar_farmer_2', isSeller: true
  },
  {
    postId: 'p004', authorId: 'u002', authorType: 'user', topicId: 't4',
    title: '互助问答：新手种番茄总生虫怎么办？',
    content: '第一次种番茄，叶子背面老是有小虫，请问有什么不用农药的方法吗？',
    images: ['post_tomato_1'],
    likeCount: 86, commentCount: 42, favoriteCount: 18, shareCount: 5,
    status: 'normal', createdAt: 1736830000000,
    authorNickname: '阿芳', authorAvatar: 'avatar_user_2', isSeller: false
  },
  {
    postId: 'p005', authorId: 'f003', authorType: 'farmer', topicId: 't1',
    title: '种植技术：明前茶的采摘与炒制',
    content: '明前茶的嫩芽采摘要求极高，必须清晨露水未干时采摘。炒制工艺也很讲究，需要杀青、揉捻、烘干三道工序。\n我们坚持传统手工炒制，茶香更浓郁。',
    images: ['post_tea_1', 'post_pick_1', 'post_roast_1'],
    likeCount: 312, commentCount: 38, favoriteCount: 72, shareCount: 22,
    status: 'normal', createdAt: 1736840000000,
    authorNickname: '田园牧歌', authorAvatar: 'avatar_farmer_3', isSeller: true
  },
  {
    postId: 'p006', authorId: 'u003', authorType: 'user', topicId: 't3',
    title: '乡村生活：周末带孩子去果园采摘',
    content: '周末带孩子去乡下采摘苹果，孩子特别开心！推荐大家多带孩子接触自然。',
    images: ['post_orchard_1', 'post_kids_1'],
    likeCount: 198, commentCount: 18, favoriteCount: 42, shareCount: 15,
    status: 'normal', createdAt: 1736850000000,
    authorNickname: '阿强', authorAvatar: 'avatar_user_3', isSeller: false
  }
];

/** 帖子评论 Mock（含无限嵌套） */
export const MOCK_COMMENTS: Comment[] = [
  {
    commentId: 'c001', postId: 'p001', parentId: null,
    authorId: 'u001', authorType: 'user',
    content: '学习了！请问堆肥配比是？',
    likeCount: 12, createdAt: 1736801000000,
    authorNickname: '小马哥', authorAvatar: 'avatar_user_1', isSeller: false,
    replies: [
      {
        commentId: 'c002', postId: 'p001', parentId: 'c001',
        authorId: 'f001', authorType: 'farmer',
        content: '70%落叶+20%鸡粪+10%草木灰，发酵3个月即可',
        likeCount: 8, createdAt: 1736802000000,
        authorNickname: '青禾农庄', authorAvatar: 'avatar_farmer_1', isSeller: true
      }
    ]
  },
  {
    commentId: 'c003', postId: 'p001', parentId: null,
    authorId: 'u002', authorType: 'user',
    content: '海拔1800米对青菜有什么影响呢',
    likeCount: 6, createdAt: 1736803000000,
    authorNickname: '阿芳', authorAvatar: 'avatar_user_2', isSeller: false
  }
];

/**
 * 帖子列表分页 Mock
 */
export function getMockPostList(
  page: number,
  size: number,
  topicId?: string,
  sortBy: PostSortBy = 'latest'
): PaginatedResult<Post> {
  let filtered: Post[] = MOCK_POSTS.slice();
  if (topicId && topicId !== 't0' && topicId.length > 0) {
    filtered = filtered.filter((p: Post): boolean => p.topicId === topicId);
  }
  if (sortBy === 'hot') {
    filtered.sort((a: Post, b: Post): number => (b.likeCount + b.commentCount * 2 + b.shareCount * 3) - (a.likeCount + a.commentCount * 2 + a.shareCount * 3));
  } else {
    filtered.sort((a: Post, b: Post): number => b.createdAt - a.createdAt);
  }
  const total: number = filtered.length;
  const start: number = (page - 1) * size;
  const list: Post[] = filtered.slice(start, start + size);
  const result: PaginatedResult<Post> = { list: list, total: total, hasMore: start + size < total };
  return result;
}

/**
 * 根据 postId 查询帖子详情
 */
export function getMockPostById(postId: string): Post | null {
  const found: Post | undefined = MOCK_POSTS.find((p: Post): boolean => p.postId === postId);
  return found ?? null;
}

/**
 * 根据 postId 查询评论列表（无限嵌套）
 */
export function getMockCommentsByPostId(postId: string): Comment[] {
  return MOCK_COMMENTS.filter((c: Comment): boolean => c.postId === postId);
}

/**
 * Mock 创建帖子（将新帖子插入列表，使其发布后可立即在列表中查看）
 */
export function mockCreatePost(
  authorId: string,
  topicId: string,
  title: string,
  content: string,
  images: string[]
): string {
  const now: number = Date.now();
  const postId: string = `p_${now}`;
  const post: Post = {
    postId,
    authorId,
    authorType: 'farmer',
    topicId,
    title,
    content,
    images,
    likeCount: 0,
    commentCount: 0,
    favoriteCount: 0,
    shareCount: 0,
    status: 'normal',
    createdAt: now,
    authorNickname: '青禾农庄',
    authorAvatar: 'avatar_farmer_1',
    isSeller: true
  };
  MOCK_POSTS.unshift(post);
  return postId;
}

/**
 * 获取预设话题列表
 */
export function getMockTopics() {
  return PRESET_TOPICS;
}
