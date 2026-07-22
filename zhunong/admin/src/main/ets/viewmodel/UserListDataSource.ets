/**
 * UserListDataSource - 管理后台用户列表数据源
 * 遵循 spec 3.3.1 / 10.8.3.1：多条件搜索（账号/手机号/昵称/类型/状态）+ 分页
 * spec 10.11.3：继承 BaseDataSource<T>，仅保留过滤字段 + fetchPage 单一职责
 * 取数走 UserRepository（spec 10.3：先 REST 后 Mock 兜底），接口 GET /api/admin/users
 *
 * spec 10.11.11（v2.2 新增）：4 态状态机扩展设计
 *  - fetchPage 内部 try-catch，失败时不抛异常，而是设置 loadFailed=true 并返回空数组
 *  - 通过 getLoadFailed() 暴露错误状态供页面 4 态判断（loading / empty / list / error）
 *  - 不修改 BaseDataSource 基类契约（保持 Step 2/3 既有决策）
 *
 * spec 10.11.11.1：多 setter 拆分模式（与 Step 2/3 一致）
 *  - setKeyword(keyword) / setPhone(phone) / setNickname(nickname)
 *  - setUserType(type) / setStatus(status)
 *  - refresh 后生效
 */

import {
  UserRecord,
  UserListQuery,
  UserRecordType,
  UserRecordStatus
} from '../model/AdminModels';
import { UserRepository } from '../repository/UserRepository';
import { AppConstants, BaseDataSource, FetchPageResult, Logger } from 'common';

export class UserListDataSource extends BaseDataSource<UserRecord> {
  /** 日志场景名（spec 10.11.3：注入基类） */
  protected readonly scene: string = AppConstants.SCENE_ADMIN;
  /** 日志动作前缀（spec 10.11.3：注入基类） */
  protected readonly actionPrefix: string = 'user_list';

  /** 搜索关键字（账号 / 昵称） */
  private keyword: string = '';
  /** 手机号搜索 */
  private phone: string = '';
  /** 昵称搜索 */
  private nickname: string = '';
  /** 类型筛选（'all' = 全部） */
  private typeFilter: 'all' | UserRecordType = 'all';
  /** 状态筛选（'all' = 全部） */
  private statusFilter: 'all' | UserRecordStatus = 'all';
  /** 加载失败标志（4 态状态机：fetchPage 内部捕获异常后设置） */
  private loadFailed: boolean = false;

  constructor() {
    super();
    // spec 10.11.3：覆盖基类默认 pageSize 20 → 20（用户列表单列，每页 20 项，与原页面一致）
    this.pageSize = 20;
  }

  /** 设置搜索关键字，refresh 后生效 */
  setKeyword(keyword: string): void {
    this.keyword = keyword;
  }

  /** 设置手机号搜索，refresh 后生效 */
  setPhone(phone: string): void {
    this.phone = phone;
  }

  /** 设置昵称搜索，refresh 后生效 */
  setNickname(nickname: string): void {
    this.nickname = nickname;
  }

  /** 设置类型筛选，refresh 后生效 */
  setUserType(type: 'all' | UserRecordType): void {
    this.typeFilter = type;
  }

  /** 设置状态筛选，refresh 后生效 */
  setStatus(status: 'all' | UserRecordStatus): void {
    this.statusFilter = status;
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
  protected async fetchPage(page: number, size: number): Promise<FetchPageResult<UserRecord>> {
    // 每次取数前重置错误状态
    this.loadFailed = false;
    try {
      const query: UserListQuery = { page, size };
      if (this.keyword.trim().length > 0) {
        query.keyword = this.keyword.trim();
      }
      if (this.phone.trim().length > 0) {
        query.phone = this.phone.trim();
      }
      if (this.nickname.trim().length > 0) {
        query.nickname = this.nickname.trim();
      }
      if (this.typeFilter !== 'all') {
        query.userType = this.typeFilter;
      }
      if (this.statusFilter !== 'all') {
        query.status = this.statusFilter;
      }
      const result = await UserRepository.getUsers(query);
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
