/**
 * ErrorToast - 操作失败 Toast 工具函数
 * 遵循 spec 2.3.5.4：
 *  - 操作失败时底部弹出 Toast（2秒自动消失）
 *  - 文案示例："加入购物车失败，请重试"
 *  - 错误信息同步写入 Logger
 *
 * 实际为 ToastUtil.error 的语义化封装，便于业务代码调用
 */

import { ToastUtil } from '../utils/ToastUtil';
import { Logger } from '../utils/Logger';
import { AppConstants } from '../constants/AppConstants';

export class ErrorToast {
  /** 操作失败 Toast（默认2秒） */
  static show(msg: string, scene: string = AppConstants.SCENE_COMMON): void {
    Logger.error(scene, { action: 'operation_fail', msg });
    ToastUtil.error(msg, 2000);
  }

  /** 加入购物车失败 */
  static cartFail(scene: string = AppConstants.SCENE_COMMON): void {
    ErrorToast.show('加入购物车失败，请重试', scene);
  }

  /** 下单失败 */
  static orderFail(scene: string = AppConstants.SCENE_COMMON): void {
    ErrorToast.show('下单失败，请重试', scene);
  }

  /** 提交失败 */
  static submitFail(scene: string = AppConstants.SCENE_COMMON): void {
    ErrorToast.show('提交失败，请重试', scene);
  }

  /** 网络异常 */
  static networkFail(scene: string = AppConstants.SCENE_COMMON): void {
    ErrorToast.show('网络连接失败，请检查网络后重试', scene);
  }

  /** 服务异常 */
  static serviceError(scene: string = AppConstants.SCENE_COMMON): void {
    ErrorToast.show('服务异常，请稍后重试', scene);
  }

  /** AI 超时 */
  static aiTimeout(scene: string = AppConstants.SCENE_COMMON): void {
    ErrorToast.show('AI生成超时，请重试', scene);
  }

  /** 限流 */
  static rateLimited(scene: string = AppConstants.SCENE_COMMON): void {
    ErrorToast.show('操作过于频繁，请稍后再试', scene);
  }
}
