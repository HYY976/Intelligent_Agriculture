/**
 * profile_page - 个人中心页（Tab 内嵌 + 独立路由双用）
 * 遵循 spec 3.1.3.5：
 *  - 顶部：头像 + 昵称 + 手机号脱敏 + 设置图标
 *  - 我的订单：5状态Tab（全部/待付款/待发货/待收货/待评价）
 *  - 功能网格：收货地址/我的钱包/我的收藏/我的关注/浏览历史/优惠券
 *  - 设置入口
 *
 * 导出 ProfileContent 供 home_page Tab 内嵌使用
 * 同时作为 @Entry 独立路由（pages/profile/profile_page）支持深链接
 */

import { TokenStore, Logger, AppConstants, UserRoutes, ToastUtil, RouteName, NavigationHelper } from 'common';
import { OrderStatusTab } from '../../model/OrderModels';
import { ProfileFunction } from '../../model/ProfileModels';
import { getMockOrderCountByStatus } from '../../mock/OrderMock';
import { MOCK_WALLET, getMockAvailableCouponCount } from '../../mock/ProfileMock';
import { ImageUtil } from '../../utils/ImageUtil';

/** 跳转订单列表的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface OrderListParam {
  status: OrderStatusTab;
}

/** 订单状态 Tab 配置 */
interface OrderTabConfig {
  tab: OrderStatusTab;
  label: string;
  icon: string;
}

@ComponentV2
export struct ProfileContent {
  /** 用户昵称 */
  @Local nickname: string = '助农用户';
  /** 用户手机号（脱敏） */
  @Local phoneMasked: string = '138****8888';
  /** 头像 key */
  @Local avatarKey: string = 'avatar_default';
  /** 各状态订单数 */
  @Local orderCounts: Record<string, number> = {} as Record<string, number>;
  /** 可用优惠券数 */
  @Local couponCount: number = 0;
  /** 钱包余额 */
  @Local balance: number = 0;

  /** 订单 Tab 配置 */
  private orderTabs: OrderTabConfig[] = [
    { tab: 'all', label: '全部', icon: '📋' },
    { tab: 'pending_payment', label: '待付款', icon: '💰' },
    { tab: 'pending_shipment', label: '待发货', icon: '📦' },
    { tab: 'pending_receipt', label: '待收货', icon: '🚚' },
    { tab: 'pending_review', label: '待评价', icon: '✍️' }
  ];

  /** 功能网格配置 */
  private functions: ProfileFunction[] = [
    { funcId: 'address', label: '收货地址', icon: '📍', route: RouteName.USER_ADDRESS_LIST },
    { funcId: 'wallet', label: '我的钱包', icon: '👛', route: RouteName.USER_WALLET },
    { funcId: 'favorite', label: '我的收藏', icon: '⭐', route: RouteName.USER_FAVORITE_LIST },
    { funcId: 'follow', label: '我的关注', icon: '➕', route: RouteName.USER_FOLLOW_LIST },
    { funcId: 'history', label: '浏览历史', icon: '🕐', route: RouteName.USER_HISTORY_LIST },
    { funcId: 'coupon', label: '优惠券', icon: '🎟️', route: RouteName.USER_COUPON_LIST }
  ];

  async aboutToAppear(): Promise<void> {
    const userInfo = await TokenStore.getUserInfo();
    if (userInfo) {
      this.nickname = userInfo.nickname;
      this.phoneMasked = this.maskPhone(userInfo.phone);
    }
    this.orderCounts = getMockOrderCountByStatus();
    this.couponCount = getMockAvailableCouponCount();
    this.balance = MOCK_WALLET.balance;
    Logger.info(AppConstants.SCENE_USER, { action: 'profile_appear' });
  }

  /** 手机号脱敏（138****8888） */
  private maskPhone(phone: string): string {
    if (phone.length < 11) {
      return phone;
    }
    return phone.substring(0, 3) + '****' + phone.substring(7);
  }

  /** 点击订单状态 Tab → 订单列表 */
  private gotoOrderList(tab: OrderStatusTab): void {
    const param: OrderListParam = { status: tab };
    NavigationHelper.push(RouteName.USER_ORDER_LIST, param);
    Logger.info(AppConstants.SCENE_USER, { action: 'goto_order_list', tab });
  }

  /** 点击功能网格项 */
  private gotoFunction(func: ProfileFunction): void {
    NavigationHelper.push(func.route);
    Logger.info(AppConstants.SCENE_USER, { action: 'goto_function', menu: func.funcId });
  }

  /** 跳转设置 */
  private gotoSetting(): void {
    NavigationHelper.push(RouteName.USER_SETTING);
  }

  build() {
    Column() {
      // 顶部用户信息区
      this.UserInfoHeader()

      // 内容区（可滚动）
      Scroll() {
        Column({ space: 12 }) {
          // 我的订单模块
          this.OrderSection()

          // 功能网格
          this.FunctionGrid()

          // 推荐好友 / 帮助中心 等额外入口
          this.ExtraEntry('👥 推荐好友', '邀请好友得优惠券')
          this.ExtraEntry('❓ 帮助中心', '常见问题与联系客服')
          this.ExtraEntry('📜 关于我们', '助农平台 v1.0.0')
        }
        .width('100%')
        .padding({ bottom: 24 })
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor($r('app.color.color_bg_page'))
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.color_bg_page'))
  }

  /** 顶部用户信息区 */
  @Builder
  UserInfoHeader() {
    Stack({ alignContent: Alignment.TopEnd }) {
      // 背景装饰
      Column()
        .width('100%')
        .height(140)
        .linearGradient({
          angle: 135,
          colors: [[$r('app.color.color_primary'), 0], [$r('app.color.color_primary_light'), 1]]
        })

      // 用户信息
      Row({ space: 14 }) {
        Image(ImageUtil.get(this.avatarKey))
          .width(64)
          .height(64)
          .borderRadius(32)
          .border({ width: 2, color: Color.White })

        Column({ space: 4 }) {
          Text(this.nickname)
            .fontSize(18)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
          Text(this.phoneMasked)
            .fontSize(13)
            .fontColor('rgba(255,255,255,0.85)')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 设置图标
        Text('⚙️')
          .fontSize(24)
          .onClick(() => {
            this.gotoSetting();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 50 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(140)
  }

  /** 我的订单模块 */
  @Builder
  OrderSection() {
    Column({ space: 12 }) {
      // 标题行
      Row() {
        Text('我的订单')
          .fontSize(15)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Medium)
        Blank()
        Text('查看全部订单 >')
          .fontSize(12)
          .fontColor($r('app.color.color_text_secondary'))
          .onClick(() => {
            this.gotoOrderList('all');
          })
      }
      .width('100%')

      // 5 状态 Tab
      Row() {
        ForEach(this.orderTabs, (tabCfg: OrderTabConfig, _i: number) => {
          Column({ space: 6 }) {
            Stack({ alignContent: Alignment.TopEnd }) {
              Text(tabCfg.icon)
                .fontSize(26)
              // 角标
              if (tabCfg.tab !== 'all' && this.orderCounts[tabCfg.tab] !== undefined && this.orderCounts[tabCfg.tab] > 0) {
                Text(`${this.orderCounts[tabCfg.tab]}`)
                  .fontSize(9)
                  .fontColor(Color.White)
                  .backgroundColor($r('app.color.color_error'))
                  .borderRadius(8)
                  .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                  .offset({ x: 8, y: -4 })
              }
            }
            Text(tabCfg.label)
              .fontSize(12)
              .fontColor($r('app.color.color_text_secondary'))
          }
          .layoutWeight(1)
          .padding({ top: 12, bottom: 12 })
          .onClick(() => {
            this.gotoOrderList(tabCfg.tab);
          })
        }, (tabCfg: OrderTabConfig) => tabCfg.tab)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(12)
    .margin({ left: 12, right: 12, top: 12 })
  }

  /** 功能网格（2列×3行） */
  @Builder
  FunctionGrid() {
    Column({ space: 0 }) {
      // 标题
      Text('常用功能')
        .fontSize(15)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 12 })

      // 网格 3行×2列
      Grid() {
        ForEach(this.functions, (func: ProfileFunction, _i: number) => {
          GridItem() {
            this.FunctionItem(func)
          }
        }, (func: ProfileFunction) => func.funcId)
      }
      .columnsTemplate('1fr 1fr')
      .rowsGap(1)
      .columnsGap(1)
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(12)
    .margin({ left: 12, right: 12 })
  }

  /** 功能项 */
  @Builder
  FunctionItem(func: ProfileFunction) {
    Row({ space: 12 }) {
      Text(func.icon)
        .fontSize(24)
      Text(func.label)
        .fontSize(13)
        .fontColor($r('app.color.color_text_primary'))
        .layoutWeight(1)
      // 优惠券数角标
      if (func.funcId === 'coupon' && this.couponCount > 0) {
        Text(`${this.couponCount}`)
          .fontSize(10)
          .fontColor($r('app.color.color_error'))
      }
      Text('>')
        .fontSize(14)
        .fontColor($r('app.color.color_text_hint'))
    }
    .width('100%')
    .height(56)
    .padding({ left: 12, right: 12 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.gotoFunction(func);
    })
  }

  /** 额外入口（推荐好友/帮助/关于） */
  @Builder
  ExtraEntry(title: string, desc: string) {
    Row() {
      Text(title)
        .fontSize(14)
        .fontColor($r('app.color.color_text_primary'))
        .layoutWeight(1)
      Text(desc)
        .fontSize(12)
        .fontColor($r('app.color.color_text_hint'))
      Text(' >')
        .fontSize(14)
        .fontColor($r('app.color.color_text_hint'))
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(12)
    .margin({ left: 12, right: 12 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      ToastUtil.show('该功能将在后续阶段实现');
    })
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
