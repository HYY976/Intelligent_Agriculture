/**
 * EntryAbility - 助农平台统一入口能力
 * 三端合并架构（spec：单 entry 入口 + 多 feature 模块）：
 *  - 作为 APP 唯一 entry 模块，桌面上只有一个图标
 *  - 加载角色选择页 pages/role_select
 *  - 用户选择身份后通过 startAbility 启动对应 feature 模块（user/farmer/admin）
 */

import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { PreferencesUtil, ThemeStore, Logger, AppConstants } from 'common';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    Logger.info(AppConstants.SCENE_COMMON, { action: 'entry_ability_on_create' });

    // 初始化 Preferences
    PreferencesUtil.init(this.context as common.UIAbilityContext);

    // 应用主题（默认跟随系统）
    ThemeStore.applyTheme(this.context as common.UIAbilityContext);
  }

  onDestroy(): void {
    Logger.info(AppConstants.SCENE_COMMON, { action: 'entry_ability_on_destroy' });
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    Logger.info(AppConstants.SCENE_COMMON, { action: 'entry_ability_on_window_stage_create' });

    // 加载角色选择页（单页，无需 Navigation 容器）
    windowStage.loadContent('pages/role_select', (err) => {
      if (err.code) {
        Logger.error(AppConstants.SCENE_COMMON, { action: 'load_role_select_fail', error: JSON.stringify(err) });
        return;
      }
      Logger.info(AppConstants.SCENE_COMMON, { action: 'load_role_select_success' });
    });
  }

  onWindowStageDestroy(): void {
    Logger.info(AppConstants.SCENE_COMMON, { action: 'entry_ability_on_window_stage_destroy' });
  }

  onForeground(): void {
    Logger.info(AppConstants.SCENE_COMMON, { action: 'entry_ability_on_foreground' });
  }

  onBackground(): void {
    Logger.info(AppConstants.SCENE_COMMON, { action: 'entry_ability_on_background' });
  }
}
