/**
 * admin_home - 管理后台首页（侧边栏导航 + RBAC 权限菜单过滤 + 控制台概览）
 * 遵循 spec 1.3.2 / 3.3.1 / 6.6.3 / 7.2 / 10.8.4：
 *  - 无底部 Tab，使用侧边栏导航（spec 1.3.2 / 7.2）
 *  - 不同角色登录后仅可见权限菜单（侧边栏导航过滤）spec 3.3.1
 *    - super_admin：控制台 + 用户管理 + API管理 + 内容审核
 *    - user_admin：控制台 + 用户管理
 *    - content_reviewer：控制台 + 内容审核
 *    - api_admin：控制台 + API管理
 *  - 顶部栏：当前管理员信息 + 退出登录
 *  - 控制台：4 张统计卡走 AdminRepository.getDashboardStats()（spec 10.8.4）
 *  - 待审核红点：aboutToAppear 调 ReviewRepository.getPendingCount()（spec 10.8.4）
 *  - 菜单点击：有 route 字段时 NavigationHelper.push（spec 10.8.4）
 */

import { TokenStore, Logger, AppConstants, NavigationHelper, RouteName } from 'common';
import { AdminInfo } from 'common';
import { AdminRole, DashboardStats } from '../../model/AdminModels';
import { AdminRepository } from '../../repository/AdminRepository';
import { ReviewRepository } from '../../repository/ReviewRepository';

/** 侧边栏菜单项 */
interface MenuItem {
  /** 菜单ID */
  id: string;
  /** 菜单名称 */
  label: string;
  /** 图标 emoji */
  icon: string;
  /** 允许访问的角色列表 */
  allowedRoles: AdminRole[];
  /** 跳转路由（dashboard 无 route，其余均跳转对应模块页） */
  route?: string;
}

@ComponentV2
export struct AdminHome {
  /** 当前管理员信息 */
  @Local adminInfo: AdminInfo | null = null;
  /** 当前选中的菜单ID（仅 dashboard 留在本页，其余菜单均跳转） */
  @Local currentMenu: string = 'dashboard';
  /** 控制台统计数据（spec 10.8.4：走 AdminRepository.getDashboardStats） */
  @Local stats: DashboardStats | null = null;
  /** 待审核数（spec 10.8.4：内容审核菜单红点） */
  @Local pendingCount: number = 0;
  /** 侧边栏菜单列表（全部，按角色过滤后展示） */
  private allMenus: MenuItem[] = [
    {
      id: 'dashboard',
      label: '控制台',
      icon: '📊',
      allowedRoles: ['super_admin', 'user_admin', 'content_reviewer', 'api_admin']
    },
    {
      id: 'user_manage',
      label: '用户管理',
      icon: '👥',
      allowedRoles: ['super_admin', 'user_admin'],
      route: RouteName.ADMIN_USER_LIST
    },
    {
      id: 'api_manage',
      label: 'API管理',
      icon: '🔌',
      allowedRoles: ['super_admin', 'api_admin'],
      route: RouteName.ADMIN_API_LIST
    },
    {
      id: 'content_review',
      label: '内容审核',
      icon: '📝',
      allowedRoles: ['super_admin', 'content_reviewer'],
      route: RouteName.ADMIN_REVIEW_LIST
    }
  ];

  async aboutToAppear(): Promise<void> {
    this.adminInfo = await TokenStore.getAdminInfo();
    if (this.adminInfo) {
      Logger.info(AppConstants.SCENE_ADMIN, {
        action: 'admin_home_appear',
        adminId: this.adminInfo.adminId,
        role: this.adminInfo.role
      });
      // 并行加载控制台统计 + 待审核数（spec 10.8.4）
      await Promise.all([
        this.loadDashboardStats(),
        this.loadPendingCount()
      ]);
    } else {
      // 未登录，跳转登录页
      NavigationHelper.replace(RouteName.ADMIN_LOGIN);
    }
  }

  /** 加载控制台统计数据（spec 10.8.4） */
  private async loadDashboardStats(): Promise<void> {
    try {
      this.stats = await AdminRepository.getDashboardStats();
    } catch (err) {
      Logger.error(AppConstants.SCENE_ADMIN, { action: 'load_dashboard_stats_fail', error: (err as Error).message });
    }
  }

  /** 加载待审核数（spec 10.8.4：内容审核菜单红点） */
  private async loadPendingCount(): Promise<void> {
    try {
      this.pendingCount = await ReviewRepository.getPendingCount();
    } catch (err) {
      Logger.error(AppConstants.SCENE_ADMIN, { action: 'load_pending_count_fail', error: (err as Error).message });
    }
  }

  /** 获取当前角色可见的菜单列表 */
  private getVisibleMenus(): MenuItem[] {
    if (!this.adminInfo) {
      return [];
    }
    const role: AdminRole = this.adminInfo.role as AdminRole;
    return this.allMenus.filter((menu: MenuItem): boolean => menu.allowedRoles.indexOf(role) >= 0);
  }

  /** 获取角色中文名 */
  private getRoleLabel(): string {
    if (!this.adminInfo) {
      return '';
    }
    switch (this.adminInfo.role) {
      case 'super_admin':
        return '超级管理员';
      case 'user_admin':
        return '用户管理员';
      case 'content_reviewer':
        return '内容审核员';
      case 'api_admin':
        return 'API管理员';
      default:
        return '';
    }
  }

  /** 退出登录 */
  private async doLogout(): Promise<void> {
    Logger.info(AppConstants.SCENE_ADMIN, { action: 'logout' });
    await TokenStore.clearAuth();
    NavigationHelper.replace(RouteName.ADMIN_LOGIN);
  }

  /** 点击菜单项（spec 10.8.4：有 route 即跳转） */
  private onMenuClick(menu: MenuItem): void {
    Logger.info(AppConstants.SCENE_ADMIN, { action: 'menu_click', menu: menu.id });
    if (menu.route) {
      NavigationHelper.push(menu.route);
    } else {
      // dashboard 留在本页
      this.currentMenu = menu.id;
    }
  }

  /** 数字千分位格式化 */
  private formatNumber(n: number): string {
    const s: string = `${n}`;
    let result: string = '';
    for (let i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 === 0) {
        result += ',';
      }
      result += s.charAt(i);
    }
    return result;
  }

  build() {
    NavDestination() {
      Row() {
        // 左侧侧边栏（spec 1.3.2 / 7.2：侧边栏导航）
        this.Sidebar()

        // 右侧主内容区
        Column() {
          // 顶部栏
          this.TopBar()
          // 主内容（dashboard 概览）
          this.MainContent()
        }
        .layoutWeight(1)
        .height('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 侧边栏 */
  @Builder
  Sidebar() {
    Column() {
      // 顶部 Logo 区
      Column({ space: 8 }) {
        Text('🛡️')
          .fontSize(36)
        Text('助农管理')
          .fontSize(18)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .padding({ top: 24, bottom: 24 })
      .alignItems(HorizontalAlign.Center)

      // 管理员信息卡片
      if (this.adminInfo) {
        Column({ space: 4 }) {
          Text(this.adminInfo.nickname)
            .fontSize(16)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
          Text(this.getRoleLabel())
            .fontSize(12)
            .fontColor('rgba(255,213,79,0.9)')
            .backgroundColor('rgba(255,213,79,0.15)')
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(8)
        }
        .width('100%')
        .padding({ top: 12, bottom: 16 })
        .alignItems(HorizontalAlign.Center)
      }

      Divider()
        .strokeWidth(1)
        .color('rgba(255,255,255,0.1)')
        .margin({ left: 16, right: 16 })

      // 菜单列表（按角色过滤）
      Column({ space: 4 }) {
        ForEach(this.getVisibleMenus(), (menu: MenuItem, _index: number) => {
          this.MenuItemRow(menu)
        }, (menu: MenuItem) => menu.id)
      }
      .width('100%')
      .padding({ top: 16, left: 12, right: 12 })

      Blank()

      // 退出登录按钮
      Button('退出登录')
        .width('80%')
        .height(40)
        .borderRadius(20)
        .backgroundColor('rgba(244,67,54,0.2)')
        .fontColor('#F44336')
        .fontSize(14)
        .margin({ bottom: 24 })
        .onClick(() => {
          this.doLogout();
        })
    }
    .width(240)
    .height('100%')
    .backgroundColor('#1B5E20')
    .justifyContent(FlexAlign.Start)
  }

  /** 菜单项行 */
  @Builder
  MenuItemRow(menu: MenuItem) {
    Row({ space: 12 }) {
      Text(menu.icon)
        .fontSize(20)
      Text(menu.label)
        .fontSize(14)
        .fontColor(this.currentMenu === menu.id ? Color.White : 'rgba(255,255,255,0.7)')
        .fontWeight(this.currentMenu === menu.id ? FontWeight.Bold : FontWeight.Normal)
        .layoutWeight(1)
      // 待审核红点（spec 10.8.4：content_review 菜单展示 pendingCount）
      if (menu.id === 'content_review' && this.pendingCount > 0) {
        Text(`${this.pendingCount}`)
          .fontSize(10)
          .fontColor(Color.White)
          .backgroundColor('#F44336')
          .borderRadius(8)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
      }
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .borderRadius(8)
    .backgroundColor(this.currentMenu === menu.id ? 'rgba(255,213,79,0.2)' : Color.Transparent)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.onMenuClick(menu);
    })
  }

  /** 顶部栏 */
  @Builder
  TopBar() {
    Row() {
      Text(this.getCurrentMenuLabel())
        .fontSize(18)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
      Blank()
      // 管理员信息
      if (this.adminInfo) {
        Row({ space: 8 }) {
          Text('👤')
            .fontSize(20)
          Column({ space: 2 }) {
            Text(this.adminInfo.nickname)
              .fontSize(13)
              .fontColor($r('app.color.color_text_primary'))
            Text(this.getRoleLabel())
              .fontSize(11)
              .fontColor($r('app.color.color_text_secondary'))
          }
          .alignItems(HorizontalAlign.End)
        }
        .alignItems(VerticalAlign.Center)
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 24, right: 24 })
    .backgroundColor($r('app.color.color_bg_card'))
    .border({ width: { bottom: 1 }, color: $r('app.color.color_divider') })
    .alignItems(VerticalAlign.Center)
  }

  /** 获取当前菜单名称 */
  private getCurrentMenuLabel(): string {
    const menus: MenuItem[] = this.getVisibleMenus();
    const found: MenuItem | undefined = menus.find((m: MenuItem): boolean => m.id === this.currentMenu);
    return found ? found.label : '控制台';
  }

  /** 主内容区（spec 10.8.4：仅 Dashboard 概览，移除 PlaceholderContent） */
  @Builder
  MainContent() {
    Column({ space: 16 }) {
      this.DashboardContent()
    }
    .width('100%')
    .height('100%')
    .padding(24)
  }

  /** 控制台内容（spec 10.8.4：数据走 AdminRepository.getDashboardStats） */
  @Builder
  DashboardContent() {
    Column({ space: 16 }) {
      Text('控制台概览')
        .fontSize(20)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Bold)
        .alignSelf(ItemAlign.Start)

      // 统计卡片网格（spec 10.8.4：4 张卡走 Repository）
      Row({ space: 16 }) {
        this.StatCard('总用户数', this.stats ? this.formatNumber(this.stats.totalUsers) : '-', '👥', $r('app.color.color_primary'))
        this.StatCard('总卖家数', this.stats ? this.formatNumber(this.stats.totalFarmers) : '-', '🌾', $r('app.color.color_secondary'))
        this.StatCard('待审核', this.stats ? this.formatNumber(this.stats.pendingReviews) : '-', '📝', $r('app.color.color_error'))
        this.StatCard('今日订单', this.stats ? this.formatNumber(this.stats.todayOrders) : '-', '📦', $r('app.color.color_accent_gold'))
      }
      .width('100%')

      // 欢迎信息（spec 10.8.4：移除"后续阶段实现"提示）
      Column({ space: 8 }) {
        Text(`欢迎回来，${this.adminInfo?.nickname ?? '管理员'}`)
          .fontSize(16)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Medium)
        Text('请通过左侧菜单导航至各管理模块')
          .fontSize(13)
          .fontColor($r('app.color.color_text_secondary'))
      }
      .width('100%')
      .padding(20)
      .borderRadius(12)
      .backgroundColor($r('app.color.color_bg_card'))
      .alignItems(HorizontalAlign.Start)
      .margin({ top: 8 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /** 统计卡片 */
  @Builder
  StatCard(label: string, value: string, icon: string, color: Resource) {
    Column({ space: 8 }) {
      Text(icon)
        .fontSize(28)
      Text(value)
        .fontSize(22)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Bold)
      Text(label)
        .fontSize(12)
        .fontColor($r('app.color.color_text_secondary'))
    }
    .layoutWeight(1)
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
    .border({ width: { top: 3 }, color: color })
    .alignItems(HorizontalAlign.Center)
  }
}
