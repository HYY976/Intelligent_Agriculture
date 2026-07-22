/**
 * FarmerCommunityModels - 卖家端社区域数据模型（spec 4.1.5）
 * 与用户端社区模型结构对齐，便于业务互通
 */

/** 帖子作者类型 */
export type PostAuthorType = 'user' | 'farmer';

/** 帖子状态（spec 4.1.5 PostStatus） */
export type PostStatus = 'normal' | 'reviewing' | 'rejected' | 'deleted';

/** 帖子实体（spec 4.1.5 Post） */
export interface Post {
  postId: string;
  /** 作者ID（用户或卖家） */
  authorId: string;
  authorType: PostAuthorType;
  /** 话题ID */
  topicId: string;
  title: string;
  /** 正文（最多5000字） */
  content: string;
  /** 图片 URL 数组（最多9张） */
  images: string[];
  likeCount: number;
  commentCount: number;
  favoriteCount: number;
  shareCount: number;
  status: PostStatus;
  createdAt: number;
  /** 作者昵称（列表展示用） */
  authorNickname?: string;
  /** 作者头像 key */
  authorAvatar?: string;
  /** 卖家标识（true 时昵称带"卖家"V标） */
  isSeller?: boolean;
}

/** 评论实体（spec 4.1.5 Comment，无限嵌套） */
export interface Comment {
  commentId: string;
  postId: string;
  /** 父评论ID（null 为一级评论） */
  parentId: string | null;
  authorId: string;
  authorType: PostAuthorType;
  /** 评论内容（仅文字+表情） */
  content: string;
  likeCount: number;
  createdAt: number;
  /** 回复列表（无限嵌套） */
  replies?: Comment[];
  /** 作者昵称 */
  authorNickname?: string;
  /** 作者头像 */
  authorAvatar?: string;
  /** 卖家标识 */
  isSeller?: boolean;
}

/** 话题实体（spec 4.1.5 Topic） */
export interface Topic {
  topicId: string;
  name: string;
  sortOrder: number;
  /** 是否预设 */
  isPreset: boolean;
}

/** 帖子列表排序方式 */
export type PostSortBy = 'latest' | 'hot';

/** 预设话题（spec 9.16.3：5个预设话题，后台可扩展） */
export const PRESET_TOPICS: Topic[] = [
  { topicId: 't0', name: '全部', sortOrder: 0, isPreset: true },
  { topicId: 't1', name: '种植技术', sortOrder: 1, isPreset: true },
  { topicId: 't2', name: '销路讨论', sortOrder: 2, isPreset: true },
  { topicId: 't3', name: '乡村生活', sortOrder: 3, isPreset: true },
  { topicId: 't4', name: '互助问答', sortOrder: 4, isPreset: true }
];

/** 帖子列表查询参数 */
export interface PostListParam {
  topicId?: string;
  sortBy: PostSortBy;
  page: number;
  size: number;
}
