/**
 * PreferencesUtil - 轻量数据持久化工具
 * 封装 @ohos.data.preferences，统一管理 Token/用户信息/模式开关等
 * 遵循 spec 1.2.1：本地存储使用 Preferences
 *                2.1.3：模式状态通过 Preferences 持久化
 *                2.3.1：主题状态持久化到 Preferences
 */

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { Logger } from './Logger';
import { AppConstants } from '../constants/AppConstants';

class PreferencesUtilImpl {
  private store: preferences.Preferences | null = null;
  private readonly storeName: string = 'zhunong_prefs';

  /** 初始化 Preferences（在 EntryAbility.onCreate 中调用） */
  async init(context: common.UIAbilityContext): Promise<void> {
    try {
      this.store = await preferences.getPreferences(context, this.storeName);
      Logger.info(AppConstants.SCENE_COMMON, { action: 'prefs_init_success' });
    } catch (err) {
      Logger.error(AppConstants.SCENE_COMMON, { action: 'prefs_init_fail', error: (err as Error).message });
    }
  }

  /** 写入字符串值 */
  async putString(key: string, value: string): Promise<void> {
    if (this.store === null) {
      Logger.warn(AppConstants.SCENE_COMMON, { action: 'prefs_not_init', key });
      return;
    }
    try {
      await this.store.put(key, value);
      await this.store.flush();
    } catch (err) {
      Logger.error(AppConstants.SCENE_COMMON, { action: 'prefs_put_string_fail', key, error: (err as Error).message });
    }
  }

  /** 读取字符串值 */
  async getString(key: string, defaultValue: string = ''): Promise<string> {
    if (this.store === null) {
      Logger.warn(AppConstants.SCENE_COMMON, { action: 'prefs_not_init', key });
      return defaultValue;
    }
    try {
      const val: preferences.ValueType = await this.store.get(key, defaultValue);
      return typeof val === 'string' ? val : defaultValue;
    } catch (err) {
      Logger.error(AppConstants.SCENE_COMMON, { action: 'prefs_get_string_fail', key, error: (err as Error).message });
      return defaultValue;
    }
  }

  /** 写入布尔值 */
  async putBoolean(key: string, value: boolean): Promise<void> {
    if (this.store === null) {
      return;
    }
    try {
      await this.store.put(key, value);
      await this.store.flush();
    } catch (err) {
      Logger.error(AppConstants.SCENE_COMMON, { action: 'prefs_put_boolean_fail', key, error: (err as Error).message });
    }
  }

  /** 读取布尔值 */
  async getBoolean(key: string, defaultValue: boolean = false): Promise<boolean> {
    if (this.store === null) {
      return defaultValue;
    }
    try {
      const val: preferences.ValueType = await this.store.get(key, defaultValue);
      return typeof val === 'boolean' ? val : defaultValue;
    } catch (err) {
      Logger.error(AppConstants.SCENE_COMMON, { action: 'prefs_get_boolean_fail', key, error: (err as Error).message });
      return defaultValue;
    }
  }

  /** 写入数字 */
  async putNumber(key: string, value: number): Promise<void> {
    if (this.store === null) {
      return;
    }
    try {
      await this.store.put(key, value);
      await this.store.flush();
    } catch (err) {
      Logger.error(AppConstants.SCENE_COMMON, { action: 'prefs_put_number_fail', key, error: (err as Error).message });
    }
  }

  /** 读取数字 */
  async getNumber(key: string, defaultValue: number = 0): Promise<number> {
    if (this.store === null) {
      return defaultValue;
    }
    try {
      const val: preferences.ValueType = await this.store.get(key, defaultValue);
      return typeof val === 'number' ? val : defaultValue;
    } catch (err) {
      Logger.error(AppConstants.SCENE_COMMON, { action: 'prefs_get_number_fail', key, error: (err as Error).message });
      return defaultValue;
    }
  }

  /** 删除指定键 */
  async remove(key: string): Promise<void> {
    if (this.store === null) {
      return;
    }
    try {
      await this.store.delete(key);
      await this.store.flush();
    } catch (err) {
      Logger.error(AppConstants.SCENE_COMMON, { action: 'prefs_remove_fail', key, error: (err as Error).message });
    }
  }

  /** 清空全部 */
  async clear(): Promise<void> {
    if (this.store === null) {
      return;
    }
    try {
      await this.store.clear();
      await this.store.flush();
      Logger.info(AppConstants.SCENE_COMMON, { action: 'prefs_clear_success' });
    } catch (err) {
      Logger.error(AppConstants.SCENE_COMMON, { action: 'prefs_clear_fail', error: (err as Error).message });
    }
  }
}

/** 全局 Preferences 单例 */
export const PreferencesUtil: PreferencesUtilImpl = new PreferencesUtilImpl();
