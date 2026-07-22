/**
 * product_list - 商品列表页
 * 遵循 spec 3.1.4.1：顶部筛选栏 + 双列瀑布流 + LazyForEach 分页
 * 路由参数：categoryId（末级分类ID）/ keyword（搜索关键词）
 */

import { UserRoutes, RouteName, NavigationHelper, Logger, AppConstants } from 'common';
import { ProductListItem, ProductSortBy } from '../../model/ProductModels';
import { ProductListDataSource } from '../../viewmodel/ProductListDataSource';
import { ProductCard } from '../../components/ProductCard';

/** 排序选项配置 */
interface SortOption {
  sortBy: ProductSortBy;
  label: string;
}

/** 跳转商品详情的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface ProductDetailParam {
  productId: string;
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
  /** 排序选项 */
  private sortOptions: SortOption[] = [
    { sortBy: 'comprehensive', label: '综合' },
    { sortBy: 'sales', label: '销量' },
    { sortBy: 'price_asc', label: '价格升' },
    { sortBy: 'price_desc', label: '价格降' },
    { sortBy: 'newest', label: '最新' }
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
    Logger.info(AppConstants.SCENE_USER, JSON.stringify({
      action: 'product_list_appear',
      categoryId: this.categoryId,
      keyword: this.keyword
    }));
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

  /** 下拉刷新 */
  private async onRefresh(): Promise<void> {
    this.isRefreshing = true;
    await this.dataSource.refresh();
    this.isRefreshing = false;
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
          Text(this.categoryName.length > 0 ? this.categoryName : (this.keyword.length > 0 ? `搜索：${this.keyword}` : '全部商品'))
            .fontSize(18)
            .fontColor($r('app.color.color_text_primary'))
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text('')
            .width(28)
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor($r('app.color.color_bg_card'))
        .alignItems(VerticalAlign.Center)

        // 排序栏
        Row() {
          ForEach(this.sortOptions, (opt: SortOption, _i: number) => {
            Text(opt.label)
              .fontSize(13)
              .fontColor(this.currentSort === opt.sortBy ? $r('app.color.color_primary') : $r('app.color.color_text_secondary'))
              .fontWeight(this.currentSort === opt.sortBy ? FontWeight.Bold : FontWeight.Normal)
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
              .onClick(() => {
                this.onSortChange(opt.sortBy);
              })
          }, (opt: SortOption) => opt.sortBy)
        }
        .width('100%')
        .height(44)
        .backgroundColor($r('app.color.color_bg_card'))
        .border({ width: { bottom: 0.5 }, color: $r('app.color.color_divider') })
        .alignItems(VerticalAlign.Center)

        // 商品列表（双列瀑布流）
        Refresh({ refreshing: $$this.isRefreshing }) {
          WaterFlow() {
            LazyForEach(this.dataSource, (item: ProductListItem, index: number) => {
              FlowItem() {
                ProductCard({
                  item: item,
                  onCardClick: (pid: string) => {
                    this.gotoProductDetail(pid);
                  }
                })
              }
              .margin({ bottom: 8 })
            }, (item: ProductListItem) => item.productId + `_${this.dataSource.totalCount()}`)
          }
          .columnsTemplate('1fr 1fr')
          .columnsGap(8)
          .rowsGap(8)
          .padding({ left: 12, right: 12, top: 8, bottom: 12 })
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
}
