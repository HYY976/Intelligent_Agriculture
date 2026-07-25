/**
 * ProductCard - 商品卡片组件（双列瀑布流用）
 * 对齐设计稿 .qn-prod：白底圆角软阴影 + 1:1 主图 + 产地标签 + 卖家头像 + 价格行
 * spec 15.4 / 3.1.3.1：用于首页推荐流、商品列表、搜索结果商品 Tab
 */

import { ProductListItem } from '../model/ProductModels';
import { ImageUtil } from '../utils/ImageUtil';
import { AppConstants } from 'common';

@ComponentV2
export struct ProductCard {
  /** 商品列表项数据 */
  @Param item: ProductListItem | null = null;
  /** 点击回调 */
  @Event onCardClick: (productId: string) => void = () => {};

  build() {
    Column() {
      // 商品主图 + 产地标签
      Stack({ alignContent: Alignment.TopStart }) {
        Image(this.item ? ImageUtil.get(this.item.mainImage) : ImageUtil.getDefaultProduct())
          .width('100%')
          .aspectRatio(1)
          .objectFit(ImageFit.Cover)
        // 产地标签（绿色圆角小标，对齐 .qn-prod-tag）
        if (this.item && this.item.shipFrom.length > 0) {
          Row({ space: 3 }) {
            Text('📍')
              .fontSize(8)
            Text(this.item.shipFrom)
              .fontSize(10)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Medium)
          }
          .backgroundColor($r('app.color.color_green'))
          .borderRadius(AppConstants.RADIUS_XS)
          .padding({ left: 7, right: 7, top: 2, bottom: 2 })
          .margin({ left: 8, top: 8 })
        }
      }
      .width('100%')
      .aspectRatio(1)

      // 商品信息区（对齐 .qn-prod-body：padding 10/11/12）
      Column({ space: 8 }) {
        // 商品标题（最多2行，对齐 .qn-prod-name）
        Text(this.item ? this.item.title : '')
          .fontSize(13)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Medium)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .lineHeight(18)
          .height(36)

        // 卖家行（头像 + 昵称，对齐 .qn-prod-farmer）
        Row({ space: 5 }) {
          Image(ImageUtil.getDefaultAvatar())
            .width(20)
            .height(20)
            .borderRadius(10)
            .objectFit(ImageFit.Cover)
          Text(this.item ? this.item.farmerName : '')
            .fontSize(11)
            .fontColor($r('app.color.color_text_2'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')

        // 价格 + 月销量（对齐 .qn-prod-price-row）
        Row() {
          // 价格（对齐 .qn-price：¥ 符号小 + 整数大）
          Text('¥')
            .fontSize(12)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
          Text(this.item ? this.formatPrice(this.item.price) : '0.0')
            .fontSize(20)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
          Blank()
          // 月销量（对齐 .qn-prod-sale）
          Text(this.item ? `月销${this.formatSales(this.item.monthlySales)}` : '')
            .fontSize(10)
            .fontColor($r('app.color.color_text_3'))
        }
        .width('100%')
        .alignItems(VerticalAlign.Bottom)
      }
      .width('100%')
      .padding({ left: 11, right: 11, top: 10, bottom: 12 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_MD)
    .clip(true)
    .shadow(AppConstants.SHADOW_CARD)
    .onClick(() => {
      if (this.item) {
        this.onCardClick(this.item.productId);
      }
    })
  }

  /** 格式化价格（保留1位小数，对齐设计稿 29.9 / 58.0） */
  private formatPrice(price: number): string {
    return price.toFixed(1);
  }

  /** 格式化月销量（>=1000 显示 k，对齐设计稿 月销1.2k / 月销856） */
  private formatSales(count: number): string {
    if (count >= 1000) {
      return `${(count / 1000).toFixed(1)}k`;
    }
    return `${count}`;
  }
}
