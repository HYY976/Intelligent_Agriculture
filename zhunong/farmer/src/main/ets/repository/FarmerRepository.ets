/**
 * FarmerRepository - 卖家信息域 Repository（spec 3.2.4.5）
 * 走 BaseRepository.fetchWithFallback：先 REST 后 Mock 兜底
 * 后端部署后无需改代码，自动切真实数据
 */

import { BaseRepository, AppConstants } from 'common';
import { FarmerProfile, CertificationInfo, CertificationStatus } from '../model/FarmerModels';
import { MOCK_FARMER_PROFILE, getMockFarmerProfileById, getMockRevenueSummary } from '../mock/FarmerMock';

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
        // spec 16.15：累计营收与首页"累计"范围完全一致（getMockRevenueSummary('total').amount）
        const baseProfile: FarmerProfile | null = getMockFarmerProfileById(farmerId);
        const base: FarmerProfile = baseProfile ?? MOCK_FARMER_PROFILE;
        const totalRevenue: number = getMockRevenueSummary('total').amount;
        const availableBalance: number = Math.round(totalRevenue * 0.225 * 100) / 100;
        // spec 16.15：粉丝数 = MOCK_FARMER_PROFILE.fansCount，与粉丝管理页同源同步
        const fansCount: number = base.fansCount;
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
          followCount: base.followCount,
          fansCount: fansCount,
          monthlyNewFans: base.monthlyNewFans,
          interactionRate: base.interactionRate
        };
        return profile;
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
