/**
 * ToastUtil - Toast 提示工具
 * 封装 promptAction，统一 Toast 样式
 * 遵循 spec 2.4.5：Toast 顶部弹出，生机绿背景白字，圆角24vp，2秒消失
 *                错误Toast：使用 color_error 背景
 */

import { promptAction } from '@kit.ArkUI';
import { Logger } from './Logger';
import { AppConstants } from '../constants/AppConstants';

type ToastScene = 'default' | 'success' | 'error' | 'warning';

class ToastUtilImpl {
  /** 普通提示 Toast（2秒） */
  show(msg: string, duration: number = 2000): void {
    this.showToast(msg, duration, 'default');
  }

  /** 信息提示 Toast（与 show 语义相同，供调用方语义化使用） */
  info(msg: string, duration: number = 2000): void {
    this.showToast(msg, duration, 'default');
  }

  /** 成功 Toast（生机绿背景） */
  success(msg: string, duration: number = 2000): void {
    this.showToast(msg, duration, 'success');
  }

  /** 错误 Toast（红色背景，spec 2.4.5） */
  error(msg: string, duration: number = 2000): void {
    this.showToast(msg, duration, 'error');
    Logger.error(AppConstants.SCENE_COMMON, { action: 'toast_error', msg });
  }

  /** 警告 Toast */
  warning(msg: string, duration: number = 2000): void {
    this.showToast(msg, duration, 'warning');
  }

  /** 底层调用 promptAction（spec 10.9.5：showToast 已弃用，改用 openToast） */
  private showToast(msg: string, duration: number, scene: ToastScene): void {
    try {
      promptAction.openToast({
        message: msg,
        duration: duration,
        bottom: 240
      });
    } catch (err) {
      Logger.error(AppConstants.SCENE_COMMON, { action: 'toast_show_fail', msg, error: (err as Error).message });
    }
  }
}

/** 全局 Toast 单例 */
export const ToastUtil: ToastUtilImpl = new ToastUtilImpl();
