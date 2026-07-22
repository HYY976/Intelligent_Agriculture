/**
 * poi_detail - POI 点位详情页（spec 3.1.4.3）
 * 大图轮播 + 名称 + 评分 + 地址 + 电话 + 营业时间 + 介绍 + 导航按钮
 * 导航按钮调起百度地图客户端或步骑行导航（后续迭代，现阶段 Toast 提示）
 */

import { RouteName, NavigationHelper, Logger, AppConstants, ToastUtil } from 'common';
import { PoiInfo, getPoiCategoryLabel, getPoiCategoryIcon } from '../../model/TravelModels';
import { getMockPoiById } from '../../mock/TravelMock';
import { ImageUtil } from '../../utils/ImageUtil';

@ComponentV2
export struct PoiDetail {
  /** POI ID */
  @Local poiId: string = '';
  /** POI 详情 */
  @Local poi: PoiInfo | null = null;
  /** 当前轮播图索引 */
  @Local currentImageIndex: number = 0;

  aboutToAppear(): void {
    const params: Record<string, string> = NavigationHelper.getParam<Record<string, string>>() as Record<string, string>;
    if (params) {
      this.poiId = params.poiId ?? '';
    }
    this.loadPoiDetail();
  }

  /** 加载 POI 详情 */
  private loadPoiDetail(): void {
    this.poi = getMockPoiById(this.poiId);
    if (!this.poi) {
      ToastUtil.error('点位不存在');
      NavigationHelper.pop();
      return;
    }
    Logger.info(AppConstants.SCENE_USER, { action: 'poi_detail_view', poiId: this.poiId });
  }

  /** 返回 */
  private goBack(): void {
    NavigationHelper.pop();
  }

  /** 拨打电话 */
  private onCall(): void {
    if (this.poi) {
      ToastUtil.info(`拨打 ${this.poi.phone}（开发中）`);
      Logger.info(AppConstants.SCENE_USER, { action: 'poi_call', poiId: this.poiId });
    }
  }

  /** 导航 */
  private onNavigate(): void {
    if (this.poi) {
      ToastUtil.info(`导航至 ${this.poi.name}（开发中）`);
      Logger.info(AppConstants.SCENE_USER, { action: 'poi_navigate', poiId: this.poiId });
    }
  }

  /** 收藏 */
  private onFavorite(): void {
    ToastUtil.success('已收藏该点位');
  }

  build() {
    NavDestination() {
      Column() {
        if (this.poi) {
          // 顶部图片轮播
          this.ImageCarousel(this.poi)
          // 内容区
          Scroll() {
            Column() {
              this.PoiInfoSection(this.poi)
              this.IntroSection(this.poi)
              this.ActionSection(this.poi)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }
          .layoutWeight(1)
          .width('100%')
          .scrollBar(BarState.Off)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 顶部图片轮播 */
  @Builder
  ImageCarousel(poi: PoiInfo) {
    Stack({ alignContent: Alignment.TopStart }) {
      Swiper() {
        ForEach(poi.images, (imgKey: string, idx: number) => {
          Image(ImageUtil.get(imgKey))
            .width('100%')
            .height(280)
            .objectFit(ImageFit.Cover)
        }, (imgKey: string) => imgKey)
      }
      .indicator(false)
      .loop(true)
      .width('100%')
      .height(280)
      .onChange((index: number) => {
        this.currentImageIndex = index;
      })

      // 渐变遮罩（顶部，增强返回按钮可读性）
      Column()
        .width('100%')
        .height(100)
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [['rgba(0,0,0,0.4)', 0], ['rgba(0,0,0,0)', 1]]
        })
        .position({ left: 0, top: 0 })

      // 返回按钮
      Text('←')
        .fontSize(24)
        .fontColor(Color.White)
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor('rgba(0,0,0,0.3)')
        .textAlign(TextAlign.Center)
        .position({ left: 12, top: 48 })
        .onClick(() => {
          this.goBack();
        })

      // 收藏按钮
      Text('☆')
        .fontSize(22)
        .fontColor(Color.White)
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor('rgba(0,0,0,0.3)')
        .textAlign(TextAlign.Center)
        .position({ right: 12, top: 48 })
        .onClick(() => {
          this.onFavorite();
        })

      // 图片索引指示器
      Text(`${this.currentImageIndex + 1}/${poi.images.length}`)
        .fontSize(11)
        .fontColor(Color.White)
        .backgroundColor('rgba(0,0,0,0.4)')
        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
        .borderRadius(10)
        .position({ right: 12, bottom: 12 })
    }
    .width('100%')
    .height(280)
  }

  /** POI 基础信息区 */
  @Builder
  PoiInfoSection(poi: PoiInfo) {
    Column({ space: 8 }) {
      // 类型标签 + 精选标签
      Row({ space: 6 }) {
        Text(`${getPoiCategoryIcon(poi.category)} ${getPoiCategoryLabel(poi.category)}`)
          .fontSize(11)
          .fontColor($r('app.color.color_primary'))
          .backgroundColor('rgba(76,175,80,0.1)')
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(10)
        if (poi.isFeatured) {
          Text('精选推荐')
            .fontSize(11)
            .fontColor($r('app.color.color_secondary'))
            .backgroundColor('rgba(255,152,0,0.1)')
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .borderRadius(10)
        }
      }
      .alignItems(VerticalAlign.Center)

      // 名称
      Text(poi.name)
        .fontSize(20)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Bold)

      // 评分 + 评分人数 + 人均
      Row({ space: 12 }) {
        Row({ space: 2 }) {
          Text('⭐')
            .fontSize(14)
          Text(poi.rating.toFixed(1))
            .fontSize(15)
            .fontColor($r('app.color.color_accent_gold'))
            .fontWeight(FontWeight.Bold)
        }
        .alignItems(VerticalAlign.Center)
        Text(`${poi.ratingCount} 条评价`)
          .fontSize(12)
          .fontColor($r('app.color.color_text_secondary'))
        Text(`人均 ¥${poi.avgPrice}`)
          .fontSize(12)
          .fontColor($r('app.color.color_price'))
          .fontWeight(FontWeight.Medium)
      }
      .alignItems(VerticalAlign.Center)

      // 分割线
      Divider()
        .color($r('app.color.color_divider'))
        .width('100%')

      // 地址
      this.InfoRow('📍', '地址', `${poi.city} · ${poi.district}\n${poi.address}`)
      // 电话
      this.InfoRow('📞', '电话', poi.phone)
      // 营业时间
      this.InfoRow('🕐', '营业时间', poi.businessHours)
      // 距离
      this.InfoRow('🗺️', '距离当前位置', this.formatDistance(poi.distance))
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius({ topLeft: 16, topRight: 16 })
    .margin({ top: -16 })
    .alignItems(HorizontalAlign.Start)
  }

  /** 信息行 */
  @Builder
  InfoRow(icon: string, label: string, value: string) {
    Row({ space: 12 }) {
      Text(icon)
        .fontSize(18)
        .width(24)
      Column({ space: 2 }) {
        Text(label)
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
        Text(value)
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Top)
  }

  /** 简介区 */
  @Builder
  IntroSection(poi: PoiInfo) {
    Column({ space: 8 }) {
      Text('点位介绍')
        .fontSize(15)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Bold)
      Text(poi.intro)
        .fontSize(13)
        .fontColor($r('app.color.color_text_secondary'))
        .lineHeight(22)
    }
    .width('100%')
    .padding(16)
    .margin({ top: 8 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(HorizontalAlign.Start)
  }

  /** 底部操作区 */
  @Builder
  ActionSection(poi: PoiInfo) {
    Row({ space: 12 }) {
      // 拨打电话
      Column({ space: 2 }) {
        Text('📞')
          .fontSize(22)
        Text('电话')
          .fontSize(11)
          .fontColor($r('app.color.color_text_secondary'))
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .width(72)
      .height(56)
      .borderRadius(12)
      .backgroundColor($r('app.color.color_bg_card'))
      .onClick(() => {
        this.onCall();
      })

      // 导航按钮（主操作）
      Row({ space: 6 }) {
        Text('🧭')
          .fontSize(18)
        Text('导航前往')
          .fontSize(15)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .layoutWeight(1)
      .height(56)
      .borderRadius(12)
      .backgroundColor($r('app.color.color_primary'))
      .onClick(() => {
        this.onNavigate();
      })
    }
    .width('100%')
    .padding(16)
    .margin({ top: 8, bottom: 32 })
    .alignItems(VerticalAlign.Center)
  }

  /** 格式化距离 */
  private formatDistance(distance: number): string {
    if (distance >= 1000) {
      return `${(distance / 1000).toFixed(1)}km`;
    }
    return `${distance}m`;
  }
}
