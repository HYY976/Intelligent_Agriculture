/**
 * FarmerEntryAbility - 农户卖家端入口能力
 * 遵循 spec 2.1.4 / 2.3.1 / 3.2 / 10.9.2：
 *  - onCreate 中初始化 PreferencesUtil、ModeStore、ThemeStore
 *  - 加载 Navigation 容器根页面 pages/root/root_page（spec 10.9.2：声明式路由迁移）
 *    root_page 内部持有 NavPathStack 并推入 splash_ad 作为首个页面
 *  - 模式开关仅卖家端首页生效（spec 6.6.1）
 */

import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { PreferencesUtil, ModeStore, ThemeStore, Logger, AppConstants } from 'common';

export default class FarmerEntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'ability_on_create' });

    // 初始化 Preferences
    PreferencesUtil.init(this.context as common.UIAbilityContext);

    // 初始化模式（标准/老年大字）—— 卖家端首页右上角圆形开关可切换
    ModeStore.initMode();

    // 应用主题（默认跟随系统）
    ThemeStore.applyTheme(this.context as common.UIAbilityContext);
  }

  onDestroy(): void {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'ability_on_destroy' });
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'ability_on_window_stage_create' });

    // 启动页 = Navigation 容器根页面（spec 10.9.2：root_page 内部推入 splash_ad）
    windowStage.loadContent('pages/root/root_page', (err) => {
      if (err.code) {
        Logger.error(AppConstants.SCENE_FARMER, { action: 'load_root_fail', error: JSON.stringify(err) });
        return;
      }
      Logger.info(AppConstants.SCENE_FARMER, { action: 'load_root_success' });
    });
  }

  onWindowStageDestroy(): void {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'ability_on_window_stage_destroy' });
  }

  onForeground(): void {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'ability_on_foreground' });
  }

  onBackground(): void {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'ability_on_background' });
  }
}
