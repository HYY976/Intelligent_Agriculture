/**
 * ApiListDataSource - 管理后台 API 接口列表数据源
 * 遵循 spec 3.3.2 / 10.8.3.2：路径搜索（防抖 300ms）+ 分页 + 跳转 API 详情 / 限流配置
 * spec 10.11.3：继承 BaseDataSource<T>，仅保留过滤字段 + fetchPage 单一职责
 * 取数走 ApiRepository（spec 10.3：先 REST 后 Mock 兜底），接口 GET /api/admin/apis
 *
 * spec 10.11.11（v2.2 新增）：4 态状态机扩展设计
 *  - fetchPage 内部 try-catch，失败时不抛异常，而是设置 loadFailed=true 并返回空数组
 *  - 通过 getLoadFailed() 暴露错误状态供页面 4 态判断（loading / empty / list / error）
 *  - 不修改 BaseDataSource 基类契约（保持 Step 2/3 既有决策）
 */

import { ApiInfo, ApiListQuery } from '../model/AdminModels';
import { ApiRepository } from '../repository/ApiRepository';
import { AppConstants, BaseDataSource, FetchPageResult, Logger } from 'common';

export class ApiListDataSource extends BaseDataSource<ApiInfo> {
  /** 日志场景名（spec 10.11.3：注入基类） */
  protected readonly scene: string = AppConstants.SCENE_ADMIN;
  /** 日志动作前缀（spec 10.11.3：注入基类） */
  protected readonly actionPrefix: string = 'api_list';

  /** 搜索关键字（接口路径 / 描述） */
  private keyword: string = '';
  /** 加载失败标志（4 态状态机：fetchPage 内部捕获异常后设置） */
  private loadFailed: boolean = false;

  constructor() {
    super();
    // spec 10.11.3：覆盖基类默认 pageSize 20 → 20（API 列表单列，每页 20 项，与原页面一致）
    this.pageSize = 20;
  }

  /** 设置搜索关键字，refresh 后生效 */
  setKeyword(keyword: string): void {
    this.keyword = keyword;
  }

  /** 获取加载失败标志（4 态状态机：供页面判断 error 视图） */
  getLoadFailed(): boolean {
    return this.loadFailed;
  }

  /**
   * 单页取数（spec 10.11.3：基类 refresh / loadMore 调用）
   * @param page 页码（从 1 开始）
   * @param size 每页条数
   */
  protected async fetchPage(page: number, size: number): Promise<FetchPageResult<ApiInfo>> {
    // 每次取数前重置错误状态
    this.loadFailed = false;
    try {
      const query: ApiListQuery = { page, size };
      if (this.keyword.trim().length > 0) {
        query.keyword = this.keyword.trim();
      }
      const result = await ApiRepository.getApis(query);
      return { list: result.list, hasMore: result.hasMore };
    } catch (err) {
      this.loadFailed = true;
      Logger.error(this.scene, {
        action: `${this.actionPrefix}_fetch_fail`,
        page: page,
        error: (err as Error).message
      });
      return { list: [], hasMore: false };
    }
  }
}
