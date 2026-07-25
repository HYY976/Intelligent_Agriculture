/**
 * farmer_login - 农户卖家端登录页
 * 对齐设计稿 pages/farmer-login.html：
 *  - 奶油白背景 + 顶部装饰气泡（黄/绿径向渐变模拟）
 *  - 品牌Logo区：黄色渐变 80×80 圆角Logo + 萌芽图标 + 右侧吉祥物 + "助农卖家"标题 + 副标题
 *  - 表单区：手机号/密码输入卡（白底圆角14+阴影+描边+左侧图标+密码显隐切换）
 *  - 资质承诺勾选（黄色选中态 20×20 方框 + 承诺文案）
 *  - 卖家登录按钮（墨黑底白字 + 右箭头图标）
 *  - "去注册"下划线链接
 *  - 底部区域：黄色认证提示卡 + 用户协议文字
 *  - 底部黄色波浪装饰
 *
 * spec 11.2：账号（手机号）+ 密码登录，保留《卖家资质承诺》勾选
 * JWT 7天有效期，存储到 Preferences，登录成功跳转 FARMER_HOME
 */

import { Logger, AppConstants, HttpUtil, TokenStore, ToastUtil, NavigationHelper, RouteName } from 'common';
import { ApiResponse, UserInfo } from 'common';

/** 登录请求体（spec 11.2 ArkTS 严格模式要求具体 interface） */
interface FarmerLoginRequest {
  phone: string;
  password: string;
  userType: 'farmer';
  /** 资质认证：已勾选资质承诺 */
  certAgreed: boolean;
}

/** 登录响应体 */
interface FarmerLoginResponse {
  token: string;
  userInfo: UserInfo;
  /** 资质认证状态：pending=待认证 / approved=已认证 / rejected=驳回 */
  certStatus: 'pending' | 'approved' | 'rejected';
}

@ComponentV2
export struct FarmerLogin {
  /** 账号（手机号） */
  @Local phone: string = '';
  /** 密码 */
  @Local password: string = '';
  /** 资质认证：是否已勾选资质承诺 */
  @Local certAgreed: boolean = true;
  /** 是否正在登录 */
  @Local isLogging: boolean = false;
  /** 密码是否明文显示 */
  @Local passwordVisible: boolean = false;

  /** 校验手机号格式 */
  private isPhoneValid(): boolean {
    const phoneRegex: RegExp = /^1[3-9]\d{9}$/;
    return phoneRegex.test(this.phone);
  }

  /** 登录 */
  private async doLogin(): Promise<void> {
    if (!this.isPhoneValid()) {
      ToastUtil.warning('请输入正确的手机号');
      return;
    }
    if (this.password.length < 6) {
      ToastUtil.warning('密码至少6位');
      return;
    }
    if (!this.certAgreed) {
      ToastUtil.warning('请先勾选卖家资质承诺');
      return;
    }
    this.isLogging = true;
    try {
      const req: FarmerLoginRequest = {
        phone: this.phone,
        password: this.password,
        userType: 'farmer',
        certAgreed: this.certAgreed
      };
      const resp: ApiResponse<FarmerLoginResponse> = await HttpUtil.post<FarmerLoginResponse>('/farmer/login', req, {
        withAuth: false
      });
      if (resp.code === AppConstants.CODE_SUCCESS && resp.data) {
        await TokenStore.setToken(resp.data.token);
        await TokenStore.setUserInfo(resp.data.userInfo);
        ToastUtil.success('登录成功');
        Logger.info(AppConstants.SCENE_FARMER, {
          action: 'login_success',
          userId: resp.data.userInfo.userId,
          certStatus: resp.data.certStatus
        });
        NavigationHelper.replace(RouteName.FARMER_HOME);
      } else {
        ToastUtil.error(resp.msg || '登录失败');
      }
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'login_fail', error: (err as Error).message });
      ToastUtil.error('登录失败，请稍后重试');
    } finally {
      this.isLogging = false;
    }
  }

  /** 跳转注册页 */
  private gotoRegister(): void {
    NavigationHelper.push(RouteName.FARMER_REGISTER);
  }

  /** 切换密码显隐 */
  private togglePasswordVisible(): void {
    this.passwordVisible = !this.passwordVisible;
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
            // 1. 顶部装饰气泡（对齐设计稿 qn-deco-1/2）
            this.Decorations()
            // 2. 品牌Logo区
            this.BrandHero()
            // 3. 表单区
            this.FormSection()
            // 4. 底部区域
            this.FooterSection()
          }
          .width('100%')
          .padding({ left: 24, right: 24, bottom: 80 })
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .backgroundColor($r('app.color.color_bg_page'))

        // 5. 底部黄色波浪装饰
        this.BottomWave()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 顶部装饰气泡（对齐设计稿 qn-deco-1/2 径向渐变模拟） */
  @Builder
  Decorations() {
    Stack() {
      // 黄色气泡（右上角，对齐 qn-deco-1）
      Column()
        .width(130)
        .height(130)
        .borderRadius(65)
        .backgroundColor('rgba(255,226,52,0.28)')
        .position({ right: -42, top: -36 })

      // 绿色气泡（左侧，对齐 qn-deco-2）
      Column()
        .width(96)
        .height(96)
        .borderRadius(48)
        .backgroundColor('rgba(126,211,33,0.18)')
        .position({ left: -34, top: 200 })
    }
    .width('100%')
    .height(300)
    .hitTestBehavior(HitTestMode.Transparent)
  }

  /** 品牌Logo区（对齐设计稿 qn-brand-hero） */
  @Builder
  BrandHero() {
    Stack({ alignContent: Alignment.TopEnd }) {
      // 主内容居中
      Column({ space: 6 }) {
        // 黄色渐变Logo + 萌芽图标（对齐 qn-brand-logo 80×80 圆角24）
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

        // 标题"助农卖家"
        Text('助农卖家')
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
      .margin({ top: 80 })
      .alignItems(HorizontalAlign.Center)

      // 右侧吉祥物装饰（对齐 qn-brand-mascot 60×60）
      Image($r('app.media.mascot_farmer'))
        .width(60)
        .height(60)
        .borderRadius(AppConstants.RADIUS_PILL)
        .objectFit(ImageFit.Cover)
        .backgroundColor($r('app.color.color_yellow_tint'))
        .border({ width: 3, color: $r('app.color.color_bg_card') })
        .shadow({ radius: 18, color: 'rgba(26,26,26,0.12)', offsetX: 0, offsetY: 6 })
        .position({ right: 8, top: 0 })
    }
    .width('100%')
    .margin({ bottom: 32 })
  }

  /** 表单区（对齐设计稿 qn-farmer-form） */
  @Builder
  FormSection() {
    Column({ space: 14 }) {
      // a) 手机号输入框（对齐 qn-farmer-field）
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

      // b) 密码输入框（对齐 qn-farmer-field + qn-eye-btn）
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
        // 密码显隐切换按钮
        Text(this.passwordVisible ? '👁' : '🙈')
          .fontSize(16)
          .fontColor($r('app.color.color_text_3'))
          .width(28)
          .height(28)
          .textAlign(TextAlign.Center)
          .onClick(() => { this.togglePasswordVisible(); })
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .borderRadius(AppConstants.RADIUS_MD)
      .backgroundColor($r('app.color.color_bg_card'))
      .border({ width: 1, color: $r('app.color.color_line') })
      .shadow(AppConstants.SHADOW_CARD)
      .alignItems(VerticalAlign.Center)

      // c) 资质承诺勾选（对齐 qn-commit）
      Row({ space: 8 }) {
        // 勾选框（对齐 qn-commit-check 20×20）
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

        // 承诺文案
        Text('我承诺具备农户资质，所售商品来源真实')
          .fontSize(12)
          .fontColor($r('app.color.color_text_2'))
          .layoutWeight(1)
          .onClick(() => { this.toggleCertAgreed(); })
      }
      .width('100%')
      .margin({ top: 2, bottom: 4 })
      .alignItems(VerticalAlign.Center)

      // d) 卖家登录按钮（对齐 qn-seller-btn 墨黑底）
      Row({ space: 6 }) {
        Text('卖家登录')
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
      .backgroundColor(this.isLogging ? $r('app.color.color_button_disabled') : $r('app.color.color_ink'))
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .opacity(this.isLogging ? 0.7 : 1)
      .margin({ top: 6 })
      .onClick(() => { this.doLogin(); })

      // e) 去注册链接
      Text('去注册')
        .fontSize(13)
        .fontColor($r('app.color.color_text_2'))
        .margin({ top: 12 })
        .decoration({ type: TextDecorationType.Underline, color: $r('app.color.color_text_2') })
        .onClick(() => { this.gotoRegister(); })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  /** 底部区域（对齐设计稿 qn-farmer-foot） */
  @Builder
  FooterSection() {
    Column({ space: 16 }) {
      // 资质认证提示卡（对齐 qn-cert-tip 黄底）
      Row({ space: 8 }) {
        Text('ℹ')
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
        Text('登录即同意')
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
    .margin({ top: 28 })
    .alignItems(HorizontalAlign.Center)
  }

  /** 底部黄色波浪装饰（对齐设计稿 qn-wave） */
  @Builder
  BottomWave() {
    Column()
      .width('100%')
      .height(50)
      .linearGradient({
        direction: GradientDirection.Right,
        colors: [
          ['rgba(255,226,52,0.5)', 0],
          ['rgba(255,217,61,0.8)', 0.5],
          ['rgba(255,226,52,0.5)', 1]
        ]
      })
      .hitTestBehavior(HitTestMode.Transparent)
  }
}
