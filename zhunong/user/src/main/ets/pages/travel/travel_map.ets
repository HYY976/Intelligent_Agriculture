/**
 * travel_map - 文旅地图页（spec 3.1.4.3 / 2.4.6.4）
 * 对齐设计稿 pages/travel-map.html：
 *  - 全屏地图底（CSS 模拟：浅绿渐变 + SVG 道路/河流装饰）
 *  - 顶部渐隐遮罩（保白字状态栏可读）
 *  - POI Marker 层（黄色定位针 SVG + 选中态脉冲圆点）
 *  - 右侧悬浮按钮（定位 + 图层）
 *  - 顶栏浮层（圆形半透明返回键 + 白色胶囊搜索栏）
 *  - 分类筛选条（横向滚动胶囊：全部/农庄/民宿/景点/采摘园/市集，黄色选中态）
 *  - 底部上拉面板（白色圆角 24 + 拖动条 + 标题/计数 + 横滑 POI 卡片）
 *
 * 百度地图 SDK 集成点（Phase 6）：
 *   1) user/oh-package.json5 添加 "@bdmap/map": "^x.x.x" 等依赖
 *   2) 将 MockMapView 替换为 MapComponent({ mapType: MapType.MAP_TYPE_NORMAL })
 *   3) 将 getMockPoiList 替换为 PoiSearch.requestAsyncSearch
 *   4) POI Marker 改用 MarkerOptions.position(LatLng)
 *   5) 信息窗改用 mapController.showPopView(PopInfoOptions)
 */

import { RouteName, NavigationHelper, Logger, AppConstants, ToastUtil, ConfigUtil } from 'common';
import { PoiInfo, PoiCategory, PoiListParam, PoiListResult, getPoiCategoryLabel } from '../../model/TravelModels';
import { getMockPoiList } from '../../mock/TravelMock';
import { ImageUtil } from '../../utils/ImageUtil';

/** 跳转 POI 详情的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface PoiDetailParam {
  poiId: string;
}

/** 分类筛选 Chip 配置项（对齐设计稿 map-chip 6 项） */
interface CategoryChipConfig {
  /** chip 标签 */
  label: string;
  /** 对应 POI 分类（null 表示"全部"） */
  category: PoiCategory | null;
}

@ComponentV2
export struct TravelMap {
  /** POI 列表（对齐设计稿 6 条 POI Marker + 卡片） */
  @Local poiList: PoiInfo[] = [];
  /** 当前选中的 POI（用于地图 Marker 高亮 + 信息窗） */
  @Local selectedPoiId: string = '';
  /** 当前类型筛选（对齐设计稿 map-chip is-active） */
  @Local currentCategory: PoiCategory | null = null;
  /** 当前搜索关键字 */
  @Local searchKeyword: string = '';
  /** 6 类分类筛选（对齐设计稿：全部/农庄/民宿/景点/采摘园/市集） */
  @Local categoryChips: CategoryChipConfig[] = [];
  /** 画布宽度（px，用于将归一化坐标乘以实际尺寸） */
  @Local canvasWidth: number = 360;
  /** 画布高度（px） */
  @Local canvasHeight: number = 640;

  async aboutToAppear(): Promise<void> {
    this.categoryChips = this.buildCategoryChips();
    await this.refreshPoiList();
    // 默认选中第一个 POI（脉冲高亮）
    if (this.poiList.length > 0) {
      this.selectedPoiId = this.poiList[0].poiId;
    }
    Logger.info(AppConstants.SCENE_USER, {
      action: 'travel_map_appear',
      count: this.poiList.length
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

  /** 点击地图 Marker / 列表卡片 → 选中 + 高亮 */
  private onPoiSelect(poi: PoiInfo): void {
    this.selectedPoiId = poi.poiId;
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

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        // ===== 1. 全屏地图底（Mock 自绘） =====
        this.MapBackground()

        // ===== 2. POI Marker 层 =====
        this.PoiMarkerLayer()

        // ===== 3. 右侧悬浮按钮（定位/图层） =====
        this.SideButtons()

        // ===== 4. 顶部渐隐遮罩（保白字状态栏可读） =====
        this.TopScrim()

        // ===== 5. 顶栏浮层：返回 + 搜索栏 =====
        this.TopBar()

        // ===== 6. 分类筛选条 =====
        this.CategoryFilterBar()

        // ===== 7. 底部上拉面板 =====
        this.BottomSheet()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 全屏地图底（CSS 模拟：浅绿渐变 + 道路 + 区块，对齐设计稿 .map-bg + SVG） */
  @Builder
  MapBackground() {
    Stack() {
      // 浅绿渐变底
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [['#EAF7D8', 0], ['#F0F7E8', 1]]
        })

      // 模拟区域色块（田地/林地，对齐设计稿 ellipse）
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 135,
          colors: [
            ['rgba(126,211,33,0.14)', 0],
            ['rgba(255,226,52,0.10)', 0.4],
            ['rgba(126,211,33,0.12)', 0.7],
            ['rgba(255,226,52,0.08)', 1]
          ]
        })

      // 模拟道路（白色粗线 + 浅灰描边）
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 0,
          colors: [['rgba(255,255,255,0.6)', 0], ['rgba(255,255,255,0)', 0.3]]
        })
    }
    .width('100%')
    .height('100%')
  }

  /** 顶部渐隐遮罩（对齐设计稿 .map-scrim，150px 高度黑色渐隐） */
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

  /** POI Marker 层（对齐设计稿 6 个 .poi-pin 黄色定位针） */
  @Builder
  PoiMarkerLayer() {
    ForEach(this.poiList, (poi: PoiInfo) => {
      this.PoiMarker(poi)
    }, (poi: PoiInfo) => poi.poiId)
  }

  /** 单个 POI Marker（黄色定位针 + 选中态脉冲圆点 + 名称气泡） */
  @Builder
  PoiMarker(poi: PoiInfo) {
    Stack() {
      // 选中态：底部脉冲圆点（绿色扩散，对齐设计稿 .poi-pulse）
      if (this.selectedPoiId === poi.poiId) {
        Column()
          .width(12)
          .height(12)
          .borderRadius(6)
          .backgroundColor('rgba(126,211,33,0.55)')
          .position({ x: '50%', y: '100%' })
          .markAnchor({ x: '50%', y: '50%' })
      }

      // 选中态：名称气泡（黑底白字，对齐设计稿 qn-msg-tag 风格）
      if (this.selectedPoiId === poi.poiId) {
        Text(poi.name)
          .fontSize(11)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
          .backgroundColor($r('app.color.color_ink'))
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(AppConstants.RADIUS_PILL)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .position({ x: '50%', y: -8 })
          .markAnchor({ x: '50%', y: '100%' })
      }

      // 黄色定位针 SVG（对齐设计稿 path + 黑色圆心）
      Column() {
        // 用 Column + 圆形模拟定位针上半部分（黄色圆）
        Column()
          .width(30)
          .height(30)
          .borderRadius(15)
          .backgroundColor($r('app.color.color_yellow'))
          .border({ width: 1.2, color: '#E6C200' })
          .shadow({ radius: 4, color: 'rgba(26,26,26,0.28)', offsetX: 0, offsetY: 3 })

        // 定位针下半部分（黑色小圆心）
        Column()
          .width(11)
          .height(11)
          .borderRadius(5.5)
          .backgroundColor($r('app.color.color_ink'))
          .position({ x: '50%', y: 9 })
          .markAnchor({ x: '50%', y: '50%' })
      }
      .width(30)
      .height(30)
    }
    .width(30)
    .height(38)
    .position({
      x: `${(poi.coordinate.x * 100).toFixed(2)}%`,
      y: `${(poi.coordinate.y * 100).toFixed(2)}%`
    })
    .markAnchor({ x: '50%', y: '100%' })
    .onClick(() => {
      this.onPoiSelect(poi);
    })
  }

  /** 右侧悬浮按钮组（定位 + 图层，对齐设计稿 .map-side） */
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
    .position({ right: 16, bottom: 296 })
  }

  /** 顶栏浮层（对齐设计稿 .map-topbar：返回 + 搜索栏） */
  @Builder
  TopBar() {
    Row({ space: 10 }) {
      // 返回按钮（圆形半透明白底 + 阴影，对齐设计稿 .map-back）
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

      // 搜索栏（白色胶囊 + 阴影，对齐设计稿 .map-search）
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

  /** 分类筛选条（对齐设计稿 .map-filter：横向滚动 6 胶囊） */
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

  /** 底部上拉面板（对齐设计稿 .map-sheet：圆角 24 白底 + 拖动条 + 标题 + 横滑卡片） */
  @Builder
  BottomSheet() {
    Column({ space: 0 }) {
      // 拖动条（对齐设计稿 .map-handle 40×4 圆角灰）
      Row()
        .width(40)
        .height(4)
        .borderRadius(2)
        .backgroundColor($r('app.color.color_line_2'))
        .margin({ top: 14, bottom: 14 })

      // 标题栏（对齐设计稿 .map-sheet-head：附近农庄 + N个结果）
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

      // 横滑 POI 卡片列表（对齐设计稿 .poi-list）
      Scroll() {
        Row({ space: 10 }) {
          ForEach(this.poiList, (poi: PoiInfo) => {
            this.PoiCard(poi)
          }, (poi: PoiInfo) => poi.poiId)
        }
        .padding({ left: 16, right: 16, bottom: 24 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius({ topLeft: AppConstants.RADIUS_XL, topRight: AppConstants.RADIUS_XL })
    .shadow({ radius: 20, color: 'rgba(26,26,26,0.08)', offsetX: 0, offsetY: -4 })
    .position({ left: 0, bottom: 0 })
  }

  /** POI 卡片（对齐设计稿 .poi-card 240 宽：图 100 高 + 名 + 黄色 pill 标签 + 评分/距离/价格） */
  @Builder
  PoiCard(poi: PoiInfo) {
    Column({ space: 0 }) {
      // 顶部图片（100 高，对齐设计稿 .poi-card-img）
      Image(ImageUtil.get(poi.images.length > 0 ? poi.images[0] : 'farm_picking'))
        .width('100%')
        .height(100)
        .borderRadius({ topLeft: AppConstants.RADIUS_MD, topRight: AppConstants.RADIUS_MD })
        .objectFit(ImageFit.Cover)
        .backgroundColor($r('app.color.color_fill'))

      // 内容区（对齐设计稿 .poi-card-body）
      Column({ space: 6 }) {
        // 名称（对齐设计稿 .poi-card-name）
        Text(poi.name)
          .fontSize(15)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 分类标签（对齐设计稿 .poi-card-tags → qn-pill qn-pill-yellow）
        Text(getPoiCategoryLabel(poi.category))
          .fontSize(11)
          .fontColor($r('app.color.color_yellow_text'))
          .fontWeight(FontWeight.Bold)
          .padding({ left: 10, right: 10, top: 3, bottom: 3 })
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_yellow_soft'))

        // 元信息行：评分 + 距离 + 价格（对齐设计稿 .poi-card-meta）
        Row({ space: 8 }) {
          // 评分
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

          // 距离
          Text(this.formatDistance(poi.distance))
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))

          // 价格（右对齐，红色，对齐设计稿 .poi-price）
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

  /** 格式化距离（米 → km，对齐设计稿 "2.3km"） */
  private formatDistance(distance: number): string {
    if (distance >= 1000) {
      return `${(distance / 1000).toFixed(1)}km`;
    }
    return `${distance}m`;
  }
}
