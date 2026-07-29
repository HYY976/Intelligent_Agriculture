/**
 * QnStatusBar - 顶部状态栏占位组件
 * 对齐设计稿 .qn-statusbar：高度 44vp，左侧时间（默认 9:41），右侧信号/Wi-Fi/电池图标
 * spec 15.4.1：13 个公共组件之一
 */

import { AppConstants } from '../constants/AppConstants';

@ComponentV2
export struct QnStatusBar {
  /** 左上角时间文字（默认 "9:41"，对齐 iOS 设计稿规范） */
  @Param title: string = '9:41';
  /** 文字颜色（默认主文字色，深色面板可传 color_text_on_dark） */
  @Param textColor: Resource = $r('app.color.color_text_primary');

  build() {
    Row() {
      // 左侧时间
      Text(this.title)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textColor)

      // 右侧图标组（信号 / Wi-Fi / 电池）
      Row({ space: 6 }) {
        Text('▰▰▰▰')
          .fontSize(12)
          .fontColor(this.textColor)
        Text('📶')
          .fontSize(12)
        Text('🔋')
          .fontSize(12)
      }
    }
    .width('100%')
    .height(AppConstants.STATUSBAR_HEIGHT)
    .padding({ left: 22, right: 18 })
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
  }
}
