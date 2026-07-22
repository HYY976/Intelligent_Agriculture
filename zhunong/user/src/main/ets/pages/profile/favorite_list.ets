/**
 * favorite_list - 我的收藏页
 * 遵循 spec 3.1.3.5：收藏商品列表，支持取消收藏
 *
 * spec 10.11.4 Step 2：ForEach → LazyForEach + keyGenerator + cachedCount
 */

import { UserRoutes, Logger, AppConstants, ToastUtil, RouteName, NavigationHelper, ListStateView } from 'common';
import { FavoriteItem } from '../../model/ProfileModels';
import { removeMockFavorite } from '../../mock/ProfileMock';
import { FavoriteListDataSource } from '../../viewmodel/FavoriteListDataSource';
import { ImageUtil } from '../../utils/ImageUtil';

/** 跳转商品详情的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface ProductDetailParam {
  productId: string;
}

@ComponentV2
export struct FavoriteList {
  /** 收藏数据源（spec 10.11.4：LazyForEach 替代 ForEach） */
  private dataSource: FavoriteListDataSource = new FavoriteListDataSource();
  /** 列表是否为空 */
  @Local isEmpty: boolean = true;

  async aboutToAppear(): Promise<void> {
    await this.refreshList();
  }

  /** 刷新列表（spec 10.11.4：异步 refresh + 空状态同步） */
  private async refreshList(): Promise<void> {
    await this.dataSource.refresh();
    this.isEmpty = this.dataSource.totalCount() === 0;
  }

  private gotoProductDetail(productId: string): void {
    const param: ProductDetailParam = { productId: productId };
    NavigationHelper.push(RouteName.USER_PRODUCT_DETAIL, param);
  }

  /** 取消收藏 */
  private async onRemove(fav: FavoriteItem): Promise<void> {
    removeMockFavorite(fav.favoriteId);
    ToastUtil.success('已取消收藏');
    await this.refreshList();
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部栏
        Row() {
          Text('‹').fontSize(28).fontColor($r('app.color.color_text_primary')).onClick(() => { NavigationHelper.pop(); })
          Text('我的收藏').fontSize(18).fontColor($r('app.color.color_text_primary')).fontWeight(FontWeight.Medium).layoutWeight(1).textAlign(TextAlign.Center)
          Text('').width(28)
        }
        .width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor($r('app.color.color_bg_card')).alignItems(VerticalAlign.Center)

        // 收藏列表（spec 10.11.4 Step 4：4 态状态机 error / loading / empty / list）
        if (this.dataSource.getLoadFailed()) {
          ListStateView({ state: 'error', onRefresh: () => this.refreshList() })
        } else if (this.dataSource.getIsFirstLoad()) {
          ListStateView({ state: 'loading' })
        } else if (this.dataSource.totalCount() === 0) {
          ListStateView({ state: 'empty', emptyText: '暂无收藏', emptyDesc: '收藏喜欢的商品方便下次购买' })
        } else {
          List({ space: 12 }) {
            LazyForEach(this.dataSource, (fav: FavoriteItem, _i: number) => {
              ListItem() {
                Row({ space: 10 }) {
                  Image(ImageUtil.get(fav.image)).width(80).height(80).borderRadius(8).objectFit(ImageFit.Cover)
                  Column({ space: 4 }) {
                    Text(fav.title).fontSize(13).fontColor($r('app.color.color_text_primary')).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(`🏪 ${fav.farmerName}`).fontSize(11).fontColor($r('app.color.color_text_secondary'))
                    Row() {
                      Text(`¥${fav.price.toFixed(2)}`).fontSize(15).fontColor($r('app.color.color_price')).fontWeight(FontWeight.Bold)
                      Blank()
                      Text('取消收藏').fontSize(11).fontColor($r('app.color.color_error')).padding({ left: 8, right: 8, top: 4, bottom: 4 }).border({ width: 1, color: $r('app.color.color_error') }).borderRadius(12).onClick(() => { this.onRemove(fav); })
                    }.width('100%').alignItems(VerticalAlign.Bottom)
                  }.layoutWeight(1).height(80).alignItems(HorizontalAlign.Start)
                }.width('100%').padding(12).backgroundColor($r('app.color.color_bg_card')).borderRadius(12).onClick(() => { this.gotoProductDetail(fav.productId); })
              }
            }, (fav: FavoriteItem) => fav.favoriteId)
          }
          .width('100%').layoutWeight(1).padding({ left: 12, right: 12, top: 12 }).scrollBar(BarState.Off)
          .cachedCount(AppConstants.LIST_CACHED_COUNT)
        }
      }
      .width('100%').height('100%').backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

}
