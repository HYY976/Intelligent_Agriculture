/**
 * user_login - 用户端登录页
 * 对齐农户端 farmer_login.ets 格式：
 *  - 奶油白背景 + 顶部装饰气泡（黄/绿径向渐变模拟）
 *  - 品牌Logo区：黄色渐变 80×80 圆角Logo + 萌芽图标 + 右侧吉祥物 + "趣农"标题 + 副标题
 *  - 表单区：手机号/密码输入卡（白底圆角14+阴影+描边+左侧图标）
 *  - 登录按钮（墨黑底白字 + 右箭头图标）
 *  - "去注册"下划线链接
 *  - 底部区域：用户协议文字
 * spec 15.5.1：账号（手机号）+ 密码登录
 */

import { Logger, AppConstants, HttpUtil, TokenStore, ToastUtil, NavigationHelper, RouteName } from 'common';
import { ApiResponse, UserInfo } from 'common';

/** 登录请求体（spec 15.5.1 ArkTS 严格模式要求具体 interface） */
interface UserLoginRequest {
  phone: string;
  password: string;
  userType: 'user';
}

/** 登录响应体 */
interface UserLoginResponse {
  token: string;
  userInfo: UserInfo;
}

@ComponentV2
export struct UserLogin {
  /** 账号（手机号） */
  @Local phone: string = '';
  /** 密码 */
  @Local password: string = '';
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
    this.isLogging = true;
    try {
      const req: UserLoginRequest = {
        phone: this.phone,
        password: this.password,
        userType: 'user'
      };
      const resp: ApiResponse<UserLoginResponse> = await HttpUtil.post<UserLoginResponse>('/user/login', req, {
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

  /** 顶部装饰气泡（对齐设计稿 qn-deco-1/2 径向渐变模拟） */
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
        .position({ left: -20, top: 40 })
    }
    .width('100%')
    .height(80)
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

        // 标题"趣农"
        Text('趣农')
          .fontSize(24)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .letterSpacing(1)
          .margin({ top: 10 })

        // 副标题
        Text('新鲜直达 · 助农优选')
          .fontSize(13)
          .fontColor($r('app.color.color_text_3'))
          .letterSpacing(0.5)
      }
      .width('100%')
      .margin({ top: 12 })
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

      // b) 密码输入框（对齐 qn-farmer-field，系统 Password 类型自带显隐切换，无需手动添加眼睛图标）
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

      // c) 登录按钮（对齐 qn-login-btn 墨黑底）
      Row({ space: 6 }) {
        Text('登录')
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

      // d) 去注册链接
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

  /** 底部区域（对齐设计稿 qn-foot） */
  @Builder
  FooterSection() {
    Column({ space: 16 }) {
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
    .margin({ top: 12 })
    .alignItems(HorizontalAlign.Center)
  }
}
