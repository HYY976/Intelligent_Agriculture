﻿﻿﻿/**
 * profile_page - 个人中心页（Tab 内嵌 + 独立路由双用）
 * 遵循 spec 3.1.3.5 + 设计稿 user-profile.html 1:1 复刻：
 *  - 黄色渐变头部：顶部图标栏（设置+消息红点）+ 吉祥物探头 + 头像+昵称+ID+等级胶囊
 *  - 悬浮资料卡：关注/粉丝/订单/积分 4 列统计
 *  - 我的订单卡：4 状态宫格（待付款/待发货/待收货/已完成）+ 全部订单链接
 *  - 更多功能宫格：8 项（智农积分/优惠券/我的农场/收藏/地址管理/智农认证/我的直播/邀请好友）
 *  - 购物车快捷入口
 *  - 设置列表卡：消息通知/智农认证/帮助中心/关于我们/设置
 *
 * 导出 ProfileContent 供 home_page Tab 内嵌使用
 * 同时作为 @Entry 独立路由（pages/profile/profile_page）支持深链接
 */

import { TokenStore, Logger, AppConstants, ToastUtil, RouteName, NavigationHelper } from 'common';
import { UserInfoKey } from 'common';
import { AppStorageV2 } from '@kit.ArkUI';
import { OrderStatusTab } from '../../model/OrderModels';
import { ProfileFunction, ProfileStats, ProfileLevel, ProfileIconTheme } from '../../model/ProfileModels';
import { getMockOrderCountByStatus } from '../../mock/OrderMock';
import {
  getMockAvailableCouponCount,
  MOCK_PROFILE_STATS,
  MOCK_PROFILE_LEVEL,
  MOCK_USER_ID,
  MOCK_CART_ITEM_COUNT
} from '../../mock/ProfileMock';
import { ImageUtil } from '../../utils/ImageUtil';

/** 跳转订单列表的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface OrderListParam {
  status: OrderStatusTab;
}

/** 订单状态 Tab 配置（对齐设计稿 qn-order-row：仅 4 项，全部订单走标题链接） */
interface OrderTabConfig {
  tab: OrderStatusTab;
  label: string;
  icon: string;
}

/** 图标主题色对（对齐设计稿 qn-ico-* 彩色底） */
interface IconThemeColors {
  bg: Resource;
  color: Resource;
}

@ComponentV2
export struct ProfileContent {
  /** 用户昵称 */
  @Local nickname: string = '小趣';
  /** 用户 ID */
  @Local userId: string = MOCK_USER_ID;
  /** 头像 key（资源 key 或 file:// URI） */
  @Local avatarKey: string = 'avatar_default';
  /** 响应式用户信息引用（设置页修改后自动同步） */
  @Local userInfoRef: UserInfoKey = AppStorageV2.connect(
    UserInfoKey,
    'authUser',
    () => new UserInfoKey()
  )!;
  /** 统计信息（关注/粉丝/订单/积分） */
  @Local stats: ProfileStats = MOCK_PROFILE_STATS;
  /** 等级信息 */
  @Local level: ProfileLevel = MOCK_PROFILE_LEVEL;
  /** 各状态订单数 */
  @Local orderCounts: Record<string, number> = {} as Record<string, number>;
  /** 可用优惠券数 */
  @Local couponCount: number = 0;
  /** 购物车商品件数 */
  @Local cartItemCount: number = MOCK_CART_ITEM_COUNT;

  /** 订单 Tab 配置（对齐设计稿 qn-order-row：4 项，无"全部"） */
  private orderTabs: OrderTabConfig[] = [
    { tab: 'pending_payment', label: '待付款', icon: '💰' },
    { tab: 'pending_shipment', label: '待发货', icon: '📦' },
    { tab: 'pending_receipt', label: '待收货', icon: '🚚' },
    { tab: 'completed', label: '已完成', icon: '✍️' }
  ];

  /** 更多功能宫格（对齐设计稿 qn-quick-grid：4列×2行 = 8 项） */
  private quickFunctions: ProfileFunction[] = [
    { funcId: 'points', label: '智农积分', icon: '🎁', iconTheme: 'yellow', route: RouteName.USER_WALLET },
    { funcId: 'coupon', label: '优惠券', icon: '🎟️', iconTheme: 'yellow', route: RouteName.USER_COUPON_LIST },
    { funcId: 'farm', label: '我的农场', icon: '🌱', iconTheme: 'green', route: '' },
    { funcId: 'favorite', label: '收藏', icon: '❤️', iconTheme: 'green', route: RouteName.USER_FAVORITE_LIST },
    { funcId: 'address', label: '地址管理', icon: '📍', iconTheme: 'blue', route: RouteName.USER_ADDRESS_LIST },
    { funcId: 'cert', label: '智农认证', icon: '✓', iconTheme: 'green', route: '' },
    { funcId: 'live', label: '我的直播', icon: '📹', iconTheme: 'red', route: '' },
    { funcId: 'invite', label: '邀请好友', icon: '👥', iconTheme: 'orange', route: '' }
  ];

  /** 设置列表（对齐设计稿 qn-list-card：5 行） */
  private settingList: ProfileFunction[] = [
    { funcId: 'message', label: '消息通知', icon: '🔔', iconTheme: 'yellow', route: RouteName.USER_MESSAGE_LIST },
    { funcId: 'cert2', label: '智农认证', icon: '✓', iconTheme: 'green', route: '' },
    { funcId: 'help', label: '帮助中心', icon: '❓', iconTheme: 'blue', route: '' },
    { funcId: 'about', label: '关于我们', icon: 'ℹ️', iconTheme: 'orange', route: '' },
    { funcId: 'setting', label: '设置', icon: '⚙️', iconTheme: 'soft', route: RouteName.USER_SETTING }
  ];

  async aboutToAppear(): Promise<void> {
    const userInfo = await TokenStore.getUserInfo();
    if (userInfo) {
      this.nickname = userInfo.nickname;
      // spec 16.12：同步头像 key（设置页修改后整端同步）
      if (userInfo.avatar && userInfo.avatar.length > 0) {
        this.avatarKey = userInfo.avatar;
      }
    }
    this.orderCounts = getMockOrderCountByStatus();
    this.couponCount = getMockAvailableCouponCount();
    Logger.info(AppConstants.SCENE_USER, { action: 'profile_appear' });
  }

  /** 监听 UserInfoKey.value 变化，设置页修改头像/昵称后自动同步到「我的」页面 */
  @Monitor('userInfoRef.value')
  onUserInfoChange(): void {
    const userInfo = this.userInfoRef.value;
    if (userInfo) {
      this.nickname = userInfo.nickname;
      if (userInfo.avatar && userInfo.avatar.length > 0) {
        this.avatarKey = userInfo.avatar;
      }
      Logger.info(AppConstants.SCENE_USER, { action: 'profile_user_info_synced' });
    }
  }

  /** 获取头像图片源：file:///data URI 直接使用，否则走 ImageUtil 资源映射 */
  private getAvatarSource(): string | Resource {
    if (this.avatarKey.startsWith('file://') || this.avatarKey.startsWith('data:') || this.avatarKey.startsWith('/')) {
      return this.avatarKey;
    }
    return ImageUtil.get(this.avatarKey);
  }

  /** 获取图标主题色对（对齐设计稿 qn-ico-* 彩色底） */
  private getIconThemeColors(theme: ProfileIconTheme): IconThemeColors {
    switch (theme) {
      case 'yellow':
        return { bg: $r('app.color.color_yellow_soft'), color: $r('app.color.color_yellow_text') };
      case 'green':
        return { bg: $r('app.color.color_green_soft'), color: $r('app.color.color_green_deep') };
      case 'blue':
        return { bg: $r('app.color.color_info_soft'), color: $r('app.color.color_info') };
      case 'red':
        return { bg: $r('app.color.color_live_soft'), color: $r('app.color.color_live') };
      case 'orange':
        return { bg: $r('app.color.color_warn_soft'), color: $r('app.color.color_warn') };
      case 'soft':
      default:
        return { bg: $r('app.color.color_fill'), color: $r('app.color.color_text_2') };
    }
  }

  /** 点击订单状态 Tab → 订单列表 */
  private gotoOrderList(tab: OrderStatusTab): void {
    const param: OrderListParam = { status: tab };
    NavigationHelper.push(RouteName.USER_ORDER_LIST, param);
    Logger.info(AppConstants.SCENE_USER, { action: 'goto_order_list', tab });
  }

  /** 点击功能项 */
  private gotoFunction(func: ProfileFunction): void {
    if (func.route) {
      NavigationHelper.push(func.route);
    } else {
      ToastUtil.show('该功能将在后续阶段实现');
    }
    Logger.info(AppConstants.SCENE_USER, { action: 'goto_function', menu: func.funcId });
  }

  /** 跳转设置 */
  private gotoSetting(): void {
    NavigationHelper.push(RouteName.USER_SETTING);
    Logger.info(AppConstants.SCENE_USER, { action: 'goto_setting' });
  }

  /** 跳转消息列表 */
  private gotoMessage(): void {
    NavigationHelper.push(RouteName.USER_MESSAGE_LIST);
    Logger.info(AppConstants.SCENE_USER, { action: 'goto_message' });
  }

  /** 跳转购物车 */
  private gotoCart(): void {
    NavigationHelper.push(RouteName.USER_CART);
    Logger.info(AppConstants.SCENE_USER, { action: 'goto_cart' });
  }

  build() {
    Column() {
      // 可滚动内容区
      Scroll() {
        Column() {
          // 黄色头部（含顶部图标栏 + 吉祥物 + 资料信息）
          this.ProfileHeader()

          // 悬浮资料卡（统计行，负 margin 上浮覆盖头部）
          this.StatCard()

          // 内容区（订单/宫格/购物车/设置列表）
          Column({ space: 12 }) {
            this.OrderCard()
            this.QuickFunctionGrid()
            this.CartEntry()
            this.SettingsListCard()
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 24 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor($r('app.color.color_bg_page'))
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.color_bg_page'))
  }

  /** 黄色头部（对齐设计稿 qn-profile-header） */
  @Builder
  ProfileHeader() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 渐变黄背景（135deg #FFE234 → #FFD93D）
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 135,
          colors: [[$r('app.color.color_yellow'), 0.0], [$r('app.color.color_yellow_deep'), 1.0]]
        })

      // 头部内容（顶部图标栏 + 资料信息 + 吉祥物）
      Column() {
        // 顶部图标栏（对齐设计稿 qn-profile-topbar；spec 16.12：删除左上设置按钮，仅保留消息按钮）
        Row() {
          // 左侧占位（保持消息按钮右对齐）
          Blank()

          // 消息按钮（带红点）
          Stack({ alignContent: Alignment.TopEnd }) {
            Row() {
              Text('🔔').fontSize(18)
            }
            .width(36)
            .height(36)
            .borderRadius(18)
            .backgroundColor(Color.White)
            .shadow(AppConstants.SHADOW_CARD)
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
            .onClick(() => { this.gotoMessage(); })

            // 红点
            Column()
              .width(8)
              .height(8)
              .borderRadius(4)
              .backgroundColor($r('app.color.color_live'))
              .border({ width: 2, color: Color.White })
              .position({ x: 22, y: 4 })
          }
          .width(36)
          .height(36)
        }
        .width('100%')
        .padding({ top: 12, bottom: 16 })
        .alignItems(VerticalAlign.Center)

        // 资料信息 + 吉祥物（对齐设计稿 qn-profile-info + qn-mascot）
        Row({ space: 12 }) {
          // 头像（64×64，白色环 + 黄色环，对齐设计稿 qn-avatar-ring）
          Stack() {
            Image(this.getAvatarSource())
              .width(64)
              .height(64)
              .borderRadius(32)
              .objectFit(ImageFit.Cover)
              .border({ width: 3, color: Color.White })
          }
          .width(70)
          .height(70)
          .borderRadius(35)
          .border({ width: 2, color: $r('app.color.color_yellow') })

          // 昵称 + ID + 等级胶囊
          Column({ space: 3 }) {
            Text(this.nickname)
              .fontSize(20)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
              .maxLines(1)

            Text(`ID: ${this.userId}`)
              .fontSize(12)
              .fontColor('rgba(255,255,255,0.85)')

            // 等级胶囊（对齐设计稿 qn-pill-ink qn-level-pill）
            Row() {
              Text(`Lv.${this.level.level} ${this.level.title}`)
                .fontSize(10)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Medium)
            }
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(AppConstants.RADIUS_PILL)
            .backgroundColor($r('app.color.color_ink'))
            .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // 品牌头像（82×82 圆形，对齐设计稿 qn-mascot）
          Image($r('app.media.avatar_brand'))
            .width(82)
            .height(82)
            .borderRadius(41)
            .objectFit(ImageFit.Cover)
            .border({ width: 3, color: 'rgba(255,255,255,0.7)' })
            .shadow(AppConstants.SHADOW_CARD)
        }
        .width('100%')
        .padding({ top: 4, bottom: 42 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height(210)
  }

  /** 悬浮资料卡（对齐设计稿 qn-profile-card qn-stat-row） */
  @Builder
  StatCard() {
    Row() {
      this.StatItem(this.stats.followCount, '关注')
      this.StatItem(this.stats.fansCount, '粉丝')
      this.StatItem(this.stats.orderCount, '订单')
      this.StatItem(this.stats.points, '积分')
    }
    .width('100%')
    .padding({ top: 18, bottom: 18 })
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .margin({ top: -30, left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
  }

  /** 统计项（对齐设计稿 qn-stat） */
  @Builder
  StatItem(num: number, lab: string) {
    Column({ space: 2 }) {
      Text(`${num}`)
        .fontSize(18)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
      Text(lab)
        .fontSize(11)
        .fontColor($r('app.color.color_text_3'))
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  /** 我的订单卡（对齐设计稿 qn-card + qn-order-row） */
  @Builder
  OrderCard() {
    Column({ space: 0 }) {
      // 标题行（对齐设计稿 qn-section-head）
      Row() {
        Text('我的订单')
          .fontSize(16)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        Blank()
        Row({ space: 2 }) {
          Text('全部订单')
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
          Text('›')
            .fontSize(14)
            .fontColor($r('app.color.color_text_3'))
        }
        .onClick(() => { this.gotoOrderList('all'); })
      }
      .width('100%')
      .padding({ bottom: 12 })
      .alignItems(VerticalAlign.Center)

      // 订单状态行（4 项，对齐设计稿 qn-order-row）
      Row() {
        ForEach(this.orderTabs, (tabCfg: OrderTabConfig, _i: number) => {
          this.OrderItem(tabCfg)
        }, (tabCfg: OrderTabConfig) => tabCfg.tab)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 订单状态项（对齐设计稿 qn-order-item） */
  @Builder
  OrderItem(tabCfg: OrderTabConfig) {
    Column({ space: 8 }) {
      // 图标圆 + 角标
      Stack({ alignContent: Alignment.TopEnd }) {
        Row() {
          Text(tabCfg.icon)
            .fontSize(22)
        }
        .width(44)
        .height(44)
        .borderRadius(22)
        .backgroundColor($r('app.color.color_fill'))
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)

        // 角标（对齐设计稿 qn-order-badge）
        if (this.orderCounts[tabCfg.tab] !== undefined && this.orderCounts[tabCfg.tab] > 0) {
          Text(`${this.orderCounts[tabCfg.tab]}`)
            .fontSize(10)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .constraintSize({ minWidth: 16 })
            .height(16)
            .borderRadius(8)
            .backgroundColor($r('app.color.color_live'))
            .border({ width: 2, color: Color.White })
            .textAlign(TextAlign.Center)
            .padding({ left: 4, right: 4 })
            .offset({ x: 6, y: -6 })
        }
      }
      .width(44)
      .height(44)

      Text(tabCfg.label)
        .fontSize(12)
        .fontColor($r('app.color.color_text_2'))
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => { this.gotoOrderList(tabCfg.tab); })
  }

  /** 更多功能宫格（对齐设计稿 qn-card + qn-quick-grid：4列×2行） */
  @Builder
  QuickFunctionGrid() {
    Column({ space: 0 }) {
      // 标题（对齐设计稿 qn-section-head）
      Text('更多功能')
        .fontSize(16)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .alignSelf(ItemAlign.Start)
        .padding({ bottom: 12 })

      // 4 列网格
      Grid() {
        ForEach(this.quickFunctions, (func: ProfileFunction, _i: number) => {
          GridItem() {
            this.QuickFunctionItem(func)
          }
        }, (func: ProfileFunction) => func.funcId)
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsGap(18)
      .columnsGap(0)
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 功能项（对齐设计稿 qn-quick-item） */
  @Builder
  QuickFunctionItem(func: ProfileFunction) {
    Column({ space: 8 }) {
      // 彩色圆形图标底（对齐设计稿 qn-quick-ico）
      Row() {
        Text(func.icon)
          .fontSize(22)
      }
      .width(46)
      .height(46)
      .borderRadius(23)
      .backgroundColor(this.getIconThemeColors(func.iconTheme).bg)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      Text(func.label)
        .fontSize(11)
        .fontColor($r('app.color.color_text_2'))
        .maxLines(1)
    }
    .alignItems(HorizontalAlign.Center)
    .onClick(() => { this.gotoFunction(func); })
  }

  /** 购物车快捷入口（对齐设计稿 qn-cart-entry） */
  @Builder
  CartEntry() {
    Row() {
      Row({ space: 12 }) {
        // 购物车图标（黄色软底圆形）
        Row() {
          Text('🛒')
            .fontSize(20)
        }
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor($r('app.color.color_yellow_soft'))
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)

        Text('我的购物车')
          .fontSize(15)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .alignItems(VerticalAlign.Center)

      Blank()

      Row({ space: 4 }) {
        Text(`${this.cartItemCount}件商品`)
          .fontSize(13)
          .fontColor($r('app.color.color_text_3'))
        Text('›')
          .fontSize(16)
          .fontColor($r('app.color.color_text_3'))
      }
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(VerticalAlign.Center)
    .onClick(() => { this.gotoCart(); })
  }

  /** 设置列表卡（对齐设计稿 qn-card qn-list-card） */
  @Builder
  SettingsListCard() {
    Column({ space: 0 }) {
      ForEach(this.settingList, (item: ProfileFunction, idx: number) => {
        this.SettingRow(item, idx < this.settingList.length - 1)
      }, (item: ProfileFunction) => item.funcId)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 设置行（对齐设计稿 qn-list-row） */
  @Builder
  SettingRow(item: ProfileFunction, showDivider: boolean) {
    Column({ space: 0 }) {
      Row() {
        Row({ space: 12 }) {
          // 图标圆形底（对齐设计稿 qn-list-ico）
          Row() {
            Text(item.icon)
              .fontSize(18)
          }
          .width(36)
          .height(36)
          .borderRadius(18)
          .backgroundColor(this.getIconThemeColors(item.iconTheme).bg)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)

          Text(item.label)
            .fontSize(15)
            .fontColor($r('app.color.color_ink_2'))
            .fontWeight(FontWeight.Medium)
        }
        .alignItems(VerticalAlign.Center)

        Blank()

        Text('›')
          .fontSize(20)
          .fontColor($r('app.color.color_text_4'))
      }
      .width('100%')
      .padding({ top: 10, bottom: 10 })
      .alignItems(VerticalAlign.Center)
      .onClick(() => { this.gotoFunction(item); })

      // 分割线（对齐设计稿 qn-divider）
      if (showDivider) {
        Divider()
          .color($r('app.color.color_line'))
          .strokeWidth(1)
      }
    }
  }
}

/** 独立路由入口（深链接用） */
@ComponentV2
export struct ProfilePage {
  build() {
    NavDestination() {
      Column() {
        // 顶部栏
        Row() {
          Text('‹')
            .fontSize(28)
            .fontColor($r('app.color.color_text_primary'))
            .onClick(() => {
              NavigationHelper.pop();
            })
          Text('个人中心')
            .fontSize(18)
            .fontColor($r('app.color.color_text_primary'))
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          Text('')
            .width(28)
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor($r('app.color.color_bg_card'))
        .alignItems(VerticalAlign.Center)

        ProfileContent()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }
}
