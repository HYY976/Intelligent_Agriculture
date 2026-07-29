﻿﻿﻿/**
 * farmer_register - 农户卖家端注册页
 * 对齐设计稿 pages/farmer-register.html：
 *  - 奶油白背景 + 顶部装饰气泡（黄/绿径向渐变模拟）
 *  - 返回按钮栏（圆形白底阴影返回键）
 *  - 品牌Logo区：黄色渐变 80×80 圆角Logo + 萌芽图标 + 右侧吉祥物 + "智农卖家"标题 + 副标题
 *  - 表单区：手机号/密码/确认密码输入卡（白底圆角14+阴影+描边+左侧图标+密码显隐切换）
 *  - 资质承诺勾选（黄色选中态 20×20 方框 + 承诺文案）
 *  - 注册按钮（墨黑底白字 + 右箭头图标）
 *  - "去登录"下划线链接
 *  - 底部区域：黄色认证提示卡（盾牌图标）+ 用户协议文字
 *  - 底部黄色波浪装饰
 *
 * spec 11.3：账号（手机号）+ 密码 + 确认密码注册，密码至少6位，两次密码必须一致
 * 注册成功自动登录并跳转 FARMER_HOME
 */

import { Logger, AppConstants, HttpUtil, TokenStore, ToastUtil, RouteName, NavigationHelper } from 'common';
import { ApiResponse, UserInfo } from 'common';

/** 注册请求体（spec 11.3 ArkTS 严格模式要求具体 interface） */
interface FarmerRegisterRequest {
  phone: string;
  password: string;
  userType: 'farmer';
}

/** 注册响应体 */
interface FarmerRegisterResponse {
  token: string;
  userInfo: UserInfo;
}

@ComponentV2
export struct FarmerRegister {
  /** 账号（手机号） */
  @Local phone: string = '';
  /** 密码 */
  @Local password: string = '';
  /** 确认密码 */
  @Local confirmPassword: string = '';
  /** 资质认证：是否已勾选资质承诺 */
  @Local certAgreed: boolean = true;
  /** 是否正在注册 */
  @Local isSubmitting: boolean = false;
  /** 密码是否明文显示 */
  @Local passwordVisible: boolean = false;
  /** 确认密码是否明文显示 */
  @Local confirmPasswordVisible: boolean = false;

  /** 校验手机号格式 */
  private isPhoneValid(): boolean {
    const phoneRegex: RegExp = /^1[3-9]\d{9}$/;
    return phoneRegex.test(this.phone);
  }

  /** 注册 */
  private async doRegister(): Promise<void> {
    if (!this.isPhoneValid()) {
      ToastUtil.warning('请输入正确的手机号');
      return;
    }
    if (this.password.length < 6) {
      ToastUtil.warning('密码至少6位');
      return;
    }
    if (this.password !== this.confirmPassword) {
      ToastUtil.warning('两次输入的密码不一致');
      return;
    }
    if (!this.certAgreed) {
      ToastUtil.warning('请先勾选卖家资质承诺');
      return;
    }
    this.isSubmitting = true;
    try {
      const req: FarmerRegisterRequest = {
        phone: this.phone,
        password: this.password,
        userType: 'farmer'
      };
      const resp: ApiResponse<FarmerRegisterResponse> = await HttpUtil.post<FarmerRegisterResponse>('/farmer/register', req, {
        withAuth: false
      });
      if (resp.code === AppConstants.CODE_SUCCESS && resp.data) {
        await TokenStore.setToken(resp.data.token);
        await TokenStore.setUserInfo(resp.data.userInfo);
        ToastUtil.success('注册成功');
        Logger.info(AppConstants.SCENE_FARMER, {
          action: 'register_success',
          userId: resp.data.userInfo.userId
        });
        NavigationHelper.replace(RouteName.FARMER_HOME);
      } else {
        ToastUtil.error(resp.msg || '注册失败');
      }
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'register_fail', error: (err as Error).message });
      ToastUtil.error('注册失败，请稍后重试');
    } finally {
      this.isSubmitting = false;
    }
  }

  /** 返回登录页 */
  private gotoLogin(): void {
    NavigationHelper.pop();
  }

  /** 切换密码显隐 */
  private togglePasswordVisible(): void {
    this.passwordVisible = !this.passwordVisible;
  }

  /** 切换确认密码显隐 */
  private toggleConfirmPasswordVisible(): void {
    this.confirmPasswordVisible = !this.confirmPasswordVisible;
  }

  /** 切换资质承诺勾选 */
  private toggleCertAgreed(): void {
    this.certAgreed = !this.certAgreed;
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.BottomStart }) {
        // 主内容滚动区
        Scroll() {
          Column() {
            // 1. 顶部装饰气泡
            this.Decorations()
            // 2. 品牌Logo区
            this.BrandHero()
            // 3. 表单区
            this.FormSection()
            // 4. 底部区域
            this.FooterSection()
          }
          .width('100%')
          .padding({ left: 24, right: 24, bottom: 24 })
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .backgroundColor($r('app.color.color_bg_page'))
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 顶部装饰气泡（对齐设计稿 qn-deco-1/2） */
  @Builder
  Decorations() {
    Stack() {
      // 黄色气泡（右上角）
      Column()
        .width(70)
        .height(70)
        .borderRadius(35)
        .backgroundColor('rgba(255,226,52,0.28)')
        .position({ right: -24, top: -24 })

      // 绿色气泡（左侧）
      Column()
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor('rgba(126,211,33,0.18)')
        .position({ left: -20, top: 30 })
    }
    .width('100%')
    .height(80)
    .hitTestBehavior(HitTestMode.Transparent)
  }

  /** 品牌Logo区（对齐设计稿 qn-brand-hero，margin-top 18px 区别于登录页 80px） */
  @Builder
  BrandHero() {
    Stack({ alignContent: Alignment.TopEnd }) {
      // 主内容居中
      Column({ space: 6 }) {
        // 黄色渐变Logo + 萌芽图标
        Column() {
          Text('🌱')
            .fontSize(40)
            .fontColor($r('app.color.color_ink'))
        }
        .width(80)
        .height(80)
        .borderRadius(AppConstants.RADIUS_XL)
        .linearGradient({
          angle: 135,
          colors: [['#FFE234', 0], ['#FFD93D', 1]]
        })
        .border({ width: 3, color: $r('app.color.color_bg_card') })
        .shadow({ radius: 26, color: 'rgba(255,217,61,0.42)', offsetX: 0, offsetY: 10 })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        // 标题"智农卖家"
        Text('智农卖家')
          .fontSize(24)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .letterSpacing(1)
          .margin({ top: 10 })

        // 副标题
        Text('商品上架·直播带货·营收管理')
          .fontSize(13)
          .fontColor($r('app.color.color_text_3'))
          .letterSpacing(0.5)
      }
      .width('100%')
      .margin({ top: 0 })
      .alignItems(HorizontalAlign.Center)

      // 右侧品牌头像（60×60 圆形，与登录页同位置）
      Image($r('app.media.avatar_brand'))
        .width(60)
        .height(60)
        .borderRadius(AppConstants.RADIUS_PILL)
        .objectFit(ImageFit.Cover)
        .border({ width: 3, color: $r('app.color.color_bg_card') })
        .shadow({ radius: 18, color: 'rgba(26,26,26,0.12)', offsetX: 0, offsetY: 6 })
        .position({ right: 8, top: 0 })
    }
    .width('100%')
    .margin({ bottom: 28 })
  }

  /** 表单区（对齐设计稿 qn-farmer-form，3 个输入字段） */
  @Builder
  FormSection() {
    Column({ space: 14 }) {
      // a) 手机号输入框
      Row({ space: 12 }) {
        Text('📱')
          .fontSize(18)
          .fontColor($r('app.color.color_text_3'))
        TextInput({ text: this.phone, placeholder: '请输入手机号' })
          .type(InputType.PhoneNumber)
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .placeholderFont({ size: 14 })
          .placeholderColor($r('app.color.color_text_4'))
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .height(52)
          .padding({ left: 0, right: 0 })
          .maxLength(11)
          .onChange((value: string) => {
            this.phone = value;
          })
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .borderRadius(AppConstants.RADIUS_MD)
      .backgroundColor($r('app.color.color_bg_card'))
      .border({ width: 1, color: $r('app.color.color_line') })
      .shadow(AppConstants.SHADOW_CARD)
      .alignItems(VerticalAlign.Center)

      // b) 密码输入框（含左侧锁图标，系统 Password 类型自带显隐切换）
      Row({ space: 12 }) {
        Text('🔒')
          .fontSize(18)
          .fontColor($r('app.color.color_text_3'))
        TextInput({ text: this.password, placeholder: '请输入密码' })
          .type(this.passwordVisible ? InputType.Normal : InputType.Password)
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .placeholderFont({ size: 14 })
          .placeholderColor($r('app.color.color_text_4'))
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .height(52)
          .padding({ left: 0, right: 0 })
          .maxLength(32)
          .onChange((value: string) => {
            this.password = value;
          })
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .borderRadius(AppConstants.RADIUS_MD)
      .backgroundColor($r('app.color.color_bg_card'))
      .border({ width: 1, color: $r('app.color.color_line') })
      .shadow(AppConstants.SHADOW_CARD)
      .alignItems(VerticalAlign.Center)

      // c) 确认密码输入框（含左侧锁图标，系统 Password 类型自带显隐切换）
      Row({ space: 12 }) {
        Text('🔒')
          .fontSize(18)
          .fontColor($r('app.color.color_text_3'))
        TextInput({ text: this.confirmPassword, placeholder: '请再次输入密码' })
          .type(this.confirmPasswordVisible ? InputType.Normal : InputType.Password)
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .placeholderFont({ size: 14 })
          .placeholderColor($r('app.color.color_text_4'))
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .height(52)
          .padding({ left: 0, right: 0 })
          .maxLength(32)
          .onChange((value: string) => {
            this.confirmPassword = value;
          })
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .borderRadius(AppConstants.RADIUS_MD)
      .backgroundColor($r('app.color.color_bg_card'))
      .border({ width: 1, color: $r('app.color.color_line') })
      .shadow(AppConstants.SHADOW_CARD)
      .alignItems(VerticalAlign.Center)

      // d) 资质承诺勾选
      Row({ space: 8 }) {
        Row() {
          if (this.certAgreed) {
            Text('✓')
              .fontSize(12)
              .fontColor($r('app.color.color_ink'))
              .fontWeight(FontWeight.Bold)
          }
        }
        .width(20)
        .height(20)
        .borderRadius(AppConstants.RADIUS_XS)
        .backgroundColor(this.certAgreed ? $r('app.color.color_yellow') : $r('app.color.color_bg_card'))
        .border({ width: 1.5, color: this.certAgreed ? $r('app.color.color_yellow_deep') : $r('app.color.color_line_2') })
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .onClick(() => { this.toggleCertAgreed(); })

        Text('我承诺具备农户资质，所售商品来源真实')
          .fontSize(12)
          .fontColor($r('app.color.color_text_2'))
          .layoutWeight(1)
          .onClick(() => { this.toggleCertAgreed(); })
      }
      .width('100%')
      .margin({ top: 2, bottom: 4 })
      .alignItems(VerticalAlign.Center)

      // e) 注册按钮（墨黑底白字，对齐 qn-register-btn）
      Row({ space: 6 }) {
        Text('注册')
          .fontSize(15)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
          .letterSpacing(1)
        Text('→')
          .fontSize(18)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .height(48)
      .borderRadius(AppConstants.RADIUS_MD)
      .backgroundColor(this.isSubmitting ? $r('app.color.color_button_disabled') : $r('app.color.color_ink'))
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .opacity(this.isSubmitting ? 0.7 : 1)
      .margin({ top: 6 })
      .onClick(() => { this.doRegister(); })

      // f) 去登录链接
      Text('去登录')
        .fontSize(13)
        .fontColor($r('app.color.color_text_2'))
        .margin({ top: 12 })
        .decoration({ type: TextDecorationType.Underline, color: $r('app.color.color_text_2') })
        .onClick(() => { this.gotoLogin(); })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  /** 底部区域（对齐设计稿 qn-farmer-foot，盾牌图标区别于登录页信息图标） */
  @Builder
  FooterSection() {
    Column({ space: 16 }) {
      // 资质认证提示卡（对齐 qn-cert-tip 黄底 + 盾牌图标）
      Row({ space: 8 }) {
        Text('🛡')
          .fontSize(14)
          .fontColor($r('app.color.color_yellow_text'))
          .fontWeight(FontWeight.Bold)
        Text('未认证卖家需先完成资质认证')
          .fontSize(12)
          .fontColor('#8A6D00')
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 12, bottom: 12 })
      .borderRadius(AppConstants.RADIUS_MD)
      .backgroundColor($r('app.color.color_yellow_soft'))
      .alignItems(VerticalAlign.Top)

      // 用户协议文字
      Row() {
        Text('注册即同意')
          .fontSize(11)
          .fontColor($r('app.color.color_text_3'))
        Text('《用户协议》')
          .fontSize(11)
          .fontColor($r('app.color.color_text_2'))
        Text('和')
          .fontSize(11)
          .fontColor($r('app.color.color_text_3'))
        Text('《隐私政策》')
          .fontSize(11)
          .fontColor($r('app.color.color_text_2'))
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .margin({ top: 8 })
    .alignItems(HorizontalAlign.Center)
  }
}
