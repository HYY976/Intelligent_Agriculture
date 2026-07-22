/**
 * ReviewRepository - 内容审核域 Repository（spec 3.3.3 / 10.8.3.3）
 * 走 BaseRepository.fetchWithFallback / postWithFallback：先 REST 后 Mock 兜底
 * 含审核列表（类型/状态筛选）/ 审核详情 / 通过 / 驳回 / 待审核数
 */

import { BaseRepository, AppConstants, PageResult } from 'common';
import {
  ContentReview,
  ReviewListQuery,
  ReviewDetailAggregate,
  ReviewRejectRequest
} from '../model/AdminModels';
import {
  getMockReviews,
  getMockReviewDetail,
  getMockPendingReviewCount,
  MOCK_REVIEWS
} from '../mock/AdminMock';

/** 审核列表查询参数（HTTP GET query） */
interface ReviewListHttpQuery {
  contentType?: string;
  status?: string;
  page: number;
  size: number;
}

/** 审核驳回请求体 */
interface ReviewRejectBody {
  reason: string;
  description?: string;
}

class ReviewRepositoryImpl {
  /**
   * 审核列表（spec 3.3.3：类型/状态筛选 + 分页）
   * GET /api/admin/reviews
   */
  async getReviews(query: ReviewListQuery): Promise<PageResult<ContentReview>> {
    const params: ReviewListHttpQuery = {
      page: query.page,
      size: query.size
    };
    if (query.contentType) {
      params.contentType = query.contentType;
    }
    if (query.status) {
      params.status = query.status;
    }
    return BaseRepository.fetchWithFallback<PageResult<ContentReview>>(
      'admin/reviews',
      params,
      async (): Promise<PageResult<ContentReview>> => getMockReviews(query),
      AppConstants.SCENE_ADMIN
    );
  }

  /**
   * 审核详情聚合（spec 3.3.3：含历史记录）
   * GET /api/admin/reviews/{reviewId}
   */
  async getReviewDetail(reviewId: string): Promise<ReviewDetailAggregate | null> {
    return BaseRepository.fetchWithFallback<ReviewDetailAggregate | null>(
      `admin/reviews/${reviewId}`,
      undefined,
      async (): Promise<ReviewDetailAggregate | null> => getMockReviewDetail(reviewId),
      AppConstants.SCENE_ADMIN
    );
  }

  /**
   * 审核通过（spec 3.3.3 / 10.8.3.3）
   * PUT /api/admin/reviews/{reviewId}/approve
   */
  async approveReview(reviewId: string): Promise<boolean> {
    // Mock 模式下直接更新本地状态
    const review: ContentReview | undefined = MOCK_REVIEWS.find(
      (r: ContentReview): boolean => r.reviewId === reviewId
    );
    if (review) {
      review.status = 'approved';
      review.reviewedAt = Date.now();
    }
    const result: boolean = await BaseRepository.postWithFallback<boolean>(
      `admin/reviews/${reviewId}/approve`,
      undefined,
      async (): Promise<boolean> => true,
      AppConstants.SCENE_ADMIN
    );
    return result;
  }

  /**
   * 审核驳回（spec 3.3.3 / 10.8.3.3：必填原因 + 自定义描述）
   * PUT /api/admin/reviews/{reviewId}/reject
   */
  async rejectReview(reviewId: string, req: ReviewRejectRequest): Promise<boolean> {
    const body: ReviewRejectBody = {
      reason: req.reason
    };
    if (req.description) {
      body.description = req.description;
    }
    // Mock 模式下直接更新本地状态
    const review: ContentReview | undefined = MOCK_REVIEWS.find(
      (r: ContentReview): boolean => r.reviewId === reviewId
    );
    if (review) {
      review.status = 'rejected';
      review.rejectReason = req.reason;
      if (req.description) {
        review.rejectDescription = req.description;
      }
      review.reviewedAt = Date.now();
    }
    const result: boolean = await BaseRepository.postWithFallback<boolean>(
      `admin/reviews/${reviewId}/reject`,
      body,
      async (): Promise<boolean> => true,
      AppConstants.SCENE_ADMIN
    );
    return result;
  }

  /**
   * 待审核数量（spec 3.3.3 / 10.8.4：admin_home 红点）
   * GET /api/admin/reviews/pending-count
   */
  async getPendingCount(): Promise<number> {
    return BaseRepository.fetchWithFallback<number>(
      'admin/reviews/pending-count',
      undefined,
      async (): Promise<number> => getMockPendingReviewCount(),
      AppConstants.SCENE_ADMIN
    );
  }
}

/** 内容审核域 Repository 单例 */
export const ReviewRepository: ReviewRepositoryImpl = new ReviewRepositoryImpl();
