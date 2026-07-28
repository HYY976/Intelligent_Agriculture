/**
 * ImageReplaceStore - 全局图片替换存储（演示用）
 * 存储 imageKey → file:// URI 的映射
 * 使用 @ObservedV2 + @Trace version 实现 V2 响应式：
 *   ReplaceableImage 在 build() 中读取 version，version 变化时全部同 key 组件自动刷新
 *
 * 持久化：开屏广告等关键替换会同步到 Preferences，应用重启后仍生效
 */

import { PreferencesUtil, Logger, AppConstants } from 'common';

/** Preferences 中存储映射关系的 key */
const PREF_KEY_IMAGE_REPLACE_MAP: string = 'image_replace_map';

@ObservedV2
export class ImageReplaceStore {
  private static instance: ImageReplaceStore | null = null;

  /** 响应式版本号：每次 set/clear 自增，驱动所有 ReplaceableImage 重新渲染 */
  @Trace version: number = 0;

  /** 内部映射表（非响应式，通过 version 间接驱动刷新） */
  private replacements: Map<string, string> = new Map<string, string>();

  private constructor() {}

  /** 获取单例 */
  static getInstance(): ImageReplaceStore {
    if (ImageReplaceStore.instance === null) {
      ImageReplaceStore.instance = new ImageReplaceStore();
    }
    return ImageReplaceStore.instance;
  }

  /** 从 Preferences 加载持久化的映射关系（应用启动时调用） */
  static async loadFromPreferences(): Promise<void> {
    try {
      const raw: string = await PreferencesUtil.getString(PREF_KEY_IMAGE_REPLACE_MAP, '');
      if (raw.length > 0) {
        const obj: Record<string, string> = JSON.parse(raw) as Record<string, string>;
        const inst: ImageReplaceStore = ImageReplaceStore.getInstance();
        Object.keys(obj).forEach((key: string) => {
          inst.replacements.set(key, obj[key]);
        });
        inst.version++;
        Logger.info(AppConstants.SCENE_USER, {
          action: 'image_replace_load',
          msg: `loaded ${inst.replacements.size} replacements`
        });
      }
    } catch (err) {
      Logger.error(AppConstants.SCENE_USER, {
        action: 'image_replace_load_fail',
        error: (err as Error).message
      });
    }
  }

  /** 获取替换 URI（未替换则返回 undefined） */
  static getUri(key: string): string | undefined {
    return ImageReplaceStore.getInstance().replacements.get(key);
  }

  /** 设置替换图片（version++ 触发全局刷新，异步持久化到 Preferences） */
  static set(key: string, uri: string): void {
    const inst: ImageReplaceStore = ImageReplaceStore.getInstance();
    inst.replacements.set(key, uri);
    inst.version++;
    // 异步持久化（不阻塞 UI）
    ImageReplaceStore.persistToPreferences();
  }

  /** 是否已替换 */
  static has(key: string): boolean {
    return ImageReplaceStore.getInstance().replacements.has(key);
  }

  /** 清除所有替换（version++ 触发全局刷新，异步清除 Preferences） */
  static clear(): void {
    const inst: ImageReplaceStore = ImageReplaceStore.getInstance();
    inst.replacements.clear();
    inst.version++;
    PreferencesUtil.remove(PREF_KEY_IMAGE_REPLACE_MAP);
  }

  /** 异步将当前映射关系持久化到 Preferences */
  private static persistToPreferences(): void {
    const inst: ImageReplaceStore = ImageReplaceStore.getInstance();
    const obj: Record<string, string> = {};
    inst.replacements.forEach((value: string, key: string) => {
      obj[key] = value;
    });
    PreferencesUtil.putString(PREF_KEY_IMAGE_REPLACE_MAP, JSON.stringify(obj));
  }
}
