/**
 * home_page - 农户卖家端首页（营收异形面板 + 模式开关 + 横滑商品卡片）
 * 遵循 spec 3.2.1 / 3.2.3 / 3.2.4 / 6.6.1：
 *  - 顶部全局固定导航栏（56vp，4入口：商城/直播/智能体/搜索）spec 3.2.1
 *  - 底部 5 Tab：首页 / 社区 / 直播 / 消息 / 个人 spec 3.2.4
 *  - 首页 Tab = 营收异形面板（深黑 #1A1A1A + 浅绿数据 #81C784 + 丰收橙点缀 + 金色装饰 + 24vp 异形圆角）spec 3.2.3.1
 *  - 右上角圆形开关（48vp×48vp）切换标准/老年大字模式，仅卖家端生效 spec 3.2.3.2 / 6.6.1
 *  - 横向滚动商品卡片（展示该卖家全部上架商品）spec 3.2.3.1
 *  - 阶段1：营收/商品数据为 Mock 占位，后续阶段接入后端
 */

import { TokenStore, Logger, AppConstants, ModeStore, FarmerRoutes, NavigationHelper, RouteName } from 'common';
import { UserInfo } from 'common';
import type { CurrentModeKey } from 'common';

/** 跳转商品编辑页的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface ProductEditParam {
  productId: string;
}

/** 营收时间范围 */
type RevenueRange = 'today' | 'month' | 'year' | 'total';

/** 营收汇总数据 */
interface RevenueSummary {
  /** 营收金额（元） */
  amount: number;
  /** 订单数 */
  orderCount: number;
  /** 商品数 */
  productCount: number;
  /** 转化率（百分比） */
  conversionRate: number;
}

/** 横滑商品卡片数据（spec 3.2.3.1：商品图+名称+价格+月销量） */
interface ProductCardInfo {
  productId: string;
  name: string;
  price: number;
  monthlySales: number;
  imageUrl: string;
}

@ComponentV2
export struct FarmerHomePage {
  /** 当前底部 Tab 索引（0=首页 1=社区 2=直播 3=消息 4=个人） */
  @Local currentTab: number = 0;
  /** 当前顶部导航入口索引（0=商城 1=直播 2=智能体 3=搜索）spec 3.2.1 */
  @Local currentNav: number = 0;
  /** 卖家昵称 */
  @Local nickname: string = '助农卖家';
  /** 当前模式（标准/老年大字）—— spec 10.18：@Local modeRef 持有 AppStorageV2 共享 ref，@Trace value 变更自动刷新 build() */
  @Local modeRef: CurrentModeKey = ModeStore.connectModeRef();
  /** 营收时间范围 */
  @Local revenueRange: RevenueRange = 'today';
  /** 营收数据（Mock） */
  @Local revenueData: RevenueSummary = {
    amount: 1286.50,
    orderCount: 23,
    productCount: 8,
    conversionRate: 12.5
  };
  /** 横滑商品列表（Mock） */
  @Local productList: ProductCardInfo[] = [
    { productId: 'p001', name: '有机青菜', price: 9.90, monthlySales: 156, imageUrl: '' },
    { productId: 'p002', name: '土鸡蛋30枚', price: 39.90, monthlySales: 89, imageUrl: '' },
    { productId: 'p003', name: '农家大米5kg', price: 59.00, monthlySales: 64, imageUrl: '' },
    { productId: 'p004', name: '新鲜番茄', price: 12.80, monthlySales: 42, imageUrl: '' }
  ];

  async aboutToAppear(): Promise<void> {
    const userInfo: UserInfo | null = await TokenStore.getUserInfo();
    if (userInfo) {
      this.nickname = userInfo.nickname;
    }
    // spec 10.18：modeRef 通过 connectModeRef() 持有共享实例，无需手动 getMode（EntryAbility.initMode 已初始化）
    Logger.info(AppConstants.SCENE_FARMER, { action: 'home_page_appear', mode: this.modeRef.value });
  }

  /** 是否老年大字模式（spec 10.18：读取 modeRef.value，@Trace 变更自动触发 build() 刷新） */
  private isElderMode(): boolean {
    return this.modeRef.value === AppConstants.MODE_ELDER;
  }

  /** 切换模式（标准 ↔ 老年大字）spec 3.2.3.2：仅卖家端生效；spec 10.18：setMode 已通过共享 ref 自动同步，无需手动赋值 */
  private async toggleMode(): Promise<void> {
    const prev: string = this.modeRef.value;
    await ModeStore.toggleMode();
    Logger.info(AppConstants.SCENE_FARMER, { action: 'mode_toggle', from: prev, to: this.modeRef.value });
  }

  /** 切换营收时间范围（点击标题区循环切换）spec 3.2.3.1 */
  private cycleRevenueRange(): void {
    const ranges: RevenueRange[] = ['today', 'month', 'year', 'total'];
    const idx: number = ranges.indexOf(this.revenueRange);
    this.revenueRange = ranges[(idx + 1) % ranges.length];
    // Mock：根据时间范围切换数据
    this.updateRevenueMock();
    Logger.info(AppConstants.SCENE_FARMER, { action: 'revenue_range_change', range: this.revenueRange });
  }

  /** 根据时间范围更新 Mock 营收数据 */
  private updateRevenueMock(): void {
    switch (this.revenueRange) {
      case 'today':
        this.revenueData = { amount: 1286.50, orderCount: 23, productCount: 8, conversionRate: 12.5 };
        break;
      case 'month':
        this.revenueData = { amount: 38560.20, orderCount: 612, productCount: 8, conversionRate: 15.8 };
        break;
      case 'year':
        this.revenueData = { amount: 458920.80, orderCount: 7823, productCount: 8, conversionRate: 14.2 };
        break;
      case 'total':
        this.revenueData = { amount: 1286530.60, orderCount: 21568, productCount: 8, conversionRate: 13.6 };
        break;
      default:
        break;
    }
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

  /** 获取营收金额展示文案 */
  private getRevenueAmountText(): string {
    return `¥${this.revenueData.amount.toFixed(2)}`;
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部全局固定导航栏（spec 3.2.1：56vp，4入口 商城/直播/智能体/搜索）
        this.TopNavBar()

        // 内容区（根据 currentTab 切换）
        Column() {
          if (this.currentTab === 0) {
            this.HomeTabContent()
          } else if (this.currentTab === 1) {
            this.PlaceholderTabContent('社区')
          } else if (this.currentTab === 2) {
            this.PlaceholderTabContent('直播（一键开播）')
          } else if (this.currentTab === 3) {
            this.PlaceholderTabContent('消息')
          } else {
            this.PlaceholderTabContent('个人中心')
          }
        }
        .width('100%')
        .layoutWeight(1)

        // 底部 5 Tab 导航（spec 3.2.4：首页/社区/直播/消息/个人）
        this.BottomTabBar()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 顶部全局固定导航栏（spec 3.2.1） */
  @Builder
  TopNavBar() {
    Row({ space: 0 }) {
      this.NavItem('商城', 0)
      this.NavItem('直播', 1)
      this.NavItem('智能体', 2)
      this.NavItem('搜索', 3)
    }
    .width('100%')
    .height(56)
    .backgroundColor($r('app.color.color_bg_card'))
    .padding({ left: 8, right: 8 })
  }

  /** 顶部导航项 */
  @Builder
  NavItem(label: string, index: number) {
    Column() {
      Text(label)
        .fontSize(this.isElderMode() ? 18 : 15)
        .fontColor(this.currentNav === index ? $r('app.color.color_secondary') : $r('app.color.color_text_secondary'))
        .fontWeight(this.currentNav === index ? FontWeight.Bold : FontWeight.Normal)
      // 选中下划线
      Divider()
        .strokeWidth(2)
        .color($r('app.color.color_secondary'))
        .width(this.currentNav === index ? 24 : 0)
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .height(56)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.currentNav = index;
      const routes: string[] = [
        RouteName.FARMER_SELLER_MALL,
        RouteName.FARMER_LIVE_BROWSE,
        RouteName.FARMER_AGENT_PAGE,
        RouteName.FARMER_SEARCH_PAGE
      ];
      const route: string = routes[index];
      Logger.info(AppConstants.SCENE_FARMER, { action: 'top_nav_click', nav: label, route });
      NavigationHelper.push(route);
    })
  }

  /** 首页 Tab 内容 = 营收异形面板 + 横滑商品卡片 + 营收明细入口 */
  @Builder
  HomeTabContent() {
    Scroll() {
      Column({ space: 16 }) {
        // 营收异形面板（spec 3.2.3.1）
        this.RevenuePanel()

        // 横向滚动商品卡片（spec 3.2.3.1：展示该卖家全部上架商品）
        this.ProductCardSection()

        // 营收明细入口（spec 3.2.3.3）
        Button('查看营收明细')
          .width('100%')
          .height(44)
          .borderRadius(22)
          .backgroundColor($r('app.color.color_bg_card'))
          .fontColor($r('app.color.color_text_primary'))
          .fontSize(this.isElderMode() ? 18 : 14)
          .margin({ top: 8 })
          .onClick(() => {
            Logger.info(AppConstants.SCENE_FARMER, { action: 'goto_revenue_detail' });
            NavigationHelper.push(RouteName.FARMER_REVENUE_DETAIL);
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 24 })
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
  }

  /** 营收异形面板（spec 3.2.3.1） */
  @Builder
  RevenuePanel() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column({ space: 12 }) {
        // 顶部行：标题（可点击切换时间范围）+ 模式开关
        Row() {
          // 营收标题（点击切换时间范围：今日/本月/本年/累计）
          Column({ space: 4 }) {
            Row({ space: 6 }) {
              Text(this.getRevenueRangeLabel())
                .fontSize(this.isElderMode() ? 20 : 16)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Medium)
              Text('›')
                .fontSize(this.isElderMode() ? 20 : 16)
                .fontColor($r('app.color.color_text_on_dark'))
            }
            .onClick(() => {
              this.cycleRevenueRange();
            })
            Text('tap 切换时间范围')
              .fontSize(10)
              .fontColor('rgba(255,255,255,0.5)')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // 右上角圆形模式开关（spec 3.2.3.2：48vp×48vp）
          this.ModeToggle()
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)

        // 营收数据大字展示（28fp，浅绿色 #81C784）spec 3.2.3.1
        Text(this.getRevenueAmountText())
          .fontSize(this.isElderMode() ? 40 : 28)
          .fontColor($r('app.color.color_text_on_dark'))
          .fontWeight(FontWeight.Bold)
          .margin({ top: 8 })
          .onClick(() => {
            this.cycleRevenueRange();
          })

        // 辅助数据展示（订单数 / 商品数 / 转化率）spec 3.2.3.1
        Row() {
          this.RevenueSubStat('订单数', `${this.revenueData.orderCount}`)
          this.RevenueSubStat('商品数', `${this.revenueData.productCount}`)
          this.RevenueSubStat('转化率', `${this.revenueData.conversionRate}%`)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)
        .margin({ top: 16 })

        // 装饰：金色分隔线 + 卖家信息
        Row({ space: 8 }) {
          Divider()
            .strokeWidth(1)
            .color($r('app.color.color_accent_gold'))
            .layoutWeight(1)
          Text(`卖家：${this.nickname}`)
            .fontSize(this.isElderMode() ? 14 : 12)
            .fontColor('rgba(255,213,79,0.9)')
          Divider()
            .strokeWidth(1)
            .color($r('app.color.color_accent_gold'))
            .layoutWeight(1)
        }
        .width('100%')
        .margin({ top: 16 })
      }
      .width('100%')
      .padding(20)
    }
    .width('100%')
    .height(280)
    .borderRadius(24)
    .backgroundColor($r('app.color.color_bg_panel_dark'))
    .border({ width: 1, color: 'rgba(255,213,79,0.3)' })
  }

  /** 右上角圆形模式开关（spec 3.2.3.2：48vp×48vp 圆形滑动开关） */
  @Builder
  ModeToggle() {
    Row() {
      // 圆形滑动开关：48x48 圆形容器 + 内部圆点滑动
      Stack() {
        // 滑动圆点
        Row() {
          Text(this.isElderMode() ? '老' : '标')
            .fontSize(11)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
        }
        .width(32)
        .height(32)
        .borderRadius(16)
        .backgroundColor(this.isElderMode() ? $r('app.color.color_primary') : $r('app.color.color_medal_silver'))
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        // 标准模式：圆点偏左；老年模式：圆点偏右
        .offset({ x: this.isElderMode() ? 8 : -8 })
        .animation({ duration: 300, curve: Curve.EaseInOut })
      }
      .width(48)
      .height(48)
      .borderRadius(24)
      .backgroundColor(this.isElderMode() ? 'rgba(139,195,74,0.3)' : 'rgba(158,158,158,0.3)')
      .border({ width: 1.5, color: this.isElderMode() ? $r('app.color.color_primary') : $r('app.color.color_medal_silver') })
      .onClick(() => {
        this.toggleMode();
      })
    }
    .width(48)
    .height(48)
  }

  /** 营收辅助数据项 */
  @Builder
  RevenueSubStat(label: string, value: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(this.isElderMode() ? 18 : 14)
        .fontColor($r('app.color.color_text_on_dark'))
        .fontWeight(FontWeight.Medium)
      Text(label)
        .fontSize(this.isElderMode() ? 12 : 10)
        .fontColor('rgba(255,255,255,0.6)')
    }
    .alignItems(HorizontalAlign.Center)
  }

  /** 横向滚动商品卡片（spec 3.2.3.1） */
  @Builder
  ProductCardSection() {
    Column({ space: 12 }) {
      Row() {
        Text('我的商品')
          .fontSize(this.isElderMode() ? 20 : 16)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Bold)
        Blank()
        Text('编辑')
          .fontSize(this.isElderMode() ? 14 : 12)
          .fontColor($r('app.color.color_secondary'))
          .onClick(() => {
            Logger.info(AppConstants.SCENE_FARMER, { action: 'goto_product_manage' });
            NavigationHelper.push(RouteName.FARMER_PRODUCT_MANAGE);
          })
      }
      .width('100%')

      // 横向滚动商品卡片
      Scroll() {
        Row({ space: 12 }) {
          ForEach(this.productList, (product: ProductCardInfo, _index: number) => {
            this.ProductCard(product)
          }, (product: ProductCardInfo) => product.productId)
        }
        .padding({ right: 16 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('100%')
    .margin({ top: 8 })
  }

  /** 单个商品卡片（spec 3.2.3.1：商品图+名称+价格+月销量，点击跳转商品编辑页） */
  @Builder
  ProductCard(product: ProductCardInfo) {
    Column({ space: 8 }) {
      // 商品图（占位：丰收橙背景 + 🌾）
      Stack() {
        Text('🌾')
          .fontSize(36)
      }
      .width(120)
      .height(120)
      .borderRadius(12)
      .backgroundColor($r('app.color.color_secondary'))
      .alignContent(Alignment.Center)

      // 商品名称
      Text(product.name)
        .fontSize(this.isElderMode() ? 16 : 13)
        .fontColor($r('app.color.color_text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width(120)

      // 价格
      Text(`¥${product.price.toFixed(2)}`)
        .fontSize(this.isElderMode() ? 16 : 14)
        .fontColor($r('app.color.color_price'))
        .fontWeight(FontWeight.Bold)

      // 月销量
      Text(`月销 ${product.monthlySales}`)
        .fontSize(this.isElderMode() ? 12 : 10)
        .fontColor($r('app.color.color_text_hint'))
    }
    .width(120)
    .padding(8)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
    .onClick(() => {
      Logger.info(AppConstants.SCENE_FARMER, { action: 'product_card_click', productId: product.productId });
      const param: ProductEditParam = { productId: product.productId };
      NavigationHelper.push(RouteName.FARMER_PRODUCT_EDIT, param);
    })
  }

  /** 占位 Tab 内容 */
  @Builder
  PlaceholderTabContent(name: string) {
    Column({ space: 12 }) {
      Text(`${name} Tab`)
        .fontSize(this.isElderMode() ? 22 : 20)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Bold)
      Text('该模块将在后续阶段实现')
        .fontSize(this.isElderMode() ? 16 : 14)
        .fontColor($r('app.color.color_text_secondary'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.color_bg_page'))
  }

  /** 底部 5 Tab 导航（spec 3.2.4） */
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
    .height(56)
    .backgroundColor($r('app.color.color_bg_card'))
    .border({ width: { top: 1 }, color: $r('app.color.color_divider') })
  }

  /** 底部 Tab 项 */
  @Builder
  BottomTabItem(label: string, icon: string, index: number) {
    Column({ space: 4 }) {
      Text(icon)
        .fontSize(this.isElderMode() ? 24 : 20)
      Text(label)
        .fontSize(this.isElderMode() ? 12 : 10)
        .fontColor(this.currentTab === index ? $r('app.color.color_secondary') : $r('app.color.color_text_secondary'))
        .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Normal)
    }
    .layoutWeight(1)
    .height(56)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.currentTab = index;
      Logger.info(AppConstants.SCENE_FARMER, { action: 'tab_switch', tab: label });
      // 首页 Tab 留在当前页，其余 Tab 跳转对应页面 spec 3.2.4
      if (index === 1) {
        // 社区 Tab → 帖子列表 spec 3.2.4.2
        NavigationHelper.push(RouteName.FARMER_COMMUNITY_LIST);
      } else if (index === 2) {
        // 直播 Tab = 一键开播入口 spec 3.2.4.3
        NavigationHelper.push(RouteName.FARMER_LIVE_CREATE);
      } else if (index === 3) {
        // 消息 Tab → 会话列表 spec 3.2.4.4
        NavigationHelper.push(RouteName.FARMER_MESSAGE_LIST);
      } else if (index === 4) {
        // 个人中心 Tab → 卖家个人中心 spec 3.2.4.5
        NavigationHelper.push(RouteName.FARMER_SELLER_PROFILE);
      }
    })
  }
}
