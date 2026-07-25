/**
 * user_login - 用户端登录页（UI 复刻 v4.0，对齐 login.html 设计稿）
 * 遵循 spec 15.5.1：整页重写，1:1 还原设计稿
 *  - 顶部装饰气泡 + 吉祥物 + 品牌标题
 *  - 账号 + 密码登录表单（默认用户身份，无需选择）
 *  - 协议勾选 + 一键登录 + 第三方登录
 *  - 去注册入口
 * 业务逻辑保留：HttpUtil.post /user/login + TokenStore + NavigationHelper
 */

import { Logger, AppConstants, HttpUtil, TokenStore, ToastUtil, RouteName, NavigationHelper } from 'common';
import { ApiResponse, UserInfo } from 'common';

/** 登录请求参数 */
interface LoginRequest {
  phone: string;
  password: string;
  userType: string;
}

/** 登录响应数据 */
interface LoginResponse {
  token: string;
  userInfo: UserInfo;
}

@ComponentV2
export struct UserLogin {
  /** 账号（兼容后端 phone 字段） */
  @Local account: string = '';
  /** 密码 */
  @Local password: string = '';
  /** 是否显示密码 */
  @Local showPassword: boolean = false;
  /** 是否已同意协议 */
  @Local agreementChecked: boolean = true;
  /** 是否正在登录 */
  @Local isLogging: boolean = false;

  /** 一键登录 */
  private async doLogin(): Promise<void> {
    if (!this.agreementChecked) {
      ToastUtil.warning('请先同意用户协议和隐私政策');
      return;
    }
    if (this.account.trim().length === 0) {
      ToastUtil.warning('请输入账号');
      return;
    }
    if (this.password.length === 0) {
      ToastUtil.warning('请输入密码');
      return;
    }
    this.isLogging = true;
    try {
      const req: LoginRequest = {
        phone: this.account,
        password: this.password,
        userType: 'user'
      };
      const resp: ApiResponse<LoginResponse> = await HttpUtil.post<LoginResponse>('/user/login', req, {
        withAuth: false
      });
      if (resp.code === AppConstants.CODE_SUCCESS && resp.data) {
        await TokenStore.setToken(resp.data.token);
        await TokenStore.setUserInfo(resp.data.userInfo);
        ToastUtil.success('登录成功');
        Logger.info(AppConstants.SCENE_USER, { action: 'login_success', userId: resp.data.userInfo.userId });
        NavigationHelper.replace(RouteName.USER_HOME);
      } else {
        ToastUtil.error(resp.msg || '登录失败');
      }
    } catch (err) {
      Logger.error(AppConstants.SCENE_USER, { action: 'login_fail', error: (err as Error).message });
      ToastUtil.error('登录失败，请稍后重试');
    } finally {
      this.isLogging = false;
    }
  }

  /** 跳转注册页 */
  private gotoRegister(): void {
    NavigationHelper.push(RouteName.USER_REGISTER);
  }

  /** 第三方登录（mock） */
  private thirdPartyLogin(platform: string): void {
    ToastUtil.info(`${platform}登录暂未开通`);
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        // 主滚动内容
        Scroll() {
          Column() {
            // 1. 顶部装饰气泡（黄色 + 绿色径向渐变）
            this.DecoBubbles()

            // 2. 吉祥物 + 品牌标题区
            this.BrandHero()

            // 3. 表单区（账号 + 密码）
            this.FormSection()

            // 4. 协议勾选
            this.AgreementSection()

            // 5. 一键登录按钮
            this.LoginButton()

            // 6. 去注册链接
            this.GoRegisterLink()

            // 7. 分割线
            this.OrDivider()

            // 8. 第三方登录
            this.ThirdPartySection()

            // 9. 底部协议文字
            this.FooterText()
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
        .width(120)
        .height(120)
        .borderRadius(AppConstants.RADIUS_PILL)
        .linearGradient({
          angle: 0,
          colors: [['rgba(255,226,52,0.35)', 0.0], ['rgba(255,226,52,0)', 0.7]]
        })
        .position({ x: '70%', y: -30 })

      // 绿色气泡（左中）
      Column()
        .width(90)
        .height(90)
        .borderRadius(AppConstants.RADIUS_PILL)
        .linearGradient({
          angle: 0,
          colors: [['rgba(126,211,33,0.22)', 0.0], ['rgba(126,211,33,0)', 0.7]]
        })
        .position({ x: -30, y: 100 })
    }
    .width('100%')
    .height(120)
  }

  /** 吉祥物 + 品牌标题 */
  @Builder
  BrandHero() {
    Column({ space: 8 }) {
      // 吉祥物图片（140×140 圆形 + 黄底 + 白边 + 阴影）
      Image($r('app.media.mascot_farmer'))
        .width(140)
        .height(140)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor($r('app.color.color_yellow_tint'))
        .border({ width: 4, color: $r('app.color.color_bg_card') })
        .shadow({
          radius: 28,
          color: 'rgba(255,217,61,0.42)',
          offsetX: 0,
          offsetY: 10
        })
        .objectFit(ImageFit.Cover)
        .margin({ top: 16 })

      // 品牌标题 "趣农" + 绿色圆点
      Row({ space: 6 }) {
        Text('趣农')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.color_ink'))
          .letterSpacing(2)
        Text('')
          .width(8)
          .height(8)
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_green'))
      }
      .margin({ top: 12 })

      // 副标题
      Text('新鲜直达 · 助农优选')
        .fontSize(13)
        .fontColor($r('app.color.color_text_3'))
        .letterSpacing(1)
        .margin({ top: 6 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  /** 表单区 */
  @Builder
  FormSection() {
    Column({ space: 12 }) {
      // 账号输入框
      Row() {
        Text('👤')
          .fontSize(18)
          .margin({ right: 10 })
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
      .height(46)
      .borderRadius(AppConstants.RADIUS_MD)
      .backgroundColor($r('app.color.color_fill'))
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .margin({ top: 28 })

      // 密码输入框 + 显示密码切换
      Row() {
        Text('🔒')
          .fontSize(18)
          .margin({ right: 10 })
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

        // 显示/隐藏密码
        Text(this.showPassword ? '👁️' : '🙈')
          .fontSize(18)
          .width(28)
          .height(28)
          .textAlign(TextAlign.Center)
          .margin({ left: 8 })
          .onClick(() => { this.showPassword = !this.showPassword; })
      }
      .width('100%')
      .height(46)
      .borderRadius(AppConstants.RADIUS_MD)
      .backgroundColor($r('app.color.color_fill'))
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
  }

  /** 协议勾选 */
  @Builder
  AgreementSection() {
    Row({ space: 8 }) {
      // 复选框
      Text(this.agreementChecked ? '✓' : '')
        .fontSize(10)
        .fontColor(Color.White)
        .width(16)
        .height(16)
        .borderRadius(4)
        .backgroundColor(this.agreementChecked ? $r('app.color.color_ink') : $r('app.color.color_bg_card'))
        .border({ width: 1.5, color: this.agreementChecked ? $r('app.color.color_ink') : $r('app.color.color_line_2') })
        .textAlign(TextAlign.Center)
        .onClick(() => { this.agreementChecked = !this.agreementChecked; })

      // 协议文字
      Text() {
        Span('我已阅读并同意')
          .fontColor($r('app.color.color_text_3'))
          .fontSize(12)
        Span('《用户协议》')
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .fontSize(12)
        Span('和')
          .fontColor($r('app.color.color_text_3'))
          .fontSize(12)
        Span('《隐私政策》')
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .fontSize(12)
      }
      .layoutWeight(1)
      .lineHeight(18)
    }
    .width('100%')
    .padding({ left: 2, right: 2, top: 8, bottom: 16 })
    .alignItems(VerticalAlign.Top)
  }

  /** 一键登录按钮 */
  @Builder
  LoginButton() {
    Row({ space: 6 }) {
      Text(this.isLogging ? '登录中...' : '一键登录')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
      if (!this.isLogging) {
        Text('→')
          .fontSize(18)
          .fontColor(Color.White)
      }
    }
    .width('100%')
    .height(46)
    .borderRadius(AppConstants.RADIUS_MD)
    .backgroundColor(this.isLogging ? $r('app.color.color_button_disabled') : $r('app.color.color_ink'))
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .margin({ top: 4 })
    .onClick(() => { if (!this.isLogging) this.doLogin(); })
  }

  /** 去注册链接 */
  @Builder
  GoRegisterLink() {
    Row({ space: 4 }) {
      Text('还没有账号？')
        .fontSize(13)
        .fontColor($r('app.color.color_text_3'))
      Text('去注册')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.color_ink'))
        .decoration({ type: TextDecorationType.Underline })
        .onClick(() => this.gotoRegister())
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .margin({ top: 16 })
  }

  /** 分割线 */
  @Builder
  OrDivider() {
    Row({ space: 12 }) {
      Column()
        .layoutWeight(1)
        .height(1)
        .backgroundColor($r('app.color.color_line'))
      Text('或使用以下方式登录')
        .fontSize(12)
        .fontColor($r('app.color.color_text_3'))
      Column()
        .layoutWeight(1)
        .height(1)
        .backgroundColor($r('app.color.color_line'))
    }
    .width('100%')
    .margin({ top: 18, bottom: 18 })
    .alignItems(VerticalAlign.Center)
  }

  /** 第三方登录 */
  @Builder
  ThirdPartySection() {
    Row({ space: 24 }) {
      // 微信登录
      Text('💬')
        .fontSize(22)
        .fontColor(Color.White)
        .width(44)
        .height(44)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor('#07C160')
        .shadow(AppConstants.SHADOW_CARD)
        .textAlign(TextAlign.Center)
        .onClick(() => this.thirdPartyLogin('微信'))

      // Apple 登录
      Text('')
        .fontSize(22)
        .fontColor(Color.White)
        .width(44)
        .height(44)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor($r('app.color.color_ink'))
        .shadow(AppConstants.SHADOW_CARD)
        .textAlign(TextAlign.Center)
        .onClick(() => this.thirdPartyLogin('Apple'))

      // 手机号登录
      Text('📞')
        .fontSize(22)
        .fontColor(Color.White)
        .width(44)
        .height(44)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor($r('app.color.color_info'))
        .shadow(AppConstants.SHADOW_CARD)
        .textAlign(TextAlign.Center)
        .onClick(() => this.thirdPartyLogin('手机号'))
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .margin({ bottom: 18 })
  }

  /** 底部协议文字 */
  @Builder
  FooterText() {
    Column({ space: 4 }) {
      Text('登录即代表同意趣农 服务协议 与 隐私政策')
        .fontSize(12)
        .fontColor($r('app.color.color_text_3'))
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .margin({ top: 8 })
  }
}
