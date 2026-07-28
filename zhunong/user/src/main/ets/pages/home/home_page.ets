/**
 * home_page - 用户端首页（5 Tab + 首页推荐流）
 * 对齐设计稿 pages/user-home.html（spec 15.5 第 65 页对照表）：
 *  - 顶部栏：智农品牌字 + 胶囊搜索栏（白底阴影）+ 购物车图标按钮（红点徽标）
 *  - 黄色英雄横幅：渐变卡 + 产地直达 eyebrow + 标题/副标题 + 立即逛逛 CTA + 吉祥物 + 自定义圆点指示器
 *  - 快捷入口九宫格：白卡内 4 列（分类/直播/智农/旅游），彩色圆形图标
 *  - 直播横滑区：LIVE pill + 正在直播 + 横向卡片（封面 + LIVE 徽标 + 观看人数 + 标题 + 主播）
 *  - 商品瀑布流：为你推荐 + 双列 ProductCard
 *  - 底部 5 Tab：首页/社区/消息(红点)/购物车/我的
 * spec 3.1.1.1 / 3.1.3 / 3.1.3.1 / 2.4.6.6 / 10.2
 * 保留层：HomeRepository / HomeRecommendDataSource / LiveRepository / NavigationHelper 调用链不变
 * 架构：Refresh > List(lanes=1) — 首个 ListItem 承载全部头部内容（随列表滚动），后续 ListItem 为商品对行
 */

import { TokenStore, Logger, AppConstants, UserRoutes, RouteName, NavigationHelper, RouterParam, LiveStatus } from 'common';
import { ProductListItem } from '../../model/ProductModels';
import { HomeRecommendDataSource } from '../../viewmodel/HomeRecommendDataSource';
import { ProductCard } from '../../components/ProductCard';
import { CartContent } from '../cart/cart_page';
import { ProfileContent } from '../profile/profile_page';
import { CommunityContent } from '../community/community_list';
import { MessageContent } from '../message/message_list';
import { BannerItem, BannerLinkType, BannerTheme } from '../../mock/BannerMock';
import { HomeRepository } from '../../repository/HomeRepository';
import { LiveRepository } from '../../repository/LiveRepository';
import { LiveListItem, LiveListParam } from '../../model/LiveModels';
import { getMockCartCount } from '../../mock/CartMock';
import { ImageUtil } from '../../utils/ImageUtil';
import { ReplaceableImage } from '../../components/ReplaceableImage';

/** 跳转商品详情的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface ProductDetailParam {
  productId: string;
}

/** 跳转直播间路由参数 */
interface LiveRoomParam {
  liveId: string;
}

/** 首页快捷入口项（对齐设计稿 .qn-cat-grid 4 列） */
interface QuickEntry {
  /** 入口标签 */
  label: string;
  /** 入口图标（emoji） */
  icon: string;
  /** 入口键 */
  entryKey: string;
  /** 图标圆背景色键 */
  colorKey: QuickEntryColor;
}

/** 快捷入口图标背景色键（对齐 .qn-cat-ico.c-green/c-yellow/c-orange/c-red/c-blue） */
type QuickEntryColor = 'green' | 'yellow' | 'red' | 'blue';

/** 商品对（双列布局用，每行 2 张商品卡） */
interface ProductPair {
  /** 左列商品 */
  left: ProductListItem;
  /** 右列商品（奇数条末位为 null） */
  right: ProductListItem | null;
}

@ComponentV2
export struct HomePage {
  /** 当前底部 Tab 索引 */
  @Local currentTab: number = 0;
  /** 用户昵称 */
  @Local nickname: string = '智农用户';
  /** 首页推荐流数据源（保留层：取数走 HomeRepository） */
  private recommendDataSource: HomeRecommendDataSource = new HomeRecommendDataSource();
  /** 是否正在下拉刷新 */
  @Local isRefreshing: boolean = false;
  /** 首页 Banner 列表（spec 2.4.6.6 / 10.2） */
  @Local banners: BannerItem[] = [];
  /** 当前 Banner 索引（自定义圆点指示器用） */
  @Local currentBannerIndex: number = 0;
  /** 4 快捷入口（对齐设计稿：分类/直播/智农/旅游） */
  @Local quickEntries: QuickEntry[] = [];
  /** 正在直播列表（横滑区，最多 6 条） */
  @Local liveList: LiveListItem[] = [];
  /** 购物车商品数量（徽标） */
  @Local cartCount: number = 0;
  /** 商品列表（从 DataSource 拷贝，用于 ForEach 渲染） */
  @Local productList: ProductListItem[] = [];
  /** 商品对列表（双列行渲染用） */
  @Local productPairs: ProductPair[] = [];
  /** 是否首次加载中 */
  @Local isLoadingFirst: boolean = true;

  async aboutToAppear(): Promise<void> {
    const userInfo = await TokenStore.getUserInfo();
    if (userInfo) {
      this.nickname = userInfo.nickname;
    }
    // Banner 走 Repository（spec 10.3：先 REST 后 Mock 兜底）
    this.banners = await HomeRepository.getBanners();
    // 直播列表：仅取 living 状态前 6 条
    const liveParam: LiveListParam = { status: 'living', page: 1, size: 6 };
    const liveResult = await LiveRepository.getLiveList(liveParam);
    this.liveList = liveResult.list;
    // 购物车数量
    this.cartCount = getMockCartCount();
    this.quickEntries = this.buildQuickEntries();
    // 首次加载推荐流
    await this.loadInitialProducts();
    Logger.info(AppConstants.SCENE_USER, {
      action: 'home_page_appear',
      count: this.banners.length
    });
  }

  /** 首次加载推荐流商品 */
  private async loadInitialProducts(): Promise<void> {
    this.isLoadingFirst = true;
    await this.recommendDataSource.refresh();
    this.rebuildProductPairs();
    this.isLoadingFirst = false;
  }

  /** 从 DataSource 拷贝数据并构建商品对（双列行用） */
  private rebuildProductPairs(): void {
    const list: ProductListItem[] = [];
    const total: number = this.recommendDataSource.totalCount();
    for (let i = 0; i < total; i++) {
      list.push(this.recommendDataSource.getData(i));
    }
    this.productList = list;

    const pairs: ProductPair[] = [];
    for (let i = 0; i < this.productList.length; i += 2) {
      const left: ProductListItem = this.productList[i];
      const right: ProductListItem | null = i + 1 < this.productList.length ? this.productList[i + 1] : null;
      const pair: ProductPair = { left: left, right: right };
      pairs.push(pair);
    }
    this.productPairs = pairs;
  }

  /** 构建 4 快捷入口数据（对齐设计稿 .qn-cat-grid；spec 16.12：智农改为商城） */
  private buildQuickEntries(): QuickEntry[] {
    const entries: QuickEntry[] = [
      { label: '分类', icon: '📦', entryKey: 'category', colorKey: 'green' },
      { label: '直播', icon: '🎥', entryKey: 'live', colorKey: 'red' },
      { label: '商城', icon: '🏪', entryKey: 'mall', colorKey: 'yellow' },
      { label: '旅游', icon: '🗺️', entryKey: 'travel', colorKey: 'blue' }
    ];
    return entries;
  }

  /** spec 16.12：快捷入口图标背景色 → 对齐个人中心"更多功能"按钮色系（替换莫兰迪色） */
  private getQuickEntryBgColor(colorKey: QuickEntryColor): ResourceColor {
    switch (colorKey) {
      case 'green':
        return $r('app.color.color_green_soft'); // 绿色软底
      case 'yellow':
        return $r('app.color.color_yellow_soft'); // 黄色软底
      case 'red':
        return $r('app.color.color_live_soft'); // 红色软底
      case 'blue':
        return $r('app.color.color_info_soft'); // 蓝色软底
      default:
        return $r('app.color.color_green_soft');
    }
  }

  /** 格式化观看人数（>=10000 显示万，对齐设计稿 1.2万 / 8560） */
  private formatViewers(count: number): string {
    if (count >= 10000) {
      return `${(count / 10000).toFixed(1)}万`;
    }
    return `${count}`;
  }

  /** 跳转搜索页 */
  private gotoSearch(): void {
    NavigationHelper.push(RouteName.USER_SEARCH_PAGE);
  }

  /** 跳转购物车 Tab */
  private gotoCart(): void {
    this.currentTab = 3;
    Logger.info(AppConstants.SCENE_USER, { action: 'goto_cart_tab' });
  }

  /** 跳转消息中心 Tab */
  private gotoMessage(): void {
    this.currentTab = 2;
    Logger.info(AppConstants.SCENE_USER, { action: 'goto_message_tab' });
  }

  /** 点击商品卡片 → 跳转商品详情 */
  private gotoProductDetail(productId: string): void {
    const param: ProductDetailParam = { productId: productId };
    NavigationHelper.push(RouteName.USER_PRODUCT_DETAIL, param);
  }

  /** 点击直播卡 → 跳转直播间 */
  private gotoLiveRoom(liveId: string): void {
    const param: LiveRoomParam = { liveId: liveId };
    NavigationHelper.push(RouteName.USER_LIVE_ROOM, param);
  }

  /** 快捷入口点击 → 路由跳转（对齐设计稿 4 入口；spec 16.12：智农改为商城，跳商品列表实时同步农户端商品） */
  private onQuickEntryClick(entryKey: string): void {
    switch (entryKey) {
      case 'category':
        NavigationHelper.push(RouteName.USER_CATEGORY_LIST);
        break;
      case 'live':
        NavigationHelper.push(RouteName.USER_LIVE_LIST);
        break;
      case 'mall':
        // spec 16.12：商城入口跳商品列表（不传 categoryId 显示全部，含 SharedProductStore 农户发布商品）
        NavigationHelper.push(RouteName.USER_PRODUCT_LIST);
        break;
      case 'travel':
        NavigationHelper.push(RouteName.USER_TRAVEL_MAP);
        break;
      default:
        break;
    }
    Logger.info(AppConstants.SCENE_USER, { action: 'quick_entry_click', type: entryKey });
  }

  /**
   * Banner 点击 → 跳转（spec 10.2，10.9.2 声明式路由）
   * 按 linkType 映射到 RouteName，从 linkUrl 提取 query 参数
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
        routeName = RouteName.USER_SEARCH_PAGE;
        break;
      default:
        Logger.warn(AppConstants.SCENE_USER, { action: 'banner_click_unknown_type', linkType: banner.linkType });
        return;
    }
    NavigationHelper.push(routeName, params);
    Logger.info(AppConstants.SCENE_USER, { action: 'banner_click', type: banner.linkType, routeName: routeName });
  }

  /** 从 URL 中提取指定 query 参数值 */
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
    this.rebuildProductPairs();
    // 同步刷新 Banner + 直播 + 购物车数量
    this.banners = await HomeRepository.getBanners();
    const liveParam: LiveListParam = { status: 'living', page: 1, size: 6 };
    const liveResult = await LiveRepository.getLiveList(liveParam);
    this.liveList = liveResult.list;
    this.cartCount = getMockCartCount();
    this.isRefreshing = false;
  }

  /** 触底加载更多 */
  private async onLoadMore(): Promise<void> {
    await this.recommendDataSource.loadMore();
    this.rebuildProductPairs();
  }

  build() {
    NavDestination() {
      Column() {
        Tabs({ barPosition: BarPosition.End, index: this.currentTab }) {
          // Tab 0：首页推荐流
          TabContent() {
            this.HomeTabContent()
          }
          .tabBar(this.TabBarItem('首页', '🏠', 0, false))

          // Tab 1：社区（spec 3.1.3.2）
          TabContent() {
            CommunityContent()
          }
          .tabBar(this.TabBarItem('社区', '💬', 1, false))

          // Tab 2：消息（spec 3.1.3.3，红点提示）
          TabContent() {
            MessageContent()
          }
          .tabBar(this.TabBarItem('消息', '✉️', 2, true))

          // Tab 3：购物车（spec 3.1.3.4）
          TabContent() {
            CartContent()
          }
          .tabBar(this.TabBarItem('购物车', '🛒', 3, false))

          // Tab 4：个人中心（spec 3.1.3.5）
          TabContent() {
            ProfileContent()
          }
          .tabBar(this.TabBarItem('我的', '👤', 4, false))
        }
        .onChange((index: number) => {
          this.currentTab = index;
          Logger.info(AppConstants.SCENE_USER, { action: 'tab_switch', tab: `${index}` });
        })
        .barHeight(64)
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_cream'))
    }
    .hideTitleBar(true)
    .onShown(() => {
      // 页面显示时刷新推荐流（实时同步农户端发布的商品）
      this.refreshRecommendIfNeeded();
    })
  }

  /** 页面重新显示时刷新推荐流数据（实时同步共享商品池） */
  private async refreshRecommendIfNeeded(): Promise<void> {
    await this.recommendDataSource.refresh();
    this.rebuildProductPairs();
  }

  /** 首页 Tab 内容：固定顶栏 + 可滚动区（List 单列：首个 ListItem 承载头部，后续为商品对行） */
  @Builder
  HomeTabContent() {
    Column() {
      // 固定顶栏：智农品牌 + 胶囊搜索 + 购物车
      this.TopBar()

      // 可滚动内容区（Refresh 包裹 List，首个 ListItem 承载头部内容，随列表滚动）
      Refresh({ refreshing: $$this.isRefreshing }) {
        List() {
          // 头部 ListItem：英雄横幅 + 九宫格 + 直播横滑 + 商品段头（随列表滚动）
          ListItem() {
            Column() {
              this.HeroBanner()
              this.QuickEntries()
              this.LiveSection()
              this.ProductSectionHead()

              // 首次加载提示
              if (this.isLoadingFirst) {
                Row({ space: 8 }) {
                  LoadingProgress()
                    .width(24)
                    .height(24)
                    .color($r('app.color.color_yellow_deep'))
                  Text('加载推荐好物...')
                    .fontSize(13)
                    .fontColor($r('app.color.color_text_3'))
                }
                .width('100%')
                .height(120)
                .justifyContent(FlexAlign.Center)
              }
            }
            .width('100%')
          }

          // 商品对行（双列 ProductCard；spec 16.12：对齐农户端商城排版 columnsGap/rowsGap=10）
          ForEach(this.productPairs, (pair: ProductPair, index: number) => {
            ListItem() {
              Row({ space: 10 }) {
                ProductCard({
                  item: pair.left,
                  onCardClick: (pid: string) => {
                    this.gotoProductDetail(pid);
                  }
                })
                if (pair.right !== null) {
                  ProductCard({
                    item: pair.right,
                    onCardClick: (pid: string) => {
                      this.gotoProductDetail(pid);
                    }
                  })
                } else {
                  // 奇数条末位占位（保持左列卡片正常宽度）
                  Column()
                    .layoutWeight(1)
                }
              }
              .width('100%')
              .padding({ left: 12, right: 12 })
              .margin({ bottom: 10 })
            }
          }, (pair: ProductPair) => pair.left.productId)
        }
        .scrollBar(BarState.Off)
        .cachedCount(AppConstants.LIST_CACHED_COUNT)
        .padding({ bottom: 16 })
        .onReachEnd(() => {
          this.onLoadMore();
        })
      }
      .onRefreshing(() => {
        this.onRefresh();
      })
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }

  /** 顶部栏：智农品牌字 + 胶囊搜索栏 + 购物车图标按钮（对齐 .qn-home-top） */
  @Builder
  TopBar() {
    Row({ space: 10 }) {
      // 品牌字（对齐 .qn-brand：18px / 800 / letter-spacing .5）
      Text('智农')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.color_ink'))

      // 胶囊搜索栏（对齐 .qn-search：白底 + 阴影 + 🔍 + 占位文字）
      Row({ space: 8 }) {
        Text('🔍')
          .fontSize(14)
        Text('搜索智农好物')
          .fontSize(13)
          .fontColor($r('app.color.color_text_3'))
        Blank()
      }
      .layoutWeight(1)
      .height(40)
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor($r('app.color.color_bg_card'))
      .shadow(AppConstants.SHADOW_CARD)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.gotoSearch();
      })

      // 购物车图标按钮（对齐 .qn-icon-btn + .qn-badge）
      Stack({ alignContent: Alignment.TopEnd }) {
        Stack({ alignContent: Alignment.Center }) {
          Text('🛒')
            .fontSize(16)
        }
        .width(32)
        .height(32)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor($r('app.color.color_bg_card'))
        .shadow(AppConstants.SHADOW_CARD)

        // 红色数量徽标（对齐 .qn-badge：右上角溢出红点）
        if (this.cartCount > 0) {
          Text(this.cartCount > 99 ? '99+' : `${this.cartCount}`)
            .fontSize(10)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .backgroundColor($r('app.color.color_live'))
            .borderRadius(AppConstants.RADIUS_PILL)
            .border({ width: 1.5, color: $r('app.color.color_bg_card') })
            .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            .offset({ x: 6, y: -6 })
        }
      }
      .width(32)
      .height(32)
      .clip(false)
      .onClick(() => {
        this.gotoCart();
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 10 })
    .alignItems(VerticalAlign.Center)
  }

  /** 黄色英雄横幅（对齐 .qn-hero：渐变卡 + eyebrow + 标题 + CTA + 吉祥物 + 圆点指示器） */
  @Builder
  HeroBanner() {
    if (this.banners.length > 0) {
      // Swiper 外层 Stack 用于叠加自定义圆点指示器
      Stack({ alignContent: Alignment.BottomStart }) {
        Swiper() {
          ForEach(this.banners, (banner: BannerItem, index: number) => {
            Stack({ alignContent: Alignment.Start }) {
              // 装饰圆（近似 .qn-hero::before 径向渐变）
              Stack()
                .width(130)
                .height(130)
                .borderRadius(65)
                .backgroundColor('rgba(255,255,255,0.25)')
                .position({ x: '62%', y: -34 })

              // 主内容（左文 + 右吉祥物）
              Row({ space: 6 }) {
                // 左侧文案
                Column({ space: 6 }) {
                  // eyebrow 标签（对齐 .qn-hero-eyebrow：黑底黄字）
                  Text(banner.tag)
                    .fontSize(10)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.color_yellow'))
                    .backgroundColor($r('app.color.color_ink'))
                    .borderRadius(AppConstants.RADIUS_PILL)
                    .padding({ left: 9, right: 9, top: 3, bottom: 3 })

                  // 主标题（对齐 h2：18px / 800）
                  Text(banner.title)
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.color_ink'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  // 副标题（对齐 .qn-hero-sub：12px / 600）
                  Text(banner.subtitle)
                    .fontSize(12)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.color_ink_2'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  // CTA 按钮（对齐 .qn-hero-cta：黑底白字 + 箭头）
                  Row({ space: 4 }) {
                    Text('立即逛逛')
                      .fontSize(12)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(Color.White)
                    Text('→')
                      .fontSize(13)
                      .fontColor(Color.White)
                  }
                  .height(30)
                  .borderRadius(AppConstants.RADIUS_PILL)
                  .backgroundColor($r('app.color.color_ink'))
                  .padding({ left: 14, right: 14 })
                  .alignItems(VerticalAlign.Center)
                  .margin({ top: 6 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                // 品牌头像（对齐 .qn-hero-mascot：96 圆形 + 白边）
                Image($r('app.media.avatar_brand'))
                  .width(96)
                  .height(96)
                  .borderRadius(48)
                  .objectFit(ImageFit.Cover)
                  .border({ width: 3, color: 'rgba(255,255,255,0.7)' })
                  .shadow({ radius: 16, color: 'rgba(0,0,0,0.12)', offsetX: 0, offsetY: 6 })
              }
              .width('100%')
              .padding(20)
              .alignItems(VerticalAlign.Center)
            }
            .width('100%')
            .height(152)
            .borderRadius(AppConstants.RADIUS_LG)
            .linearGradient({
              angle: 135,
              colors: [[$r('app.color.color_yellow'), 0.0], [$r('app.color.color_yellow_deep'), 1.0]]
            })
            .shadow(AppConstants.SHADOW_YELLOW)
            .onClick(() => {
              this.onBannerClick(banner);
            })
          }, (banner: BannerItem) => banner.bannerId)
        }
        .autoPlay(true)
        .interval(4000)
        .loop(true)
        .duration(500)
        .indicator(false)
        .onChange((index: number) => {
          this.currentBannerIndex = index;
        })

        // 自定义圆点指示器（对齐 .qn-hero-dots：左下，active 加宽黑色）
        Row({ space: 4 }) {
          ForEach(this.banners, (banner: BannerItem, index: number) => {
            Column()
              .width(index === this.currentBannerIndex ? 16 : 6)
              .height(6)
              .borderRadius(3)
              .backgroundColor(index === this.currentBannerIndex
                ? $r('app.color.color_ink')
                : 'rgba(26,26,26,0.22)')
          }, (banner: BannerItem) => banner.bannerId)
        }
        .padding({ left: 20, bottom: 10 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8 })
    }
  }

  /** 快捷入口九宫格（对齐 .qn-cat-grid：白卡内 4 列圆形彩色图标） */
  @Builder
  QuickEntries() {
    Column() {
      Row() {
        ForEach(this.quickEntries, (entry: QuickEntry, index: number) => {
          Column({ space: 8 }) {
            // 圆形彩色图标（对齐 .qn-cat-ico：48 圆 + 阴影）
            Stack({ alignContent: Alignment.Center }) {
              Text(entry.icon)
                .fontSize(22)
            }
            .width(48)
            .height(48)
            .borderRadius(24)
            .backgroundColor(this.getQuickEntryBgColor(entry.colorKey))
            .shadow({ radius: 8, color: 'rgba(26,26,26,0.10)', offsetX: 0, offsetY: 3 })

            // 标签（对齐 .qn-cat-label：12px / 500）
            Text(entry.label)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.color_ink_2'))
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
    }
    .width('100%')
    .padding(16)
    .margin({ top: 16, left: 16, right: 16 })
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 直播横滑区（对齐 .qn-live-scroll：段头 + 横向卡片列表） */
  @Builder
  LiveSection() {
    if (this.liveList.length > 0) {
      Column() {
        // 段头（对齐 .qn-section-head：LIVE pill + "正在直播" + 查看更多）
        Row() {
          Row({ space: 8 }) {
            // LIVE pill（对齐 .qn-pill-live：红底白字 + 圆点）
            Row({ space: 3 }) {
              Column()
                .width(6)
                .height(6)
                .borderRadius(3)
                .backgroundColor(Color.White)
              Text('LIVE')
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
            }
            .backgroundColor($r('app.color.color_live'))
            .borderRadius(AppConstants.RADIUS_PILL)
            .padding({ left: 10, right: 10, top: 3, bottom: 3 })

            Text('正在直播')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.color_ink'))
          }

          Blank()

          // 查看更多（对齐 .qn-more）
          Row({ space: 2 }) {
            Text('查看更多')
              .fontSize(12)
              .fontColor($r('app.color.color_text_3'))
            Text('›')
              .fontSize(14)
              .fontColor($r('app.color.color_text_3'))
          }
          .onClick(() => {
            NavigationHelper.push(RouteName.USER_LIVE_LIST);
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 4, bottom: 12 })

        // 横向滚动直播卡（对齐 .qn-live-scroll）
        List({ space: 12 }) {
          ForEach(this.liveList, (live: LiveListItem, index: number) => {
            ListItem() {
              this.LiveCard(live)
            }
          }, (live: LiveListItem) => live.liveId)
        }
        .listDirection(Axis.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 4 })
      }
      .width('100%')
      .margin({ top: 16 })
    }
  }

  /** 直播卡片（对齐 .qn-live-card：148 宽 / 96 高封面 + LIVE 徽标 + 观看人数 + 标题 + 主播） */
  @Builder
  LiveCard(live: LiveListItem) {
    Column({ space: 0 }) {
      // 封面 + LIVE 徽标（左上）+ 观看人数（右下）（对齐 .qn-thumb）
      Stack({ alignContent: Alignment.BottomEnd }) {
        ReplaceableImage({ imageKey: live.coverImage, imgWidth: 148, imgHeight: 96, imgRadius: AppConstants.RADIUS_MD, imgFit: ImageFit.Cover })

        // LIVE 徽标（对齐 .qn-live-badge：左上角红底白字，绝对定位）
        Row({ space: 3 }) {
          Column()
            .width(6)
            .height(6)
            .borderRadius(3)
            .backgroundColor(Color.White)
          Text('LIVE')
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .backgroundColor($r('app.color.color_live'))
        .borderRadius(AppConstants.RADIUS_PILL)
        .padding({ left: 7, right: 7, top: 2, bottom: 2 })
        .position({ x: 8, y: 8 })

        // 观看人数（对齐 .qn-live-viewers：右下角半透明黑底，Stack alignContent=BottomEnd + margin）
        Row({ space: 3 }) {
          Text('👁')
            .fontSize(9)
          Text(this.formatViewers(live.onlineCount))
            .fontSize(10)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
        }
        .backgroundColor('rgba(26,26,26,0.55)')
        .borderRadius(AppConstants.RADIUS_PILL)
        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        .margin({ right: 6, bottom: 6 })
      }
      .width(148)
      .height(96)
      .clip(true)

      // 直播标题（对齐 .qn-live-name：12px / 600）
      Text(live.title)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.color_ink'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 8 })
        .width(148)

      // 主播名（对齐 .qn-live-farmer：11px / text-3）
      Text(`主播 ${live.anchorName}`)
        .fontSize(11)
        .fontColor($r('app.color.color_text_3'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 3 })
        .width(148)
    }
    .width(148)
    .onClick(() => {
      this.gotoLiveRoom(live.liveId);
    })
  }

  /** 商品区段头（对齐农户端"我的商品"段头排版："为你推荐" + 查看全部） */
  @Builder
  ProductSectionHead() {
    Row() {
      Text('为你推荐')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.color_ink'))

      Blank()

      Row({ space: 2 }) {
        Text('查看全部')
          .fontSize(12)
          .fontColor($r('app.color.color_text_3'))
        Text('›')
          .fontSize(14)
          .fontColor($r('app.color.color_text_3'))
      }
      .onClick(() => {
        NavigationHelper.push(RouteName.USER_SEARCH_PAGE);
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 20, bottom: 12 })
  }

  /** Tab 项（对齐 .qn-tab：图标 + 文字，选中态黑字+黄图标，消息 Tab 带红点） */
  @Builder
  TabBarItem(label: string, icon: string, index: number, showDot: boolean) {
    Column({ space: 2 }) {
      Stack({ alignContent: Alignment.TopEnd }) {
        Text(icon)
          .fontSize(22)
          .fontColor(this.currentTab === index
            ? $r('app.color.color_yellow_deep')
            : $r('app.color.color_text_3'))

        // 消息红点（对齐 .qn-tab-dot）
        if (showDot) {
          Column()
            .width(7)
            .height(7)
            .borderRadius(3.5)
            .backgroundColor($r('app.color.color_live'))
            .border({ width: 1.5, color: $r('app.color.color_bg_card') })
        }
      }
      .width(24)
      .height(24)

      Text(label)
        .fontSize(10)
        .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.currentTab === index
          ? $r('app.color.color_ink')
          : $r('app.color.color_text_3'))
    }
    .width('100%')
    .height(64)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
