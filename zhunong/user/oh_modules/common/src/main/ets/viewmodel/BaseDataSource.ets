/**
 * BaseDataSource - LazyForEach 通用数据源基类（spec 10.11.3 落地）
 *
 * 设计目标：
 *  - 抽取自 user 端 4 个 DataSource（HomeRecommendDataSource / CommunityDataSource /
 *    ProductListDataSource / LiveDataSource）的公共逻辑
 *  - 子类仅需实现 fetchPage 单一职责，其余分页 / 监听 / 状态管理 / 日志 由基类统一处理
 *  - 消除 600+ 行重复代码，后续 farmer / admin 新增 DataSource 仅需 ~15 行 / 个
 *
 * 子类契约：
 *  - 必须实现 readonly scene（日志场景名，如 AppConstants.SCENE_USER）
 *  - 必须实现 readonly actionPrefix（日志动作前缀，如 'home_recommend'）
 *  - 必须实现 fetchPage(page, size) 单页取数逻辑
 *  - 可选重写 readonly pageSize（默认 20）
 *  - 可选自定义过滤状态字段 + setFilter() 方法（在 fetchPage 内消费）
 *
 * 使用示例（HomeRecommendDataSource 重构后）：
 *
 * ```ts
 * export class HomeRecommendDataSource extends BaseDataSource<ProductListItem> {
 *   protected readonly scene: string = AppConstants.SCENE_USER;
 *   protected readonly actionPrefix: string = 'home_recommend';
 *
 *   protected async fetchPage(page: number, size: number): Promise<FetchPageResult<ProductListItem>> {
 *     const result = await HomeRepository.getRecommendList(page, size);
 *     return { list: result.list, hasMore: result.hasMore };
 *   }
 * }
 * ```
 */

import { Logger } from '../utils/Logger';
import { LogInfo } from '../utils/Logger';
import { FetchPageResult } from '../model/CommonModels';

/**
 * LazyForEach 通用数据源抽象基类
 * 实现 IDataSource 接口，提供 totalCount / getData / registerDataChangeListener /
 * unregisterDataChangeListener / refresh / loadMore 等通用方法
 */
export abstract class BaseDataSource<T> implements IDataSource {
  /** 列表数据（子类可读，不可外部访问） */
  protected items: T[] = [];
  /** 监听器列表（私有，仅基类管理） */
  private listeners: DataChangeListener[] = [];
  /** 当前页码 */
  protected currentPage: number = 0;
  /** 每页条数（子类可重写 readonly 覆盖默认值 20） */
  protected pageSize: number = 20;
  /** 是否正在加载 */
  protected isLoading: boolean = false;
  /** 是否还有更多 */
  protected hasMore: boolean = true;
  /** 是否首次加载 */
  protected isFirstLoad: boolean = true;
  /** 最近一次 refresh / loadMore 是否失败（供页面读取展示错误态） */
  protected hasLoadFailed: boolean = false;

  /** 子类注入：日志场景名（如 AppConstants.SCENE_USER / SCENE_FARMER / SCENE_ADMIN） */
  protected abstract readonly scene: string;
  /** 子类注入：日志动作前缀（如 'home_recommend' / 'community_list'） */
  protected abstract readonly actionPrefix: string;

  /**
   * 子类实现：单页取数
   * @param page 页码（从 1 开始）
   * @param size 每页条数
   * @returns 当前页数据列表 + 是否还有更多
   */
  protected abstract fetchPage(page: number, size: number): Promise<FetchPageResult<T>>;

  /** IDataSource：获取数据项总数 */
  totalCount(): number {
    return this.items.length;
  }

  /** IDataSource：根据索引获取数据 */
  getData(index: number): T {
    return this.items[index];
  }

  /** IDataSource：注册监听器 */
  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  /** IDataSource：注销监听器 */
  unregisterDataChangeListener(listener: DataChangeListener): void {
    const idx: number = this.listeners.indexOf(listener);
    if (idx >= 0) {
      this.listeners.splice(idx, 1);
    }
  }

  /** 通知监听器数据全部重载 */
  protected notifyReload(): void {
    this.listeners.forEach((l: DataChangeListener) => {
      l.onDataReloaded();
    });
  }

  /** 通知监听器追加数据（spec 10.9.4.1：onDataAdded → onDataAdd，V2 推荐写法） */
  protected notifyAdd(index: number): void {
    this.listeners.forEach((l: DataChangeListener) => {
      l.onDataAdd(index);
    });
  }

  /** 首次加载 / 刷新 */
  async refresh(): Promise<void> {
    if (this.isLoading) {
      return;
    }
    this.isLoading = true;
    try {
      this.currentPage = 1;
      const result = await this.fetchPage(this.currentPage, this.pageSize);
      this.items = result.list;
      this.hasMore = result.hasMore;
      this.isFirstLoad = false;
      this.hasLoadFailed = false;
      this.notifyReload();
      const refreshLog: LogInfo = {
        action: `${this.actionPrefix}_refresh`,
        count: this.items.length,
        hasMore: this.hasMore
      };
      Logger.info(this.scene, refreshLog);
    } catch (err) {
      this.hasLoadFailed = true;
      Logger.error(this.scene, {
        action: `${this.actionPrefix}_refresh_fail`,
        error: (err as Error).message
      });
    } finally {
      this.isLoading = false;
    }
  }

  /** 加载更多 */
  async loadMore(): Promise<void> {
    if (this.isLoading || !this.hasMore) {
      return;
    }
    this.isLoading = true;
    try {
      this.currentPage++;
      const result = await this.fetchPage(this.currentPage, this.pageSize);
      const startIndex: number = this.items.length;
      this.items = this.items.concat(result.list);
      this.hasMore = result.hasMore;
      this.hasLoadFailed = false;
      this.notifyAdd(startIndex);
      const loadMoreLog: LogInfo = {
        action: `${this.actionPrefix}_load_more`,
        page: this.currentPage,
        added: result.list.length,
        hasMore: this.hasMore
      };
      Logger.info(this.scene, loadMoreLog);
    } catch (err) {
      this.hasLoadFailed = true;
      Logger.error(this.scene, {
        action: `${this.actionPrefix}_load_more_fail`,
        error: (err as Error).message
      });
      this.currentPage--;
    } finally {
      this.isLoading = false;
    }
  }

  /** 是否首次加载 */
  getIsFirstLoad(): boolean {
    return this.isFirstLoad;
  }

  /** 是否正在加载 */
  getIsLoading(): boolean {
    return this.isLoading;
  }

  /** 是否还有更多 */
  getHasMore(): boolean {
    return this.hasMore;
  }

  /** 最近一次 refresh / loadMore 是否失败（供页面读取展示错误态） */
  getLoadFailed(): boolean {
    return this.hasLoadFailed;
  }
}
