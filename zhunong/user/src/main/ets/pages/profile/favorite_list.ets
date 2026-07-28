/**
 * favorite_list - 我的收藏页
 * 遵循 spec 3.1.3.5 + 设计稿 favorite.html 1:1 复刻：
 *  - 顶栏：白色圆形返回按钮 + 居中标题"我的收藏" + 右侧"管理"文字按钮
 *  - 2 列瀑布流商品卡（10px 列间距 + 10px 行间距）
 *  - 卡片：商品图（100%×120px） + 信息区（标题2行 + 卖家 + 价格 + 红心取消收藏按钮）
 *
 * spec 10.11.4 Step 2：ForEach → LazyForEach + keyGenerator + cachedCount
 */

import { Logger, AppConstants, ToastUtil, RouteName, NavigationHelper, ListStateView } from 'common';
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
  /** 是否管理模式（隐藏红心、显示删除） */
  @Local isManageMode: boolean = false;

  async aboutToAppear(): Promise<void> {
    await this.refreshList();
  }

  /** 刷新列表（spec 10.11.4：异步 refresh + 空状态同步） */
  private async refreshList(): Promise<void> {
    await this.dataSource.refresh();
    this.isEmpty = this.dataSource.totalCount() === 0;
  }

  private gotoProductDetail(productId: string): void {
    if (this.isManageMode) {
      return;
    }
    const param: ProductDetailParam = { productId: productId };
    NavigationHelper.push(RouteName.USER_PRODUCT_DETAIL, param);
  }

  /** 取消收藏 */
  private async onRemove(fav: FavoriteItem): Promise<void> {
    removeMockFavorite(fav.favoriteId);
    ToastUtil.success('已取消收藏');
    await this.refreshList();
  }

  /** 切换管理模式 */
  private toggleManage(): void {
    this.isManageMode = !this.isManageMode;
    Logger.info(AppConstants.SCENE_USER, { action: 'favorite_manage_toggle', msg: `isManageMode=${this.isManageMode}` });
  }

  build() {
    NavDestination() {
      Column() {
        // ===== 顶部导航栏（对齐设计稿 qn-topbar） =====
        Row() {
          // 白色圆形返回按钮
          Row() {
            Text('‹').fontSize(22).fontColor($r('app.color.color_ink')).fontWeight(FontWeight.Bold)
          }
          .width(32)
          .height(32)
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_bg_card'))
          .shadow(AppConstants.SHADOW_CARD)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .onClick(() => { NavigationHelper.pop(); })

          // 居中标题
          Text('我的收藏')
            .fontSize(17)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          // 右侧"管理"文字按钮（对齐设计稿 qn-topbar-action）
          Text(this.isManageMode ? '完成' : '管理')
            .fontSize(14)
            .fontColor($r('app.color.color_text_2'))
            .fontWeight(FontWeight.Medium)
            .padding({ left: 4, right: 4 })
            .onClick(() => { this.toggleManage(); })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 4, bottom: 10 })
        .alignItems(VerticalAlign.Center)

        // ===== 收藏列表（spec 10.11.4 Step 4：4 态状态机 error / loading / empty / list） =====
        if (this.dataSource.getLoadFailed()) {
          ListStateView({ state: 'error', onRefresh: () => this.refreshList() })
        } else if (this.dataSource.getIsFirstLoad()) {
          ListStateView({ state: 'loading' })
        } else if (this.dataSource.totalCount() === 0) {
          ListStateView({ state: 'empty', emptyText: '暂无收藏', emptyDesc: '收藏喜欢的商品方便下次购买' })
        } else {
          // 2 列瀑布流（对齐设计稿 qn-fav-grid column-count: 2 + 10px gap）
          WaterFlow() {
            LazyForEach(this.dataSource, (fav: FavoriteItem) => {
              FlowItem() {
                this.FavoriteCard(fav)
              }
              .width('100%')
            }, (fav: FavoriteItem) => fav.favoriteId)
          }
          .columnsTemplate('1fr 1fr')
          .columnsGap(10)
          .rowsGap(10)
          .layoutWeight(1)
          .width('100%')
          .padding({ left: 16, right: 16, top: 4, bottom: 16 })
          .scrollBar(BarState.Off)
          .cachedCount(AppConstants.LIST_CACHED_COUNT)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 收藏商品卡（对齐设计稿 qn-fav-card） */
  @Builder
  FavoriteCard(fav: FavoriteItem) {
    Column() {
      // 商品图（120px 高，对齐设计稿 qn-fav-img）
      Stack({ alignContent: Alignment.TopEnd }) {
        Image(ImageUtil.get(fav.image))
          .width('100%')
          .height(120)
          .objectFit(ImageFit.Cover)
          .backgroundColor($r('app.color.color_fill'))

        // 下架标签（对齐设计稿：商品已下架时显示）
        if (fav.offShelf) {
          Text('已下架')
            .fontSize(10)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(AppConstants.RADIUS_PILL)
            .backgroundColor('rgba(26,26,26,0.6)')
            .margin({ top: 6, right: 6 })
        }

        // 管理模式下的删除浮层
        if (this.isManageMode) {
          // 半透明遮罩 + 删除按钮
          Column()
            .width('100%')
            .height(120)
            .backgroundColor('rgba(26,26,26,0.35)')
          Column() {
            Row() {
              Text('🗑️').fontSize(18).fontColor(Color.White)
            }
            .width(36)
            .height(36)
            .borderRadius(AppConstants.RADIUS_PILL)
            .backgroundColor($r('app.color.color_live'))
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .width('100%')
          .height(120)
        }
      }
      .width('100%')
      .height(120)

      // 信息区（对齐设计稿 qn-fav-info）
      Column({ space: 4 }) {
        // 标题（13px Bold，最多 2 行，对齐设计稿 qn-fav-title）
        Text(fav.title)
          .fontSize(13)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .lineHeight(18)
          .constraintSize({ minHeight: 36 })

        // 卖家（11px text_3，对齐设计稿 qn-fav-seller）
        Text(fav.farmerName)
          .fontSize(11)
          .fontColor($r('app.color.color_text_3'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 底部行：价格 + 红心（对齐设计稿 qn-fav-bottom）
        Row() {
          // 价格（红色 16px Bold，对齐设计稿 qn-fav-price）
          Row({ space: 1 }) {
            Text('¥')
              .fontSize(11)
              .fontColor($r('app.color.color_live'))
              .fontWeight(FontWeight.Bold)
              .baselineOffset(3)
            Text(fav.price.toFixed(1))
              .fontSize(16)
              .fontColor($r('app.color.color_live'))
              .fontWeight(FontWeight.Bold)
          }
          .alignItems(VerticalAlign.Bottom)

          Blank()

          // 红心取消收藏按钮（对齐设计稿 qn-fav-heart，24×24 红色）
          if (!this.isManageMode) {
            Row() {
              Text('❤️').fontSize(18)
            }
            .width(24)
            .height(24)
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
            .onClick(() => { this.onRemove(fav); })
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding(12)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .clip(true)
    .shadow(AppConstants.SHADOW_CARD)
    .onClick(() => { this.gotoProductDetail(fav.productId); })
  }
}
