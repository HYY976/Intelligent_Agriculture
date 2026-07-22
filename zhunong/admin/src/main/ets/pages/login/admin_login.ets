/**
 * admin_login - 管理后台登录页
 * 遵循 spec 1.3.2 / 3.3.1 / 6.6.3：
 *  - 登录方式：用户名 + 密码 + 角色（4角色RBAC：超管/用户管理员/内容审核员/API管理员）
 *  - JWT 24小时有效（后端控制，比用户/卖家的7天短）
 *  - 登录成功跳转 pages/home/admin_home（侧边栏导航）
 *  现阶段 Mock：用户名 admin + 密码 123456 + 任意角色均可登录成功（后端 Mock）
 */
import { Logger, AppConstants, HttpUtil, TokenStore, ToastUtil, NavigationHelper, RouteName } from 'common';
import { ApiResponse, AdminInfo } from 'common';

/** 管理员角色枚举（spec 3.3.1：4角色RBAC） */
type AdminRole = 'super_admin' | 'user_admin' | 'content_reviewer' | 'api_admin';

/** 角色选项 */
interface RoleOption {
  value: AdminRole;
  label: string;
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
  /** 角色选项列表 */
  private roleOptions: RoleOption[] = [
    { value: 'super_admin', label: '超级管理员' },
    { value: 'user_admin', label: '用户管理员' },
    { value: 'content_reviewer', label: '内容审核员' },
    { value: 'api_admin', label: 'API管理员' }
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
      Column({ space: 20 }) {
        // 顶部品牌区
        Column({ space: 8 }) {
          Text('🛡️')
            .fontSize(64)
            .margin({ bottom: 12 })
          Text('助农管理后台')
            .fontSize(24)
            .fontColor($r('app.color.color_text_primary'))
            .fontWeight(FontWeight.Bold)
          Text('用户管理 · API管理 · 内容审核')
            .fontSize(14)
            .fontColor($r('app.color.color_text_secondary'))
        }
        .width('100%')
        .margin({ top: 80, bottom: 32 })

        // 用户名输入框
        Column({ space: 8 }) {
          Text('用户名')
            .fontSize(14)
            .fontColor($r('app.color.color_text_secondary'))
            .alignSelf(ItemAlign.Start)
          TextInput({ text: this.username })
            .type(InputType.Normal)
            .maxLength(32)
            .height(48)
            .borderRadius(12)
            .backgroundColor($r('app.color.color_bg_page'))
            .padding({ left: 16, right: 16 })
            .fontSize(16)
            .onChange((value: string) => {
              this.username = value;
            })
        }
        .width('100%')

        // 密码输入框
        Column({ space: 8 }) {
          Text('密码')
            .fontSize(14)
            .fontColor($r('app.color.color_text_secondary'))
            .alignSelf(ItemAlign.Start)
          TextInput({ text: this.password })
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

        // 角色选择（spec 3.3.1：4角色RBAC）
        Column({ space: 8 }) {
          Text('登录角色')
            .fontSize(14)
            .fontColor($r('app.color.color_text_secondary'))
            .alignSelf(ItemAlign.Start)
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.roleOptions, (option: RoleOption, _index: number) => {
              Text(option.label)
                .fontSize(13)
                .fontColor(this.selectedRole === option.value ? Color.White : $r('app.color.color_text_secondary'))
                .backgroundColor(this.selectedRole === option.value ? $r('app.color.color_primary') : $r('app.color.color_bg_page'))
                .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                .margin({ right: 8, bottom: 8 })
                .borderRadius(16)
                .onClick(() => {
                  this.selectedRole = option.value;
                })
            }, (option: RoleOption) => option.value)
          }
          .width('100%')
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

        // Mock 提示
        Text('Mock 阶段：用户名 admin / 密码 123456 / 任意角色可登录')
          .fontSize(12)
          .fontColor($r('app.color.color_text_hint'))
          .margin({ top: 16 })

        // 用户协议
        Text('登录即表示遵守《管理员操作规范》')
          .fontSize(12)
          .fontColor($r('app.color.color_text_hint'))
          .margin({ top: 4 })
      }
      .width('100%')
      .height('100%')
      .padding({ left: 32, right: 32 })
      .backgroundColor($r('app.color.color_bg_card'))
      .alignItems(HorizontalAlign.Center)
    }
    .hideTitleBar(true)
  }
}
