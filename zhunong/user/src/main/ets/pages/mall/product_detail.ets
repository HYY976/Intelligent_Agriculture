/**
 * product_detail - 商品详情页
 * 遵循 spec 3.1.4.1：
 *  - 顶部商品轮播图（多图 Swiper）
 *  - 商品标题 + 价格 + 月销 + 库存
 *  - SKU 多规格选择
 *  - 运费 + 发货地
 *  - 商品详情描述
 *  - 评价区（5星评分 + 文字 + 多图 + 卖家回复）
 *  - 底部操作栏：客服/店铺/收藏/加入购物车/立即购买
 */

import { UserRoutes, RouteName, NavigationHelper, Logger, AppConstants, ToastUtil } from 'common';
import { Product, ProductSku, ProductSkuSpec } from '../../model/ProductModels';
import { Review } from '../../model/ProductModels';
import { getMockProductById, MOCK_FARMER_NAMES, getMockCategoryPath } from '../../mock/ProductMock';
import { getMockReviewsByProductId, getMockReviewStats, ReviewStats } from '../../mock/ReviewMock';
import { addToMockCart } from '../../mock/CartMock';
import { ImageUtil } from '../../utils/ImageUtil';
import { StarRating } from '../../components/StarRating';

/** 跳转确认订单的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface OrderConfirmParam {
  buyNow: number;
  productId: string;
  skuId: string;
  quantity: number;
}

@ComponentV2
export struct ProductDetail {
  /** 商品 ID */
  @Local productId: string = '';
  /** 商品详情 */
  @Local product: Product | null = null;
  /** 评价列表 */
  @Local reviews: Review[] = [];
  /** 评价统计 */
  @Local reviewStats: ReviewStats = { avgRating: 5, totalCount: 0, goodRate: 100 };
  /** 当前轮播图索引 */
  @Local currentImageIndex: number = 0;
  /** 当前选中的 SKU 索引 */
  @Local selectedSkuIndex: number = 0;
  /** 购买数量 */
  @Local quantity: number = 1;
  /** 是否已收藏 */
  @Local isFavorited: boolean = false;

  aboutToAppear(): void {
    const params: Record<string, string> = NavigationHelper.getParam<Record<string, string>>() as Record<string, string>;
    if (params) {
      this.productId = params.productId ?? '';
    }
    this.loadProductDetail();
  }

  /** 加载商品详情 */
  private loadProductDetail(): void {
    this.product = getMockProductById(this.productId);
    if (this.product) {
      this.reviews = getMockReviewsByProductId(this.productId);
      this.reviewStats = getMockReviewStats(this.productId);
      Logger.info(AppConstants.SCENE_USER, JSON.stringify({
        action: 'product_detail_view',
        productId: this.productId,
        reviewCount: this.reviews.length
      }));
    } else {
      ToastUtil.error('商品不存在');
      NavigationHelper.pop();
    }
  }

  /** 切换 SKU */
  private onSkuSelect(index: number): void {
    this.selectedSkuIndex = index;
    this.quantity = 1;
  }

  /** 加入购物车 */
  private onAddToCart(): void {
    if (!this.product) {
      return;
    }
    const sku: ProductSku = this.product.skuList[this.selectedSkuIndex];
    addToMockCart(this.productId, sku.skuId, this.quantity);
    ToastUtil.success('已加入购物车');
    Logger.info(AppConstants.SCENE_USER, JSON.stringify({
      action: 'add_to_cart',
      productId: this.productId,
      skuId: sku.skuId,
      quantity: this.quantity
    }));
  }

  /** 立即购买 */
  private onBuyNow(): void {
    if (!this.product) {
      return;
    }
    const sku: ProductSku = this.product.skuList[this.selectedSkuIndex];
    Logger.info(AppConstants.SCENE_USER, JSON.stringify({
      action: 'buy_now',
      productId: this.productId,
      skuId: sku.skuId,
      quantity: this.quantity
    }));
    // 跳转确认订单页（通过 params 传递立即购买信息）
    const param: OrderConfirmParam = { buyNow: 1, productId: this.productId, skuId: sku.skuId, quantity: this.quantity };
    NavigationHelper.push(RouteName.USER_ORDER_CONFIRM, param);
  }

  /** 切换收藏 */
  private onToggleFavorite(): void {
    this.isFavorited = !this.isFavorited;
    ToastUtil.success(this.isFavorited ? '已收藏' : '已取消收藏');
  }

  /** 跳转店铺主页（Phase 3 占位） */
  private gotoShop(): void {
    ToastUtil.show('店铺主页将在后续阶段实现');
  }

  /** 跳转客服（Phase 3 占位） */
  private gotoChat(): void {
    ToastUtil.show('客服会话将在后续阶段实现');
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部栏
        Row() {
          Text('‹')
            .fontSize(28)
            .fontColor($r('app.color.color_text_primary'))
            .onClick(() => {
              NavigationHelper.pop();
            })
          Blank()
          Text('商品详情')
            .fontSize(16)
            .fontColor($r('app.color.color_text_primary'))
            .fontWeight(FontWeight.Medium)
          Blank()
          Text('🛒')
            .fontSize(22)
            .onClick(() => {
              NavigationHelper.push(RouteName.USER_CART);
            })
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor($r('app.color.color_bg_card'))
        .alignItems(VerticalAlign.Center)

        // 内容区
        Scroll() {
          Column({ space: 12 }) {
            if (this.product) {
              // 商品轮播图
              this.ImageCarousel()
              // 商品基本信息
              this.ProductInfoCard()
              // SKU 选择
              this.SkuSelector()
              // 运费发货地
              this.ShipInfoCard()
              // 商品详情描述
              this.DescriptionCard()
              // 评价区
              this.ReviewSection()
            }
          }
          .width('100%')
          .padding({ bottom: 80 })
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor($r('app.color.color_bg_page'))
        .scrollBar(BarState.Off)

        // 底部操作栏
        if (this.product) {
          this.BottomActionBar()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 商品轮播图 */
  @Builder
  ImageCarousel() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Swiper() {
        ForEach(this.product!.mainImages, (imgKey: string, _i: number) => {
          Image(ImageUtil.get(imgKey))
            .width('100%')
            .aspectRatio(1)
            .objectFit(ImageFit.Cover)
        }, (imgKey: string, i: number) => `${imgKey}_${i}`)
      }
      .indicator(true)
      .onChange((index: number) => {
        this.currentImageIndex = index;
      })

      // 图片索引指示器
      Text(`${this.currentImageIndex + 1}/${this.product!.mainImages.length}`)
        .fontSize(11)
        .fontColor(Color.White)
        .backgroundColor('rgba(0,0,0,0.5)')
        .borderRadius(10)
        .padding({ left: 8, right: 8, top: 2, bottom: 2 })
        .margin({ right: 12, bottom: 12 })
    }
    .width('100%')
    .aspectRatio(1)
  }

  /** 商品基本信息卡片 */
  @Builder
  ProductInfoCard() {
    Column({ space: 8 }) {
      // 价格行
      Row({ space: 4 }) {
        Text('¥')
          .fontSize(14)
          .fontColor($r('app.color.color_price'))
          .fontWeight(FontWeight.Bold)
        Text(this.product!.price.toFixed(2))
          .fontSize(26)
          .fontColor($r('app.color.color_price'))
          .fontWeight(FontWeight.Bold)
        Blank()
        Text(`月销 ${this.product!.monthlySales}`)
          .fontSize(12)
          .fontColor($r('app.color.color_text_secondary'))
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)

      // 标题
      Text(this.product!.title)
        .fontSize(15)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .lineHeight(22)

      // 库存 + 分类
      Row() {
        Text(`库存 ${this.product!.stock} 件`)
          .fontSize(12)
          .fontColor($r('app.color.color_text_secondary'))
        Blank()
        Text(getMockCategoryPath(this.product!.categoryId))
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(12)
    .margin({ left: 12, right: 12 })
  }

  /** SKU 选择 */
  @Builder
  SkuSelector() {
    Column({ space: 10 }) {
      Text('规格选择')
        .fontSize(14)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)

      // SKU 列表
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.product!.skuList, (sku: ProductSku, index: number) => {
          Text(this.formatSkuSpec(sku))
            .fontSize(13)
            .fontColor(this.selectedSkuIndex === index ? Color.White : $r('app.color.color_text_primary'))
            .backgroundColor(this.selectedSkuIndex === index ? $r('app.color.color_primary') : $r('app.color.color_bg_page'))
            .border({ width: 1, color: this.selectedSkuIndex === index ? $r('app.color.color_primary') : $r('app.color.color_divider') })
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .margin({ right: 8, bottom: 8 })
            .borderRadius(8)
            .onClick(() => {
              this.onSkuSelect(index);
            })
        }, (sku: ProductSku) => sku.skuId)
      }
      .width('100%')

      // 当前 SKU 价格 + 库存
      Row() {
        Text(`¥${this.product!.skuList[this.selectedSkuIndex].price.toFixed(2)}`)
          .fontSize(16)
          .fontColor($r('app.color.color_price'))
          .fontWeight(FontWeight.Bold)
        Blank()
        Text(`库存 ${this.product!.skuList[this.selectedSkuIndex].stock} 件`)
          .fontSize(12)
          .fontColor($r('app.color.color_text_secondary'))
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(12)
    .margin({ left: 12, right: 12 })
  }

  /** 运费发货地 */
  @Builder
  ShipInfoCard() {
    Column({ space: 8 }) {
      Row() {
        Text('发货地')
          .fontSize(13)
          .fontColor($r('app.color.color_text_secondary'))
          .width(72)
        Text(this.product!.shipFrom)
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
        Blank()
        Text(`🏪 ${MOCK_FARMER_NAMES[this.product!.farmerId] ?? '未知卖家'}`)
          .fontSize(12)
          .fontColor($r('app.color.color_primary'))
          .onClick(() => {
            this.gotoShop();
          })
      }
      .width('100%')
      Row() {
        Text('运费')
          .fontSize(13)
          .fontColor($r('app.color.color_text_secondary'))
          .width(72)
        Text(this.product!.freightTemplate)
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(12)
    .margin({ left: 12, right: 12 })
  }

  /** 商品详情描述 */
  @Builder
  DescriptionCard() {
    Column({ space: 10 }) {
      Text('商品详情')
        .fontSize(14)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)
      Text(this.product!.description)
        .fontSize(13)
        .fontColor($r('app.color.color_text_secondary'))
        .lineHeight(22)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(12)
    .margin({ left: 12, right: 12 })
  }

  /** 评价区 */
  @Builder
  ReviewSection() {
    Column({ space: 12 }) {
      // 评价标题
      Row() {
        Text('商品评价')
          .fontSize(14)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Medium)
        Blank()
        Text(`${this.reviewStats.avgRating}分 · 好评率${this.reviewStats.goodRate}%`)
          .fontSize(12)
          .fontColor($r('app.color.color_text_secondary'))
      }
      .width('100%')

      // 评价列表
      if (this.reviews.length > 0) {
        ForEach(this.reviews, (review: Review, _i: number) => {
          this.ReviewItem(review)
        }, (review: Review) => review.reviewId)
      } else {
        Text('暂无评价')
          .fontSize(13)
          .fontColor($r('app.color.color_text_hint'))
          .padding(16)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(12)
    .margin({ left: 12, right: 12 })
  }

  /** 单条评价 */
  @Builder
  ReviewItem(review: Review) {
    Column({ space: 8 }) {
      // 用户信息行
      Row({ space: 8 }) {
        Image(ImageUtil.get(review.buyerAvatar))
          .width(32)
          .height(32)
          .borderRadius(16)
        Column({ space: 2 }) {
          Text(review.buyerNickname)
            .fontSize(13)
            .fontColor($r('app.color.color_text_primary'))
            .fontWeight(FontWeight.Medium)
          StarRating({ rating: review.rating, starSize: 12 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text(this.formatTime(review.createdAt))
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')

      // 评价内容
      Text(review.content)
        .fontSize(13)
        .fontColor($r('app.color.color_text_primary'))
        .lineHeight(20)

      // 评价图片
      if (review.images.length > 0) {
        Row({ space: 6 }) {
          ForEach(review.images, (imgKey: string, _j: number) => {
            Image(ImageUtil.get(imgKey))
              .width(72)
              .height(72)
              .borderRadius(6)
              .objectFit(ImageFit.Cover)
          }, (imgKey: string, j: number) => `${imgKey}_${j}`)
        }
        .width('100%')
      }

      // 卖家回复
      if (review.farmerReply && review.farmerReply.length > 0) {
        Column({ space: 4 }) {
          Text('卖家回复')
            .fontSize(11)
            .fontColor($r('app.color.color_text_secondary'))
          Text(review.farmerReply)
            .fontSize(12)
            .fontColor($r('app.color.color_text_secondary'))
            .lineHeight(18)
        }
        .width('100%')
        .padding(10)
        .backgroundColor($r('app.color.color_bg_page'))
        .borderRadius(8)
      }

      Divider().color($r('app.color.color_divider')).margin({ top: 4 })
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }

  /** 底部操作栏 */
  @Builder
  BottomActionBar() {
    Row({ space: 8 }) {
      // 客服
      Column({ space: 2 }) {
        Text('💬').fontSize(20)
        Text('客服').fontSize(10).fontColor($r('app.color.color_text_secondary'))
      }
      .width(48)
      .height(48)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        this.gotoChat();
      })

      // 店铺
      Column({ space: 2 }) {
        Text('🏪').fontSize(20)
        Text('店铺').fontSize(10).fontColor($r('app.color.color_text_secondary'))
      }
      .width(48)
      .height(48)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        this.gotoShop();
      })

      // 收藏
      Column({ space: 2 }) {
        Text(this.isFavorited ? '⭐' : '☆').fontSize(20)
        Text('收藏').fontSize(10).fontColor($r('app.color.color_text_secondary'))
      }
      .width(48)
      .height(48)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        this.onToggleFavorite();
      })

      // 加入购物车
      Button('加入购物车')
        .height(44)
        .borderRadius(22)
        .backgroundColor($r('app.color.color_primary'))
        .fontColor(Color.White)
        .fontSize(13)
        .layoutWeight(1)
        .onClick(() => {
          this.onAddToCart();
        })

      // 立即购买
      Button('立即购买')
        .height(44)
        .borderRadius(22)
        .backgroundColor($r('app.color.color_secondary'))
        .fontColor(Color.White)
        .fontSize(13)
        .layoutWeight(1)
        .onClick(() => {
          this.onBuyNow();
        })
    }
    .width('100%')
    .height(64)
    .padding({ left: 12, right: 12 })
    .backgroundColor($r('app.color.color_bg_card'))
    .border({ width: { top: 0.5 }, color: $r('app.color.color_divider') })
    .alignItems(VerticalAlign.Center)
  }

  /** 格式化 SKU 规格 */
  private formatSkuSpec(sku: ProductSku): string {
    return sku.specs.map((s: ProductSkuSpec) => `${s.name}:${s.value}`).join(' / ');
  }

  /** 格式化时间戳 */
  private formatTime(ts: number): string {
    const d: Date = new Date(ts);
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  }
}
