/**
 * seller_profile - 卖家个人中心（spec 3.2.4.5）
 *
 * 顶部：卖家信息（头像 + 店铺名 + 资质认证状态）
 * 功能模块（8入口）：
 *  - 商品管理 → pages/profile/product_manage
 *  - 直播管理 → pages/profile/live_manage
 *  - 提现 → pages/profile/withdraw
 *  - 营收统计 → pages/profile/revenue_stats
 *  - 粉丝管理 → pages/profile/fans_list
 *  - 资质认证 → pages/profile/certification
 *  - 设置 → pages/profile/setting
 *
 * 关注粉丝体系：
 *  - 卖家关注数 + 粉丝数在卖家主页展示
 */

import { Logger, AppConstants, FarmerRoutes, NavigationHelper, RouteName } from 'common';
import { FarmerProfile } from '../../model/FarmerModels';
import { FarmerRepository } from '../../repository/FarmerRepository';
import { MOCK_FARMER_ID } from '../../mock/FarmerMock';

/** 功能入口项 */
interface ProfileEntry {
  label: string;
  icon: string;
  route: string;
  desc: string;
}

@ComponentV2
export struct SellerProfile {
  /** 卖家信息 */
  @Local profile: FarmerProfile | null = null;
  /** 是否正在加载 */
  @Local isLoading: boolean = false;

  /** 功能入口列表 */
  private entries: ProfileEntry[] = [
    { label: '商品管理', icon: '🛍', route: RouteName.FARMER_PRODUCT_MANAGE, desc: '商品列表+上下架' },
    { label: '直播管理', icon: '📹', route: RouteName.FARMER_LIVE_MANAGE, desc: '历史直播+数据' },
    { label: '提现', icon: '💰', route: RouteName.FARMER_WITHDRAW, desc: '可提现余额+记录' },
    { label: '营收统计', icon: '📊', route: RouteName.FARMER_REVENUE_STATS, desc: '日/月/年营收图表' },
    { label: '粉丝管理', icon: '👥', route: RouteName.FARMER_FANS_LIST, desc: '粉丝列表' },
    { label: '资质认证', icon: '✓', route: RouteName.FARMER_CERTIFICATION, desc: 'Mock 认证' },
    { label: '设置', icon: '⚙', route: RouteName.FARMER_SETTING, desc: '主题/字号/退出' }
  ];

  async aboutToAppear(): Promise<void> {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'seller_profile_appear' });
    await this.loadProfile();
  }

  /** 加载卖家信息 */
  private async loadProfile(): Promise<void> {
    this.isLoading = true;
    try {
      this.profile = await FarmerRepository.getMyProfile(MOCK_FARMER_ID);
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'load_profile_fail', error: (err as Error).message });
    } finally {
      this.isLoading = false;
    }
  }

  /** 进入功能页 */
  private gotoEntry(route: string): void {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'goto_entry', route });
    NavigationHelper.push(route);
  }

  /** 认证状态文案 */
  private getCertLabel(): string {
    if (!this.profile) {
      return '未认证';
    }
    if (this.profile.certificationStatus === 'approved') {
      return '已认证';
    } else if (this.profile.certificationStatus === 'pending') {
      return '认证中';
    }
    return '未认证';
  }

  /** 认证状态颜色 */
  private getCertColor(): Resource {
    if (!this.profile) {
      return $r('app.color.color_text_hint');
    }
    if (this.profile.certificationStatus === 'approved') {
      return $r('app.color.color_primary');
    } else if (this.profile.certificationStatus === 'pending') {
      return $r('app.color.color_secondary');
    }
    return $r('app.color.color_text_hint');
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        Scroll() {
          Column({ space: 16 }) {
            this.ProfileHeader()
            this.AccountStats()
            this.EntriesSection()
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 24 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 顶部导航 */
  @Builder
  TopBar() {
    Row({ space: 12 }) {
      Text('‹')
        .fontSize(28)
        .fontColor($r('app.color.color_text_primary'))
        .onClick(() => NavigationHelper.pop())
      Text('卖家中心')
        .fontSize(18)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** 卖家信息头部 */
  @Builder
  ProfileHeader() {
    Column({ space: 12 }) {
      Row({ space: 16 }) {
        // 店铺 Logo
        Stack() {
          Text('🌾')
            .fontSize(40)
        }
        .width(72)
        .height(72)
        .borderRadius(36)
        .backgroundColor($r('app.color.color_primary_light'))
        .alignContent(Alignment.Center)

        Column({ space: 4 }) {
          Row({ space: 6 }) {
            Text(this.profile?.shopName ?? '加载中...')
              .fontSize(18)
              .fontColor($r('app.color.color_text_primary'))
              .fontWeight(FontWeight.Bold)
            // 卖家 V 标
            Text('V')
              .fontSize(11)
              .fontColor(Color.White)
              .backgroundColor($r('app.color.color_secondary'))
              .width(20)
              .height(20)
              .borderRadius(10)
              .textAlign(TextAlign.Center)
          }
          Text(this.profile?.shopIntro ?? '暂无店铺介绍')
            .fontSize(12)
            .fontColor($r('app.color.color_text_secondary'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
          // 认证状态
          Row({ space: 4 }) {
            Text(this.getCertLabel())
              .fontSize(11)
              .fontColor(this.getCertColor())
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 账户数据统计 */
  @Builder
  AccountStats() {
    Row() {
      this.StatItem('累计营收', `¥${(this.profile?.totalRevenue ?? 0).toFixed(0)}`, $r('app.color.color_price'))
      this.StatItem('可提现', `¥${(this.profile?.availableBalance ?? 0).toFixed(2)}`, $r('app.color.color_primary'))
      this.StatItem('粉丝', `${this.profile?.fansCount ?? 0}`, $r('app.color.color_text_primary'))
      this.StatItem('关注', `${this.profile?.followCount ?? 0}`, $r('app.color.color_text_secondary'))
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
    .justifyContent(FlexAlign.SpaceAround)
  }

  /** 统计项 */
  @Builder
  StatItem(label: string, value: string, color: Resource) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(14)
        .fontColor(color)
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(label)
        .fontSize(11)
        .fontColor($r('app.color.color_text_hint'))
    }
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)
  }

  /** 功能入口 */
  @Builder
  EntriesSection() {
    Column({ space: 0 }) {
      ForEach(this.entries, (entry: ProfileEntry, idx: number) => {
        Row({ space: 12 }) {
          Text(entry.icon)
            .fontSize(22)
            .width(40)
            .height(40)
            .borderRadius(20)
            .backgroundColor($r('app.color.color_bg_page'))
            .textAlign(TextAlign.Center)
          Column({ space: 2 }) {
            Text(entry.label)
              .fontSize(14)
              .fontColor($r('app.color.color_text_primary'))
            Text(entry.desc)
              .fontSize(11)
              .fontColor($r('app.color.color_text_hint'))
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Text('›')
            .fontSize(20)
            .fontColor($r('app.color.color_text_hint'))
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .onClick(() => this.gotoEntry(entry.route))
        if (idx < this.entries.length - 1) {
          Divider()
            .strokeWidth(0.5)
            .color($r('app.color.color_divider'))
            .margin({ left: 68 })
        }
      }, (entry: ProfileEntry) => entry.route)
    }
    .width('100%')
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }
}
