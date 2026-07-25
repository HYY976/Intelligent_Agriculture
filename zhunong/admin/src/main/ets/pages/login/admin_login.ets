/**
 * admin_login - 管理后台登录页（UI 复刻 qunong-harmony-app/pages/admin-login.html）
 * 遵循 spec 1.3.2 / 3.3.1 / 6.6.3：
 *  - 登录方式：用户名 + 密码 + 角色（4角色RBAC：超管/用户管理员/内容审核员/API管理员）
 *  - JWT 24小时有效（后端控制，比用户/卖家的7天短）
 *  - 登录成功跳转 pages/home/admin_home（侧边栏导航）
 *  现阶段 Mock：用户名 admin + 密码 123456 + 任意角色均可登录成功（后端 Mock）
 *
 * UI 设计要点（对齐 admin-login.html）：
 *  - 顶部黄/绿径向渐变小气泡装饰
 *  - 黄色渐变圆角方块 Logo（80×80）+ 盾牌图标 + 右上深绿小角标
 *  - 表单区：用户名/密码字段（52高，左侧图标 + 右侧眼睛切换）
 *  - 角色选择：深绿小圆点 + "选择角色" 标题 + 2×2 胶囊网格（选中黄底墨黑）
 *  - 墨黑登录按钮（48高，箭头图标）
 *  - 黄底测试账号提示卡 + 用户协议文字
 *  - 底部黄色波浪装饰（双层 Path）
 */
import { Logger, AppConstants, HttpUtil, TokenStore, ToastUtil, NavigationHelper, RouteName } from 'common';
import { ApiResponse, AdminInfo } from 'common';

/** 管理员角色枚举（spec 3.3.1：4角色RBAC） */
type AdminRole = 'super_admin' | 'user_admin' | 'content_reviewer' | 'api_admin';

/** 角色选项 */
interface RoleOption {
  /** 角色值 */
  value: AdminRole;
  /** 角色中文名 */
  label: string;
  /** 角色图标 emoji */
  icon: string;
}

interface AdminLoginRequest {
  username: string;
  password: string;
  role: AdminRole;
}

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
  /** 选中的角色 */
  @Local selectedRole: AdminRole = 'super_admin';
  /** 是否正在登录 */
  @Local isLogging: boolean = false;
  /** 是否显示明文密码 */
  @Local showPassword: boolean = false;
  /** 角色选项列表（2×2 网格） */
  private roleOptions: RoleOption[] = [
    { value: 'super_admin', label: '超级管理员', icon: '🛡️' },
    { value: 'user_admin', label: '用户管理员', icon: '👥' },
    { value: 'content_reviewer', label: '内容审核员', icon: '📝' },
    { value: 'api_admin', label: 'API管理员', icon: '🔌' }
  ];

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

  /** 登录 */
  private async doLogin(): Promise<void> {
    if (!this.validateForm()) {
      return;
    }
    this.isLogging = true;
    try {
      const req: AdminLoginRequest = {
        username: this.username,
        password: this.password,
        role: this.selectedRole
      };
      const resp: ApiResponse<AdminLoginResponse> = await HttpUtil.post<AdminLoginResponse>('/admin/login', req, {
        withAuth: false
      });
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
          Text('🛡️')
            .fontSize(40)
            .fontColor($r('app.color.color_admin_green'))
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
      Text('助农管理后台')
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
      // c) 角色选择区
      this.RoleSection()
      // d) 管理员登录按钮
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
      Text('👤')
        .fontSize(18)
        .fontColor($r('app.color.color_text_3'))
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
      Text('🔒')
        .fontSize(18)
        .fontColor($r('app.color.color_text_3'))
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
        Text(this.showPassword ? '👁️' : '🙈')
          .fontSize(18)
          .fontColor($r('app.color.color_text_3'))
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

  /** 角色选择区（2×2 胶囊网格） */
  @Builder
  RoleSection() {
    Column({ space: 12 }) {
      // 标题行（深绿小圆点 + "选择角色"）
      Row({ space: 6 }) {
        Column()
          .width(6)
          .height(6)
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_admin_green'))
        Text('选择角色')
          .fontSize(13)
          .fontColor($r('app.color.color_ink_2'))
          .fontWeight(FontWeight.Medium)
          .letterSpacing(0.3)
      }
      .width('100%')
      .padding({ left: 2 })

      // 2×2 角色胶囊网格
      Grid() {
        ForEach(this.roleOptions, (option: RoleOption) => {
          GridItem() {
            this.RoleTag(option)
          }
        }, (option: RoleOption) => option.value)
      }
      .columnsTemplate('1fr 1fr')
      .rowsGap(8)
      .columnsGap(8)
      .width('100%')
      .height(94)
    }
    .width('100%')
    .margin({ top: 8, bottom: 22 })
    .alignItems(HorizontalAlign.Start)
  }

  /** 单个角色胶囊 */
  @Builder
  RoleTag(option: RoleOption) {
    Row({ space: 6 }) {
      Text(option.icon)
        .fontSize(15)
      Text(option.label)
        .fontSize(13)
        .fontColor(this.selectedRole === option.value ? $r('app.color.color_ink') : $r('app.color.color_text_2'))
        .fontWeight(this.selectedRole === option.value ? FontWeight.Bold : FontWeight.Medium)
    }
    .width('100%')
    .height(42)
    .borderRadius(AppConstants.RADIUS_PILL)
    .backgroundColor(this.selectedRole === option.value ? $r('app.color.color_yellow') : $r('app.color.color_bg_card'))
    .border({
      width: 1,
      color: this.selectedRole === option.value ? $r('app.color.color_yellow_deep') : $r('app.color.color_line_2')
    })
    .shadow(this.selectedRole === option.value
      ? { radius: 12, color: 'rgba(255,217,61,0.45)', offsetX: 0, offsetY: 4 }
      : AppConstants.SHADOW_CARD)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.selectedRole = option.value;
    })
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
      Text('ℹ️')
        .fontSize(16)
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
