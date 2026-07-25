/**
 * ThemeStore - 主题（浅色/深色/跟随系统）状态管理
 * 遵循 spec 2.3.1：
 *  - 默认跟随系统深色/浅色模式（COLOR_MODE_NOT_SET）
 *  - 用户可在个人中心-设置中手动覆盖（浅色/深色/跟随系统三选一）
 *  - 手动覆盖状态持久化到 Preferences（key: theme_setting）
 *  10.9.3：AppStorage → AppStorageV2（API 12+ 类型安全版本）
 */

import { AppStorageV2 } from '@kit.ArkUI';
import { PreferencesUtil } from '../utils/PreferencesUtil';
import { Logger } from '../utils/Logger';
import { AppConstants } from '../constants/AppConstants';
import { ConfigurationConstant, AbilityConstant } from '@kit.AbilityKit';
import { common } from '@kit.AbilityKit';
import { CurrentThemeKey } from '../model/CommonModels';

class ThemeStoreImpl {
  /** AppStorageV2 中当前主题的 key */
  static readonly STORAGE_KEY: string = 'currentTheme';

  /** 设置主题（持久化 + AppStorageV2 广播） */
  async setTheme(theme: string): Promise<void> {
    try {
      await PreferencesUtil.putString(AppConstants.KEY_THEME, theme);
      // 10.12：Key 类型 interface → class，回调改为 new CurrentThemeKey() + 默认值赋值
      const themeRef: CurrentThemeKey = AppStorageV2.connect(
        CurrentThemeKey,
        ThemeStoreImpl.STORAGE_KEY,
        () => {
          const initial: CurrentThemeKey = new CurrentThemeKey();
          initial.value = AppConstants.THEME_SYSTEM;
          return initial;
        }
      )!;
      themeRef.value = theme;
      Logger.info(AppConstants.SCENE_COMMON, { action: 'theme_set', theme });
    } catch (err) {
      Logger.error(AppConstants.SCENE_COMMON, { action: 'theme_set_fail', theme, error: (err as Error).message });
    }
  }

  /** 读取当前主题 */
  async getTheme(): Promise<string> {
    const themeRef: CurrentThemeKey = AppStorageV2.connect(
      CurrentThemeKey,
      ThemeStoreImpl.STORAGE_KEY,
      () => {
        const initial: CurrentThemeKey = new CurrentThemeKey();
        initial.value = AppConstants.THEME_SYSTEM;
        return initial;
      }
    )!;
    if (themeRef.value && themeRef.value.length > 0) {
      return themeRef.value;
    }
    const persisted: string = await PreferencesUtil.getString(AppConstants.KEY_THEME, AppConstants.THEME_SYSTEM);
    themeRef.value = persisted;
    return persisted;
  }

  /**
   * 页面/组件连接到当前主题状态 ref（响应式）
   * spec 10.18：页面用 @Local themeRef = ThemeStore.connectThemeRef() 持有，
   * 在 build() 中读取 themeRef.value 即可自动响应 setTheme 广播。
   * @returns AppStorageV2 中 currentTheme 的共享实例（已 @Trace value）
   */
  connectThemeRef(): CurrentThemeKey {
    return AppStorageV2.connect(
      CurrentThemeKey,
      ThemeStoreImpl.STORAGE_KEY,
      () => {
        const initial: CurrentThemeKey = new CurrentThemeKey();
        initial.value = AppConstants.THEME_SYSTEM;
        return initial;
      }
    )!;
  }

  /**
   * 应用主题到 Ability 上下文
   * 在 EntryAbility.onCreate 中调用
   */
  async applyTheme(context: common.UIAbilityContext): Promise<void> {
    const theme: string = await this.getTheme();
    try {
      const colorMode: number = this.mapThemeToColorMode(theme);
      context.getApplicationContext().setColorMode(colorMode);
      Logger.info(AppConstants.SCENE_COMMON, { action: 'theme_applied', theme, colorMode });
    } catch (err) {
      Logger.error(AppConstants.SCENE_COMMON, { action: 'theme_apply_fail', theme, error: (err as Error).message });
    }
  }

  /** 主题字符串映射为系统 ColorMode 常量 */
  private mapThemeToColorMode(theme: string): number {
    switch (theme) {
      case AppConstants.THEME_LIGHT:
        return ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
      case AppConstants.THEME_DARK:
        return ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
      case AppConstants.THEME_SYSTEM:
      default:
        return ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
    }
  }
}

/** 全局 Theme 单例 */
export const ThemeStore: ThemeStoreImpl = new ThemeStoreImpl();
