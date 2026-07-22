/**
 * QuantitySelector - 数量选择器组件
 * 用于购物车商品数量调整、商品详情 SKU 选择数量
 */

@ComponentV2
export struct QuantitySelector {
  /** 当前数量 */
  @Param quantity: number = 1;
  /** 最小值 */
  @Param min: number = 1;
  /** 最大值（库存） */
  @Param max: number = 99;
  /** 数量变化回调 */
  @Event onQuantityChange: (quantity: number) => void = () => {};

  build() {
    Row() {
      // 减号
      Text('−')
        .fontSize(18)
        .fontColor(this.quantity <= this.min ? $r('app.color.color_text_hint') : $r('app.color.color_text_primary'))
        .width(28)
        .height(28)
        .textAlign(TextAlign.Center)
        .borderRadius({ topLeft: 4, bottomLeft: 4 })
        .backgroundColor($r('app.color.color_bg_page'))
        .onClick(() => {
          if (this.quantity > this.min) {
            this.onQuantityChange(this.quantity - 1);
          }
        })
      // 数量
      Text(`${this.quantity}`)
        .fontSize(14)
        .fontColor($r('app.color.color_text_primary'))
        .width(40)
        .height(28)
        .textAlign(TextAlign.Center)
        .backgroundColor($r('app.color.color_bg_card'))
        .border({ width: 0.5, color: $r('app.color.color_divider') })
      // 加号
      Text('+')
        .fontSize(18)
        .fontColor(this.quantity >= this.max ? $r('app.color.color_text_hint') : $r('app.color.color_text_primary'))
        .width(28)
        .height(28)
        .textAlign(TextAlign.Center)
        .borderRadius({ topRight: 4, bottomRight: 4 })
        .backgroundColor($r('app.color.color_bg_page'))
        .onClick(() => {
          if (this.quantity < this.max) {
            this.onQuantityChange(this.quantity + 1);
          }
        })
    }
    .height(28)
    .alignItems(VerticalAlign.Center)
  }
}
