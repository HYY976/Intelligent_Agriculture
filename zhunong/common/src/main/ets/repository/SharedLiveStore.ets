/**
 * SharedLiveStore - 共享直播池（双端同步用）
 *
 * 用途：
 *  - 农户端开播时调用 publish() 将直播间写入共享池
 *  - 农户端结束直播时调用 markEnded() 更新状态
 *  - 用户端读取直播列表时调用 getAll() 合并到列表头部
 *  - 字段对齐 user 端 LiveListItem 关键字段，确保双端数据结构一致
 *
 * 注意：
 *  - 通过 PreferencesUtil 持久化（key=shared_lives）实现跨 HAP 数据同步
 *  - 退出登录时调用 clear() 清空，避免账号切换数据残留
 */

import { PreferencesUtil } from '../utils/PreferencesUtil';
import { Logger } from '../utils/Logger';
import { AppConstants } from '../constants/AppConstants';
import { LiveStatus } from '../model/CommonModels';

/** 共享直播（双端同步用，字段对齐 user 端 LiveListItem 关键字段） */
export interface SharedLive {
  liveId: string;
  /** 主播卖家 ID */
  farmerId: string;
  /** 主播昵称 */
  farmerName: string;
  /** 主播头像 key */
  farmerAvatar: string;
  title: string;
  /** 封面图 key */
  coverImage: string;
  /** 直播分类（fresh/grain/meat/tea/other） */
  category: string;
  /** 直播状态 */
  status: LiveStatus;
  /** 在线观看人数（living）/累计 UV（ended） */
  onlineCount: number;
  /** 累计观看 UV */
  totalViewUv: number;
  createdAt: number;
}

/** Preferences 持久化的容器结构 */
interface SharedLivesContainer {
  items: SharedLive[];
}

class SharedLiveStoreImpl {
  /** 内存缓存（启动后从 Preferences 加载） */
  private lives: SharedLive[] = [];
  /** 是否已从 Preferences 加载过 */
  private loaded: boolean = false;
  /** Preferences key */
  private static readonly PREF_KEY: string = 'shared_lives';

  /** 从 Preferences 加载到内存（懒加载，仅一次） */
  private async ensureLoaded(): Promise<void> {
    if (this.loaded) {
      return;
    }
    try {
      const json: string = await PreferencesUtil.getString(SharedLiveStoreImpl.PREF_KEY, '');
      if (json.length > 0) {
        const container: SharedLivesContainer = JSON.parse(json) as SharedLivesContainer;
        if (container && Array.isArray(container.items)) {
          this.lives = container.items;
        }
      }
      this.loaded = true;
      Logger.info(AppConstants.SCENE_COMMON, {
        action: 'shared_lives_loaded',
        count: this.lives.length
      });
    } catch (err) {
      Logger.error(AppConstants.SCENE_COMMON, {
        action: 'shared_lives_load_fail',
        error: (err as Error).message
      });
      this.lives = [];
      this.loaded = true;
    }
  }

  /** 持久化到 Preferences */
  private async persist(): Promise<void> {
    try {
      const container: SharedLivesContainer = { items: this.lives };
      await PreferencesUtil.putString(
        SharedLiveStoreImpl.PREF_KEY,
        JSON.stringify(container)
      );
    } catch (err) {
      Logger.error(AppConstants.SCENE_COMMON, {
        action: 'shared_lives_persist_fail',
        error: (err as Error).message
      });
    }
  }

  /**
   * 发布直播到共享池（农户端开播时调用）
   * - 同 liveId 已存在则更新；否则新增到头部
   */
  async publish(live: SharedLive): Promise<void> {
    await this.ensureLoaded();
    this.lives = this.lives.filter((l: SharedLive): boolean => l.liveId !== live.liveId);
    this.lives.unshift(live);
    await this.persist();
    Logger.info(AppConstants.SCENE_COMMON, {
      action: 'shared_live_published',
      liveId: live.liveId,
      total: this.lives.length
    });
  }

  /**
   * 标记直播结束（农户端结束直播时调用）
   */
  async markEnded(liveId: string): Promise<void> {
    await this.ensureLoaded();
    this.lives = this.lives.map((l: SharedLive): SharedLive => {
      if (l.liveId === liveId) {
        return {
          liveId: l.liveId,
          farmerId: l.farmerId,
          farmerName: l.farmerName,
          farmerAvatar: l.farmerAvatar,
          title: l.title,
          coverImage: l.coverImage,
          category: l.category,
          status: 'ended',
          onlineCount: l.onlineCount,
          totalViewUv: l.totalViewUv,
          createdAt: l.createdAt
        };
      }
      return l;
    });
    await this.persist();
  }

  /**
   * 获取全部共享直播（用户端读取并合并到列表头部）
   * 返回副本，避免外部直接修改内部状态
   */
  async getAll(): Promise<SharedLive[]> {
    await this.ensureLoaded();
    return this.lives.slice();
  }

  /** 根据 liveId 获取共享直播 */
  async getById(liveId: string): Promise<SharedLive | null> {
    await this.ensureLoaded();
    const found: SharedLive | undefined = this.lives.find(
      (l: SharedLive): boolean => l.liveId === liveId
    );
    return found ?? null;
  }

  /** 删除指定直播 */
  async remove(liveId: string): Promise<void> {
    await this.ensureLoaded();
    this.lives = this.lives.filter(
      (l: SharedLive): boolean => l.liveId !== liveId
    );
    await this.persist();
  }

  /**
   * 清空共享池（退出登录时调用，避免账号切换数据残留）
   */
  async clear(): Promise<void> {
    this.lives = [];
    this.loaded = true;
    await PreferencesUtil.remove(SharedLiveStoreImpl.PREF_KEY);
    Logger.info(AppConstants.SCENE_COMMON, { action: 'shared_lives_cleared' });
  }
}

/** 共享直播池单例 */
export const SharedLiveStore: SharedLiveStoreImpl = new SharedLiveStoreImpl();
