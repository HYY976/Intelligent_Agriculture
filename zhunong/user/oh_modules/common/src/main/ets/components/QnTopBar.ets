/**
 * QnTopBar - 顶部导航栏组件
 * 对齐设计稿 .qn-topbar：左返回按钮 / 中标题 / 右图标按钮
 * spec 15.4.1：13 个公共组件之一
 */

import { AppConstants } from '../constants/AppConstants';

@ComponentV2
export struct QnTopBar {
  /** 居中标题 */
  @Param title: string = '';
  /** 是否显示左侧返回按钮（默认 true） */
  @Param showBack: boolean = true;
  /** 右侧图标资源（可选，不传则不展示） */
  @Param rightIcon: Resource | null = null;
  /** 标题颜色（默认主文字色） */
  @Param textColor: Resource = $r('app.color.color_text_primary');
  /** 左侧返回回调 */
  @Event onBack: () => void = () => {};
  /** 右侧图标点击回调 */
  @Event onRightClick: () => void = () => {};

  build() {
    Row() {
      // 左侧：返回按钮（圆形白底 + 阴影）
      if (this.showBack) {
        Text('‹')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.color_text_primary'))
          .width(32)
          .height(32)
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_bg_card'))
          .shadow(AppConstants.SHADOW_CARD)
          .textAlign(TextAlign.Center)
          .onClick(() => this.onBack())
      } else {
        Text('').width(32).height(32)
      }

      // 中间标题
      Text(this.title)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textColor)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 右侧图标按钮
      if (this.rightIcon !== null) {
        Stack({ alignContent: Alignment.Center }) {
          Image(this.rightIcon)
            .width(20)
            .height(20)
            .fillColor($r('app.color.color_text_primary'))
        }
        .width(32)
        .height(32)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor($r('app.color.color_bg_card'))
        .shadow(AppConstants.SHADOW_CARD)
        .onClick(() => this.onRightClick())
      } else {
        Text('').width(32).height(32)
      }
    }
    .width('100%')
    .padding({ top: 4, bottom: 10, left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
  }
}
