/**
 * QnButton - 按钮组件
 * 对齐设计稿 .qn-btn 全系列：
 *  - variant: primary(黑底白字) / yellow(黄底黑字) / green(绿底白字) / ghost(灰底灰字) / line(白底描边)
 *  - size: normal(46px) / sm(32px)
 *  - block: 全宽
 *  - pill: 胶囊圆角
 * spec 15.4.1：13 个公共组件之一
 */

import { AppConstants } from '../constants/AppConstants';

/** 按钮变体 */
export type QnButtonVariant = 'primary' | 'yellow' | 'green' | 'ghost' | 'line';

/** 按钮尺寸 */
export type QnButtonSize = 'normal' | 'sm';

@ComponentV2
export struct QnButton {
  /** 按钮文字 */
  @Param text: string = '';
  /** 变体（默认 primary 黑底白字，对齐 .qn-btn-primary） */
  @Param variant: QnButtonVariant = 'primary';
  /** 尺寸（默认 normal 46px） */
  @Param sizeType: QnButtonSize = 'normal';
  /** 是否全宽（对齐 .qn-btn-block） */
  @Param block: boolean = false;
  /** 是否胶囊形（对齐 .qn-btn-pill） */
  @Param pill: boolean = false;
  /** 是否禁用 */
  @Param disabled: boolean = false;
  /** 点击回调 */
  @Event on_click: () => void = () => {};

  build() {
    Button(this.text)
      .type(ButtonType.Normal)
      .height(this.sizeType === 'sm' ? 32 : 46)
      .borderRadius(this.pill ? AppConstants.RADIUS_PILL : AppConstants.RADIUS_MD)
      .backgroundColor(this.getBgColor())
      .fontColor(this.getFontColor())
      .fontSize(this.sizeType === 'sm' ? 13 : 15)
      .fontWeight(FontWeight.Bold)
      .width(this.block ? '100%' : undefined)
      .padding({ left: this.sizeType === 'sm' ? 14 : 20, right: this.sizeType === 'sm' ? 14 : 20 })
      .enabled(!this.disabled)
      .border(this.variant === 'line' ? { width: 1, color: $r('app.color.color_line_2') } : { width: 0 })
      .onClick(() => this.on_click())
  }

  /** 获取背景色 */
  private getBgColor(): ResourceColor {
    if (this.disabled) {
      return $r('app.color.color_button_disabled');
    }
    switch (this.variant) {
      case 'primary':
        return $r('app.color.color_ink');
      case 'yellow':
        return $r('app.color.color_yellow');
      case 'green':
        return $r('app.color.color_green');
      case 'ghost':
        return $r('app.color.color_fill');
      case 'line':
        return $r('app.color.color_bg_card');
      default:
        return $r('app.color.color_ink');
    }
  }

  /** 获取文字色 */
  private getFontColor(): ResourceColor {
    switch (this.variant) {
      case 'primary':
        return Color.White;
      case 'yellow':
        return $r('app.color.color_ink');
      case 'green':
        return Color.White;
      case 'ghost':
        return $r('app.color.color_text_2');
      case 'line':
        return $r('app.color.color_ink');
      default:
        return Color.White;
    }
  }
}
