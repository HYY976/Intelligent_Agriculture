/**
 * UserEntryAbility - 用户端入口能力
 * 遵循 spec 2.1.4 / 2.3.1 / 10.9.2：
 *  - onCreate 中初始化 PreferencesUtil、ModeStore、ThemeStore
 *  - 加载 Navigation 容器根页面 pages/root/root_page（替代原 pages/splash/splash_ad）
 *  - root_page 内部通过 NavPathStack 推入 splash_ad 作为首个页面
 *  - 设置主题为跟随系统（COLOR_MODE_NOT_SET 默认）
 */

import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { PreferencesUtil, ModeStore, ThemeStore, Logger, AppConstants, TokenStore } from 'common';

export default class UserEntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    Logger.info(AppConstants.SCENE_USER, { action: 'ability_on_create' });

    // 初始化 Preferences
    PreferencesUtil.init(this.context as common.UIAbilityContext);

    // 初始化模式（标准/老年大字）
    ModeStore.initMode();

    // 应用主题（默认跟随系统）
    ThemeStore.applyTheme(this.context as common.UIAbilityContext);
  }

  onDestroy(): void {
    Logger.info(AppConstants.SCENE_USER, { action: 'ability_on_destroy' });
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    Logger.info(AppConstants.SCENE_USER, { action: 'ability_on_window_stage_create' });

    // spec 10.9.2：加载 Navigation 容器根页面（root_page 内部推入 splash_ad）
    windowStage.loadContent('pages/root/root_page', (err) => {
      if (err.code) {
        Logger.error(AppConstants.SCENE_USER, { action: 'load_root_fail', error: JSON.stringify(err) });
        return;
      }
      Logger.info(AppConstants.SCENE_USER, { action: 'load_root_success' });
    });
  }

  onWindowStageDestroy(): void {
    Logger.info(AppConstants.SCENE_USER, { action: 'ability_on_window_stage_destroy' });
  }

  onForeground(): void {
    Logger.info(AppConstants.SCENE_USER, { action: 'ability_on_foreground' });
  }

  onBackground(): void {
    Logger.info(AppConstants.SCENE_USER, { action: 'ability_on_background' });
  }
}
