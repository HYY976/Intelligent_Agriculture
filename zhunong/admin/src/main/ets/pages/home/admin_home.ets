/**
 * admin_home - 管理后台首页（UI 复刻 qunong-harmony-app/pages/admin-dashboard.html）
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
 *
 * UI 设计要点（对齐 admin-dashboard.html）：
 *  - 左侧 240px 深绿侧边栏（#1B5E20）：黄色 Logo + 管理员卡 + 菜单（激活态左侧 3px 黄色条）+ 红色退出
 *  - 右侧主区：顶部栏 + 黄色渐变欢迎卡（含吉祥物）+ 4 统计卡（带趋势%）+ 7 天 GMV 柱状图 + 3 快捷操作
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
  /** 角标类型（soft=灰白 / red=红色 / none=无） */
  badgeType?: 'soft' | 'red' | 'none';
}

/** 统计卡数据项（含图标颜色、趋势） */
interface StatCardData {
  /** 标签 */
  label: string;
  /** 数值（已格式化） */
  value: string;
  /** 图标 emoji */
  icon: string;
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
  /** 图标 emoji */
  icon: string;
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
  /** 侧边栏菜单列表（全部，按角色过滤后展示） */
  private allMenus: MenuItem[] = [
    {
      id: 'dashboard',
      label: '控制台',
      icon: '📊',
      allowedRoles: ['super_admin', 'user_admin', 'content_reviewer', 'api_admin'],
      badgeType: 'none'
    },
    {
      id: 'user_manage',
      label: '用户管理',
      icon: '👥',
      allowedRoles: ['super_admin', 'user_admin'],
      route: RouteName.ADMIN_USER_LIST,
      badgeType: 'soft'
    },
    {
      id: 'api_manage',
      label: 'API管理',
      icon: '🔌',
      allowedRoles: ['super_admin', 'api_admin'],
      route: RouteName.ADMIN_API_LIST,
      badgeType: 'none'
    },
    {
      id: 'content_review',
      label: '内容审核',
      icon: '🛡️',
      allowedRoles: ['super_admin', 'content_reviewer'],
      route: RouteName.ADMIN_REVIEW_LIST,
      badgeType: 'red'
    },
    {
      id: 'ads_manage',
      label: '广告管理',
      icon: '📢',
      allowedRoles: ['super_admin'],
      route: RouteName.ADMIN_ADS_LIST,
      badgeType: 'none'
    }
  ];

  /** 7 天 GMV 柱状图 Mock 数据 */
  private barData: BarItem[] = [
    { label: '周一', value: 9.2, valueText: '¥9.2k', heightPercent: 48, isPeak: false },
    { label: '周二', value: 12.5, valueText: '¥12.5k', heightPercent: 62, isPeak: false },
    { label: '周三', value: 8.6, valueText: '¥8.6k', heightPercent: 43, isPeak: false },
    { label: '周四', value: 15.8, valueText: '¥15.8k', heightPercent: 78, isPeak: false },
    { label: '周五', value: 11.2, valueText: '¥11.2k', heightPercent: 56, isPeak: false },
    { label: '周六', value: 23.8, valueText: '¥23.8k', heightPercent: 96, isPeak: true },
    { label: '周日', value: 17.4, valueText: '¥17.4k', heightPercent: 82, isPeak: false }
  ];

  /** 快捷操作列表 */
  private quickActions: QuickAction[] = [
    {
      title: '用户管理',
      desc: '查看与管理平台用户',
      icon: '👥',
      iconBg: $r('app.color.color_yellow'),
      iconColor: $r('app.color.color_ink'),
      route: RouteName.ADMIN_USER_LIST
    },
    {
      title: '内容审核',
      desc: '12 条内容待审核',
      icon: '🛡️',
      iconBg: $r('app.color.color_green'),
      iconColor: Color.White,
      route: RouteName.ADMIN_REVIEW_LIST
    },
    {
      title: 'API管理',
      desc: '密钥与接口配置',
      icon: '🔌',
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
        icon: '👥',
        iconBg: $r('app.color.color_info_soft'),
        iconColor: $r('app.color.color_info'),
        trend: 8.2
      },
      {
        label: '总卖家',
        value: this.stats ? this.formatNumber(this.stats.totalFarmers) : '1,234',
        icon: '🏪',
        iconBg: $r('app.color.color_green_soft'),
        iconColor: $r('app.color.color_green_deep'),
        trend: 3.5
      },
      {
        label: '待审核',
        value: this.stats ? this.formatNumber(this.stats.pendingReviews) : '12',
        icon: '⏳',
        iconBg: $r('app.color.color_warn_soft'),
        iconColor: $r('app.color.color_warn'),
        trend: -2.1
      },
      {
        label: '今日订单',
        value: this.stats ? this.formatNumber(this.stats.todayOrders) : '456',
        icon: '📦',
        iconBg: $r('app.color.color_yellow_soft'),
        iconColor: $r('app.color.color_yellow_text'),
        trend: 12.8
      }
    ];
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
          // 主内容（dashboard 概览，可滚动）
          this.MainContent()
        }
        .layoutWeight(1)
        .height('100%')
        .backgroundColor($r('app.color.color_cream'))
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 侧边栏（深绿 #1B5E20） */
  @Builder
  Sidebar() {
    Column() {
      // 顶部 Logo 区（黄色方块 + "助农管理"）
      Row({ space: 10 }) {
        Stack() {
          Text('🌾')
            .fontSize(20)
            .fontColor($r('app.color.color_admin_green'))
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
      .width('100%')
      .padding({ left: 20, right: 20, top: 20, bottom: 20 })
      .alignItems(VerticalAlign.Center)

      // 管理员信息卡片（半透明白底 + 头像 + 名称 + 角色徽标）
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
            Text(this.adminInfo.role)
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

      // 退出登录按钮
      Row({ space: 10 }) {
        Text('🚪')
          .fontSize(18)
        Text('退出登录')
          .fontSize(14)
          .fontColor($r('app.color.color_logout_red'))
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 18, bottom: 18 })
      .border({ width: { top: 1 }, color: 'rgba(255,255,255,0.08)' })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.doLogout();
      })
    }
    .width(240)
    .height('100%')
    .backgroundColor($r('app.color.color_admin_green'))
    .justifyContent(FlexAlign.Start)
  }

  /** 菜单项行（激活态：左侧 3px 黄色条 + 半透明白底） */
  @Builder
  MenuItemRow(menu: MenuItem) {
    Stack() {
      // 激活态左侧黄色条
      if (this.currentMenu === menu.id) {
        Column()
          .width(3)
          .height(48)
          .backgroundColor($r('app.color.color_yellow'))
          .borderRadius({ topRight: 2, bottomRight: 2 })
          .position({ x: 0, y: 0 })
      }

      Row({ space: 12 }) {
        Text(menu.icon)
          .fontSize(20)
          .fontColor(this.currentMenu === menu.id ? $r('app.color.color_yellow') : 'rgba(255,255,255,0.82)')
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
            .padding({ left: 5, right: 5, top: 0, bottom: 0 })
            .height(18)
            .textAlign(TextAlign.Center)
            .fontWeight(FontWeight.Bold)
            .constraintSize({ minWidth: 18 })
        } else if (menu.badgeType === 'soft' && this.getBadgeCount(menu) > 0) {
          Text(`${this.getBadgeCount(menu)}`)
            .fontSize(10)
            .fontColor(Color.White)
            .backgroundColor('rgba(255,255,255,0.22)')
            .borderRadius(AppConstants.RADIUS_PILL)
            .padding({ left: 5, right: 5, top: 0, bottom: 0 })
            .height(18)
            .textAlign(TextAlign.Center)
            .fontWeight(FontWeight.Bold)
            .constraintSize({ minWidth: 18 })
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

  /** 顶部栏 */
  @Builder
  TopBar() {
    Row() {
      Text(this.getCurrentMenuLabel())
        .fontSize(20)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .letterSpacing(0.3)
      Blank()
      // 管理员信息（头像 + 名称 + 角色徽标）
      if (this.adminInfo) {
        Row({ space: 10 }) {
          Image($r('app.media.avatar_admin'))
            .width(34)
            .height(34)
            .borderRadius(17)
            .border({ width: 1, color: $r('app.color.color_line_2') })
            .objectFit(ImageFit.Cover)
          Text(this.adminInfo.nickname)
            .fontSize(14)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
          Text(this.getRoleLabel())
            .fontSize(11)
            .fontColor($r('app.color.color_green_deep'))
            .backgroundColor($r('app.color.color_green_soft'))
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(AppConstants.RADIUS_PILL)
            .fontWeight(FontWeight.Bold)
        }
        .alignItems(VerticalAlign.Center)
      }
    }
    .width('100%')
    .height(64)
    .padding({ left: 24, right: 24 })
    .backgroundColor($r('app.color.color_cream'))
    .alignItems(VerticalAlign.Center)
  }

  /** 获取当前菜单名称 */
  private getCurrentMenuLabel(): string {
    const menus: MenuItem[] = this.getVisibleMenus();
    const found: MenuItem | undefined = menus.find((m: MenuItem): boolean => m.id === this.currentMenu);
    return found ? found.label : '控制台概览';
  }

  /** 主内容区（spec 10.8.4：仅 Dashboard 概览） */
  @Builder
  MainContent() {
    Scroll() {
      Column({ space: 20 }) {
        // 1. 黄色渐变欢迎卡（含吉祥物）
        this.WelcomeCard()
        // 2. 4 张统计卡片
        this.StatGrid()
        // 3. 趋势图表卡（7 天 GMV 柱状图）
        this.ChartCard()
        // 4. 快捷操作区
        this.QuickSection()
      }
      .width('100%')
      .padding(24)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .align(Alignment.Top)
  }

  /** 黄色渐变欢迎卡（含吉祥物） */
  @Builder
  WelcomeCard() {
    Row() {
      // 左侧文字区
      Column({ space: 8 }) {
        Text(`欢迎回来，${this.adminInfo?.nickname ?? '管理员'}`)
          .fontSize(20)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .letterSpacing(0.3)
        // 副信息行：今日新增用户 · 订单 · GMV
        Row({ space: 14 }) {
          Text(`今日新增用户 ${this.stats ? this.stats.todayOrders : 286}`)
            .fontSize(13)
            .fontColor('rgba(26,26,26,0.7)')
            .fontWeight(FontWeight.Medium)
          Column()
            .width(4)
            .height(4)
            .borderRadius(2)
            .backgroundColor('rgba(26,26,26,0.3)')
          Text(`订单 ${this.stats ? this.stats.todayOrders : 456} 笔`)
            .fontSize(13)
            .fontColor('rgba(26,26,26,0.7)')
            .fontWeight(FontWeight.Medium)
          Column()
            .width(4)
            .height(4)
            .borderRadius(2)
            .backgroundColor('rgba(26,26,26,0.3)')
          Text('GMV ¥56,800')
            .fontSize(13)
            .fontColor('rgba(26,26,26,0.7)')
            .fontWeight(FontWeight.Medium)
        }
        .alignItems(VerticalAlign.Center)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 右侧吉祥物
      Image($r('app.media.mascot_farmer'))
        .width(104)
        .height(104)
        .objectFit(ImageFit.Contain)
        .margin({ left: 16 })
    }
    .width('100%')
    .padding({ left: 28, right: 28, top: 24, bottom: 24 })
    .borderRadius(AppConstants.RADIUS_LG)
    .linearGradient({
      angle: 135,
      colors: [[$r('app.color.color_yellow'), 0.0], [$r('app.color.color_yellow_deep'), 1.0]]
    })
    .shadow({ radius: 18, color: 'rgba(255,217,61,0.35)', offsetX: 0, offsetY: 6 })
    .alignItems(VerticalAlign.Center)
  }

  /** 4 张统计卡片网格 */
  @Builder
  StatGrid() {
    Row({ space: 16 }) {
      ForEach(this.buildStatCards(), (stat: StatCardData) => {
        this.StatCard(stat)
      }, (stat: StatCardData) => stat.label)
    }
    .width('100%')
  }

  /** 单个统计卡片 */
  @Builder
  StatCard(stat: StatCardData) {
    Column({ space: 12 }) {
      // 头部：标签 + 图标圆
      Row() {
        Text(stat.label)
          .fontSize(13)
          .fontColor($r('app.color.color_text_2'))
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
        Stack() {
          Text(stat.icon)
            .fontSize(20)
        }
        .width(38)
        .height(38)
        .borderRadius(19)
        .backgroundColor(stat.iconBg)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 数值
      Text(stat.value)
        .fontSize(28)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .letterSpacing(-0.5)

      // 趋势
      Row({ space: 3 }) {
        Text(stat.trend > 0 ? '▲' : '▼')
          .fontSize(12)
          .fontColor(stat.trend > 0 ? $r('app.color.color_green_deep') : $r('app.color.color_live'))
          .fontWeight(FontWeight.Bold)
        Text(`${stat.trend > 0 ? '+' : ''}${stat.trend}%`)
          .fontSize(12)
          .fontColor(stat.trend > 0 ? $r('app.color.color_green_deep') : $r('app.color.color_live'))
          .fontWeight(FontWeight.Bold)
      }
      .alignItems(VerticalAlign.Center)
    }
    .layoutWeight(1)
    .padding(18)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 趋势图表卡（7 天 GMV 柱状图） */
  @Builder
  ChartCard() {
    Column({ space: 16 }) {
      // 标题行
      Row() {
        Text('近7天GMV趋势')
          .fontSize(16)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        Blank()
        Text() {
          Span('日均 ')
            .fontColor($r('app.color.color_text_3'))
            .fontSize(12)
          Span('¥18,366')
            .fontColor($r('app.color.color_ink'))
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
          Span(' · 累计 ')
            .fontColor($r('app.color.color_text_3'))
            .fontSize(12)
          Span('¥128,560')
            .fontColor($r('app.color.color_ink'))
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
        }
        .fontSize(12)
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)

      // 柱状图
      Row() {
        ForEach(this.barData, (bar: BarItem) => {
          this.BarColumn(bar)
        }, (bar: BarItem) => bar.label)
      }
      .width('100%')
      .height(200)
      .padding({ bottom: 6 })
      .border({ width: { bottom: 1 }, color: $r('app.color.color_line') })

      // X 轴标签
      Row() {
        ForEach(this.barData, (bar: BarItem) => {
          Text(bar.label)
            .fontSize(11)
            .fontColor(bar.isPeak ? $r('app.color.color_ink') : $r('app.color.color_text_3'))
            .fontWeight(bar.isPeak ? FontWeight.Bold : FontWeight.Medium)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
        }, (bar: BarItem) => bar.label)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 22, bottom: 22 })
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 单个柱状图列 */
  @Builder
  BarColumn(bar: BarItem) {
    Column() {
      // 数值标签
      Text(bar.valueText)
        .fontSize(10)
        .fontColor(bar.isPeak ? $r('app.color.color_ink') : $r('app.color.color_text_2'))
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 6 })
      // 柱子（黄色渐变）
      Column()
        .width('60%')
        .height(`${bar.heightPercent}%`)
        .borderRadius({ topLeft: 8, topRight: 8, bottomLeft: 4, bottomRight: 4 })
        .linearGradient({
          angle: 0,
          colors: bar.isPeak
            ? [[$r('app.color.color_yellow_deep'), 0.0], [$r('app.color.color_gold'), 1.0]]
            : [[$r('app.color.color_yellow'), 0.0], [$r('app.color.color_yellow_deep'), 1.0]]
        })
        .shadow(bar.isPeak
          ? { radius: 10, color: 'rgba(255,217,61,0.5)', offsetX: 0, offsetY: 4 }
          : { radius: 0, color: Color.Transparent, offsetX: 0, offsetY: 0 })
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.End)
    .alignItems(HorizontalAlign.Center)
  }

  /** 快捷操作区 */
  @Builder
  QuickSection() {
    Column({ space: 14 }) {
      Text('快捷操作')
        .fontSize(16)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)

      Row({ space: 16 }) {
        ForEach(this.quickActions, (action: QuickAction) => {
          this.QuickButton(action)
        }, (action: QuickAction) => action.title)
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /** 单个快捷操作按钮 */
  @Builder
  QuickButton(action: QuickAction) {
    Row({ space: 14 }) {
      // 图标圆
      Stack() {
        Text(action.icon)
          .fontSize(22)
          .fontColor(action.iconColor)
      }
      .width(46)
      .height(46)
      .borderRadius(23)
      .backgroundColor(action.iconBg)
      .shadow({ radius: 12, color: 'rgba(255,217,61,0.45)', offsetX: 0, offsetY: 4 })

      // 文字区
      Column({ space: 2 }) {
        Text(action.title)
          .fontSize(15)
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
    }
    .layoutWeight(1)
    .padding(20)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      NavigationHelper.push(action.route);
    })
  }
}
