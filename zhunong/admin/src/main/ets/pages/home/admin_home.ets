/**
 * admin_home - 管理后台首页（移动端适配 v2.0）
 * 遵循 spec 1.3.2 / 3.3.1 / 6.6.3 / 7.2 / 10.8.4：
 *  - 无底部 Tab，使用抽屉式侧边栏导航（默认收起，汉堡按钮呼出）
 *  - 不同角色登录后仅可见权限菜单（侧边栏导航过滤）spec 3.3.1
 *    - super_admin：控制台 + 用户管理 + API管理 + 内容审核 + 广告管理
 *    - user_admin：控制台 + 用户管理
 *    - content_reviewer：控制台 + 内容审核
 *    - api_admin：控制台 + API管理
 *  - 顶部栏：汉堡按钮 + 页面标题 + 管理员信息
 *  - 控制台：4 张统计卡（2×2 网格）走 AdminRepository.getDashboardStats()
 *  - 待审核红点：aboutToAppear 调 ReviewRepository.getPendingCount()
 *  - 菜单点击：有 route 字段时 NavigationHelper.push
 *
 * v2.0 移动端适配改进：
 *  - 侧边栏改为抽屉式（默认收起，汉堡按钮 + 遮罩呼出）
 *  - 统计卡改为 2×2 网格（适配窄屏）
 *  - 柱状图优化（数值标签竖排、柱子宽度自适应）
 *  - 欢迎卡吉祥物缩小至 56×56（不抢占核心数据区）
 *  - 快捷操作改为纵向列表（适配窄屏点击）
 *  - 侧边栏选中态高亮条优化（与文字对齐）
 *  - 退出登录增加红色边框背景（提升警示辨识度）
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
  /** 图标资源（SVG 矢量图） */
  icon: Resource;
  /** 允许访问的角色列表 */
  allowedRoles: AdminRole[];
  /** 跳转路由（dashboard 无 route，其余均跳转对应模块页） */
  route?: string;
  /** 角标类型（soft=灰白 / red=红色 / none=无） */
  badgeType?: 'soft' | 'red' | 'none';
}

/** 统计卡数据项（含图标颜色、趋势） */
interface StatCardData {
  /** 标签 */
  label: string;
  /** 数值（已格式化） */
  value: string;
  /** 图标资源（SVG 矢量图） */
  icon: Resource;
  /** 图标背景色（浅） */
  iconBg: ResourceColor;
  /** 图标颜色（深） */
  iconColor: ResourceColor;
  /** 趋势百分比（正=上升 负=下降） */
  trend: number;
}

/** 7 天 GMV 柱状图数据项 */
interface BarItem {
  /** 日期标签 */
  label: string;
  /** 数值（千元） */
  value: number;
  /** 显示文本 */
  valueText: string;
  /** 高度百分比（0-100） */
  heightPercent: number;
  /** 是否为峰值（今日） */
  isPeak: boolean;
}

/** 快捷操作项 */
interface QuickAction {
  /** 标题 */
  title: string;
  /** 描述 */
  desc: string;
  /** 图标资源（SVG 矢量图） */
  icon: Resource;
  /** 图标背景色 */
  iconBg: ResourceColor;
  /** 图标颜色 */
  iconColor: ResourceColor;
  /** 跳转路由 */
  route: string;
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
  /** 用户管理待处理数（侧边栏软角标） */
  @Local userPendingCount: number = 3;
  /** 侧边栏抽屉是否展开（v2.0：默认收起） */
  @Local sidebarOpen: boolean = false;

  /** 侧边栏菜单列表（全部，按角色过滤后展示） */
  private allMenus: MenuItem[] = [
    {
      id: 'dashboard',
      label: '控制台',
      icon: $r('app.media.icon_dashboard'),
      allowedRoles: ['super_admin', 'user_admin', 'content_reviewer', 'api_admin'],
      badgeType: 'none'
    },
    {
      id: 'user_manage',
      label: '用户管理',
      icon: $r('app.media.icon_users'),
      allowedRoles: ['super_admin', 'user_admin'],
      route: RouteName.ADMIN_USER_LIST,
      badgeType: 'soft'
    },
    {
      id: 'api_manage',
      label: 'API管理',
      icon: $r('app.media.icon_api'),
      allowedRoles: ['super_admin', 'api_admin'],
      route: RouteName.ADMIN_API_LIST,
      badgeType: 'none'
    },
    {
      id: 'content_review',
      label: '内容审核',
      icon: $r('app.media.icon_shield'),
      allowedRoles: ['super_admin', 'content_reviewer'],
      route: RouteName.ADMIN_REVIEW_LIST,
      badgeType: 'red'
    },
    {
      id: 'ads_manage',
      label: '广告管理',
      icon: $r('app.media.icon_megaphone'),
      allowedRoles: ['super_admin'],
      route: RouteName.ADMIN_ADS_LIST,
      badgeType: 'none'
    }
  ];

  /** 7 天 GMV 柱状图 Mock 数据 */
  private barData: BarItem[] = [
    { label: '周一', value: 9.2, valueText: '9.2k', heightPercent: 48, isPeak: false },
    { label: '周二', value: 12.5, valueText: '12.5k', heightPercent: 62, isPeak: false },
    { label: '周三', value: 8.6, valueText: '8.6k', heightPercent: 43, isPeak: false },
    { label: '周四', value: 15.8, valueText: '15.8k', heightPercent: 78, isPeak: false },
    { label: '周五', value: 11.2, valueText: '11.2k', heightPercent: 56, isPeak: false },
    { label: '周六', value: 23.8, valueText: '23.8k', heightPercent: 96, isPeak: true },
    { label: '周日', value: 17.4, valueText: '17.4k', heightPercent: 82, isPeak: false }
  ];

  /** 快捷操作列表 */
  private quickActions: QuickAction[] = [
    {
      title: '用户管理',
      desc: '查看与管理平台用户',
      icon: $r('app.media.icon_users'),
      iconBg: $r('app.color.color_yellow'),
      iconColor: $r('app.color.color_ink'),
      route: RouteName.ADMIN_USER_LIST
    },
    {
      title: '内容审核',
      desc: '12 条内容待审核',
      icon: $r('app.media.icon_shield'),
      iconBg: $r('app.color.color_green'),
      iconColor: Color.White,
      route: RouteName.ADMIN_REVIEW_LIST
    },
    {
      title: 'API管理',
      desc: '密钥与接口配置',
      icon: $r('app.media.icon_api'),
      iconBg: $r('app.color.color_info'),
      iconColor: Color.White,
      route: RouteName.ADMIN_API_LIST
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
    // 点击后关闭抽屉
    this.sidebarOpen = false;
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

  /** 获取菜单角标数值 */
  private getBadgeCount(menu: MenuItem): number {
    if (menu.id === 'content_review') {
      return this.pendingCount;
    }
    if (menu.id === 'user_manage') {
      return this.userPendingCount;
    }
    return 0;
  }

  /** 构建统计卡数据 */
  private buildStatCards(): StatCardData[] {
    return [
      {
        label: '总用户',
        value: this.stats ? this.formatNumber(this.stats.totalUsers) : '12,856',
        icon: $r('app.media.icon_users'),
        iconBg: $r('app.color.color_info_soft'),
        iconColor: $r('app.color.color_info'),
        trend: 8.2
      },
      {
        label: '总卖家',
        value: this.stats ? this.formatNumber(this.stats.totalFarmers) : '1,234',
        icon: $r('app.media.icon_store'),
        iconBg: $r('app.color.color_green_soft'),
        iconColor: $r('app.color.color_green_deep'),
        trend: 3.5
      },
      {
        label: '待审核',
        value: this.stats ? this.formatNumber(this.stats.pendingReviews) : '12',
        icon: $r('app.media.icon_hourglass'),
        iconBg: $r('app.color.color_warn_soft'),
        iconColor: $r('app.color.color_warn'),
        trend: -2.1
      },
      {
        label: '今日订单',
        value: this.stats ? this.formatNumber(this.stats.todayOrders) : '456',
        icon: $r('app.media.icon_package'),
        iconBg: $r('app.color.color_yellow_soft'),
        iconColor: $r('app.color.color_yellow_text'),
        trend: 12.8
      }
    ];
  }

  /** 获取当前菜单名称 */
  private getCurrentMenuLabel(): string {
    const menus: MenuItem[] = this.getVisibleMenus();
    const found: MenuItem | undefined = menus.find((m: MenuItem): boolean => m.id === this.currentMenu);
    return found ? found.label : '控制台概览';
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Start }) {
        // 主内容区（全屏）
        Column() {
          // 顶部栏（含汉堡按钮）
          this.TopBar()
          // 主内容（dashboard 概览，可滚动）
          this.MainContent()
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.color_cream'))

        // 遮罩层（抽屉打开时显示）
        if (this.sidebarOpen) {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('rgba(0,0,0,0.45)')
            .onClick(() => { this.sidebarOpen = false; })
        }

        // 抽屉式侧边栏（默认收起在左侧外）
        if (this.sidebarOpen) {
          this.Sidebar()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 侧边栏抽屉（深绿 #1B5E20，v2.0 抽屉式） */
  @Builder
  Sidebar() {
    Column() {
      // 顶部 Logo 区 + 关闭按钮
      Row() {
        Row({ space: 10 }) {
          Stack() {
            Image($r('app.media.icon_seedling'))
              .width(20)
              .height(20)
              .fillColor(Color.White)
          }
          .width(34)
          .height(34)
          .borderRadius(AppConstants.RADIUS_SM)
          .backgroundColor($r('app.color.color_yellow'))
          Text('助农管理')
            .fontSize(18)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .letterSpacing(0.5)
        }
        .layoutWeight(1)
        .alignItems(VerticalAlign.Center)

        // 关闭按钮（✕）
        Stack() {
          Text('✕')
            .fontSize(16)
            .fontColor('rgba(255,255,255,0.6)')
        }
        .width(32)
        .height(32)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor('rgba(255,255,255,0.1)')
        .onClick(() => { this.sidebarOpen = false; })
      }
      .width('100%')
      .padding({ left: 20, right: 16, top: 20, bottom: 20 })
      .alignItems(VerticalAlign.Center)

      // 管理员信息卡片
      if (this.adminInfo) {
        Row({ space: 12 }) {
          Image($r('app.media.avatar_admin'))
            .width(42)
            .height(42)
            .borderRadius(21)
            .border({ width: 2, color: 'rgba(255,255,255,0.4)' })
            .objectFit(ImageFit.Cover)
          Column({ space: 5 }) {
            Text(this.adminInfo.nickname)
              .fontSize(14)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.getRoleLabel())
              .fontSize(10)
              .fontColor($r('app.color.color_yellow'))
              .backgroundColor('rgba(255,226,52,0.16)')
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .borderRadius(AppConstants.RADIUS_PILL)
              .letterSpacing(0.3)
              .fontWeight(FontWeight.Bold)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding(14)
        .margin({ left: 16, right: 16, bottom: 8 })
        .borderRadius(AppConstants.RADIUS_MD)
        .backgroundColor('rgba(255,255,255,0.12)')
        .alignItems(VerticalAlign.Center)
      }

      // 菜单列表（按角色过滤）
      Column({ space: 0 }) {
        ForEach(this.getVisibleMenus(), (menu: MenuItem) => {
          this.MenuItemRow(menu)
        }, (menu: MenuItem) => menu.id)
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })
      .layoutWeight(1)

      // 退出登录按钮（v2.0：红色半透明背景 + 边框，提升警示辨识度）
      Row({ space: 10 }) {
        Image($r('app.media.icon_logout'))
          .width(18)
          .height(18)
          .fillColor($r('app.color.color_logout_red'))
        Text('退出登录')
          .fontSize(14)
          .fontColor($r('app.color.color_logout_red'))
          .fontWeight(FontWeight.Bold)
        Blank()
        Text('→')
          .fontSize(14)
          .fontColor($r('app.color.color_logout_red'))
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 16 })
      .margin({ left: 16, right: 16, bottom: 16 })
      .borderRadius(AppConstants.RADIUS_MD)
      .backgroundColor('rgba(244,67,54,0.1)')
      .border({ width: 1, color: 'rgba(244,67,54,0.3)' })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.doLogout();
      })
    }
    .width('78%')
    .height('100%')
    .backgroundColor($r('app.color.color_admin_green'))
    .justifyContent(FlexAlign.Start)
  }

  /** 菜单项行（v2.0：激活态左侧 3px 黄色条与文字对齐优化） */
  @Builder
  MenuItemRow(menu: MenuItem) {
    Stack() {
      // 激活态左侧黄色条（与菜单文字垂直居中对齐）
      if (this.currentMenu === menu.id) {
        Column()
          .width(3)
          .height(28)
          .backgroundColor($r('app.color.color_yellow'))
          .borderRadius({ topRight: 2, bottomRight: 2 })
          .position({ x: 0, y: 10 })
      }

      Row({ space: 12 }) {
        Image(menu.icon)
          .width(20)
          .height(20)
          .fillColor(this.currentMenu === menu.id ? $r('app.color.color_yellow') : Color.White)
          .opacity(this.currentMenu === menu.id ? 1 : 0.82)
        Text(menu.label)
          .fontSize(14)
          .fontColor(this.currentMenu === menu.id ? Color.White : 'rgba(255,255,255,0.82)')
          .fontWeight(this.currentMenu === menu.id ? FontWeight.Bold : FontWeight.Medium)
          .layoutWeight(1)
        // 角标
        if (menu.badgeType === 'red' && this.getBadgeCount(menu) > 0) {
          Text(`${this.getBadgeCount(menu)}`)
            .fontSize(10)
            .fontColor(Color.White)
            .backgroundColor($r('app.color.color_live'))
            .borderRadius(AppConstants.RADIUS_PILL)
            .padding({ left: 6, right: 6, top: 1, bottom: 1 })
            .height(20)
            .textAlign(TextAlign.Center)
            .fontWeight(FontWeight.Bold)
            .constraintSize({ minWidth: 20 })
        } else if (menu.badgeType === 'soft' && this.getBadgeCount(menu) > 0) {
          Text(`${this.getBadgeCount(menu)}`)
            .fontSize(10)
            .fontColor(Color.White)
            .backgroundColor('rgba(255,255,255,0.22)')
            .borderRadius(AppConstants.RADIUS_PILL)
            .padding({ left: 6, right: 6, top: 1, bottom: 1 })
            .height(20)
            .textAlign(TextAlign.Center)
            .fontWeight(FontWeight.Bold)
            .constraintSize({ minWidth: 20 })
        }
      }
      .width('100%')
      .height(48)
      .padding({ left: 20, right: 16 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(48)
    .backgroundColor(this.currentMenu === menu.id ? 'rgba(255,255,255,0.15)' : Color.Transparent)
    .onClick(() => {
      this.onMenuClick(menu);
    })
  }

  /** 顶部栏（v2.0：汉堡按钮 + 页面标题 + 管理员信息） */
  @Builder
  TopBar() {
    Row({ space: 12 }) {
      // 汉堡按钮
      Stack() {
        Column({ space: 4 }) {
          Column()
            .width(20)
            .height(2)
            .borderRadius(1)
            .backgroundColor($r('app.color.color_ink'))
          Column()
            .width(20)
            .height(2)
            .borderRadius(1)
            .backgroundColor($r('app.color.color_ink'))
          Column()
            .width(20)
            .height(2)
            .borderRadius(1)
            .backgroundColor($r('app.color.color_ink'))
        }
      }
      .width(40)
      .height(40)
      .borderRadius(AppConstants.RADIUS_SM)
      .backgroundColor($r('app.color.color_bg_card'))
      .shadow(AppConstants.SHADOW_CARD)
      .onClick(() => { this.sidebarOpen = true; })

      // 页面标题
      Text(this.getCurrentMenuLabel())
        .fontSize(18)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .letterSpacing(0.3)
        .layoutWeight(1)

      // 管理员头像
      if (this.adminInfo) {
        Image($r('app.media.avatar_admin'))
          .width(36)
          .height(36)
          .borderRadius(18)
          .border({ width: 1, color: $r('app.color.color_line_2') })
          .objectFit(ImageFit.Cover)
      }
    }
    .width('100%')
    .height(60)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_cream'))
    .alignItems(VerticalAlign.Center)
  }

  /** 主内容区（spec 10.8.4：仅 Dashboard 概览） */
  @Builder
  MainContent() {
    Scroll() {
      Column({ space: 16 }) {
        // 1. 黄色渐变欢迎卡（吉祥物缩小）
        this.WelcomeCard()
        // 2. 4 张统计卡片（2×2 网格）
        this.StatGrid()
        // 3. 趋势图表卡（7 天 GMV 柱状图）
        this.ChartCard()
        // 4. 快捷操作区（纵向列表）
        this.QuickSection()
      }
      .width('100%')
      .padding(16)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .align(Alignment.Top)
  }

  /** 黄色渐变欢迎卡（v2.0：吉祥物缩小至 56×56，不抢占核心数据区） */
  @Builder
  WelcomeCard() {
    Row() {
      // 左侧文字区
      Column({ space: 6 }) {
        Text(`欢迎回来，${this.adminInfo?.nickname ?? '管理员'}`)
          .fontSize(18)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .letterSpacing(0.3)
        // 副信息行：今日订单 · GMV
        Row({ space: 10 }) {
          Text(`订单 ${this.stats ? this.stats.todayOrders : 456} 笔`)
            .fontSize(12)
            .fontColor('rgba(26,26,26,0.7)')
            .fontWeight(FontWeight.Medium)
          Column()
            .width(3)
            .height(3)
            .borderRadius(2)
            .backgroundColor('rgba(26,26,26,0.3)')
          Text('GMV ¥56,800')
            .fontSize(12)
            .fontColor('rgba(26,26,26,0.7)')
            .fontWeight(FontWeight.Medium)
        }
        .alignItems(VerticalAlign.Center)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 右侧吉祥物（v2.0：从 104 缩小至 56）
      Image($r('app.media.mascot_farmer'))
        .width(56)
        .height(56)
        .objectFit(ImageFit.Contain)
        .margin({ left: 12 })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 18, bottom: 18 })
    .borderRadius(AppConstants.RADIUS_LG)
    .linearGradient({
      angle: 135,
      colors: [[$r('app.color.color_yellow'), 0.0], [$r('app.color.color_yellow_deep'), 1.0]]
    })
    .shadow({ radius: 14, color: 'rgba(255,217,61,0.35)', offsetX: 0, offsetY: 4 })
    .alignItems(VerticalAlign.Center)
  }

  /** 4 张统计卡片（v2.0：2×2 网格布局，适配窄屏） */
  @Builder
  StatGrid() {
    Grid() {
      ForEach(this.buildStatCards(), (stat: StatCardData) => {
        GridItem() {
          this.StatCard(stat)
        }
      }, (stat: StatCardData) => stat.label)
    }
    .columnsTemplate('1fr 1fr')
    .rowsGap(12)
    .columnsGap(12)
    .width('100%')
    .height(290)
  }

  /** 单个统计卡片 */
  @Builder
  StatCard(stat: StatCardData) {
    Column({ space: 10 }) {
      // 头部：标签 + 图标圆
      Row() {
        Text(stat.label)
          .fontSize(12)
          .fontColor($r('app.color.color_text_2'))
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
        Stack() {
          Image(stat.icon)
            .width(18)
            .height(18)
            .fillColor(stat.iconColor)
        }
        .width(34)
        .height(34)
        .borderRadius(17)
        .backgroundColor(stat.iconBg)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 数值
      Text(stat.value)
        .fontSize(24)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .letterSpacing(-0.5)
        .maxLines(1)

      // 趋势
      Row({ space: 3 }) {
        Text(stat.trend > 0 ? '▲' : '▼')
          .fontSize(11)
          .fontColor(stat.trend > 0 ? $r('app.color.color_green_deep') : $r('app.color.color_live'))
          .fontWeight(FontWeight.Bold)
        Text(`${stat.trend > 0 ? '+' : ''}${stat.trend}%`)
          .fontSize(11)
          .fontColor(stat.trend > 0 ? $r('app.color.color_green_deep') : $r('app.color.color_live'))
          .fontWeight(FontWeight.Bold)
      }
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(14)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 趋势图表卡（v2.0：柱状图优化，数值标签精简，柱子宽度自适应） */
  @Builder
  ChartCard() {
    Column({ space: 14 }) {
      // 标题行
      Row() {
        Text('近7天GMV趋势')
          .fontSize(15)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        Blank()
        Text('日均 ¥18.4k · 累计 ¥128.6k')
          .fontSize(11)
          .fontColor($r('app.color.color_text_3'))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 柱状图区域
      Row() {
        ForEach(this.barData, (bar: BarItem) => {
          this.BarColumn(bar)
        }, (bar: BarItem) => bar.label)
      }
      .width('100%')
      .height(180)
      .padding({ bottom: 6 })
      .border({ width: { bottom: 1 }, color: $r('app.color.color_line') })

      // X 轴标签
      Row() {
        ForEach(this.barData, (bar: BarItem) => {
          Text(bar.label)
            .fontSize(10)
            .fontColor(bar.isPeak ? $r('app.color.color_ink') : $r('app.color.color_text_3'))
            .fontWeight(bar.isPeak ? FontWeight.Bold : FontWeight.Medium)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .maxLines(1)
        }, (bar: BarItem) => bar.label)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 18, bottom: 18 })
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 单个柱状图列（v2.0：数值标签精简去¥前缀，字号缩小避免重叠） */
  @Builder
  BarColumn(bar: BarItem) {
    Column() {
      // 数值标签（精简：去¥前缀，仅保留数字+k）
      Text(bar.valueText)
        .fontSize(9)
        .fontColor(bar.isPeak ? $r('app.color.color_ink') : $r('app.color.color_text_2'))
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 4 })
        .maxLines(1)
      // 柱子（黄色渐变）
      Column()
        .width('55%')
        .height(`${bar.heightPercent}%`)
        .borderRadius({ topLeft: 6, topRight: 6, bottomLeft: 3, bottomRight: 3 })
        .linearGradient({
          angle: 0,
          colors: bar.isPeak
            ? [[$r('app.color.color_yellow_deep'), 0.0], [$r('app.color.color_gold'), 1.0]]
            : [[$r('app.color.color_yellow'), 0.0], [$r('app.color.color_yellow_deep'), 1.0]]
        })
        .shadow(bar.isPeak
          ? { radius: 8, color: 'rgba(255,217,61,0.5)', offsetX: 0, offsetY: 3 }
          : { radius: 0, color: Color.Transparent, offsetX: 0, offsetY: 0 })
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.End)
    .alignItems(HorizontalAlign.Center)
  }

  /** 快捷操作区（v2.0：纵向列表，适配窄屏点击） */
  @Builder
  QuickSection() {
    Column({ space: 10 }) {
      Text('快捷操作')
        .fontSize(15)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)

      ForEach(this.quickActions, (action: QuickAction) => {
        this.QuickButton(action)
      }, (action: QuickAction) => action.title)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /** 单个快捷操作按钮（v2.0：全宽纵向列表项） */
  @Builder
  QuickButton(action: QuickAction) {
    Row({ space: 14 }) {
      // 图标圆
      Stack() {
        Image(action.icon)
          .width(20)
          .height(20)
          .fillColor(action.iconColor)
      }
      .width(42)
      .height(42)
      .borderRadius(21)
      .backgroundColor(action.iconBg)

      // 文字区
      Column({ space: 2 }) {
        Text(action.title)
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        Text(action.desc)
          .fontSize(12)
          .fontColor($r('app.color.color_text_3'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 右箭头
      Text('›')
        .fontSize(20)
        .fontColor($r('app.color.color_text_4'))
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      NavigationHelper.push(action.route);
    })
  }
}
