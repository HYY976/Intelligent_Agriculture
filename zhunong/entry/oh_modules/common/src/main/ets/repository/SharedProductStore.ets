/**
 * SharedProductStore - 共享商品池（双端同步用）
 *
 * 用途（spec 16.3）：
 *  - 农户端发布商品时调用 publish() 将商品写入共享池
 *  - 用户端读取商品列表时调用 getAll() 合并到 Mock 列表头部
 *  - 字段对齐 user 端 Product，确保双端数据结构一致
 *
 * 注意：
 *  - 当前为内存单例，跨 HAP 不共享实例
 *  - 通过 PreferencesUtil 持久化（key=shared_products）实现跨 HAP 数据同步
 *  - 退出登录时调用 clear() 清空，避免账号切换数据残留
 */

import { PreferencesUtil } from '../utils/PreferencesUtil';
import { Logger } from '../utils/Logger';
import { AppConstants } from '../constants/AppConstants';
import { ProductStatus } from '../model/CommonModels';

/** 共享商品（双端同步用，字段对齐 user 端 Product） */
export interface SharedProduct {
  productId: string;
  farmerId: string;
  /** 卖家昵称（来自 UserInfo.nickname） */
  farmerName: string;
  /** 卖家头像 key（来自 UserInfo.avatar） */
  farmerAvatar: string;
  title: string;
  categoryId: string;
  mainImages: string[];
  aiPosterUrl?: string;
  description: string;
  price: number;
  stock: number;
  shipFrom: string;
  freightTemplate: string;
  monthlySales: number;
  monthlyGmv: number;
  totalSales: number;
  status: ProductStatus;
  createdAt: number;
  updatedAt: number;
}

/** Preferences 持久化的容器结构 */
interface SharedProductsContainer {
  items: SharedProduct[];
}

class SharedProductStoreImpl {
  /** 内存缓存（启动后从 Preferences 加载） */
  private products: SharedProduct[] = [];
  /** 是否已从 Preferences 加载过 */
  private loaded: boolean = false;
  /** Preferences key */
  private static readonly PREF_KEY: string = 'shared_products';

  /** 从 Preferences 加载到内存（懒加载，仅一次） */
  private async ensureLoaded(): Promise<void> {
    if (this.loaded) {
      return;
    }
    try {
      const json: string = await PreferencesUtil.getString(SharedProductStoreImpl.PREF_KEY, '');
      if (json.length > 0) {
        const container: SharedProductsContainer = JSON.parse(json) as SharedProductsContainer;
        if (container && Array.isArray(container.items)) {
          this.products = container.items;
        }
      }
      this.loaded = true;
      Logger.info(AppConstants.SCENE_COMMON, {
        action: 'shared_products_loaded',
        count: this.products.length
      });
    } catch (err) {
      Logger.error(AppConstants.SCENE_COMMON, {
        action: 'shared_products_load_fail',
        error: (err as Error).message
      });
      this.products = [];
      this.loaded = true;
    }
  }

  /** 持久化到 Preferences */
  private async persist(): Promise<void> {
    try {
      const container: SharedProductsContainer = { items: this.products };
      await PreferencesUtil.putString(
        SharedProductStoreImpl.PREF_KEY,
        JSON.stringify(container)
      );
    } catch (err) {
      Logger.error(AppConstants.SCENE_COMMON, {
        action: 'shared_products_persist_fail',
        error: (err as Error).message
      });
    }
  }

  /**
   * 发布商品到共享池（农户端调用）
   * - 同 productId 已存在则更新；否则新增
   */
  async publish(product: SharedProduct): Promise<void> {
    await this.ensureLoaded();
    // 移除已存在的相同 productId 商品
    this.products = this.products.filter((p: SharedProduct): boolean => p.productId !== product.productId);
    this.products.push(product);
    await this.persist();
    Logger.info(AppConstants.SCENE_COMMON, {
      action: 'shared_product_published',
      productId: product.productId,
      total: this.products.length
    });
  }

  /**
   * 获取全部共享商品（用户端读取并合并到 Mock 列表头部）
   * 返回副本，避免外部直接修改内部状态
   */
  async getAll(): Promise<SharedProduct[]> {
    await this.ensureLoaded();
    return this.products.slice();
  }

  /** 根据 productId 获取共享商品 */
  async getById(productId: string): Promise<SharedProduct | null> {
    await this.ensureLoaded();
    const found: SharedProduct | undefined = this.products.find(
      (p: SharedProduct): boolean => p.productId === productId
    );
    return found ?? null;
  }

  /** 根据 farmerId 获取该卖家的所有共享商品 */
  async getByFarmer(farmerId: string): Promise<SharedProduct[]> {
    await this.ensureLoaded();
    return this.products.filter(
      (p: SharedProduct): boolean => p.farmerId === farmerId
    );
  }

  /** 删除指定商品 */
  async remove(productId: string): Promise<void> {
    await this.ensureLoaded();
    this.products = this.products.filter(
      (p: SharedProduct): boolean => p.productId !== productId
    );
    await this.persist();
  }

  /**
   * 清空共享池（退出登录时调用，避免账号切换数据残留）
   */
  async clear(): Promise<void> {
    this.products = [];
    this.loaded = true;
    await PreferencesUtil.remove(SharedProductStoreImpl.PREF_KEY);
    Logger.info(AppConstants.SCENE_COMMON, { action: 'shared_products_cleared' });
  }
}

/** 共享商品池单例 */
export const SharedProductStore: SharedProductStoreImpl = new SharedProductStoreImpl();
