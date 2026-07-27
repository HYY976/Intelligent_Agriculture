/**
 * product_detail - 商品详情购买页（spec 16.10）
 *
 * 淘宝式商品详情布局：
 *  - 顶部：返回键 + 商品标题（简）
 *  - 大图轮播区（主图）
 *  - 价格区（大字号红价 + 原价划线 + 月销）
 *  - 商品标题区
 *  - 发货信息区（发货地 / 运费 / 库存）
 *  - 商品详情区（图文描述）
 *  - 底部固定栏：客服 + 收藏 + 加购物车 + 立即购买
 *
 * 数据来源：优先 SharedProductStore.getById()，回退 Mock
 */

import { Logger, AppConstants, ToastUtil, NavigationHelper, RouteName, SharedProductStore, SharedProduct, TokenStore, UserInfo } from 'common';
import { MOCK_FARMER_PRODUCTS } from '../../mock/FarmerMock';

/** spec 16.10：商品详情页入参 */
interface ProductDetailParam {
  productId: string;
}

/** spec 16.10：商品详情展示模型 */
interface ProductDetailView {
  productId: string;
  title: string;
  /** 主图 URI 列表（file:// / http:// / mock key） */
  images: string[];
  /** 现价 */
  price: number;
  /** 原价（划线价） */
  originalPrice: number;
  /** 月销量 */
  monthlySales: number;
  /** 库存 */
  stock: number;
  /** 发货地 */
  shipFrom: string;
  /** 运费文案 */
  freightText: string;
  /** 商品描述（详情图文） */
  description: string;
  /** 卖家昵称 */
  farmerName: string;
  /** 卖家头像 */
  farmerAvatar: string;
  /** 类目 ID */
  categoryId: string;
}

@ComponentV2
export struct ProductDetail {
  /** 商品 ID */
  @Local productId: string = '';
  /** 商品详情视图数据 */
  @Local view: ProductDetailView | null = null;
  /** 当前主图索引 */
  @Local currentImageIndex: number = 0;
  /** 是否已收藏 */
  @Local favorited: boolean = false;
  /** 加载状态 */
  @Local loading: boolean = true;
  /** 购买数量 */
  @Local buyCount: number = 1;
  /** 是否展开详情描述 */
  @Local descExpanded: boolean = false;
  /** 卖家昵称（来自 TokenStore，同步个人信息修改） */
  @Local sellerName: string = '助农店铺';
  /** 卖家头像（来自 TokenStore） */
  @Local sellerAvatar: string = '';

  aboutToAppear(): void {
    const param: ProductDetailParam | undefined = NavigationHelper.getParam() as ProductDetailParam | undefined;
    this.productId = param?.productId ?? '';
    Logger.info(AppConstants.SCENE_FARMER, { action: 'product_detail_appear', productId: this.productId });
    this.loadDetail();
    this.loadSellerInfo();
  }

  /** spec 16.10：加载商品详情：先查 SharedProductStore，回退 Mock */
  private async loadDetail(): Promise<void> {
    this.loading = true;
    try {
      // 1. 优先从 SharedProductStore 读取（已发布商品，含真实图片 URI）
      const shared: SharedProduct | null = await SharedProductStore.getById(this.productId);
      if (shared !== null) {
        this.view = {
          productId: shared.productId,
          title: shared.title,
          images: shared.mainImages.length > 0 ? shared.mainImages : ['prod_default'],
          price: shared.price,
          originalPrice: shared.price * 1.2,
          monthlySales: shared.monthlySales,
          stock: shared.stock,
          shipFrom: shared.shipFrom,
          freightText: shared.freightTemplate === 'free' ? '包邮' : '运费 ¥10.00',
          description: shared.description,
          farmerName: shared.farmerName,
          farmerAvatar: shared.farmerAvatar,
          categoryId: shared.categoryId
        };
        this.loading = false;
        return;
      }
      // 2. 回退到 Mock 数据
      const mock = MOCK_FARMER_PRODUCTS.find((p) => p.productId === this.productId);
      if (mock) {
        this.view = {
          productId: mock.productId,
          title: mock.title,
          images: mock.mainImage && mock.mainImage.length > 0 ? [mock.mainImage] : ['prod_default'],
          price: mock.price,
          originalPrice: mock.price * 1.2,
          monthlySales: mock.monthlySales,
          stock: mock.stock,
          shipFrom: '本地农场',
          freightText: '包邮',
          description: `本商品为${mock.title}，源自优质产区，严格把控品质，新鲜直达。`,
          farmerName: '我的店铺',
          farmerAvatar: '',
          categoryId: mock.categoryId ?? ''
        };
      } else {
        // 3. 兜底：构造默认详情
        this.view = {
          productId: this.productId,
          title: '商品详情',
          images: ['prod_default'],
          price: 0,
          originalPrice: 0,
          monthlySales: 0,
          stock: 0,
          shipFrom: '本地农场',
          freightText: '包邮',
          description: '暂无商品信息',
          farmerName: '助农店铺',
          farmerAvatar: '',
          categoryId: ''
        };
      }
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'product_detail_load_fail', error: (err as Error).message });
    } finally {
      this.loading = false;
    }
  }

  /** spec 16.10：从 TokenStore 同步卖家昵称和头像（与个人信息修改保持一致） */
  private async loadSellerInfo(): Promise<void> {
    try {
      const user: UserInfo | null = await TokenStore.getUserInfo();
      if (user) {
        this.sellerName = user.nickname && user.nickname.length > 0 ? user.nickname : '助农店铺';
        this.sellerAvatar = user.avatar;
      }
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'load_seller_info_fail', error: (err as Error).message });
    }
  }

  /** 返回 */
  private goBack(): void {
    NavigationHelper.pop();
  }

  /** 切换收藏 */
  private toggleFavorite(): void {
    this.favorited = !this.favorited;
    ToastUtil.success(this.favorited ? '已收藏' : '已取消收藏');
  }

  /** 减少购买数量 */
  private decreaseCount(): void {
    if (this.buyCount > 1) {
      this.buyCount--;
    }
  }

  /** 增加购买数量 */
  private increaseCount(): void {
    const stock: number = this.view?.stock ?? 99;
    if (this.buyCount < stock) {
      this.buyCount++;
    } else {
      ToastUtil.warning('已达库存上限');
    }
  }

  /** 加入购物车（演示） */
  private addToCart(): void {
    ToastUtil.success('已加入购物车');
  }

  /** 立即购买（演示） */
  private buyNow(): void {
    ToastUtil.success('下单成功（演示）');
  }

  /** 客服咨询（演示） */
  private contactService(): void {
    ToastUtil.info('客服功能开发中');
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        if (this.loading) {
          Column({ space: 8 }) {
            LoadingProgress().width(48).height(48)
            Text('加载中...').fontSize(14).fontColor($r('app.color.color_text_hint'))
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else if (this.view !== null) {
          this.DetailContent()
          this.BottomActionBar()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 顶部导航栏 */
  @Builder
  TopBar() {
    Row() {
      Text('‹')
        .fontSize(28)
        .fontColor($r('app.color.color_text_primary'))
        .width(40)
        .height(40)
        .textAlign(TextAlign.Center)
        .onClick(() => this.goBack())
      Text('商品详情')
        .fontSize(17)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Text('')
        .width(40)
        .height(40)
    }
    .width('100%')
    .height(48)
    .padding({ left: 8, right: 8 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** 详情内容（可滚动） */
  @Builder
  DetailContent() {
    Scroll() {
      Column({ space: 10 }) {
        this.ImageCarousel()
        this.PriceCard()
        this.TitleCard()
        this.ShipInfoCard()
        this.DescriptionCard()
      }
      .width('100%')
      .padding({ bottom: 80 })
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .align(Alignment.TopStart)
  }

  /** 主图轮播区 */
  @Builder
  ImageCarousel() {
    Swiper() {
      ForEach(this.view!.images, (img: string, idx: number) => {
        Stack() {
          if (img.startsWith('file://') || img.startsWith('http://') || img.startsWith('https://')) {
            Image(img)
              .width('100%')
              .height(380)
              .objectFit(ImageFit.Cover)
          } else {
            Column({ space: 12 }) {
              Text('🌾').fontSize(80)
              Text(img).fontSize(12).fontColor($r('app.color.color_text_hint'))
            }
            .width('100%')
            .height(380)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          }
        }
        .width('100%')
        .height(380)
        .backgroundColor($r('app.color.color_card_yellow'))
        .alignContent(Alignment.Center)
        .onClick(() => {
          this.currentImageIndex = idx;
        })
      }, (img: string, idx: number) => `${img}_${idx}`)
    }
    .width('100%')
    .height(380)
    .indicator(true)
    .index(this.currentImageIndex)
    .onChange((index: number) => {
      this.currentImageIndex = index;
    })
  }

  /** 价格卡片 */
  @Builder
  PriceCard() {
    Column({ space: 6 }) {
      Row({ space: 8 }) {
        // spec 16.10：¥ 符号字号与价格数字一致
        Text('¥')
          .fontSize(32)
          .fontColor($r('app.color.color_price'))
          .fontWeight(FontWeight.Bold)
        Text(`${this.view!.price.toFixed(2)}`)
          .fontSize(32)
          .fontColor($r('app.color.color_price'))
          .fontWeight(FontWeight.Bold)
        Text(`¥${this.view!.originalPrice.toFixed(2)}`)
          .fontSize(13)
          .fontColor($r('app.color.color_text_hint'))
          .decoration({ type: TextDecorationType.LineThrough })
          .baselineOffset(-2)
          .layoutWeight(1)
        Text(`月销 ${this.view!.monthlySales}`)
          .fontSize(12)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 商品标题卡片 */
  @Builder
  TitleCard() {
    Column({ space: 8 }) {
      Text(this.view!.title)
        .fontSize(17)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Bold)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
      Row({ space: 12 }) {
        Text(`库存 ${this.view!.stock} 件`)
          .fontSize(12)
          .fontColor($r('app.color.color_text_hint'))
        Text(`已售 ${this.view!.monthlySales} 件`)
          .fontSize(12)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 发货信息卡片 */
  @Builder
  ShipInfoCard() {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        Text('发货地')
          .fontSize(13)
          .fontColor($r('app.color.color_text_hint'))
          .width(64)
        Text(this.view!.shipFrom)
          .fontSize(14)
          .fontColor($r('app.color.color_text_primary'))
          .layoutWeight(1)
      }
      .width('100%')

      Row({ space: 8 }) {
        Text('运费')
          .fontSize(13)
          .fontColor($r('app.color.color_text_hint'))
          .width(64)
        Text(this.view!.freightText)
          .fontSize(14)
          .fontColor($r('app.color.color_text_primary'))
          .layoutWeight(1)
      }
      .width('100%')

      Row({ space: 8 }) {
        Text('卖家')
          .fontSize(13)
          .fontColor($r('app.color.color_text_hint'))
          .width(64)
        Row({ space: 6 }) {
          if (this.sellerAvatar.startsWith('file://') || this.sellerAvatar.startsWith('http://')) {
            Image(this.sellerAvatar)
              .width(20).height(20).borderRadius(10)
              .objectFit(ImageFit.Cover)
          } else {
            Text('👤').fontSize(14)
          }
          Text(this.sellerName)
            .fontSize(14)
            .fontColor($r('app.color.color_text_primary'))
        }
        .layoutWeight(1)
      }
      .width('100%')

      Row({ space: 8 }) {
        Text('数量')
          .fontSize(13)
          .fontColor($r('app.color.color_text_hint'))
          .width(64)
        Row({ space: 12 }) {
          Text('−')
            .fontSize(20)
            .fontColor($r('app.color.color_text_primary'))
            .width(32).height(32)
            .textAlign(TextAlign.Center)
            .borderRadius(16)
            .backgroundColor($r('app.color.color_fill'))
            .onClick(() => this.decreaseCount())
          Text(`${this.buyCount}`)
            .fontSize(15)
            .fontColor($r('app.color.color_text_primary'))
            .width(40)
            .textAlign(TextAlign.Center)
          Text('+')
            .fontSize(20)
            .fontColor($r('app.color.color_text_primary'))
            .width(32).height(32)
            .textAlign(TextAlign.Center)
            .borderRadius(16)
            .backgroundColor($r('app.color.color_fill'))
            .onClick(() => this.increaseCount())
        }
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 商品详情描述卡片 */
  @Builder
  DescriptionCard() {
    Column({ space: 10 }) {
      Row() {
        Text('商品详情')
          .fontSize(15)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
      }
      .width('100%')

      Text(this.view!.description)
        .fontSize(13)
        .fontColor($r('app.color.color_text_2'))
        .maxLines(this.descExpanded ? 100 : 4)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .lineHeight(20)

      if (this.view!.description.length > 80) {
        Text(this.descExpanded ? '收起 ▲' : '展开全部 ▼')
          .fontSize(12)
          .fontColor($r('app.color.color_price'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 6 })
          .onClick(() => { this.descExpanded = !this.descExpanded; })
      }

      // 商品图文详情（占位图）
      Column({ space: 8 }) {
        Text('【产品特色】')
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Bold)
          .width('100%')
        Text('· 原产地直供，新鲜采摘\n· 严格筛选，品质保证\n· 绿色种植，安心食用\n· 快速配送，锁住新鲜')
          .fontSize(13)
          .fontColor($r('app.color.color_text_2'))
          .width('100%')
          .lineHeight(20)
      }
      .width('100%')
      .padding({ top: 12 })

      Column({ space: 8 }) {
        Text('【温馨提示】')
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Bold)
          .width('100%')
        Text('· 农产品受季节影响，外观可能略有差异\n· 收到商品后请尽快食用，确保口感\n· 如有质量问题，请联系客服处理')
          .fontSize(13)
          .fontColor($r('app.color.color_text_2'))
          .width('100%')
          .lineHeight(20)
      }
      .width('100%')
      .padding({ top: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 底部固定操作栏 */
  @Builder
  BottomActionBar() {
    Row({ space: 8 }) {
      // 客服
      Column({ space: 2 }) {
        Text('💬').fontSize(20)
        Text('客服').fontSize(10).fontColor($r('app.color.color_text_2'))
      }
      .width(48)
      .height(48)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => this.contactService())

      // 收藏
      Column({ space: 2 }) {
        Text(this.favorited ? '★' : '☆').fontSize(22)
        Text(this.favorited ? '已收藏' : '收藏').fontSize(10)
          .fontColor($r('app.color.color_text_2'))
      }
      .width(48)
      .height(48)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => this.toggleFavorite())

      // 加入购物车
      Button('加入购物车')
        .layoutWeight(1)
        .height(44)
        .fontSize(14)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.color_info'))
        .borderRadius(22)
        .onClick(() => this.addToCart())

      // 立即购买
      Button('立即购买')
        .layoutWeight(1)
        .height(44)
        .fontSize(14)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.color_price'))
        .borderRadius(22)
        .onClick(() => this.buyNow())
    }
    .width('100%')
    .height(60)
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }
}
