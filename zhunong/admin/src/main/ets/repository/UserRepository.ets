/**
 * UserRepository - 用户管理域 Repository（spec 3.3.1 / 10.8.3.1）
 * 走 BaseRepository.fetchWithFallback / postWithFallback：先 REST 后 Mock 兜底
 * 含用户列表（多条件搜索）/ 用户详情 / 封禁 / 解封 / 重置密码
 */

import { BaseRepository, AppConstants, PageResult } from 'common';
import {
  UserRecord,
  UserListQuery,
  UserBanRequest,
  UserDetailAggregate
} from '../model/AdminModels';
import {
  getMockUsers,
  getMockUserDetail
} from '../mock/AdminMock';

/** 用户列表查询参数（HTTP GET query） */
interface UserListHttpQuery {
  keyword?: string;
  phone?: string;
  nickname?: string;
  startTime?: number;
  endTime?: number;
  userType?: string;
  status?: string;
  page: number;
  size: number;
}

/** 封禁用户请求体 */
interface BanUserBody {
  reason: string;
  description?: string;
  duration: string;
}

class UserRepositoryImpl {
  /**
   * 用户列表（spec 3.3.1：多条件搜索 + 分页）
   * GET /api/admin/users
   */
  async getUsers(query: UserListQuery): Promise<PageResult<UserRecord>> {
    const params: UserListHttpQuery = {
      page: query.page,
      size: query.size
    };
    if (query.keyword) {
      params.keyword = query.keyword;
    }
    if (query.phone) {
      params.phone = query.phone;
    }
    if (query.nickname) {
      params.nickname = query.nickname;
    }
    if (query.startTime) {
      params.startTime = query.startTime;
    }
    if (query.endTime) {
      params.endTime = query.endTime;
    }
    if (query.userType) {
      params.userType = query.userType;
    }
    if (query.status) {
      params.status = query.status;
    }
    return BaseRepository.fetchWithFallback<PageResult<UserRecord>>(
      'admin/users',
      params,
      async (): Promise<PageResult<UserRecord>> => getMockUsers(query),
      AppConstants.SCENE_ADMIN
    );
  }

  /**
   * 用户详情聚合数据（spec 3.3.1：基本信息 + 订单/内容/设备历史）
   * GET /api/admin/users/{userId}
   */
  async getUserDetail(userId: string): Promise<UserDetailAggregate | null> {
    return BaseRepository.fetchWithFallback<UserDetailAggregate | null>(
      `admin/users/${userId}`,
      undefined,
      async (): Promise<UserDetailAggregate | null> => getMockUserDetail(userId),
      AppConstants.SCENE_ADMIN
    );
  }

  /**
   * 封禁用户（spec 3.3.1：必填原因 + 时长 1天/7天/30天/永久）
   * PUT /api/admin/users/{userId}/ban
   */
  async banUser(userId: string, req: UserBanRequest): Promise<boolean> {
    const body: BanUserBody = {
      reason: req.reason,
      duration: req.duration
    };
    if (req.description) {
      body.description = req.description;
    }
    const result: boolean = await BaseRepository.postWithFallback<boolean>(
      `admin/users/${userId}/ban`,
      body,
      async (): Promise<boolean> => true,
      AppConstants.SCENE_ADMIN
    );
    return result;
  }

  /**
   * 解封用户（spec 3.3.1）
   * PUT /api/admin/users/{userId}/unban
   */
  async unbanUser(userId: string): Promise<boolean> {
    const result: boolean = await BaseRepository.postWithFallback<boolean>(
      `admin/users/${userId}/unban`,
      undefined,
      async (): Promise<boolean> => true,
      AppConstants.SCENE_ADMIN
    );
    return result;
  }

  /**
   * 重置密码（spec 3.3.1：重置为默认密码 zhunong@123，下次登录强制修改）
   * PUT /api/admin/users/{userId}/reset-password
   */
  async resetPassword(userId: string): Promise<boolean> {
    const result: boolean = await BaseRepository.postWithFallback<boolean>(
      `admin/users/${userId}/reset-password`,
      undefined,
      async (): Promise<boolean> => true,
      AppConstants.SCENE_ADMIN
    );
    return result;
  }
}

/** 用户管理域 Repository 单例 */
export const UserRepository: UserRepositoryImpl = new UserRepositoryImpl();
