/**
 * certification - 资质认证（spec 3.2.4.5 / 13.2）
 *
 * 现阶段仅 UI 预留，提交后直接"认证通过"（Mock 认证）
 * 表单字段：
 *  - 姓名
 *  - 身份证号
 *  - 身份证正面图
 *  - 身份证反面图
 *  - 农户资质图
 *
 * 提交后调用 FarmerRepository.submitCertification
 * Mock 阶段直接返回 approved
 */

import { Logger, AppConstants, ToastUtil, NavigationHelper, RouteName } from 'common';
import { CertificationInfo, CertificationStatus } from '../../model/FarmerModels';
import { FarmerRepository } from '../../repository/FarmerRepository';
import { MOCK_FARMER_ID } from '../../mock/FarmerMock';

@ComponentV2
export struct Certification {
  /** 真实姓名 */
  @Local realName: string = '';
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
  /** 当前认证状态（提交后更新） */
  @Local currentStatus: CertificationStatus | null = null;

  /** 身份证号预设选项（Mock：方便测试） */
  private idCardPresets: string[] = [
    '530***********1234',
    '430***********5678',
    '420***********9012',
    '320***********3456'
  ];

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
  private uploadImage(field: 'idCardFrontImg' | 'idCardBackImg' | 'farmerCertImg'): void {
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
      NavigationHelper.pop();
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
          Column({ space: 16 }) {
            this.NoticeCard()
            this.BasicInfoSection()
            this.IdCardSection()
            this.FarmerCertSection()
            this.SubmitButton()
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 24 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
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
      Text('资质认证')
        .fontSize(18)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** 说明卡 */
  @Builder
  NoticeCard() {
    Column({ space: 6 }) {
      Row({ space: 6 }) {
        Text('ℹ️')
          .fontSize(14)
        Text('资质认证说明')
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      Text('提交资质认证后即可发布商品 / 开通直播。当前阶段为 Mock 认证，提交后直接"认证通过"，后端部署后将切换为人工审核流程。')
        .fontSize(11)
        .fontColor($r('app.color.color_text_secondary'))
        .width('100%')
    }
    .width('100%')
    .padding(12)
    .borderRadius(8)
    .backgroundColor('rgba(255,213,79,0.15)')
  }

  /** 基本信息 */
  @Builder
  BasicInfoSection() {
    Column({ space: 12 }) {
      Text('基本信息')
        .fontSize(14)
        .fontColor($r('app.color.color_text_secondary'))
        .alignSelf(ItemAlign.Start)
      Column({ space: 6 }) {
        Text('* 真实姓名')
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
          .alignSelf(ItemAlign.Start)
        TextInput({ text: this.realName, placeholder: '请输入真实姓名' })
          .height(44)
          .borderRadius(8)
          .backgroundColor($r('app.color.color_bg_page'))
          .padding({ left: 12, right: 12 })
          .fontSize(14)
          .maxLength(20)
          .onChange((v: string) => { this.realName = v; })
      }
      .width('100%')
      Column({ space: 6 }) {
        Text('* 身份证号')
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
          .alignSelf(ItemAlign.Start)
        Select(this.idCardPresets.map((s: string): SelectOption => { return { value: s }; }))
          .selected(this.idCardPresets.indexOf(this.idCardNo))
          .value(this.idCardNo.length > 0 ? this.idCardNo : '请选择或输入身份证号（Mock）')
          .height(44)
          .borderRadius(8)
          .backgroundColor($r('app.color.color_bg_page'))
          .onSelect((idx: number) => { this.idCardNo = this.idCardPresets[idx]; })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 身份证上传 */
  @Builder
  IdCardSection() {
    Column({ space: 12 }) {
      Text('身份证照片')
        .fontSize(14)
        .fontColor($r('app.color.color_text_secondary'))
        .alignSelf(ItemAlign.Start)
      Row({ space: 12 }) {
        this.ImageUploadBox('正面', this.idCardFrontImg, 'idCardFrontImg')
        this.ImageUploadBox('反面', this.idCardBackImg, 'idCardBackImg')
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 图片上传盒子 */
  @Builder
  ImageUploadBox(label: string, imgKey: string, field: 'idCardFrontImg' | 'idCardBackImg' | 'farmerCertImg') {
    Column({ space: 6 }) {
      Stack() {
        if (imgKey.length > 0) {
          Column({ space: 4 }) {
            Text('✓')
              .fontSize(36)
              .fontColor($r('app.color.color_primary'))
            Text('已上传')
              .fontSize(10)
              .fontColor($r('app.color.color_text_hint'))
          }
        } else {
          Column({ space: 4 }) {
            Text('📷')
              .fontSize(28)
            Text('点击上传')
              .fontSize(10)
              .fontColor($r('app.color.color_text_hint'))
          }
        }
      }
      .width('100%')
      .height(100)
      .borderRadius(8)
      .backgroundColor(imgKey.length > 0 ? 'rgba(139,195,74,0.1)' : $r('app.color.color_bg_page'))
      .alignContent(Alignment.Center)
      .onClick(() => { this.uploadImage(field); })
      Text(label)
        .fontSize(11)
        .fontColor($r('app.color.color_text_secondary'))
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  /** 农户资质图 */
  @Builder
  FarmerCertSection() {
    Column({ space: 12 }) {
      Text('农户资质图')
        .fontSize(14)
        .fontColor($r('app.color.color_text_secondary'))
        .alignSelf(ItemAlign.Start)
      this.ImageUploadBox('农户资质', this.farmerCertImg, 'farmerCertImg')
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 提交按钮 */
  @Builder
  SubmitButton() {
    Button(this.isSubmitting ? '提交中...' : '提交认证')
      .width('100%')
      .height(48)
      .borderRadius(24)
      .backgroundColor(this.isSubmitting ? $r('app.color.color_button_disabled') : $r('app.color.color_secondary'))
      .fontColor(Color.White)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .enabled(!this.isSubmitting)
      .onClick(() => { this.submitCertification(); })
  }
}
