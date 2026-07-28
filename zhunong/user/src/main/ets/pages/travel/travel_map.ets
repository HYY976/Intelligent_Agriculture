/**
 * travel_map - 文旅地图页（spec 5.2 / 2.4.6.4）
 * 对齐 spec 5.2 整体布局（Stack 分层）：
 *  1. 底层：腾讯地图 WebView（全屏）+ fallback 渐变底图
 *  2. 顶部浮层：渐隐遮罩 + 返回按钮 + 搜索栏
 *  3. 分类筛选条：横向滚动胶囊（全部/农庄/民宿/景点/采摘园/市集）
 *  4. 右侧悬浮按钮：定位 + 图层切换
 *  5. 底部内容面板（Scroll 可滚动，白色圆角顶部）：
 *     - 拖动条 + 标题栏
 *     - 推荐路线列表（spec 5.3.1：3 条主题路线卡片）
 *     - 横滑 POI 卡片列表
 *     - 热门景点瀑布流（双列 WaterFlow）
 *     - 预订入口卡片（精选体验预订横幅）
 *
 * 腾讯地图接入（spec 5.1）：Web 组件加载 rawfile/travel_map.html
 *  - 通过 runJavaScript 调用 window.addMarker / clearMarkers / moveTo
 *  - 通过 javaScriptProxy 注入 appBridge，JS 侧 appBridge.onPoiClick / onMapReady 直接回调 ArkTS
 *  - 无 Key 时 HTML 自动走 fallback 模式，POI 列表仍正常展示
 */

import { webview } from '@kit.ArkWeb';
import { RouteName, NavigationHelper, Logger, AppConstants, ToastUtil } from 'common';
import {
  PoiInfo,
  PoiCategory,
  PoiListParam,
  PoiListResult,
  TravelRoute,
  getPoiCategoryLabel
} from '../../model/TravelModels';
import { getMockPoiList, MOCK_ROUTES, getMockBookingByPoiId } from '../../mock/TravelMock';
import { ImageUtil } from '../../utils/ImageUtil';
import { BookingExperience } from '../../model/TravelModels';

/** 跳转 POI 详情的路由参数 */
interface PoiDetailParam {
  poiId: string;
}

/** 跳转体验预约的路由参数 */
interface BookingRouteParam {
  poiId: string;
}

/** 分类筛选 Chip 配置项 */
interface CategoryChipConfig {
  /** chip 标签 */
  label: string;
  /** 对应 POI 分类（null 表示"全部"） */
  category: PoiCategory | null;
}

/** 热门景点瀑布流数据项（复用 PoiInfo） */
interface WaterfallItem {
  poi: PoiInfo;
  /** 卡片高度类型（用于瀑布流错落） */
  size: 'small' | 'medium' | 'large';
}

/**
 * JS → ArkTS 桥接对象（通过 Web 组件 javaScriptProxy 注入到 HTML 的 appBridge）。
 * HTML 中 window.appBridge.onPoiClick / onMapReady 调用会直接回调到此处。
 */
class TravelMapBridge {
  private readonly onPoiClickHandler: (poiId: string) => void;
  private readonly onMapReadyHandler: () => void;

  constructor(onPoiClick: (poiId: string) => void, onMapReady: () => void) {
    this.onPoiClickHandler = onPoiClick;
    this.onMapReadyHandler = onMapReady;
  }

  /** JS Marker 点击回调 */
  onPoiClick(poiId: string): void {
    this.onPoiClickHandler(poiId);
  }

  /** JS 地图就绪回调 */
  onMapReady(): void {
    this.onMapReadyHandler();
  }
}

@ComponentV2
export struct TravelMap {
  /** POI 列表 */
  @Local poiList: PoiInfo[] = [];
  /** 推荐路线列表（spec 5.3.1） */
  @Local routeList: TravelRoute[] = [];
  /** 热门景点瀑布流数据 */
  @Local waterfallItems: WaterfallItem[] = [];
  /** 精选体验预订数据（spec 5.3.3） */
  @Local featuredBooking: BookingExperience | null = null;
  /** 当前选中的 POI（用于地图 Marker 高亮） */
  @Local selectedPoiId: string = '';
  /** 当前类型筛选 */
  @Local currentCategory: PoiCategory | null = null;
  /** 当前搜索关键字 */
  @Local searchKeyword: string = '';
  /** 6 类分类筛选 */
  @Local categoryChips: CategoryChipConfig[] = [];
  /** Web 控制器（腾讯地图） */
  private webController: webview.WebviewController = new webview.WebviewController();
  /** 地图 SDK 是否就绪 */
  @Local mapSdkReady: boolean = false;
  /** 待注入的 Marker 队列（SDK ready 前缓存） */
  private pendingMarkers: PoiInfo[] = [];
  /** JS → ArkTS 桥接对象（javaScriptProxy 注入到 HTML 的 appBridge） */
  private bridge: TravelMapBridge = new TravelMapBridge(
    (poiId: string): void => { this.handlePoiClickFromJs(poiId); },
    (): void => { this.handleMapReadyFromJs(); }
  );

  async aboutToAppear(): Promise<void> {
    this.categoryChips = this.buildCategoryChips();
    this.routeList = MOCK_ROUTES;
    this.featuredBooking = getMockBookingByPoiId('poi001');
    await this.refreshPoiList();
    if (this.poiList.length > 0) {
      this.selectedPoiId = this.poiList[0].poiId;
    }
    this.buildWaterfallItems();
    Logger.info(AppConstants.SCENE_USER, {
      action: 'travel_map_appear',
      count: this.poiList.length,
      total: this.routeList.length
    });
  }

  /** 构建 6 类分类筛选配置 */
  private buildCategoryChips(): CategoryChipConfig[] {
    const chips: CategoryChipConfig[] = [
      { label: '全部', category: null },
      { label: getPoiCategoryLabel('farm'), category: 'farm' },
      { label: getPoiCategoryLabel('homestay'), category: 'homestay' },
      { label: getPoiCategoryLabel('sightspot'), category: 'sightspot' },
      { label: getPoiCategoryLabel('picking_garden'), category: 'picking_garden' },
      { label: getPoiCategoryLabel('market'), category: 'market' }
    ];
    return chips;
  }

  /** 构建热门景点瀑布流数据（复用 POI 列表，按 distance 交替分配尺寸） */
  private buildWaterfallItems(): void {
    const items: WaterfallItem[] = this.poiList.map((poi: PoiInfo, idx: number): WaterfallItem => {
      const size: 'small' | 'medium' | 'large' = idx % 3 === 0 ? 'large' : (idx % 3 === 1 ? 'medium' : 'small');
      return { poi: poi, size: size };
    });
    this.waterfallItems = items;
  }

  /** 刷新 POI 列表 */
  private async refreshPoiList(): Promise<void> {
    const param: PoiListParam = {
      city: '杭州',
      category: this.currentCategory ?? undefined,
      keyword: this.searchKeyword.length > 0 ? this.searchKeyword : undefined,
      sortBy: 'distance',
      page: 1,
      size: 50
    };
    const result: PoiListResult = getMockPoiList(param);
    this.poiList = result.list;
    // 同步更新 Marker
    this.injectMarkers();
  }

  /** 返回 */
  private goBack(): void {
    NavigationHelper.pop();
  }

  /** 切换类型筛选 */
  private onCategorySelect(category: PoiCategory | null): void {
    this.currentCategory = category;
    this.refreshPoiList();
    Logger.info(AppConstants.SCENE_USER, {
      action: 'travel_category_switch',
      filter: category ?? 'all'
    });
  }

  /** 点击 POI（Marker / 列表卡片） → 选中 + 高亮 + 移动地图 */
  private onPoiSelect(poi: PoiInfo): void {
    this.selectedPoiId = poi.poiId;
    this.moveMapToPoi(poi);
    Logger.info(AppConstants.SCENE_USER, {
      action: 'poi_select',
      poiId: poi.poiId
    });
  }

  /** 跳转 POI 详情 */
  private gotoPoiDetail(poiId: string): void {
    const param: PoiDetailParam = { poiId: poiId };
    NavigationHelper.push(RouteName.USER_POI_DETAIL, param);
  }

  /** 跳转体验预约（spec 5.3.3 预订入口） */
  private gotoBooking(poiId: string): void {
    const param: BookingRouteParam = { poiId: poiId };
    NavigationHelper.push(RouteName.USER_BOOKING, param);
  }

  /** 点击定位按钮 */
  private onLocate(): void {
    ToastUtil.info('已回到当前位置');
  }

  /** 点击图层切换 */
  private onLayerToggle(): void {
    ToastUtil.info('图层切换（开发中）');
  }

  /** 搜索提交 */
  private onSearchSubmit(): void {
    this.refreshPoiList();
    if (this.poiList.length > 0) {
      this.selectedPoiId = this.poiList[0].poiId;
    }
    ToastUtil.info(`搜索到 ${this.poiList.length} 个结果`);
  }

  /** ============================================================
   *  腾讯地图 WebView 交互
   *  ============================================================ */

  /** Web 页面加载完成（触发 Marker 注入尝试） */
  private onWebPageFinish(): void {
    // SDK 就绪由 JS 主动回调 handleMapReadyFromJs 通知
    // 这里先尝试注入一次（fallback 模式下 runJavaScript 调用会被忽略）
    this.injectMarkers();
  }

  /** JS 回调：地图 SDK 就绪 */
  private handleMapReadyFromJs(): void {
    this.mapSdkReady = true;
    this.injectMarkers();
    Logger.info(AppConstants.SCENE_USER, {
      action: 'travel_map_sdk_ready'
    });
  }

  /** JS 回调：Marker 被点击 */
  private handlePoiClickFromJs(poiId: string): void {
    this.selectedPoiId = poiId;
    Logger.info(AppConstants.SCENE_USER, {
      action: 'poi_marker_click',
      poiId: poiId
    });
  }

  /** 注入 POI Marker 到地图 */
  private injectMarkers(): void {
    if (!this.mapSdkReady) {
      this.pendingMarkers = this.poiList.slice();
      return;
    }
    try {
      this.webController.runJavaScript('window.clearMarkers()');
      for (let i = 0; i < this.poiList.length; i++) {
        const poi: PoiInfo = this.poiList[i];
        if (poi.coordinate.lat !== undefined && poi.coordinate.lng !== undefined) {
          const lat: number = poi.coordinate.lat;
          const lng: number = poi.coordinate.lng;
          const name: string = poi.name.replace(/'/g, '');
          const poiId: string = poi.poiId;
          this.webController.runJavaScript(
            `window.addMarker('${poiId}', ${lat}, ${lng}, '${name}')`
          );
        }
      }
    } catch (err) {
      Logger.error(AppConstants.SCENE_USER, {
        action: 'travel_inject_markers_fail',
        error: (err as Error).message
      });
    }
  }

  /** 移动地图到指定 POI */
  private moveMapToPoi(poi: PoiInfo): void {
    if (!this.mapSdkReady) return;
    if (poi.coordinate.lat !== undefined && poi.coordinate.lng !== undefined) {
      const lat: number = poi.coordinate.lat;
      const lng: number = poi.coordinate.lng;
      try {
        this.webController.runJavaScript(`window.moveTo(${lat}, ${lng}, 14)`);
      } catch (err) {
        Logger.error(AppConstants.SCENE_USER, {
          action: 'travel_move_map_fail',
          error: (err as Error).message
        });
      }
    }
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        // ===== 1. 底层：腾讯地图 WebView（全屏） =====
        this.MapWebView()

        // ===== 2. 顶部渐隐遮罩 =====
        this.TopScrim()

        // ===== 3. 顶栏浮层：返回 + 搜索栏 =====
        this.TopBar()

        // ===== 4. 分类筛选条 =====
        this.CategoryFilterBar()

        // ===== 5. 右侧悬浮按钮（定位/图层） =====
        this.SideButtons()

        // ===== 6. 底部内容面板（路线 + POI + 瀑布流 + 预订入口） =====
        this.BottomSheet()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 底层腾讯地图 WebView（spec 5.1：Web 组件加载 rawfile/travel_map.html） */
  @Builder
  MapWebView() {
    Web({ src: $rawfile('travel_map.html'), controller: this.webController })
      .width('100%')
      .height('100%')
      .javaScriptAccess(true)
      .domStorageAccess(true)
      .fileAccess(true)
      .javaScriptProxy({
        object: this.bridge,
        name: 'appBridge',
        methodList: ['onPoiClick', 'onMapReady'],
        controller: this.webController
      })
      .onPageEnd(() => {
        this.onWebPageFinish();
      })
  }

  /** 顶部渐隐遮罩 */
  @Builder
  TopScrim() {
    Column()
      .width('100%')
      .height(150)
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: [
          ['rgba(26,26,26,0.30)', 0],
          ['rgba(26,26,26,0.08)', 0.6],
          ['rgba(26,26,26,0)', 1]
        ]
      })
      .hitTestBehavior(HitTestMode.Transparent)
  }

  /** 右侧悬浮按钮组（定位 + 图层） */
  @Builder
  SideButtons() {
    Column({ space: 12 }) {
      // 定位按钮
      Row() {
        Text('📍')
          .fontSize(20)
          .fontColor($r('app.color.color_ink'))
      }
      .width(44)
      .height(44)
      .borderRadius(22)
      .backgroundColor($r('app.color.color_bg_card'))
      .shadow(AppConstants.SHADOW_FLOAT)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { this.onLocate(); })

      // 图层按钮
      Row() {
        Text('🗂️')
          .fontSize(20)
          .fontColor($r('app.color.color_ink'))
      }
      .width(44)
      .height(44)
      .borderRadius(22)
      .backgroundColor($r('app.color.color_bg_card'))
      .shadow(AppConstants.SHADOW_FLOAT)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { this.onLayerToggle(); })
    }
    .position({ right: 16, bottom: 420 })
  }

  /** 顶栏浮层（返回 + 搜索栏） */
  @Builder
  TopBar() {
    Row({ space: 10 }) {
      // 返回按钮
      Row() {
        Text('‹')
          .fontSize(24)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .width(36)
      .height(36)
      .borderRadius(18)
      .backgroundColor('rgba(255,255,255,0.85)')
      .shadow(AppConstants.SHADOW_CARD)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { this.goBack(); })

      // 搜索栏
      Row({ space: 8 }) {
        Text('🔍')
          .fontSize(14)
          .fontColor($r('app.color.color_text_3'))
        TextInput({ text: this.searchKeyword, placeholder: '搜索农庄/景点' })
          .fontSize(13)
          .fontColor($r('app.color.color_ink'))
          .placeholderFont({ size: 13 })
          .placeholderColor($r('app.color.color_text_3'))
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .height(40)
          .padding({ left: 0, right: 0 })
          .onChange((value: string) => {
            this.searchKeyword = value;
          })
          .onSubmit(() => {
            this.onSearchSubmit();
          })
      }
      .layoutWeight(1)
      .height(40)
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor($r('app.color.color_bg_card'))
      .shadow(AppConstants.SHADOW_CARD)
      .padding({ left: 14, right: 14 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 50, bottom: 0 })
    .alignItems(VerticalAlign.Center)
  }

  /** 分类筛选条 */
  @Builder
  CategoryFilterBar() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.categoryChips, (chip: CategoryChipConfig) => {
          Text(chip.label)
            .fontSize(13)
            .fontColor(this.currentCategory === chip.category ? $r('app.color.color_ink') : $r('app.color.color_ink_2'))
            .fontWeight(this.currentCategory === chip.category ? FontWeight.Bold : FontWeight.Normal)
            .backgroundColor(this.currentCategory === chip.category ? $r('app.color.color_yellow') : 'rgba(255,255,255,0.92)')
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .borderRadius(AppConstants.RADIUS_PILL)
            .shadow(AppConstants.SHADOW_CARD)
            .onClick(() => { this.onCategorySelect(chip.category); })
        }, (chip: CategoryChipConfig) => chip.label)
      }
      .padding({ left: 16, right: 16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .padding({ top: 8, bottom: 4 })
    .position({ left: 0, top: 100 })
  }

  /** 底部内容面板（spec 5.2：路线 + POI + 瀑布流 + 预订入口） */
  @Builder
  BottomSheet() {
    Scroll() {
      Column({ space: 0 }) {
        // 拖动条
        Row()
          .width(40)
          .height(4)
          .borderRadius(2)
          .backgroundColor($r('app.color.color_line_2'))
          .margin({ top: 14, bottom: 14 })

        // 标题栏
        Row({ space: 8 }) {
          Text('附近农庄')
            .fontSize(16)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
          Text(`${this.poiList.length}个结果`)
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 12 })
        .alignItems(VerticalAlign.Bottom)

        // ===== 推荐路线列表（spec 5.3.1） =====
        this.RecommendRoutesSection()

        // ===== 横滑 POI 卡片列表 =====
        this.PoiCardListSection()

        // ===== 热门景点瀑布流（spec 5.3.2） =====
        this.HotSpotsWaterfallSection()

        // ===== 预订入口卡片（spec 5.3.3） =====
        this.BookingEntrySection()
      }
      .width('100%')
      .padding({ bottom: 40 })
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .width('100%')
    .height(460)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius({ topLeft: AppConstants.RADIUS_XL, topRight: AppConstants.RADIUS_XL })
    .shadow({ radius: 20, color: 'rgba(26,26,26,0.08)', offsetX: 0, offsetY: -4 })
    .position({ left: 0, bottom: 0 })
  }

  /** 推荐路线列表（spec 5.3.1：3 条主题路线卡片） */
  @Builder
  RecommendRoutesSection() {
    Column({ space: 0 }) {
      // 段头
      Row({ space: 6 }) {
        Text('🎯')
          .fontSize(14)
        Text('推荐路线')
          .fontSize(15)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 10 })

      // 路线卡片列表（垂直）
      Column({ space: 12 }) {
        ForEach(this.routeList, (route: TravelRoute) => {
          this.RouteCard(route)
        }, (route: TravelRoute) => route.routeId)
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 16 })
    }
    .width('100%')
  }

  /** 单个路线卡片（封面图 + 标题 + 路线点 + 时长/价格 + 标签） */
  @Builder
  RouteCard(route: TravelRoute) {
    Column({ space: 0 }) {
      // 封面图 + 时长胶囊
      Stack({ alignContent: Alignment.TopEnd }) {
        Image(ImageUtil.get(route.coverImage))
          .width('100%')
          .height(120)
          .objectFit(ImageFit.Cover)
          .borderRadius({ topLeft: AppConstants.RADIUS_MD, topRight: AppConstants.RADIUS_MD })
          .backgroundColor($r('app.color.color_fill'))

        Text(route.duration)
          .fontSize(11)
          .fontColor(Color.White)
          .backgroundColor('rgba(26,26,26,0.6)')
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(AppConstants.RADIUS_PILL)
          .margin({ top: 10, right: 10 })
      }
      .width('100%')
      .height(120)

      // 内容区
      Column({ space: 8 }) {
        Text(route.title)
          .fontSize(15)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 路线点（POI 名称串联）
        Row({ space: 4 }) {
          ForEach(route.poiNames, (name: string, idx: number) => {
            Text(name)
              .fontSize(11)
              .fontColor($r('app.color.color_text_2'))
            if (idx < route.poiNames.length - 1) {
              Text('→')
                .fontSize(11)
                .fontColor($r('app.color.color_text_4'))
            }
          }, (name: string, idx: number) => `${name}-${idx}`)
        }
        .width('100%')

        // 描述
        Text(route.description)
          .fontSize(12)
          .fontColor($r('app.color.color_text_3'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 标签 + 价格行
        Row({ space: 6 }) {
          ForEach(route.tags, (tag: string) => {
            Text(tag)
              .fontSize(10)
              .fontColor($r('app.color.color_yellow_text'))
              .backgroundColor($r('app.color.color_yellow_soft'))
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(AppConstants.RADIUS_PILL)
          }, (tag: string) => tag)

          Blank()

          // 价格
          Row({ space: 1 }) {
            Text('¥')
              .fontSize(11)
              .fontColor($r('app.color.color_live'))
              .fontWeight(FontWeight.Bold)
            Text(`${route.price}`)
              .fontSize(15)
              .fontColor($r('app.color.color_live'))
              .fontWeight(FontWeight.Bold)
            Text('/人')
              .fontSize(10)
              .fontColor($r('app.color.color_text_3'))
          }
          .alignItems(VerticalAlign.Bottom)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding(12)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .borderRadius(AppConstants.RADIUS_MD)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .onClick(() => {
      // 跳转第一个 POI 详情（演示用）
      if (route.poiIds.length > 0) {
        this.gotoPoiDetail(route.poiIds[0]);
      }
    })
  }

  /** 横滑 POI 卡片列表 */
  @Builder
  PoiCardListSection() {
    Column({ space: 0 }) {
      // 段头
      Row({ space: 6 }) {
        Text('📍')
          .fontSize(14)
        Text('附近农庄')
          .fontSize(15)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        Blank()
        Text('查看全部 ›')
          .fontSize(12)
          .fontColor($r('app.color.color_text_3'))
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 10 })

      // 横滑卡片
      Scroll() {
        Row({ space: 10 }) {
          ForEach(this.poiList, (poi: PoiInfo) => {
            this.PoiCard(poi)
          }, (poi: PoiInfo) => poi.poiId)
        }
        .padding({ left: 16, right: 16 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .padding({ bottom: 16 })
    }
    .width('100%')
  }

  /** POI 卡片（240 宽：图 + 名 + 标签 + 评分/距离/价格） */
  @Builder
  PoiCard(poi: PoiInfo) {
    Column({ space: 0 }) {
      // 顶部图片
      Image(ImageUtil.get(poi.images.length > 0 ? poi.images[0] : 'farm_picking'))
        .width('100%')
        .height(100)
        .borderRadius({ topLeft: AppConstants.RADIUS_MD, topRight: AppConstants.RADIUS_MD })
        .objectFit(ImageFit.Cover)
        .backgroundColor($r('app.color.color_fill'))

      // 内容区
      Column({ space: 6 }) {
        Text(poi.name)
          .fontSize(15)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(getPoiCategoryLabel(poi.category))
          .fontSize(11)
          .fontColor($r('app.color.color_yellow_text'))
          .fontWeight(FontWeight.Bold)
          .padding({ left: 10, right: 10, top: 3, bottom: 3 })
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_yellow_soft'))

        // 元信息行：评分 + 距离 + 价格
        Row({ space: 8 }) {
          Row({ space: 2 }) {
            Text('★')
              .fontSize(13)
              .fontColor('#FFB300')
            Text(poi.rating.toFixed(1))
              .fontSize(12)
              .fontColor($r('app.color.color_ink'))
              .fontWeight(FontWeight.Bold)
          }
          .alignItems(VerticalAlign.Center)

          Text(this.formatDistance(poi.distance))
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))

          Row({ space: 1 }) {
            Text('¥')
              .fontSize(12)
              .fontColor($r('app.color.color_live'))
              .fontWeight(FontWeight.Bold)
            Text(`${poi.avgPrice}`)
              .fontSize(14)
              .fontColor($r('app.color.color_live'))
              .fontWeight(FontWeight.Bold)
            Text('/人')
              .fontSize(11)
              .fontColor($r('app.color.color_text_3'))
              .fontWeight(FontWeight.Bold)
          }
          .alignItems(VerticalAlign.Bottom)
          .layoutWeight(1)
          .justifyContent(FlexAlign.End)
        }
        .width('100%')
        .margin({ top: 4 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding(12)
      .alignItems(HorizontalAlign.Start)
    }
    .width(240)
    .borderRadius(AppConstants.RADIUS_MD)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .onClick(() => {
      this.onPoiSelect(poi);
      this.gotoPoiDetail(poi.poiId);
    })
  }

  /** 热门景点瀑布流（spec 5.3.2：双列 WaterFlow） */
  @Builder
  HotSpotsWaterfallSection() {
    Column({ space: 0 }) {
      // 段头
      Row({ space: 6 }) {
        Text('🔥')
          .fontSize(14)
        Text('热门景点')
          .fontSize(15)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 10 })

      // 瀑布流
      WaterFlow() {
        ForEach(this.waterfallItems, (item: WaterfallItem) => {
          FlowItem() {
            this.WaterfallCard(item)
          }
        }, (item: WaterfallItem) => item.poi.poiId)
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(10)
      .rowsGap(10)
      .padding({ left: 16, right: 16 })
      .width('100%')
      .height(560)
    }
    .width('100%')
    .padding({ top: 8, bottom: 16 })
  }

  /** 瀑布流卡片（错落高度：small=140 / medium=170 / large=200） */
  @Builder
  WaterfallCard(item: WaterfallItem) {
    Column({ space: 0 }) {
      // 封面图（高度随 size 变化）
      Image(ImageUtil.get(item.poi.images.length > 0 ? item.poi.images[0] : 'farm_picking'))
        .width('100%')
        .height(item.size === 'large' ? 160 : (item.size === 'medium' ? 130 : 100))
        .objectFit(ImageFit.Cover)
        .borderRadius({ topLeft: AppConstants.RADIUS_MD, topRight: AppConstants.RADIUS_MD })
        .backgroundColor($r('app.color.color_fill'))

      Column({ space: 6 }) {
        Text(item.poi.name)
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(getPoiCategoryLabel(item.poi.category))
          .fontSize(10)
          .fontColor($r('app.color.color_yellow_text'))
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_yellow_soft'))

        Row({ space: 4 }) {
          Text('★')
            .fontSize(11)
            .fontColor('#FFB300')
          Text(item.poi.rating.toFixed(1))
            .fontSize(11)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
          Text(this.formatDistance(item.poi.distance))
            .fontSize(11)
            .fontColor($r('app.color.color_text_3'))
          Blank()
          Text(`¥${item.poi.avgPrice}`)
            .fontSize(12)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding(10)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .borderRadius(AppConstants.RADIUS_MD)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .onClick(() => {
      this.onPoiSelect(item.poi);
      this.gotoPoiDetail(item.poi.poiId);
    })
  }

  /** 预订入口卡片（spec 5.3.3：精选体验预订横幅） */
  @Builder
  BookingEntrySection() {
    Column({ space: 0 }) {
      // 段头
      Row({ space: 6 }) {
        Text('🎟️')
          .fontSize(14)
        Text('精选体验预订')
          .fontSize(15)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 10 })

      if (this.featuredBooking !== null) {
        this.BookingBanner(this.featuredBooking as BookingExperience)
      }
    }
    .width('100%')
    .padding({ top: 8, bottom: 24 })
  }

  /** 预订横幅卡片（封面 + 标题 + 距离 + 标签 + 评分 + 价格 + 立即预订按钮） */
  @Builder
  BookingBanner(booking: BookingExperience) {
    Column({ space: 0 }) {
      // 封面图 + 距离胶囊
      Stack({ alignContent: Alignment.TopStart }) {
        Image(ImageUtil.get(booking.coverImage))
          .width('100%')
          .height(140)
          .objectFit(ImageFit.Cover)
          .borderRadius({ topLeft: AppConstants.RADIUS_MD, topRight: AppConstants.RADIUS_MD })
          .backgroundColor($r('app.color.color_fill'))

        Text(booking.distanceText)
          .fontSize(11)
          .fontColor(Color.White)
          .backgroundColor('rgba(26,26,26,0.6)')
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(AppConstants.RADIUS_PILL)
          .margin({ top: 10, left: 10 })
      }
      .width('100%')
      .height(140)

      // 内容区
      Column({ space: 10 }) {
        // 标题
        Text(booking.poiName)
          .fontSize(16)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)

        // 标签行
        Row({ space: 6 }) {
          ForEach(booking.tags, (tag: string) => {
            Text(tag)
              .fontSize(10)
              .fontColor($r('app.color.color_yellow_text'))
              .backgroundColor($r('app.color.color_yellow_soft'))
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(AppConstants.RADIUS_PILL)
          }, (tag: string) => tag)
        }
        .width('100%')

        // 评分 + 已预约
        Row({ space: 12 }) {
          Row({ space: 2 }) {
            Text('★')
              .fontSize(13)
              .fontColor('#FFB300')
            Text(booking.rating.toFixed(1))
              .fontSize(12)
              .fontColor($r('app.color.color_ink'))
              .fontWeight(FontWeight.Bold)
          }
          .alignItems(VerticalAlign.Center)

          Text(booking.bookingCountText)
            .fontSize(11)
            .fontColor($r('app.color.color_text_3'))
        }
        .width('100%')

        // 价格行
        Row({ space: 4 }) {
          Text('¥')
            .fontSize(12)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
          Text(`${booking.pricePerPerson}`)
            .fontSize(18)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
          Text('/人')
            .fontSize(11)
            .fontColor($r('app.color.color_text_3'))
          Blank()
          Text(booking.priceSubtitle)
            .fontSize(11)
            .fontColor($r('app.color.color_text_3'))
        }
        .width('100%')
        .alignItems(VerticalAlign.Bottom)

        // 立即预订按钮
        Text('立即预订')
          .width('100%')
          .height(42)
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_ink'))
          .fontColor(Color.White)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.gotoBooking(booking.poiId);
          })
      }
      .width('100%')
      .padding(14)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .borderRadius(AppConstants.RADIUS_MD)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .padding({ left: 16, right: 16 })
  }

  /** 格式化距离（米 → km） */
  private formatDistance(distance: number): string {
    if (distance >= 1000) {
      return `${(distance / 1000).toFixed(1)}km`;
    }
    return `${distance}m`;
  }
}
