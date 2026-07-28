/**
 * seller_mall_page - 卖家商城页（spec 3.2.1）
 *
 * 上下分段结构：
 *  - 上部：商品上架发布快捷表单（可折叠）+ 跳转完整发布页入口
 *  - 下部：全平台商品推荐流（非自家商品，作为市场参考）
 *
 * 上部表单可折叠，下滑区域展示推荐流
 */

import { Logger, AppConstants, FarmerRoutes, NavigationHelper, RouteName, PageResult, SharedProductStore, SharedProduct } from 'common';
import { FarmerProductItem } from '../../model/FarmerModels';
import { ProductManageRepository } from '../../repository/ProductManageRepository';
import { MOCK_FARMER_ID } from '../../mock/FarmerMock';
import { ImageUtil } from '../../utils/ImageUtil';

/** 跳转商品编辑页的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface ProductEditParam {
  productId: string;
}

/** 推荐流商品卡片（简化版，全平台商品） */
interface RecommendProduct {
  productId: string;
  title: string;
  price: number;
  imageUrl: string;
  monthlySales: number;
  farmerName: string;
}

/** 全平台推荐流 Mock 数据（非自家商品，spec 3.2.1：作为市场参考） */
const MOCK_RECOMMEND_LIST: RecommendProduct[] = [
  { productId: 'rp001', title: '红心蜜柚 5斤装 福建平和直发', price: 29.90, imageUrl: 'rp_pomelo', monthlySales: 8620, farmerName: '平和果农' },
  { productId: 'rp002', title: '云南小黄姜 2斤 现挖现发', price: 19.90, imageUrl: 'rp_ginger', monthlySales: 5630, farmerName: '滇南农场' },
  { productId: 'rp003', title: '内蒙古土豆 10斤 沙土地种植', price: 26.80, imageUrl: 'rp_potato', monthlySales: 4520, farmerName: '草原牧歌' },
  { productId: 'rp004', title: '海南金钻凤梨 8斤 当季新鲜', price: 59.00, imageUrl: 'rp_pineapple', monthlySales: 3280, farmerName: '三亚果场' },
  { productId: 'rp005', title: '陕西洛川苹果 5斤 脆甜多汁', price: 39.90, imageUrl: 'rp_apple', monthlySales: 9850, farmerName: '洛川果园' },
  { productId: 'rp006', title: '新疆灰枣 500g 一级骏枣', price: 25.80, imageUrl: 'rp_date', monthlySales: 6580, farmerName: '丝路枣农' },
  { productId: 'rp007', title: '广西百香果 3斤 紫皮香甜', price: 22.50, imageUrl: 'rp_passion', monthlySales: 4280, farmerName: '桂南果场' },
  { productId: 'rp008', title: '山东大樱桃 2斤 车厘子美早', price: 89.00, imageUrl: 'rp_cherry', monthlySales: 2180, farmerName: '齐鲁樱桃园' }
];

@ComponentV2
export struct SellerMallPage {
  /** 上部表单是否折叠 */
  @Local formCollapsed: boolean = false;
  /** 快捷标题输入 */
  @Local quickTitle: string = '';
  /** 快捷价格输入 */
  @Local quickPrice: string = '';
  /** 推荐流列表 */
  @Local recommendList: RecommendProduct[] = MOCK_RECOMMEND_LIST.slice();
  /** 自家在售商品数（顶部展示） */
  @Local myOnSaleCount: number = 0;

  async aboutToAppear(): Promise<void> {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'seller_mall_page_appear' });
    await this.refreshData();
  }

  onPageShow(): void {
    // spec 16.9：从发布页返回后刷新，确保新发布商品立即显示在推荐流
    this.refreshData();
  }

  /** spec 16.9：合并自家已发布商品到推荐流顶部 */
  private async refreshData(): Promise<void> {
    try {
      const result: PageResult<FarmerProductItem> = await ProductManageRepository.getMyProducts(MOCK_FARMER_ID, 1, 50, 'approved');
      this.myOnSaleCount = result.list.filter((p: FarmerProductItem): boolean => p.status === 'approved').length;
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'load_my_count_fail', error: (err as Error).message });
    }
    // spec 16.9：同步 SharedProductStore 中已发布商品到推荐流头部
    try {
      const shared: SharedProduct[] = await SharedProductStore.getAll();
      const mockIds: Set<string> = new Set<string>(MOCK_RECOMMEND_LIST.map(
        (p: RecommendProduct): string => p.productId
      ));
      const mine: RecommendProduct[] = shared
        .filter((p: SharedProduct): boolean => p.status === 'approved')
        .map((p: SharedProduct): RecommendProduct => {
          const item: RecommendProduct = {
            productId: p.productId,
            title: p.title,
            price: p.price,
            imageUrl: p.mainImages.length > 0 ? p.mainImages[0] : 'rp_default',
            monthlySales: p.monthlySales,
            farmerName: p.farmerName
          };
          return item;
        })
        .filter((p: RecommendProduct): boolean => !mockIds.has(p.productId));
      this.recommendList = mine.concat(MOCK_RECOMMEND_LIST.slice());
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'sync_shared_products_fail', error: (err as Error).message });
    }
  }

  /** 切换折叠 */
  private toggleCollapse(): void {
    this.formCollapsed = !this.formCollapsed;
  }

  /** 跳转完整发布页 */
  private gotoPublish(): void {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'goto_product_publish' });
    NavigationHelper.push(RouteName.FARMER_PRODUCT_PUBLISH);
  }

  /** spec 16.10：跳转商品详情购买页（不再跳编辑页） */
  private gotoProductEdit(productId: string): void {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'goto_product_detail', productId });
    const param: ProductEditParam = { productId: productId };
    NavigationHelper.push(RouteName.FARMER_PRODUCT_DETAIL, param);
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        Scroll() {
          Column({ space: 12 }) {
            // 上部：商品上架发布快捷表单（可折叠）
            this.PublishFormSection()
            // 下部：全平台推荐流
            this.RecommendStreamSection()
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 12, bottom: 24 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 顶部导航 */
  @Builder
  TopBar() {
    Row({ space: 12 }) {
      Text('‹')
        .fontSize(28)
        .fontColor($r('app.color.color_text_primary'))
        .onClick(() => NavigationHelper.pop())
      Text('商城')
        .fontSize(18)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
      Text(`在售 ${this.myOnSaleCount} 件`)
        .fontSize(12)
        .fontColor($r('app.color.color_text_secondary'))
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** 上部：商品上架发布快捷表单（可折叠） */
  @Builder
  PublishFormSection() {
    Column({ space: 12 }) {
      // 标题行 + 折叠按钮
      Row() {
        Text('⚡ 快速上架')
          .fontSize(16)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text(this.formCollapsed ? '展开 ▾' : '收起 ▴')
          .fontSize(12)
          .fontColor($r('app.color.color_secondary'))
          .onClick(() => this.toggleCollapse())
      }
      .width('100%')

      if (!this.formCollapsed) {
        // 快捷表单（标题 + 价格 + 跳转完整发布页按钮）
        Column({ space: 10 }) {
          TextInput({ text: this.quickTitle, placeholder: '商品标题（5-60字）' })
            .height(44)
            .borderRadius(8)
            .backgroundColor($r('app.color.color_bg_page'))
            .padding({ left: 12, right: 12 })
            .fontSize(14)
            .maxLength(60)
            .onChange((v: string) => { this.quickTitle = v; })

          Row({ space: 10 }) {
            TextInput({ text: this.quickPrice, placeholder: '价格' })
              .type(InputType.Number)
              .height(44)
              .borderRadius(8)
              .backgroundColor($r('app.color.color_bg_page'))
              .padding({ left: 12, right: 12 })
              .fontSize(14)
              .layoutWeight(1)
              .onChange((v: string) => { this.quickPrice = v; })
            Button('完整发布 →')
              .height(44)
              .borderRadius(8)
              .backgroundColor($r('app.color.color_cta_black'))
              .fontColor(Color.White)
              .fontSize(14)
              .padding({ left: 16, right: 16 })
              .onClick(() => this.gotoPublish())
          }
          .width('100%')
        }
        .width('100%')
      } else {
        // 折叠态：仅显示快捷发布按钮
        Button('＋ 进入完整发布页')
          .width('100%')
          .height(44)
          .borderRadius(8)
          .backgroundColor($r('app.color.color_cta_black'))
          .fontColor(Color.White)
          .fontSize(14)
          .onClick(() => this.gotoPublish())
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 下部：全平台商品推荐流（spec 3.2.1：非自家商品，市场参考） */
  @Builder
  RecommendStreamSection() {
    Column({ space: 12 }) {
      Row() {
        Text('全平台热销')
          .fontSize(16)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text('市场参考')
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')

      // 推荐流网格（2列）
      Grid() {
        ForEach(this.recommendList, (item: RecommendProduct, _idx: number) => {
          GridItem() {
            this.RecommendCard(item)
          }
        }, (item: RecommendProduct) => item.productId)
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(10)
      .rowsGap(10)
      .width('100%')
    }
    .width('100%')
  }

  /** 推荐商品卡片 */
  @Builder
  RecommendCard(item: RecommendProduct) {
    Column({ space: 8 }) {
      Stack() {
        // spec 16.9/16.12：支持真实 file:// / http URI，其他 key 走 ImageUtil 映射
        if (item.imageUrl.startsWith('file://') || item.imageUrl.startsWith('http://') || item.imageUrl.startsWith('https://')) {
          Image(item.imageUrl)
            .width('100%')
            .height(140)
            .borderRadius(8)
            .objectFit(ImageFit.Cover)
        } else {
          Image(ImageUtil.get(item.imageUrl))
            .width('100%')
            .height(140)
            .borderRadius(8)
            .objectFit(ImageFit.Cover)
        }
      }
      .width('100%')
      .height(140)
      .borderRadius(8)
      .backgroundColor($r('app.color.color_card_yellow'))
      .alignContent(Alignment.Center)

      Text(item.title)
        .fontSize(13)
        .fontColor($r('app.color.color_text_primary'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Text(item.farmerName)
        .fontSize(11)
        .fontColor($r('app.color.color_text_hint'))
        .width('100%')

      Row() {
        Text(`¥${item.price.toFixed(2)}`)
          .fontSize(14)
          .fontColor($r('app.color.color_price'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text(`月销 ${item.monthlySales}`)
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')
    }
    .width('100%')
    .padding(8)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
    .onClick(() => this.gotoProductEdit(item.productId))
  }
}
