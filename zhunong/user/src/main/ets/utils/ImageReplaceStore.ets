/**
 * ImageReplaceStore - 全局图片替换存储（演示用）
 * 存储 imageKey → file:// URI 的映射
 * 使用 @ObservedV2 + @Trace version 实现 V2 响应式：
 *   ReplaceableImage 在 build() 中读取 version，version 变化时全部同 key 组件自动刷新
 */

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

  /** 获取替换 URI（未替换则返回 undefined） */
  static getUri(key: string): string | undefined {
    return ImageReplaceStore.getInstance().replacements.get(key);
  }

  /** 设置替换图片（version++ 触发全局刷新） */
  static set(key: string, uri: string): void {
    const inst: ImageReplaceStore = ImageReplaceStore.getInstance();
    inst.replacements.set(key, uri);
    inst.version++;
  }

  /** 是否已替换 */
  static has(key: string): boolean {
    return ImageReplaceStore.getInstance().replacements.has(key);
  }

  /** 清除所有替换 */
  static clear(): void {
    const inst: ImageReplaceStore = ImageReplaceStore.getInstance();
    inst.replacements.clear();
    inst.version++;
  }
}
