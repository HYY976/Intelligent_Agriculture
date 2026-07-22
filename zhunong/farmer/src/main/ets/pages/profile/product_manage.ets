/**
 * product_manage - 商品管理（spec 3.2.4.5）
 *
 * 商品列表 + 上下架 + 编辑 + 删除
 * - 状态筛选（全部/已上架/待审核/仓库中/已驳回）
 * - 分页加载
 * - 跳转商品编辑
 */

import { Logger, AppConstants, ToastUtil, ProductStatus, NavigationHelper, RouteName, ListStateView } from 'common';
import { FarmerProductItem, PRODUCT_STATUS_LABELS } from '../../model/FarmerModels';
import { ProductManageRepository } from '../../repository/ProductManageRepository';
import { ProductManageDataSource } from '../../viewmodel/ProductManageDataSource';

/** 状态筛选项 */
interface StatusFilterOption {
  value: string; // 'all' | ProductStatus
  label: string;
}

/** 跳转商品编辑页的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface ProductEditParam {
  productId: string;
}

@ComponentV2
export struct ProductManage {
  /** 列表数据源（spec 10.11.4 Step 3：BaseDataSource + LazyForEach） */
  private dataSource: ProductManageDataSource = new ProductManageDataSource();
  /** 列表是否为空（用于三态空态判断） */
  @Local isEmpty: boolean = true;
  /** 当前状态筛选 */
  @Local statusFilter: string = 'all';

  /** 状态选项 */
  private statusOptions: StatusFilterOption[] = [
    { value: 'all', label: '全部' },
    { value: 'approved', label: '已上架' },
    { value: 'pending_review', label: '待审核' },
    { value: 'draft', label: '仓库中' },
    { value: 'rejected', label: '已驳回' },
    { value: 'off_shelf', label: '已下架' }
  ];

  async aboutToAppear(): Promise<void> {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'product_manage_appear' });
    await this.refresh();
  }

  /** 刷新 */
  private async refresh(): Promise<void> {
    this.dataSource.setStatus(this.statusFilter);
    await this.dataSource.refresh();
    this.isEmpty = this.dataSource.totalCount() === 0;
  }

  /** 切换状态筛选 */
  private async onStatusChange(s: string): Promise<void> {
    this.statusFilter = s;
    await this.refresh();
  }

  /** 跳转编辑 */
  private gotoEdit(productId: string): void {
    const param: ProductEditParam = { productId: productId };
    NavigationHelper.push(RouteName.FARMER_PRODUCT_EDIT, param);
  }

  /** 切换上下架 */
  private async toggleShelf(product: FarmerProductItem): Promise<void> {
    const target: ProductStatus = product.status === 'approved'
      ? 'off_shelf'
      : 'approved';
    try {
      await ProductManageRepository.setProductStatus(product.productId, target);
      ToastUtil.success(target === 'approved' ? '已上架' : '已下架');
      Logger.info(AppConstants.SCENE_FARMER, { action: 'toggle_shelf', productId: product.productId, productStatus: target });
      // spec 10.11.4 Step 3：操作成功后刷新数据源
      await this.dataSource.refresh();
      this.isEmpty = this.dataSource.totalCount() === 0;
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'toggle_shelf_fail', error: (err as Error).message });
      ToastUtil.error('操作失败');
    }
  }

  /** 删除商品 */
  private async deleteProduct(product: FarmerProductItem): Promise<void> {
    try {
      await ProductManageRepository.deleteProduct(product.productId);
      ToastUtil.success('已删除');
      Logger.info(AppConstants.SCENE_FARMER, { action: 'delete_product', productId: product.productId });
      // spec 10.11.4 Step 3：操作成功后刷新数据源
      await this.dataSource.refresh();
      this.isEmpty = this.dataSource.totalCount() === 0;
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'delete_product_fail', error: (err as Error).message });
      ToastUtil.error('删除失败');
    }
  }

  /** 状态颜色 */
  private statusColor(status: ProductStatus): Resource {
    if (status === 'approved') {
      return $r('app.color.color_primary');
    } else if (status === 'pending_review') {
      return $r('app.color.color_secondary');
    } else if (status === 'rejected') {
      return $r('app.color.color_error');
    }
    return $r('app.color.color_text_hint');
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        this.StatusFilterBar()
        this.ProductList()
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
      Text('商品管理')
        .fontSize(18)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** 状态筛选 */
  @Builder
  StatusFilterBar() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.statusOptions, (opt: StatusFilterOption) => {
          Text(opt.label)
            .fontSize(12)
            .fontColor(this.statusFilter === opt.value ? Color.White : $r('app.color.color_text_secondary'))
            .backgroundColor(this.statusFilter === opt.value ? $r('app.color.color_primary') : $r('app.color.color_bg_card'))
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(14)
            .onClick(() => { this.onStatusChange(opt.value); })
        }, (opt: StatusFilterOption) => opt.value)
      }
      .padding({ left: 12, right: 12 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .height(44)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 商品列表 */
  @Builder
  ProductList() {
    if (this.dataSource.getLoadFailed()) {
      ListStateView({ state: 'error', onRefresh: () => this.refresh() })
    } else if (this.dataSource.getIsFirstLoad()) {
      ListStateView({ state: 'loading' })
    } else if (this.dataSource.totalCount() === 0) {
      ListStateView({ state: 'empty', emptyUseEmoji: true, emptyEmoji: '🛍', emptyText: '暂无商品' })
    } else {
      List({ space: 12 }) {
        LazyForEach(this.dataSource, (product: FarmerProductItem) => {
          ListItem() {
            this.ProductCard(product)
          }
        }, (product: FarmerProductItem) => `${product.productId}_${product.status}_${product.stock}`)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 12, right: 12, top: 8, bottom: 12 })
      .scrollBar(BarState.Off)
      .cachedCount(AppConstants.LIST_CACHED_COUNT)
      .onReachEnd(() => {
        this.dataSource.loadMore();
      })
    }
  }

  /** 商品卡片 */
  @Builder
  ProductCard(product: FarmerProductItem) {
    Column({ space: 8 }) {
      Row({ space: 12 }) {
        Text('🌾')
          .fontSize(28)
          .width(72)
          .height(72)
          .borderRadius(8)
          .backgroundColor($r('app.color.color_primary_light'))
          .textAlign(TextAlign.Center)
        Column({ space: 4 }) {
          Text(product.title)
            .fontSize(14)
            .fontColor($r('app.color.color_text_primary'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
          Row({ space: 8 }) {
            Text(`¥${product.price.toFixed(2)}`)
              .fontSize(13)
              .fontColor($r('app.color.color_price'))
              .fontWeight(FontWeight.Bold)
            Text(`库存 ${product.stock}`)
              .fontSize(11)
              .fontColor($r('app.color.color_text_hint'))
            Text(`月销 ${product.monthlySales}`)
              .fontSize(11)
              .fontColor($r('app.color.color_text_hint'))
          }
          .width('100%')
          Text(PRODUCT_STATUS_LABELS[product.status])
            .fontSize(11)
            .fontColor(this.statusColor(product.status))
            .fontWeight(FontWeight.Medium)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      // 驳回原因
      if (product.status === 'rejected' && product.rejectReason) {
        Text(`⚠ 驳回原因：${product.rejectReason}`)
          .fontSize(11)
          .fontColor($r('app.color.color_error'))
          .width('100%')
      }

      // 操作按钮
      Row({ space: 8 }) {
        Button('编辑')
          .layoutWeight(1)
          .height(32)
          .borderRadius(16)
          .backgroundColor($r('app.color.color_bg_page'))
          .fontColor($r('app.color.color_text_primary'))
          .fontSize(12)
          .onClick(() => this.gotoEdit(product.productId))
        if (product.status === 'approved' || product.status === 'off_shelf') {
          Button(product.status === 'approved' ? '下架' : '上架')
            .layoutWeight(1)
            .height(32)
            .borderRadius(16)
            .backgroundColor($r('app.color.color_bg_page'))
            .fontColor($r('app.color.color_secondary'))
            .fontSize(12)
            .onClick(() => this.toggleShelf(product))
        }
        Button('删除')
          .layoutWeight(1)
          .height(32)
          .borderRadius(16)
          .backgroundColor($r('app.color.color_bg_page'))
          .fontColor($r('app.color.color_error'))
          .fontSize(12)
          .onClick(() => this.deleteProduct(product))
      }
      .width('100%')
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }
}
