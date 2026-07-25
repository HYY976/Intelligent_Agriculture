/**
 * QnCard - 通用卡片组件
 * 对齐设计稿 .qn-card（白底圆角软阴影） / .qn-card-yellow（黄渐变柔光阴影）
 * spec 15.4.1：13 个公共组件之一
 * 用法：
 * ```
 * QnCard({ variant: 'white' }) {
 *   Text('卡片内容')
 * }
 * ```
 */

import { AppConstants } from '../constants/AppConstants';

/** 卡片变体 */
export type QnCardVariant = 'white' | 'yellow';

@ComponentV2
export struct QnCard {
  /** 变体（默认 white 白底） */
  @Param variant: QnCardVariant = 'white';
  /** 内边距（默认 -1 自动：white=16vp / yellow=18vp） */
  @Param cardPadding: number = -1;
  /** 内容插槽 */
  @BuilderParam content: () => void;

  build() {
    if (this.variant === 'yellow') {
      // 黄渐变卡（对齐 .qn-card-yellow：linear-gradient 135deg + 柔光阴影）
      Column() {
        this.content()
      }
      .width('100%')
      .padding(this.cardPadding >= 0 ? this.cardPadding : 18)
      .borderRadius(AppConstants.RADIUS_LG)
      .linearGradient({
        angle: 135,
        colors: [[$r('app.color.color_yellow'), 0.0], [$r('app.color.color_yellow_deep'), 1.0]]
      })
      .shadow(AppConstants.SHADOW_YELLOW)
    } else {
      // 白底卡（对齐 .qn-card：白底圆角软阴影）
      Column() {
        this.content()
      }
      .width('100%')
      .padding(this.cardPadding >= 0 ? this.cardPadding : 16)
      .borderRadius(AppConstants.RADIUS_LG)
      .backgroundColor($r('app.color.color_bg_card'))
      .shadow(AppConstants.SHADOW_CARD)
    }
  }
}
