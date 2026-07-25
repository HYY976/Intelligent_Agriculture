/**
 * QnSearchBar - 搜索栏组件
 * 对齐设计稿 .qn-search：胶囊形白底 + 阴影 + 左搜索图标 + 占位文字
 * spec 15.4.1：13 个公共组件之一
 */

import { AppConstants } from '../constants/AppConstants';

@ComponentV2
export struct QnSearchBar {
  /** 占位文字（默认 "搜索..."） */
  @Param placeholder: string = '搜索...';
  /** 当前输入值（受控） */
  @Param value: string = '';
  /** 输入回调 */
  @Event on_change: (val: string) => void = () => {};
  /** 提交回调（回车） */
  @Event on_submit: (q: string) => void = () => {};

  build() {
    Row({ space: 8 }) {
      Text('🔍')
        .fontSize(14)
      TextInput({ text: this.value, placeholder: this.placeholder })
        .layoutWeight(1)
        .backgroundColor(Color.Transparent)
        .borderRadius(0)
        .fontSize(13)
        .fontColor($r('app.color.color_ink'))
        .placeholderColor($r('app.color.color_text_3'))
        .placeholderFont({ size: 13 })
        .onChange((val: string) => this.on_change(val))
        .onSubmit((enterKey: EnterKeyType) => this.on_submit(this.value))
    }
    .width('100%')
    .height(40)
    .borderRadius(AppConstants.RADIUS_PILL)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
  }
}
