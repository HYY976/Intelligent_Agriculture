/**
 * AdminEntryAbility - 系统管理后台端入口能力
 * 遵循 spec 2.1.4 / 2.3.1 / 3.3 / 6.6.3 / 10.9.2：
 *  - onCreate 中初始化 PreferencesUtil、ThemeStore（管理后台不适配老年大字模式，无需 ModeStore）
 *  - 加载 Navigation 容器根页面 pages/root/root_page（spec 10.9.2：声明式路由迁移）
 *    root_page 内部持有 NavPathStack 并推入 admin_login 作为首个页面
 *  - 管理后台 JWT 24 小时有效（后端控制）
 */

import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { PreferencesUtil, ThemeStore, Logger, AppConstants } from 'common';

export default class AdminEntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    Logger.info(AppConstants.SCENE_ADMIN, { action: 'ability_on_create' });

    // 初始化 Preferences
    PreferencesUtil.init(this.context as common.UIAbilityContext);

    // 应用主题（默认跟随系统；管理后台不适配老年大字模式 spec 6.6.3）
    ThemeStore.applyTheme(this.context as common.UIAbilityContext);
  }

  onDestroy(): void {
    Logger.info(AppConstants.SCENE_ADMIN, { action: 'ability_on_destroy' });
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    Logger.info(AppConstants.SCENE_ADMIN, { action: 'ability_on_window_stage_create' });

    // 启动页 = Navigation 容器根页面（spec 10.9.2：root_page 内部推入 admin_login）
    windowStage.loadContent('pages/root/root_page', (err) => {
      if (err.code) {
        Logger.error(AppConstants.SCENE_ADMIN, { action: 'load_root_fail', error: JSON.stringify(err) });
        return;
      }
      Logger.info(AppConstants.SCENE_ADMIN, { action: 'load_root_success' });
    });
  }

  onWindowStageDestroy(): void {
    Logger.info(AppConstants.SCENE_ADMIN, { action: 'ability_on_window_stage_destroy' });
  }

  onForeground(): void {
    Logger.info(AppConstants.SCENE_ADMIN, { action: 'ability_on_foreground' });
  }

  onBackground(): void {
    Logger.info(AppConstants.SCENE_ADMIN, { action: 'ability_on_background' });
  }
}
