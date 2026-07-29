/**
 * admin_login - 管理后台登录页（UI 复刻 qunong-harmony-app/pages/admin-login.html）
 * 遵循 spec 1.3.2 / 3.3.1 / 6.6.3：
 *  - 登录方式：用户名 + 密码（统一超级管理员，不区分角色）
 *  - JWT 24小时有效（后端控制，比用户/卖家的7天短）
 *  - 登录成功跳转 pages/home/admin_home（侧边栏导航）
 *  现阶段 Mock：用户名 admin + 密码 123456 即可登录成功（后端 Mock）
 *
 * UI 设计要点（对齐 admin-login.html）：
 *  - 顶部黄/绿径向渐变小气泡装饰
 *  - 黄色渐变圆角方块 Logo（80×80）+ 盾牌图标 + 右上深绿小角标
 *  - 表单区：用户名/密码字段（52高，左侧图标 + 右侧眼睛切换）
 *  - 墨黑登录按钮（48高，箭头图标）
 *  - 黄底测试账号提示卡 + 用户协议文字
 *  - 底部黄色波浪装饰（双层 Path）
 */
import { Logger, AppConstants, MockAuthUtil, TokenStore, ToastUtil, NavigationHelper, RouteName } from 'common';
import { ApiResponse, AdminInfo } from 'common';

interface AdminLoginResponse {
  token: string;
  adminInfo: AdminInfo;
}

@ComponentV2
export struct AdminLogin {
  /** 用户名 */
  @Local username: string = '';
  /** 密码 */
  @Local password: string = '';
  /** 是否正在登录 */
  @Local isLogging: boolean = false;
  /** 是否显示明文密码 */
  @Local showPassword: boolean = false;

  /** 校验表单 */
  private validateForm(): boolean {
    if (this.username.trim().length === 0) {
      ToastUtil.warning('请输入用户名');
      return false;
    }
    if (this.password.length === 0) {
      ToastUtil.warning('请输入密码');
      return false;
    }
    return true;
  }

  /** 登录（走本地 MockAuthUtil，无需后端） */
  private async doLogin(): Promise<void> {
    if (!this.validateForm()) {
      return;
    }
    this.isLogging = true;
    try {
      const resp: ApiResponse<AdminLoginResponse> = await MockAuthUtil.loginAdmin(
        this.username, this.password, 'super_admin'
      );
      if (resp.code === AppConstants.CODE_SUCCESS && resp.data) {
        await TokenStore.setToken(resp.data.token);
        await TokenStore.setAdminInfo(resp.data.adminInfo);
        ToastUtil.success('登录成功');
        Logger.info(AppConstants.SCENE_ADMIN, {
          action: 'login_success',
          adminId: resp.data.adminInfo.adminId,
          role: resp.data.adminInfo.role
        });
        NavigationHelper.replace(RouteName.ADMIN_HOME);
      } else {
        ToastUtil.error(resp.msg || '登录失败');
      }
    } catch (err) {
      Logger.error(AppConstants.SCENE_ADMIN, { action: 'login_fail', error: (err as Error).message });
      ToastUtil.error('登录失败，请稍后重试');
    } finally {
      this.isLogging = false;
    }
  }

  build() {
    NavDestination() {
      Stack() {
        // 主内容（滚动容器）
        Scroll() {
          Column() {
            // 1. 品牌Logo区
            this.BrandHero()
            // 2. 表单区
            this.FormArea()
            // 3. 测试账号提示卡
            this.MockTipCard()
            // 4. 用户协议文字
            this.AgreementText()
            // 5. 注册入口链接
            this.RegisterLink()
          }
          .width('100%')
          .padding({ left: 24, right: 24, bottom: 80 })
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .height('100%')
        .align(Alignment.Top)
        .scrollBar(BarState.Off)

        // 顶部装饰小气泡（黄 + 绿 径向渐变）
        this.TopDecorations()

        // 底部黄色波浪装饰
        this.BottomWave()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_cream'))
    }
    .hideTitleBar(true)
  }

  /** 顶部装饰小气泡（黄 + 绿 径向渐变圆） */
  @Builder
  TopDecorations() {
    Stack() {
      // 黄色装饰圆 1（右上）
      Column()
        .width(140)
        .height(140)
        .borderRadius(70)
        .linearGradient({
          angle: 0,
          colors: [['rgba(255,226,52,0.34)', 0.0], ['rgba(255,226,52,0)', 0.7]]
        })
        .position({ x: '70%', y: -40 })

      // 绿色装饰圆 2（左中）
      Column()
        .width(104)
        .height(104)
        .borderRadius(52)
        .linearGradient({
          angle: 0,
          colors: [['rgba(126,211,33,0.22)', 0.0], ['rgba(126,211,33,0)', 0.7]]
        })
        .position({ x: -38, y: 210 })
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None)
    .alignContent(Alignment.TopStart)
  }

  /** 品牌 Logo 区 */
  @Builder
  BrandHero() {
    Column({ space: 8 }) {
      // 黄色渐变圆角方块 Logo + 深绿小角标
      Stack() {
        // 黄色渐变方块 + 盾牌图标
        Stack() {
          Image($r('app.media.icon_shield'))
            .width(40)
            .height(40)
            .fillColor($r('app.color.color_admin_green'))
        }
        .width(80)
        .height(80)
        .borderRadius(AppConstants.RADIUS_XL)
        .linearGradient({
          angle: 135,
          colors: [[$r('app.color.color_yellow'), 0.0], [$r('app.color.color_yellow_deep'), 1.0]]
        })
        .shadow({ radius: 26, color: 'rgba(255,217,61,0.42)', offsetX: 0, offsetY: 10 })
        .border({ width: 3, color: $r('app.color.color_bg_card') })

        // 右上深绿小角标（白色对勾）
        Stack() {
          Text('✓')
            .fontSize(12)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
        }
        .width(22)
        .height(22)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor($r('app.color.color_admin_green'))
        .border({ width: 2, color: $r('app.color.color_bg_card') })
        .shadow({ radius: 8, color: 'rgba(27,94,32,0.35)', offsetX: 0, offsetY: 3 })
        .position({ x: 56, y: -6 })
      }
      .width(80)
      .height(80)
      .margin({ top: 72 })

      // 标题
      Text('智农管理后台')
        .fontSize(22)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .letterSpacing(1)
        .margin({ top: 8 })

      // 副标题
      Text('用户管理·API管理·内容审核')
        .fontSize(13)
        .fontColor($r('app.color.color_text_3'))
        .letterSpacing(0.5)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  /** 表单区 */
  @Builder
  FormArea() {
    Column({ space: 14 }) {
      // a) 用户名输入框
      this.UsernameField()
      // b) 密码输入框（带眼睛切换）
      this.PasswordField()
      // c) 管理员登录按钮
      this.LoginButton()
    }
    .width('100%')
    .margin({ top: 32 })
  }

  /** 用户名输入框 */
  @Builder
  UsernameField() {
    Row({ space: 12 }) {
      // 用户图标
      Image($r('app.media.icon_user'))
        .width(18)
        .height(18)
        .fillColor($r('app.color.color_text_3'))
      // 输入框
      TextInput({ text: this.username, placeholder: '请输入用户名' })
        .type(InputType.Normal)
        .maxLength(32)
        .backgroundColor(Color.Transparent)
        .fontSize(14)
        .fontColor($r('app.color.color_ink'))
        .placeholderColor($r('app.color.color_text_4'))
        .placeholderFont({ size: 14 })
        .layoutWeight(1)
        .height('100%')
        .onChange((value: string) => {
          this.username = value;
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
  }

  /** 密码输入框（带显隐切换） */
  @Builder
  PasswordField() {
    Row({ space: 12 }) {
      // 锁图标
      Image($r('app.media.icon_lock'))
        .width(18)
        .height(18)
        .fillColor($r('app.color.color_text_3'))
      // 密码输入框
      TextInput({ text: this.password, placeholder: '请输入密码' })
        .type(this.showPassword ? InputType.Normal : InputType.Password)
        .maxLength(32)
        .backgroundColor(Color.Transparent)
        .fontSize(14)
        .fontColor($r('app.color.color_ink'))
        .placeholderColor($r('app.color.color_text_4'))
        .placeholderFont({ size: 14 })
        .layoutWeight(1)
        .height('100%')
        .onChange((value: string) => {
          this.password = value;
        })
      // 眼睛切换按钮
      Stack() {
        Image(this.showPassword ? $r('app.media.icon_eye') : $r('app.media.icon_eye_off'))
          .width(18)
          .height(18)
          .fillColor($r('app.color.color_text_3'))
      }
      .width(28)
      .height(28)
      .onClick(() => {
        this.showPassword = !this.showPassword;
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
  }

  /** 管理员登录按钮 */
  @Builder
  LoginButton() {
    Row({ space: 6 }) {
      Text(this.isLogging ? '登录中...' : '登录')
        .fontSize(15)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .letterSpacing(1)
      if (!this.isLogging) {
        Text('→')
          .fontSize(18)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
      }
    }
    .width('100%')
    .height(48)
    .borderRadius(AppConstants.RADIUS_MD)
    .backgroundColor(this.isLogging ? $r('app.color.color_button_disabled') : $r('app.color.color_cta_black'))
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .opacity(this.isLogging ? 0.7 : 1)
    .onClick(() => {
      if (!this.isLogging) {
        this.doLogin();
      }
    })
  }

  /** 测试账号提示卡 */
  @Builder
  MockTipCard() {
    Row({ space: 8 }) {
      Image($r('app.media.icon_info'))
        .width(16)
        .height(16)
        .fillColor('#8A6D00')
      Text() {
        Span('测试账号：')
          .fontColor('#8A6D00')
          .fontSize(12)
        Span('admin / 123456')
          .fontColor('#6B5400')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
      }
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .borderRadius(AppConstants.RADIUS_MD)
    .backgroundColor($r('app.color.color_yellow_soft'))
    .margin({ top: 18 })
    .alignItems(VerticalAlign.Top)
  }

  /** 用户协议文字 */
  @Builder
  AgreementText() {
    Text() {
      Span('登录即同意')
        .fontColor($r('app.color.color_text_3'))
        .fontSize(11)
      Span('《用户协议》')
        .fontColor($r('app.color.color_text_2'))
        .fontSize(11)
      Span('和')
        .fontColor($r('app.color.color_text_3'))
        .fontSize(11)
      Span('《隐私政策》')
        .fontColor($r('app.color.color_text_2'))
        .fontSize(11)
    }
    .width('100%')
    .textAlign(TextAlign.Center)
    .margin({ top: 16 })
  }

  /** 注册入口链接 */
  @Builder
  RegisterLink() {
    Row({ space: 4 }) {
      Text('还没有账号？')
        .fontColor($r('app.color.color_text_3'))
        .fontSize(13)
      Text('立即注册 →')
        .fontColor($r('app.color.color_admin_green'))
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .margin({ top: 12 })
    .onClick(() => {
      NavigationHelper.replace(RouteName.ADMIN_REGISTER);
    })
  }

  /** 底部黄色波浪装饰（双层 Path） */
  @Builder
  BottomWave() {
    Stack() {
      // 使用两个 Column 模拟波浪层（简化实现）
      Column()
        .width('100%')
        .height(50)
        .linearGradient({
          angle: 0,
          colors: [['rgba(255,226,52,0.5)', 0.0], ['rgba(255,217,61,0.5)', 1.0]]
        })
        .position({ x: 0, y: 0 })
      Column()
        .width('100%')
        .height(35)
        .linearGradient({
          angle: 0,
          colors: [['rgba(255,226,52,0.8)', 0.0], ['rgba(255,217,61,0.8)', 1.0]]
        })
        .position({ x: 0, y: 15 })
    }
    .width('100%')
    .height(50)
    .hitTestBehavior(HitTestMode.None)
    .alignContent(Alignment.Bottom)
    .position({ x: 0, y: '100%' })
    .translate({ y: -50 })
  }
}
