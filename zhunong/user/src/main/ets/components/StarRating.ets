/**
 * StarRating - 星级评分组件
 * 用于商品详情评价区、评价提交页
 */

@ComponentV2
export struct StarRating {
  /** 当前评分（0-5，支持半星显示） */
  @Param rating: number = 0;
  /** 星星大小 */
  @Param starSize: number = 16;
  /** 是否可交互 */
  @Param interactive: boolean = false;
  /** 评分变化回调（interactive=true 时触发） */
  @Event onRatingChange: (rating: number) => void = () => {};

  build() {
    Row({ space: 2 }) {
      ForEach([1, 2, 3, 4, 5], (star: number) => {
        Text(this.getStarChar(star))
          .fontSize(this.starSize)
          .fontColor(star <= Math.floor(this.rating) ? $r('app.color.color_accent_gold') : $r('app.color.color_divider'))
          .onClick(() => {
            if (this.interactive) {
              this.onRatingChange(star);
            }
          })
      }, (star: number) => `${star}`)
    }
    .alignItems(VerticalAlign.Center)
  }

  /** 获取星星字符（实心★ / 半星☆ / 空☆） */
  private getStarChar(star: number): string {
    if (star <= Math.floor(this.rating)) {
      return '★';
    }
    return '☆';
  }
}
