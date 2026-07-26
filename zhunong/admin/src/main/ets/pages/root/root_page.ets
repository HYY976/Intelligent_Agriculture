/**
 * RootPage - 管理后台端 Navigation 容器根页面
 * 遵循 spec 10.9.2：router → Navigation 声明式路由迁移
 *
 * 职责：
 *  1) 持有全局 NavPathStack 实例并注入 NavigationHelper
 *  2) 通过 navDestination(this.pageMap) 集中路由 10 个 admin 页面
 *  3) aboutToAppear 时推入 admin_login 作为首个页面（启动入口）
 *
 * 替代关系：
 *  - 原 AdminEntryAbility.loadContent('pages/login/admin_login')
 *  - 现 AdminEntryAbility.loadContent('pages/root/root_page') → NavPathStack.pushPath(admin_login)
 *
 * 注：admin 模块无开屏广告（spec 5.3），启动页直接是 admin_login；
 *     admin_login 内部根据 JWT 有效性决定是否跳转 admin_home。
 */

import { RouteName, NavigationHelper } from 'common';

// 登录
import { AdminLogin } from '../login/admin_login';
import { AdminRegister } from '../login/admin_register';

// 后台首页
import { AdminHome } from '../home/admin_home';

// 用户管理
import { UserList } from '../user_manage/user_list';
import { UserDetail } from '../user_manage/user_detail';

// API 管理
import { ApiList } from '../api_manage/api_list';
import { ApiDetail } from '../api_manage/api_detail';
import { RateLimit } from '../api_manage/rate_limit';
import { ApiKeyPage } from '../api_manage/api_key';

// 内容审核
import { ReviewList } from '../content_review/review_list';
import { ReviewDetail } from '../content_review/review_detail';

// 广告管理
import { AdsList } from '../ads_manage/ads_list';

@Entry
@ComponentV2
struct RootPage {
  /** 全局 NavPathStack，由 NavigationHelper 共享 */
  private navStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    // 注入 NavigationHelper（供全端调用 push/replace/pop）
    NavigationHelper.init(this.navStack);
    // 推入启动页（admin_login 内部根据 JWT 决定是否跳转 admin_home）
    this.navStack.pushPath({ name: RouteName.ADMIN_LOGIN });
  }

  /**
   * 路由表：根据 name 渲染对应 struct
   * 被 NavPathStack.pushPath/replacePath 时调用
   */
  @Builder
  pageMap(name: string, param: object) {
    if (name === RouteName.ADMIN_LOGIN) {
      AdminLogin()
    } else if (name === RouteName.ADMIN_REGISTER) {
      AdminRegister()
    } else if (name === RouteName.ADMIN_HOME) {
      AdminHome()
    } else if (name === RouteName.ADMIN_USER_LIST) {
      UserList()
    } else if (name === RouteName.ADMIN_USER_DETAIL) {
      UserDetail()
    } else if (name === RouteName.ADMIN_API_LIST) {
      ApiList()
    } else if (name === RouteName.ADMIN_API_DETAIL) {
      ApiDetail()
    } else if (name === RouteName.ADMIN_RATE_LIMIT) {
      RateLimit()
    } else if (name === RouteName.ADMIN_API_KEY) {
      ApiKeyPage()
    } else if (name === RouteName.ADMIN_REVIEW_LIST) {
      ReviewList()
    } else if (name === RouteName.ADMIN_REVIEW_DETAIL) {
      ReviewDetail()
    } else if (name === RouteName.ADMIN_ADS_LIST) {
      AdsList()
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
