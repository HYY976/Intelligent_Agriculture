/**
 * certification - 资质认证（spec 3.2.4.5 / 13.2）
 *
 * 对齐设计稿 pages/certification.html：
 *  - 顶部导航（圆形返回键 + 居中标题 + 占位）
 *  - 浅黄底说明卡（icon + 说明文案）
 *  - 基本信息卡（真实姓名 + 证件类型 + 身份证号）
 *  - 身份证照片卡（正面 + 反面，150x100 虚线上传框）
 *  - 农户资质证明卡（全宽 120px 虚线上传框）
 *  - 审核状态卡（待提交/审核中/已通过 pill）
 *  - 底部固定提交按钮（墨黑底白字）
 *
 * 现阶段仅 UI 预留，提交后直接"认证通过"（Mock 认证）
 */

import { Logger, AppConstants, ToastUtil, NavigationHelper } from 'common';
import { CertificationInfo, CertificationStatus } from '../../model/FarmerModels';
import { FarmerRepository } from '../../repository/FarmerRepository';
import { MOCK_FARMER_ID } from '../../mock/FarmerMock';

/** 证件类型选项 */
interface IdTypeOption {
  value: string;
  label: string;
}

/** 上传字段类型 */
type UploadField = 'idCardFrontImg' | 'idCardBackImg' | 'farmerCertImg';

@ComponentV2
export struct Certification {
  /** 真实姓名 */
  @Local realName: string = '';
  /** 证件类型 */
  @Local idType: string = 'id_card';
  /** 身份证号 */
  @Local idCardNo: string = '';
  /** 身份证正面图 key */
  @Local idCardFrontImg: string = '';
  /** 身份证反面图 key */
  @Local idCardBackImg: string = '';
  /** 农户资质图 key */
  @Local farmerCertImg: string = '';
  /** 是否正在提交 */
  @Local isSubmitting: boolean = false;
  /** 当前认证状态 */
  @Local currentStatus: CertificationStatus | null = null;

  /** 证件类型选项 */
  private idTypeOptions: IdTypeOption[] = [
    { value: 'id_card', label: '大陆身份证' },
    { value: 'passport', label: '护照' },
    { value: 'hk_macao', label: '港澳通行证' },
    { value: 'tw', label: '台湾通行证' }
  ];

  async aboutToAppear(): Promise<void> {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'certification_appear' });
  }

  /** 取证件类型文案 */
  private getIdTypeLabel(): string {
    const opt: IdTypeOption | undefined = this.idTypeOptions.find((o: IdTypeOption): boolean => o.value === this.idType);
    return opt ? opt.label : '请选择证件类型';
  }

  /** 取审核状态 pill 文案 */
  private getStatusLabel(): string {
    if (this.currentStatus === 'approved') {
      return '已通过';
    }
    if (this.currentStatus === 'pending') {
      return '审核中';
    }
    if (this.currentStatus === 'rejected') {
      return '已驳回';
    }
    return '待提交';
  }

  /** 取审核状态 pill 底色 */
  private getStatusBg(): Resource {
    if (this.currentStatus === 'approved') {
      return $r('app.color.color_green_soft');
    }
    if (this.currentStatus === 'pending') {
      return $r('app.color.color_warn_soft');
    }
    if (this.currentStatus === 'rejected') {
      return $r('app.color.color_live_soft');
    }
    return $r('app.color.color_fill');
  }

  /** 取审核状态 pill 前景色 */
  private getStatusFg(): Resource {
    if (this.currentStatus === 'approved') {
      return $r('app.color.color_green_deep');
    }
    if (this.currentStatus === 'pending') {
      return $r('app.color.color_warn');
    }
    if (this.currentStatus === 'rejected') {
      return $r('app.color.color_live');
    }
    return $r('app.color.color_text_2');
  }

  /** 校验 */
  private validateForm(): boolean {
    if (this.realName.length === 0) {
      ToastUtil.warning('请填写真实姓名');
      return false;
    }
    if (this.idCardNo.length === 0) {
      ToastUtil.warning('请填写身份证号');
      return false;
    }
    if (this.idCardFrontImg.length === 0) {
      ToastUtil.warning('请上传身份证正面图');
      return false;
    }
    if (this.idCardBackImg.length === 0) {
      ToastUtil.warning('请上传身份证反面图');
      return false;
    }
    if (this.farmerCertImg.length === 0) {
      ToastUtil.warning('请上传农户资质图');
      return false;
    }
    return true;
  }

  /** 上传图片（Mock） */
  private uploadImage(field: UploadField): void {
    const presets: Record<string, string> = {
      'idCardFrontImg': 'cert_id_front',
      'idCardBackImg': 'cert_id_back',
      'farmerCertImg': 'cert_farmer'
    };
    if (field === 'idCardFrontImg') {
      this.idCardFrontImg = presets['idCardFrontImg'];
    } else if (field === 'idCardBackImg') {
      this.idCardBackImg = presets['idCardBackImg'];
    } else {
      this.farmerCertImg = presets['farmerCertImg'];
    }
    ToastUtil.success('已上传（Mock）');
  }

  /** 提交认证 */
  private async submitCertification(): Promise<void> {
    if (!this.validateForm()) {
      return;
    }
    this.isSubmitting = true;
    try {
      const certInfo: CertificationInfo = {
        realName: this.realName,
        idCardNo: this.idCardNo,
        idCardFrontImg: this.idCardFrontImg,
        idCardBackImg: this.idCardBackImg,
        farmerCertImg: this.farmerCertImg
      };
      const status: CertificationStatus = await FarmerRepository.submitCertification(MOCK_FARMER_ID, certInfo);
      this.currentStatus = status;
      ToastUtil.success('认证已通过（Mock）');
      Logger.info(AppConstants.SCENE_FARMER, { action: 'certification_success', certStatus: status });
      setTimeout((): void => {
        NavigationHelper.pop();
      }, 1000);
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'certification_fail', error: (err as Error).message });
      ToastUtil.error('提交失败');
    } finally {
      this.isSubmitting = false;
    }
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        Scroll() {
          Column({ space: 12 }) {
            this.TipCard()
            this.BasicInfoCard()
            this.IdCardCard()
            this.FarmerCertCard()
            this.StatusCard()
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 4, bottom: 100 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        // 底部固定提交按钮
        this.BottomSubmitBar()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_cream'))
    }
    .hideTitleBar(true)
  }

  /** 顶部导航（圆形返回键 + 居中标题 + 占位） */
  @Builder
  TopBar() {
    Row() {
      Text('‹')
        .fontSize(20)
        .fontColor($r('app.color.color_ink'))
        .width(32)
        .height(32)
        .borderRadius(16)
        .backgroundColor($r('app.color.color_bg_card'))
        .shadow(AppConstants.SHADOW_CARD)
        .textAlign(TextAlign.Center)
        .onClick(() => NavigationHelper.pop())
      Text('资质认证')
        .fontSize(17)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      // 占位（保持标题居中）
      Text('')
        .width(32)
        .height(32)
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16, bottom: 10 })
    .alignItems(VerticalAlign.Center)
  }

  /** 浅黄底说明卡 */
  @Builder
  TipCard() {
    Row({ space: 10 }) {
      Text('ℹ')
        .fontSize(16)
        .fontColor('#E0A800')
        .width(20)
        .textAlign(TextAlign.Center)
      Text('完成资质认证后可享受更多平台权益，现阶段提交后系统自动审核通过')
        .fontSize(13)
        .fontColor($r('app.color.color_ink_2'))
        .lineHeight(20)
        .layoutWeight(1)
    }
    .width('100%')
    .padding(14)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_yellow_tint'))
    .alignItems(VerticalAlign.Top)
  }

  /** 基本信息卡 */
  @Builder
  BasicInfoCard() {
    Column({ space: 16 }) {
      // 卡片标题
      Text('基本信息')
        .fontSize(16)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .alignSelf(ItemAlign.Start)
      // 真实姓名
      Column({ space: 8 }) {
        Text('真实姓名')
          .fontSize(13)
          .fontColor($r('app.color.color_text_2'))
          .alignSelf(ItemAlign.Start)
        TextInput({ text: this.realName, placeholder: '请输入真实姓名' })
          .height(46)
          .borderRadius(AppConstants.RADIUS_MD)
          .backgroundColor($r('app.color.color_fill'))
          .padding({ left: 16, right: 16 })
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .maxLength(20)
          .onChange((v: string) => { this.realName = v; })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      // 证件类型
      Column({ space: 8 }) {
        Text('证件类型')
          .fontSize(13)
          .fontColor($r('app.color.color_text_2'))
          .alignSelf(ItemAlign.Start)
        // 证件类型选择器（使用 Select 组件）
        Select(this.idTypeOptions.map((o: IdTypeOption): SelectOption => { return { value: o.label }; }))
          .selected(this.idTypeOptions.findIndex((o: IdTypeOption): boolean => o.value === this.idType))
          .value(this.getIdTypeLabel())
          .height(46)
          .borderRadius(AppConstants.RADIUS_MD)
          .backgroundColor($r('app.color.color_fill'))
          .onSelect((idx: number) => { this.idType = this.idTypeOptions[idx].value; })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      // 身份证号
      Column({ space: 8 }) {
        Text('身份证号')
          .fontSize(13)
          .fontColor($r('app.color.color_text_2'))
          .alignSelf(ItemAlign.Start)
        TextInput({ text: this.idCardNo, placeholder: '请输入身份证号' })
          .height(46)
          .borderRadius(AppConstants.RADIUS_MD)
          .backgroundColor($r('app.color.color_fill'))
          .padding({ left: 16, right: 16 })
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .maxLength(18)
          .onChange((v: string) => { this.idCardNo = v; })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 身份证照片卡（正面 + 反面，两列） */
  @Builder
  IdCardCard() {
    Column({ space: 14 }) {
      Text('身份证照片')
        .fontSize(16)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .alignSelf(ItemAlign.Start)
      Row({ space: 12 }) {
        this.UploadBox('正面', this.idCardFrontImg, 'idCardFrontImg', false)
        this.UploadBox('反面', this.idCardBackImg, 'idCardBackImg', false)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 农户资质证明卡（全宽上传框） */
  @Builder
  FarmerCertCard() {
    Column({ space: 14 }) {
      Text('农户资质证明')
        .fontSize(16)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .alignSelf(ItemAlign.Start)
      this.UploadBox('上传土地承包/合作社证明', this.farmerCertImg, 'farmerCertImg', true)
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 上传框（双列 150x100 或全宽 120） */
  @Builder
  UploadBox(label: string, imgKey: string, field: UploadField, isWide: boolean) {
    Stack() {
      Column({ space: isWide ? 8 : 6 }) {
        if (imgKey.length > 0) {
          // 已上传：绿色对勾
          Text('✓')
            .fontSize(28)
            .fontColor($r('app.color.color_green_deep'))
            .backgroundColor($r('app.color.color_green_soft'))
            .width(isWide ? 56 : 40)
            .height(isWide ? 56 : 40)
            .borderRadius(isWide ? 28 : 20)
            .textAlign(TextAlign.Center)
            .fontWeight(FontWeight.Bold)
        } else {
          // 未上传：相机图标
          Text('📷')
            .fontSize(isWide ? 28 : 24)
            .fontColor($r('app.color.color_text_3'))
        }
        Text(label)
          .fontSize(isWide ? 13 : 12)
          .fontColor($r('app.color.color_text_3'))
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .width(isWide ? '100%' : '50%')
    .height(isWide ? 120 : 100)
    .borderRadius(AppConstants.RADIUS_MD)
    .backgroundColor($r('app.color.color_fill'))
    .border({ width: 1.5, color: $r('app.color.color_text_4'), style: BorderStyle.Dashed })
    .alignContent(Alignment.Center)
    .onClick(() => this.uploadImage(field))
  }

  /** 审核状态卡 */
  @Builder
  StatusCard() {
    Row() {
      Text('审核状态')
        .fontSize(14)
        .fontColor($r('app.color.color_ink_2'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
      // 状态 pill
      Text(this.getStatusLabel())
        .fontSize(11)
        .fontColor(this.getStatusFg())
        .backgroundColor(this.getStatusBg())
        .padding({ left: 10, right: 10, top: 3, bottom: 3 })
        .borderRadius(AppConstants.RADIUS_PILL)
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(VerticalAlign.Center)
  }

  /** 底部固定提交按钮 */
  @Builder
  BottomSubmitBar() {
    Row() {
      Button(this.isSubmitting ? '提交中...' : '提交认证')
        .width('100%')
        .height(46)
        .borderRadius(AppConstants.RADIUS_MD)
        .backgroundColor(this.isSubmitting ? $r('app.color.color_button_disabled') : $r('app.color.color_cta_black'))
        .fontColor(Color.White)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .enabled(!this.isSubmitting)
        .onClick(() => { this.submitCertification(); })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 16 })
    .backgroundColor($r('app.color.color_cream'))
    .shadow({ radius: 12, color: 'rgba(26,26,26,0.05)', offsetX: 0, offsetY: -2 })
  }
}
