/**
 * cart_page - 购物车页（Tab 内嵌 + 独立路由双用）
 * 遵循 spec 3.1.3.4：
 *  - 商品按卖家分组展示
 *  - 每项：勾选框 + 商品图 + 标题 + 规格 + 价格 + 数量增减 + 左滑删除
 *  - 底部结算栏：全选 + 合计 + 结算按钮（多卖家合并结算）
 *  - 空购物车：空状态 + "去逛逛"按钮
 *  - Mock 支付（下单后跳转订单确认页）
 *
 * spec 10.11.4 Step 2：外层 ForEach → LazyForEach + keyGenerator + cachedCount
 * 内层 items ForEach 保留（UI 元素级，spec 10.11.1 注释允许保留）
 *
 * 导出 CartContent 供 home_page Tab 内嵌使用
 * 同时作为独立路由（pages/cart/cart_page）支持深链接
 */

import { Logger, AppConstants, UserRoutes, ToastUtil, RouteName, NavigationHelper, ListStateView } from 'common';
import { CartItem, CartGroup, CartSummary } from '../../model/CartModels';
import {
  updateCartItemSelected, toggleGroupSelect, toggleAllSelect,
  updateCartItemQuantity, deleteCartItem, clearSelectedCartItems, getMockCartCount
} from '../../mock/CartMock';
import { CartDataSource } from '../../viewmodel/CartDataSource';
import { ImageUtil } from '../../utils/ImageUtil';
import { QuantitySelector } from '../../components/QuantitySelector';

/** 购物车内容组件（可复用于 Tab 与独立页） */
@ComponentV2
export struct CartContent {
  /** 购物车分组数据源（spec 10.11.4：LazyForEach 替代 ForEach） */
  private dataSource: CartDataSource = new CartDataSource();
  /** 列表是否为空（驱动空状态切换） */
  @Local isEmpty: boolean = true;
  /** 是否全选 */
  @Local allSelected: boolean = false;
  /** 选中总数 */
  @Local selectedCount: number = 0;
  /** 合计金额 */
  @Local totalAmount: number = 0;

  async aboutToAppear(): Promise<void> {
    await this.refreshCart();
  }

  /** 刷新购物车数据（spec 10.11.4：异步 refresh + 同步 summary） */
  private async refreshCart(): Promise<void> {
    await this.dataSource.refresh();
    this.isEmpty = this.dataSource.totalCount() === 0;
    this.updateSummary();
  }

  /** 重新计算汇总（全选状态/数量/金额） */
  private updateSummary(): void {
    let allSel: boolean = true;
    let count: number = 0;
    let amount: number = 0;
    let hasItems: boolean = false;
    const groups: CartGroup[] = this.dataSource.getGroups();
    groups.forEach((g: CartGroup) => {
      g.items.forEach((item: CartItem) => {
        hasItems = true;
        if (item.selected) {
          count += item.quantity;
          amount += item.price * item.quantity;
        } else {
          allSel = false;
        }
      });
    });
    this.allSelected = hasItems && allSel;
    this.selectedCount = count;
    this.totalAmount = Math.round(amount * 100) / 100;
  }

  /** 切换商品选中 */
  private async onItemSelect(group: CartGroup, item: CartItem): Promise<void> {
    updateCartItemSelected(item.cartItemId, !item.selected);
    await this.refreshCart();
  }

  /** 切换分组全选 */
  private async onGroupSelect(group: CartGroup): Promise<void> {
    toggleGroupSelect(group.farmerId, !group.allSelected);
    await this.refreshCart();
  }

  /** 切换全选 */
  private async onToggleAll(): Promise<void> {
    toggleAllSelect(!this.allSelected);
    await this.refreshCart();
  }

  /** 数量变化 */
  private async onQuantityChange(item: CartItem, quantity: number): Promise<void> {
    updateCartItemQuantity(item.cartItemId, quantity);
    await this.refreshCart();
  }

  /** 删除商品 */
  private async onDeleteItem(item: CartItem): Promise<void> {
    deleteCartItem(item.cartItemId);
    ToastUtil.success('已删除');
    await this.refreshCart();
  }

  /** 去结算 */
  private gotoCheckout(): void {
    if (this.selectedCount === 0) {
      ToastUtil.warning('请选择要结算的商品');
      return;
    }
    Logger.info(AppConstants.SCENE_USER, JSON.stringify({
      action: 'cart_checkout',
      count: this.selectedCount,
      amount: this.totalAmount
    }));
    NavigationHelper.push(RouteName.USER_ORDER_CONFIRM);
  }

  /** 去逛逛（空状态按钮） */
  private gotoHome(): void {
    NavigationHelper.pop();
  }

  build() {
    Column() {
      // spec 10.11.4 Step 4：4 态状态机（error / loading / empty / list）
      if (this.dataSource.getLoadFailed()) {
        ListStateView({ state: 'error', onRefresh: () => this.refreshCart() })
      } else if (this.dataSource.getIsFirstLoad()) {
        ListStateView({ state: 'loading' })
      } else if (this.dataSource.totalCount() === 0) {
        // 空购物车（spec 3.1.3.4：空状态 + "去逛逛"按钮；spec 10.17：ListStateView image 模式）
        ListStateView({
          state: 'empty',
          emptyText: '购物车是空的',
          emptyDesc: '快去挑选心仪的农产品吧',
          emptyImage: $r('app.media.empty_cart'),
          emptyActionText: '去逛逛',
          onEmptyAction: () => {
            this.gotoHome();
          }
        })
      } else {
        // 购物车列表
        Column() {
          List({ space: 12 }) {
            LazyForEach(this.dataSource, (group: CartGroup, _gi: number) => {
              ListItemGroup({ header: this.GroupHeader(group) }) {
                ForEach(group.items, (item: CartItem, _ii: number) => {
                  ListItem() {
                    this.CartItemRow(group, item)
                  }
                }, (item: CartItem) => item.cartItemId)
              }
            }, (group: CartGroup) => group.farmerId + `_${group.allSelected}_${group.items.length}`)
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 12, right: 12, top: 12 })
          .alignListItem(ListItemAlign.Center)
          .cachedCount(AppConstants.LIST_CACHED_COUNT)

          // 底部结算栏（spec 3.1.3.4）
          this.BottomBar()
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.color_bg_page'))
  }

  /** 卖家分组头部 */
  @Builder
  GroupHeader(group: CartGroup) {
    Row({ space: 8 }) {
      // 分组全选框
      Text(group.allSelected ? '☑' : '☐')
        .fontSize(20)
        .fontColor(group.allSelected ? $r('app.color.color_primary') : $r('app.color.color_text_hint'))
        .onClick(() => {
          this.onGroupSelect(group);
        })
      Text('🏪')
        .fontSize(14)
      Text(group.farmerName)
        .fontSize(14)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
      Text('进店 >')
        .fontSize(12)
        .fontColor($r('app.color.color_text_secondary'))
    }
    .width('100%')
    .height(40)
    .padding({ left: 12, right: 12 })
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius({ topLeft: 12, topRight: 12 })
    .alignItems(VerticalAlign.Center)
  }

  /** 购物车商品行 */
  @Builder
  CartItemRow(group: CartGroup, item: CartItem) {
    Row({ space: 10 }) {
      // 勾选框
      Text(item.selected ? '☑' : '☐')
        .fontSize(20)
        .fontColor(item.selected ? $r('app.color.color_primary') : $r('app.color.color_text_hint'))
        .onClick(() => {
          this.onItemSelect(group, item);
        })

      // 商品图
      Image(ImageUtil.get(item.image))
        .width(80)
        .height(80)
        .borderRadius(8)
        .objectFit(ImageFit.Cover)

      // 商品信息
      Column({ space: 4 }) {
        Text(item.title)
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(item.specText)
          .fontSize(11)
          .fontColor($r('app.color.color_text_secondary'))
          .backgroundColor($r('app.color.color_bg_page'))
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(4)
        Row() {
          Text('¥')
            .fontSize(11)
            .fontColor($r('app.color.color_price'))
            .fontWeight(FontWeight.Bold)
          Text(item.price.toFixed(2))
            .fontSize(15)
            .fontColor($r('app.color.color_price'))
            .fontWeight(FontWeight.Bold)
          Blank()
          QuantitySelector({
            quantity: item.quantity,
            min: 1,
            max: item.stock,
            onQuantityChange: (q: number) => {
              this.onQuantityChange(item, q);
            }
          })
        }
        .width('100%')
        .alignItems(VerticalAlign.Bottom)
      }
      .layoutWeight(1)
      .height(80)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(12)
    .alignItems(VerticalAlign.Top)
    .gesture(
      SwipeGesture({ fingers: 1, direction: SwipeDirection.Horizontal })
        .onAction(() => {
          this.onDeleteItem(item);
        })
    )
  }

  /** 底部结算栏 */
  @Builder
  BottomBar() {
    Row({ space: 12 }) {
      // 全选
      Row({ space: 6 }) {
        Text(this.allSelected ? '☑' : '☐')
          .fontSize(20)
          .fontColor(this.allSelected ? $r('app.color.color_primary') : $r('app.color.color_text_hint'))
        Text('全选')
          .fontSize(13)
          .fontColor($r('app.color.color_text_secondary'))
      }
      .onClick(() => {
        this.onToggleAll();
      })

      Blank()

      // 合计
      Row({ space: 4 }) {
        Text('合计：')
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
        Text('¥')
          .fontSize(12)
          .fontColor($r('app.color.color_price'))
          .fontWeight(FontWeight.Bold)
        Text(this.totalAmount.toFixed(2))
          .fontSize(18)
          .fontColor($r('app.color.color_price'))
          .fontWeight(FontWeight.Bold)
      }
      .alignItems(VerticalAlign.Bottom)

      // 结算按钮
      Button(`结算(${this.selectedCount})`)
        .height(40)
        .borderRadius(20)
        .backgroundColor(this.selectedCount > 0 ? $r('app.color.color_secondary') : $r('app.color.color_button_disabled'))
        .fontColor(Color.White)
        .fontSize(14)
        .padding({ left: 24, right: 24 })
        .enabled(this.selectedCount > 0)
        .onClick(() => {
          this.gotoCheckout();
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .border({ width: { top: 0.5 }, color: $r('app.color.color_divider') })
    .alignItems(VerticalAlign.Center)
  }

}

/** 独立路由入口（深链接用） */
@ComponentV2
export struct CartPage {
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
          Text('购物车')
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

        // 购物车内容
        CartContent()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }
}
