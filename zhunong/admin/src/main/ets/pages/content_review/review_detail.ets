/**
 * review_detail - 内容审核详情（UI 复刻对齐 admin-review.html 设计语言）
 * 遵循 spec 3.3.3 / 10.8.3.3：
 *  - 顶部：内容基本信息卡（头像 + 提交者 + 类型 pill + 时间 + 封面图 + 标题 + 描述 + 审核要点框）
 *  - 中部：历史审核记录时间轴
 *  - 底部固定操作栏（仅 pending 显示）：驳回（弹模态）+ 通过（绿底）
 *  - 已审核：底部展示状态 + 审核员 + 时间 + 驳回原因
 *
 * UI 设计要点（对齐设计语言）：
 *  - 顶栏：圆形返回键 + 居中标题
 *  - 内容卡：白底圆角 + 32 头像 + 作者 + 类型 pill + 时间 + 140 封面图 + 标题 + 描述 + 黄底审核要点框
 *  - 历史时间轴：序号圆点 + 状态/审核员/原因/时间
 *  - 驳回弹窗使用方案 C 模式（@Local showRejectDialog + Stack + @Builder）
 *
 * 越权防御（spec 10.8.8）：aboutToAppear 校验 super_admin / content_reviewer
 */

import { Logger, AppConstants, ToastUtil, TokenStore, NavigationHelper, RouteName, ListStateView } from 'common';
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

/** 审核要点项 */
interface ReviewPoint {
  text: string;
  isOk: boolean;
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
  /** 是否展示驳回弹窗（方案 C：@Local + Stack + @Builder） */
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

  /** 点击驳回（弹模态） */
  private onClickReject(): void {
    this.selectedReason = '';
    this.rejectDescription = '';
    this.showRejectDialog = true;
  }

  /** 关闭驳回弹窗 */
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

  /** 获取审核要点（Mock） */
  private getReviewPoints(): ReviewPoint[] {
    if (!this.detail) {
      return [];
    }
    const type: ReviewContentType = this.detail.review.contentType;
    if (type === 'product') {
      return [
        { text: '价格合理', isOk: true },
        { text: '图片原创', isOk: true },
        { text: '无违规词', isOk: true },
        { text: '需人工确认产地证明', isOk: false }
      ];
    }
    if (type === 'post') {
      return [
        { text: '内容健康', isOk: true },
        { text: '无广告', isOk: true },
        { text: '可通过', isOk: true }
      ];
    }
    if (type === 'live') {
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
        .backgroundColor($r('app.color.color_cream'))

        // 驳回弹窗（方案 C：@Local showRejectDialog + Stack + @Builder）
        if (this.showRejectDialog) {
          this.RejectDialog()
        }
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
  }

  /** 顶部导航：圆形返回键 + 居中标题 */
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

      Text('审核详情')
        .fontSize(17)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 占位保持标题居中
      Column().width(32).height(32)
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16, top: 4, bottom: 10 })
    .alignItems(VerticalAlign.Center)
  }

  /** 内容滚动区 */
  @Builder
  ContentScroll() {
    Scroll() {
      Column({ space: 14 }) {
        this.ContentCard()
        this.HistoryCard()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 80 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .align(Alignment.Top)
  }

  /** 内容基本信息卡（含头像/作者/类型/时间/封面图/标题/描述/审核要点） */
  @Builder
  ContentCard() {
    Column({ space: 12 }) {
      // 1. 头部：头像 + 作者 + 类型 pill + 时间
      Row({ space: 8 }) {
        Image($r('app.media.avatar_farmer'))
          .width(32)
          .height(32)
          .borderRadius(16)
          .backgroundColor($r('app.color.color_fill'))
          .objectFit(ImageFit.Cover)
        Text(this.detail!.review.submitterNickname)
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: 100 })
        this.ContentTypePill(this.detail!.review.contentType)
        this.StatusPill(this.detail!.review.status)
        Blank()
        Text(this.formatTime(this.detail!.review.submittedAt))
          .fontSize(11)
          .fontColor($r('app.color.color_text_3'))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 2. 封面图（140h）
      Stack() {
        Image($r('app.media.icon_image'))
          .width(40)
          .height(40)
          .fillColor($r('app.color.color_text_4'))
        Stack() {
          Text(this.getCoverBadge(this.detail!.review.contentType))
            .fontSize(10)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
        }
        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor(this.getCoverBadgeColor(this.detail!.review.contentType))
        .position({ x: 8, y: 8 })
      }
      .width('100%')
      .height(140)
      .borderRadius(AppConstants.RADIUS_MD)
      .backgroundColor($r('app.color.color_fill'))
      .alignContent(Alignment.Center)

      // 3. 标题
      Text(this.detail!.review.contentTitle)
        .fontSize(15)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .width('100%')

      // 4. 描述
      if (this.detail!.review.contentPreview && this.detail!.review.contentPreview.length > 0) {
        Text(this.detail!.review.contentPreview)
          .fontSize(13)
          .fontColor($r('app.color.color_text_2'))
          .width('100%')
          .lineHeight(20)
      }

      // 5. 审核要点框
      this.ReviewPointsBox()

      // 6. 提交者详细信息
      Divider().color($r('app.color.color_line')).strokeWidth(1)

      Column({ space: 4 }) {
        Row({ space: 8 }) {
          Text('内容 ID')
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
          Text(this.detail!.review.contentId)
            .fontSize(12)
            .fontColor($r('app.color.color_ink_2'))
            .fontWeight(FontWeight.Medium)
        }
        Row({ space: 8 }) {
          Text('提交者 ID')
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
          Text(this.detail!.review.submitterId)
            .fontSize(12)
            .fontColor($r('app.color.color_ink_2'))
            .fontWeight(FontWeight.Medium)
        }
        // 已审核时展示审核员
        if (this.detail!.review.status !== 'pending' && this.detail!.review.reviewerNickname) {
          Row({ space: 8 }) {
            Text('审核员')
              .fontSize(12)
              .fontColor($r('app.color.color_text_3'))
            Text(this.detail!.review.reviewerNickname)
              .fontSize(12)
              .fontColor($r('app.color.color_ink_2'))
              .fontWeight(FontWeight.Medium)
            Blank()
            if (this.detail!.review.reviewedAt) {
              Text(this.formatTime(this.detail!.review.reviewedAt))
                .fontSize(11)
                .fontColor($r('app.color.color_text_3'))
            }
          }
          .width('100%')
        }
        // 已驳回时展示驳回原因
        if (this.detail!.review.status === 'rejected' && this.detail!.review.rejectReason) {
          Row({ space: 8 }) {
            Text('驳回原因')
              .fontSize(12)
              .fontColor($r('app.color.color_live'))
            Text(this.detail!.review.rejectReason)
              .fontSize(12)
              .fontColor($r('app.color.color_live'))
              .fontWeight(FontWeight.Medium)
          }
          if (this.detail!.review.rejectDescription) {
            Text(`说明：${this.detail!.review.rejectDescription}`)
              .fontSize(11)
              .fontColor($r('app.color.color_text_3'))
              .width('100%')
          }
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
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

  /** 状态 pill */
  @Builder
  StatusPill(status: AdminReviewStatus) {
    Text(REVIEW_STATUS_LABELS[status])
      .fontSize(11)
      .fontColor(status === 'pending'
        ? $r('app.color.color_yellow_text')
        : status === 'approved'
          ? $r('app.color.color_green_deep')
          : $r('app.color.color_live'))
      .backgroundColor(status === 'pending'
        ? $r('app.color.color_yellow_soft')
        : status === 'approved'
          ? $r('app.color.color_green_soft')
          : $r('app.color.color_live_soft'))
      .padding({ left: 10, right: 10, top: 3, bottom: 3 })
      .borderRadius(AppConstants.RADIUS_PILL)
      .fontWeight(FontWeight.Medium)
  }

  /** 审核要点框（黄底 + 边框） */
  @Builder
  ReviewPointsBox() {
    Column({ space: 6 }) {
      Row({ space: 4 }) {
        Image($r('app.media.icon_clipboard'))
          .width(12)
          .height(12)
          .fillColor($r('app.color.color_yellow_text'))
        Text('审核要点')
          .fontSize(12)
          .fontColor($r('app.color.color_yellow_text'))
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')

      ForEach(this.getReviewPoints(), (point: ReviewPoint, index: number) => {
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

  /** 历史审核记录卡 */
  @Builder
  HistoryCard() {
    Column({ space: 10 }) {
      Row() {
        Text('审核历史')
          .fontSize(15)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text(`${this.detail!.history.length} 条`)
          .fontSize(11)
          .fontColor($r('app.color.color_text_3'))
      }
      .width('100%')

      ForEach(this.detail!.history, (item: ReviewHistoryItem, idx: number) => {
        this.HistoryItem(item, idx)
      }, (item: ReviewHistoryItem, idx: number) => `${item.reviewId}_${idx}`)
    }
    .width('100%')
    .padding(14)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 历史记录项（时间轴样式） */
  @Builder
  HistoryItem(item: ReviewHistoryItem, idx: number) {
    Row({ space: 12 }) {
      // 序号圆点
      Stack() {
        Text(`${idx + 1}`)
          .fontSize(11)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
      }
      .width(24)
      .height(24)
      .borderRadius(12)
      .backgroundColor(item.status === 'approved'
        ? $r('app.color.color_green')
        : item.status === 'rejected'
          ? $r('app.color.color_live')
          : $r('app.color.color_yellow'))

      Column({ space: 3 }) {
        Row({ space: 6 }) {
          Text(REVIEW_STATUS_LABELS[item.status])
            .fontSize(13)
            .fontColor(item.status === 'approved'
              ? $r('app.color.color_green_deep')
              : item.status === 'rejected'
                ? $r('app.color.color_live')
                : $r('app.color.color_yellow_text'))
            .fontWeight(FontWeight.Bold)
          if (item.reviewerNickname) {
            Text(`· ${item.reviewerNickname}`)
              .fontSize(11)
              .fontColor($r('app.color.color_text_3'))
          }
        }
        .width('100%')

        Text(item.note)
          .fontSize(12)
          .fontColor($r('app.color.color_text_2'))
          .width('100%')

        if (item.rejectReason) {
          Text(`驳回：${item.rejectReason}`)
            .fontSize(11)
            .fontColor($r('app.color.color_live'))
            .width('100%')
        }

        if (item.rejectDescription) {
          Text(`说明：${item.rejectDescription}`)
            .fontSize(11)
            .fontColor($r('app.color.color_text_3'))
            .width('100%')
        }

        Text(this.formatTime(item.reviewedAt))
          .fontSize(10)
          .fontColor($r('app.color.color_text_4'))
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .border({ width: { bottom: 1 }, color: $r('app.color.color_line') })
    .alignItems(VerticalAlign.Top)
  }

  /** 底部操作栏 */
  @Builder
  BottomActionBar() {
    if (this.detail && this.detail!.review.status === 'pending') {
      // 待审核：展示驳回 + 通过按钮
      Row({ space: 12 }) {
        Text(this.isProcessing ? '处理中...' : '驳回')
          .layoutWeight(1)
          .height(46)
          .borderRadius(AppConstants.RADIUS_MD)
          .backgroundColor($r('app.color.color_bg_card'))
          .border({ width: 1, color: $r('app.color.color_line_2') })
          .fontColor($r('app.color.color_text_2'))
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            if (!this.isProcessing) {
              this.onClickReject();
            }
          })
        Text(this.isProcessing ? '处理中...' : '通过')
          .layoutWeight(1)
          .height(46)
          .borderRadius(AppConstants.RADIUS_MD)
          .backgroundColor($r('app.color.color_green'))
          .fontColor(Color.White)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            if (!this.isProcessing) {
              this.onClickApprove();
            }
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor($r('app.color.color_bg_card'))
      .shadow({ radius: 12, color: 'rgba(26,26,26,0.05)', offsetX: 0, offsetY: -2 })
    } else if (this.detail && this.detail!.review.status !== 'pending') {
      // 已审核：展示状态信息
      Row({ space: 12 }) {
        Text(`✓ ${REVIEW_STATUS_LABELS[this.detail!.review.status]}`)
          .fontSize(14)
          .fontColor(this.detail!.review.status === 'approved'
            ? $r('app.color.color_green_deep')
            : $r('app.color.color_live'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        if (this.detail!.review.rejectReason) {
          Text(`驳回：${this.detail!.review.rejectReason}`)
            .fontSize(11)
            .fontColor($r('app.color.color_live'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .constraintSize({ maxWidth: 200 })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      .backgroundColor($r('app.color.color_bg_card'))
      .shadow({ radius: 12, color: 'rgba(26,26,26,0.05)', offsetX: 0, offsetY: -2 })
      .alignItems(VerticalAlign.Center)
    }
  }

  /** 驳回弹窗（方案 C：Stack + 遮罩 + @Builder） */
  @Builder
  RejectDialog() {
    Stack() {
      // 遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => { this.closeRejectDialog(); })

      // 弹窗内容
      Column({ space: 14 }) {
        Text('驳回审核')
          .fontSize(18)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)

        Text('请选择驳回原因')
          .fontSize(13)
          .fontColor($r('app.color.color_text_2'))
          .fontWeight(FontWeight.Medium)

        // 预设原因（胶囊样式）
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.rejectReasonOptions, (opt: RejectReasonOption) => {
            Text(opt.label)
              .fontSize(12)
              .fontColor(this.selectedReason === opt.value ? Color.White : $r('app.color.color_text_2'))
              .fontWeight(this.selectedReason === opt.value ? FontWeight.Bold : FontWeight.Medium)
              .backgroundColor(this.selectedReason === opt.value ? $r('app.color.color_live') : $r('app.color.color_fill'))
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .margin({ right: 6, bottom: 6 })
              .borderRadius(AppConstants.RADIUS_PILL)
              .onClick(() => { this.onSelectReason(opt.value); })
          }, (opt: RejectReasonOption) => opt.value)
        }
        .width('100%')

        // 自定义描述
        Text('自定义描述（选"其他"时必填）')
          .fontSize(13)
          .fontColor($r('app.color.color_text_2'))
          .fontWeight(FontWeight.Medium)
        TextArea({ text: this.rejectDescription, placeholder: '请输入驳回描述（最多 200 字）' })
          .width('100%')
          .height(80)
          .fontSize(13)
          .backgroundColor($r('app.color.color_fill'))
          .borderRadius(AppConstants.RADIUS_MD)
          .maxLength(200)
          .onChange((value: string) => { this.onDescriptionChange(value); })

        // 字数统计
        Row() {
          Blank()
          Text(`${this.rejectDescription.length}/200`)
            .fontSize(10)
            .fontColor(this.rejectDescription.length >= 200 ? $r('app.color.color_live') : $r('app.color.color_text_4'))
        }
        .width('100%')

        // 按钮区
        Row({ space: 12 }) {
          Text('取消')
            .layoutWeight(1)
            .height(44)
            .borderRadius(AppConstants.RADIUS_MD)
            .backgroundColor($r('app.color.color_fill'))
            .fontColor($r('app.color.color_text_2'))
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
            .onClick(() => { this.closeRejectDialog(); })
          Text(this.isProcessing ? '处理中...' : '确认驳回')
            .layoutWeight(1)
            .height(44)
            .borderRadius(AppConstants.RADIUS_MD)
            .backgroundColor($r('app.color.color_live'))
            .fontColor(Color.White)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
            .onClick(() => { this.doReject(); })
        }
        .width('100%')
      }
      .width('85%')
      .padding(20)
      .backgroundColor($r('app.color.color_bg_card'))
      .borderRadius(AppConstants.RADIUS_XL)
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.Center)
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
