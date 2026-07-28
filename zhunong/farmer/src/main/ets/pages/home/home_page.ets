﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿/**
 * home_page - 农户卖家端首页
 * 对齐设计稿 pages/farmer-home.html：
 *  - 顶部 4 入口导航栏（商城/直播/智能体/搜索）白底圆角18浮卡 56vp
 *  - 营收异形面板（深黑 #1A1A1A 底 + 右上角径向光晕 + 时间范围胶囊组 + 圆形模式开关
 *    + 营收金额大字浅绿 #81C784 + 辅助数据3等分 + 金色分隔线 + 卖家名称行+V徽章）
 *  - 我的商品标题区（"我的商品" + "查看全部 ›"）
 *  - 横向滚动商品卡片（120宽：120×120图 + 名称 + 价格 + 月销）
 *  - 查看营收明细按钮（黄色胶囊全宽按钮 + 右箭头）
 *  - 底部 5 Tab 导航（首页/社区/直播/消息/个人，5等分无FAB，选中态黄色图标）
 *
 * spec 3.2.1 / 3.2.3 / 3.2.4 / 6.6.1
 */

import { TokenStore, Logger, AppConstants, ModeStore, NavigationHelper, RouteName, FontUtil, SharedProductStore, SharedProduct } from 'common';
import { UserInfo } from 'common';
import type { CurrentModeKey } from 'common';
import { FarmerProfile, RevenueSummary, RevenueRange, FarmerProductItem } from '../../model/FarmerModels';
import { FarmerRepository } from '../../repository/FarmerRepository';
import { RevenueRepository } from '../../repository/RevenueRepository';
import { MOCK_FARMER_ID, getMockRevenueSummary, getMockHomeProducts } from '../../mock/FarmerMock';
import { ImageUtil } from '../../utils/ImageUtil';

/** 跳转商品编辑页的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface ProductEditParam {
  productId: string;
}

/** spec 16.10：跳转商品详情购买页的路由参数 */
interface ProductDetailParam {
  productId: string;
}

/** 营收时间范围胶囊项 */
interface RevenueRangeOption {
  value: RevenueRange;
  label: string;
}

@ComponentV2
export struct FarmerHomePage {
  /** 当前底部 Tab 索引（0=首页 1=社区 2=直播 3=消息 4=个人） */
  @Local currentTab: number = 0;
  /** 卖家信息 */
  @Local profile: FarmerProfile | null = null;
  /** spec 16.10：用户昵称（与设置页个人信息同步） */
  @Local userNickname: string = '';
  /** spec 16.10：用户头像 URI（与设置页个人信息同步） */
  @Local userAvatar: string = '';
  /** 当前模式（标准/老年大字）—— spec 10.18：@Local modeRef 持有 AppStorageV2 共享 ref */
  @Local modeRef: CurrentModeKey = ModeStore.connectModeRef();
  /** 营收时间范围 */
  @Local revenueRange: RevenueRange = 'today';
  /** 营收数据 */
  @Local revenueData: RevenueSummary = {
    amount: 1286.00,
    orderCount: 23,
    productCount: 8,
    conversionRate: 12.5
  };
  /** 横滑商品列表 */
  @Local productList: FarmerProductItem[] = [];

  /** 营收时间范围选项（对齐设计稿 qn-rev-seg） */
  private rangeOptions: RevenueRangeOption[] = [
    { value: 'today', label: '今日' },
    { value: 'month', label: '本月' },
    { value: 'year', label: '本年' },
    { value: 'total', label: '累计' }
  ];

  async aboutToAppear(): Promise<void> {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'home_page_appear', mode: this.modeRef.value });
    await this.loadData();
    await this.loadUserInfo();
  }

  /** spec 16.10/16.14：从发布页/设置页/卖家中心返回后刷新，确保营收/粉丝/商品数据同步 */
  onPageShow(): void {
    this.loadData();
    this.loadUserInfo();
  }

  /** spec 16.10：从 TokenStore 加载用户头像和昵称（与设置页个人信息同步） */
  private async loadUserInfo(): Promise<void> {
    try {
      const user: UserInfo | null = await TokenStore.getUserInfo();
      if (user) {
        this.userNickname = user.nickname && user.nickname.length > 0 ? user.nickname : '';
        this.userAvatar = user.avatar;
      }
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'home_load_user_info_fail', error: (err as Error).message });
    }
  }

  /** 加载数据 */
  private async loadData(): Promise<void> {
    try {
      this.profile = await FarmerRepository.getMyProfile(MOCK_FARMER_ID);
      this.revenueData = await RevenueRepository.getRevenueSummary(MOCK_FARMER_ID, this.revenueRange);
      this.productList = getMockHomeProducts();
      // spec 16.10：同步 SharedProductStore 中已发布商品到首页"我的商品"
      await this.syncPublishedProducts();
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'home_load_fail', error: (err as Error).message });
      // 兜底 Mock
      this.productList = getMockHomeProducts();
    }
  }

  /** spec 16.10：合并 SharedProductStore 中已发布商品到首页"我的商品"列表头部 */
  private async syncPublishedProducts(): Promise<void> {
    try {
      const shared: SharedProduct[] = await SharedProductStore.getAll();
      const existingIds: Set<string> = new Set<string>(this.productList.map(
        (p: FarmerProductItem): string => p.productId
      ));
      const mine: FarmerProductItem[] = shared
        .filter((p: SharedProduct): boolean => p.status === 'approved')
        .map((p: SharedProduct): FarmerProductItem => {
          const item: FarmerProductItem = {
            productId: p.productId,
            title: p.title,
            mainImage: p.mainImages.length > 0 ? p.mainImages[0] : 'prod_default',
            price: p.price,
            stock: p.stock,
            monthlySales: p.monthlySales,
            monthlyGmv: p.monthlyGmv,
            status: p.status,
            createdAt: p.createdAt
          };
          return item;
        })
        .filter((p: FarmerProductItem): boolean => !existingIds.has(p.productId));
      if (mine.length > 0) {
        this.productList = mine.concat(this.productList);
      }
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'home_sync_products_fail', error: (err as Error).message });
    }
  }

  /** 是否老年大字模式（spec 10.18） */
  private isElderMode(): boolean {
    return this.modeRef.value === AppConstants.MODE_ELDER;
  }

  /** 切换模式 spec 3.2.3.2 */
  private async toggleMode(): Promise<void> {
    const prev: string = this.modeRef.value;
    await ModeStore.toggleMode();
    Logger.info(AppConstants.SCENE_FARMER, { action: 'mode_toggle', from: prev, to: this.modeRef.value });
  }

  /** 切换营收时间范围 */
  private async onRangeChange(r: RevenueRange): Promise<void> {
    this.revenueRange = r;
    try {
      this.revenueData = await RevenueRepository.getRevenueSummary(MOCK_FARMER_ID, r);
    } catch (err) {
      this.revenueData = getMockRevenueSummary(r);
    }
    Logger.info(AppConstants.SCENE_FARMER, { action: 'revenue_range_change', range: r });
  }

  /** 获取营收范围文案 */
  private getRevenueRangeLabel(): string {
    switch (this.revenueRange) {
      case 'today':
        return '今日营收';
      case 'month':
        return '本月营收';
      case 'year':
        return '本年营收';
      case 'total':
        return '累计营收';
      default:
        return '今日营收';
    }
  }

  /** 格式化金额（千分位） */
  private formatAmount(amount: number): string {
    const parts: string[] = amount.toFixed(2).split('.');
    parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    return parts.join('.');
  }

  build() {
    NavDestination() {
      Column() {
        // 1. 顶部 4 入口导航栏（白底圆角浮卡）
        this.TopNavBar()

        // 2. 内容区
        Scroll() {
          Column({ space: 16 }) {
            // a) 营收异形面板（深黑底）
            this.RevenuePanel()

            // b) 我的商品标题区
            this.ProductSectionHead()

            // c) 横向滚动商品卡片
            this.ProductScroll()

            // d) 查看营收明细按钮（黄色胶囊）
            this.ViewRevenueButton()
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 24 })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        // 3. 底部 5 Tab 导航
        this.BottomTabBar()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
    .onShown(() => {
      // spec 16.10/16.15：NavDestination 显示时刷新（从设置页/发布页/卖家中心返回后同步营收/头像/姓名/新商品）
      this.loadData();
      this.syncPublishedProducts();
      this.loadUserInfo();
    })
  }

  /** 顶部 4 入口导航栏（对齐设计稿 qn-topnav：白底圆角18浮卡 56vp） */
  @Builder
  TopNavBar() {
    Row() {
      this.NavItem('商城', '🛍', 0, RouteName.FARMER_SELLER_MALL)
      this.NavItem('直播', '📹', 1, RouteName.FARMER_LIVE_BROWSE)
      this.NavItem('智能体', '✨', 2, RouteName.FARMER_AGENT_PAGE)
      this.NavItem('搜索', '🔍', 3, RouteName.FARMER_SEARCH_PAGE)
    }
    .width('100%')
    .height(56)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .padding({ left: 8, right: 8 })
    .margin({ left: 16, right: 16, top: 12, bottom: 4 })
  }

  /** 顶部导航项（对齐设计稿 qn-topnav-item：纵向图标+文字） */
  @Builder
  NavItem(label: string, icon: string, _index: number, route: string) {
    Column({ space: 3 }) {
      Text(icon)
        .fontSize(this.isElderMode() ? 24 : 22)
      Text(label)
        .fontSize(this.isElderMode() ? 13 : 11)
        .fontColor($r('app.color.color_ink_2'))
        .fontWeight(FontWeight.Medium)
    }
    .layoutWeight(1)
    .height(56)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      Logger.info(AppConstants.SCENE_FARMER, { action: 'top_nav_click', nav: label });
      NavigationHelper.push(route);
    })
  }

  /** 营收异形面板（对齐设计稿 qn-rev-panel：深黑底 + 右上角光晕 + 时间胶囊组 + 模式开关 + 金额大字 + 3等分数据 + 金线 + 卖家行） */
  @Builder
  RevenuePanel() {
    Stack({ alignContent: Alignment.TopEnd }) {
      // 右上角径向光晕装饰（对齐 qn-rev-panel::after）
      Column()
        .width(132)
        .height(132)
        .borderRadius(66)
        .linearGradient({
          angle: 0,
          colors: [['rgba(255,217,61,0.22)', 0], ['rgba(255,217,61,0)', 0.7]]
        })
        .position({ right: -44, top: -44 })
        .hitTestBehavior(HitTestMode.Transparent)

      // 主内容
      Column() {
        // 顶部行：标题 + 时间胶囊组 | 模式开关
        Row() {
          // 左侧：标题 + 时间范围胶囊组
          Column({ space: 8 }) {
            Text(this.getRevenueRangeLabel())
              .fontSize(this.isElderMode() ? 20 : 16)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
            // 时间范围胶囊组（对齐 qn-rev-seg）
            Row({ space: 3 }) {
              ForEach(this.rangeOptions, (opt: RevenueRangeOption) => {
                Text(opt.label)
                  .fontSize(this.isElderMode() ? 13 : 11)
                  .fontColor(this.revenueRange === opt.value ? Color.White : 'rgba(255,255,255,0.65)')
                  .fontWeight(this.revenueRange === opt.value ? FontWeight.Bold : FontWeight.Normal)
                  .backgroundColor(this.revenueRange === opt.value ? 'rgba(255,255,255,0.18)' : Color.Transparent)
                  .padding({ left: 10, right: 10, top: 3, bottom: 3 })
                  .borderRadius(AppConstants.RADIUS_PILL)
                  .onClick(() => { this.onRangeChange(opt.value); })
              }, (opt: RevenueRangeOption) => opt.value)
            }
            .padding({ left: 3, right: 3, top: 3, bottom: 3 })
            .borderRadius(AppConstants.RADIUS_PILL)
            .backgroundColor('rgba(255,255,255,0.08)')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // 右侧：圆形模式开关（对齐 qn-mode-switch 48×48）
          this.ModeToggle()
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)

        // 营收金额大字（对齐 qn-rev-amount：浅绿 #81C784）
        Row() {
          Text('¥')
            .fontSize(this.isElderMode() ? 22 : 18)
            .fontColor($r('app.color.color_green_mint'))
            .fontWeight(FontWeight.Bold)
            .margin({ right: 2 })
          Text(this.formatAmount(this.revenueData.amount))
            .fontSize(this.isElderMode() ? 36 : 28)
            .fontColor($r('app.color.color_green_mint'))
            .fontWeight(FontWeight.Bold)
        }
        .margin({ top: 18 })

        // 辅助数据 3 等分（对齐 qn-rev-stats：订单数/商品数/转化率）
        Row() {
          this.RevenueCell(`${this.revenueData.orderCount}`, '笔', '订单数')
          this.RevenueCell(`${this.revenueData.productCount}`, '件', '商品数')
          this.RevenueCell(`${this.revenueData.conversionRate}`, '%', '转化率')
        }
        .width('100%')
        .margin({ top: 16 })

        // 金色分隔线（对齐 qn-rev-gold-line）
        Divider()
          .strokeWidth(1)
          .color('rgba(255,215,0,0.3)')
          .margin({ top: 16, bottom: 16 })

        // 卖家名称行（对齐 qn-rev-seller：头像 + 店铺名 + V徽章；spec 16.10：同步设置页头像/姓名）
        Row({ space: 10 }) {
          Image(this.userAvatar && this.userAvatar.length > 0
            ? this.userAvatar
            : $r('app.media.avatar_farmer'))
            .width(32)
            .height(32)
            .borderRadius(16)
            .objectFit(ImageFit.Cover)
            .border({ width: 2, color: 'rgba(255,217,61,0.4)' })
          Text(this.userNickname && this.userNickname.length > 0
            ? this.userNickname
            : (this.profile?.shopName ?? '助农卖家'))
            .fontSize(this.isElderMode() ? 15 : 13)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
          // V 认证徽章（对齐 qn-v-badge：16×16 黄底圆 + V字）
          Text('V')
            .fontSize(FontUtil.s(11, this.isElderMode()))
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .width(16)
            .height(16)
            .borderRadius(8)
            .backgroundColor($r('app.color.color_yellow'))
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding(20)
    }
    .width('100%')
    .borderRadius(AppConstants.RADIUS_XL)
    .backgroundColor($r('app.color.color_dark_panel'))
    .shadow({ radius: 24, color: 'rgba(26,26,26,0.18)', offsetX: 0, offsetY: 8 })
  }

  /** 右上角模式开关（滑动式：默认⇄老人，点击切换） */
  @Builder
  ModeToggle() {
    Row({ space: 8 }) {
      // 文字标签
      Text(this.isElderMode() ? '老人' : '默认')
        .fontSize(FontUtil.s(11, this.isElderMode()))
        .fontColor('rgba(255,255,255,0.75)')
        .fontWeight(FontWeight.Medium)

      // 滑轨 + 滑块
      Stack() {
        Row() {
          Text(this.isElderMode() ? '老' : '默')
            .fontSize(FontUtil.s(10, this.isElderMode()))
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
        }
        .width(22)
        .height(22)
        .borderRadius(11)
        .backgroundColor(this.isElderMode() ? $r('app.color.color_yellow') : Color.White)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .shadow({ radius: 4, color: 'rgba(0,0,0,0.25)', offsetX: 0, offsetY: 2 })
        .position({ x: this.isElderMode() ? 25 : 3, y: 3 })
        .animation({ duration: 200, curve: Curve.EaseInOut })
      }
      .width(50)
      .height(28)
      .borderRadius(14)
      .backgroundColor(this.isElderMode() ? 'rgba(255,217,61,0.4)' : $r('app.color.color_dark_soft'))
      .onClick(() => { this.toggleMode(); })
    }
    .alignItems(VerticalAlign.Center)
  }

  /** 营收辅助数据项（对齐 qn-rev-cell：数字+单位 / 标签） */
  @Builder
  RevenueCell(num: string, unit: string, label: string) {
    Column({ space: 5 }) {
      Row() {
        Text(num)
          .fontSize(this.isElderMode() ? 17 : 14)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
        Text(unit)
          .fontSize(FontUtil.s(11, this.isElderMode()))
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 1 })
      }
      Text(label)
        .fontSize(this.isElderMode() ? 13 : 11)
        .fontColor('rgba(255,255,255,0.62)')
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .border({ width: { left: 0 }, color: Color.Transparent })
  }

  /** 我的商品标题区（对齐 qn-section-head：标题 + 查看全部›） */
  @Builder
  ProductSectionHead() {
    Row() {
      Text('我的商品')
        .fontSize(this.isElderMode() ? 20 : 16)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
      Blank()
      Row() {
        Text('查看全部')
          .fontSize(this.isElderMode() ? 13 : 12)
          .fontColor($r('app.color.color_text_3'))
        Text('›')
          .fontSize(this.isElderMode() ? 14 : 12)
          .fontColor($r('app.color.color_text_3'))
      }
      .onClick(() => {
        Logger.info(AppConstants.SCENE_FARMER, { action: 'goto_product_manage' });
        NavigationHelper.push(RouteName.FARMER_PRODUCT_MANAGE);
      })
    }
    .width('100%')
    .padding({ left: 2, right: 2, bottom: 8 })
  }

  /** 横向滚动商品卡片（对齐 qn-prod-scroll：120宽卡片横滑） */
  @Builder
  ProductScroll() {
    Scroll() {
      Row({ space: 12 }) {
        ForEach(this.productList, (product: FarmerProductItem) => {
          this.ProductCard(product)
        }, (product: FarmerProductItem) => product.productId)
      }
      .padding({ right: 16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
  }

  /** 单个商品卡片（对齐 qn-prod-card：120×120图 + 名称 + 价格 + 月销） */
  @Builder
  ProductCard(product: FarmerProductItem) {
    Column({ space: 6 }) {
      // 商品图（120×120 圆角14，spec 16.11：支持 file:// / http(s) URI 直接渲染）
      Image(
        product.mainImage.startsWith('file://') || product.mainImage.startsWith('http')
          ? product.mainImage
          : ImageUtil.get(product.mainImage)
      )
        .width(120)
        .height(120)
        .borderRadius(AppConstants.RADIUS_MD)
        .objectFit(ImageFit.Cover)
        .backgroundColor($r('app.color.color_fill'))

      // 商品名称（单行省略）
      Text(product.title)
        .fontSize(this.isElderMode() ? 14 : 12)
        .fontColor($r('app.color.color_ink_2'))
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width(120)

      // 价格（红色）
      Row() {
        Text('¥')
          .fontSize(FontUtil.s(11, this.isElderMode()))
          .fontColor($r('app.color.color_live'))
          .fontWeight(FontWeight.Bold)
        Text(product.price.toFixed(1))
          .fontSize(this.isElderMode() ? 16 : 14)
          .fontColor($r('app.color.color_live'))
          .fontWeight(FontWeight.Bold)
      }

      // 月销量
      Text(`月销 ${product.monthlySales}`)
        .fontSize(this.isElderMode() ? 12 : 10)
        .fontColor($r('app.color.color_text_3'))
    }
    .width(120)
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      Logger.info(AppConstants.SCENE_FARMER, { action: 'product_card_click', productId: product.productId });
      // spec 16.10：所有商品点击进入详情购买页
      const param: ProductDetailParam = { productId: product.productId };
      NavigationHelper.push(RouteName.FARMER_PRODUCT_DETAIL, param);
    })
  }

  /** 查看营收明细按钮（对齐 qn-btn-yellow qn-btn-pill：黄色胶囊全宽） */
  @Builder
  ViewRevenueButton() {
    Row() {
      Text('查看营收明细')
        .fontSize(this.isElderMode() ? 17 : 15)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
      Text('›')
        .fontSize(FontUtil.s(16, this.isElderMode()))
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .margin({ left: 6 })
    }
    .width('100%')
    .height(46)
    .borderRadius(AppConstants.RADIUS_PILL)
    .backgroundColor($r('app.color.color_yellow'))
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      Logger.info(AppConstants.SCENE_FARMER, { action: 'goto_revenue_stats' });
      NavigationHelper.push(RouteName.FARMER_REVENUE_STATS);
    })
  }

  /** 底部 5 Tab 导航（对齐 qn-tabbar：5等分无FAB，选中态黄色图标） */
  @Builder
  BottomTabBar() {
    Row() {
      this.BottomTabItem('首页', '🏠', 0)
      this.BottomTabItem('社区', '💬', 1)
      this.BottomTabItem('直播', '📹', 2)
      this.BottomTabItem('消息', '✉️', 3)
      this.BottomTabItem('个人', '👤', 4)
    }
    .width('100%')
    .height(64)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_NAV)
    .padding({ left: 8, right: 8, bottom: 8 })
  }

  /** 底部 Tab 项（对齐 qn-tab：选中态墨黑文字+黄色图标） */
  @Builder
  BottomTabItem(label: string, icon: string, index: number) {
    Column({ space: 2 }) {
      Text(icon)
        .fontSize(this.isElderMode() ? 26 : 24)
        .fontColor(this.currentTab === index ? $r('app.color.color_yellow_deep') : $r('app.color.color_text_3'))
      Text(label)
        .fontSize(this.isElderMode() ? 12 : 10)
        .fontColor(this.currentTab === index ? $r('app.color.color_ink') : $r('app.color.color_text_3'))
        .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Medium)
    }
    .layoutWeight(1)
    .height(64)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.currentTab = index;
      Logger.info(AppConstants.SCENE_FARMER, { action: 'tab_switch', tab: label });
      if (index === 1) {
        NavigationHelper.push(RouteName.FARMER_COMMUNITY_LIST);
      } else if (index === 2) {
        NavigationHelper.push(RouteName.FARMER_LIVE_CREATE);
      } else if (index === 3) {
        NavigationHelper.push(RouteName.FARMER_MESSAGE_LIST);
      } else if (index === 4) {
        NavigationHelper.push(RouteName.FARMER_SELLER_PROFILE);
      }
    })
  }
}
