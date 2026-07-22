/**
 * AdminRepository - 管理后台控制台 Repository（spec 3.3 / 10.8.4）
 * 走 BaseRepository.fetchWithFallback：先 REST 后 Mock 兜底
 * 提供控制台统计数据（用户数/卖家数/待审核/今日订单）
 */

import { BaseRepository, AppConstants } from 'common';
import { DashboardStats } from '../model/AdminModels';
import { MOCK_DASHBOARD_STATS } from '../mock/AdminMock';

class AdminRepositoryImpl {
  /**
   * 控制台统计数据（spec 10.8.4：admin_home Dashboard）
   * GET /api/admin/dashboard/stats
   */
  async getDashboardStats(): Promise<DashboardStats> {
    return BaseRepository.fetchWithFallback<DashboardStats>(
      'admin/dashboard/stats',
      undefined,
      async (): Promise<DashboardStats> => MOCK_DASHBOARD_STATS,
      AppConstants.SCENE_ADMIN
    );
  }
}

/** 控制台域 Repository 单例 */
export const AdminRepository: AdminRepositoryImpl = new AdminRepositoryImpl();
