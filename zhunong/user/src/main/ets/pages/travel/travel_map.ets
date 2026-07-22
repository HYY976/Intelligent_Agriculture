/**
 * travel_map - 文旅地图页（spec 3.1.4.3 / 2.4.6.4）
 * 上层：地图视图（百度地图 SDK MapComponent 预留位 → Phase 3 用自绘 Mock 地图）
 * 下层：底部滑动面板（默认40%屏，上滑80%下滑20%）展示推荐点位列表
 * 数据来源：百度地图 POI 检索（@bdmap/search PoiSearch）→ Phase 3 用本地 Mock
 *
 * 百度地图 SDK 集成点（Phase 6）：
 *   1) user/oh-package.json5 添加 "@bdmap/map": "^x.x.x" 等依赖
 *   2) 将 MockMapView 替换为 MapComponent({ mapType: MapType.MAP_TYPE_NORMAL })
 *   3) 将 getMockPoiList 替换为 PoiSearch.requestAsyncSearch
 *   4) POI Marker 改用 MarkerOptions.position(LatLng)
 *   5) 信息窗改用 mapController.showPopView(PopInfoOptions)
 */

import { UserRoutes, RouteName, NavigationHelper, Logger, AppConstants, ToastUtil, ConfigUtil } from 'common';
import { PoiInfo, PoiCategory, PoiListParam, PoiListResult, getPoiCategoryLabel, getPoiCategoryIcon } from '../../model/TravelModels';
import { getMockPoiList, MOCK_CITIES } from '../../mock/TravelMock';
import { ImageUtil } from '../../utils/ImageUtil';

/** 跳转 POI 详情的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface PoiDetailParam {
  poiId: string;
}

@ComponentV2
export struct TravelMap {
  /** 当前城市 */
  @Local currentCity: string = '杭州';
  /** POI 列表 */
  @Local poiList: PoiInfo[] = [];
  /** 当前选中的 POI（用于地图 Marker 高亮 + 信息窗） */
  @Local selectedPoi: PoiInfo | null = null;
  /** 是否显示城市选择浮层 */
  @Local showCityPicker: boolean = false;
  /** 当前类型筛选 */
  @Local currentCategory: PoiCategory | null = null;
  /** 当前排序 */
  @Local currentSortBy: 'distance' | 'rating' | 'price_asc' | 'price_desc' = 'distance';
  /** 底部面板高度比例（0.2 / 0.4 / 0.8） */
  @Local panelHeightRatio: number = 0.4;
  /** 是否首次加载 */
  @Local isFirstLoad: boolean = true;

  async aboutToAppear(): Promise<void> {
    await this.refreshPoiList();
    this.isFirstLoad = false;
    Logger.info(AppConstants.SCENE_USER, { action: 'travel_map_appear', city: this.currentCity });
  }

  /** 刷新 POI 列表 */
  private async refreshPoiList(): Promise<void> {
    const param: PoiListParam = {
      city: this.currentCity,
      category: this.currentCategory ?? undefined,
      sortBy: this.currentSortBy,
      page: 1,
      size: 50
    };
    const result: PoiListResult = getMockPoiList(param);
    this.poiList = result.list;
    // 默认选中第一个精选/距离最近的 POI
    if (this.poiList.length > 0) {
      this.selectedPoi = this.poiList[0];
    } else {
      this.selectedPoi = null;
    }
  }

  /** 返回 */
  private goBack(): void {
    NavigationHelper.pop();
  }

  /** 切换城市 */
  private onCitySelect(city: string): void {
    this.currentCity = city;
    this.showCityPicker = false;
    this.refreshPoiList();
    Logger.info(AppConstants.SCENE_USER, { action: 'travel_city_switch', city: city });
  }

  /** 切换类型筛选 */
  private onCategorySelect(category: PoiCategory | null): void {
    this.currentCategory = category;
    this.refreshPoiList();
  }

  /** 切换排序 */
  private onSortChange(): void {
    const sortList: Array<'distance' | 'rating' | 'price_asc' | 'price_desc'> = ['distance', 'rating', 'price_asc', 'price_desc'];
    const currentIdx: number = sortList.indexOf(this.currentSortBy);
    this.currentSortBy = sortList[(currentIdx + 1) % sortList.length];
    this.refreshPoiList();
    ToastUtil.info(`按${this.sortLabel(this.currentSortBy)}排序`);
  }

  /** 排序文案 */
  private sortLabel(sortBy: 'distance' | 'rating' | 'price_asc' | 'price_desc'): string {
    switch (sortBy) {
      case 'distance': return '距离';
      case 'rating': return '评分';
      case 'price_asc': return '价格低到高';
      case 'price_desc': return '价格高到低';
      default: return '距离';
    }
  }

  /** 点击地图 Marker / 列表项 */
  private onPoiSelect(poi: PoiInfo): void {
    this.selectedPoi = poi;
    Logger.info(AppConstants.SCENE_USER, { action: 'poi_select', poiId: poi.poiId });
  }

  /** 跳转 POI 详情 */
  private gotoPoiDetail(poiId: string): void {
    const param: PoiDetailParam = { poiId: poiId };
    NavigationHelper.push(RouteName.USER_POI_DETAIL, param);
  }

  /** 点击导航按钮（Mock：调起百度地图客户端，后续迭代） */
  private onNavigate(poi: PoiInfo): void {
    ToastUtil.info(`导航至 ${poi.name}（开发中）`);
    Logger.info(AppConstants.SCENE_USER, { action: 'poi_navigate', poiId: poi.poiId });
  }

  /** 底部面板上滑/下滑切换 */
  private onPanelDrag(state: PanelDragState): void {
    if (state === 'expand') {
      this.panelHeightRatio = 0.8;
    } else if (state === 'collapse') {
      this.panelHeightRatio = 0.2;
    } else {
      this.panelHeightRatio = 0.4;
    }
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        // ===== 上层：地图视图 =====
        this.MapView()

        // ===== 顶部城市选择栏 =====
        this.TopCityBar()

        // ===== 类型筛选 Tab =====
        this.CategoryFilterBar()

        // ===== 底部滑动面板 =====
        this.BottomPanel()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 地图视图（spec 10.4：按 ConfigUtil.useRealBaiduMap() 开关切换真实 SDK / Mock 自绘） */
  @Builder
  MapView() {
    if (ConfigUtil.useRealBaiduMap()) {
      this.RealBaiduMapView()
    } else {
      this.MockMapView()
    }
  }

  /**
   * 真实百度地图 SDK 视图（spec 10.4：默认不启用，待用户提供真实 AK + 安装 @bdmap/* 包后启用）
   *
   * 启用步骤：
   *  1) user/oh-package.json5 添加依赖：@bdmap/base @bdmap/map @bdmap/search @bdmap/locsdk @bdmap/util
   *  2) ConfigUtil 中替换 baiduMapAk 为真实 AK
   *  3) 调用 ConfigUtil.setUseRealBaiduMap(true) 启用此分支
   *  4) 取消下方注释，填充真实 MapComponent / PoiSearch / Marker 集成代码
   */
  @Builder
  RealBaiduMapView() {
    // 真实集成代码占位（待启用）：
    // import { MapComponent, MapType } from '@bdmap/map';
    // import { PoiSearch, PoiRequestParam } from '@bdmap/search';
    // import { MarkerOptions, LatLng } from '@bdmap/map';
    // MapComponent({ mapType: MapType.MAP_TYPE_NORMAL, mapOptions: { ... } })
    //   .onLoaded((mapController: map.MapController) => { this.mapController = mapController; })
    //   .width('100%').height('100%')
    // POI 检索：PoiSearch.requestAsyncSearch(new PoiRequestParam({ ... }), (result) => { ... })
    // POI Marker：mapController.addMarker(MarkerOptions.position(new LatLng(lat, lng)))
    Stack({ alignContent: Alignment.Center }) {
      Text('百度地图 SDK 待启用')
        .fontSize(14)
        .fontColor($r('app.color.color_text_hint'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.color_bg_page'))
  }

  /** Mock 自绘地图视图（默认：渐变背景 + Marker 点位 + 信息窗） */
  @Builder
  MockMapView() {
    Stack() {
      // 地图底图（Mock：浅绿渐变 + 网格纹理模拟地形）
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 135,
          colors: [['#E8F5E9', 0], ['#C8E6C9', 0.5], ['#A5D6A7', 1]]
        })

      // 模拟地图路网（细线条装饰）
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 45,
          colors: [['rgba(255,255,255,0.15)', 0], ['rgba(255,255,255,0)', 0.3], ['rgba(255,255,255,0.15)', 0.6], ['rgba(255,255,255,0)', 1]]
        })

      // POI Marker 列表（Mock：绝对定位）
      ForEach(this.poiList, (poi: PoiInfo) => {
        this.PoiMarker(poi)
      }, (poi: PoiInfo) => poi.poiId)

      // 当前定位按钮（右下角）
      this.LocationButton()

      // 比例尺 + 罗盘（左下角，Mock 装饰）
      this.MapDecorations()
    }
    .width('100%')
    .height('100%')
  }

  /** POI Marker（Mock：麦穗图标，选中态放大变橙） */
  @Builder
  PoiMarker(poi: PoiInfo) {
    Column({ space: 2 }) {
      Text(this.selectedPoi && this.selectedPoi.poiId === poi.poiId ? '🌾' : getPoiCategoryIcon(poi.category))
        .fontSize(this.selectedPoi && this.selectedPoi.poiId === poi.poiId ? 36 : 28)
      // 选中态显示名称
      if (this.selectedPoi && this.selectedPoi.poiId === poi.poiId) {
        Text(poi.name)
          .fontSize(11)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.color_secondary'))
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(8)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
    }
    .position({
      x: poi.coordinate.x * 360,
      y: poi.coordinate.y * 600
    })
    .markAnchor({ x: '50%', y: '100%' })
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.onPoiSelect(poi);
    })
  }

  /** 当前定位按钮 */
  @Builder
  LocationButton() {
    Text('📍')
      .fontSize(24)
      .width(48)
      .height(48)
      .textAlign(TextAlign.Center)
      .backgroundColor($r('app.color.color_bg_card'))
      .borderRadius(24)
      .shadow({ radius: 8, color: 'rgba(0,0,0,0.15)', offsetX: 0, offsetY: 2 })
      .position({ right: 16, bottom: 360 })
      .onClick(() => {
        ToastUtil.info('已回到当前位置');
      })
  }

  /** 比例尺 + 罗盘装饰 */
  @Builder
  MapDecorations() {
    Column({ space: 4 }) {
      Text('🧭 北')
        .fontSize(11)
        .fontColor($r('app.color.color_text_secondary'))
      Text('1km')
        .fontSize(10)
        .fontColor($r('app.color.color_text_secondary'))
      Row()
        .width(40)
        .height(2)
        .backgroundColor($r('app.color.color_text_secondary'))
    }
    .position({ left: 16, bottom: 360 })
    .alignItems(HorizontalAlign.Center)
  }

  /** 顶部城市选择栏 */
  @Builder
  TopCityBar() {
    Row({ space: 12 }) {
      // 返回按钮
      Text('←')
        .fontSize(24)
        .fontColor($r('app.color.color_text_primary'))
        .onClick(() => {
          this.goBack();
        })
      // 城市选择入口
      Row({ space: 4 }) {
        Text('📍')
          .fontSize(16)
        Text(this.currentCity)
          .fontSize(15)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Medium)
        Text('▾')
          .fontSize(12)
          .fontColor($r('app.color.color_text_secondary'))
      }
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .borderRadius(20)
      .backgroundColor($r('app.color.color_bg_card'))
      .shadow({ radius: 4, color: 'rgba(0,0,0,0.1)', offsetX: 0, offsetY: 1 })
      .onClick(() => {
        this.showCityPicker = true;
      })
      Blank()
      // 排序按钮
      Text(this.sortLabel(this.currentSortBy))
        .fontSize(13)
        .fontColor($r('app.color.color_text_primary'))
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .borderRadius(20)
        .backgroundColor($r('app.color.color_bg_card'))
        .shadow({ radius: 4, color: 'rgba(0,0,0,0.1)', offsetX: 0, offsetY: 1 })
        .onClick(() => {
          this.onSortChange();
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16, top: 36 })
    .alignItems(VerticalAlign.Center)
    .bindSheet($$this.showCityPicker, this.CityPickerSheet(), {
      height: '40%',
      dragBar: true,
      backgroundColor: $r('app.color.color_bg_card')
    })
  }

  /** 类型筛选 Tab */
  @Builder
  CategoryFilterBar() {
    Row({ space: 8 }) {
      this.CategoryChip('全部', null)
      this.CategoryChip(getPoiCategoryLabel('farmhouse'), 'farmhouse')
      this.CategoryChip(getPoiCategoryLabel('rural_tourism'), 'rural_tourism')
      this.CategoryChip(getPoiCategoryLabel('farm'), 'farm')
      this.CategoryChip(getPoiCategoryLabel('picking_garden'), 'picking_garden')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 96 })
    .alignItems(VerticalAlign.Center)
  }

  /** 类型筛选 Chip */
  @Builder
  CategoryChip(label: string, category: PoiCategory | null) {
    Text(label)
      .fontSize(12)
      .fontColor(this.currentCategory === category ? Color.White : $r('app.color.color_text_primary'))
      .backgroundColor(this.currentCategory === category ? $r('app.color.color_primary') : $r('app.color.color_bg_card'))
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .borderRadius(14)
      .shadow({ radius: 4, color: 'rgba(0,0,0,0.08)', offsetX: 0, offsetY: 1 })
      .onClick(() => {
        this.onCategorySelect(category);
      })
  }

  /** 城市选择 Sheet */
  @Builder
  CityPickerSheet() {
    Column({ space: 0 }) {
      Text('选择城市')
        .fontSize(16)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .padding({ left: 16, top: 12, bottom: 12 })

      List() {
        ForEach(MOCK_CITIES, (city: string) => {
          ListItem() {
            Row({ space: 8 }) {
              Text(city === this.currentCity ? '✓' : '')
                .fontSize(16)
                .fontColor($r('app.color.color_primary'))
                .width(24)
              Text(city)
                .fontSize(15)
                .fontColor(city === this.currentCity ? $r('app.color.color_primary') : $r('app.color.color_text_primary'))
                .layoutWeight(1)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .onClick(() => {
              this.onCitySelect(city);
            })
          }
        }, (city: string) => city)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
  }

  /** 底部滑动面板（默认40%，上滑80%，下滑20%） */
  @Builder
  BottomPanel() {
    Column({ space: 0 }) {
      // 拖动条
      Column() {
        Row()
          .width(36)
          .height(4)
          .borderRadius(2)
          .backgroundColor($r('app.color.color_divider'))
      }
      .width('100%')
      .height(20)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        // 点击拖动条切换展开/收起
        if (this.panelHeightRatio === 0.4) {
          this.onPanelDrag('expand');
        } else if (this.panelHeightRatio === 0.8) {
          this.onPanelDrag('collapse');
        } else {
          this.onPanelDrag('normal');
        }
      })

      // 标题栏
      Row({ space: 8 }) {
        Text(`推荐点位 (${this.poiList.length})`)
          .fontSize(15)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text(this.panelHeightRatio === 0.8 ? '收起' : '展开')
          .fontSize(12)
          .fontColor($r('app.color.color_primary'))
          .onClick(() => {
            this.onPanelDrag(this.panelHeightRatio === 0.8 ? 'normal' : 'expand');
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })

      // POI 列表
      List({ space: 8 }) {
        ForEach(this.poiList, (poi: PoiInfo) => {
          ListItem() {
            this.PoiListRow(poi)
          }
        }, (poi: PoiInfo) => poi.poiId)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 16, right: 16, bottom: 24 })
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height(`${(this.panelHeightRatio * 100).toFixed(0)}%`)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius({ topLeft: 16, topRight: 16 })
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.1)', offsetX: 0, offsetY: -2 })
    .position({ left: 0, bottom: 0 })
    .animation({ duration: 300, curve: Curve.EaseInOut })
  }

  /** POI 列表项 */
  @Builder
  PoiListRow(poi: PoiInfo) {
    Row({ space: 12 }) {
      // 点位图
      Stack({ alignContent: Alignment.TopStart }) {
        Image(ImageUtil.get(poi.images.length > 0 ? poi.images[0] : 'prod_fruit_1'))
          .width(72)
          .height(72)
          .borderRadius(12)
          .objectFit(ImageFit.Cover)
        if (poi.isFeatured) {
          Text('精选')
            .fontSize(9)
            .fontColor(Color.White)
            .backgroundColor($r('app.color.color_secondary'))
            .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            .borderRadius({ topLeft: 12, bottomRight: 8 })
        }
      }
      .width(72)
      .height(72)

      // 信息区
      Column({ space: 4 }) {
        Row({ space: 4 }) {
          Text(getPoiCategoryIcon(poi.category))
            .fontSize(12)
          Text(poi.name)
            .fontSize(14)
            .fontColor($r('app.color.color_text_primary'))
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .alignItems(VerticalAlign.Center)

        // 评分 + 人均 + 距离
        Row({ space: 8 }) {
          Row({ space: 2 }) {
            Text('⭐')
              .fontSize(11)
            Text(poi.rating.toFixed(1))
              .fontSize(12)
              .fontColor($r('app.color.color_accent_gold'))
              .fontWeight(FontWeight.Bold)
          }
          .alignItems(VerticalAlign.Center)
          Text(`¥${poi.avgPrice}/人`)
            .fontSize(11)
            .fontColor($r('app.color.color_text_secondary'))
          Text(this.formatDistance(poi.distance))
            .fontSize(11)
            .fontColor($r('app.color.color_text_secondary'))
        }
        .alignItems(VerticalAlign.Center)

        // 地址
        Text(poi.address)
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 选中态高亮 + 点击查看详情
      Column() {
        Text('详情')
          .fontSize(12)
          .fontColor(this.selectedPoi && this.selectedPoi.poiId === poi.poiId ? Color.White : $r('app.color.color_primary'))
          .backgroundColor(this.selectedPoi && this.selectedPoi.poiId === poi.poiId ? $r('app.color.color_primary') : 'rgba(76,175,80,0.1)')
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .borderRadius(10)
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .borderRadius(12)
    .backgroundColor(this.selectedPoi && this.selectedPoi.poiId === poi.poiId ? 'rgba(76,175,80,0.06)' : $r('app.color.color_bg_page'))
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.onPoiSelect(poi);
    })
  }

  /** 格式化距离 */
  private formatDistance(distance: number): string {
    if (distance >= 1000) {
      return `${(distance / 1000).toFixed(1)}km`;
    }
    return `${distance}m`;
  }
}

/** 底部面板拖动状态 */
type PanelDragState = 'expand' | 'normal' | 'collapse';
