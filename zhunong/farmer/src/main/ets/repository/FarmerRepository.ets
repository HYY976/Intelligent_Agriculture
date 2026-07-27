/**
 * FarmerRepository - 卖家信息域 Repository（spec 3.2.4.5）
 * 走 BaseRepository.fetchWithFallback：先 REST 后 Mock 兜底
 * 后端部署后无需改代码，自动切真实数据
 */

import { BaseRepository, AppConstants } from 'common';
import { SharedProductStore, SharedProduct } from 'common';
import { FarmerProfile, CertificationInfo, CertificationStatus } from '../model/FarmerModels';
import { MOCK_FARMER_PROFILE, getMockFarmerProfileById, MOCK_FANS_LIST } from '../mock/FarmerMock';

/** 卖家信息查询参数 */
interface FarmerProfileQuery {
  farmerId: string;
}

class FarmerRepositoryImpl {
  /**
   * 查询当前卖家信息
   * GET /api/farmer/profile?farmerId=xxx
   */
  async getMyProfile(farmerId: string): Promise<FarmerProfile> {
    const params: FarmerProfileQuery = { farmerId };
    return BaseRepository.fetchWithFallback<FarmerProfile>(
      'farmer/profile',
      params,
      async (): Promise<FarmerProfile> => {
        // spec 16.11/16.12：从 SharedProductStore 同步真实数据（累计收入、可提现、粉丝等）
        try {
          const products: SharedProduct[] = await SharedProductStore.getAll();
          const approvedProducts: SharedProduct[] = products.filter(
            (p: SharedProduct): boolean => p.status === 'approved'
          );
          // spec 16.12：累计营收 = 月销售额 × 12（与首页"累计"范围一致）
          const monthlyRevenue: number = approvedProducts.reduce(
            (sum: number, p: SharedProduct): number => sum + (p.monthlyGmv || p.price * (p.monthlySales || 5)), 0
          );
          const baseRevenue: number = monthlyRevenue > 0 ? monthlyRevenue : 8000;
          const totalRevenue: number = Math.round(baseRevenue * 12 * (0.9 + Math.random() * 0.2) * 100) / 100;
          // 可提现 = 累计营收 × 22.5%（扣除平台佣金）
          const availableBalance: number = Math.round(totalRevenue * 0.225 * 100) / 100;
          // spec 16.12：粉丝数 = 粉丝列表实际数量（与粉丝管理页同步）
          const fansCount: number = MOCK_FANS_LIST.length;
          // 关注数基于商品数量估算
          const followCount: number = Math.max(28, Math.round(approvedProducts.length * 1.5));

          const baseProfile: FarmerProfile | null = getMockFarmerProfileById(farmerId);
          // spec 16.11：ArkTS 不支持对象 spread，使用显式拷贝
          const base: FarmerProfile = baseProfile ?? MOCK_FARMER_PROFILE;
          const profile: FarmerProfile = {
            farmerId: base.farmerId,
            shopName: base.shopName,
            shopLogo: base.shopLogo,
            shopIntro: base.shopIntro,
            certificationStatus: base.certificationStatus,
            certificationInfo: base.certificationInfo,
            totalRevenue: totalRevenue,
            availableBalance: availableBalance,
            frozenBalance: base.frozenBalance,
            followCount: followCount,
            fansCount: fansCount,
            monthlyNewFans: base.monthlyNewFans,
            interactionRate: base.interactionRate
          };
          return profile;
        } catch (_err) {
          const profile: FarmerProfile | null = getMockFarmerProfileById(farmerId);
          return profile ?? MOCK_FARMER_PROFILE;
        }
      },
      AppConstants.SCENE_FARMER
    );
  }

  /**
   * 更新店铺信息
   * PUT /api/farmer/profile
   */
  async updateProfile(farmerId: string, shopName: string, shopIntro: string, shopLogo: string): Promise<boolean> {
    const body: UpdateProfileBody = { farmerId, shopName, shopIntro, shopLogo };
    const result: boolean = await BaseRepository.postWithFallback<boolean>(
      'farmer/profile',
      body,
      async (): Promise<boolean> => true,
      AppConstants.SCENE_FARMER
    );
    return result;
  }

  /**
   * 提交资质认证（spec 13.2：Mock 认证，提交后直接"认证通过"）
   * POST /api/farmer/certification
   */
  async submitCertification(farmerId: string, certInfo: CertificationInfo): Promise<CertificationStatus> {
    const body: SubmitCertBody = { farmerId, certInfo };
    const result: CertificationStatus = await BaseRepository.postWithFallback<CertificationStatus>(
      'farmer/certification',
      body,
      async (): Promise<CertificationStatus> => {
        // Mock：直接返回 approved
        return 'approved';
      },
      AppConstants.SCENE_FARMER
    );
    return result;
  }
}

/** 更新店铺信息请求体 */
interface UpdateProfileBody {
  farmerId: string;
  shopName: string;
  shopIntro: string;
  shopLogo: string;
}

/** 提交资质认证请求体 */
interface SubmitCertBody {
  farmerId: string;
  certInfo: CertificationInfo;
}

/** 卖家信息域 Repository 单例 */
export const FarmerRepository: FarmerRepositoryImpl = new FarmerRepositoryImpl();
