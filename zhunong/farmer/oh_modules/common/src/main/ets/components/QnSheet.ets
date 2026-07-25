/**
 * QnSheet - 底部弹出层组件
 * 对齐设计稿 .qn-mask + .qn-sheet：遮罩 rgba(0,0,0,0.45) + 圆角面板从底部弹出
 * spec 15.4.1：13 个公共组件之一
 * 方案 C 自建模态模式（@ComponentV2 + Stack + @BuilderParam 内容注入）
 *
 * 用法：
 * ```
 * Stack() {
 *   // 页面内容
 *   if (this.showSheet) {
 *     QnSheet({ show: this.showSheet, on_close: () => this.showSheet = false }) {
 *       Text('Sheet 内容')
 *     }
 *   }
 * }
 * ```
 */

import { AppConstants } from '../constants/AppConstants';

@ComponentV2
export struct QnSheet {
  /** 是否显示 */
  @Param show: boolean = false;
  /** 关闭回调（点击遮罩触发） */
  @Event on_close: () => void = () => {};
  /** 内容插槽 */
  @BuilderParam content: () => void;

  build() {
    if (this.show) {
      Stack({ alignContent: Alignment.Bottom }) {
        // 遮罩层
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0,0,0,0.45)')
          .onClick(() => this.on_close())

        // 底部面板
        Column() {
          this.content()
        }
        .width('100%')
        .backgroundColor($r('app.color.color_cream'))
        .borderRadius({ topLeft: AppConstants.RADIUS_XL, topRight: AppConstants.RADIUS_XL })
        .padding({ top: 20, bottom: 28, left: 16, right: 16 })
      }
      .width('100%')
      .height('100%')
    }
  }
}
