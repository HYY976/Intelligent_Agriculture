/**
 * seller_profile - 卖家中心（spec 3.2.4.5）
 *
 * 对齐设计稿 pages/seller-profile.html：
 *  - 黄色渐变头部区（含状态栏 + 顶部导航 + 卖家信息 + 已认证 pill）
 *  - 悬浮统计卡（4 列：累计营收 / 可提现 / 粉丝 / 关注）
 *  - 功能入口列表卡（7 行：商品/直播/提现/营收/粉丝/认证/设置）
 */

import { Logger, AppConstants, NavigationHelper, RouteName, ModeStore, FontUtil, TokenStore } from 'common';
import { UserInfo } from 'common';
import type { CurrentModeKey } from 'common';
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
  /** spec 16.10：用户昵称（来自 TokenStore，与设置页个人信息同步） */
  @Local userNickname: string = '';
  /** spec 16.10：用户头像 URI（来自 TokenStore，与设置页个人信息同步） */
  @Local userAvatar: string = '';
  /** 当前模式（spec 16.6：老人模式字体放大） */
  @Local modeRef: CurrentModeKey = ModeStore.connectModeRef();

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
    await this.loadUserInfo();
  }

  /** spec 16.14：页面再次显示时同步刷新用户信息和店铺资料（营收/粉丝同步） */
  onPageShow(): void {
    this.loadUserInfo();
    this.loadProfile();
  }

  /** spec 16.10：从 TokenStore 加载用户头像和昵称（与设置页个人信息同步） */
  private async loadUserInfo(): Promise<void> {
    try {
      const user: UserInfo | null = await TokenStore.getUserInfo();
      if (user) {
        this.userNickname = user.nickname && user.nickname.length > 0 ? user.nickname : '';
        this.userAvatar = user.avatar;
      }
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'load_user_info_fail', error: (err as Error).message });
    }
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
    .onShown(() => {
      // spec 16.10/16.15：页面再次显示时刷新用户信息和店铺资料（营收/粉丝同步）
      this.loadUserInfo();
      this.loadProfile();
    })
  }

  /** spec 16.7：黄色头部高度（老人模式加大，避免遮挡统计卡） */
  private headerHeight(): number {
    return this.isElder() ? 220 : 170;
  }

  /** 黄色头部区（高度随模式自适应，避免老人模式遮挡下方统计卡） */
  @Builder
  YellowHeader() {
    Stack() {
      // 渐变背景 + 装饰圆
      Column()
        .width('100%')
        .height(this.headerHeight())
        .linearGradient({
          angle: 135,
          colors: [[$r('app.color.color_yellow'), 0.0], [$r('app.color.color_yellow_deep'), 1.0]]
        })
      // 右上装饰圆（进一步缩小至50×50并右移）
      Column()
        .width(50)
        .height(50)
        .borderRadius(25)
        .backgroundColor('rgba(255,255,255,0.2)')
        .position({ x: '90%', y: -15 })

      // 卖家信息区 + 顶栏（z=3）
      Column({ space: 8 }) {
        this.TopBar()
        this.SellerInfoRow()
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height(this.headerHeight())
    .alignContent(Alignment.TopStart)
  }

  /** 顶部导航栏（白底图标） */
  @Builder
  TopBar() {
    Row() {
      // 返回
      Text('‹')
        .fontSize(FontUtil.s(28, this.isElder()))
        .fontColor(Color.White)
        .width(32)
        .height(32)
        .textAlign(TextAlign.Center)
        .onClick(() => NavigationHelper.pop())
      // 标题
      Text('卖家中心')
        .fontSize(FontUtil.s(20, this.isElder()))
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      // spec 16.5：移除设置齿轮 emoji，改为不可见占位（保持标题居中）
      Column()
        .width(32)
        .height(32)
        .onClick(() => this.gotoSetting())
    }
    .width('100%')
    .height(48)
    .alignItems(VerticalAlign.Center)
  }

  /** spec 16.6：当前是否老年大字模式 */
  private isElder(): boolean {
    return FontUtil.isElder(this.modeRef.value);
  }

  /** 卖家信息行 */
  @Builder
  SellerInfoRow() {
    Row({ space: 12 }) {
      // spec 16.10：优先显示用户在设置页设置的头像，回退到店铺 Logo
      Image(this.userAvatar && this.userAvatar.length > 0
        ? this.userAvatar
        : ImageUtil.get(this.profile?.shopLogo ?? 'avatar_farmer'))
        .width(64)
        .height(64)
        .borderRadius(32)
        .objectFit(ImageFit.Cover)
        .border({ width: 3, color: Color.White })
      // 名称 + V 标 + 简介 + 已认证 pill
      Column({ space: 4 }) {
        Row({ space: 6 }) {
          // spec 16.10：优先显示用户在设置页设置的姓名，回退到店铺名
          Text(this.userNickname && this.userNickname.length > 0
            ? this.userNickname
            : (this.profile?.shopName ?? '加载中...'))
            .fontSize(FontUtil.s(20, this.isElder()))
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          // V 标
          Text('V')
            .fontSize(FontUtil.s(13, this.isElder()))
            .fontColor(Color.White)
            .backgroundColor($r('app.color.color_info'))
            .width(22)
            .height(22)
            .borderRadius(11)
            .textAlign(TextAlign.Center)
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        // 简介
        Text(this.profile?.shopIntro ?? '专注有机果蔬种植')
          .fontSize(FontUtil.s(14, this.isElder()))
          .fontColor('rgba(255,255,255,0.85)')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        // 已认证 pill（绿底白字）
        Row({ space: 3 }) {
          Text('✓')
            .fontSize(FontUtil.s(12, this.isElder()))
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
          Text('已认证')
            .fontSize(FontUtil.s(13, this.isElder()))
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
        }
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
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

  /** 悬浮统计卡（spec 16.7：两种模式均不上浮覆盖黄色头部，避免遮挡） */
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
    .margin({ top: 8 })
  }

  /** 单个统计项 */
  @Builder
  StatItem(value: string, label: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(FontUtil.s(20, this.isElder()))
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(label)
        .fontSize(FontUtil.s(13, this.isElder()))
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
          .fontSize(FontUtil.s(18, this.isElder()))
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

  /** 单个入口行（spec 16.5：放大图标和字体，确保看得清晰） */
  @Builder
  EntryRow(entry: ProfileEntry) {
    Row({ space: 14 }) {
      // 图标（放大到 48×48，emoji 字号 24）
      Text(entry.icon)
        .fontSize(FontUtil.s(24, this.isElder()))
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor(this.toneBg(entry.tone))
        .fontColor(this.toneFg(entry.tone))
        .textAlign(TextAlign.Center)
      // 文案
      Column({ space: 3 }) {
        Text(entry.label)
          .fontSize(FontUtil.s(17, this.isElder()))
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        Text(entry.desc)
          .fontSize(FontUtil.s(13, this.isElder()))
          .fontColor($r('app.color.color_text_3'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      // 箭头
      Text('›')
        .fontSize(FontUtil.s(24, this.isElder()))
        .fontColor($r('app.color.color_text_4'))
    }
    .width('100%')
    .height(64)
    .padding({ left: 0, right: 0 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => this.gotoEntry(entry.route))
  }
}
