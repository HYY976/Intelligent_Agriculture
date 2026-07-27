/**
 * FontUtil - 字号工具（spec 16.6：老人模式全局字体放大）
 *
 * 用途：
 *  - 提供 isElder() 判定当前是否为老年大字模式
 *  - 提供 s(base) 将标准字号按模式放大（老年模式 ×1.3，标准模式 ×1.0）
 *  - 各页面通过 @Local modeRef = ModeStore.connectModeRef() 响应式刷新
 *    在 build() 中使用 FontUtil.s(14, this.modeRef.value === AppConstants.MODE_ELDER) 替代固定数字
 *
 * 设计原则：
 *  - 最小字号 14（老年模式最低 18），保证可读性
 *  - 大字号（≥18）放大倍率略低（×1.25），避免过度放大破坏布局
 *  - 标题/正文/辅助文字统一使用本工具，确保全局一致性
 */

import { AppConstants } from '../constants/AppConstants';

export class FontUtil {
  /** 标准模式放大倍率 */
  static readonly SCALE_STANDARD: number = 1.0;
  /** 老年模式放大倍率（小字号） */
  static readonly SCALE_ELDER: number = 1.3;
  /** 老年模式放大倍率（大字号 ≥18） */
  static readonly SCALE_ELDER_LARGE: number = 1.25;
  /** 大字号阈值（≥此值使用 SCALE_ELDER_LARGE） */
  static readonly LARGE_THRESHOLD: number = 18;
  /** 老年模式最小字号 */
  static readonly ELDER_MIN: number = 18;

  /**
   * 按模式放大字号
   * @param base 标准模式下的字号
   * @param isElder 是否老年大字模式
   * @returns 实际渲染字号
   */
  static s(base: number, isElder: boolean): number {
    if (!isElder) {
      return base;
    }
    const scale: number = base >= FontUtil.LARGE_THRESHOLD ? FontUtil.SCALE_ELDER_LARGE : FontUtil.SCALE_ELDER;
    const scaled: number = Math.round(base * scale);
    return scaled < FontUtil.ELDER_MIN ? FontUtil.ELDER_MIN : scaled;
  }

  /**
   * 判定模式值是否为老年大字
   */
  static isElder(modeValue: string): boolean {
    return modeValue === AppConstants.MODE_ELDER;
  }
}
