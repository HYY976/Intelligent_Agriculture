/**
 * order_confirm - 确认订单页
 * 遵循 spec 3.1.4.1：
 *  - 收货地址 + 商品列表 + 优惠券选择 + 留言 + 合计
 *  - 提交订单 → Mock 支付 → 订单状态变为"待发货"
 *  - 支持两种入口：购物车结算（多商品）/ 立即购买（单品）
 */

import { UserRoutes, RouteName, NavigationHelper, Logger, AppConstants, ToastUtil } from 'common';
import { Order, SubOrder, OrderItem, OrderItemSpec } from '../../model/OrderModels';
import { createMockOrder, updateMockOrderStatus, CreateOrderItem } from '../../mock/OrderMock';
import { getMockCartGroups } from '../../mock/CartMock';
import { clearSelectedCartItems } from '../../mock/CartMock';
import { getMockDefaultAddress, MOCK_COUPONS } from '../../mock/ProfileMock';
import { Address, Coupon } from '../../model/ProfileModels';
import { getMockProductById, MOCK_FARMER_NAMES } from '../../mock/ProductMock';
import { ImageUtil } from '../../utils/ImageUtil';
import { CartGroup, CartItem } from '../../model/CartModels';
import { ProductSku } from '../../model/ProductModels';

/** 卖家分组（用于订单确认页展示） */
interface SellerGroup {
  farmerId: string;
  farmerName: string;
  items: OrderItem[];
  subtotal: number;
  freight: number;
}

/** 跳转地址列表的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface AddressListNavParam {
  from: string;
}

/** 跳转订单详情的路由参数 */
interface OrderDetailParam {
  orderId: string;
}

@ComponentV2
export struct OrderConfirm {
  /** 是否立即购买模式 */
  @Local buyNow: boolean = false;
  /** 立即购买商品 ID */
  @Local buyProductId: string = '';
  /** 立即购买 SKU ID */
  @Local buySkuId: string = '';
  /** 立即购买数量 */
  @Local buyQuantity: number = 1;
  /** 收货地址 */
  @Local address: Address | null = null;
  /** 订单商品项列表（按卖家分组） */
  @Local orderItems: OrderItem[] = [];
  /** 卖家分组（farmerId → items） */
  @Local sellerGroups: SellerGroup[] = [];
  /** 选中的优惠券 */
  @Local selectedCoupon: Coupon | null = null;
  /** 可用优惠券列表 */
  @Local availableCoupons: Coupon[] = [];
  /** 买家留言 */
  @Local remark: string = '';
  /** 商品总金额 */
  @Local totalAmount: number = 0;
  /** 运费总额 */
  @Local totalFreight: number = 0;
  /** 优惠金额 */
  @Local discount: number = 0;
  /** 应付金额 */
  @Local payable: number = 0;
  /** 是否正在提交 */
  @Local isSubmitting: boolean = false;

  aboutToAppear(): void {
    const params: Record<string, string> = NavigationHelper.getParam<Record<string, string>>() as Record<string, string>;
    if (params) {
      this.buyNow = params.buyNow === '1';
      this.buyProductId = params.productId ?? '';
      this.buySkuId = params.skuId ?? '';
      this.buyQuantity = parseInt(params.quantity ?? '1', 10);
    }
    this.address = getMockDefaultAddress();
    this.loadOrderItems();
    this.loadCoupons();
    this.calculateTotal();
  }

  /** 加载订单商品项（购物车模式 / 立即购买模式） */
  private loadOrderItems(): void {
    this.sellerGroups = [];
    if (this.buyNow) {
      // 立即购买：单品
      const product = getMockProductById(this.buyProductId);
      if (product) {
        const skuIdx: number = this.buySkuId
          ? product.skuList.findIndex((s: ProductSku) => s.skuId === this.buySkuId)
          : 0;
        const sku = product.skuList[skuIdx >= 0 ? skuIdx : 0];
        const item: OrderItem = {
          productId: product.productId,
          skuId: sku.skuId,
          title: product.title,
          image: product.mainImages[0],
          specs: sku.specs,
          price: sku.price,
          quantity: this.buyQuantity
        };
        const subtotal: number = sku.price * this.buyQuantity;
        const freight: number = subtotal >= 39 ? 0 : 5;
        const sg: SellerGroup = {
          farmerId: product.farmerId,
          farmerName: MOCK_FARMER_NAMES[product.farmerId] ?? '未知卖家',
          items: [item],
          subtotal: subtotal,
          freight: freight
        };
        this.sellerGroups = [sg];
        this.orderItems = [item];
      }
    } else {
      // 购物车结算：选中商品
      const groups: CartGroup[] = getMockCartGroups();
      groups.forEach((g: CartGroup) => {
        const selectedItems: CartItem[] = g.items.filter((it: CartItem) => it.selected);
        if (selectedItems.length === 0) {
          return;
        }
        const items: OrderItem[] = selectedItems.map((ci: CartItem): OrderItem => {
          const spec: OrderItemSpec = { name: '规格', value: ci.specText };
          return {
            productId: ci.productId,
            skuId: ci.skuId,
            title: ci.title,
            image: ci.image,
            specs: [spec],
            price: ci.price,
            quantity: ci.quantity
          };
        });
        const subtotal: number = items.reduce((sum: number, it: OrderItem) => sum + it.price * it.quantity, 0);
        const freight: number = subtotal >= 39 ? 0 : 5;
        const sg: SellerGroup = {
          farmerId: g.farmerId,
          farmerName: g.farmerName,
          items: items,
          subtotal: subtotal,
          freight: freight
        };
        this.sellerGroups.push(sg);
        this.orderItems = this.orderItems.concat(items);
      });
    }
  }

  /** 加载可用优惠券 */
  private loadCoupons(): void {
    const total: number = this.sellerGroups.reduce((sum: number, g: SellerGroup) => sum + g.subtotal, 0);
    this.availableCoupons = MOCK_COUPONS.filter((c: Coupon) => {
      if (c.status !== 'unused') {
        return false;
      }
      if (c.type === 'full_cut' && c.threshold && total < c.threshold) {
        return false;
      }
      return true;
    });
  }

  /** 计算金额 */
  private calculateTotal(): void {
    this.totalAmount = this.sellerGroups.reduce((sum: number, g: SellerGroup) => sum + g.subtotal, 0);
    this.totalFreight = this.sellerGroups.reduce((sum: number, g: SellerGroup) => sum + g.freight, 0);
    this.discount = this.selectedCoupon ? (this.selectedCoupon.cutAmount ?? 0) : 0;
    this.payable = Math.max(0, this.totalAmount + this.totalFreight - this.discount);
    this.payable = Math.round(this.payable * 100) / 100;
  }

  /** 选择优惠券 */
  private onSelectCoupon(coupon: Coupon | null): void {
    this.selectedCoupon = coupon;
    this.calculateTotal();
  }

  /** 选择地址（Phase 2 跳转地址列表选择） */
  private gotoAddressList(): void {
    const param: AddressListNavParam = { from: 'order_confirm' };
    NavigationHelper.push(RouteName.USER_ADDRESS_LIST, param);
  }

  /** 提交订单 + Mock 支付 */
  private async onSubmitOrder(): Promise<void> {
    if (!this.address) {
      ToastUtil.warning('请选择收货地址');
      return;
    }
    this.isSubmitting = true;
    try {
      // 构造订单项
      const orderItemsParam: CreateOrderItem[] = this.orderItems.map((it: OrderItem): CreateOrderItem => {
        const item: CreateOrderItem = {
          productId: it.productId,
          skuId: it.skuId,
          quantity: it.quantity
        };
        return item;
      });
      // 创建订单
      const order: Order = createMockOrder(
        orderItemsParam,
        this.address.addressId,
        this.selectedCoupon?.couponId,
        this.remark.length > 0 ? this.remark : undefined
      );
      Logger.info(AppConstants.SCENE_USER, JSON.stringify({
        action: 'order_created',
        orderId: order.orderId,
        amount: order.totalAmount
      }));
      // Mock 支付（弹窗选择支付方式）
      this.showMockPayment(order.orderId);
    } catch (err) {
      Logger.error(AppConstants.SCENE_USER, {
        action: 'order_create_fail',
        error: (err as Error).message
      });
      ToastUtil.error('下单失败，请重试');
    } finally {
      this.isSubmitting = false;
    }
  }

  /** Mock 支付（简化：直接支付成功，跳转订单详情） */
  private showMockPayment(orderId: string): void {
    // Phase 2 简化：直接模拟支付成功，状态变更为"待发货"
    updateMockOrderStatus(orderId, 'pending_shipment');
    // 购物车模式：清空已选中商品
    if (!this.buyNow) {
      clearSelectedCartItems();
    }
    ToastUtil.success('支付成功');
    Logger.info(AppConstants.SCENE_USER, JSON.stringify({
      action: 'mock_payment_success',
      orderId: orderId
    }));
    // 跳转订单详情
    setTimeout(() => {
      const param: OrderDetailParam = { orderId: orderId };
      NavigationHelper.replace(RouteName.USER_ORDER_DETAIL, param);
    }, 800);
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
          Text('确认订单')
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

        // 内容区
        Scroll() {
          Column({ space: 12 }) {
            // 收货地址
            this.AddressCard()
            // 商品列表（按卖家分组）
            ForEach(this.sellerGroups, (group: SellerGroup, _i: number) => {
              this.SellerGroupCard(group)
            }, (group: SellerGroup) => group.farmerId)
            // 优惠券
            this.CouponCard()
            // 留言
            this.RemarkCard()
            // 金额明细
            this.AmountDetail()
          }
          .width('100%')
          .padding({ bottom: 80 })
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor($r('app.color.color_bg_page'))
        .scrollBar(BarState.Off)

        // 底部提交栏
        this.BottomSubmitBar()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 收货地址卡片 */
  @Builder
  AddressCard() {
    Row({ space: 12 }) {
      Text('📍').fontSize(24)
      if (this.address) {
        Column({ space: 4 }) {
          Row({ space: 8 }) {
            Text(this.address.receiverName).fontSize(14).fontColor($r('app.color.color_text_primary')).fontWeight(FontWeight.Medium)
            Text(this.address.phone).fontSize(13).fontColor($r('app.color.color_text_secondary'))
          }
          Text(`${this.address.province}${this.address.city}${this.address.district} ${this.address.detail}`)
            .fontSize(12).fontColor($r('app.color.color_text_secondary')).maxLines(2)
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
      } else {
        Text('请选择收货地址').fontSize(14).fontColor($r('app.color.color_text_hint')).layoutWeight(1)
      }
      Text('›').fontSize(20).fontColor($r('app.color.color_text_hint'))
    }
    .width('100%').padding(16).backgroundColor($r('app.color.color_bg_card')).borderRadius(12)
    .margin({ left: 12, right: 12, top: 12 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => { this.gotoAddressList(); })
  }

  /** 卖家分组卡片 */
  @Builder
  SellerGroupCard(group: SellerGroup) {
    Column({ space: 10 }) {
      // 卖家名
      Row({ space: 4 }) {
        Text('🏪').fontSize(13)
        Text(group.farmerName).fontSize(13).fontColor($r('app.color.color_text_primary')).fontWeight(FontWeight.Medium)
      }
      // 商品列表
      ForEach(group.items, (item: OrderItem, _j: number) => {
        Row({ space: 10 }) {
          Image(ImageUtil.get(item.image)).width(72).height(72).borderRadius(8).objectFit(ImageFit.Cover)
          Column({ space: 4 }) {
            Text(item.title).fontSize(12).fontColor($r('app.color.color_text_primary')).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.formatSpecs(item.specs)).fontSize(11).fontColor($r('app.color.color_text_secondary'))
            Row() {
              Text(`¥${item.price.toFixed(2)}`).fontSize(13).fontColor($r('app.color.color_price')).fontWeight(FontWeight.Bold)
              Blank()
              Text(`x${item.quantity}`).fontSize(12).fontColor($r('app.color.color_text_secondary'))
            }.width('100%')
          }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        }.width('100%')
      }, (item: OrderItem) => item.productId + (item.skuId ?? ''))
      // 运费
      Row() {
        Text('运费').fontSize(12).fontColor($r('app.color.color_text_secondary'))
        Blank()
        Text(group.freight === 0 ? '包邮' : `¥${group.freight.toFixed(2)}`).fontSize(12).fontColor($r('app.color.color_text_primary'))
      }.width('100%')
    }
    .width('100%').padding(16).backgroundColor($r('app.color.color_bg_card')).borderRadius(12).margin({ left: 12, right: 12 })
  }

  /** 优惠券卡片 */
  @Builder
  CouponCard() {
    Row() {
      Text('🎟️ 优惠券').fontSize(13).fontColor($r('app.color.color_text_primary'))
      Blank()
      if (this.selectedCoupon) {
        Text(`-${this.selectedCoupon.cutAmount ?? 0}元`).fontSize(13).fontColor($r('app.color.color_error'))
      } else if (this.availableCoupons.length > 0) {
        Text(`${this.availableCoupons.length}张可用`).fontSize(12).fontColor($r('app.color.color_secondary'))
      } else {
        Text('暂无可用').fontSize(12).fontColor($r('app.color.color_text_hint'))
      }
      Text(' ›').fontSize(14).fontColor($r('app.color.color_text_hint'))
    }
    .width('100%').height(48).padding({ left: 16, right: 16 }).backgroundColor($r('app.color.color_bg_card')).borderRadius(12).margin({ left: 12, right: 12 }).alignItems(VerticalAlign.Center)
    .onClick(() => {
      // 简化：循环切换优惠券
      if (this.availableCoupons.length === 0) {
        ToastUtil.show('暂无可用优惠券');
        return;
      }
      if (this.selectedCoupon) {
        const idx: number = this.availableCoupons.indexOf(this.selectedCoupon);
        this.onSelectCoupon(idx + 1 < this.availableCoupons.length ? this.availableCoupons[idx + 1] : null);
      } else {
        this.onSelectCoupon(this.availableCoupons[0]);
      }
    })
  }

  /** 留言卡片 */
  @Builder
  RemarkCard() {
    Column({ space: 8 }) {
      Text('订单留言').fontSize(13).fontColor($r('app.color.color_text_primary'))
      TextInput({ text: this.remark, placeholder: '选填，给卖家留言（50字内）' })
        .fontSize(13).maxLength(50).height(40).backgroundColor($r('app.color.color_bg_page')).borderRadius(8)
        .padding({ left: 12, right: 12 })
        .onChange((v: string) => { this.remark = v; })
    }
    .width('100%').padding(16).backgroundColor($r('app.color.color_bg_card')).borderRadius(12).margin({ left: 12, right: 12 }).alignItems(HorizontalAlign.Start)
  }

  /** 金额明细 */
  @Builder
  AmountDetail() {
    Column({ space: 8 }) {
      Row() {
        Text('商品金额').fontSize(13).fontColor($r('app.color.color_text_secondary'))
        Blank()
        Text(`¥${this.totalAmount.toFixed(2)}`).fontSize(13).fontColor($r('app.color.color_text_primary'))
      }.width('100%')
      Row() {
        Text('运费').fontSize(13).fontColor($r('app.color.color_text_secondary'))
        Blank()
        Text(`¥${this.totalFreight.toFixed(2)}`).fontSize(13).fontColor($r('app.color.color_text_primary'))
      }.width('100%')
      if (this.discount > 0) {
        Row() {
          Text('优惠').fontSize(13).fontColor($r('app.color.color_text_secondary'))
          Blank()
          Text(`-¥${this.discount.toFixed(2)}`).fontSize(13).fontColor($r('app.color.color_error'))
        }.width('100%')
      }
    }
    .width('100%').padding(16).backgroundColor($r('app.color.color_bg_card')).borderRadius(12).margin({ left: 12, right: 12 })
  }

  /** 底部提交栏 */
  @Builder
  BottomSubmitBar() {
    Row() {
      Column({ space: 2 }) {
        Row({ space: 2 }) {
          Text('应付：').fontSize(12).fontColor($r('app.color.color_text_secondary'))
          Text(`¥${this.payable.toFixed(2)}`).fontSize(18).fontColor($r('app.color.color_price')).fontWeight(FontWeight.Bold)
        }
      }.layoutWeight(1)
      Button('提交订单')
        .height(44).borderRadius(22).backgroundColor($r('app.color.color_secondary')).fontColor(Color.White).fontSize(15)
        .padding({ left: 32, right: 32 }).enabled(!this.isSubmitting)
        .onClick(() => { this.onSubmitOrder(); })
    }
    .width('100%').height(64).padding({ left: 16, right: 16 }).backgroundColor($r('app.color.color_bg_card')).border({ width: { top: 0.5 }, color: $r('app.color.color_divider') }).alignItems(VerticalAlign.Center)
  }

  /** 格式化规格 */
  private formatSpecs(specs?: OrderItemSpec[]): string {
    if (!specs || specs.length === 0) {
      return '';
    }
    return specs.map((s: OrderItemSpec) => s.value).join(' / ');
  }
}
