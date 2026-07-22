/**
 * user_register - 用户端注册页
 * 遵循 spec 1.3.2：
 *  - 注册方式：账号（手机号）+ 密码 + 确认密码 + 昵称（可选）
 *  - 密码至少6位，两次密码必须一致
 *  - 注册成功自动登录并跳转首页 pages/home/home_page
 */

import { Logger, AppConstants, HttpUtil, TokenStore, ToastUtil, RouteName, NavigationHelper } from 'common';
import { ApiResponse, UserInfo } from 'common';

interface RegisterRequest {
  phone: string;
  password: string;
  nickname: string;
  userType: 'user';
}

interface RegisterResponse {
  token: string;
  userInfo: UserInfo;
}

@ComponentV2
export struct UserRegister {
  /** 账号（手机号） */
  @Local phone: string = '';
  /** 昵称（可选） */
  @Local nickname: string = '';
  /** 密码 */
  @Local password: string = '';
  /** 确认密码 */
  @Local confirmPassword: string = '';
  /** 是否正在注册 */
  @Local isSubmitting: boolean = false;

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
    this.isSubmitting = true;
    try {
      const req: RegisterRequest = {
        phone: this.phone,
        password: this.password,
        nickname: this.nickname,
        userType: 'user'
      };
      const resp: ApiResponse<RegisterResponse> = await HttpUtil.post<RegisterResponse>('/user/register', req, {
        withAuth: false
      });
      if (resp.code === AppConstants.CODE_SUCCESS && resp.data) {
        // 注册成功自动登录
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
      Column({ space: 20 }) {
        // 顶部品牌区
        Column({ space: 8 }) {
          Text('🌾')
            .fontSize(56)
            .margin({ bottom: 8 })
          Text('注册账号')
            .fontSize(22)
            .fontColor($r('app.color.color_text_primary'))
            .fontWeight(FontWeight.Bold)
          Text('加入助农平台，开启助农之旅')
            .fontSize(13)
            .fontColor($r('app.color.color_text_secondary'))
        }
        .width('100%')
        .margin({ top: 48, bottom: 24 })

        // 账号输入框
        Column({ space: 8 }) {
          Text('账号（手机号）')
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

        // 昵称输入框（可选）
        Column({ space: 8 }) {
          Text('昵称（选填）')
            .fontSize(14)
            .fontColor($r('app.color.color_text_secondary'))
            .alignSelf(ItemAlign.Start)
          TextInput({ text: this.nickname, placeholder: '请输入昵称，不填则自动生成' })
            .type(InputType.Normal)
            .maxLength(20)
            .height(48)
            .borderRadius(12)
            .backgroundColor($r('app.color.color_bg_page'))
            .padding({ left: 16, right: 16 })
            .fontSize(16)
            .onChange((value: string) => {
              this.nickname = value;
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

        // 确认密码输入框
        Column({ space: 8 }) {
          Text('确认密码')
            .fontSize(14)
            .fontColor($r('app.color.color_text_secondary'))
            .alignSelf(ItemAlign.Start)
          TextInput({ text: this.confirmPassword, placeholder: '请再次输入密码' })
            .type(InputType.Password)
            .maxLength(32)
            .height(48)
            .borderRadius(12)
            .backgroundColor($r('app.color.color_bg_page'))
            .padding({ left: 16, right: 16 })
            .fontSize(16)
            .onChange((value: string) => {
              this.confirmPassword = value;
            })
        }
        .width('100%')

        // 注册按钮
        Button('注册')
          .width('100%')
          .height(48)
          .borderRadius(24)
          .backgroundColor(this.isSubmitting ? $r('app.color.color_button_disabled') : $r('app.color.color_primary'))
          .fontColor(Color.White)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .enabled(!this.isSubmitting)
          .margin({ top: 12 })
          .onClick(() => {
            this.doRegister();
          })

        // 去登录
        Row({ space: 4 }) {
          Text('已有账号？')
            .fontSize(14)
            .fontColor($r('app.color.color_text_secondary'))
          Text('去登录')
            .fontSize(14)
            .fontColor($r('app.color.color_primary'))
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 8 })
        .onClick(() => {
          this.gotoLogin();
        })
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
