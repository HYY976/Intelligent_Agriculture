/**
 * RevenueRepository - 营收域 Repository（spec 3.2.3 / 4.1.7）
 * 走 BaseRepository.fetchWithFallback：先 REST 后 Mock 兜底
 * 含营收汇总 / 营收明细列表 / 提现记录 / 营收统计图表
 */

import { BaseRepository, AppConstants, PageResult } from 'common';
import {
  RevenueSummary,
  RevenueRecord,
  RevenueRange,
  RevenueRecordStatus,
  RevenueStatsDimension,
  RevenueChartPoint,
  Withdrawal
} from '../model/FarmerModels';
import {
  getMockRevenueSummary,
  getMockRevenueRecords,
  getMockWithdrawals,
  getMockRevenueChart
} from '../mock/FarmerMock';

/** 营收汇总查询参数 */
interface RevenueSummaryQuery {
  farmerId: string;
  range: RevenueRange;
}

/** 营收明细查询参数 */
interface RevenueRecordQuery {
  farmerId: string;
  range: RevenueRange;
  status?: string;
  page: number;
  size: number;
}

/** 营收统计图表查询参数 */
interface RevenueChartQuery {
  farmerId: string;
  dimension: RevenueStatsDimension;
}

/** 提现记录查询参数 */
interface WithdrawalListQuery {
  farmerId: string;
  page: number;
  size: number;
}

/** 提现请求体 */
interface WithdrawRequestBody {
  farmerId: string;
  amount: number;
  account: string;
}

class RevenueRepositoryImpl {
  /**
   * 营收汇总（spec 3.2.3.1：今日/月/年/累计切换）
   * GET /api/revenue/summary?farmerId=&range=
   */
  async getRevenueSummary(farmerId: string, range: RevenueRange): Promise<RevenueSummary> {
    const params: RevenueSummaryQuery = { farmerId, range };
    return BaseRepository.fetchWithFallback<RevenueSummary>(
      'revenue/summary',
      params,
      async (): Promise<RevenueSummary> => getMockRevenueSummary(range),
      AppConstants.SCENE_FARMER
    );
  }

  /**
   * 营收明细列表（spec 3.2.3.3：按订单粒度，支持时间范围+状态筛选+分页）
   * GET /api/revenue/records?farmerId=&range=&status=&page=&size=
   */
  async getRevenueRecords(
    farmerId: string,
    range: RevenueRange,
    status: RevenueRecordStatus | undefined,
    page: number,
    size: number
  ): Promise<PageResult<RevenueRecord>> {
    const params: RevenueRecordQuery = { farmerId, range, page, size };
    if (status) {
      params.status = status;
    }
    return BaseRepository.fetchWithFallback<PageResult<RevenueRecord>>(
      'revenue/records',
      params,
      async (): Promise<PageResult<RevenueRecord>> => {
        const mockResult = getMockRevenueRecords(range, status, page, size);
        const result: PageResult<RevenueRecord> = {
          list: mockResult.list,
          total: mockResult.total,
          page: page,
          size: size,
          hasMore: mockResult.hasMore
        };
        return result;
      },
      AppConstants.SCENE_FARMER
    );
  }

  /**
   * 营收统计图表数据（spec 3.2.4.5：按日/月/年折线图）
   * GET /api/revenue/chart?farmerId=&dimension=
   */
  async getRevenueChart(farmerId: string, dimension: RevenueStatsDimension): Promise<RevenueChartPoint[]> {
    const params: RevenueChartQuery = { farmerId, dimension };
    return BaseRepository.fetchWithFallback<RevenueChartPoint[]>(
      'revenue/chart',
      params,
      async (): Promise<RevenueChartPoint[]> => getMockRevenueChart(dimension),
      AppConstants.SCENE_FARMER
    );
  }

  /**
   * 提现记录列表（spec 9.3：确认收货即可提现，无审核）
   * GET /api/revenue/withdrawals?farmerId=&page=&size=
   */
  async getWithdrawals(farmerId: string, page: number, size: number): Promise<PageResult<Withdrawal>> {
    const params: WithdrawalListQuery = { farmerId, page, size };
    return BaseRepository.fetchWithFallback<PageResult<Withdrawal>>(
      'revenue/withdrawals',
      params,
      async (): Promise<PageResult<Withdrawal>> => {
        const mockResult = getMockWithdrawals(page, size);
        const result: PageResult<Withdrawal> = {
          list: mockResult.list,
          total: mockResult.total,
          page: page,
          size: size,
          hasMore: mockResult.hasMore
        };
        return result;
      },
      AppConstants.SCENE_FARMER
    );
  }

  /**
   * 申请提现（spec 9.3：确认收货即可提现，无审核）
   * POST /api/revenue/withdraw
   */
  async requestWithdraw(farmerId: string, amount: number, account: string): Promise<boolean> {
    const body: WithdrawRequestBody = { farmerId, amount, account };
    const result: boolean = await BaseRepository.postWithFallback<boolean>(
      'revenue/withdraw',
      body,
      async (): Promise<boolean> => true,
      AppConstants.SCENE_FARMER
    );
    return result;
  }
}

/** 营收域 Repository 单例 */
export const RevenueRepository: RevenueRepositoryImpl = new RevenueRepositoryImpl();
