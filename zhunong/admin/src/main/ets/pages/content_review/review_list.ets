/**
 * review_list - 内容审核列表（spec 3.3.3 / 10.8.3.3）
 *
 * - 顶部筛选栏：类型 Tab（全部 / 商品 / 直播 / 帖子 / 举报）
 *   + 状态 Tab（待审核 / 已通过 / 已驳回）
 * - LazyForEach 分页审核列表
 * - 列表项：内容类型 Tag + 内容标题 + 提交者 + 提交时间 + 状态 Tag
 *   （pending 黄 / approved 绿 / rejected 红）
 * - 点击 → `pages/content_review/review_detail?reviewId=xxx`
 * - 顶部"待审核"红点数字显示（从 `ReviewRepository.getPendingCount()` 获取）
 *
 * 越权防御（spec 10.8.8）：aboutToAppear 校验 super_admin / content_reviewer
 */

import { Logger, AppConstants, ToastUtil, TokenStore, NavigationHelper, RouteName, ListStateView } from 'common';
import { AdminInfo } from 'common';
import {
  ContentReview,
  ReviewContentType,
  AdminReviewStatus,
  AdminRole,
  REVIEW_CONTENT_TYPE_LABELS,
  REVIEW_STATUS_LABELS
} from '../../model/AdminModels';
import { ReviewRepository } from '../../repository/ReviewRepository';
import { ReviewListDataSource } from '../../viewmodel/ReviewListDataSource';

/** 跳转审核详情的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface ReviewDetailParam {
  reviewId: string;
}

/** 类型筛选项 */
interface TypeFilterOption {
  value: 'all' | ReviewContentType;
  label: string;
}

/** 状态筛选项 */
interface StatusFilterOption {
  value: AdminReviewStatus;
  label: string;
}

@ComponentV2
export struct ReviewList {
  /** 列表数据源（spec 10.11.4 Step 4：BaseDataSource + LazyForEach + 4 态状态机） */
  private dataSource: ReviewListDataSource = new ReviewListDataSource();
  /** 类型筛选 */
  @Local typeFilter: 'all' | ReviewContentType = 'all';
  /** 状态筛选（默认待审核） */
  @Local statusFilter: AdminReviewStatus = 'pending';
  /** 待审核数（红点显示，spec 10.8.3.3，由 ReviewRepository 独立加载） */
  @Local pendingCount: number = 0;

  /** 类型选项 */
  private typeOptions: TypeFilterOption[] = [
    { value: 'all', label: '全部' },
    { value: 'product', label: '商品' },
    { value: 'live', label: '直播' },
    { value: 'post', label: '帖子' },
    { value: 'report', label: '举报' }
  ];

  /** 状态选项 */
  private statusOptions: StatusFilterOption[] = [
    { value: 'pending', label: '待审核' },
    { value: 'approved', label: '已通过' },
    { value: 'rejected', label: '已驳回' }
  ];

  async aboutToAppear(): Promise<void> {
    // 越权防御（spec 10.8.8）
    const adminInfo: AdminInfo | null = await TokenStore.getAdminInfo();
    if (!adminInfo) {
      ToastUtil.warning('请先登录');
      NavigationHelper.replace(RouteName.ADMIN_LOGIN);
      return;
    }
    const allowedRoles: AdminRole[] = ['super_admin', 'content_reviewer'];
    if (allowedRoles.indexOf(adminInfo.role as AdminRole) < 0) {
      ToastUtil.warning('无权限访问该页面');
      NavigationHelper.pop();
      return;
    }
    Logger.info(AppConstants.SCENE_ADMIN, { action: 'review_list_appear', adminId: adminInfo.adminId, role: adminInfo.role });
    // 并行加载待审核数 + 列表
    await Promise.all([
      this.loadPendingCount(),
      this.refresh()
    ]);
  }

  /** 加载待审核数（spec 10.8.3.3：红点数字） */
  private async loadPendingCount(): Promise<void> {
    try {
      this.pendingCount = await ReviewRepository.getPendingCount();
    } catch (err) {
      Logger.error(AppConstants.SCENE_ADMIN, { action: 'load_pending_count_fail', error: (err as Error).message });
    }
  }

  /** 刷新 */
  private async refresh(): Promise<void> {
    this.dataSource.setType(this.typeFilter);
    this.dataSource.setStatus(this.statusFilter);
    await this.dataSource.refresh();
  }

  /** 切换类型筛选 */
  private async onTypeChange(value: 'all' | ReviewContentType): Promise<void> {
    this.typeFilter = value;
    await this.refresh();
  }

  /** 切换状态筛选 */
  private async onStatusChange(value: AdminReviewStatus): Promise<void> {
    this.statusFilter = value;
    await this.refresh();
  }

  /** 跳转审核详情 */
  private gotoDetail(reviewId: string): void {
    const param: ReviewDetailParam = { reviewId: reviewId };
    NavigationHelper.push(RouteName.ADMIN_REVIEW_DETAIL, param);
  }

  /** 状态 Tag 颜色（spec 10.8.3.3：pending 黄 / approved 绿 / rejected 红） */
  private statusBg(status: AdminReviewStatus): string {
    if (status === 'pending') {
      return 'rgba(255,193,7,0.15)';
    } else if (status === 'approved') {
      return 'rgba(76,175,80,0.15)';
    }
    return 'rgba(244,67,54,0.15)';
  }

  private statusColor(status: AdminReviewStatus): string {
    if (status === 'pending') {
      return '#FFC107';
    } else if (status === 'approved') {
      return '#4CAF50';
    }
    return '#F44336';
  }

  /** 类型 Tag 颜色 */
  private typeBg(type: ReviewContentType): string {
    if (type === 'product') {
      return 'rgba(76,175,80,0.12)';
    } else if (type === 'live') {
      return 'rgba(255,152,0,0.12)';
    } else if (type === 'post') {
      return 'rgba(33,150,243,0.12)';
    }
    return 'rgba(244,67,54,0.12)';
  }

  private typeColor(type: ReviewContentType): string {
    if (type === 'product') {
      return '#4CAF50';
    } else if (type === 'live') {
      return '#FF9800';
    } else if (type === 'post') {
      return '#2196F3';
    }
    return '#F44336';
  }

  /** 格式化时间 */
  private formatTime(ts: number): string {
    const d: Date = new Date(ts);
    const m: string = (d.getMonth() + 1).toString().padStart(2, '0');
    const day: string = d.getDate().toString().padStart(2, '0');
    const hh: string = d.getHours().toString().padStart(2, '0');
    const mi: string = d.getMinutes().toString().padStart(2, '0');
    return `${m}-${day} ${hh}:${mi}`;
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        this.TypeFilterBar()
        this.StatusFilterBar()
        // spec 10.11.4 Step 4：4 态状态机（error / loading / empty / list）
        if (this.dataSource.getLoadFailed()) {
          ListStateView({ state: 'error', onRefresh: () => this.refresh() })
        } else if (this.dataSource.getIsFirstLoad()) {
          ListStateView({ state: 'loading' })
        } else if (this.dataSource.totalCount() === 0) {
          ListStateView({ state: 'empty', emptyUseEmoji: true, emptyEmoji: '📭', emptyText: `暂无${REVIEW_STATUS_LABELS[this.statusFilter]}内容`, emptyActionText: '刷新', onEmptyAction: () => this.refresh() })
        } else {
          this.ReviewListView()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 顶部导航（含待审核红点） */
  @Builder
  TopBar() {
    Row({ space: 12 }) {
      Text('‹')
        .fontSize(28)
        .fontColor($r('app.color.color_text_primary'))
        .onClick(() => NavigationHelper.pop())
      Text('内容审核')
        .fontSize(18)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
      // 待审核红点（spec 10.8.3.3）
      if (this.pendingCount > 0) {
        Row({ space: 4 }) {
          Text('🔔')
            .fontSize(12)
          Text(`${this.pendingCount}`)
            .fontSize(12)
            .fontColor(Color.White)
            .backgroundColor($r('app.color.color_error'))
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(8)
            .fontWeight(FontWeight.Bold)
        }
        .alignItems(VerticalAlign.Center)
      }
      Text(`共 ${this.dataSource.totalCount()} 条`)
        .fontSize(12)
        .fontColor($r('app.color.color_text_secondary'))
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** 类型筛选栏 */
  @Builder
  TypeFilterBar() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.typeOptions, (opt: TypeFilterOption) => {
          Text(opt.label)
            .fontSize(12)
            .fontColor(this.typeFilter === opt.value ? Color.White : $r('app.color.color_text_secondary'))
            .backgroundColor(this.typeFilter === opt.value ? $r('app.color.color_primary') : $r('app.color.color_bg_card'))
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(14)
            .onClick(() => { this.onTypeChange(opt.value); })
        }, (opt: TypeFilterOption) => opt.value)
      }
      .padding({ left: 12, right: 12 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .height(44)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 状态筛选栏 */
  @Builder
  StatusFilterBar() {
    Row({ space: 0 }) {
      ForEach(this.statusOptions, (opt: StatusFilterOption, idx: number) => {
        Column({ space: 4 }) {
          Text(opt.label)
            .fontSize(13)
            .fontColor(this.statusFilter === opt.value ? $r('app.color.color_primary') : $r('app.color.color_text_secondary'))
            .fontWeight(this.statusFilter === opt.value ? FontWeight.Bold : FontWeight.Regular)
          // 下划线指示器
          Column()
            .width(this.statusFilter === opt.value ? 24 : 0)
            .height(2)
            .backgroundColor($r('app.color.color_primary'))
            .borderRadius(1)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 8, bottom: 8 })
        .onClick(() => { this.onStatusChange(opt.value); })
      }, (opt: StatusFilterOption) => opt.value)
    }
    .width('100%')
    .backgroundColor($r('app.color.color_bg_card'))
    .border({ width: { bottom: 0.5 }, color: $r('app.color.color_divider') })
  }

  /** 审核列表 */
  @Builder
  ReviewListView() {
    List({ space: 8 }) {
      LazyForEach(this.dataSource, (review: ContentReview) => {
        ListItem() {
          this.ReviewItemCard(review)
        }
      }, (review: ContentReview) => `${review.reviewId}_${review.status}_${review.submittedAt}`)

      // 加载更多 / 加载中 / 没有更多
      ListItem() {
        if (this.dataSource.getIsLoading()) {
          Row({ space: 8 }) {
            LoadingProgress().width(20).height(20)
            Text('加载中...')
              .fontSize(12)
              .fontColor($r('app.color.color_text_secondary'))
          }
          .width('100%')
          .height(48)
          .justifyContent(FlexAlign.Center)
        } else if (this.dataSource.getHasMore()) {
          Text('上拉加载更多')
            .fontSize(12)
            .fontColor($r('app.color.color_text_hint'))
            .width('100%')
            .height(48)
            .textAlign(TextAlign.Center)
            .onClick(() => this.dataSource.loadMore())
        } else {
          Text('没有更多了')
            .fontSize(12)
            .fontColor($r('app.color.color_text_hint'))
            .width('100%')
            .height(48)
            .textAlign(TextAlign.Center)
        }
      }
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 12, right: 12, top: 8 })
    .cachedCount(AppConstants.LIST_CACHED_COUNT)
    .onReachEnd(() => this.dataSource.loadMore())
  }

  /** 审核项卡片 */
  @Builder
  ReviewItemCard(review: ContentReview) {
    Column({ space: 8 }) {
      // 第一行：类型 Tag + 标题 + 状态 Tag
      Row({ space: 8 }) {
        Text(REVIEW_CONTENT_TYPE_LABELS[review.contentType])
          .fontSize(10)
          .fontColor(this.typeColor(review.contentType))
          .backgroundColor(this.typeBg(review.contentType))
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(4)
        Text(review.contentTitle)
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(REVIEW_STATUS_LABELS[review.status])
          .fontSize(10)
          .fontColor(this.statusColor(review.status))
          .backgroundColor(this.statusBg(review.status))
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(4)
      }
      .width('100%')

      // 第二行：内容预览
      if (review.contentPreview && review.contentPreview.length > 0) {
        Text(review.contentPreview)
          .fontSize(11)
          .fontColor($r('app.color.color_text_secondary'))
          .width('100%')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }

      // 第三行：提交者 + 时间
      Row({ space: 8 }) {
        Text(`提交者：${review.submitterNickname}`)
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
          .layoutWeight(1)
        Text(this.formatTime(review.submittedAt))
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')

      // 已审核时展示审核员
      if (review.status !== 'pending' && review.reviewerNickname) {
        Text(`审核员：${review.reviewerNickname}`)
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
          .width('100%')
      }

      // 已驳回时展示驳回原因
      if (review.status === 'rejected' && review.rejectReason) {
        Text(`⚠ 驳回原因：${review.rejectReason}`)
          .fontSize(11)
          .fontColor($r('app.color.color_error'))
          .width('100%')
      }
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
    .onClick(() => {
      this.gotoDetail(review.reviewId);
    })
  }

}
