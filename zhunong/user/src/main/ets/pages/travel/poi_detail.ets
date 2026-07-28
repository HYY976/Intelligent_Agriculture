/**
 * poi_detail - POI 点位详情页（spec 3.1.4.3）
 * 对齐设计稿 pages/poi-detail.html：
 *  - 顶部图片轮播 240 高 + 状态栏白字叠图
 *  - 左上返回键 + 右上收藏键（圆形 82% 白底 + 模糊，对齐设计稿 qn-poi-circle-btn）
 *  - 右下图片索引指示器（黑底白字胶囊，如 1/4）
 *  - 中部 Scroll 内容区（向上覆盖图片 8px + 圆角 24 顶部）：
 *    1) 名称区：黄色 pill 分类 + 绿色 pill 智农推荐 + 20px 加粗标题
 *    2) 评分行：★ 4.8 · 128条评价 · 人均¥88 · 距您2.3km
 *    3) 信息卡（3 行）：地址(黄)/电话(绿)/营业时间(蓝)，每行 30×30 彩色图标
 *    4) 简介卡：标题 + 多段简介文字
 *  - 底部固定操作栏：电话(白底描边) + 导航前往(墨黑底白字)
 *
 * 导航按钮调起百度地图客户端或步骑行导航（后续迭代，现阶段 Toast 提示）
 */

import { RouteName, NavigationHelper, Logger, AppConstants, ToastUtil } from 'common';
import { PoiInfo, getPoiCategoryLabel } from '../../model/TravelModels';
import { getMockPoiById } from '../../mock/TravelMock';
import { ImageUtil } from '../../utils/ImageUtil';

/** 跳转体验预约页的路由参数 */
interface BookingParam {
  poiId: string;
}

@ComponentV2
export struct PoiDetail {
  /** POI ID */
  @Local poiId: string = '';
  /** POI 详情 */
  @Local poi: PoiInfo | null = null;
  /** 当前轮播图索引（对齐设计稿 qn-poi-index "1/4"） */
  @Local currentImageIndex: number = 0;
  /** 是否已收藏 */
  @Local isFavorited: boolean = false;

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
    Logger.info(AppConstants.SCENE_USER, {
      action: 'poi_detail_view',
      poiId: this.poiId
    });
  }

  /** 返回 */
  private goBack(): void {
    NavigationHelper.pop();
  }

  /** 拨打电话 */
  private onCall(): void {
    if (this.poi) {
      ToastUtil.info(`拨打 ${this.poi.phone}（开发中）`);
      Logger.info(AppConstants.SCENE_USER, {
        action: 'poi_call',
        poiId: this.poiId
      });
    }
  }

  /** 导航 */
  private onNavigate(): void {
    if (this.poi) {
      ToastUtil.info(`导航至 ${this.poi.name}（开发中）`);
      Logger.info(AppConstants.SCENE_USER, {
        action: 'poi_navigate',
        poiId: this.poiId
      });
    }
  }

  /** 收藏 */
  private onFavorite(): void {
    this.isFavorited = !this.isFavorited;
    ToastUtil.success(this.isFavorited ? '已收藏该点位' : '已取消收藏');
    Logger.info(AppConstants.SCENE_USER, {
      action: 'poi_favorite',
      poiId: this.poiId,
      favorited: this.isFavorited
    });
  }

  /** 跳转体验预约页（对齐设计稿 POI 详情底部"立即预约"扩展入口） */
  private gotoBooking(): void {
    if (this.poi && this.poi.bookable) {
      const param: BookingParam = { poiId: this.poiId };
      NavigationHelper.push(RouteName.USER_BOOKING, param);
    } else {
      ToastUtil.info('该点位暂未开放预约');
    }
  }

  build() {
    NavDestination() {
      Column() {
        if (this.poi) {
          // 顶部图片轮播
          this.ImageCarousel(this.poi)
          // 内容区
          Scroll() {
            Column({ space: 12 }) {
              this.NameSection(this.poi)
              this.RatingRow(this.poi)
              this.InfoCard(this.poi)
              this.IntroCard(this.poi)
              if (this.poi.bookable) {
                this.BookingEntryCard(this.poi)
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor($r('app.color.color_bg_page'))
            .borderRadius({ topLeft: AppConstants.RADIUS_XL, topRight: AppConstants.RADIUS_XL })
            .margin({ top: -8 })
            .alignItems(HorizontalAlign.Start)
          }
          .layoutWeight(1)
          .width('100%')
          .scrollBar(BarState.Off)
          // 底部固定操作栏
          this.BottomActionBar(this.poi)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 顶部图片轮播（对齐设计稿 .qn-poi-carousel 240 高） */
  @Builder
  ImageCarousel(poi: PoiInfo) {
    Stack({ alignContent: Alignment.TopStart }) {
      Swiper() {
        ForEach(poi.images, (imgKey: string) => {
          Image(ImageUtil.get(imgKey))
            .width('100%')
            .height(240)
            .objectFit(ImageFit.Cover)
            .backgroundColor($r('app.color.color_fill'))
        }, (imgKey: string) => imgKey)
      }
      .indicator(false)
      .loop(true)
      .width('100%')
      .height(240)
      .onChange((index: number) => {
        this.currentImageIndex = index;
      })

      // 顶部渐隐遮罩（增强返回按钮可读性，对齐设计稿状态栏叠图）
      Column()
        .width('100%')
        .height(100)
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [['rgba(0,0,0,0.30)', 0], ['rgba(0,0,0,0)', 1]]
        })

      // 左上返回按钮（对齐设计稿 .qn-poi-circle-btn.qn-poi-back）
      Row() {
        Text('‹')
          .fontSize(22)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .width(36)
      .height(36)
      .borderRadius(18)
      .backgroundColor('rgba(255,255,255,0.82)')
      .shadow({ radius: 8, color: 'rgba(26,26,26,0.18)', offsetX: 0, offsetY: 2 })
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .position({ left: 16, top: 52 })
      .onClick(() => { this.goBack(); })

      // 右上收藏按钮（对齐设计稿 .qn-poi-circle-btn.qn-poi-fav）
      Row() {
        Text(this.isFavorited ? '♥' : '♡')
          .fontSize(20)
          .fontColor(this.isFavorited ? $r('app.color.color_live') : $r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .width(36)
      .height(36)
      .borderRadius(18)
      .backgroundColor('rgba(255,255,255,0.82)')
      .shadow({ radius: 8, color: 'rgba(26,26,26,0.18)', offsetX: 0, offsetY: 2 })
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .position({ right: 16, top: 52 })
      .onClick(() => { this.onFavorite(); })

      // 右下图片索引指示器（对齐设计稿 .qn-poi-index "1/4"）
      Text(`${this.currentImageIndex + 1}/${poi.images.length}`)
        .fontSize(11)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .backgroundColor('rgba(26,26,26,0.55)')
        .padding({ left: 10, right: 10, top: 3, bottom: 3 })
        .borderRadius(AppConstants.RADIUS_PILL)
        .position({ right: 12, bottom: 12 })
    }
    .width('100%')
    .height(240)
  }

  /** 名称区（对齐设计稿 .qn-poi-name-row + qn-poi-title） */
  @Builder
  NameSection(poi: PoiInfo) {
    Column({ space: 6 }) {
      // 标签行（黄色分类 + 绿色智农推荐）
      Row({ space: 6 }) {
        Text(getPoiCategoryLabel(poi.category))
          .fontSize(11)
          .fontColor($r('app.color.color_yellow_text'))
          .fontWeight(FontWeight.Bold)
          .padding({ left: 10, right: 10, top: 3, bottom: 3 })
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_yellow_soft'))

        if (poi.isFeatured) {
          Text('智农推荐')
            .fontSize(11)
            .fontColor($r('app.color.color_green_deep'))
            .fontWeight(FontWeight.Bold)
            .padding({ left: 10, right: 10, top: 3, bottom: 3 })
            .borderRadius(AppConstants.RADIUS_PILL)
            .backgroundColor($r('app.color.color_green_soft'))
        }
      }
      .alignItems(VerticalAlign.Center)

      // 名称标题（20px 加粗）
      Text(poi.name)
        .fontSize(20)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .lineHeight(26)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /** 评分行（对齐设计稿 .qn-poi-meta：★ 4.8 · 128条评价 · 人均¥88 · 距您2.3km） */
  @Builder
  RatingRow(poi: PoiInfo) {
    Row({ space: 6 }) {
      // 黄色星
      Text('★')
        .fontSize(14)
        .fontColor($r('app.color.color_yellow_deep'))
      // 评分（加粗黑色）
      Text(poi.rating.toFixed(1))
        .fontSize(13)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
      // 评价数
      Text(`${poi.ratingCount}条评价`)
        .fontSize(13)
        .fontColor($r('app.color.color_text_3'))
      // 分隔点
      Text('·')
        .fontSize(13)
        .fontColor($r('app.color.color_text_4'))
      // 人均价格（红色加粗）
      Text(`人均 ¥${poi.avgPrice}`)
        .fontSize(13)
        .fontColor($r('app.color.color_live'))
        .fontWeight(FontWeight.Bold)
      // 分隔点
      Text('·')
        .fontSize(13)
        .fontColor($r('app.color.color_text_4'))
      // 距离
      Text(`距您${this.formatDistance(poi.distance)}`)
        .fontSize(13)
        .fontColor($r('app.color.color_text_3'))
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  /** 信息卡（对齐设计稿 .qn-poi-info-card：3 行彩色图标信息） */
  @Builder
  InfoCard(poi: PoiInfo) {
    Column({ space: 0 }) {
      // 地址行（黄色图标底）
      this.InfoRow('📍', 'qn-ico-yellow', `${poi.city} · ${poi.district} · ${poi.address}`)
      // 分割线
      Divider().color($r('app.color.color_line')).width('100%')
      // 电话行（绿色图标底）
      this.InfoRow('📞', 'qn-ico-green', poi.phone)
      // 分割线
      Divider().color($r('app.color.color_line')).width('100%')
      // 营业时间行（蓝色图标底）
      this.InfoRow('🕐', 'qn-ico-blue', poi.businessHours)
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 信息行（对齐设计稿 .qn-poi-info-row：30×30 彩色图标 + 文字） */
  @Builder
  InfoRow(icon: string, iconTheme: string, text: string) {
    Row({ space: 12 }) {
      // 彩色图标底（30×30 圆角 10）
      Row() {
        Text(icon)
          .fontSize(15)
          .fontColor(this.getIconThemeColor(iconTheme))
      }
      .width(30)
      .height(30)
      .borderRadius(AppConstants.RADIUS_SM)
      .backgroundColor(this.getIconThemeBg(iconTheme))
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      // 文字
      Text(text)
        .fontSize(14)
        .fontColor($r('app.color.color_ink_2'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height(48)
    .alignItems(VerticalAlign.Center)
  }

  /** 简介卡（对齐设计稿 .qn-card 简介区：标题 + 多段文字） */
  @Builder
  IntroCard(poi: PoiInfo) {
    Column({ space: 10 }) {
      Text('农庄简介')
        .fontSize(16)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)

      // 简介按 \n 分段，每段独立 Text（对齐设计稿 .qn-poi-intro-text 段间距 8）
      ForEach(this.splitIntro(poi.intro), (paragraph: string, idx: number) => {
        Text(paragraph)
          .fontSize(14)
          .fontColor($r('app.color.color_ink_2'))
          .lineHeight(24)
      }, (paragraph: string, idx: number) => `${idx}_${paragraph.substring(0, 8)}`)
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 预约入口卡（对齐设计稿扩展：仅 bookable POI 显示，提供跳转预约页入口） */
  @Builder
  BookingEntryCard(poi: PoiInfo) {
    Row({ space: 12 }) {
      Column({ space: 4 }) {
        Text('体验预约')
          .fontSize(15)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        Text(`¥${poi.avgPrice}/人起 · 在线预订`)
          .fontSize(12)
          .fontColor($r('app.color.color_text_3'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 立即预约按钮（黄色胶囊）
      Row() {
        Text('立即预约')
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .height(40)
      .padding({ left: 18, right: 18 })
      .borderRadius(AppConstants.RADIUS_MD)
      .backgroundColor($r('app.color.color_yellow'))
      .shadow(AppConstants.SHADOW_YELLOW)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { this.gotoBooking(); })
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(VerticalAlign.Center)
  }

  /** 底部固定操作栏（对齐设计稿 .qn-poi-actionbar：电话 + 导航前往） */
  @Builder
  BottomActionBar(poi: PoiInfo) {
    Row({ space: 12 }) {
      // 电话按钮（白底描边）
      Row({ space: 6 }) {
        Text('📞')
          .fontSize(16)
        Text('电话')
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .height(48)
      .padding({ left: 18, right: 18 })
      .borderRadius(AppConstants.RADIUS_MD)
      .backgroundColor($r('app.color.color_bg_card'))
      .border({ width: 1, color: $r('app.color.color_line_2') })
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { this.onCall(); })

      // 导航按钮（墨黑底白字，主操作）
      Row({ space: 8 }) {
        Text('🧭')
          .fontSize(18)
        Text('导航前往')
          .fontSize(16)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
      }
      .layoutWeight(1)
      .height(48)
      .borderRadius(AppConstants.RADIUS_MD)
      .backgroundColor($r('app.color.color_ink'))
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { this.onNavigate(); })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 32 })
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_NAV)
    .alignItems(VerticalAlign.Center)
  }

  /** 图标主题色 → 文字色（对齐设计稿 .qn-ico-yellow/green/blue） */
  private getIconThemeColor(theme: string): ResourceColor {
    switch (theme) {
      case 'qn-ico-yellow':
        return $r('app.color.color_yellow_text');
      case 'qn-ico-green':
        return $r('app.color.color_green_deep');
      case 'qn-ico-blue':
        return $r('app.color.color_info');
      default:
        return $r('app.color.color_ink');
    }
  }

  /** 图标主题色 → 背景色（对齐设计稿 .qn-ico-yellow/green/blue） */
  private getIconThemeBg(theme: string): ResourceColor {
    switch (theme) {
      case 'qn-ico-yellow':
        return $r('app.color.color_yellow_soft');
      case 'qn-ico-green':
        return $r('app.color.color_green_soft');
      case 'qn-ico-blue':
        return $r('app.color.color_info_soft');
      default:
        return $r('app.color.color_fill');
    }
  }

  /** 简介按 \n 分段（对齐设计稿多段 .qn-poi-intro-text） */
  private splitIntro(intro: string): string[] {
    return intro.split('\n');
  }

  /** 格式化距离（米 → km） */
  private formatDistance(distance: number): string {
    if (distance >= 1000) {
      return `${(distance / 1000).toFixed(1)}km`;
    }
    return `${distance}m`;
  }
}
