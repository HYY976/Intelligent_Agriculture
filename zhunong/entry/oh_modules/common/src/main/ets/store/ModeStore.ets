/**
 * ModeStore - 标准/老年大字模式状态管理
 * 遵循 spec 2.1.4：
 *  - 切换状态通过 Preferences 持久化（key: mode_setting，value: standard/elder）
 *  - 切换时通过 AppStorageV2 全局广播模式变化
 *  - 各页面通过 @Local modeRef = ModeStore.connectModeRef() 响应式刷新（AppStorageV2 + @ObservedV2/@Trace，spec 10.18）
 *  - 切换范围：仅当前端 APP 生效（用户端/卖家端各自切换，管理后台不适配）
 *  10.9.3：AppStorage → AppStorageV2（API 12+ 类型安全版本）
 *  10.12：Key 类型 interface → class，回调改为 new CurrentModeKey() + 默认值赋值
 */

import { AppStorageV2 } from '@kit.ArkUI';
import { PreferencesUtil } from '../utils/PreferencesUtil';
import { Logger } from '../utils/Logger';
import { AppConstants } from '../constants/AppConstants';
import { CurrentModeKey } from '../model/CommonModels';

class ModeStoreImpl {
  /** AppStorageV2 中当前模式的 key（页面通过 AppStorageV2.connect 监听） */
  static readonly STORAGE_KEY: string = 'currentMode';

  /** 设置模式（持久化 + AppStorageV2 广播） */
  async setMode(mode: string): Promise<void> {
    try {
      await PreferencesUtil.putString(AppConstants.KEY_MODE, mode);
      const modeRef: CurrentModeKey = AppStorageV2.connect(
        CurrentModeKey,
        ModeStoreImpl.STORAGE_KEY,
        () => {
          const initial: CurrentModeKey = new CurrentModeKey();
          initial.value = AppConstants.MODE_STANDARD;
          return initial;
        }
      )!;
      modeRef.value = mode;
      Logger.info(AppConstants.SCENE_COMMON, { action: 'mode_set', mode });
    } catch (err) {
      Logger.error(AppConstants.SCENE_COMMON, { action: 'mode_set_fail', mode, error: (err as Error).message });
    }
  }

  /** 读取当前模式（先从 AppStorageV2，再从 Preferences） */
  async getMode(): Promise<string> {
    const modeRef: CurrentModeKey = AppStorageV2.connect(
      CurrentModeKey,
      ModeStoreImpl.STORAGE_KEY,
      () => {
        const initial: CurrentModeKey = new CurrentModeKey();
        initial.value = AppConstants.MODE_STANDARD;
        return initial;
      }
    )!;
    if (modeRef.value && modeRef.value.length > 0) {
      return modeRef.value;
    }
    const persisted: string = await PreferencesUtil.getString(AppConstants.KEY_MODE, AppConstants.MODE_STANDARD);
    modeRef.value = persisted;
    return persisted;
  }

  /**
   * 页面/组件连接到当前模式状态 ref（响应式）
   * spec 10.18：页面用 @Local modeRef = ModeStore.connectModeRef() 持有，
   * 在 build() 中读取 modeRef.value 即可自动响应 setMode 广播。
   * @returns AppStorageV2 中 currentMode 的共享实例（已 @Trace value）
   */
  connectModeRef(): CurrentModeKey {
    return AppStorageV2.connect(
      CurrentModeKey,
      ModeStoreImpl.STORAGE_KEY,
      () => {
        const initial: CurrentModeKey = new CurrentModeKey();
        initial.value = AppConstants.MODE_STANDARD;
        return initial;
      }
    )!;
  }

  /** 切换模式（标准 ↔ 老年） */
  async toggleMode(): Promise<string> {
    const current: string = await this.getMode();
    const next: string = current === AppConstants.MODE_STANDARD ? AppConstants.MODE_ELDER : AppConstants.MODE_STANDARD;
    await this.setMode(next);
    return next;
  }

  /** 是否老年大字模式 */
  async isElderMode(): Promise<boolean> {
    const mode: string = await this.getMode();
    return mode === AppConstants.MODE_ELDER;
  }

  /**
   * 应用启动时初始化模式
   * 在 EntryAbility.onCreate 中调用
   */
  async initMode(): Promise<void> {
    const mode: string = await this.getMode();
    const modeRef: CurrentModeKey = AppStorageV2.connect(
      CurrentModeKey,
      ModeStoreImpl.STORAGE_KEY,
      () => {
        const initial: CurrentModeKey = new CurrentModeKey();
        initial.value = AppConstants.MODE_STANDARD;
        return initial;
      }
    )!;
    modeRef.value = mode;
    Logger.info(AppConstants.SCENE_COMMON, { action: 'mode_init', mode });
  }
}

/** 全局 Mode 单例 */
export const ModeStore: ModeStoreImpl = new ModeStoreImpl();
