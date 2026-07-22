/**
 * NavigationHelper - Navigation 路由跳转工具
 * 遵循 spec 10.9.2：router.pushUrl/replaceUrl/back/getParams → NavPathStack 声明式路由
 * 用法：
 *   1) 在各端 root_page.ets 中初始化：NavigationHelper.init(navStack);
 *   2) 跳转：NavigationHelper.push(RouteName.USER_HOME, { id: 'xxx' });
 *   3) 替换：NavigationHelper.replace(RouteName.USER_LOGIN);
 *   4) 返回：NavigationHelper.pop();
 *   5) 取参：const param = NavigationHelper.getParam<MyParam>();
 *
 * 设计要点：
 *  - 单例 NavPathStack，各端 EntryAbility 初始化时注入
 *  - 参数透传通过 pushPath/replacePath 的 param 字段
 *  - 取参通过 navStack.getParamByIndex 或 navStack.getAllParamName
 *  - 兜底返回 false / undefined，避免崩溃
 */

import { Logger } from './Logger';
import { AppConstants } from '../constants/AppConstants';

class NavigationHelperImpl {
  /** 全局 NavPathStack 引用，由 root_page 注入 */
  private navStack: NavPathStack | null = null;

  /**
   * 初始化 NavPathStack（各端 root_page 在 aboutToAppear 中调用）
   * @param stack NavPathStack 实例
   */
  init(stack: NavPathStack): void {
    this.navStack = stack;
    Logger.info(AppConstants.SCENE_COMMON, { action: 'nav_helper_init' });
  }

  /**
   * 推入新页面（对应 router.pushUrl）
   * @param name 路由名（route_map.json 中注册的 name）
   * @param param 透传参数对象（可选）
   * @returns 是否成功
   */
  push(name: string, param?: object): boolean {
    if (!this.checkReady()) {
      return false;
    }
    try {
      this.navStack!.pushPath({ name: name, param: param });
      Logger.info(AppConstants.SCENE_COMMON, { action: 'nav_push', name: name });
      return true;
    } catch (err) {
      Logger.error(AppConstants.SCENE_COMMON, {
        action: 'nav_push_fail',
        name: name,
        error: (err as Error).message
      });
      return false;
    }
  }

  /**
   * 替换当前页面（对应 router.replaceUrl）
   * @param name 路由名
   * @param param 透传参数对象（可选）
   * @returns 是否成功
   */
  replace(name: string, param?: object): boolean {
    if (!this.checkReady()) {
      return false;
    }
    try {
      this.navStack!.replacePath({ name: name, param: param });
      Logger.info(AppConstants.SCENE_COMMON, { action: 'nav_replace', name: name });
      return true;
    } catch (err) {
      Logger.error(AppConstants.SCENE_COMMON, {
        action: 'nav_replace_fail',
        name: name,
        error: (err as Error).message
      });
      return false;
    }
  }

  /**
   * 返回上一页（对应 router.back）
   * @returns 是否成功
   */
  pop(): boolean {
    if (!this.checkReady()) {
      return false;
    }
    try {
      // NavPathStack 无 canPop API，用 size() > 0 判断
      const stackSize: number = this.navStack!.size();
      if (stackSize === 0) {
        Logger.info(AppConstants.SCENE_COMMON, { action: 'nav_pop_skipped', reason: 'empty_stack' });
        return false;
      }
      this.navStack!.pop();
      Logger.info(AppConstants.SCENE_COMMON, { action: 'nav_pop' });
      return true;
    } catch (err) {
      Logger.error(AppConstants.SCENE_COMMON, {
        action: 'nav_pop_fail',
        error: (err as Error).message
      });
      return false;
    }
  }

  /**
   * 返回到指定路由（栈中存在该页面则弹出到它，否则不操作）
   * @param name 路由名
   * @returns 是否成功
   */
  popTo(name: string): boolean {
    if (!this.checkReady()) {
      return false;
    }
    try {
      this.navStack!.popToName(name);
      Logger.info(AppConstants.SCENE_COMMON, { action: 'nav_pop_to', name: name });
      return true;
    } catch (err) {
      Logger.error(AppConstants.SCENE_COMMON, {
        action: 'nav_pop_to_fail',
        name: name,
        error: (err as Error).message
      });
      return false;
    }
  }

  /**
   * 清空路由栈并推入新页面（用于登录/退出后跳转首页）
   * @param name 路由名
   * @param param 透传参数（可选）
   * @returns 是否成功
   */
  resetTo(name: string, param?: object): boolean {
    if (!this.checkReady()) {
      return false;
    }
    try {
      this.navStack!.clear();
      this.navStack!.pushPath({ name: name, param: param });
      Logger.info(AppConstants.SCENE_COMMON, { action: 'nav_reset_to', name: name });
      return true;
    } catch (err) {
      Logger.error(AppConstants.SCENE_COMMON, {
        action: 'nav_reset_to_fail',
        name: name,
        error: (err as Error).message
      });
      return false;
    }
  }

  /**
   * 获取当前页面参数（对应 router.getParams）
   * 在被导航页面的 aboutToAppear / onPageShow 中调用
   * @returns 参数对象，无则返回 undefined
   */
  getParam<T>(): T | undefined {
    if (!this.checkReady()) {
      return undefined;
    }
    try {
      const stackSize: number = this.navStack!.size();
      if (stackSize === 0) {
        return undefined;
      }
      // getParamByIndex 返回 unknown，需 as object 断言
      const param: object | undefined = this.navStack!.getParamByIndex(stackSize - 1) as object;
      if (param === undefined || param === null) {
        return undefined;
      }
      return param as T;
    } catch (err) {
      Logger.error(AppConstants.SCENE_COMMON, {
        action: 'nav_get_param_fail',
        error: (err as Error).message
      });
      return undefined;
    }
  }

  /**
   * 获取指定名称路由的参数（用于同名页面多次压栈时按 name 取参）
   * @param name 路由名
   * @returns 参数对象（取最后一个匹配项），无则返回 undefined
   */
  getParamByName<T>(name: string): T | undefined {
    if (!this.checkReady()) {
      return undefined;
    }
    try {
      // NavPathStack.getParamByName 返回 unknown[]，需 as Object[] 断言
      const params: Array<Object> = this.navStack!.getParamByName(name) as Array<Object>;
      if (params.length === 0) {
        return undefined;
      }
      return params[params.length - 1] as T;
    } catch (err) {
      Logger.error(AppConstants.SCENE_COMMON, {
        action: 'nav_get_param_by_name_fail',
        name: name,
        error: (err as Error).message
      });
      return undefined;
    }
  }

  /**
   * 获取当前栈顶路由名
   * @returns 路由名，无则返回空字符串
   */
  getCurrentName(): string {
    if (!this.checkReady()) {
      return '';
    }
    try {
      const stackSize: number = this.navStack!.size();
      if (stackSize === 0) {
        return '';
      }
      // NavPathStack 无 getNameByIndex API，用 getAllPathName() 取栈顶 name
      const allNames: string[] = this.navStack!.getAllPathName();
      return allNames[allNames.length - 1];
    } catch (err) {
      Logger.error(AppConstants.SCENE_COMMON, {
        action: 'nav_get_current_name_fail',
        error: (err as Error).message
      });
      return '';
    }
  }

  /**
   * 检查 navStack 是否已初始化
   * @returns 是否就绪
   */
  isReady(): boolean {
    return this.navStack !== null;
  }

  /** 内部就绪校验 */
  private checkReady(): boolean {
    if (this.navStack === null) {
      Logger.error(AppConstants.SCENE_COMMON, {
        action: 'nav_not_ready',
        error: 'NavigationHelper.navStack is null, call init() first in root_page'
      });
      return false;
    }
    return true;
  }
}

/** 全局 Navigation 单例 */
export const NavigationHelper: NavigationHelperImpl = new NavigationHelperImpl();
