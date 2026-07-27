/**
 * product_detail - 商品详情页（对齐设计稿 product-detail.html）
 *  - 顶栏：返回 + 居中标题 + 分享/客服
 *  - 主图区：大图 320h + LIVE 徽标 + 收藏心形按钮
 *  - 缩略图横滑指示器
 *  - 标题价格卡：标题 + 副标题 + 价格 + 划线价 + 已售 + 服务标签
 *  - 农户信息卡：头像（黄色光环） + 昵称 + 认证标 + 地址 + 关注 + 进店箭头
 *  - 商品规格卡：产地/规格/保质期/储存方式 键值对
 *  - 图文详情区：黄色胶囊标题 + 多图 + 文字
 *  - 用户评价区：评分 + 5星 + 好评率 + 评价列表
 *  - 底部固定操作栏：客服 + 购物车(带角标) + 加入购物车(黄) + 立即购买(黑)
 */

import { RouteName, NavigationHelper, Logger, AppConstants, ToastUtil } from 'common';
import { Product, ProductSku, ProductSkuSpec, Review } from '../../model/ProductModels';
import { MOCK_FARMER_NAMES, MOCK_FARMER_AVATARS, getMockCategoryPath } from '../../mock/ProductMock';
import { ProductRepository } from '../../repository/ProductRepository';
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

/** 商品规格键值对（对齐设计稿 pd-spec-row） */
interface SpecRow {
  /** 键名（如：产地/规格/保质期/储存方式） */
  key: string;
  /** 键值 */
  value: string;
}

/** 服务标签（对齐设计稿 pd-tags） */
interface ServiceTag {
  /** 标签文字 */
  label: string;
  /** 标签样式：yellow / green / soft */
  style: 'yellow' | 'green' | 'soft';
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
  /** 当前主图索引 */
  @Local currentImageIndex: number = 0;
  /** 当前选中的 SKU 索引 */
  @Local selectedSkuIndex: number = 0;
  /** 购买数量 */
  @Local quantity: number = 1;
  /** 是否已收藏 */
  @Local isFavorited: boolean = false;
  /** 是否已关注农户 */
  @Local isFollowed: boolean = false;

  aboutToAppear(): void {
    const params: Record<string, string> = NavigationHelper.getParam<Record<string, string>>() as Record<string, string>;
    if (params) {
      this.productId = params.productId ?? '';
    }
    this.loadProductDetail();
  }

  /** 加载商品详情（spec 16.3：先查 SharedProductStore，再回退 mock） */
  private async loadProductDetail(): Promise<void> {
    this.product = await ProductRepository.getProductById(this.productId);
    if (this.product) {
      this.reviews = getMockReviewsByProductId(this.productId);
      this.reviewStats = getMockReviewStats(this.productId);
      Logger.info(AppConstants.SCENE_USER, {
        action: 'product_detail_view',
        productId: this.productId,
        count: this.reviews.length
      });
    } else {
      ToastUtil.error('商品不存在');
      NavigationHelper.pop();
    }
  }

  /** 切换主图 */
  private onThumbClick(index: number): void {
    this.currentImageIndex = index;
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
    Logger.info(AppConstants.SCENE_USER, {
      action: 'add_to_cart',
      productId: this.productId,
      skuId: sku.skuId,
      quantity: this.quantity
    });
  }

  /** 立即购买 */
  private onBuyNow(): void {
    if (!this.product) {
      return;
    }
    const sku: ProductSku = this.product.skuList[this.selectedSkuIndex];
    Logger.info(AppConstants.SCENE_USER, {
      action: 'buy_now',
      productId: this.productId,
      skuId: sku.skuId,
      quantity: this.quantity
    });
    const param: OrderConfirmParam = { buyNow: 1, productId: this.productId, skuId: sku.skuId, quantity: this.quantity };
    NavigationHelper.push(RouteName.USER_ORDER_CONFIRM, param);
  }

  /** 切换收藏 */
  private onToggleFavorite(): void {
    this.isFavorited = !this.isFavorited;
    ToastUtil.success(this.isFavorited ? '已收藏' : '已取消收藏');
  }

  /** 切换关注农户 */
  private onToggleFollow(): void {
    this.isFollowed = !this.isFollowed;
    ToastUtil.success(this.isFollowed ? '已关注' : '已取消关注');
  }

  /** 跳转店铺主页（Phase 3 占位） */
  private gotoShop(): void {
    ToastUtil.show('店铺主页将在后续阶段实现');
  }

  /** 跳转客服（Phase 3 占位） */
  private gotoChat(): void {
    ToastUtil.show('客服会话将在后续阶段实现');
  }

  /** 跳转购物车 */
  private gotoCart(): void {
    NavigationHelper.push(RouteName.USER_CART);
  }

  /** 跳转分享（Phase 3 占位） */
  private gotoShare(): void {
    ToastUtil.show('分享功能将在后续阶段实现');
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部栏（对齐设计稿 pd-topbar）
        this.TopBar()

        // 内容区
        Scroll() {
          Column({ space: 12 }) {
            if (this.product) {
              // 主图大图区 + 缩略图横滑
              this.HeroImageSection()
              // 标题价格卡
              this.TitlePriceCard()
              // 农户信息卡
              this.FarmerCard()
              // 商品规格卡
              this.SpecCard()
              // SKU 选择卡
              this.SkuSelector()
              // 图文详情区
              this.DetailImageSection()
              // 用户评价区
              this.ReviewSection()
            }
          }
          .width('100%')
          .padding({ bottom: 100 })
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor($r('app.color.color_bg_page'))
        .scrollBar(BarState.Off)

        // 底部固定操作栏
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

  /** 顶部栏（对齐设计稿 pd-topbar：返回 + 居中标题 + 分享/客服） */
  @Builder
  TopBar() {
    Row() {
      // 返回按钮（对齐设计稿 qn-icon-btn：白底圆 + 软阴影）
      Text('←')
        .fontSize(20)
        .fontColor($r('app.color.color_ink'))
        .width(32)
        .height(32)
        .textAlign(TextAlign.Center)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor('rgba(255,255,255,0.9)')
        .shadow(AppConstants.SHADOW_CARD)
        .onClick(() => {
          NavigationHelper.pop();
        })

      // 居中标题（对齐设计稿 qn-title-center）
      Text('商品详情')
        .fontSize(17)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 右侧操作：分享 + 客服
      Row({ space: 10 }) {
        Text('↗')
          .fontSize(18)
          .fontColor($r('app.color.color_ink'))
          .width(32)
          .height(32)
          .textAlign(TextAlign.Center)
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor('rgba(255,255,255,0.9)')
          .shadow(AppConstants.SHADOW_CARD)
          .onClick(() => {
            this.gotoShare();
          })
        Text('🎧')
          .fontSize(16)
          .fontColor($r('app.color.color_ink'))
          .width(32)
          .height(32)
          .textAlign(TextAlign.Center)
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor('rgba(255,255,255,0.9)')
          .shadow(AppConstants.SHADOW_CARD)
          .onClick(() => {
            this.gotoChat();
          })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 10 })
    .alignItems(VerticalAlign.Center)
  }

  /** 主图大图区 + 缩略图横滑（对齐设计稿 pd-hero + pd-thumbs） */
  @Builder
  HeroImageSection() {
    Column() {
      // 大图区（对齐设计稿 pd-hero：圆角 18 + 阴影 + 320 高）
      Stack({ alignContent: Alignment.TopEnd }) {
        Image(ImageUtil.get(this.product!.mainImages[this.currentImageIndex]))
          .width('100%')
          .height(320)
          .objectFit(ImageFit.Cover)
          .borderRadius(AppConstants.RADIUS_LG)

        // 右上角：LIVE 徽标 + 收藏心形（对齐设计稿 pd-hero-badge）
        Row({ space: 8 }) {
          // LIVE 徽标（对齐设计稿 qn-pill-live）
          Row({ space: 3 }) {
            Text('●')
              .fontSize(8)
              .fontColor(Color.White)
            Text('LIVE')
              .fontSize(10)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
          }
          .backgroundColor($r('app.color.color_live'))
          .borderRadius(AppConstants.RADIUS_PILL)
          .padding({ left: 7, right: 7, top: 2, bottom: 2 })

          // 收藏心形按钮（对齐设计稿 pd-fav：白底圆 + 红色心形）
          Text(this.isFavorited ? '♥' : '♡')
            .fontSize(20)
            .fontColor($r('app.color.color_live'))
            .width(34)
            .height(34)
            .textAlign(TextAlign.Center)
            .borderRadius(AppConstants.RADIUS_PILL)
            .backgroundColor('rgba(255,255,255,0.92)')
            .shadow(AppConstants.SHADOW_CARD)
            .onClick(() => {
              this.onToggleFavorite();
            })
        }
        .margin({ top: 12, right: 12 })
      }
      .width('100%')
      .height(320)
      .margin({ left: 16, right: 16, bottom: 10 })

      // 缩略图横滑指示（对齐设计稿 pd-thumbs）
      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.product!.mainImages, (imgKey: string, index: number) => {
            Stack() {
              Image(ImageUtil.get(imgKey))
                .width(52)
                .height(52)
                .borderRadius(AppConstants.RADIUS_SM)
                .objectFit(ImageFit.Cover)
            }
            .width(56)
            .height(56)
            .padding(2)
            .borderRadius(AppConstants.RADIUS_SM)
            .border({ width: 2, color: this.currentImageIndex === index ? $r('app.color.color_primary') : Color.Transparent })
            .backgroundColor($r('app.color.color_fill'))
            .onClick(() => {
              this.onThumbClick(index);
            })
          }, (imgKey: string, index: number) => `${imgKey}_${index}`)
        }
        .padding({ left: 16, right: 16, top: 10, bottom: 4 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('100%')
  }

  /** 标题价格卡（对齐设计稿 qn-card：标题 + 副标题 + 价格行 + 标签） */
  @Builder
  TitlePriceCard() {
    Column({ space: 0 }) {
      // 标题（对齐设计稿 pd-title：17px 粗体）
      Text(this.product!.title)
        .fontSize(17)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .lineHeight(23)
        .width('100%')

      // 副标题（对齐设计稿 pd-subtitle：12px 灰色）
      Text(this.getSubtitle())
        .fontSize(12)
        .fontColor($r('app.color.color_text_2'))
        .margin({ top: 4 })
        .width('100%')

      // 价格行（对齐设计稿 pd-price-row：¥小 + 数字大 + 划线价 + 已售）
      Row() {
        // 当前价格（对齐设计稿 pd-price：¥14 + 数字28）
        Row({ space: 1 }) {
          Text('¥')
            .fontSize(14)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
          Text(this.formatPrice(this.product!.price))
            .fontSize(28)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
        }
        .alignItems(VerticalAlign.Bottom)

        // 划线价（对齐设计稿 qn-price-old）
        Text(`¥${this.formatPrice(this.product!.price * 1.45)}`)
          .fontSize(12)
          .fontColor($r('app.color.color_text_4'))
          .decoration({ type: TextDecorationType.LineThrough })
          .margin({ left: 6 })

        Blank()

        // 已售（对齐设计稿 pd-sold）
        Text(`已售 ${this.formatSoldCount(this.product!.monthlySales)}`)
          .fontSize(12)
          .fontColor($r('app.color.color_text_3'))
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .margin({ top: 12 })
      .alignItems(VerticalAlign.Bottom)

      // 服务标签（对齐设计稿 pd-tags）
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.getServiceTags(), (tag: ServiceTag, index: number) => {
          Row({ space: 4 }) {
            Text(this.getTagIcon(tag.style))
              .fontSize(10)
            Text(tag.label)
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
          }
          .padding({ left: 10, right: 10, top: 3, bottom: 3 })
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor(this.getTagBgColor(tag.style))
          .margin({ right: 6, top: 6 })
        }, (tag: ServiceTag, index: number) => `${tag.label}_${index}`)
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .margin({ left: 16, right: 16 })
  }

  /** 农户信息卡（对齐设计稿 pd-farmer：头像 + 名称 + 地址 + 关注 + 进店箭头） */
  @Builder
  FarmerCard() {
    Row({ space: 12 }) {
      // 头像（对齐设计稿 pd-farmer-ava：48×48 + 双层光环）
      Stack() {
        Image(ImageUtil.get(this.getFarmerAvatar()))
          .width(48)
          .height(48)
          .borderRadius(AppConstants.RADIUS_PILL)
          .objectFit(ImageFit.Cover)
          .border({ width: 3, color: $r('app.color.color_bg_card') })
      }
      .width(54)
      .height(54)
      .borderRadius(AppConstants.RADIUS_PILL)
      .border({ width: 5, color: $r('app.color.color_yellow') })
      .alignContent(Alignment.Center)

      // 农户信息（对齐设计稿 pd-farmer-info）
      Column() {
        // 名称 + 认证标
        Row({ space: 6 }) {
          Text(this.getFarmerName())
            .fontSize(15)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
          // 认证标（对齐设计稿 qn-pill-green）
          Row({ space: 3 }) {
            Text('✓')
              .fontSize(10)
              .fontColor($r('app.color.color_green_deep'))
            Text('已认证')
              .fontSize(10)
              .fontColor($r('app.color.color_green_deep'))
              .fontWeight(FontWeight.Bold)
          }
          .padding({ left: 7, right: 7, top: 2, bottom: 2 })
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_green_soft'))
        }
        .alignItems(VerticalAlign.Center)

        // 地址（对齐设计稿 pd-farmer-loc）
        Row({ space: 3 }) {
          Text('📍')
            .fontSize(11)
          Text(this.product!.shipFrom)
            .fontSize(12)
            .fontColor($r('app.color.color_text_2'))
        }
        .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 右侧操作：关注按钮 + 进店箭头
      Row({ space: 10 }) {
        // 关注按钮（对齐设计稿 qn-btn-line）
        Text(this.isFollowed ? '已关注' : '+ 关注')
          .fontSize(13)
          .fontColor(this.isFollowed ? $r('app.color.color_text_2') : $r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .height(32)
          .padding({ left: 14, right: 14 })
          .borderRadius(AppConstants.RADIUS_SM)
          .backgroundColor($r('app.color.color_bg_card'))
          .border({ width: 1, color: $r('app.color.color_line_2') })
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.onToggleFollow();
          })
        // 进店箭头（对齐设计稿 pd-store-arrow）
        Text('›')
          .fontSize(14)
          .fontColor($r('app.color.color_text_2'))
          .width(28)
          .height(28)
          .textAlign(TextAlign.Center)
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_fill'))
          .onClick(() => {
            this.gotoShop();
          })
      }
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .margin({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
  }

  /** 商品规格卡（对齐设计稿 pd-spec-list：键值对列表） */
  @Builder
  SpecCard() {
    Column() {
      // 区块标题（对齐设计稿 qn-section-head）
      Row() {
        Text('商品规格')
          .fontSize(16)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Row({ space: 2 }) {
          Text('查看全部')
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
          Text('›')
            .fontSize(14)
            .fontColor($r('app.color.color_text_3'))
        }
      }
      .width('100%')
      .padding({ bottom: 4 })

      // 规格键值对列表（对齐设计稿 pd-spec-row）
      ForEach(this.getSpecList(), (spec: SpecRow, index: number) => {
        Row({ space: 12 }) {
          Text(spec.key)
            .fontSize(13)
            .fontColor($r('app.color.color_text_3'))
            .fontWeight(FontWeight.Medium)
            .width(72)
          Text(spec.value)
            .fontSize(13)
            .fontColor($r('app.color.color_ink_2'))
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ top: 11, bottom: 11 })
        .borderWidth({ top: index > 0 ? 1 : 0 })
        .borderColor($r('app.color.color_divider'))
        .alignItems(VerticalAlign.Top)
      }, (spec: SpecRow, index: number) => `${spec.key}_${index}`)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .margin({ left: 16, right: 16 })
  }

  /** SKU 选择卡 */
  @Builder
  SkuSelector() {
    Column({ space: 10 }) {
      Text('规格选择')
        .fontSize(16)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .alignSelf(ItemAlign.Start)

      // SKU 列表
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.product!.skuList, (sku: ProductSku, index: number) => {
          Text(this.formatSkuSpec(sku))
            .fontSize(13)
            .fontColor(this.selectedSkuIndex === index ? $r('app.color.color_ink') : $r('app.color.color_ink_2'))
            .fontWeight(FontWeight.Medium)
            .backgroundColor(this.selectedSkuIndex === index ? $r('app.color.color_yellow_soft') : $r('app.color.color_fill'))
            .border({ width: 1, color: this.selectedSkuIndex === index ? $r('app.color.color_primary') : Color.Transparent })
            .padding({ left: 14, right: 14, top: 8, bottom: 8 })
            .margin({ right: 8, bottom: 8 })
            .borderRadius(AppConstants.RADIUS_SM)
            .onClick(() => {
              this.onSkuSelect(index);
            })
        }, (sku: ProductSku) => sku.skuId)
      }
      .width('100%')

      // 当前 SKU 价格 + 库存
      Row() {
        Text(`¥${this.formatPrice(this.product!.skuList[this.selectedSkuIndex].price)}`)
          .fontSize(16)
          .fontColor($r('app.color.color_live'))
          .fontWeight(FontWeight.Bold)
        Blank()
        Text(`库存 ${this.product!.skuList[this.selectedSkuIndex].stock} 件`)
          .fontSize(12)
          .fontColor($r('app.color.color_text_2'))
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .margin({ left: 16, right: 16 })
  }

  /** 图文详情区（对齐设计稿 pd-detail-sec：黄色胶囊标题 + 多图 + 文字） */
  @Builder
  DetailImageSection() {
    Column({ space: 10 }) {
      // 黄色胶囊标题（对齐设计稿 pd-detail-head）
      Row({ space: 6 }) {
        Text('📋')
          .fontSize(14)
        Text('图文详情')
          .fontSize(13)
          .fontColor('#B8860B')
          .fontWeight(FontWeight.Bold)
      }
      .padding({ left: 14, right: 14, top: 6, bottom: 6 })
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor($r('app.color.color_yellow_soft'))
      .alignSelf(ItemAlign.Start)
      .margin({ bottom: 12 })

      // 多张详情图（对齐设计稿 pd-detail-img）
      ForEach(this.product!.mainImages, (imgKey: string, index: number) => {
        Image(ImageUtil.get(imgKey))
          .width('100%')
          .height(180)
          .objectFit(ImageFit.Cover)
          .borderRadius(AppConstants.RADIUS_MD)
          .backgroundColor($r('app.color.color_fill'))
          .margin({ bottom: 10 })
      }, (imgKey: string, index: number) => `detail_${imgKey}_${index}`)

      // 文字描述（对齐设计稿 pd-detail-text）
      Text(this.product!.description)
        .fontSize(13)
        .fontColor($r('app.color.color_text_2'))
        .lineHeight(22)
        .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 16 })
  }

  /** 用户评价区（对齐设计稿：评分 + 5星 + 好评率 + 评价列表） */
  @Builder
  ReviewSection() {
    Column() {
      // 标题行（对齐设计稿 qn-section-head）
      Row() {
        Row({ space: 4 }) {
          Text('用户评价')
            .fontSize(16)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
          Text(`(${this.formatCount(this.reviewStats.totalCount)})`)
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
            .fontWeight(FontWeight.Medium)
        }
        .layoutWeight(1)
        Row({ space: 2 }) {
          Text('查看全部')
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
          Text('›')
            .fontSize(14)
            .fontColor($r('app.color.color_text_3'))
        }
      }
      .width('100%')
      .padding({ bottom: 6 })

      // 评分头部（对齐设计稿 pd-rate-head：大数字 + 5星 + 好评率）
      Row({ space: 14 }) {
        // 评分大数字（对齐设计稿 pd-rate-score）
        Row({ space: 2 }) {
          Text(this.formatRating(this.reviewStats.avgRating))
            .fontSize(30)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
          Text('分')
            .fontSize(11)
            .fontColor($r('app.color.color_text_3'))
            .margin({ left: 2, bottom: 4 })
        }
        .alignItems(VerticalAlign.Bottom)

        // 5 颗星（对齐设计稿 pd-rate-stars）
        StarRating({ rating: this.reviewStats.avgRating, starSize: 16 })

        // 好评率（对齐设计稿 pd-rate-meta）
        Row() {
          Text('好评率 ')
            .fontSize(12)
            .fontColor($r('app.color.color_text_2'))
            .fontWeight(FontWeight.Medium)
          Text(`${this.reviewStats.goodRate}%`)
            .fontSize(12)
            .fontColor($r('app.color.color_green_deep'))
            .fontWeight(FontWeight.Bold)
        }
        .margin({ left: 8 })
        .alignItems(VerticalAlign.Bottom)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding({ bottom: 14 })

      // 评价列表
      if (this.reviews.length > 0) {
        ForEach(this.reviews.slice(0, 2), (review: Review, _i: number) => {
          this.ReviewItem(review)
        }, (review: Review) => review.reviewId)
      } else {
        Text('暂无评价')
          .fontSize(13)
          .fontColor($r('app.color.color_text_3'))
          .padding(16)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .margin({ left: 16, right: 16 })
  }

  /** 单条评价（对齐设计稿 pd-review） */
  @Builder
  ReviewItem(review: Review) {
    Column({ space: 8 }) {
      // 评价人头部（对齐设计稿 pd-review-head：头像 + 昵称 + 星星）
      Row({ space: 8 }) {
        Image(ImageUtil.get(review.buyerAvatar))
          .width(28)
          .height(28)
          .borderRadius(AppConstants.RADIUS_PILL)
          .objectFit(ImageFit.Cover)
        Text(review.buyerNickname)
          .fontSize(13)
          .fontColor($r('app.color.color_ink_2'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        StarRating({ rating: review.rating, starSize: 12 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 评价文字（对齐设计稿 pd-review-text）
      Text(review.content)
        .fontSize(13)
        .fontColor($r('app.color.color_ink_2'))
        .lineHeight(21)
        .width('100%')

      // 评价图片（对齐设计稿 pd-review-imgs：60×60 网格）
      if (review.images.length > 0) {
        Row({ space: 6 }) {
          ForEach(review.images.slice(0, 3), (imgKey: string, _j: number) => {
            Image(ImageUtil.get(imgKey))
              .width(60)
              .height(60)
              .borderRadius(AppConstants.RADIUS_SM)
              .objectFit(ImageFit.Cover)
          }, (imgKey: string, j: number) => `${review.reviewId}_${imgKey}_${j}`)
        }
        .width('100%')
      }

      // 卖家回复
      if (review.farmerReply && review.farmerReply.length > 0) {
        Column({ space: 4 }) {
          Text('卖家回复')
            .fontSize(11)
            .fontColor($r('app.color.color_text_2'))
            .fontWeight(FontWeight.Medium)
          Text(review.farmerReply)
            .fontSize(12)
            .fontColor($r('app.color.color_text_2'))
            .lineHeight(18)
            .width('100%')
        }
        .width('100%')
        .padding(10)
        .backgroundColor($r('app.color.color_fill'))
        .borderRadius(AppConstants.RADIUS_SM)
      }
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .borderWidth({ top: 1 })
    .borderColor($r('app.color.color_divider'))
  }

  /** 底部固定操作栏（对齐设计稿 pd-actionbar：客服 + 购物车 + 加入购物车 + 立即购买） */
  @Builder
  BottomActionBar() {
    Row({ space: 8 }) {
      // 客服图标按钮（对齐设计稿 pd-act-ico）
      Column({ space: 1 }) {
        Text('💬')
          .fontSize(20)
        Text('客服')
          .fontSize(9)
          .fontColor($r('app.color.color_text_2'))
          .fontWeight(FontWeight.Medium)
      }
      .width(44)
      .height(44)
      .borderRadius(AppConstants.RADIUS_SM)
      .backgroundColor($r('app.color.color_fill'))
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        this.gotoChat();
      })

      // 购物车图标按钮 + 角标（对齐设计稿 pd-act-ico + pd-badge）
      Stack({ alignContent: Alignment.TopEnd }) {
        Column({ space: 1 }) {
          Text('🛒')
            .fontSize(20)
          Text('购物车')
            .fontSize(9)
            .fontColor($r('app.color.color_text_2'))
            .fontWeight(FontWeight.Medium)
        }
        .width(44)
        .height(44)
        .borderRadius(AppConstants.RADIUS_SM)
        .backgroundColor($r('app.color.color_fill'))
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        // 角标（对齐设计稿 pd-badge）
        Text('3')
          .fontSize(9)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
          .height(14)
          .padding({ left: 3, right: 3 })
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_live'))
          .border({ width: 1.5, color: Color.White })
          .textAlign(TextAlign.Center)
          .markAnchor({ x: 14, y: 0 })
          .position({ x: 30, y: -2 })
      }
      .width(44)
      .height(44)
      .onClick(() => {
        this.gotoCart();
      })

      // 加入购物车按钮（对齐设计稿 pd-act-cart：黄底黑字）
      Text('加入购物车')
        .fontSize(14)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .height(44)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor($r('app.color.color_primary'))
        .textAlign(TextAlign.Center)
        .layoutWeight(1)
        .onClick(() => {
          this.onAddToCart();
        })

      // 立即购买按钮（对齐设计稿 pd-act-buy：黑底白字）
      Text('立即购买')
        .fontSize(14)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .height(44)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor($r('app.color.color_ink'))
        .textAlign(TextAlign.Center)
        .layoutWeight(1)
        .onClick(() => {
          this.onBuyNow();
        })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor($r('app.color.color_bg_card'))
    .border({ width: { top: 0.5 }, color: $r('app.color.color_divider') })
    .shadow(AppConstants.SHADOW_NAV)
    .alignItems(VerticalAlign.Center)
  }

  /** 获取副标题 */
  private getSubtitle(): string {
    const categoryPath: string = getMockCategoryPath(this.product!.categoryId);
    if (categoryPath.length > 0) {
      const parts: string[] = categoryPath.split(' > ');
      if (parts.length >= 2) {
        return `${parts[parts.length - 1]} · 当季新鲜`;
      }
      return categoryPath;
    }
    return '当季头茬 香甜多汁';
  }

  /** 获取农户名 */
  private getFarmerName(): string {
    return MOCK_FARMER_NAMES[this.product!.farmerId] ?? '未知卖家';
  }

  /** 获取农户头像 */
  private getFarmerAvatar(): string {
    return MOCK_FARMER_AVATARS[this.product!.farmerId] ?? 'avatar_default';
  }

  /** 获取服务标签列表（对齐设计稿：顺丰冷链/坏果包赔/当季新品） */
  private getServiceTags(): ServiceTag[] {
    const tags: ServiceTag[] = [
      { label: '顺丰冷链', style: 'yellow' },
      { label: '坏果包赔', style: 'green' },
      { label: '当季新品', style: 'soft' }
    ];
    return tags;
  }

  /** 获取标签图标 emoji */
  private getTagIcon(style: 'yellow' | 'green' | 'soft'): string {
    if (style === 'yellow') {
      return '🚚';
    } else if (style === 'green') {
      return '🛡';
    }
    return '✨';
  }

  /** 获取标签背景色 */
  private getTagBgColor(style: 'yellow' | 'green' | 'soft'): ResourceColor {
    if (style === 'yellow') {
      return $r('app.color.color_yellow_soft');
    } else if (style === 'green') {
      return $r('app.color.color_green_soft');
    }
    return $r('app.color.color_fill');
  }

  /** 获取规格键值对列表（对齐设计稿 pd-spec-row） */
  private getSpecList(): SpecRow[] {
    const list: SpecRow[] = [];
    list.push({ key: '产地', value: `${this.product!.shipFrom} · ${this.getFarmerName()}` });
    const sku: ProductSku = this.product!.skuList[this.selectedSkuIndex];
    list.push({ key: '规格', value: this.formatSkuSpec(sku) });
    list.push({ key: '保质期', value: '冷藏 5 天 / 收货后建议 3 日内食用' });
    list.push({ key: '储存方式', value: '0-4℃ 冷藏保鲜，避免阳光直射' });
    return list;
  }

  /** 格式化 SKU 规格 */
  private formatSkuSpec(sku: ProductSku): string {
    return sku.specs.map((s: ProductSkuSpec) => `${s.name}:${s.value}`).join(' / ');
  }

  /** 格式化价格（保留1位小数） */
  private formatPrice(price: number): string {
    return price.toFixed(1);
  }

  /** 格式化已售数量（>=10000 显示万） */
  private formatSoldCount(count: number): string {
    if (count >= 10000) {
      return `${(count / 10000).toFixed(1)}万`;
    }
    return `${count}`;
  }

  /** 格式化评分（保留1位小数） */
  private formatRating(rating: number): string {
    return rating.toFixed(1);
  }

  /** 格式化数量（万） */
  private formatCount(n: number): string {
    if (n >= 10000) {
      return `${(n / 10000).toFixed(1)}万`;
    }
    return `${n}`;
  }
}
