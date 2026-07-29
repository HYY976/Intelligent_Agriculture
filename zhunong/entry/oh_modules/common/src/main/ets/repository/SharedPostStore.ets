/**
 * SharedPostStore - 共享社区帖子池（双端同步用）
 *
 * 用途：
 *  - 农户端发帖时调用 publish() 将帖子写入共享池
 *  - 用户端读取帖子列表时调用 getAll() 合并到列表头部
 *  - 字段对齐 user 端 PostListItem，确保双端数据结构一致
 *
 * 注意：
 *  - 通过 PreferencesUtil 持久化（key=shared_posts）实现跨 HAP 数据同步
 *  - 退出登录时调用 clear() 清空，避免账号切换数据残留
 */

import { PreferencesUtil } from '../utils/PreferencesUtil';
import { Logger } from '../utils/Logger';
import { AppConstants } from '../constants/AppConstants';

/** 帖子作者类型 */
export type SharedPostAuthorType = 'user' | 'farmer';

/** 共享帖子（双端同步用，字段对齐 user 端 PostListItem） */
export interface SharedPost {
  postId: string;
  authorId: string;
  authorType: SharedPostAuthorType;
  authorNickname: string;
  authorAvatar: string;
  topicId: string;
  /** 话题名（冗余字段，列表展示用） */
  topicName: string;
  title: string;
  /** 正文（最多5000字） */
  content: string;
  /** 图片 key 数组（最多9张） */
  images: string[];
  likeCount: number;
  commentCount: number;
  favoriteCount: number;
  /** 卖家标识（true 时昵称带"卖家"V标） */
  isSeller: boolean;
  createdAt: number;
}

/** Preferences 持久化的容器结构 */
interface SharedPostsContainer {
  items: SharedPost[];
}

class SharedPostStoreImpl {
  /** 内存缓存（启动后从 Preferences 加载） */
  private posts: SharedPost[] = [];
  /** 是否已从 Preferences 加载过 */
  private loaded: boolean = false;
  /** Preferences key */
  private static readonly PREF_KEY: string = 'shared_posts';

  /** 从 Preferences 加载到内存（懒加载，仅一次） */
  private async ensureLoaded(): Promise<void> {
    if (this.loaded) {
      return;
    }
    try {
      const json: string = await PreferencesUtil.getString(SharedPostStoreImpl.PREF_KEY, '');
      if (json.length > 0) {
        const container: SharedPostsContainer = JSON.parse(json) as SharedPostsContainer;
        if (container && Array.isArray(container.items)) {
          this.posts = container.items;
        }
      }
      this.loaded = true;
      Logger.info(AppConstants.SCENE_COMMON, {
        action: 'shared_posts_loaded',
        count: this.posts.length
      });
    } catch (err) {
      Logger.error(AppConstants.SCENE_COMMON, {
        action: 'shared_posts_load_fail',
        error: (err as Error).message
      });
      this.posts = [];
      this.loaded = true;
    }
  }

  /** 持久化到 Preferences */
  private async persist(): Promise<void> {
    try {
      const container: SharedPostsContainer = { items: this.posts };
      await PreferencesUtil.putString(
        SharedPostStoreImpl.PREF_KEY,
        JSON.stringify(container)
      );
    } catch (err) {
      Logger.error(AppConstants.SCENE_COMMON, {
        action: 'shared_posts_persist_fail',
        error: (err as Error).message
      });
    }
  }

  /**
   * 发布帖子到共享池（农户端调用）
   * - 同 postId 已存在则更新；否则新增
   */
  async publish(post: SharedPost): Promise<void> {
    await this.ensureLoaded();
    this.posts = this.posts.filter((p: SharedPost): boolean => p.postId !== post.postId);
    this.posts.unshift(post);
    await this.persist();
    Logger.info(AppConstants.SCENE_COMMON, {
      action: 'shared_post_published',
      postId: post.postId,
      total: this.posts.length
    });
  }

  /**
   * 获取全部共享帖子（用户端读取并合并到列表头部）
   * 返回副本，避免外部直接修改内部状态
   */
  async getAll(): Promise<SharedPost[]> {
    await this.ensureLoaded();
    return this.posts.slice();
  }

  /** 根据 postId 获取共享帖子 */
  async getById(postId: string): Promise<SharedPost | null> {
    await this.ensureLoaded();
    const found: SharedPost | undefined = this.posts.find(
      (p: SharedPost): boolean => p.postId === postId
    );
    return found ?? null;
  }

  /** 删除指定帖子 */
  async remove(postId: string): Promise<void> {
    await this.ensureLoaded();
    this.posts = this.posts.filter(
      (p: SharedPost): boolean => p.postId !== postId
    );
    await this.persist();
  }

  /**
   * 清空共享池（退出登录时调用，避免账号切换数据残留）
   */
  async clear(): Promise<void> {
    this.posts = [];
    this.loaded = true;
    await PreferencesUtil.remove(SharedPostStoreImpl.PREF_KEY);
    Logger.info(AppConstants.SCENE_COMMON, { action: 'shared_posts_cleared' });
  }
}

/** 共享帖子池单例 */
export const SharedPostStore: SharedPostStoreImpl = new SharedPostStoreImpl();
