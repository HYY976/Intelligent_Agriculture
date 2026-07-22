/**
 * ProductCard - 商品卡片组件（双列瀑布流用）
 * 遵循 spec 3.1.3.1：商品主图 + 标题 + 价格 + 月销量 + 卖家名 + 发货地
 * 用于首页推荐流、商品列表、搜索结果商品 Tab
 */

import { ProductListItem } from '../model/ProductModels';
import { ImageUtil } from '../utils/ImageUtil';

@ComponentV2
export struct ProductCard {
  /** 商品列表项数据 */
  @Param item: ProductListItem | null = null;
  /** 点击回调 */
  @Event onCardClick: (productId: string) => void = () => {};

  build() {
    Column() {
      // 商品主图
      Stack({ alignContent: Alignment.BottomStart }) {
        Image(this.item ? ImageUtil.get(this.item.mainImage) : ImageUtil.getDefaultProduct())
          .width('100%')
          .aspectRatio(1)
          .borderRadius({ topLeft: 12, topRight: 12 })
          .objectFit(ImageFit.Cover)
        // 发货地标签
        if (this.item) {
          Text(this.item.shipFrom)
            .fontSize(10)
            .fontColor(Color.White)
            .backgroundColor('rgba(0,0,0,0.5)')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius({ topRight: 8, bottomRight: 8 })
        }
      }
      .width('100%')
      .aspectRatio(1)

      // 商品信息区
      Column({ space: 6 }) {
        // 商品标题（最多2行）
        Text(this.item ? this.item.title : '')
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .lineHeight(18)

        // 卖家名
        Row({ space: 4 }) {
          Text('🏪')
            .fontSize(11)
          Text(this.item ? this.item.farmerName : '')
            .fontSize(11)
            .fontColor($r('app.color.color_text_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')

        // 价格 + 月销量
        Row() {
          Text('¥')
            .fontSize(11)
            .fontColor($r('app.color.color_price'))
            .fontWeight(FontWeight.Bold)
          Text(this.item ? this.item.price.toFixed(2) : '0.00')
            .fontSize(17)
            .fontColor($r('app.color.color_price'))
            .fontWeight(FontWeight.Bold)
          Blank()
          Text(this.item ? `月销 ${this.formatSales(this.item.monthlySales)}` : '')
            .fontSize(10)
            .fontColor($r('app.color.color_text_hint'))
        }
        .width('100%')
        .alignItems(VerticalAlign.Bottom)
      }
      .width('100%')
      .padding(8)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(12)
    .clip(true)
    .onClick(() => {
      if (this.item) {
        this.onCardClick(this.item.productId);
      }
    })
  }

  /** 格式化月销量（>=10000 显示万） */
  private formatSales(count: number): string {
    if (count >= 10000) {
      return `${(count / 10000).toFixed(1)}万`;
    }
    return `${count}`;
  }
}
