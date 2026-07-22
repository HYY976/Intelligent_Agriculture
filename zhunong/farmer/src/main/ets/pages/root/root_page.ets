/**
 * RootPage - 农户端 Navigation 容器根页面
 * 遵循 spec 10.9.2：router → Navigation 声明式路由迁移
 *
 * 职责：
 *  1) 持有全局 NavPathStack 实例并注入 NavigationHelper
 *  2) 通过 navDestination(this.pageMap) 集中路由 25 个 farmer 页面
 *  3) aboutToAppear 时推入 splash_ad 作为首个页面（启动入口）
 *
 * 替代关系：
 *  - 原 FarmerEntryAbility.loadContent('pages/splash/splash_ad')
 *  - 现 FarmerEntryAbility.loadContent('pages/root/root_page') → NavPathStack.pushPath(splash_ad)
 */

import { RouteName, NavigationHelper } from 'common';

// 启动链路
import { SplashAd } from '../splash/splash_ad';
import { FarmerLogin } from '../login/farmer_login';
import { FarmerHomePage } from '../home/home_page';
import { RevenueDetail } from '../home/revenue_detail';

// 商城
import { SellerMallPage } from '../mall/seller_mall_page';
import { ProductPublish } from '../mall/product_publish';
import { ProductEdit } from '../mall/product_edit';

// 直播
import { LiveBrowse } from '../live/live_browse';
import { LiveCreate } from '../live/live_create';
import { LiveRoom } from '../live/live_room';

// 智能体
import { AgentPage } from '../agent/agent_page';

// 搜索
import { SearchPage } from '../search/search_page';

// 社区
import { CommunityList } from '../community/community_list';
import { PostDetail } from '../community/post_detail';
import { PostCreate } from '../community/post_create';

// 消息
import { MessageList } from '../message/message_list';
import { ChatDetail } from '../message/chat_detail';

// 个人中心
import { SellerProfile } from '../profile/seller_profile';
import { ProductManage } from '../profile/product_manage';
import { LiveManage } from '../profile/live_manage';
import { Withdraw } from '../profile/withdraw';
import { RevenueStats } from '../profile/revenue_stats';
import { FansList } from '../profile/fans_list';
import { Certification } from '../profile/certification';
import { Setting } from '../profile/setting';

@Entry
@ComponentV2
struct RootPage {
  /** 全局 NavPathStack，由 NavigationHelper 共享 */
  private navStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    // 注入 NavigationHelper（供全端调用 push/replace/pop）
    NavigationHelper.init(this.navStack);
    // 推入启动页（splash_ad 内部根据登录态决定跳 home 或 login）
    this.navStack.pushPath({ name: RouteName.FARMER_SPLASH });
  }

  /**
   * 路由表：根据 name 渲染对应 struct
   * 被 NavPathStack.pushPath/replacePath 时调用
   */
  @Builder
  pageMap(name: string, param: object) {
    if (name === RouteName.FARMER_SPLASH) {
      SplashAd()
    } else if (name === RouteName.FARMER_LOGIN) {
      FarmerLogin()
    } else if (name === RouteName.FARMER_HOME) {
      FarmerHomePage()
    } else if (name === RouteName.FARMER_REVENUE_DETAIL) {
      RevenueDetail()
    } else if (name === RouteName.FARMER_SELLER_MALL) {
      SellerMallPage()
    } else if (name === RouteName.FARMER_PRODUCT_PUBLISH) {
      ProductPublish()
    } else if (name === RouteName.FARMER_PRODUCT_EDIT) {
      ProductEdit()
    } else if (name === RouteName.FARMER_LIVE_BROWSE) {
      LiveBrowse()
    } else if (name === RouteName.FARMER_LIVE_CREATE) {
      LiveCreate()
    } else if (name === RouteName.FARMER_LIVE_ROOM) {
      LiveRoom()
    } else if (name === RouteName.FARMER_AGENT_PAGE) {
      AgentPage()
    } else if (name === RouteName.FARMER_SEARCH_PAGE) {
      SearchPage()
    } else if (name === RouteName.FARMER_COMMUNITY_LIST) {
      CommunityList()
    } else if (name === RouteName.FARMER_POST_DETAIL) {
      PostDetail()
    } else if (name === RouteName.FARMER_POST_CREATE) {
      PostCreate()
    } else if (name === RouteName.FARMER_MESSAGE_LIST) {
      MessageList()
    } else if (name === RouteName.FARMER_CHAT_DETAIL) {
      ChatDetail()
    } else if (name === RouteName.FARMER_SELLER_PROFILE) {
      SellerProfile()
    } else if (name === RouteName.FARMER_PRODUCT_MANAGE) {
      ProductManage()
    } else if (name === RouteName.FARMER_LIVE_MANAGE) {
      LiveManage()
    } else if (name === RouteName.FARMER_WITHDRAW) {
      Withdraw()
    } else if (name === RouteName.FARMER_REVENUE_STATS) {
      RevenueStats()
    } else if (name === RouteName.FARMER_FANS_LIST) {
      FansList()
    } else if (name === RouteName.FARMER_CERTIFICATION) {
      Certification()
    } else if (name === RouteName.FARMER_SETTING) {
      Setting()
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
