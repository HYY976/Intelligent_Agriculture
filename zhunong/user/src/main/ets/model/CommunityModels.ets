/**
 * CommunityModels - 用户端社区域数据模型
 * 遵循 spec 4.1.5 社区帖子实体定义、3.1.3.2 社区Tab规范
 * 含话题/帖子/评论（无限嵌套）/互动
 */

import { PostStatus } from 'common';

/** 话题实体（spec 4.1.5 Topic） */
export interface Topic {
  topicId: string;
  /** 话题名 */
  name: string;
  /** 排序值 */
  sortOrder: number;
  /** 是否预设 */
  isPreset: boolean;
}

/** 帖子作者类型 */
export type PostAuthorType = 'user' | 'farmer';

/** 帖子列表项（精简字段，列表渲染用） */
export interface PostListItem {
  postId: string;
  /** 作者 ID */
  authorId: string;
  /** 作者类型 */
  authorType: PostAuthorType;
  /** 作者昵称 */
  authorNickname: string;
  /** 作者头像 key */
  authorAvatar: string;
  /** 话题 ID */
  topicId: string;
  /** 话题名（冗余字段，避免列表再查话题表） */
  topicName: string;
  /** 标题 */
  title: string;
  /** 内容预览（2行，列表展示用） */
  contentPreview: string;
  /** 图片 key 数组（最多9张，列表展示前3张缩略） */
  images: string[];
  /** 点赞数 */
  likeCount: number;
  /** 评论数 */
  commentCount: number;
  /** 收藏数 */
  favoriteCount: number;
  /** 是否已点赞（当前用户） */
  isLiked: boolean;
  /** 是否已收藏（当前用户） */
  isFavorited: boolean;
  /** 发布时间戳 */
  createdAt: number;
}

/** 帖子详情（spec 4.1.5 Post 完整字段） */
export interface PostDetail extends PostListItem {
  /** 正文完整内容（最多5000字） */
  content: string;
  /** 分享数 */
  shareCount: number;
  /** 帖子状态 */
  status: PostStatus;
}

/** 评论（spec 4.1.5 Comment，无限嵌套） */
export interface Comment {
  commentId: string;
  postId: string;
  /** 父评论 ID（null 为一级评论） */
  parentId: string | null;
  /** 被回复人昵称（楼中楼回复时展示） */
  replyToNickname?: string;
  /** 作者 ID */
  authorId: string;
  /** 作者类型 */
  authorType: PostAuthorType;
  /** 作者昵称 */
  authorNickname: string;
  /** 作者头像 key */
  authorAvatar: string;
  /** 评论内容（仅文字+表情，不支持图片） */
  content: string;
  /** 点赞数 */
  likeCount: number;
  /** 是否已点赞（当前用户） */
  isLiked: boolean;
  /** 发布时间戳 */
  createdAt: number;
  /** 回复列表（无限嵌套） */
  replies: Comment[];
}

/** 帖子列表排序方式 */
export type PostSortBy = 'latest' | 'hottest';

/** 帖子列表查询参数 */
export interface PostListParam {
  /** 话题 ID（undefined=全部） */
  topicId?: string;
  /** 关键字 */
  keyword?: string;
  sortBy: PostSortBy;
  page: number;
  size: number;
}

/** 帖子列表分页结果 */
export interface PostListResult {
  list: PostListItem[];
  hasMore: boolean;
}

/** 举报原因预设项 */
export interface ReportReason {
  reasonId: string;
  /** 原因文案 */
  label: string;
}

/** 预设举报原因（spec 3.1.3.2 举报） */
export const REPORT_REASONS: ReportReason[] = [
  { reasonId: 'r001', label: '涉嫌违规内容' },
  { reasonId: 'r002', label: '广告营销' },
  { reasonId: 'r003', label: '不实信息' },
  { reasonId: 'r004', label: '侵犯权益' },
  { reasonId: 'r005', label: '人身攻击' },
  { reasonId: 'r006', label: '其他（自定义描述）' }
];
