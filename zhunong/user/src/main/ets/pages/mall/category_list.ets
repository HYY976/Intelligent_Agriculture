/**
 * category_list - 商品分类页
 * 遵循 spec 3.1.4.1：三级分类树（左侧一级分类Tab + 右侧二三级分类网格）
 * 点击末级分类跳转商品列表页
 *
 * spec 10.11.4 Step 2：外层 ForEach（一级分类）→ LazyForEach + keyGenerator + cachedCount
 * 内层 ForEach（二三级分类）保留（UI 元素级，spec 10.11.1 注释允许保留）
 */

import { UserRoutes, RouteName, NavigationHelper, Logger, AppConstants, ListStateView } from 'common';
import { Category } from '../../model/ProductModels';
import { CategoryListDataSource } from '../../viewmodel/CategoryListDataSource';

/** 跳转商品列表的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface ProductListNavParam {
  categoryId: string;
  categoryName: string;
}

@ComponentV2
export struct CategoryList {
  /** 一级分类数据源（spec 10.11.4：LazyForEach 替代 ForEach） */
  private dataSource: CategoryListDataSource = new CategoryListDataSource();
  /** 当前选中的一级分类索引 */
  @Local currentTopIndex: number = 0;
  /** 列表是否为空（驱动 4 态状态机切换） */
  @Local isEmpty: boolean = true;

  async aboutToAppear(): Promise<void> {
    await this.refresh();
    Logger.info(AppConstants.SCENE_USER, { action: 'category_list_appear', total: this.dataSource.totalCount() });
  }

  /** 刷新列表（spec 10.13：4 态状态机） */
  private async refresh(): Promise<void> {
    await this.dataSource.refresh();
    this.isEmpty = this.dataSource.totalCount() === 0;
  }

  /** 点击末级分类 → 商品列表 */
  private gotoProductList(categoryId: string, categoryName: string): void {
    const param: ProductListNavParam = { categoryId: categoryId, categoryName: categoryName };
    NavigationHelper.push(RouteName.USER_PRODUCT_LIST, param);
    Logger.info(AppConstants.SCENE_USER, JSON.stringify({ action: 'goto_product_list', from: 'category', categoryId: categoryId }));
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
          Text('商品分类')
            .fontSize(18)
            .fontColor($r('app.color.color_text_primary'))
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          Text('')
            .width(28)
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor($r('app.color.color_bg_card'))
        .alignItems(VerticalAlign.Center)

        // spec 10.11.4 Step 4：4 态状态机（error / loading / empty / list）
        if (this.dataSource.getLoadFailed()) {
          ListStateView({ state: 'error', onRefresh: () => this.refresh() })
        } else if (this.dataSource.getIsFirstLoad()) {
          ListStateView({ state: 'loading' })
        } else if (this.dataSource.totalCount() === 0) {
          this.EmptyView()
        } else {
        // 左右布局：左侧一级分类 + 右侧二三级分类
        Row() {
          // 左侧一级分类
          Column() {
            List() {
              LazyForEach(this.dataSource, (cat: Category, index: number) => {
                ListItem() {
                  Column({ space: 6 }) {
                    Text(cat.icon ?? '')
                      .fontSize(22)
                    Text(cat.name)
                      .fontSize(12)
                      .fontColor(this.currentTopIndex === index ? $r('app.color.color_cta_black') : $r('app.color.color_text_secondary'))
                      .fontWeight(this.currentTopIndex === index ? FontWeight.Bold : FontWeight.Normal)
                  }
                  .width('100%')
                  .height(72)
                  .justifyContent(FlexAlign.Center)
                  .alignItems(HorizontalAlign.Center)
                  .backgroundColor(this.currentTopIndex === index ? $r('app.color.color_bg_card') : $r('app.color.color_bg_page'))
                  .border({ width: { left: 3 }, color: this.currentTopIndex === index ? $r('app.color.color_primary') : Color.Transparent })
                  .onClick(() => {
                    this.currentTopIndex = index;
                  })
                }
              }, (cat: Category) => cat.categoryId)
            }
            .width('100%')
            .layoutWeight(1)
            .cachedCount(AppConstants.LIST_CACHED_COUNT)
            .divider({ strokeWidth: 0.5, color: $r('app.color.color_divider'), startMargin: 8, endMargin: 8 })
          }
          .width(96)
          .height('100%')
          .backgroundColor($r('app.color.color_bg_page'))

          // 右侧二三级分类
          Scroll() {
            Column({ space: 16 }) {
              if (this.dataSource.totalCount() > 0 && this.currentTopIndex < this.dataSource.totalCount()) {
                ForEach(this.dataSource.getData(this.currentTopIndex).children ?? [], (subCat: Category, _i: number) => {
                  // 二级分类标题
                  Column({ space: 10 }) {
                    Text(subCat.name)
                      .fontSize(14)
                      .fontColor($r('app.color.color_text_primary'))
                      .fontWeight(FontWeight.Medium)
                      .alignSelf(ItemAlign.Start)

                    // 三级分类网格（3列）
                    Grid() {
                      ForEach(subCat.children ?? [], (leafCat: Category, _j: number) => {
                        GridItem() {
                          Column({ space: 6 }) {
                            Text(leafCat.icon ?? '')
                              .fontSize(28)
                            Text(leafCat.name)
                              .fontSize(12)
                              .fontColor($r('app.color.color_text_secondary'))
                          }
                          .width('100%')
                          .height(72)
                          .justifyContent(FlexAlign.Center)
                          .alignItems(HorizontalAlign.Center)
                          .backgroundColor($r('app.color.color_bg_page'))
                          .borderRadius(8)
                          .onClick(() => {
                            this.gotoProductList(leafCat.categoryId, leafCat.name);
                          })
                        }
                      }, (leafCat: Category) => leafCat.categoryId)
                    }
                    .columnsTemplate('1fr 1fr 1fr')
                    .rowsGap(8)
                    .columnsGap(8)
                    .width('100%')
                  }
                  .width('100%')
                  .alignItems(HorizontalAlign.Start)
                }, (subCat: Category) => subCat.categoryId)
              }
            }
            .width('100%')
            .padding(12)
          }
          .layoutWeight(1)
          .height('100%')
          .backgroundColor($r('app.color.color_bg_card'))
          .scrollBar(BarState.Off)
        }
        .width('100%')
        .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 空状态（spec 10.13：4 态状态机） */
  @Builder
  EmptyView() {
    Column({ space: 12 }) {
      Text('📂')
        .fontSize(64)
      Text('暂无分类数据')
        .fontSize(14)
        .fontColor($r('app.color.color_text_secondary'))
      Button('刷新')
        .height(36)
        .borderRadius(18)
        .backgroundColor($r('app.color.color_cta_black'))
        .fontColor(Color.White)
        .fontSize(14)
        .onClick(() => this.refresh())
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

}
