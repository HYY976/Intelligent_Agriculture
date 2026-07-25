/**
 * user_login - 用户端登录页（UI 复刻 v4.0，对齐 login.html 设计稿）
 * 遵循 spec 15.5.1：整页重写，1:1 还原设计稿
 *  - 顶部装饰气泡 + 吉祥物 + 品牌标题
 *  - 角色选择卡片（用户/农民/管理员三端切换）
 *  - 手机号 + 验证码登录表单
 *  - 协议勾选 + 一键登录 + 第三方登录
 *  - 底部黄色波浪装饰
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

/** 角色类型 */
type LoginRole = 'user' | 'farmer' | 'admin';

/** 角色卡片数据 */
interface RoleCardData {
  role: LoginRole;
  icon: string;
  name: string;
  desc: string;
}

@ComponentV2
export struct UserLogin {
  /** 手机号 */
  @Local phone: string = '';
  /** 验证码（作为密码发送到后端） */
  @Local code: string = '';
  /** 当前选中角色 */
  @Local selectedRole: LoginRole = 'user';
  /** 是否已同意协议 */
  @Local agreementChecked: boolean = true;
  /** 是否正在登录 */
  @Local isLogging: boolean = false;
  /** 验证码倒计时秒数（0 表示可发送） */
  @Local codeCountdown: number = 0;

  /** 倒计时定时器 */
  private countdownTimerId: number = -1;

  /** 角色卡片数据 */
  private readonly roleCards: RoleCardData[] = [
    { role: 'user', icon: '👤', name: '用户端', desc: '买菜购物' },
    { role: 'farmer', icon: '🌱', name: '农民端', desc: '开店带货' },
    { role: 'admin', icon: '🛡️', name: '管理员端', desc: '后台运营' }
  ];

  aboutToDisappear(): void {
    if (this.countdownTimerId !== -1) {
      clearInterval(this.countdownTimerId);
      this.countdownTimerId = -1;
    }
  }

  /** 校验手机号格式 */
  private isPhoneValid(): boolean {
    const phoneRegex: RegExp = /^1[3-9]\d{9}$/;
    return phoneRegex.test(this.phone);
  }

  /** 发送验证码（mock：提示已发送 + 启动 60s 倒计时） */
  private sendCode(): void {
    if (this.codeCountdown > 0) {
      return;
    }
    if (!this.isPhoneValid()) {
      ToastUtil.warning('请输入正确的手机号');
      return;
    }
    ToastUtil.success('验证码已发送');
    this.codeCountdown = 60;
    this.countdownTimerId = setInterval(() => {
      this.codeCountdown -= 1;
      if (this.codeCountdown <= 0) {
        this.codeCountdown = 0;
        if (this.countdownTimerId !== -1) {
          clearInterval(this.countdownTimerId);
          this.countdownTimerId = -1;
        }
      }
    }, 1000);
  }

  /** 选择角色 */
  private selectRole(role: LoginRole): void {
    this.selectedRole = role;
    if (role === 'farmer') {
      NavigationHelper.replace(RouteName.FARMER_LOGIN);
    } else if (role === 'admin') {
      NavigationHelper.replace(RouteName.ADMIN_LOGIN);
    }
  }

  /** 一键登录 */
  private async doLogin(): Promise<void> {
    if (!this.agreementChecked) {
      ToastUtil.warning('请先同意用户协议和隐私政策');
      return;
    }
    if (!this.isPhoneValid()) {
      ToastUtil.warning('请输入正确的手机号');
      return;
    }
    if (this.code.length < 6) {
      ToastUtil.warning('请输入6位验证码');
      return;
    }
    this.isLogging = true;
    try {
      const req: LoginRequest = {
        phone: this.phone,
        password: this.code,
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

            // 3. 角色选择区
            this.RoleSection()

            // 4. 表单区（手机号 + 验证码）
            this.FormSection()

            // 5. 协议勾选
            this.AgreementSection()

            // 6. 一键登录按钮
            this.LoginButton()

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

        // 10. 底部黄色波浪装饰
        this.WaveDecoration()
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
        .position({ x: -30, y: 180 })
    }
    .width('100%')
    .height(280)
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
        .margin({ top: 56 })

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
      .margin({ top: 18 })

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

  /** 角色选择区 */
  @Builder
  RoleSection() {
    Column({ space: 10 }) {
      // 标签
      Row({ space: 6 }) {
        Text('')
          .width(12)
          .height(2)
          .backgroundColor($r('app.color.color_yellow_deep'))
          .borderRadius(AppConstants.RADIUS_PILL)
        Text('选择登录身份')
          .fontSize(12)
          .fontColor($r('app.color.color_text_3'))
      }
      .width('100%')
      .padding({ left: 2 })
      .margin({ top: 28, bottom: 10 })

      // 角色卡片行
      Row({ space: 10 }) {
        ForEach(this.roleCards, (card: RoleCardData, index: number) => {
          this.RoleCard(card)
        }, (card: RoleCardData, index: number) => `role_${card.role}`)
      }
      .width('100%')
    }
    .width('100%')
  }

  /** 单个角色卡片 */
  @Builder
  RoleCard(card: RoleCardData) {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column({ space: 8 }) {
        // 图标
        Text(card.icon)
          .fontSize(22)
          .width(40)
          .height(40)
          .borderRadius(AppConstants.RADIUS_SM)
          .backgroundColor(this.selectedRole === card.role ? $r('app.color.color_bg_card') : $r('app.color.color_fill'))
          .textAlign(TextAlign.Center)

        // 名称
        Text(card.name)
          .fontSize(13)
          .fontWeight(this.selectedRole === card.role ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.selectedRole === card.role ? $r('app.color.color_ink') : $r('app.color.color_ink_2'))

        // 描述
        Text(card.desc)
          .fontSize(10)
          .fontColor(this.selectedRole === card.role ? '#6B5B00' : $r('app.color.color_text_3'))
      }
      .width('100%')
      .padding({ top: 14, bottom: 12, left: 6, right: 6 })
      .borderRadius(AppConstants.RADIUS_MD)
      .backgroundColor(this.selectedRole === card.role ? Color.Transparent : $r('app.color.color_bg_card'))
      .linearGradient(this.selectedRole === card.role ? {
        angle: 135,
        colors: [[$r('app.color.color_yellow'), 0.0], [$r('app.color.color_yellow_deep'), 1.0]]
      } : { angle: 0, colors: [['rgba(0,0,0,0)', 0.0], ['rgba(0,0,0,0)', 1.0]] })
      .border({ width: 1.5, color: this.selectedRole === card.role ? $r('app.color.color_yellow_deep') : $r('app.color.color_line') })
      .shadow(this.selectedRole === card.role ? {
        radius: 16,
        color: 'rgba(255,217,61,0.4)',
        offsetX: 0,
        offsetY: 6
      } : { radius: 0, color: Color.Transparent, offsetX: 0, offsetY: 0 })
      .alignItems(HorizontalAlign.Center)
      .onClick(() => this.selectRole(card.role))

      // 选中角标
      if (this.selectedRole === card.role) {
        Text('✓')
          .fontSize(10)
          .fontColor(Color.White)
          .width(16)
          .height(16)
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_ink'))
          .textAlign(TextAlign.Center)
          .position({ x: '88%', y: 6 })
      }
    }
    .layoutWeight(1)
  }

  /** 表单区 */
  @Builder
  FormSection() {
    Column({ space: 12 }) {
      // 手机号输入框
      Row() {
        Text('📱')
          .fontSize(18)
          .margin({ right: 10 })
        TextInput({ text: this.phone, placeholder: '请输入手机号' })
          .layoutWeight(1)
          .type(InputType.PhoneNumber)
          .maxLength(11)
          .backgroundColor(Color.Transparent)
          .borderRadius(0)
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .placeholderColor($r('app.color.color_text_4'))
          .placeholderFont({ size: 14 })
          .onChange((val: string) => { this.phone = val; })
      }
      .width('100%')
      .height(46)
      .borderRadius(AppConstants.RADIUS_MD)
      .backgroundColor($r('app.color.color_fill'))
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .margin({ top: 22 })

      // 验证码输入框 + 获取验证码按钮
      Row() {
        Text('🔒')
          .fontSize(18)
          .margin({ right: 10 })
        TextInput({ text: this.code, placeholder: '请输入验证码' })
          .layoutWeight(1)
          .type(InputType.Number)
          .maxLength(6)
          .backgroundColor(Color.Transparent)
          .borderRadius(0)
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .placeholderColor($r('app.color.color_text_4'))
          .placeholderFont({ size: 14 })
          .onChange((val: string) => { this.code = val; })

        // 获取验证码按钮
        Text(this.codeCountdown > 0 ? `${this.codeCountdown}s 后重发` : '获取验证码')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.codeCountdown > 0 ? $r('app.color.color_text_4') : $r('app.color.color_ink'))
          .padding({ left: 12 })
          .margin({ left: 8 })
          .border({ width: { left: 1 }, color: $r('app.color.color_line_2') })
          .onClick(() => this.sendCode())
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
        Span('，未注册手机号将自动创建账号')
          .fontColor($r('app.color.color_text_3'))
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
    .margin({ top: 22, bottom: 18 })
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
      Text('未注册的手机号验证后将自动注册账号')
        .fontSize(12)
        .fontColor($r('app.color.color_text_3'))
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .margin({ top: 8 })
  }

  /** 底部黄色波浪装饰 */
  @Builder
  WaveDecoration() {
    Column()
      .width('100%')
      .height(60)
      .linearGradient({
        angle: 0,
        colors: [['rgba(255,226,52,0.55)', 0.0], ['rgba(255,217,61,0.85)', 1.0]]
      })
      .position({ x: 0, y: '92%' })
  }
}
