/**
 * seller_profile - 卖家中心（spec 3.2.4.5）
 *
 * 对齐设计稿 pages/seller-profile.html：
 *  - 黄色渐变头部区（含状态栏 + 顶部导航 + 卖家信息 + 已认证 pill）
 *  - 悬浮统计卡（4 列：累计营收 / 可提现 / 粉丝 / 关注）
 *  - 功能入口列表卡（7 行：商品/直播/提现/营收/粉丝/认证/设置）
 */

import { Logger, AppConstants, NavigationHelper, RouteName } from 'common';
import { FarmerProfile } from '../../model/FarmerModels';
import { FarmerRepository } from '../../repository/FarmerRepository';
import { MOCK_FARMER_ID } from '../../mock/FarmerMock';
import { ImageUtil } from '../../utils/ImageUtil';

/** 图标底色（对齐设计稿 qn-ico-*） */
type IconTone = 'yellow' | 'red' | 'green' | 'blue' | 'orange' | 'soft';

/** 功能入口项 */
interface ProfileEntry {
  /** 主标题 */
  label: string;
  /** 副标题 */
  desc: string;
  /** emoji 图标 */
  icon: string;
  /** 图标底色 */
  tone: IconTone;
  /** 跳转路由 */
  route: string;
}

@ComponentV2
export struct SellerProfile {
  /** 卖家信息 */
  @Local profile: FarmerProfile | null = null;
  /** 是否正在加载 */
  @Local isLoading: boolean = false;

  /** 功能入口列表（对齐设计稿 7 行：商品/直播/提现/营收/粉丝/认证/设置） */
  private entries: ProfileEntry[] = [
    { label: '商品管理', desc: '商品列表+上下架', icon: '🛍', tone: 'yellow', route: RouteName.FARMER_PRODUCT_MANAGE },
    { label: '直播管理', desc: '历史直播+数据', icon: '📹', tone: 'red', route: RouteName.FARMER_LIVE_MANAGE },
    { label: '提现', desc: '可提现余额+记录', icon: '💰', tone: 'green', route: RouteName.FARMER_WITHDRAW },
    { label: '营收统计', desc: '日/月/年营收图表', icon: '📊', tone: 'blue', route: RouteName.FARMER_REVENUE_STATS },
    { label: '粉丝管理', desc: '粉丝列表', icon: '👥', tone: 'orange', route: RouteName.FARMER_FANS_LIST },
    { label: '资质认证', desc: 'Mock认证', icon: '✓', tone: 'green', route: RouteName.FARMER_CERTIFICATION },
    { label: '设置', desc: '主题/字号/退出', icon: '⚙', tone: 'soft', route: RouteName.FARMER_SETTING }
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

  /** 进入设置页（顶栏右侧齿轮） */
  private gotoSetting(): void {
    NavigationHelper.push(RouteName.FARMER_SETTING);
  }

  /** 格式化金额（千分位） */
  private formatAmount(v: number): string {
    return v.toFixed(0).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  }

  /** 取图标底色 Resource */
  private toneBg(tone: IconTone): Resource {
    switch (tone) {
      case 'yellow': return $r('app.color.color_yellow_soft');
      case 'red': return $r('app.color.color_live_soft');
      case 'green': return $r('app.color.color_green_soft');
      case 'blue': return $r('app.color.color_info_soft');
      case 'orange': return $r('app.color.color_warn_soft');
      case 'soft':
      default: return $r('app.color.color_fill');
    }
  }

  /** 取图标前景色 Resource */
  private toneFg(tone: IconTone): Resource {
    switch (tone) {
      case 'yellow': return $r('app.color.color_yellow_text');
      case 'red': return $r('app.color.color_live');
      case 'green': return $r('app.color.color_green_deep');
      case 'blue': return $r('app.color.color_info');
      case 'orange': return $r('app.color.color_warn');
      case 'soft':
      default: return $r('app.color.color_text_2');
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 黄色头部区（含状态栏 + 顶栏 + 卖家信息）
        this.YellowHeader()
        // 内容区：悬浮统计卡 + 功能入口列表
        Scroll() {
          Column({ space: 12 }) {
            this.FloatingStatsCard()
            this.EntriesCard()
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 24 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_cream'))
    }
    .hideTitleBar(true)
  }

  /** 黄色头部区 */
  @Builder
  YellowHeader() {
    Stack() {
      // 渐变背景 + 装饰圆
      Column()
        .width('100%')
        .height(220)
        .linearGradient({
          angle: 135,
          colors: [[$r('app.color.color_yellow'), 0.0], [$r('app.color.color_yellow_deep'), 1.0]]
        })
      // 右上装饰圆
      Column()
        .width(140)
        .height(140)
        .borderRadius(70)
        .backgroundColor('rgba(255,255,255,0.3)')
        .position({ x: '78%', y: -30 })

      // 卖家信息区 + 顶栏（z=3）
      Column({ space: 12 }) {
        this.TopBar()
        this.SellerInfoRow()
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height(220)
    .alignContent(Alignment.TopStart)
  }

  /** 顶部导航栏（白底图标） */
  @Builder
  TopBar() {
    Row() {
      // 返回
      Text('‹')
        .fontSize(28)
        .fontColor(Color.White)
        .width(32)
        .height(32)
        .textAlign(TextAlign.Center)
        .onClick(() => NavigationHelper.pop())
      // 标题
      Text('卖家中心')
        .fontSize(18)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      // 设置齿轮
      Text('⚙')
        .fontSize(18)
        .fontColor(Color.White)
        .width(32)
        .height(32)
        .textAlign(TextAlign.Center)
        .onClick(() => this.gotoSetting())
    }
    .width('100%')
    .height(44)
    .alignItems(VerticalAlign.Center)
  }

  /** 卖家信息行 */
  @Builder
  SellerInfoRow() {
    Row({ space: 12 }) {
      // 店铺 Logo（白边描边）
      Image(ImageUtil.get(this.profile?.shopLogo ?? 'avatar_farmer'))
        .width(64)
        .height(64)
        .borderRadius(32)
        .objectFit(ImageFit.Cover)
        .border({ width: 3, color: Color.White })
      // 名称 + V 标 + 简介 + 已认证 pill
      Column({ space: 4 }) {
        Row({ space: 6 }) {
          Text(this.profile?.shopName ?? '加载中...')
            .fontSize(18)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          // V 标
          Text('V')
            .fontSize(11)
            .fontColor(Color.White)
            .backgroundColor($r('app.color.color_info'))
            .width(18)
            .height(18)
            .borderRadius(9)
            .textAlign(TextAlign.Center)
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        // 简介
        Text(this.profile?.shopIntro ?? '专注有机果蔬种植')
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.8)')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        // 已认证 pill（绿底白字）
        Row({ space: 3 }) {
          Text('✓')
            .fontSize(10)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
          Text('已认证')
            .fontSize(11)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
        }
        .padding({ left: 10, right: 10, top: 3, bottom: 3 })
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor($r('app.color.color_green'))
        .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ top: 6 })
  }

  /** 悬浮统计卡（向上覆盖黄色头部 30px） */
  @Builder
  FloatingStatsCard() {
    Row() {
      this.StatItem(`¥${this.formatAmount(this.profile?.totalRevenue ?? 0)}`, '累计营收')
      this.StatDivider()
      this.StatItem(`¥${this.formatAmount(this.profile?.availableBalance ?? 0)}`, '可提现')
      this.StatDivider()
      this.StatItem(`${this.profile?.fansCount ?? 0}`, '粉丝')
      this.StatDivider()
      this.StatItem(`${this.profile?.followCount ?? 0}`, '关注')
    }
    .width('100%')
    .padding({ top: 18, bottom: 18, left: 8, right: 8 })
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .margin({ top: -30 })
  }

  /** 单个统计项 */
  @Builder
  StatItem(value: string, label: string) {
    Column({ space: 2 }) {
      Text(value)
        .fontSize(17)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(label)
        .fontSize(11)
        .fontColor($r('app.color.color_text_3'))
    }
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)
  }

  /** 统计项分隔竖线 */
  @Builder
  StatDivider() {
    Column()
      .width(1)
      .height(24)
      .backgroundColor('rgba(26,26,26,0.12)')
  }

  /** 功能入口列表卡 */
  @Builder
  EntriesCard() {
    Column({ space: 0 }) {
      // 区块标题
      Row() {
        Text('卖家功能')
          .fontSize(16)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .padding({ top: 4, bottom: 12 })

      // 入口列表
      ForEach(this.entries, (entry: ProfileEntry, idx: number) => {
        this.EntryRow(entry)
        if (idx < this.entries.length - 1) {
          Divider()
            .strokeWidth(1)
            .color($r('app.color.color_line'))
            .margin({ left: 0, right: 0 })
        }
      }, (entry: ProfileEntry) => entry.route)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 8 })
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 单个入口行 */
  @Builder
  EntryRow(entry: ProfileEntry) {
    Row({ space: 12 }) {
      // 图标
      Text(entry.icon)
        .fontSize(18)
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor(this.toneBg(entry.tone))
        .fontColor(this.toneFg(entry.tone))
        .textAlign(TextAlign.Center)
      // 文案
      Column({ space: 2 }) {
        Text(entry.label)
          .fontSize(15)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        Text(entry.desc)
          .fontSize(12)
          .fontColor($r('app.color.color_text_3'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      // 箭头
      Text('›')
        .fontSize(20)
        .fontColor($r('app.color.color_text_4'))
    }
    .width('100%')
    .height(56)
    .padding({ left: 0, right: 0 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => this.gotoEntry(entry.route))
  }
}
