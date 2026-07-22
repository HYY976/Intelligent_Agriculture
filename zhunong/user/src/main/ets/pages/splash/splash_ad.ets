/**
 * splash_ad - 开屏广告页（spec 3.1.2.2）
 * 功能：
 *  - 冷启动展示开屏广告（Phase 2 使用 MOCK_SPLASH_ADS 本地 Mock）
 *  - 展示时长 5 秒，5秒内出现"跳过 Xs"按钮可点击跳过
 *  - 双榜#1同时获得时，Swiper 左右滑动展示两个海报
 *  - 点击广告跳转对应商品详情页（商品榜）或直播间（直播榜，Phase 3 占位）
 *  - 兜底：无广告记录 → 直接进入登录或首页
 */

import { Logger, AppConstants, TokenStore, UserRoutes, RouteName, NavigationHelper } from 'common';
import { SplashAd } from '../../model/SearchModels';
import { MOCK_SPLASH_ADS } from '../../mock/SearchMock';
import { ImageUtil } from '../../utils/ImageUtil';

/** 跳转商品详情的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface ProductDetailParam {
  productId: string;
}

@ComponentV2
export struct SplashAdPage {
  /** 广告列表（双榜#1最多2条） */
  @Local adList: SplashAd[] = MOCK_SPLASH_ADS;
  /** 当前展示的广告索引 */
  @Local currentIndex: number = 0;
  /** 倒计时剩余秒数（spec 3.1.2.2：5秒） */
  @Local countdownSec: number = AppConstants.SPLASH_DISPLAY_MS / 1000;
  /** 是否已展示完广告 */
  @Local adFinished: boolean = false;
  /** 倒计时定时器 */
  private countdownTimerId: number | undefined = undefined;

  async aboutToAppear(): Promise<void> {
    Logger.info(AppConstants.SCENE_USER, JSON.stringify({ action: 'splash_ad_appear', adCount: this.adList.length }));
    if (this.adList.length > 0) {
      this.startCountdown();
    } else {
      await this.navigateToNext();
    }
  }

  aboutToDisappear(): void {
    if (this.countdownTimerId !== undefined) {
      clearInterval(this.countdownTimerId);
      this.countdownTimerId = undefined;
    }
  }

  /** 启动 5 秒倒计时（spec 3.1.2.2） */
  private startCountdown(): void {
    this.countdownSec = AppConstants.SPLASH_DISPLAY_MS / 1000;
    this.countdownTimerId = setInterval(() => {
      this.countdownSec -= 1;
      if (this.countdownSec <= 0) {
        if (this.countdownTimerId !== undefined) {
          clearInterval(this.countdownTimerId);
          this.countdownTimerId = undefined;
        }
        this.navigateToNext();
      }
    }, 1000);
  }

  /** 跳过广告 */
  private async skipAd(): Promise<void> {
    if (this.countdownTimerId !== undefined) {
      clearInterval(this.countdownTimerId);
      this.countdownTimerId = undefined;
    }
    await this.navigateToNext();
  }

  /** 点击广告跳转（spec 3.1.2.2：跳转对应商品详情页或直播间） */
  private async clickAd(ad: SplashAd): Promise<void> {
    if (this.countdownTimerId !== undefined) {
      clearInterval(this.countdownTimerId);
      this.countdownTimerId = undefined;
    }
    Logger.info(AppConstants.SCENE_USER, JSON.stringify({ action: 'splash_ad_click', adId: ad.adId, rankType: ad.rankType }));

    // 跳过广告后判断登录态
    const isLoggedIn: boolean = await TokenStore.isLoggedIn();
    if (!isLoggedIn) {
      NavigationHelper.replace(RouteName.USER_LOGIN);
      return;
    }

    // 已登录：根据榜单类型跳转
    if (ad.rankType === 'product') {
      // 商品榜#1 → 跳转商品详情
      const param: ProductDetailParam = { productId: ad.targetId };
      NavigationHelper.replace(RouteName.USER_PRODUCT_DETAIL, param);
    } else {
      // 直播榜#1 → 跳转直播间（Phase 3 实现，暂跳首页）
      Logger.info(AppConstants.SCENE_USER, JSON.stringify({ action: 'goto_live_placeholder', liveId: ad.targetId }));
      NavigationHelper.replace(RouteName.USER_HOME);
    }
  }

  /** 进入下一步：登录页 或 首页 */
  private async navigateToNext(): Promise<void> {
    if (this.adFinished) {
      return;
    }
    this.adFinished = true;
    const isLoggedIn: boolean = await TokenStore.isLoggedIn();
    if (isLoggedIn) {
      NavigationHelper.replace(RouteName.USER_HOME);
    } else {
      NavigationHelper.replace(RouteName.USER_LOGIN);
    }
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.TopEnd }) {
        if (this.adList.length === 0) {
          // 无广告时展示品牌主视觉（生机绿背景 + 麦穗图标）
          Column({ space: 12 }) {
            Text('🌾')
              .fontSize(120)
            Text('助农')
              .fontSize(32)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
            Text('清新自然 · 助农全面融入')
              .fontSize(14)
              .fontColor(Color.White)
              .opacity(0.8)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .backgroundColor($r('app.color.color_primary'))
        } else if (this.adList.length === 1) {
          // 单广告展示
          this.SplashAdView(this.adList[0])
        } else {
          // 双榜#1：Swiper 左右滑动展示两个海报（spec 3.1.2.2 ViewPager 效果）
          Swiper() {
            ForEach(this.adList, (ad: SplashAd, index: number) => {
              this.SplashAdView(ad)
            }, (ad: SplashAd, index: number) => ad.adId)
          }
          .index(this.currentIndex)
          .indicator(true)
          .loop(false)
          .duration(300)
          .onChange((index: number) => {
            this.currentIndex = index;
          })
        }

        // 右上角跳过按钮（始终可见，倒计时秒数）
        if (this.adList.length > 0) {
          Button(this.countdownSec > 0 ? `跳过 ${this.countdownSec}s` : '跳过')
            .fontSize(12)
            .fontColor(Color.White)
            .backgroundColor('rgba(0,0,0,0.5)')
            .borderRadius(20)
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .margin({ right: 16, top: 48 })
            .onClick(() => {
              this.skipAd();
            })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#000000')
    }
    .hideTitleBar(true)
  }

  /** 单个广告海报视图（spec 3.1.2.2：海报 + 肩带"月热销#1" + 卖家/标题兜底） */
  @Builder
  SplashAdView(ad: SplashAd) {
    Stack({ alignContent: Alignment.TopStart }) {
      // 海报图（使用 ImageUtil 解析本地 SVG 资源）
      Image(ImageUtil.get(ad.posterUrl))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .onClick(() => {
          this.clickAd(ad);
        })

      // 肩带"月热销#1"（spec 3.1.2.2）
      Text(ad.badge)
        .fontSize(14)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.color_secondary'))
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .borderRadius(4)
        .margin({ left: 16, top: 80 })

      // 底部卖家 + 标题兜底信息
      Column({ space: 4 }) {
        Text(ad.title)
          .fontSize(18)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
        Text(ad.sellerName)
          .fontSize(12)
          .fontColor(Color.White)
          .opacity(0.85)
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 64 })
      .alignItems(HorizontalAlign.Start)
      .position({ x: 0, y: '85%' })
    }
    .width('100%')
    .height('100%')
  }
}
