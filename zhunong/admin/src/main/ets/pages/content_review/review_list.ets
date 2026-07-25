/**
 * review_list - 内容审核列表（UI 复刻 qunong-harmony-app/pages/admin-review.html）
 * 遵循 spec 3.3.3 / 10.8.3.3：
 *  - 顶部统计行：待审核 / 今日已审 / 待处理举报
 *  - 状态筛选 Tab：待审核 / 已通过 / 已驳回 / 举报（横滑胶囊 + 计数徽标）
 *  - LazyForEach 分页审核列表
 *  - 列表项：头像 + 提交者 + 类型 pill + 时间 + 封面图 + 标题 + 描述 + 价格 + 审核要点框 + 操作栏
 *  - 操作栏：驳回（线框）+ 详情（链接）+ 通过（绿底）
 *
 * UI 设计要点（对齐 admin-review.html）：
 *  - 顶栏：圆形返回键 + 居中 "内容审核" + "历史" 文字按钮
 *  - 3 列统计卡（带竖线分隔，待审核红 / 待处理举报橙）
 *  - 状态筛选 Tab（激活态墨黑底 + 黄色计数徽标）
 *  - 审核卡：白底圆角 + 32 头像 + 作者 + 类型 pill + 时间 + 140 封面图 + 标题 + 描述 + 黄底审核要点框 + 操作栏
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

/** 状态筛选项（含计数） */
interface StatusFilterOption {
  value: AdminReviewStatus | 'report';
  label: string;
  count: number;
}

/** 统计项 */
interface OverviewStat {
  num: string;
  lab: string;
  /** 颜色类型 */
  colorType: 'live' | 'warn' | 'ink';
}

/** 审核要点项 */
interface ReviewPoint {
  /** 要点文本 */
  text: string;
  /** 是否通过 */
  isOk: boolean;
}

@ComponentV2
export struct ReviewList {
  /** 列表数据源（spec 10.11.4 Step 4：BaseDataSource + LazyForEach + 4 态状态机） */
  private dataSource: ReviewListDataSource = new ReviewListDataSource();
  /** 状态筛选（默认待审核，对齐设计稿） */
  @Local statusFilter: AdminReviewStatus | 'report' = 'pending';
  /** 待审核数（统计行） */
  @Local pendingCount: number = 12;
  /** 今日已审数 */
  @Local todayReviewedCount: number = 48;
  /** 待处理举报数 */
  @Local pendingReportCount: number = 3;

  /** 统计行数据 */
  private getOverviewStats(): OverviewStat[] {
    return [
      { num: `${this.pendingCount}`, lab: '待审核', colorType: 'live' },
      { num: `${this.todayReviewedCount}`, lab: '今日已审', colorType: 'ink' },
      { num: `${this.pendingReportCount}`, lab: '待处理举报', colorType: 'warn' }
    ];
  }

  /** 状态筛选选项 */
  private getStatusOptions(): StatusFilterOption[] {
    return [
      { value: 'pending', label: '待审核', count: 12 },
      { value: 'approved', label: '已通过', count: 126 },
      { value: 'rejected', label: '已驳回', count: 8 },
      { value: 'report', label: '举报', count: 3 }
    ];
  }

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

  /** 加载待审核数 */
  private async loadPendingCount(): Promise<void> {
    try {
      const count = await ReviewRepository.getPendingCount();
      this.pendingCount = count > 0 ? count : 12;
    } catch (err) {
      Logger.error(AppConstants.SCENE_ADMIN, { action: 'load_pending_count_fail', error: (err as Error).message });
    }
  }

  /** 刷新 */
  private async refresh(): Promise<void> {
    // 将状态筛选映射到 dataSource
    if (this.statusFilter === 'report') {
      this.dataSource.setType('report');
      this.dataSource.setStatus('pending');
    } else {
      this.dataSource.setType('all');
      this.dataSource.setStatus(this.statusFilter);
    }
    await this.dataSource.refresh();
  }

  /** 切换状态筛选 */
  private async onStatusChange(value: AdminReviewStatus | 'report'): Promise<void> {
    this.statusFilter = value;
    await this.refresh();
  }

  /** 跳转审核详情 */
  private gotoDetail(reviewId: string): void {
    const param: ReviewDetailParam = { reviewId: reviewId };
    NavigationHelper.push(RouteName.ADMIN_REVIEW_DETAIL, param);
  }

  /** 直接通过（列表卡内快捷操作） */
  private async quickApprove(reviewId: string): Promise<void> {
    try {
      await ReviewRepository.approveReview(reviewId);
      ToastUtil.success('已通过');
      Logger.info(AppConstants.SCENE_ADMIN, { action: 'review_quick_approve', reviewId: reviewId });
      await this.dataSource.refresh();
    } catch (err) {
      Logger.error(AppConstants.SCENE_ADMIN, { action: 'review_quick_approve_fail', error: (err as Error).message });
      ToastUtil.error('操作失败');
    }
  }

  /** 直接驳回（列表卡内快捷操作，跳转详情页填写原因） */
  private quickReject(reviewId: string): void {
    this.gotoDetail(reviewId);
  }

  /** 格式化时间为相对时间（10分钟前 / 1小时前 / 月-日 时:分） */
  private formatRelativeTime(ts: number): string {
    const now: number = Date.now();
    const diff: number = now - ts;
    if (diff < 60000) {
      return '刚刚';
    }
    if (diff < 3600000) {
      return `${Math.floor(diff / 60000)}分钟前`;
    }
    if (diff < 86400000) {
      return `${Math.floor(diff / 3600000)}小时前`;
    }
    const d: Date = new Date(ts);
    const m: string = (d.getMonth() + 1).toString().padStart(2, '0');
    const day: string = d.getDate().toString().padStart(2, '0');
    const hh: string = d.getHours().toString().padStart(2, '0');
    const mi: string = d.getMinutes().toString().padStart(2, '0');
    return `${m}-${day} ${hh}:${mi}`;
  }

  /** 获取审核要点（Mock，根据内容类型返回要点列表） */
  private getReviewPoints(review: ContentReview): ReviewPoint[] {
    if (review.contentType === 'product') {
      return [
        { text: '价格合理', isOk: true },
        { text: '图片原创', isOk: true },
        { text: '无违规词', isOk: true },
        { text: '需人工确认产地证明', isOk: false }
      ];
    }
    if (review.contentType === 'post') {
      return [
        { text: '内容健康', isOk: true },
        { text: '无广告', isOk: true },
        { text: '可通过', isOk: true }
      ];
    }
    if (review.contentType === 'live') {
      return [
        { text: '封面合规', isOk: true },
        { text: '标题无误', isOk: true },
        { text: '需关注直播内容', isOk: false }
      ];
    }
    return [
      { text: '待人工核实', isOk: false }
    ];
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        this.OverviewStats()
        this.StatusFilterTabs()
        // spec 10.11.4 Step 4：4 态状态机（error / loading / empty / list）
        if (this.dataSource.getLoadFailed()) {
          ListStateView({ state: 'error', onRefresh: () => this.refresh() })
        } else if (this.dataSource.getIsFirstLoad()) {
          ListStateView({ state: 'loading' })
        } else if (this.dataSource.totalCount() === 0) {
          ListStateView({ state: 'empty', emptyUseEmoji: true, emptyEmoji: '📭', emptyText: '暂无审核内容', emptyActionText: '刷新', onEmptyAction: () => this.refresh() })
        } else {
          this.ReviewListView()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_cream'))
    }
    .hideTitleBar(true)
  }

  /** 顶部导航：圆形返回键 + 居中标题 + "历史"文字按钮 */
  @Builder
  TopBar() {
    Row() {
      Stack() {
        Text('‹')
          .fontSize(22)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .width(32)
      .height(32)
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor($r('app.color.color_bg_card'))
      .shadow(AppConstants.SHADOW_CARD)
      .onClick(() => NavigationHelper.pop())

      Text('内容审核')
        .fontSize(17)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Text('历史')
        .fontSize(13)
        .fontColor($r('app.color.color_text_2'))
        .fontWeight(FontWeight.Medium)
        .width(48)
        .textAlign(TextAlign.End)
        .onClick(() => {
          ToastUtil.info('历史记录开发中');
        })
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16, top: 4, bottom: 10 })
    .alignItems(VerticalAlign.Center)
  }

  /** 3 列统计卡（待审核/今日已审/待处理举报） */
  @Builder
  OverviewStats() {
    Row() {
      ForEach(this.getOverviewStats(), (stat: OverviewStat, index: number) => {
        Row() {
          Column({ space: 3 }) {
            Text(stat.num)
              .fontSize(20)
              .fontColor(stat.colorType === 'live'
                ? $r('app.color.color_live')
                : stat.colorType === 'warn'
                  ? $r('app.color.color_warn')
                  : $r('app.color.color_ink'))
              .fontWeight(FontWeight.Bold)
            Text(stat.lab)
              .fontSize(11)
              .fontColor($r('app.color.color_text_3'))
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          if (index < this.getOverviewStats().length - 1) {
            Column()
              .width(1)
              .height(28)
              .backgroundColor($r('app.color.color_line'))
          }
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }, (stat: OverviewStat, index: number) => `${stat.lab}_${index}`)
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .margin({ left: 16, right: 16, bottom: 12 })
    .alignItems(VerticalAlign.Center)
  }

  /** 状态筛选 Tab（横滑胶囊 + 计数徽标） */
  @Builder
  StatusFilterTabs() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.getStatusOptions(), (opt: StatusFilterOption) => {
          Row({ space: 5 }) {
            Text(opt.label)
              .fontSize(13)
              .fontColor(this.statusFilter === opt.value ? Color.White : $r('app.color.color_text_2'))
              .fontWeight(FontWeight.Medium)
            // 计数徽标
            Text(`${opt.count}`)
              .fontSize(11)
              .fontColor(this.statusFilter === opt.value ? $r('app.color.color_ink') : $r('app.color.color_text_2'))
              .fontWeight(FontWeight.Bold)
              .backgroundColor(this.statusFilter === opt.value ? $r('app.color.color_yellow') : $r('app.color.color_fill'))
              .height(18)
              .padding({ left: 5, right: 5 })
              .borderRadius(AppConstants.RADIUS_PILL)
              .textAlign(TextAlign.Center)
              .constraintSize({ minWidth: 18 })
          }
          .height(34)
          .padding({ left: 14, right: 14 })
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor(this.statusFilter === opt.value ? $r('app.color.color_cta_black') : $r('app.color.color_bg_card'))
          .shadow(AppConstants.SHADOW_CARD)
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.onStatusChange(opt.value);
          })
        }, (opt: StatusFilterOption) => opt.value)
      }
      .padding({ left: 16, right: 16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .padding({ bottom: 12 })
  }

  /** 审核列表 */
  @Builder
  ReviewListView() {
    List({ space: 14 }) {
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
              .fontColor($r('app.color.color_text_2'))
          }
          .width('100%')
          .height(48)
          .justifyContent(FlexAlign.Center)
        } else if (this.dataSource.getHasMore()) {
          Text('上拉加载更多')
            .fontSize(12)
            .fontColor($r('app.color.color_text_4'))
            .width('100%')
            .height(48)
            .textAlign(TextAlign.Center)
            .onClick(() => this.dataSource.loadMore())
        } else {
          Text('没有更多了')
            .fontSize(12)
            .fontColor($r('app.color.color_text_4'))
            .width('100%')
            .height(48)
            .textAlign(TextAlign.Center)
        }
      }
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 16, right: 16, top: 4 })
    .cachedCount(AppConstants.LIST_CACHED_COUNT)
    .onReachEnd(() => this.dataSource.loadMore())
  }

  /** 审核项卡片（完整设计：头像 + 作者 + pill + 时间 + 封面图 + 标题 + 描述 + 要点 + 操作栏） */
  @Builder
  ReviewItemCard(review: ContentReview) {
    Column({ space: 12 }) {
      // 1. 头部：头像 + 作者 + 类型 pill + 时间
      Row({ space: 8 }) {
        Image($r('app.media.avatar_farmer'))
          .width(32)
          .height(32)
          .borderRadius(16)
          .backgroundColor($r('app.color.color_fill'))
          .objectFit(ImageFit.Cover)
        Text(review.submitterNickname)
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: 100 })
        this.ContentTypePill(review.contentType)
        Blank()
        Text(this.formatRelativeTime(review.submittedAt))
          .fontSize(11)
          .fontColor($r('app.color.color_text_3'))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 2. 封面图（140h，圆角）
      Stack() {
        Text('🖼️')
          .fontSize(40)
          .fontColor($r('app.color.color_text_4'))
        // 内容类型角标
        Stack() {
          Text(this.getCoverBadge(review.contentType))
            .fontSize(10)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
        }
        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor(this.getCoverBadgeColor(review.contentType))
        .position({ x: 8, y: 8 })
      }
      .width('100%')
      .height(140)
      .borderRadius(AppConstants.RADIUS_MD)
      .backgroundColor($r('app.color.color_fill'))
      .alignContent(Alignment.Center)

      // 3. 标题
      Text(review.contentTitle)
        .fontSize(15)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .width('100%')

      // 4. 描述
      if (review.contentPreview && review.contentPreview.length > 0) {
        Text(review.contentPreview)
          .fontSize(13)
          .fontColor($r('app.color.color_text_2'))
          .width('100%')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .lineHeight(20)
      }

      // 5. 审核要点框（黄底 + 边框）
      this.ReviewPointsBox(review)

      // 6. 操作栏（驳回 + 详情 + 通过）
      Row({ space: 10 }) {
        // 驳回按钮（线框）
        Text('驳回')
          .fontSize(14)
          .fontColor($r('app.color.color_text_2'))
          .fontWeight(FontWeight.Bold)
          .backgroundColor($r('app.color.color_bg_card'))
          .border({ width: 1, color: $r('app.color.color_line_2') })
          .height(38)
          .padding({ left: 18, right: 18 })
          .borderRadius(AppConstants.RADIUS_MD)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.quickReject(review.reviewId);
          })

        // 详情链接
        Row({ space: 2 }) {
          Text('详情')
            .fontSize(13)
            .fontColor($r('app.color.color_text_3'))
            .fontWeight(FontWeight.Medium)
          Text('›')
            .fontSize(14)
            .fontColor($r('app.color.color_text_3'))
        }
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.gotoDetail(review.reviewId);
        })

        Blank()

        // 通过按钮（绿底）
        Text('通过')
          .fontSize(14)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
          .backgroundColor($r('app.color.color_green'))
          .height(38)
          .padding({ left: 22, right: 22 })
          .borderRadius(AppConstants.RADIUS_MD)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.quickApprove(review.reviewId);
          })
      }
      .width('100%')
      .padding({ top: 12 })
      .border({ width: { top: 1 }, color: $r('app.color.color_line') })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(14)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 内容类型 pill */
  @Builder
  ContentTypePill(type: ReviewContentType) {
    Text(REVIEW_CONTENT_TYPE_LABELS[type])
      .fontSize(11)
      .fontColor(type === 'post' ? $r('app.color.color_green_deep') : $r('app.color.color_info'))
      .backgroundColor(type === 'post' ? $r('app.color.color_green_soft') : $r('app.color.color_info_soft'))
      .padding({ left: 10, right: 10, top: 3, bottom: 3 })
      .borderRadius(AppConstants.RADIUS_PILL)
      .fontWeight(FontWeight.Medium)
  }

  /** 审核要点框（黄底 + 边框 + ✓/⚠ 标记列表） */
  @Builder
  ReviewPointsBox(review: ContentReview) {
    Column({ space: 6 }) {
      // 标题行
      Row({ space: 4 }) {
        Text('📋')
          .fontSize(12)
        Text('审核要点')
          .fontSize(12)
          .fontColor($r('app.color.color_yellow_text'))
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')

      // 要点列表
      ForEach(this.getReviewPoints(review), (point: ReviewPoint, index: number) => {
        Row({ space: 6 }) {
          Text(point.isOk ? '✓' : '⚠')
            .fontSize(12)
            .fontColor(point.isOk ? $r('app.color.color_green_deep') : $r('app.color.color_warn'))
            .fontWeight(FontWeight.Bold)
          Text(point.text)
            .fontSize(12)
            .fontColor($r('app.color.color_ink_2'))
            .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
      }, (point: ReviewPoint, index: number) => `${point.text}_${index}`)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .borderRadius(AppConstants.RADIUS_SM)
    .backgroundColor($r('app.color.color_yellow_tint'))
    .border({ width: 1, color: '#F5EBA8' })
    .alignItems(HorizontalAlign.Start)
  }

  /** 获取封面角标文案 */
  private getCoverBadge(type: ReviewContentType): string {
    if (type === 'live') {
      return '● LIVE';
    }
    if (type === 'product') {
      return '商品';
    }
    if (type === 'post') {
      return '笔记';
    }
    return '举报';
  }

  /** 获取封面角标颜色 */
  private getCoverBadgeColor(type: ReviewContentType): ResourceColor {
    if (type === 'live') {
      return $r('app.color.color_live');
    }
    if (type === 'product') {
      return $r('app.color.color_green');
    }
    if (type === 'post') {
      return $r('app.color.color_info');
    }
    return $r('app.color.color_warn');
  }
}
