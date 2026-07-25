/**
 * product_list - 商品列表页（对齐设计稿 product-list.html）
 *  - 顶栏：返回 + 搜索框（白底胶囊 + 软阴影） + 黑色搜索按钮
 *  - 排序栏：综合 / 销量 / 价格（上下三角） / 新品 + 筛选按钮
 *  - 商品横向卡片：80×80 主图 + 标题 + 卖家头像首字 + 价格 + 月销
 *  - 路由参数：categoryId（末级分类ID）/ keyword（搜索关键词）
 */

import { RouteName, NavigationHelper, Logger, AppConstants } from 'common';
import { ProductListItem, ProductSortBy } from '../../model/ProductModels';
import { ProductListDataSource } from '../../viewmodel/ProductListDataSource';
import { ImageUtil } from '../../utils/ImageUtil';

/** 排序选项配置 */
interface SortOption {
  sortBy: ProductSortBy;
  label: string;
  /** 是否价格项（显示上下三角） */
  hasTri: boolean;
}

/** 跳转商品详情的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface ProductDetailParam {
  productId: string;
}

/** 跳转搜索页的路由参数 */
interface SearchParam {
  keyword: string;
}

@ComponentV2
export struct ProductList {
  /** 分类 ID */
  @Local categoryId: string = '';
  /** 分类名 */
  @Local categoryName: string = '';
  /** 关键词 */
  @Local keyword: string = '';
  /** 当前排序 */
  @Local currentSort: ProductSortBy = 'comprehensive';
  /** 是否正在下拉刷新 */
  @Local isRefreshing: boolean = false;
  /** 数据源 */
  private dataSource: ProductListDataSource = new ProductListDataSource();
  /** 排序选项（对齐设计稿：综合 / 销量 / 价格 / 新品 + 筛选） */
  private sortOptions: SortOption[] = [
    { sortBy: 'comprehensive', label: '综合', hasTri: false },
    { sortBy: 'sales', label: '销量', hasTri: false },
    { sortBy: 'price_asc', label: '价格', hasTri: true },
    { sortBy: 'newest', label: '新品', hasTri: false }
  ];

  aboutToAppear(): void {
    // 解析路由参数
    const params: Record<string, string> = NavigationHelper.getParam<Record<string, string>>() as Record<string, string>;
    if (params) {
      this.categoryId = params.categoryId ?? '';
      this.categoryName = params.categoryName ? decodeURIComponent(params.categoryName) : '';
      this.keyword = params.keyword ? decodeURIComponent(params.keyword) : '';
    }
    // 设置筛选条件
    this.dataSource.setFilter(this.categoryId, this.keyword);
    this.dataSource.setSortBy(this.currentSort);
    // 首次加载
    this.dataSource.refresh();
    Logger.info(AppConstants.SCENE_USER, {
      action: 'product_list_appear',
      category: this.categoryId,
      keyword: this.keyword
    });
  }

  /** 切换排序 */
  private onSortChange(sortBy: ProductSortBy): void {
    this.currentSort = sortBy;
    this.dataSource.setSortBy(sortBy);
    this.dataSource.refresh();
  }

  /** 跳转商品详情 */
  private gotoProductDetail(productId: string): void {
    const param: ProductDetailParam = { productId: productId };
    NavigationHelper.push(RouteName.USER_PRODUCT_DETAIL, param);
  }

  /** 跳转搜索页 */
  private gotoSearch(): void {
    NavigationHelper.push(RouteName.USER_SEARCH_PAGE);
  }

  /** 下拉刷新 */
  private async onRefresh(): Promise<void> {
    this.isRefreshing = true;
    await this.dataSource.refresh();
    this.isRefreshing = false;
  }

  build() {
    NavDestination() {
      Column() {
        // 顶栏：返回 + 搜索框 + 搜索按钮（对齐设计稿 qn-topbar）
        this.TopBar()

        // 排序栏（对齐设计稿 qn-sortbar）
        this.SortBar()

        // 商品列表（横向卡片，对齐设计稿 qn-prod-card）
        Refresh({ refreshing: $$this.isRefreshing }) {
          List() {
            LazyForEach(this.dataSource, (item: ProductListItem, index: number) => {
              ListItem() {
                this.ProductRowCard(item)
              }
              .margin({ bottom: 10 })
            }, (item: ProductListItem) => item.productId + `_${this.dataSource.totalCount()}`)
          }
          .padding({ left: 16, right: 16, top: 12, bottom: 4 })
          .scrollBar(BarState.Off)
          .cachedCount(AppConstants.LIST_CACHED_COUNT)
          .onReachEnd(() => {
            this.dataSource.loadMore();
          })
        }
        .onRefreshing(() => {
          this.onRefresh();
        })
        .layoutWeight(1)
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 顶栏：返回 + 搜索框 + 黑色搜索按钮（对齐设计稿 qn-topbar + qn-search-input） */
  @Builder
  TopBar() {
    Row({ space: 10 }) {
      // 返回按钮（对齐设计稿 qn-icon-btn：白底圆 + 软阴影）
      Text('←')
        .fontSize(18)
        .fontColor($r('app.color.color_ink'))
        .width(32)
        .height(32)
        .textAlign(TextAlign.Center)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor($r('app.color.color_bg_card'))
        .shadow(AppConstants.SHADOW_CARD)
        .onClick(() => {
          NavigationHelper.pop();
        })

      // 搜索框（对齐设计稿 qn-search-input：白底胶囊 + 软阴影）
      Row({ space: 8 }) {
        Text('🔍')
          .fontSize(14)
          .fontColor($r('app.color.color_text_3'))
        Text(this.keyword.length > 0 ? this.keyword : (this.categoryName.length > 0 ? this.categoryName : '搜索商品'))
          .fontSize(14)
          .fontColor(this.keyword.length > 0 || this.categoryName.length > 0 ? $r('app.color.color_ink') : $r('app.color.color_text_3'))
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .height(40)
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor($r('app.color.color_bg_card'))
      .shadow(AppConstants.SHADOW_CARD)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.gotoSearch();
      })

      // 搜索按钮（对齐设计稿 qn-search-btn：黑底白字 + 圆角）
      Text('搜索')
        .fontSize(13)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .height(32)
        .padding({ left: 16, right: 16 })
        .borderRadius(AppConstants.RADIUS_SM)
        .backgroundColor($r('app.color.color_ink'))
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.gotoSearch();
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 10 })
    .alignItems(VerticalAlign.Center)
  }

  /** 排序栏（对齐设计稿 qn-sortbar：4 项等分 + 筛选按钮） */
  @Builder
  SortBar() {
    Row() {
      // 4 个排序项
      Row() {
        ForEach(this.sortOptions, (opt: SortOption, _i: number) => {
          Row({ space: 4 }) {
            Text(opt.label)
              .fontSize(14)
              .fontColor(this.currentSort === opt.sortBy ? $r('app.color.color_ink') : $r('app.color.color_text_3'))
              .fontWeight(this.currentSort === opt.sortBy ? FontWeight.Bold : FontWeight.Medium)
            // 价格项显示上下三角（对齐设计稿 qn-sort-tri）
            if (opt.hasTri) {
              Column({ space: 1 }) {
                Text('▲')
                  .fontSize(7)
                  .fontColor(this.currentSort === 'price_desc' ? $r('app.color.color_ink') : $r('app.color.color_text_4'))
                Text('▼')
                  .fontSize(7)
                  .fontColor(this.currentSort === 'price_asc' ? $r('app.color.color_ink') : $r('app.color.color_text_4'))
              }
            }
          }
          .layoutWeight(1)
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            // 价格项点击在升序/降序间切换
            if (opt.sortBy === 'price_asc') {
              this.onSortChange(this.currentSort === 'price_asc' ? 'price_desc' : 'price_asc');
            } else {
              this.onSortChange(opt.sortBy);
            }
          })
        }, (opt: SortOption) => opt.sortBy)
      }
      .layoutWeight(1)
      .height('100%')

      // 筛选按钮（对齐设计稿 qn-filter-btn：漏斗 + 筛选文字）
      Row({ space: 4 }) {
        Text('⚙')
          .fontSize(16)
          .fontColor($r('app.color.color_text_3'))
        Text('筛选')
          .fontSize(13)
          .fontColor($r('app.color.color_text_3'))
          .fontWeight(FontWeight.Medium)
      }
      .height('100%')
      .padding({ left: 14 })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        Logger.info(AppConstants.SCENE_USER, { action: 'filter_placeholder' });
      })
    }
    .width('100%')
    .height(44)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_page'))
    .borderWidth({ bottom: 1 })
    .borderColor($r('app.color.color_divider'))
    .alignItems(VerticalAlign.Center)
  }

  /** 商品横向卡片（对齐设计稿 qn-prod-card：80×80 主图 + 信息区 + 价格） */
  @Builder
  ProductRowCard(item: ProductListItem) {
    Row({ space: 12 }) {
      // 主图（80×80 圆角，对齐设计稿 qn-prod-img）
      Image(ImageUtil.get(item.mainImage))
        .width(80)
        .height(80)
        .borderRadius(AppConstants.RADIUS_MD)
        .objectFit(ImageFit.Cover)
        .backgroundColor($r('app.color.color_fill'))

      // 信息区（对齐设计稿 qn-prod-info：标题 + 卖家 + 价格行）
      Column() {
        // 标题（最多2行）
        Text(item.title)
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .lineHeight(19)

        // 卖家行（对齐设计稿 qn-prod-seller：彩色圆形首字 + 昵称）
        Row({ space: 5 }) {
          Text(this.getSellerInitial(item.farmerName))
            .fontSize(9)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .width(16)
            .height(16)
            .borderRadius(AppConstants.RADIUS_PILL)
            .backgroundColor(this.getSellerColor(item.farmerName))
            .textAlign(TextAlign.Center)
          Text(item.farmerName)
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')
        .margin({ top: 4 })

        // 价格 + 月销（对齐设计稿 qn-prod-bottom：价格 + 月销）
        Row() {
          // 价格（¥ 小 + 数字大，对齐设计稿 qn-price）
          Row({ space: 1 }) {
            Text('¥')
              .fontSize(12)
              .fontColor($r('app.color.color_live'))
              .fontWeight(FontWeight.Bold)
            Text(this.formatPrice(item.price))
              .fontSize(20)
              .fontColor($r('app.color.color_live'))
              .fontWeight(FontWeight.Bold)
          }
          .alignItems(VerticalAlign.Bottom)

          Blank()

          // 月销量
          Text(`月销${this.formatSales(item.monthlySales)}`)
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
        }
        .width('100%')
        .margin({ top: 4 })
        .alignItems(VerticalAlign.Bottom)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(VerticalAlign.Top)
    .onClick(() => {
      this.gotoProductDetail(item.productId);
    })
  }

  /** 获取卖家昵称首字（用于彩色圆形头像） */
  private getSellerInitial(name: string): string {
    if (name.length === 0) {
      return '?';
    }
    return name.charAt(0);
  }

  /** 根据卖家名生成稳定颜色（对齐设计稿多色头像） */
  private getSellerColor(name: string): ResourceColor {
    const colors: ResourceColor[] = [
      $r('app.color.color_green'),
      $r('app.color.color_live'),
      $r('app.color.color_info'),
      $r('app.color.color_warn'),
      $r('app.color.color_green_deep'),
      $r('app.color.color_yellow_deep')
    ];
    let hash: number = 0;
    for (let i = 0; i < name.length; i++) {
      hash = (hash * 31 + name.charCodeAt(i)) & 0x7fffffff;
    }
    return colors[hash % colors.length];
  }

  /** 格式化价格（保留1位小数） */
  private formatPrice(price: number): string {
    return price.toFixed(1);
  }

  /** 格式化月销量（>=1000 显示 k） */
  private formatSales(count: number): string {
    if (count >= 1000) {
      return `${(count / 1000).toFixed(1)}k`;
    }
    return `${count}`;
  }
}
