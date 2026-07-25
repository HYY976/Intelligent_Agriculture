/**
 * splash_ad - 开屏广告页（UI 复刻 v4.0，对齐 splash-ad.html 设计稿）
 * 遵循 spec 15.5.1：整页重写，1:1 还原设计稿
 *  - 全屏背景图（hero_harvest.jpg）+ 暗色渐变蒙版
 *  - 状态栏白字 + 右上角"广告"角标
 *  - 底部品牌 Logo（黄色渐变方块 + 萌芽图标）+ "趣农" + "新鲜农货·产地直发"
 *  - 跳过按钮（右下，倒计时秒数）+ "— 广告 —" 提示
 * 业务逻辑保留：MOCK_SPLASH_ADS + 5秒倒计时 + 跳过/点击跳转 + TokenStore 登录态判断
 */

import { Logger, AppConstants, TokenStore, RouteName, NavigationHelper } from 'common';
import { SplashAd } from '../../model/SearchModels';
import { MOCK_SPLASH_ADS } from '../../mock/SearchMock';
import { ImageUtil } from '../../utils/ImageUtil';

/** 跳转商品详情的路由参数 */
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
  private countdownTimerId: number = -1;

  async aboutToAppear(): Promise<void> {
    Logger.info(AppConstants.SCENE_USER, JSON.stringify({ action: 'splash_ad_appear', adCount: this.adList.length }));
    if (this.adList.length > 0) {
      this.startCountdown();
    } else {
      await this.navigateToNext();
    }
  }

  aboutToDisappear(): void {
    if (this.countdownTimerId !== -1) {
      clearInterval(this.countdownTimerId);
      this.countdownTimerId = -1;
    }
  }

  /** 启动 5 秒倒计时 */
  private startCountdown(): void {
    this.countdownSec = AppConstants.SPLASH_DISPLAY_MS / 1000;
    this.countdownTimerId = setInterval(() => {
      this.countdownSec -= 1;
      if (this.countdownSec <= 0) {
        if (this.countdownTimerId !== -1) {
          clearInterval(this.countdownTimerId);
          this.countdownTimerId = -1;
        }
        this.navigateToNext();
      }
    }, 1000);
  }

  /** 跳过广告 */
  private async skipAd(): Promise<void> {
    if (this.countdownTimerId !== -1) {
      clearInterval(this.countdownTimerId);
      this.countdownTimerId = -1;
    }
    await this.navigateToNext();
  }

  /** 点击广告跳转 */
  private async clickAd(): Promise<void> {
    if (this.countdownTimerId !== -1) {
      clearInterval(this.countdownTimerId);
      this.countdownTimerId = -1;
    }
    if (this.adList.length === 0) {
      await this.navigateToNext();
      return;
    }
    const ad: SplashAd = this.adList[this.currentIndex];
    Logger.info(AppConstants.SCENE_USER, JSON.stringify({ action: 'splash_ad_click', adId: ad.adId, rankType: ad.rankType }));

    const isLoggedIn: boolean = await TokenStore.isLoggedIn();
    if (!isLoggedIn) {
      NavigationHelper.replace(RouteName.USER_LOGIN);
      return;
    }
    if (ad.rankType === 'product') {
      const param: ProductDetailParam = { productId: ad.targetId };
      NavigationHelper.replace(RouteName.USER_PRODUCT_DETAIL, param);
    } else {
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
      Stack({ alignContent: Alignment.TopStart }) {
        // 1. 全屏背景图（优先使用广告海报，兜底 hero_harvest）
        if (this.adList.length > 0) {
          Image(ImageUtil.get(this.adList[this.currentIndex].posterUrl))
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
            .onClick(() => this.clickAd())
        } else {
          Image($r('app.media.hero_harvest'))
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
        }

        // 2. 暗色渐变蒙版（底部 0.35 → 顶部 0）
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: 180,
            colors: [['rgba(26,26,26,0)', 0.4], ['rgba(26,26,26,0.35)', 1.0]]
          })

        // 3. 状态栏（白字）
        Row() {
          Text('9:41')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
          Row({ space: 6 }) {
            Text('▰▰▰▰')
              .fontSize(12)
              .fontColor(Color.White)
            Text('📶')
              .fontSize(12)
            Text('🔋')
              .fontSize(12)
          }
        }
        .width('100%')
        .height(AppConstants.STATUSBAR_HEIGHT)
        .padding({ left: 22, right: 18 })
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)

        // 4. 右上角"广告"角标
        Text('广告')
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor('rgba(255,255,255,0.85)')
          .backgroundColor('rgba(26,26,26,0.45)')
          .padding({ top: 3, bottom: 3, left: 9, right: 9 })
          .borderRadius(AppConstants.RADIUS_XS)
          .position({ x: '78%', y: 50 })

        // 5. 底部内容区
        Column() {
          // 品牌 Logo 区 + 跳过按钮
          Row() {
            // 品牌 Logo + 文字
            Row({ space: 12 }) {
              // 黄色渐变 Logo 方块 + 萌芽图标
              Text('🌱')
                .fontSize(28)
                .fontColor($r('app.color.color_ink'))
                .width(54)
                .height(54)
                .borderRadius(AppConstants.RADIUS_LG)
                .linearGradient({
                  angle: 135,
                  colors: [[$r('app.color.color_yellow'), 0.0], [$r('app.color.color_yellow_deep'), 1.0]]
                })
                .shadow({
                  radius: 20,
                  color: 'rgba(255,217,61,0.45)',
                  offsetX: 0,
                  offsetY: 8
                })
                .textAlign(TextAlign.Center)

              // 品牌文字
              Column({ space: 4 }) {
                Text('趣农')
                  .fontSize(26)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                  .letterSpacing(2)
                Text('新鲜农货·产地直发')
                  .fontSize(12)
                  .fontColor('rgba(255,255,255,0.88)')
                  .letterSpacing(0.5)
              }
              .alignItems(HorizontalAlign.Start)
            }
            .layoutWeight(1)

            // 跳过按钮
            Row({ space: 5 }) {
              Text(`跳过 ${this.countdownSec}s`)
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
              Text('›')
                .fontSize(16)
                .fontColor(Color.White)
            }
            .backgroundColor('rgba(26,26,26,0.55)')
            .borderRadius(AppConstants.RADIUS_PILL)
            .padding({ top: 8, bottom: 8, left: 15, right: 15 })
            .onClick(() => this.skipAd())
          }
          .width('100%')
          .padding({ left: 22, right: 22 })
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)

          // 底部"广告"提示
          Text('—  广  告  —')
            .fontSize(10)
            .fontColor('rgba(255,255,255,0.55)')
            .letterSpacing(3)
            .textAlign(TextAlign.Center)
            .margin({ top: 16, bottom: 22 })
        }
        .width('100%')
        .position({ x: 0, y: '80%' })
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_ink'))
    }
    .hideTitleBar(true)
  }
}
