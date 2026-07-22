/**
 * RootPage - 用户端 Navigation 容器根页面
 * 遵循 spec 10.9.2：router → Navigation 声明式路由迁移
 *
 * 职责：
 *  1) 持有全局 NavPathStack 实例并注入 NavigationHelper
 *  2) 通过 navDestination(this.pageMap) 集中路由 30 个 user 页面
 *  3) aboutToAppear 时推入 splash_ad 作为首个页面（启动入口）
 *
 * 替代关系：
 *  - 原 UserEntryAbility.loadContent('pages/splash/splash_ad')
 *  - 现 UserEntryAbility.loadContent('pages/root/root_page') → NavPathStack.pushPath(splash_ad)
 */

import { RouteName, NavigationHelper } from 'common';

// 启动链路
import { SplashAdPage } from '../splash/splash_ad';
import { UserLogin } from '../login/user_login';
import { UserRegister } from '../login/user_register';
import { HomePage } from '../home/home_page';

// 社区
import { CommunityList } from '../community/community_list';
import { PostDetailPage } from '../community/post_detail';
import { PostCreate } from '../community/post_create';

// 消息
import { MessageList } from '../message/message_list';
import { ChatDetail } from '../message/chat_detail';

// 购物车 & 个人中心
import { CartPage } from '../cart/cart_page';
import { ProfilePage } from '../profile/profile_page';
import { Setting } from '../profile/setting';
import { AddressList } from '../profile/address_list';
import { AddressEdit } from '../profile/address_edit';
import { FavoriteList } from '../profile/favorite_list';
import { FollowList } from '../profile/follow_list';
import { HistoryList } from '../profile/history_list';
import { CouponList } from '../profile/coupon_list';
import { Wallet } from '../profile/wallet';

// 搜索
import { SearchPage } from '../search/search_page';
// 注：search_result 未独立成文件，由 search_page 内部状态切换；如未来独立需补 import

// 商城
import { CategoryList } from '../mall/category_list';
import { ProductList } from '../mall/product_list';
import { ProductDetail } from '../mall/product_detail';
import { OrderConfirm } from '../mall/order_confirm';
import { OrderList } from '../mall/order_list';
import { OrderDetail } from '../mall/order_detail';
import { ReviewCreate } from '../mall/review_create';

// 直播 & 文旅
import { LiveList } from '../live/live_list';
import { LiveRoom } from '../live/live_room';
import { TravelMap } from '../travel/travel_map';
import { PoiDetail } from '../travel/poi_detail';

@Entry
@ComponentV2
struct RootPage {
  /** 全局 NavPathStack，由 NavigationHelper 共享 */
  private navStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    // 注入 NavigationHelper（供全端调用 push/replace/pop）
    NavigationHelper.init(this.navStack);
    // 推入启动页（splash_ad 内部根据登录态决定跳 home 或 login）
    this.navStack.pushPath({ name: RouteName.USER_SPLASH });
  }

  /**
   * 路由表：根据 name 渲染对应 struct
   * 被 NavPathStack.pushPath/replacePath 时调用
   */
  @Builder
  pageMap(name: string, param: object) {
    if (name === RouteName.USER_SPLASH) {
      SplashAdPage()
    } else if (name === RouteName.USER_LOGIN) {
      UserLogin()
    } else if (name === RouteName.USER_REGISTER) {
      UserRegister()
    } else if (name === RouteName.USER_HOME) {
      HomePage()
    } else if (name === RouteName.USER_COMMUNITY_LIST) {
      CommunityList()
    } else if (name === RouteName.USER_POST_DETAIL) {
      PostDetailPage()
    } else if (name === RouteName.USER_POST_CREATE) {
      PostCreate()
    } else if (name === RouteName.USER_MESSAGE_LIST) {
      MessageList()
    } else if (name === RouteName.USER_CHAT_DETAIL) {
      ChatDetail()
    } else if (name === RouteName.USER_CART) {
      CartPage()
    } else if (name === RouteName.USER_PROFILE) {
      ProfilePage()
    } else if (name === RouteName.USER_SETTING) {
      Setting()
    } else if (name === RouteName.USER_ADDRESS_LIST) {
      AddressList()
    } else if (name === RouteName.USER_ADDRESS_EDIT) {
      AddressEdit()
    } else if (name === RouteName.USER_FAVORITE_LIST) {
      FavoriteList()
    } else if (name === RouteName.USER_FOLLOW_LIST) {
      FollowList()
    } else if (name === RouteName.USER_HISTORY_LIST) {
      HistoryList()
    } else if (name === RouteName.USER_COUPON_LIST) {
      CouponList()
    } else if (name === RouteName.USER_WALLET) {
      Wallet()
    } else if (name === RouteName.USER_SEARCH_PAGE) {
      SearchPage()
    } else if (name === RouteName.USER_SEARCH_RESULT) {
      // search_result 暂复用 SearchPage（内部状态切换）
      SearchPage()
    } else if (name === RouteName.USER_CATEGORY_LIST) {
      CategoryList()
    } else if (name === RouteName.USER_PRODUCT_LIST) {
      ProductList()
    } else if (name === RouteName.USER_PRODUCT_DETAIL) {
      ProductDetail()
    } else if (name === RouteName.USER_ORDER_CONFIRM) {
      OrderConfirm()
    } else if (name === RouteName.USER_ORDER_LIST) {
      OrderList()
    } else if (name === RouteName.USER_ORDER_DETAIL) {
      OrderDetail()
    } else if (name === RouteName.USER_REVIEW_CREATE) {
      ReviewCreate()
    } else if (name === RouteName.USER_LIVE_LIST) {
      LiveList()
    } else if (name === RouteName.USER_LIVE_ROOM) {
      LiveRoom()
    } else if (name === RouteName.USER_TRAVEL_MAP) {
      TravelMap()
    } else if (name === RouteName.USER_POI_DETAIL) {
      PoiDetail()
    } else {
      // 未知路由：兜底空页面
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.color_bg_page'))
    }
  }

  build() {
    Navigation(this.navStack) {
    }
    .navDestination(this.pageMap)
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}
