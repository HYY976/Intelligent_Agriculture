/**
 * QnInput - 输入框组件
 * 对齐设计稿 .qn-input（纯输入）/ .qn-field（带左图标 + 右动作按钮）
 * spec 15.4.1：13 个公共组件之一
 */

import { AppConstants } from '../constants/AppConstants';

/** 输入框类型 */
export type QnInputType = 'normal' | 'phone' | 'password' | 'number';

@ComponentV2
export struct QnInput {
  /** 占位文字 */
  @Param placeholder: string = '';
  /** 输入类型（默认 normal） */
  @Param inputType: QnInputType = 'normal';
  /** 左图标资源（可选，对齐 .qn-field-ico） */
  @Param icon: Resource | null = null;
  /** 右侧动作按钮文案（对齐 .qn-field-action，如 "获取验证码"） */
  @Param actionText: string = '';
  /** 右侧动作是否禁用（对齐 .is-disabled） */
  @Param actionDisabled: boolean = false;
  /** 最大长度 */
  @Param maxLength: number = 100;
  /** 当前输入值（受控） */
  @Param value: string = '';
  /** 输入回调 */
  @Event on_change: (val: string) => void = () => {};
  /** 右侧动作点击回调 */
  @Event on_action: () => void = () => {};

  build() {
    Row() {
      // 左图标
      if (this.icon !== null) {
        Image(this.icon)
          .width(20)
          .height(20)
          .fillColor($r('app.color.color_text_3'))
          .margin({ right: 10 })
      }

      // 输入框
      TextInput({ text: this.value, placeholder: this.placeholder })
        .layoutWeight(1)
        .type(this.mapInputType())
        .maxLength(this.maxLength)
        .backgroundColor(Color.Transparent)
        .borderRadius(0)
        .fontSize(14)
        .fontColor($r('app.color.color_ink'))
        .placeholderColor($r('app.color.color_text_4'))
        .placeholderFont({ size: 14 })
        .onChange((val: string) => this.on_change(val))

      // 右侧动作按钮
      if (this.actionText.length > 0) {
        Text(this.actionText)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.actionDisabled ? $r('app.color.color_text_4') : $r('app.color.color_ink'))
          .padding({ left: 12 })
          .margin({ left: 8 })
          .border({ width: { left: 1 }, color: $r('app.color.color_line_2') })
          .onClick(() => { if (!this.actionDisabled) this.on_action(); })
      }
    }
    .width('100%')
    .height(46)
    .borderRadius(AppConstants.RADIUS_MD)
    .backgroundColor($r('app.color.color_fill'))
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
  }

  private mapInputType(): InputType {
    switch (this.inputType) {
      case 'phone':
        return InputType.PhoneNumber;
      case 'password':
        return InputType.Password;
      case 'number':
        return InputType.Number;
      default:
        return InputType.Normal;
    }
  }
}
