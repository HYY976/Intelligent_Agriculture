/**
 * review_detail - 内容审核详情（spec 3.3.3 / 10.8.3.3）
 *
 * - 顶部：内容基本信息卡（类型 + 标题 + 提交者信息 + 提交时间）
 * - 中部：内容详情展示区（按 contentType 渲染：
 *   商品图+标题+描述 / 直播封面+标题+介绍 / 帖子内容+图片 / 举报原因+目标内容）
 * - 历史审核记录列表（如有多次提交，展示完整流转记录）
 * - 底部固定操作栏（仅 pending 状态显示）：
 *   - 通过按钮（绿）→ 调 `ReviewRepository.approveReview(reviewId)`
 *   - 驳回按钮（红）→ 弹 AlertDialog 选驳回原因
 *     - 预设原因 Radio：涉嫌违规 / 图片不清晰 / 描述不符 / 敏感词 / 其他
 *     - 自定义描述 TextArea（最多 200 字，选"其他"时必填）
 *     - 确认按钮调 `ReviewRepository.rejectReview(reviewId, reason, description)`
 * - 已审核内容：底部显示"已审核"状态 + 审核员 + 审核时间 + 驳回原因（如已驳回）
 *
 * 越权防御（spec 10.8.8）：aboutToAppear 校验 super_admin / content_reviewer
 */

import { Logger, AppConstants, ToastUtil, TokenStore, AdminRoutes, NavigationHelper, RouteName, RouterParam, ListStateView } from 'common';
import { AdminInfo } from 'common';
import {
  ReviewDetailAggregate,
  ReviewHistoryItem,
  ReviewContentType,
  AdminReviewStatus,
  AdminRole,
  ReviewRejectRequest,
  REVIEW_CONTENT_TYPE_LABELS,
  REVIEW_STATUS_LABELS,
  PRESET_REJECT_REASONS
} from '../../model/AdminModels';
import { ReviewRepository } from '../../repository/ReviewRepository';

/** 预设驳回原因项 */
interface RejectReasonOption {
  value: string;
  label: string;
}

@ComponentV2
export struct ReviewDetail {
  /** 路由参数：审核 ID */
  @Local reviewId: string = '';
  /** 详情聚合数据 */
  @Local detail: ReviewDetailAggregate | null = null;
  /** 是否正在加载 */
  @Local isLoading: boolean = false;
  /** 加载失败 */
  @Local loadFailed: boolean = false;
  /** 是否正在审核（通过/驳回） */
  @Local isProcessing: boolean = false;
  /** 是否展示驳回对话框 */
  @Local showRejectDialog: boolean = false;
  /** 选中的驳回原因 */
  @Local selectedReason: string = '';
  /** 自定义描述 */
  @Local rejectDescription: string = '';

  /** 预设驳回原因选项 */
  private rejectReasonOptions: RejectReasonOption[] = PRESET_REJECT_REASONS.map(
    (reason: string): RejectReasonOption => {
      return { value: reason, label: reason };
    }
  );

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
    // 读取路由参数
    const params = NavigationHelper.getParam<Record<string, string>>();
    if (params && params.reviewId) {
      this.reviewId = params.reviewId;
    }
    Logger.info(AppConstants.SCENE_ADMIN, { action: 'review_detail_appear', adminId: adminInfo.adminId, reviewId: this.reviewId });
    await this.loadDetail();
  }

  /** 加载详情 */
  private async loadDetail(): Promise<void> {
    if (this.reviewId.length === 0) {
      ToastUtil.warning('缺少审核 ID');
      NavigationHelper.pop();
      return;
    }
    this.isLoading = true;
    this.loadFailed = false;
    try {
      this.detail = await ReviewRepository.getReviewDetail(this.reviewId);
      if (!this.detail) {
        ToastUtil.warning('审核记录不存在');
        NavigationHelper.pop();
        return;
      }
    } catch (err) {
      this.loadFailed = true;
      Logger.error(AppConstants.SCENE_ADMIN, { action: 'load_review_detail_fail', error: (err as Error).message });
    } finally {
      this.isLoading = false;
    }
  }

  /** 点击通过 */
  private async onClickApprove(): Promise<void> {
    this.isProcessing = true;
    try {
      await ReviewRepository.approveReview(this.reviewId);
      ToastUtil.success('已通过');
      Logger.info(AppConstants.SCENE_ADMIN, { action: 'review_approve', reviewId: this.reviewId });
      NavigationHelper.pop();
    } catch (err) {
      Logger.error(AppConstants.SCENE_ADMIN, { action: 'review_approve_fail', error: (err as Error).message });
      ToastUtil.error('操作失败');
    } finally {
      this.isProcessing = false;
    }
  }

  /** 点击驳回（弹对话框） */
  private onClickReject(): void {
    this.selectedReason = '';
    this.rejectDescription = '';
    this.showRejectDialog = true;
  }

  /** 关闭驳回对话框 */
  private closeRejectDialog(): void {
    this.showRejectDialog = false;
  }

  /** 选择驳回原因 */
  private onSelectReason(reason: string): void {
    this.selectedReason = reason;
  }

  /** 描述输入变更 */
  private onDescriptionChange(value: string): void {
    if (value.length > 200) {
      this.rejectDescription = value.substring(0, 200);
    } else {
      this.rejectDescription = value;
    }
  }

  /** 驳回表单校验 */
  private validateRejectForm(): boolean {
    if (this.selectedReason.length === 0) {
      ToastUtil.warning('请选择驳回原因');
      return false;
    }
    if (this.selectedReason === '其他' && this.rejectDescription.trim().length === 0) {
      ToastUtil.warning('选择"其他"时必须填写描述');
      return false;
    }
    return true;
  }

  /** 确认驳回 */
  private async doReject(): Promise<void> {
    if (!this.validateRejectForm()) {
      return;
    }
    this.showRejectDialog = false;
    this.isProcessing = true;
    try {
      const req: ReviewRejectRequest = { reason: this.selectedReason };
      if (this.rejectDescription.trim().length > 0) {
        req.description = this.rejectDescription.trim();
      }
      await ReviewRepository.rejectReview(this.reviewId, req);
      ToastUtil.success('已驳回');
      Logger.info(AppConstants.SCENE_ADMIN, { action: 'review_reject', reviewId: this.reviewId, reason: this.selectedReason });
      NavigationHelper.pop();
    } catch (err) {
      Logger.error(AppConstants.SCENE_ADMIN, { action: 'review_reject_fail', error: (err as Error).message });
      ToastUtil.error('操作失败');
    } finally {
      this.isProcessing = false;
    }
  }

  /** 状态 Tag 颜色 */
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

  /** 历史状态文案（含流转说明） */
  private historyStatusText(item: ReviewHistoryItem): string {
    return REVIEW_STATUS_LABELS[item.status];
  }

  /** 格式化时间 */
  private formatTime(ts: number): string {
    const d: Date = new Date(ts);
    const y: number = d.getFullYear();
    const m: string = (d.getMonth() + 1).toString().padStart(2, '0');
    const day: string = d.getDate().toString().padStart(2, '0');
    const hh: string = d.getHours().toString().padStart(2, '0');
    const mi: string = d.getMinutes().toString().padStart(2, '0');
    return `${y}-${m}-${day} ${hh}:${mi}`;
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          this.TopBar()
          if (this.loadFailed) {
            ListStateView({ state: 'error', onRefresh: () => this.loadDetail() })
          } else if (!this.detail) {
            ListStateView({ state: 'loading' })
          } else {
            this.ContentScroll()
            this.BottomActionBar()
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.color_bg_page'))

        // 驳回对话框
        if (this.showRejectDialog) {
          this.RejectDialog()
        }
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
  }

  /** 顶部导航 */
  @Builder
  TopBar() {
    Row({ space: 12 }) {
      Text('‹')
        .fontSize(28)
        .fontColor($r('app.color.color_text_primary'))
        .onClick(() => NavigationHelper.pop())
      Text('审核详情')
        .fontSize(18)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
      Text(this.reviewId)
        .fontSize(11)
        .fontColor($r('app.color.color_text_hint'))
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** 内容滚动区 */
  @Builder
  ContentScroll() {
    Scroll() {
      Column({ space: 12 }) {
        this.BasicInfoCard()
        this.ContentDetailCard()
        this.HistoryCard()
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 12, bottom: 12 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  /** 基本信息 */
  @Builder
  BasicInfoCard() {
    Column({ space: 8 }) {
      // 类型 + 状态
      Row({ space: 8 }) {
        Text(REVIEW_CONTENT_TYPE_LABELS[this.detail!.review.contentType])
          .fontSize(10)
          .fontColor(this.typeColor(this.detail!.review.contentType))
          .backgroundColor(this.typeBg(this.detail!.review.contentType))
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(4)
        Text(REVIEW_STATUS_LABELS[this.detail!.review.status])
          .fontSize(10)
          .fontColor(this.statusColor(this.detail!.review.status))
          .backgroundColor(this.statusBg(this.detail!.review.status))
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(4)
        Text(this.detail!.review.contentId)
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
          .layoutWeight(1)
          .textAlign(TextAlign.RIGHT)
      }
      .width('100%')

      Text(this.detail!.review.contentTitle)
        .fontSize(16)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .width('100%')

      Divider().color($r('app.color.color_divider')).margin({ top: 4, bottom: 4 })

      // 提交者信息
      Row({ space: 12 }) {
        Text(`提交者：${this.detail!.review.submitterNickname}`)
          .fontSize(12)
          .fontColor($r('app.color.color_text_secondary'))
          .layoutWeight(1)
        Text(this.formatTime(this.detail!.review.submittedAt))
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')

      // 已审核时展示审核员与时间
      if (this.detail!.review.status !== 'pending' && this.detail!.review.reviewerNickname) {
        Row({ space: 12 }) {
          Text(`审核员：${this.detail!.review.reviewerNickname}`)
            .fontSize(12)
            .fontColor($r('app.color.color_text_secondary'))
            .layoutWeight(1)
          if (this.detail!.review.reviewedAt) {
            Text(this.formatTime(this.detail!.review.reviewedAt))
              .fontSize(11)
              .fontColor($r('app.color.color_text_hint'))
          }
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 内容详情展示区（按 contentType 分支渲染） */
  @Builder
  ContentDetailCard() {
    Column({ space: 8 }) {
      Text('内容详情')
        .fontSize(14)
        .fontColor($r('app.color.color_text_secondary'))
        .alignSelf(ItemAlign.Start)

      // 内容预览
      if (this.detail!.review.contentPreview && this.detail!.review.contentPreview.length > 0) {
        Text(this.detail!.review.contentPreview)
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
          .width('100%')
          .lineHeight(20)
      }

      // 内容图片（如有）
      if (this.detail!.review.contentImages && this.detail!.review.contentImages.length > 0) {
        Row({ space: 8 }) {
          ForEach(this.detail!.review.contentImages, (imgKey: string, idx: number) => {
            Column({ space: 4 }) {
              Text('🖼')
                .fontSize(24)
              Text('图片')
                .fontSize(9)
                .fontColor($r('app.color.color_text_hint'))
            }
            .width(72)
            .height(72)
            .borderRadius(8)
            .backgroundColor($r('app.color.color_bg_page'))
            .alignItems(HorizontalAlign.Center)
            .justifyContent(FlexAlign.Center)
          }, (imgKey: string, idx: number) => `${imgKey}_${idx}`)
        }
        .width('100%')
      }

      // 内容类型说明
      Text(`（内容类型：${REVIEW_CONTENT_TYPE_LABELS[this.detail!.review.contentType]}）`)
        .fontSize(11)
        .fontColor($r('app.color.color_text_hint'))
        .width('100%')
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 历史审核记录 */
  @Builder
  HistoryCard() {
    Column({ space: 8 }) {
      Row() {
        Text('审核历史')
          .fontSize(14)
          .fontColor($r('app.color.color_text_secondary'))
          .layoutWeight(1)
        Text(`${this.detail!.history.length} 条`)
          .fontSize(10)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')

      ForEach(this.detail!.history, (item: ReviewHistoryItem, idx: number) => {
        this.HistoryItem(item, idx)
      }, (item: ReviewHistoryItem, idx: number) => `${item.reviewId}_${idx}`)
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 历史记录项 */
  @Builder
  HistoryItem(item: ReviewHistoryItem, idx: number) {
    Column({ space: 4 }) {
      Row({ space: 8 }) {
        // 序号圆点
        Stack() {
          Text(`${idx + 1}`)
            .fontSize(11)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
        }
        .width(20)
        .height(20)
        .borderRadius(10)
        .backgroundColor($r('app.color.color_primary'))
        .alignContent(Alignment.Center)

        Column({ space: 2 }) {
          Row({ space: 6 }) {
            Text(this.historyStatusText(item))
              .fontSize(12)
              .fontColor(this.statusColor(item.status))
              .fontWeight(FontWeight.Medium)
            if (item.reviewerNickname) {
              Text(`· ${item.reviewerNickname}`)
                .fontSize(11)
                .fontColor($r('app.color.color_text_hint'))
            }
          }
          .width('100%')

          Text(item.note)
            .fontSize(11)
            .fontColor($r('app.color.color_text_secondary'))
            .width('100%')

          if (item.rejectReason) {
            Text(`驳回原因：${item.rejectReason}`)
              .fontSize(11)
              .fontColor($r('app.color.color_error'))
              .width('100%')
          }

          if (item.rejectDescription) {
            Text(`说明：${item.rejectDescription}`)
              .fontSize(11)
              .fontColor($r('app.color.color_text_hint'))
              .width('100%')
          }

          Text(this.formatTime(item.reviewedAt))
            .fontSize(10)
            .fontColor($r('app.color.color_text_hint'))
            .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .border({ width: { bottom: 0.5 }, color: $r('app.color.color_divider') })
  }

  /** 底部操作栏 */
  @Builder
  BottomActionBar() {
    if (this.detail && this.detail!.review.status === 'pending') {
      // 待审核：展示通过 + 驳回按钮
      Row({ space: 12 }) {
        Button('驳回')
          .layoutWeight(1)
          .height(44)
          .borderRadius(22)
          .backgroundColor($r('app.color.color_bg_card'))
          .fontColor($r('app.color.color_error'))
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .enabled(!this.isProcessing)
          .onClick(() => this.onClickReject())
        Button('通过')
          .layoutWeight(1)
          .height(44)
          .borderRadius(22)
          .backgroundColor($r('app.color.color_primary'))
          .fontColor(Color.White)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .enabled(!this.isProcessing)
          .onClick(() => this.onClickApprove())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor($r('app.color.color_bg_card'))
      .border({ width: { top: 0.5 }, color: $r('app.color.color_divider') })
    } else if (this.detail && this.detail!.review.status !== 'pending') {
      // 已审核：展示已审核状态
      Row({ space: 12 }) {
        Text(`✓ ${REVIEW_STATUS_LABELS[this.detail!.review.status]}`)
          .fontSize(14)
          .fontColor(this.statusColor(this.detail!.review.status))
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
        if (this.detail!.review.rejectReason) {
          Text(`驳回原因：${this.detail!.review.rejectReason}`)
            .fontSize(11)
            .fontColor($r('app.color.color_error'))
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor($r('app.color.color_bg_card'))
      .border({ width: { top: 0.5 }, color: $r('app.color.color_divider') })
      .alignItems(VerticalAlign.Center)
    }
  }

  /** 驳回对话框（预设原因 Radio + 描述 TextArea） */
  @Builder
  RejectDialog() {
    Stack({ alignContent: Alignment.Center }) {
      // 遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => { this.closeRejectDialog(); })

      // 对话框内容
      Column({ space: 12 }) {
        Text('驳回审核')
          .fontSize(16)
          .fontColor($r('app.color.color_error'))
          .fontWeight(FontWeight.Medium)

        Text('请选择驳回原因：')
          .fontSize(12)
          .fontColor($r('app.color.color_text_secondary'))
          .alignSelf(ItemAlign.Start)

        // 预设原因 Radio
        Column({ space: 8 }) {
          ForEach(this.rejectReasonOptions, (opt: RejectReasonOption) => {
            Row({ space: 8 }) {
              // Radio 外圈（先绘制，后绘制的填充点会盖在上面）
              Stack() {
                Column()
                  .width(20)
                  .height(20)
                  .borderRadius(10)
                  .border({ width: 1.5, color: this.selectedReason === opt.value ? $r('app.color.color_primary') : $r('app.color.color_text_hint') })
                  .backgroundColor(Color.Transparent)
                // 选中态填充点（后绘制，盖在外圈上）
                if (this.selectedReason === opt.value) {
                  Column()
                    .width(10)
                    .height(10)
                    .borderRadius(5)
                    .backgroundColor($r('app.color.color_primary'))
                }
              }
              .width(20)
              .height(20)
              .alignContent(Alignment.Center)

              Text(opt.label)
                .fontSize(13)
                .fontColor($r('app.color.color_text_primary'))
                .layoutWeight(1)
            }
            .width('100%')
            .onClick(() => { this.onSelectReason(opt.value); })
          }, (opt: RejectReasonOption) => opt.value)
        }
        .width('100%')
        .padding(8)
        .borderRadius(8)
        .backgroundColor($r('app.color.color_bg_page'))

        // 自定义描述
        Column({ space: 4 }) {
          Row() {
            Text('自定义描述')
              .fontSize(12)
              .fontColor($r('app.color.color_text_secondary'))
              .layoutWeight(1)
            Text(`选"其他"时必填 · ${this.rejectDescription.length}/200`)
              .fontSize(10)
              .fontColor(this.rejectDescription.length > 200 ? $r('app.color.color_error') : $r('app.color.color_text_hint'))
          }
          .width('100%')
          TextArea({ text: this.rejectDescription, placeholder: '请输入驳回描述（选"其他"时必填，最多 200 字）' })
            .height(80)
            .borderRadius(8)
            .backgroundColor($r('app.color.color_bg_page'))
            .padding(8)
            .fontSize(13)
            .maxLength(200)
            .onChange((value: string) => { this.onDescriptionChange(value); })
        }
        .width('100%')

        // 按钮区
        Row({ space: 8 }) {
          Button('取消')
            .layoutWeight(1)
            .height(40)
            .borderRadius(20)
            .backgroundColor($r('app.color.color_bg_page'))
            .fontColor($r('app.color.color_text_primary'))
            .fontSize(14)
            .onClick(() => { this.closeRejectDialog(); })
          Button('确认驳回')
            .layoutWeight(1)
            .height(40)
            .borderRadius(20)
            .backgroundColor($r('app.color.color_error'))
            .fontColor(Color.White)
            .fontSize(14)
            .onClick(() => { this.doReject(); })
        }
        .width('100%')
      }
      .width('88%')
      .padding(20)
      .borderRadius(12)
      .backgroundColor($r('app.color.color_bg_card'))
    }
    .width('100%')
    .height('100%')
  }
}
