/**
 * QnPrice - 价格组件
 * 对齐设计稿 .qn-price（¥符号小 + 整数大 + 划线原价）
 * spec 15.4.1：13 个公共组件之一
 */

@ComponentV2
export struct QnPrice {
  /** 货币符号（默认 "¥"） */
  @Param symbol: string = '¥';
  /** 价格整数部分（或完整数字） */
  @Param intPart: string = '';
  /** 小数部分（可选） */
  @Param decimalPart: string = '';
  /** 原价（划线显示，可选） */
  @Param oldPrice: string = '';
  /** 字号（默认 20fp，对齐 .qn-price .int） */
  @Param fontSize: number = 20;

  build() {
    Row({ space: 6 }) {
      // 当前价格：¥符号小 + 整数大
      Text(this.symbol)
        .fontSize(this.fontSize - 8)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.color_live'))
      Text(this.intPart + (this.decimalPart.length > 0 ? this.decimalPart : ''))
        .fontSize(this.fontSize)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.color_live'))

      // 原价（划线）
      if (this.oldPrice.length > 0) {
        Text(this.oldPrice)
          .fontSize(12)
          .fontColor($r('app.color.color_text_4'))
          .decoration({ type: TextDecorationType.LineThrough })
      }
    }
    .alignItems(VerticalAlign.Bottom)
  }
}
