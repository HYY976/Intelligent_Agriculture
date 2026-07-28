/**
 * splash_ad - 卖家端开屏广告页
 * 遵循 spec 3.1.2.2 / 5.2：
 *  - 卖家端冷启动同样展示开屏广告（5秒倒计时 + 跳过按钮）
 *  - 双榜#1同时获得时，左右滑动方式展示两个海报（ViewPager 效果）
 *  - 兜底：无广告记录 → 直接进入登录或首页
 */

import { Logger, AppConstants, TokenStore, HttpUtil, NavigationHelper, RouteName } from 'common';
import { SplashAdInfo } from '../../model/SplashAdInfo';

@ComponentV2
export struct SplashAd {
  /** 广告列表（双榜#1最多2条） */
  @Local adList: SplashAdInfo[] = [];
  /** 当前展示的广告索引 */
  @Local currentIndex: number = 0;
  /** 倒计时剩余秒数 */
  @Local countdownSec: number = 5;
  /** 是否已展示完广告 */
  @Local adFinished: boolean = false;
  /** 倒计时定时器 */
  private countdownTimerId: number | undefined = undefined;

  async aboutToAppear(): Promise<void> {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'splash_ad_appear' });
    await this.loadSplashAds();
    if (this.adList.length > 0) {
      this.startCountdown();
    } else {
      // 无广告，直接进入下一步
      await this.navigateToNext();
    }
  }

  aboutToDisappear(): void {
    if (this.countdownTimerId !== undefined) {
      clearInterval(this.countdownTimerId);
      this.countdownTimerId = undefined;
    }
  }

  /** 加载开屏广告（spec 3.1.2.2：检查当前月份有效记录） */
  private async loadSplashAds(): Promise<void> {
    try {
      const resp = await HttpUtil.get<SplashAdInfo[]>('/ad/splash', undefined, {
        withAuth: false,
        showErrorToast: false
      });
      if (resp.code === AppConstants.CODE_SUCCESS && resp.data) {
        this.adList = resp.data;
        Logger.info(AppConstants.SCENE_FARMER, { action: 'splash_ad_loaded', count: this.adList.length });
      } else {
        this.adList = [];
      }
    } catch (err) {
      // 加载失败不阻塞启动，直接进入下一步
      Logger.warn(AppConstants.SCENE_FARMER, { action: 'splash_ad_load_fail', error: (err as Error).message });
      this.adList = [];
    }
  }

  /** 启动 5 秒倒计时 */
  private startCountdown(): void {
    this.countdownSec = 5;
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
  private async clickAd(ad: SplashAdInfo): Promise<void> {
    if (this.countdownTimerId !== undefined) {
      clearInterval(this.countdownTimerId);
      this.countdownTimerId = undefined;
    }
    Logger.info(AppConstants.SCENE_FARMER, { action: 'splash_ad_click', adId: ad.adId, targetUrl: ad.targetUrl });
    // 先跳转到下一步判断登录态，再处理广告跳转
    const isLoggedIn: boolean = await TokenStore.isLoggedIn();
    if (!isLoggedIn) {
      NavigationHelper.replace(RouteName.FARMER_LOGIN);
      return;
    }
    // 后续阶段补充根据 targetUrl 跳转商品详情/直播间逻辑
    NavigationHelper.replace(RouteName.FARMER_HOME);
  }

  /** 进入下一步：登录页 或 首页 */
  private async navigateToNext(): Promise<void> {
    if (this.adFinished) {
      return;
    }
    this.adFinished = true;
    const isLoggedIn: boolean = await TokenStore.isLoggedIn();
    if (isLoggedIn) {
      NavigationHelper.replace(RouteName.FARMER_HOME);
    } else {
      NavigationHelper.replace(RouteName.FARMER_LOGIN);
    }
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.BottomEnd }) {
        if (this.adList.length === 0) {
          // 无广告时展示卖家端品牌主视觉（丰收橙背景 + 麦穗图标）
          Column() {
            Text('🌾')
              .fontSize(120)
              .margin({ bottom: 24 })
            Text('智农卖家')
              .fontSize(32)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
            Text('营收管理 · 商品上架 · 直播带货')
              .fontSize(14)
              .fontColor(Color.White)
              .opacity(0.8)
              .margin({ top: 8 })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .backgroundColor($r('app.color.color_cta_black'))
        } else if (this.adList.length === 1) {
          // 单广告展示
          this.SplashAdView(this.adList[0])
        } else {
          // 双榜#1：左右滑动展示两个海报（spec 3.1.2.2 ViewPager 效果）
          Swiper() {
            ForEach(this.adList, (ad: SplashAdInfo, _index: number) => {
              this.SplashAdView(ad)
            }, (ad: SplashAdInfo) => ad.adId)
          }
          .index(this.currentIndex)
          .indicator(true)
          .loop(false)
          .duration(300)
          .onChange((index: number) => {
            this.currentIndex = index;
          })
        }

        // 右上角跳过按钮（5秒倒计时中始终可见）
        if (this.adList.length > 0 && this.countdownSec <= 5) {
          Button(this.countdownSec > 0 ? `跳过 ${this.countdownSec}s` : '跳过')
            .fontSize(12)
            .fontColor(Color.White)
            .backgroundColor('rgba(0,0,0,0.5)')
            .borderRadius(20)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .margin({ right: 16, bottom: 32 })
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

  /** 单个广告海报视图 */
  @Builder
  SplashAdView(ad: SplashAdInfo) {
    Stack() {
      // 海报图片（AI海报URL，未生成时使用商品首图+肩带兜底）
      Image(ad.posterUrl)
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .onClick(() => {
          this.clickAd(ad);
        })

      // 肩带"月热销#1"
      if (ad.rankType === 'product') {
        Text('月热销商品榜 #1')
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.color_cta_black'))
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(4)
          .position({ x: 16, y: 48 })
      } else {
        Text('月热销直播榜 #1')
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.color_cta_black'))
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(4)
          .position({ x: 16, y: 48 })
      }
    }
    .width('100%')
    .height('100%')
  }
}
