/**
 * farmer_login - 农户卖家端登录页
 * 遵循 spec 1.3.2 / 13.2：
 *  - 登录方式：手机号 + 验证码 + 资质Mock认证（UI 预留）
 *  - JWT 7天有效期，存储到 Preferences
 *  - 登录成功跳转首页 pages/home/home_page（营收异形面板）
 *  - 资质Mock认证：登录前需勾选"卖家资质承诺"复选框（UI 预留，真实资质上传在 pages/profile/certification）
 *  现阶段验证码 Mock：任意 6 位数字均可登录成功（后端 Mock）
 */
import { Logger, AppConstants, HttpUtil, TokenStore, ToastUtil, NavigationHelper, RouteName } from 'common';
import { ApiResponse, UserInfo } from 'common';

interface FarmerLoginRequest {
  phone: string;
  code: string;
  userType: 'farmer';
  /** 资质Mock认证：已勾选资质承诺 */
  certAgreed: boolean;
}

interface FarmerLoginResponse {
  token: string;
  userInfo: UserInfo;
  /** 资质认证状态：pending=待认证 / approved=已认证 / rejected=驳回 */
  certStatus: 'pending' | 'approved' | 'rejected';
}

/** 发送短信验证码请求体 */
interface SmsCodeRequest {
  phone: string;
}

@ComponentV2
export struct FarmerLogin {
  /** 手机号 */
  @Local phone: string = '';
  /** 验证码 */
  @Local code: string = '';
  /** 资质Mock认证：是否已勾选资质承诺 */
  @Local certAgreed: boolean = false;
  /** 获取验证码按钮文案 */
  @Local codeButtonText: string = '获取验证码';
  /** 是否正在倒计时 */
  @Local codeButtonDisabled: boolean = false;
  /** 是否正在登录 */
  @Local isLogging: boolean = false;
  /** 倒计时定时器 */
  private countdownTimerId: number | undefined = undefined;

  aboutToDisappear(): void {
    if (this.countdownTimerId !== undefined) {
      clearInterval(this.countdownTimerId);
      this.countdownTimerId = undefined;
    }
  }

  /** 校验手机号格式 */
  private isPhoneValid(): boolean {
    const phoneRegex: RegExp = /^1[3-9]\d{9}$/;
    return phoneRegex.test(this.phone);
  }

  /** 获取验证码（Mock：任意手机号都发送成功） */
  private async sendCode(): Promise<void> {
    if (!this.isPhoneValid()) {
      ToastUtil.warning('请输入正确的手机号');
      return;
    }
    try {
      const smsReq: SmsCodeRequest = { phone: this.phone };
      const resp = await HttpUtil.post<null>('/farmer/sms_code', smsReq, {
        withAuth: false
      });
      if (resp.code === AppConstants.CODE_SUCCESS) {
        ToastUtil.success('验证码已发送');
        this.startCodeCountdown();
      } else {
        ToastUtil.error(resp.msg || '验证码发送失败');
      }
    } catch (err) {
      // Mock 阶段直接进入倒计时
      ToastUtil.success('验证码已发送（Mock: 任意6位数字）');
      this.startCodeCountdown();
    }
  }

  /** 启动 60 秒倒计时 */
  private startCodeCountdown(): void {
    let remainSec: number = 60;
    this.codeButtonDisabled = true;
    this.codeButtonText = `${remainSec}s 后重试`;
    this.countdownTimerId = setInterval(() => {
      remainSec -= 1;
      if (remainSec <= 0) {
        if (this.countdownTimerId !== undefined) {
          clearInterval(this.countdownTimerId);
          this.countdownTimerId = undefined;
        }
        this.codeButtonDisabled = false;
        this.codeButtonText = '获取验证码';
      } else {
        this.codeButtonText = `${remainSec}s 后重试`;
      }
    }, 1000);
  }

  /** 登录 */
  private async doLogin(): Promise<void> {
    if (!this.isPhoneValid()) {
      ToastUtil.warning('请输入正确的手机号');
      return;
    }
    if (this.code.length !== 6) {
      ToastUtil.warning('请输入6位验证码');
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
        code: this.code,
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

  build() {
    NavDestination() {
      Column({ space: 20 }) {
        // 顶部品牌区
        Column({ space: 8 }) {
          Text('🌾')
            .fontSize(72)
            .margin({ bottom: 16 })
          Text('助农卖家')
            .fontSize(24)
            .fontColor($r('app.color.color_text_primary'))
            .fontWeight(FontWeight.Bold)
          Text('商品上架 · 直播带货 · 营收管理')
            .fontSize(14)
            .fontColor($r('app.color.color_text_secondary'))
        }
        .width('100%')
        .margin({ top: 60, bottom: 24 })

        // 手机号输入框
        Column({ space: 8 }) {
          Text('手机号')
            .fontSize(14)
            .fontColor($r('app.color.color_text_secondary'))
            .alignSelf(ItemAlign.Start)
          TextInput({ text: this.phone })
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

        // 验证码输入框 + 获取验证码按钮
        Column({ space: 8 }) {
          Text('验证码')
            .fontSize(14)
            .fontColor($r('app.color.color_text_secondary'))
            .alignSelf(ItemAlign.Start)
          Row({ space: 12 }) {
            TextInput({ text: this.code })
              .type(InputType.Number)
              .maxLength(6)
              .height(48)
              .borderRadius(12)
              .backgroundColor($r('app.color.color_bg_page'))
              .padding({ left: 16, right: 16 })
              .fontSize(16)
              .layoutWeight(1)
              .onChange((value: string) => {
                this.code = value;
              })
            Button(this.codeButtonText)
              .height(48)
              .borderRadius(12)
              .backgroundColor(this.codeButtonDisabled ? $r('app.color.color_button_disabled') : $r('app.color.color_secondary'))
              .fontColor(Color.White)
              .fontSize(14)
              .enabled(!this.codeButtonDisabled)
              .onClick(() => {
                this.sendCode();
              })
          }
          .width('100%')
        }
        .width('100%')

        // 资质Mock认证：卖家资质承诺（spec 1.3.2 / 13.2 UI 预留）
        Row({ space: 8 }) {
          Checkbox()
            .select(this.certAgreed)
            .selectedColor($r('app.color.color_primary'))
            .width(20)
            .height(20)
            .onChange((checked: boolean) => {
              this.certAgreed = checked;
            })
          Text('我已阅读并同意《卖家资质承诺》，承诺所售农产品来源合法、质量合格')
            .fontSize(12)
            .fontColor($r('app.color.color_text_secondary'))
            .layoutWeight(1)
            .onClick(() => {
              this.certAgreed = !this.certAgreed;
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
        .padding({ top: 8 })

        // 登录按钮
        Button('卖家登录')
          .width('100%')
          .height(48)
          .borderRadius(24)
          .backgroundColor(this.isLogging ? $r('app.color.color_button_disabled') : $r('app.color.color_secondary'))
          .fontColor(Color.White)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .enabled(!this.isLogging)
          .margin({ top: 8 })
          .onClick(() => {
            this.doLogin();
          })

        // 资质认证入口提示（spec 13.2：UI 预留，真实认证在个人中心）
        Text('资质认证将在个人中心完成（Mock 认证）')
          .fontSize(12)
          .fontColor($r('app.color.color_text_hint'))
          .margin({ top: 12 })

        // 用户协议
        Text('登录即表示同意《用户协议》和《隐私政策》')
          .fontSize(12)
          .fontColor($r('app.color.color_text_hint'))
          .margin({ top: 4 })
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
