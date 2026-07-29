/**
 * QnPill - 胶囊标签组件
 * 对齐设计稿 .qn-pill 全系列：green(浅绿底深绿字) / yellow(浅黄底金字) / ink(黑底白字) / live(红底白字) / soft(灰底灰字)
 * spec 15.4.1：13 个公共组件之一
 */

import { AppConstants } from '../constants/AppConstants';

/** 胶囊变体 */
export type QnPillVariant = 'green' | 'yellow' | 'ink' | 'live' | 'soft';

@ComponentV2
export struct QnPill {
  /** 标签文字 */
  @Param text: string = '';
  /** 变体（默认 green 浅绿底深绿字，对齐 .qn-pill-green） */
  @Param variant: QnPillVariant = 'green';

  build() {
    Text(this.text)
      .fontSize(11)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.getFontColor())
      .backgroundColor(this.getBgColor())
      .borderRadius(AppConstants.RADIUS_PILL)
      .padding({ top: 3, bottom: 3, left: 10, right: 10 })
  }

  private getBgColor(): ResourceColor {
    switch (this.variant) {
      case 'green':
        return $r('app.color.color_green_soft');
      case 'yellow':
        return $r('app.color.color_yellow_soft');
      case 'ink':
        return $r('app.color.color_ink');
      case 'live':
        return $r('app.color.color_live');
      case 'soft':
        return $r('app.color.color_fill');
      default:
        return $r('app.color.color_green_soft');
    }
  }

  private getFontColor(): ResourceColor {
    switch (this.variant) {
      case 'green':
        return $r('app.color.color_green_deep');
      case 'yellow':
        return '#B8860B'; // 设计稿 .qn-pill-yellow 字色（深金）
      case 'ink':
        return Color.White;
      case 'live':
        return Color.White;
      case 'soft':
        return $r('app.color.color_text_2');
      default:
        return $r('app.color.color_green_deep');
    }
  }
}
