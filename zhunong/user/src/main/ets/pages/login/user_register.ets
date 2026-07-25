/**
 * user_register - 用户端注册页（UI 复刻 v4.0，对齐 user-register.html 设计稿）
 * 遵循 spec 15.5.1：整页重写，1:1 还原设计稿
 *  - 顶部装饰气泡 + 状态栏 + 返回按钮
 *  - 品牌 Logo 区（黄色渐变方块 + 吉祥物装饰）
 *  - 账号 + 密码 + 确认密码表单（带眼睛切换）
 *  - 注册按钮 + 去登录链接
 *  - 底部黄色波浪装饰
 * 业务逻辑保留：HttpUtil.post /user/register + TokenStore + NavigationHelper
 */

import { Logger, AppConstants, HttpUtil, TokenStore, ToastUtil, RouteName, NavigationHelper } from 'common';
import { ApiResponse, UserInfo } from 'common';

/** 注册请求参数 */
interface RegisterRequest {
  phone: string;
  password: string;
  nickname: string;
  userType: string;
}

/** 注册响应数据 */
interface RegisterResponse {
  token: string;
  userInfo: UserInfo;
}

@ComponentV2
export struct UserRegister {
  /** 账号（兼容后端 phone 字段） */
  @Local account: string = '';
  /** 密码 */
  @Local password: string = '';
  /** 确认密码 */
  @Local confirmPassword: string = '';
  /** 是否显示密码 */
  @Local showPassword: boolean = false;
  /** 是否显示确认密码 */
  @Local showConfirmPassword: boolean = false;
  /** 是否正在注册 */
  @Local isSubmitting: boolean = false;

  /** 注册 */
  private async doRegister(): Promise<void> {
    if (this.account.trim().length === 0) {
      ToastUtil.warning('请输入账号');
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
    this.isSubmitting = true;
    try {
      const req: RegisterRequest = {
        phone: this.account,
        password: this.password,
        nickname: '',
        userType: 'user'
      };
      const resp: ApiResponse<RegisterResponse> = await HttpUtil.post<RegisterResponse>('/user/register', req, {
        withAuth: false
      });
      if (resp.code === AppConstants.CODE_SUCCESS && resp.data) {
        await TokenStore.setToken(resp.data.token);
        await TokenStore.setUserInfo(resp.data.userInfo);
        ToastUtil.success('注册成功');
        Logger.info(AppConstants.SCENE_USER, { action: 'register_success', userId: resp.data.userInfo.userId });
        NavigationHelper.replace(RouteName.USER_HOME);
      } else {
        ToastUtil.error(resp.msg || '注册失败');
      }
    } catch (err) {
      Logger.error(AppConstants.SCENE_USER, { action: 'register_fail', error: (err as Error).message });
      ToastUtil.error('注册失败，请稍后重试');
    } finally {
      this.isSubmitting = false;
    }
  }

  /** 返回登录页 */
  private gotoLogin(): void {
    NavigationHelper.pop();
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        Scroll() {
          Column() {
            // 1. 顶部装饰气泡
            this.DecoBubbles()

            // 2. 返回按钮
            this.BackBar()

            // 3. 品牌 Logo 区
            this.BrandHero()

            // 4. 表单区
            this.FormSection()

            // 5. 注册按钮
            this.RegisterButton()

            // 6. 去登录链接
            this.GoLoginLink()

            // 7. 底部协议文字
            this.AgreementText()
          }
          .width('100%')
          .padding({ left: 24, right: 24, bottom: 32 })
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_cream'))
    }
    .hideTitleBar(true)
  }

  /** 顶部装饰气泡 */
  @Builder
  DecoBubbles() {
    Stack() {
      // 黄色气泡（右上）
      Column()
        .width(130)
        .height(130)
        .borderRadius(AppConstants.RADIUS_PILL)
        .linearGradient({
          angle: 0,
          colors: [['rgba(255,226,52,0.32)', 0.0], ['rgba(255,226,52,0)', 0.7]]
        })
        .position({ x: '68%', y: -36 })

      // 绿色气泡（左中）
      Column()
        .width(96)
        .height(96)
        .borderRadius(AppConstants.RADIUS_PILL)
        .linearGradient({
          angle: 0,
          colors: [['rgba(126,211,33,0.20)', 0.0], ['rgba(126,211,33,0)', 0.7]]
        })
        .position({ x: -34, y: 120 })
    }
    .width('100%')
    .height(140)
  }

  /** 返回按钮 */
  @Builder
  BackBar() {
    Row() {
      Text('‹')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.color_ink'))
        .width(36)
        .height(36)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor($r('app.color.color_bg_card'))
        .shadow(AppConstants.SHADOW_CARD)
        .textAlign(TextAlign.Center)
        .onClick(() => this.gotoLogin())
    }
    .width('100%')
    .height(40)
    .padding({ top: 4 })
  }

  /** 品牌 Logo 区 */
  @Builder
  BrandHero() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column({ space: 6 }) {
        // 黄色渐变 Logo 方块 + 萌芽图标
        Text('🌱')
          .fontSize(36)
          .fontColor($r('app.color.color_ink'))
          .width(80)
          .height(80)
          .borderRadius(AppConstants.RADIUS_XL)
          .linearGradient({
            angle: 135,
            colors: [[$r('app.color.color_yellow'), 0.0], [$r('app.color.color_yellow_deep'), 1.0]]
          })
          .shadow({
            radius: 26,
            color: 'rgba(255,217,61,0.42)',
            offsetX: 0,
            offsetY: 10
          })
          .border({ width: 3, color: $r('app.color.color_bg_card') })
          .textAlign(TextAlign.Center)
          .margin({ top: 8 })

        // 品牌标题
        Text('趣农')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.color_ink'))
          .letterSpacing(1)
          .margin({ top: 12 })

        // 副标题
        Text('新鲜农货 产地直发')
          .fontSize(13)
          .fontColor($r('app.color.color_text_3'))
          .letterSpacing(0.5)
          .margin({ top: 6 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      // 右上角吉祥物装饰
      Image($r('app.media.mascot_farmer'))
        .width(60)
        .height(60)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor($r('app.color.color_yellow_tint'))
        .border({ width: 3, color: $r('app.color.color_bg_card') })
        .shadow(AppConstants.SHADOW_FLOAT)
        .objectFit(ImageFit.Cover)
        .position({ x: '82%', y: 0 })
    }
    .width('100%')
  }

  /** 表单区 */
  @Builder
  FormSection() {
    Column({ space: 14 }) {
      // 账号输入框
      Row() {
        Text('👤')
          .fontSize(18)
          .margin({ right: 12 })
        TextInput({ text: this.account, placeholder: '请输入账号' })
          .layoutWeight(1)
          .type(InputType.Normal)
          .maxLength(32)
          .backgroundColor(Color.Transparent)
          .borderRadius(0)
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .placeholderColor($r('app.color.color_text_4'))
          .placeholderFont({ size: 14 })
          .onChange((val: string) => { this.account = val; })
      }
      .width('100%')
      .height(52)
      .borderRadius(AppConstants.RADIUS_MD)
      .backgroundColor($r('app.color.color_bg_card'))
      .border({ width: 1, color: $r('app.color.color_line') })
      .shadow(AppConstants.SHADOW_CARD)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .margin({ top: 36 })

      // 密码输入框
      Row() {
        Text('🔒')
          .fontSize(18)
          .margin({ right: 12 })
        TextInput({ text: this.password, placeholder: '请输入密码' })
          .layoutWeight(1)
          .type(this.showPassword ? InputType.Normal : InputType.Password)
          .maxLength(32)
          .backgroundColor(Color.Transparent)
          .borderRadius(0)
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .placeholderColor($r('app.color.color_text_4'))
          .placeholderFont({ size: 14 })
          .onChange((val: string) => { this.password = val; })
        Text(this.showPassword ? '👁️' : '🙈')
          .fontSize(18)
          .width(28)
          .height(28)
          .textAlign(TextAlign.Center)
          .margin({ left: 8 })
          .onClick(() => { this.showPassword = !this.showPassword; })
      }
      .width('100%')
      .height(52)
      .borderRadius(AppConstants.RADIUS_MD)
      .backgroundColor($r('app.color.color_bg_card'))
      .border({ width: 1, color: $r('app.color.color_line') })
      .shadow(AppConstants.SHADOW_CARD)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      // 确认密码输入框
      Row() {
        Text('🔒')
          .fontSize(18)
          .margin({ right: 12 })
        TextInput({ text: this.confirmPassword, placeholder: '请再次输入密码' })
          .layoutWeight(1)
          .type(this.showConfirmPassword ? InputType.Normal : InputType.Password)
          .maxLength(32)
          .backgroundColor(Color.Transparent)
          .borderRadius(0)
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .placeholderColor($r('app.color.color_text_4'))
          .placeholderFont({ size: 14 })
          .onChange((val: string) => { this.confirmPassword = val; })
        Text(this.showConfirmPassword ? '👁️' : '🙈')
          .fontSize(18)
          .width(28)
          .height(28)
          .textAlign(TextAlign.Center)
          .margin({ left: 8 })
          .onClick(() => { this.showConfirmPassword = !this.showConfirmPassword; })
      }
      .width('100%')
      .height(52)
      .borderRadius(AppConstants.RADIUS_MD)
      .backgroundColor($r('app.color.color_bg_card'))
      .border({ width: 1, color: $r('app.color.color_line') })
      .shadow(AppConstants.SHADOW_CARD)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
  }

  /** 注册按钮 */
  @Builder
  RegisterButton() {
    Row({ space: 6 }) {
      Text(this.isSubmitting ? '注册中...' : '注册')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .letterSpacing(1)
      if (!this.isSubmitting) {
        Text('→')
          .fontSize(18)
          .fontColor(Color.White)
      }
    }
    .width('100%')
    .height(48)
    .borderRadius(AppConstants.RADIUS_MD)
    .backgroundColor(this.isSubmitting ? $r('app.color.color_button_disabled') : $r('app.color.color_ink'))
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .margin({ top: 8 })
    .onClick(() => { if (!this.isSubmitting) this.doRegister(); })
  }

  /** 去登录链接 */
  @Builder
  GoLoginLink() {
    Text('去登录')
      .fontSize(13)
      .fontColor($r('app.color.color_text_2'))
      .decoration({ type: TextDecorationType.Underline })
      .margin({ top: 16 })
      .onClick(() => this.gotoLogin())
  }

  /** 底部协议文字 */
  @Builder
  AgreementText() {
    Text('注册即同意《用户协议》和《隐私政策》')
      .fontSize(11)
      .fontColor($r('app.color.color_text_3'))
      .textAlign(TextAlign.Center)
      .margin({ top: 24 })
  }
}
