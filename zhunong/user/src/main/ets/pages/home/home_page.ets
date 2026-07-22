/**
 * home_page - 用户端首页（5 Tab + 首页推荐流）
 * 遵循 spec 3.1.1.1 / 3.1.3 / 3.1.3.1 / 2.4.6.6 / 10.2：
 *  - 顶部全局搜索导航栏（56vp，点击跳转搜索页）
 *  - 5 Tab：首页 / 社区 / 消息 / 购物车 / 个人
 *  - 首页 Tab = Banner 轮播 + 5 快捷入口 + 双列瀑布流推荐流
 *  - 下拉刷新（Refresh）+ 上拉加载更多（触底 100vp 触发）
 *  - 购物车/个人中心 Tab 嵌入 CartContent/ProfileContent 组件
 */

import { TokenStore, Logger, AppConstants, UserRoutes, RouteName, NavigationHelper, RouterParam } from 'common';
import { ProductListItem } from '../../model/ProductModels';
import { HomeRecommendDataSource } from '../../viewmodel/HomeRecommendDataSource';
import { ProductCard } from '../../components/ProductCard';
import { CartContent } from '../cart/cart_page';
import { ProfileContent } from '../profile/profile_page';
import { CommunityContent } from '../community/community_list';
import { MessageContent } from '../message/message_list';
import { BannerItem, BannerLinkType, BannerTheme } from '../../mock/BannerMock';
import { HomeRepository } from '../../repository/HomeRepository';

/** 跳转商品详情的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface ProductDetailParam {
  productId: string;
}

/** 跳转分类商品列表的路由参数 */
interface CategoryListParam {
  categoryId: string;
}

/** 首页快捷入口项 */
interface QuickEntry {
  /** 入口标签 */
  label: string;
  /** 入口图标（emoji） */
  icon: string;
  /** 入口键（fresh/grain/live/travel/community） */
  entryKey: string;
}

@ComponentV2
export struct HomePage {
  /** 当前底部 Tab 索引 */
  @Local currentTab: number = 0;
  /** 用户昵称 */
  @Local nickname: string = '助农用户';
  /** 首页推荐流数据源 */
  private recommendDataSource: HomeRecommendDataSource = new HomeRecommendDataSource();
  /** 是否正在下拉刷新 */
  @Local isRefreshing: boolean = false;
  /** 首页 Banner 列表（spec 2.4.6.6 / 10.2） */
  @Local banners: BannerItem[] = [];
  /** 5 快捷入口（spec 10.2） */
  @Local quickEntries: QuickEntry[] = [];

  async aboutToAppear(): Promise<void> {
    const userInfo = await TokenStore.getUserInfo();
    if (userInfo) {
      this.nickname = userInfo.nickname;
    }
    // Banner 走 Repository（spec 10.3：先 REST 后 Mock 兜底）
    this.banners = await HomeRepository.getBanners();
    this.quickEntries = this.buildQuickEntries();
    Logger.info(AppConstants.SCENE_USER, { action: 'home_page_appear', index: this.banners.length });
  }

  /** 构建 5 快捷入口数据（spec 10.2） */
  private buildQuickEntries(): QuickEntry[] {
    const entries: QuickEntry[] = [
      { label: '生鲜', icon: '🥬', entryKey: 'fresh' },
      { label: '粮油', icon: '🌾', entryKey: 'grain' },
      { label: '直播', icon: '📺', entryKey: 'live' },
      { label: '文旅', icon: '🗺️', entryKey: 'travel' },
      { label: '社区', icon: '💬', entryKey: 'community' }
    ];
    return entries;
  }

  /** Banner 主题色 → 资源色值（禁止硬编码色值，spec 1.2.5 / 2.3.2） */
  private getBannerBgColor(theme: BannerTheme): ResourceColor {
    switch (theme) {
      case 'green':
        return $r('app.color.color_primary');
      case 'orange':
        return $r('app.color.color_secondary');
      case 'gold':
        return $r('app.color.color_accent_gold');
      case 'red':
        return $r('app.color.color_price');
      case 'lightgreen':
        return $r('app.color.color_primary_light');
      default:
        return $r('app.color.color_primary');
    }
  }

  /** 跳转搜索页 */
  private gotoSearch(): void {
    NavigationHelper.push(RouteName.USER_SEARCH_PAGE);
  }

  /** 跳转消息中心（切换到消息 Tab） */
  private gotoMessage(): void {
    this.currentTab = 2;
    Logger.info(AppConstants.SCENE_USER, { action: 'goto_message_tab' });
  }

  /** 点击商品卡片 → 跳转商品详情 */
  private gotoProductDetail(productId: string): void {
    const param: ProductDetailParam = { productId: productId };
    NavigationHelper.push(RouteName.USER_PRODUCT_DETAIL, param);
  }

  /** 快捷入口点击 → 路由跳转（spec 10.2 跳转表） */
  private onQuickEntryClick(entryKey: string): void {
    switch (entryKey) {
      case 'fresh': {
        const param: CategoryListParam = { categoryId: 'fresh' };
        NavigationHelper.push(RouteName.USER_CATEGORY_LIST, param);
        break;
      }
      case 'grain': {
        const param: CategoryListParam = { categoryId: 'grain' };
        NavigationHelper.push(RouteName.USER_CATEGORY_LIST, param);
        break;
      }
      case 'live':
        NavigationHelper.push(RouteName.USER_LIVE_LIST);
        break;
      case 'travel':
        NavigationHelper.push(RouteName.USER_TRAVEL_MAP);
        break;
      case 'community':
        // 切换到社区 Tab（currentTab=1）
        this.currentTab = 1;
        break;
      default:
        break;
    }
    Logger.info(AppConstants.SCENE_USER, { action: 'quick_entry_click', type: entryKey });
  }

  /**
   * Banner 点击 → 跳转（spec 10.2，Phase 6 接入真实活动/榜单路由）
   * 10.9.2：迁移到 Navigation 声明式路由
   *  - 按 linkType 映射到 RouteName（替代解析 linkUrl 路径）
   *  - 仍从 linkUrl 提取 query 参数（如 categoryId=fresh），传入 NavigationHelper.push
   *  - rank 类型目标页 search_result 暂未在 root_page 注册，fallback 到 search_page（spec 3.1.3.3）
   */
  private onBannerClick(banner: BannerItem): void {
    if (banner.linkType === 'none' || banner.linkUrl.length === 0) {
      return;
    }

    let routeName: string = '';
    const params: RouterParam = {} as RouterParam;

    switch (banner.linkType) {
      case 'category': {
        routeName = RouteName.USER_CATEGORY_LIST;
        const categoryId: string | undefined = this.extractQueryParam(banner.linkUrl, 'categoryId');
        if (categoryId !== undefined) {
          params.categoryId = categoryId;
        }
        break;
      }
      case 'live':
        routeName = RouteName.USER_LIVE_LIST;
        break;
      case 'travel':
        routeName = RouteName.USER_TRAVEL_MAP;
        break;
      case 'rank':
        // rank 类型目标页 search_result 暂未注册，fallback 到 search_page（spec 3.1.3.3）
        routeName = RouteName.USER_SEARCH_PAGE;
        break;
      default:
        Logger.warn(AppConstants.SCENE_USER, { action: 'banner_click_unknown_type', linkType: banner.linkType });
        return;
    }

    NavigationHelper.push(routeName, params);
    Logger.info(AppConstants.SCENE_USER, { action: 'banner_click', type: banner.linkType, routeName: routeName });
  }

  /** 从 URL 中提取指定 query 参数值（如 `pages/x/y?categoryId=fresh` → `fresh`） */
  private extractQueryParam(url: string, key: string): string | undefined {
    const queryIndex: number = url.indexOf('?');
    if (queryIndex < 0) {
      return undefined;
    }
    const query: string = url.substring(queryIndex + 1);
    if (query.length === 0) {
      return undefined;
    }
    const pairs: string[] = query.split('&');
    for (const pair of pairs) {
      const kv: string[] = pair.split('=');
      if (kv.length === 2 && kv[0] === key) {
        return decodeURIComponent(kv[1]);
      }
    }
    return undefined;
  }

  /** 下拉刷新 */
  private async onRefresh(): Promise<void> {
    this.isRefreshing = true;
    await this.recommendDataSource.refresh();
    this.isRefreshing = false;
  }

  /** 触底加载更多 */
  private async onLoadMore(): Promise<void> {
    await this.recommendDataSource.loadMore();
  }

  build() {
    NavDestination() {
      Column() {
        Tabs({ barPosition: BarPosition.End, index: this.currentTab }) {
          // Tab 0：首页推荐流
          TabContent() {
            this.HomeTabContent()
          }
          .tabBar(this.TabBarItem('首页', '🏠', 0))

          // Tab 1：社区（spec 3.1.3.2）
          TabContent() {
            CommunityContent()
          }
          .tabBar(this.TabBarItem('社区', '💬', 1))

          // Tab 2：消息（spec 3.1.3.3）
          TabContent() {
            MessageContent()
          }
          .tabBar(this.TabBarItem('消息', '✉️', 2))

          // Tab 3：购物车（spec 3.1.3.4）
          TabContent() {
            CartContent()
          }
          .tabBar(this.TabBarItem('购物车', '🛒', 3))

          // Tab 4：个人中心（spec 3.1.3.5）
          TabContent() {
            ProfileContent()
          }
          .tabBar(this.TabBarItem('我的', '👤', 4))
        }
        .onChange((index: number) => {
          this.currentTab = index;
          Logger.info(AppConstants.SCENE_USER, { action: 'tab_switch', tab: `${index}` });
        })
        .barHeight(56)
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 首页 Tab 内容：顶部搜索栏 + Banner 轮播 + 5 快捷入口 + 双列瀑布流推荐流 */
  @Builder
  HomeTabContent() {
    Column() {
      // 顶部全局搜索导航栏（spec 3.1.1.1）
      this.TopSearchBar()

      // Banner 轮播区（spec 2.4.6.6 / 10.2：160vp 高度，12vp 圆角，4s 自动轮播，上方独立区域）
      this.BannerSection()

      // 5 快捷入口区（spec 10.2：圆形图标，生机绿，横向均分，上方独立区域）
      this.QuickEntries()

      // 推荐流（Refresh + WaterFlow + LazyForEach），Banner+入口区不破坏下拉刷新/上拉加载
      Refresh({ refreshing: $$this.isRefreshing }) {
        WaterFlow() {
          LazyForEach(this.recommendDataSource, (item: ProductListItem, index: number) => {
            FlowItem() {
              ProductCard({
                item: item,
                onCardClick: (pid: string) => {
                  this.gotoProductDetail(pid);
                }
              })
            }
            .margin({ bottom: 8 })
          }, (item: ProductListItem) => item.productId + `_${item.title.length}_${this.recommendDataSource.totalCount()}`)
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(8)
        .rowsGap(8)
        .padding({ left: 12, right: 12, top: 8, bottom: 12 })
        .cachedCount(AppConstants.LIST_CACHED_COUNT)
        .onReachStart(() => {
          // 首次进入触发加载
          if (this.recommendDataSource.getIsFirstLoad()) {
            this.recommendDataSource.refresh();
          }
        })
        .onReachEnd(() => {
          // 触底加载更多（spec 3.1.3.1：触底 100vp 触发）
          this.onLoadMore();
        })
      }
      .onRefreshing(() => {
        // 下拉刷新触发
        this.onRefresh();
      })
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }

  /** Banner 轮播区（spec 2.4.6.6 / 10.2） */
  @Builder
  BannerSection() {
    if (this.banners.length > 0) {
      Swiper() {
        ForEach(this.banners, (banner: BannerItem, index: number) => {
          Stack({ alignContent: Alignment.Start }) {
            // 角标标签
            Text(banner.tag)
              .fontSize(10)
              .fontColor($r('app.color.color_bg_card'))
              .backgroundColor($r('app.color.color_secondary'))
              .borderRadius(8)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .position({ x: 12, y: 12 })
            // 主标题 + 副标题
            Column({ space: 6 }) {
              Text(banner.title)
                .fontSize(20)
                .fontColor($r('app.color.color_bg_card'))
                .fontWeight(FontWeight.Bold)
              Text(banner.subtitle)
                .fontSize(12)
                .fontColor($r('app.color.color_bg_card'))
                .opacity(0.9)
            }
            .alignItems(HorizontalAlign.Start)
            .padding({ left: 16, right: 16, top: 36, bottom: 16 })
          }
          .width('100%')
          .height(160)
          .borderRadius(12)
          .backgroundColor(this.getBannerBgColor(banner.theme))
          .padding({ left: 4, right: 4 })
          .onClick(() => {
            this.onBannerClick(banner);
          })
        }, (banner: BannerItem) => banner.bannerId)
      }
      .autoPlay(true)
      .interval(4000)
      .loop(true)
      .duration(500)
      .indicator(true)
      .padding({ left: 12, right: 12, top: 8 })
    }
  }

  /** 5 快捷入口区（spec 10.2：圆形图标，生机绿，横向均分） */
  @Builder
  QuickEntries() {
    Row() {
      ForEach(this.quickEntries, (entry: QuickEntry, index: number) => {
        Column({ space: 6 }) {
          // 圆形图标
          Stack({ alignContent: Alignment.Center }) {
            Text(entry.icon)
              .fontSize(26)
          }
          .width(48)
          .height(48)
          .borderRadius(24)
          .backgroundColor($r('app.color.color_primary_light'))
          // 标签
          Text(entry.label)
            .fontSize(11)
            .fontColor($r('app.color.color_text_primary'))
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.onQuickEntryClick(entry.entryKey);
        })
      }, (entry: QuickEntry) => entry.entryKey)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 12, bottom: 8 })
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 顶部全局搜索导航栏（spec 3.1.1.1） */
  @Builder
  TopSearchBar() {
    Row({ space: 12 }) {
      // APP Logo
      Text('🌾')
        .fontSize(24)

      // 搜索框入口（点击跳转搜索页，非直接输入）
      Row() {
        Text('搜索农产品/直播/帖子/农户')
          .fontSize(13)
          .fontColor($r('app.color.color_text_hint'))
        Blank()
        Text('🔍')
          .fontSize(18)
      }
      .layoutWeight(1)
      .height(36)
      .borderRadius(18)
      .backgroundColor($r('app.color.color_bg_page'))
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.gotoSearch();
      })

      // 消息快捷入口
      Text('✉️')
        .fontSize(22)
        .onClick(() => {
          this.gotoMessage();
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** Tab 项（图标 + 文字） */
  @Builder
  TabBarItem(label: string, icon: string, index: number) {
    Column({ space: 4 }) {
      Text(icon)
        .fontSize(20)
      Text(label)
        .fontSize(10)
        .fontColor(this.currentTab === index ? $r('app.color.color_primary') : $r('app.color.color_text_secondary'))
    }
    .width('100%')
    .height(56)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
