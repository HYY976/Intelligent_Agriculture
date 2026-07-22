/**
 * user_login - 用户端登录页
 * 遵循 spec 1.3.2：
 *  - 登录方式：账号（手机号）+ 密码
 *  - JWT 7天有效期，存储到 Preferences（sessionStorage 改为 Preferences 持久化）
 *  - 登录成功跳转首页 pages/home/home_page
 */

import { Logger, AppConstants, HttpUtil, TokenStore, ToastUtil, RouteName, NavigationHelper } from 'common';
import { ApiResponse, UserInfo } from 'common';

interface LoginRequest {
  phone: string;
  password: string;
  userType: 'user';
}

interface LoginResponse {
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
      const req: LoginRequest = { phone: this.phone, password: this.password, userType: 'user' };
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

  build() {
    NavDestination() {
      Column({ space: 24 }) {
        // 顶部品牌区
        Column({ space: 8 }) {
          Text('🌾')
            .fontSize(72)
            .margin({ bottom: 16 })
          Text('助农平台')
            .fontSize(24)
            .fontColor($r('app.color.color_text_primary'))
            .fontWeight(FontWeight.Bold)
          Text('欢迎来到助农平台')
            .fontSize(14)
            .fontColor($r('app.color.color_text_secondary'))
        }
        .width('100%')
        .margin({ top: 60, bottom: 32 })

        // 账号输入框
        Column({ space: 8 }) {
          Text('账号')
            .fontSize(14)
            .fontColor($r('app.color.color_text_secondary'))
            .alignSelf(ItemAlign.Start)
          TextInput({ text: this.phone, placeholder: '请输入手机号' })
            .type(InputType.PhoneNumber)
            .maxLength(11)
            .height(48)
            .borderRadius(12)
            .backgroundColor($r('app.color.color_bg_page'))
            .padding({ left: 16, right: 16 })
            .fontSize(16)
            .onChange((value: string) => {
              this.phone = value;
            })
        }
        .width('100%')

        // 密码输入框
        Column({ space: 8 }) {
          Text('密码')
            .fontSize(14)
            .fontColor($r('app.color.color_text_secondary'))
            .alignSelf(ItemAlign.Start)
          TextInput({ text: this.password, placeholder: '请输入密码（至少6位）' })
            .type(InputType.Password)
            .maxLength(32)
            .height(48)
            .borderRadius(12)
            .backgroundColor($r('app.color.color_bg_page'))
            .padding({ left: 16, right: 16 })
            .fontSize(16)
            .onChange((value: string) => {
              this.password = value;
            })
        }
        .width('100%')

        // 登录按钮
        Button('登录')
          .width('100%')
          .height(48)
          .borderRadius(24)
          .backgroundColor(this.isLogging ? $r('app.color.color_button_disabled') : $r('app.color.color_primary'))
          .fontColor(Color.White)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .enabled(!this.isLogging)
          .margin({ top: 16 })
          .onClick(() => {
            this.doLogin();
          })

        // 去注册
        Row({ space: 4 }) {
          Text('没有账号？')
            .fontSize(14)
            .fontColor($r('app.color.color_text_secondary'))
          Text('去注册')
            .fontSize(14)
            .fontColor($r('app.color.color_primary'))
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 8 })
        .onClick(() => {
          this.gotoRegister();
        })

        // 用户协议
        Text('登录即表示同意《用户协议》和《隐私政策》')
          .fontSize(12)
          .fontColor($r('app.color.color_text_hint'))
          .margin({ top: 16 })
      }
      .width('100%')
      .height('100%')
      .padding({ left: 24, right: 24 })
      .backgroundColor($r('app.color.color_bg_card'))
      .alignItems(HorizontalAlign.Center)
    }
    .hideTitleBar(true)
  }
}
