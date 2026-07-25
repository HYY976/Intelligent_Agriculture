/**
 * cart_page - 购物车页（对齐设计稿 pages/user-cart.html）
 *  - 顶部栏：居中标题"购物车" + 编辑/完成按钮
 *  - 优惠提示条：浅黄底 + 虚线边框 + 礼物图标 + 满减提示
 *  - 店铺分组卡：白卡 + 绿色圆形勾选框 + 店铺名 + 进店 + 商品行
 *  - 商品行：勾选框 + 80×80主图 + 标题 + 规格标签 + 价格 + 步进器
 *  - 推荐区：为你推荐 + 横滑商品卡(120宽)
 *  - 底部结算栏：全选 + 合计(红) + 去结算/删除按钮(黄/红)
 * spec 3.1.3.4
 * 导出 CartContent 供 home_page Tab 内嵌使用
 */

import { Logger, AppConstants, ToastUtil, RouteName, NavigationHelper, ListStateView } from 'common';
import { CartItem, CartGroup } from '../../model/CartModels';
import { Product } from '../../model/ProductModels';
import {
  updateCartItemSelected, toggleGroupSelect, toggleAllSelect,
  updateCartItemQuantity, deleteCartItem, clearSelectedCartItems
} from '../../mock/CartMock';
import { MOCK_PRODUCTS } from '../../mock/ProductMock';
import { CartDataSource } from '../../viewmodel/CartDataSource';
import { ImageUtil } from '../../utils/ImageUtil';

/** 推荐商品参数（跳转商品详情） */
interface ProductDetailParam {
  productId: string;
}

/** 购物车内容组件（可复用于 Tab 与独立页） */
@ComponentV2
export struct CartContent {
  /** 购物车分组数据源 */
  private dataSource: CartDataSource = new CartDataSource();
  /** 列表是否为空 */
  @Local isEmpty: boolean = true;
  /** 是否全选 */
  @Local allSelected: boolean = false;
  /** 选中总数 */
  @Local selectedCount: number = 0;
  /** 合计金额 */
  @Local totalAmount: number = 0;
  /** 是否编辑模式（编辑模式下底部按钮变为删除） */
  @Local isEditing: boolean = false;
  /** 推荐商品列表 */
  private recommendList: Product[] = MOCK_PRODUCTS.slice(0, 6);

  async aboutToAppear(): Promise<void> {
    await this.refreshCart();
  }

  /** 刷新购物车数据 */
  private async refreshCart(): Promise<void> {
    await this.dataSource.refresh();
    this.isEmpty = this.dataSource.totalCount() === 0;
    this.updateSummary();
  }

  /** 重新计算汇总 */
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

  /** 数量减少 */
  private async onQuantityMinus(item: CartItem): Promise<void> {
    if (item.quantity > 1) {
      updateCartItemQuantity(item.cartItemId, item.quantity - 1);
      await this.refreshCart();
    }
  }

  /** 数量增加 */
  private async onQuantityPlus(item: CartItem): Promise<void> {
    if (item.quantity < item.stock) {
      updateCartItemQuantity(item.cartItemId, item.quantity + 1);
      await this.refreshCart();
    }
  }

  /** 删除选中商品 */
  private async onDeleteSelected(): Promise<void> {
    if (this.selectedCount === 0) {
      ToastUtil.warning('请选择要删除的商品');
      return;
    }
    clearSelectedCartItems();
    ToastUtil.success('已删除选中商品');
    this.isEditing = false;
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

  /** 跳转商品详情 */
  private gotoProductDetail(productId: string): void {
    const param: ProductDetailParam = { productId: productId };
    NavigationHelper.push(RouteName.USER_PRODUCT_DETAIL, param);
  }

  /** 切换编辑模式 */
  private onToggleEdit(): void {
    this.isEditing = !this.isEditing;
  }

  /** 格式化价格 */
  private formatPrice(price: number): string {
    return price.toFixed(1);
  }

  build() {
    Column() {
      // 4 态状态机
      if (this.dataSource.getLoadFailed()) {
        ListStateView({ state: 'error', onRefresh: () => this.refreshCart() })
      } else if (this.dataSource.getIsFirstLoad()) {
        ListStateView({ state: 'loading' })
      } else if (this.dataSource.totalCount() === 0) {
        // 空购物车
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
          // 顶部栏（对齐设计稿 qn-topbar：居中标题 + 编辑）
          this.TopBar()

          // 内容滚动区
          Scroll() {
            Column({ space: 12 }) {
              // 优惠提示条（对齐设计稿 qn-cart-promo）
              this.PromoBar()

              // 店铺分组列表
              ForEach(this.dataSource.getGroups(), (group: CartGroup, _gi: number) => {
                this.ShopGroupCard(group)
              }, (group: CartGroup) => group.farmerId + `_${group.allSelected}_${group.items.length}`)

              // 推荐区（对齐设计稿 qn-rec-scroll）
              this.RecommendationSection()
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 4, bottom: 16 })
            .alignItems(HorizontalAlign.Start)
          }
          .layoutWeight(1)
          .width('100%')
          .scrollBar(BarState.Off)

          // 底部结算栏（对齐设计稿 qn-cart-bar）
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

  /** 顶部栏（对齐设计稿 qn-topbar：居中标题 + 编辑） */
  @Builder
  TopBar() {
    Row() {
      // 左侧占位（保持标题居中）
      Text('')
        .width(48)

      // 居中标题（对齐设计稿 qn-title-center：17px 700）
      Text('购物车')
        .fontSize(17)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 编辑/完成按钮（对齐设计稿 qn-edit-btn：14px 600）
      Text(this.isEditing ? '完成' : '编辑')
        .fontSize(14)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Medium)
        .width(48)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.onToggleEdit();
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 10 })
    .alignItems(VerticalAlign.Center)
  }

  /** 优惠提示条（对齐设计稿 qn-cart-promo：浅黄底 + 虚线边框） */
  @Builder
  PromoBar() {
    Row({ space: 8 }) {
      Text('🎁')
        .fontSize(16)
      Text('满99元减20元，还差')
        .fontSize(13)
        .fontColor($r('app.color.color_ink_2'))
        .fontWeight(FontWeight.Medium)
      Text('¥70.1')
        .fontSize(13)
        .fontColor($r('app.color.color_live'))
        .fontWeight(FontWeight.Bold)
      Text('元')
        .fontSize(13)
        .fontColor($r('app.color.color_ink_2'))
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor($r('app.color.color_yellow_tint'))
    .border({ width: 1, color: $r('app.color.color_yellow_deep'), style: BorderStyle.Dashed })
    .borderRadius(AppConstants.RADIUS_MD)
    .alignItems(VerticalAlign.Center)
  }

  /** 店铺分组卡（对齐设计稿 qn-cart-shop） */
  @Builder
  ShopGroupCard(group: CartGroup) {
    Column({ space: 0 }) {
      // 店铺行（对齐设计稿 qn-cart-shop-head）
      Row({ space: 10 }) {
        // 圆形勾选框（对齐设计稿 qn-check：22px 绿色圆）
        this.RoundCheckBox(group.allSelected, () => {
          this.onGroupSelect(group);
        })

        // 店铺图标 + 名称（对齐设计稿 qn-cart-shop-name）
        Row({ space: 6 }) {
          Text('🏪')
            .fontSize(16)
          Text(group.farmerName)
            .fontSize(15)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(VerticalAlign.Center)

        // 进店（对齐设计稿 qn-cart-shop-enter）
        Row({ space: 1 }) {
          Text('进店')
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
          Text('›')
            .fontSize(14)
            .fontColor($r('app.color.color_text_3'))
        }
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding({ bottom: 4 })
      .alignItems(VerticalAlign.Center)

      // 商品行列表
      ForEach(group.items, (item: CartItem, _ii: number) => {
        this.CartItemRow(group, item)
      }, (item: CartItem) => item.cartItemId + `_${item.selected}_${item.quantity}`)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 4 })
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 购物车商品行（对齐设计稿 qn-cart-item） */
  @Builder
  CartItemRow(group: CartGroup, item: CartItem) {
    Row({ space: 12 }) {
      // 圆形勾选框
      this.RoundCheckBox(item.selected, () => {
        this.onItemSelect(group, item);
      })

      // 商品主图（80×80 圆角14）
      Image(ImageUtil.get(item.image))
        .width(80)
        .height(80)
        .borderRadius(AppConstants.RADIUS_MD)
        .objectFit(ImageFit.Cover)
        .backgroundColor($r('app.color.color_fill'))

      // 商品信息区（对齐设计稿 qn-cart-info）
      Column() {
        // 商品名称（14px 700）
        Text(item.title)
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .lineHeight(19)
          .width('100%')

        // 规格标签（对齐设计稿 qn-cart-spec：11px 灰底）
        Text(item.specText)
          .fontSize(11)
          .fontColor($r('app.color.color_text_3'))
          .backgroundColor($r('app.color.color_fill'))
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .borderRadius(AppConstants.RADIUS_XS)
          .margin({ top: 6 })

        // 底部行：价格 + 步进器（对齐设计稿 qn-cart-bottom）
        Row() {
          // 价格（对齐设计稿 qn-price：¥小 + 数字大 + 红色）
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

          // 步进器（对齐设计稿 qn-stepper：26px 圆形按钮）
          this.Stepper(item)
        }
        .width('100%')
        .margin({ top: 10 })
        .alignItems(VerticalAlign.Bottom)
      }
      .layoutWeight(1)
      .height(80)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .alignItems(VerticalAlign.Top)
    .border({ width: { top: 1 }, color: { top: $r('app.color.color_divider') } })
  }

  /** 圆形勾选框（对齐设计稿 qn-check：22px 圆，选中绿色） */
  @Builder
  RoundCheckBox(isSelected: boolean, onTap: () => void) {
    if (isSelected) {
      Text('✓')
        .fontSize(14)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .width(22)
        .height(22)
        .textAlign(TextAlign.Center)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor($r('app.color.color_green'))
        .onClick(() => {
          onTap();
        })
    } else {
      Text('')
        .width(20)
        .height(20)
        .borderRadius(AppConstants.RADIUS_PILL)
        .border({ width: 1.5, color: $r('app.color.color_text_4') })
        .onClick(() => {
          onTap();
        })
    }
  }

  /** 步进器（对齐设计稿 qn-stepper：26px 圆形按钮 + 数字） */
  @Builder
  Stepper(item: CartItem) {
    Row({ space: 0 }) {
      // 减少按钮
      Text('−')
        .fontSize(14)
        .fontColor(item.quantity > 1 ? $r('app.color.color_ink') : $r('app.color.color_text_4'))
        .width(26)
        .height(26)
        .textAlign(TextAlign.Center)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor($r('app.color.color_fill'))
        .border({ width: 1, color: $r('app.color.color_line_2') })
        .onClick(() => {
          this.onQuantityMinus(item);
        })

      // 数量
      Text(`${item.quantity}`)
        .fontSize(14)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .constraintSize({ minWidth: 30 })

      // 增加按钮
      Text('+')
        .fontSize(14)
        .fontColor(item.quantity < item.stock ? $r('app.color.color_ink') : $r('app.color.color_text_4'))
        .width(26)
        .height(26)
        .textAlign(TextAlign.Center)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor($r('app.color.color_fill'))
        .border({ width: 1, color: $r('app.color.color_line_2') })
        .onClick(() => {
          this.onQuantityPlus(item);
        })
    }
    .alignItems(VerticalAlign.Center)
  }

  /** 推荐区（对齐设计稿 qn-rec-scroll：横滑商品卡） */
  @Builder
  RecommendationSection() {
    Column({ space: 0 }) {
      // 标题行（对齐设计稿 qn-section-head）
      Row() {
        Text('为你推荐')
          .fontSize(16)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        Blank()
        Row({ space: 2 }) {
          Text('换一批')
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
          Text('›')
            .fontSize(14)
            .fontColor($r('app.color.color_text_3'))
        }
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding({ top: 4, bottom: 12 })

      // 横滑商品卡（对齐设计稿 qn-rec-scroll）
      Scroll() {
        Row({ space: 12 }) {
          ForEach(this.recommendList, (product: Product) => {
            this.RecommendCard(product)
          }, (product: Product) => product.productId)
        }
        .padding({ right: 4 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('100%')
    .margin({ top: 16 })
    .alignItems(HorizontalAlign.Start)
  }

  /** 推荐商品卡（对齐设计稿 qn-rec-card：120宽 + 1:1图 + 名称 + 价格） */
  @Builder
  RecommendCard(product: Product) {
    Column({ space: 0 }) {
      // 商品图（120×120 圆角14）
      Image(ImageUtil.get(product.mainImages[0]))
        .width(120)
        .height(120)
        .borderRadius(AppConstants.RADIUS_MD)
        .objectFit(ImageFit.Cover)
        .backgroundColor($r('app.color.color_fill'))

      // 商品名称（12px 600 2行）
      Text(product.title)
        .fontSize(12)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Medium)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .lineHeight(16)
        .margin({ top: 6 })
        .width(120)

      // 价格（对齐设计稿 qn-price）
      Row({ space: 1 }) {
        Text('¥')
          .fontSize(12)
          .fontColor($r('app.color.color_live'))
          .fontWeight(FontWeight.Bold)
        Text(this.formatPrice(product.price))
          .fontSize(16)
          .fontColor($r('app.color.color_live'))
          .fontWeight(FontWeight.Bold)
      }
      .margin({ top: 2 })
      .alignItems(VerticalAlign.Bottom)
    }
    .width(120)
    .onClick(() => {
      this.gotoProductDetail(product.productId);
    })
  }

  /** 底部结算栏（对齐设计稿 qn-cart-bar） */
  @Builder
  BottomBar() {
    Row({ space: 10 }) {
      // 全选（对齐设计稿 qn-bar-check）
      Row({ space: 6 }) {
        this.RoundCheckBox(this.allSelected, () => {
          this.onToggleAll();
        })
        Text('全选')
          .fontSize(13)
          .fontColor($r('app.color.color_ink_2'))
          .fontWeight(FontWeight.Medium)
      }
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.onToggleAll();
      })

      Blank()

      // 合计/数量（对齐设计稿 qn-bar-total）
      if (!this.isEditing) {
        Column() {
          Row({ space: 2 }) {
            Text('合计')
              .fontSize(13)
              .fontColor($r('app.color.color_ink_2'))
              .fontWeight(FontWeight.Medium)
            Text('¥')
              .fontSize(12)
              .fontColor($r('app.color.color_live'))
              .fontWeight(FontWeight.Bold)
            Text(this.formatPrice(this.totalAmount))
              .fontSize(20)
              .fontColor($r('app.color.color_live'))
              .fontWeight(FontWeight.Bold)
          }
          .alignItems(VerticalAlign.Bottom)

          Text('不含运费')
            .fontSize(10)
            .fontColor($r('app.color.color_text_4'))
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.End)
      } else {
        Text(`已选 ${this.selectedCount} 件`)
          .fontSize(13)
          .fontColor($r('app.color.color_ink_2'))
          .fontWeight(FontWeight.Medium)
      }

      // 结算/删除按钮（对齐设计稿 qn-btn-primary/yellow）
      Text(this.isEditing ? `删除(${this.selectedCount})` : `去结算(${this.selectedCount})`)
        .fontSize(15)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .height(42)
        .padding({ left: 22, right: 22 })
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor(this.isEditing
          ? (this.selectedCount > 0 ? $r('app.color.color_live') : $r('app.color.color_text_4'))
          : (this.selectedCount > 0 ? $r('app.color.color_primary') : $r('app.color.color_text_4')))
        .textAlign(TextAlign.Center)
        .onClick(() => {
          if (this.isEditing) {
            this.onDeleteSelected();
          } else {
            this.gotoCheckout();
          }
        })
    }
    .width('100%')
    .height(60)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_NAV)
    .alignItems(VerticalAlign.Center)
  }
}

/** 独立路由入口（深链接用） */
@ComponentV2
export struct CartPage {
  build() {
    NavDestination() {
      Column() {
        CartContent()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }
}
