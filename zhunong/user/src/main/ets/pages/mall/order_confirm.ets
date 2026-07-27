/**
 * order_confirm - 确认订单页
 * 遵循 spec 3.1.4.1 + UI 复刻 order-confirm.html：
 *  - 收货地址卡（白底 + 黄色圆形定位图标）
 *  - 卖家分组卡（店铺头 + V 认证标 + 商品行 + 运费行）
 *  - 优惠券单行卡（绿值 + 箭头）
 *  - 支付方式卡（微信/支付宝/余额 + 单选）
 *  - 备注单行卡（行内输入）
 *  - 金额汇总卡（商品金额/运费/优惠 + 合计）
 *  - 底部固定提交栏（合计 + 提交订单墨黑按钮）
 *  - 提交订单 → Mock 支付 → 订单状态变为"待发货"
 *  - 支持两种入口：购物车结算（多商品）/ 立即购买（单品）
 */

import { RouteName, NavigationHelper, Logger, AppConstants, ToastUtil } from 'common';
import { Order, OrderItem, OrderItemSpec } from '../../model/OrderModels';
import { createMockOrder, CreateOrderItem } from '../../mock/OrderMock';
import { getMockCartGroups } from '../../mock/CartMock';
import { getMockDefaultAddress, MOCK_COUPONS } from '../../mock/ProfileMock';
import { Address, Coupon } from '../../model/ProfileModels';
import { MOCK_FARMER_NAMES } from '../../mock/ProductMock';
import { ProductRepository } from '../../repository/ProductRepository';
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

/** 跳转收银台（支付页）的路由参数 */
interface PaymentNavParam {
  orderId: string;
  buyNow: string;
}

/** 进入确认订单页的路由参数（立即购买 / 购物车结算） */
interface OrderConfirmNavParam {
  buyNow?: string;
  productId?: string;
  skuId?: string;
  quantity?: string;
}

/** 支付方式枚举 */
type PayMethod = 'wechat' | 'alipay' | 'balance';

/** 支付方式选项 */
interface PayMethodOption {
  method: PayMethod;
  name: string;
  desc?: string;
  iconBg: ResourceColor;
  iconText: string;
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
  /** 选中的支付方式 */
  @Local payMethod: PayMethod = 'wechat';
  /** 支付方式选项列表 */
  @Local payOptions: PayMethodOption[] = [
    { method: 'wechat', name: '微信支付', desc: '推荐使用', iconBg: $r('app.color.color_green'), iconText: '微' },
    { method: 'alipay', name: '支付宝', iconBg: $r('app.color.color_info'), iconText: '付' },
    { method: 'balance', name: '余额支付', desc: '可用余额 ¥0.00', iconBg: $r('app.color.color_ink'), iconText: '余' }
  ];

  async aboutToAppear(): Promise<void> {
    const params = NavigationHelper.getParam<OrderConfirmNavParam>();
    if (params) {
      this.buyNow = params.buyNow === '1';
      this.buyProductId = params.productId ?? '';
      this.buySkuId = params.skuId ?? '';
      this.buyQuantity = parseInt(params.quantity ?? '1', 10);
    }
    this.address = getMockDefaultAddress();
    await this.loadOrderItems();
    this.loadCoupons();
    this.calculateTotal();
  }

  /** 加载订单商品项（购物车模式 / 立即购买模式） */
  private async loadOrderItems(): Promise<void> {
    this.sellerGroups = [];
    if (this.buyNow) {
      // 立即购买：单品（spec 16.3：先查共享池，再回退 mock）
      const product = await ProductRepository.getProductById(this.buyProductId);
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
      // 跳转收银台（支付页）
      this.gotoPayment(order.orderId);
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

  /** 跳转收银台（支付页） */
  private gotoPayment(orderId: string): void {
    const param: PaymentNavParam = {
      orderId: orderId,
      buyNow: this.buyNow ? 'true' : 'false'
    };
    NavigationHelper.push(RouteName.USER_PAYMENT, param);
  }

  /** 格式化规格 */
  private formatSpecs(specs?: OrderItemSpec[]): string {
    if (!specs || specs.length === 0) {
      return '';
    }
    return specs.map((s: OrderItemSpec) => s.value).join(' / ');
  }

  /** 格式化价格整数部分 */
  private formatPriceInt(price: number): string {
    return price.toFixed(2);
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部栏（对齐设计稿 qn-topbar）
        Row() {
          Text('‹')
            .fontSize(28)
            .fontColor($r('app.color.color_ink'))
            .width(32)
            .height(32)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              NavigationHelper.pop();
            })
          Text('确认订单')
            .fontSize(17)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          Text('')
            .width(32)
            .height(32)
        }
        .width('100%')
        .height(48)
        .padding({ left: 16, right: 16 })
        .backgroundColor($r('app.color.color_bg_card'))
        .alignItems(VerticalAlign.Center)

        // 内容区
        Scroll() {
          Column({ space: 12 }) {
            // 收货地址卡
            this.AddressCard()
            // 商品清单（按卖家分组）
            ForEach(this.sellerGroups, (group: SellerGroup, _i: number) => {
              this.SellerGroupCard(group)
            }, (group: SellerGroup) => group.farmerId)
            // 优惠券单行卡
            this.CouponCard()
            // 支付方式卡
            this.PaymentCard()
            // 备注单行卡
            this.RemarkCard()
            // 金额汇总卡
            this.AmountDetail()
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 100 })
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor($r('app.color.color_bg_page'))
        .scrollBar(BarState.Off)

        // 底部固定提交栏
        this.BottomSubmitBar()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 收货地址卡片（对齐设计稿 qn-card + qn-addr-card） */
  @Builder
  AddressCard() {
    Row({ space: 12 }) {
      // 黄色圆形定位图标（40×40 圆）
      Text('📍')
        .fontSize(20)
        .width(40)
        .height(40)
        .textAlign(TextAlign.Center)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor($r('app.color.color_primary'))

      // 地址信息
      if (this.address) {
        Column({ space: 4 }) {
          // 收货人 + 电话（15px 800 + 13px 600）
          Row({ space: 10 }) {
            Text(this.address.receiverName)
              .fontSize(15)
              .fontColor($r('app.color.color_ink'))
              .fontWeight(FontWeight.Bold)
            Text(this.address.phone)
              .fontSize(13)
              .fontColor($r('app.color.color_text_2'))
              .fontWeight(FontWeight.Medium)
          }
          .alignItems(VerticalAlign.Bottom)

          // 地址详文（13px text_2）
          Text(`${this.address.province}${this.address.city}${this.address.district} ${this.address.detail}`)
            .fontSize(13)
            .fontColor($r('app.color.color_text_2'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      } else {
        Text('请选择收货地址')
          .fontSize(15)
          .fontColor($r('app.color.color_text_3'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
      }

      // 右箭头
      Text('›')
        .fontSize(20)
        .fontColor($r('app.color.color_text_3'))
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(VerticalAlign.Center)
    .onClick(() => { this.gotoAddressList(); })
  }

  /** 卖家分组卡片（对齐设计稿 qn-card + qn-confirm-shop） */
  @Builder
  SellerGroupCard(group: SellerGroup) {
    Column({ space: 0 }) {
      // 店铺行（对齐设计稿 qn-confirm-shop-head）
      Row({ space: 10 }) {
        // 店铺头像（28×28 圆 + 首字母）
        Text(group.farmerName.charAt(0))
          .fontSize(13)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .width(28)
          .height(28)
          .textAlign(TextAlign.Center)
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_fill'))

        // 店铺名 + V 认证标
        Row({ space: 4 }) {
          Text(group.farmerName)
            .fontSize(15)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
          // V 认证标（15×15 圆 info 色 + 白色 ✓）
          Text('✓')
            .fontSize(9)
            .fontColor(Color.White)
            .width(15)
            .height(15)
            .textAlign(TextAlign.Center)
            .borderRadius(AppConstants.RADIUS_PILL)
            .backgroundColor($r('app.color.color_info'))
        }
        .alignItems(VerticalAlign.Center)
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ bottom: 4 })
      .alignItems(VerticalAlign.Center)

      // 商品列表
      ForEach(group.items, (item: OrderItem, _j: number) => {
        Row({ space: 12 }) {
          // 商品主图（80×80 RADIUS_MD）
          Image(ImageUtil.get(item.image))
            .width(80)
            .height(80)
            .borderRadius(AppConstants.RADIUS_MD)
            .objectFit(ImageFit.Cover)
            .backgroundColor($r('app.color.color_fill'))

          // 商品信息
          Column({ space: 0 }) {
            // 商品名（14px 700）
            Text(item.title)
              .fontSize(14)
              .fontColor($r('app.color.color_ink'))
              .fontWeight(FontWeight.Bold)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .lineHeight(19)

            // 规格标签（11px text_3 + 灰底）
            Text(this.formatSpecs(item.specs))
              .fontSize(11)
              .fontColor($r('app.color.color_text_3'))
              .backgroundColor($r('app.color.color_fill'))
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .borderRadius(AppConstants.RADIUS_XS)
              .margin({ top: 6 })

            // 底部行：价格 + 数量
            Row() {
              // 价格（¥12px + 数字20px 红 800）
              Row({ space: 1 }) {
                Text('¥')
                  .fontSize(12)
                  .fontColor($r('app.color.color_live'))
                  .fontWeight(FontWeight.Bold)
                Text(this.formatPriceInt(item.price))
                  .fontSize(20)
                  .fontColor($r('app.color.color_live'))
                  .fontWeight(FontWeight.Bold)
              }
              .alignItems(VerticalAlign.Bottom)

              Blank()

              // 数量（13px 600 text_3）
              Text(`x${item.quantity}`)
                .fontSize(13)
                .fontColor($r('app.color.color_text_3'))
                .fontWeight(FontWeight.Medium)
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
        .border({ width: { top: 1 }, color: { top: $r('app.color.color_line') } })
      }, (item: OrderItem) => item.productId + (item.skuId ?? ''))

      // 运费行
      Row() {
        Text('运费')
          .fontSize(13)
          .fontColor($r('app.color.color_text_2'))
        Blank()
        Text(group.freight === 0 ? '包邮' : `¥${group.freight.toFixed(2)}`)
          .fontSize(13)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .padding({ top: 12 })
      .border({ width: { top: 1 }, color: { top: $r('app.color.color_line') } })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 优惠券单行卡（对齐设计稿 qn-card + qn-row） */
  @Builder
  CouponCard() {
    Row({ space: 10 }) {
      Text('优惠券')
        .fontSize(14)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)

      Blank()

      if (this.selectedCoupon) {
        Text(`-${this.selectedCoupon.cutAmount ?? 0}元`)
          .fontSize(13)
          .fontColor($r('app.color.color_green_deep'))
          .fontWeight(FontWeight.Bold)
      } else if (this.availableCoupons.length > 0) {
        Text(`${this.availableCoupons.length}张可用`)
          .fontSize(13)
          .fontColor($r('app.color.color_green_deep'))
          .fontWeight(FontWeight.Bold)
      } else {
        Text('暂无可用')
          .fontSize(13)
          .fontColor($r('app.color.color_text_3'))
      }

      Text('›')
        .fontSize(18)
        .fontColor($r('app.color.color_text_3'))
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
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

  /** 支付方式卡（对齐设计稿 qn-card + qn-pay） */
  @Builder
  PaymentCard() {
    Column({ space: 0 }) {
      ForEach(this.payOptions, (opt: PayMethodOption, idx: number) => {
        Row({ space: 10 }) {
          // 圆形图标（28×28 + 首字汉字）
          Text(opt.iconText)
            .fontSize(13)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .width(28)
            .height(28)
            .textAlign(TextAlign.Center)
            .borderRadius(AppConstants.RADIUS_PILL)
            .backgroundColor(opt.iconBg)

          // 名称 + 描述
          Column({ space: 2 }) {
            Text(opt.name)
              .fontSize(14)
              .fontColor($r('app.color.color_ink'))
              .fontWeight(FontWeight.Medium)
            if (opt.desc) {
              Text(opt.desc)
                .fontSize(11)
                .fontColor($r('app.color.color_text_3'))
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // 单选圆
          Text(this.payMethod === opt.method ? '✓' : '')
            .fontSize(11)
            .fontColor(Color.White)
            .width(20)
            .height(20)
            .textAlign(TextAlign.Center)
            .borderRadius(AppConstants.RADIUS_PILL)
            .backgroundColor(this.payMethod === opt.method ? $r('app.color.color_green') : Color.Transparent)
            .border({ width: 1.5, color: this.payMethod === opt.method ? $r('app.color.color_green') : $r('app.color.color_text_4') })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .alignItems(VerticalAlign.Center)
        .border(idx > 0 ? { width: { top: 1 }, color: { top: $r('app.color.color_line') } } : {})
        .onClick(() => { this.payMethod = opt.method; })
      }, (opt: PayMethodOption) => opt.method)
    }
    .width('100%')
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 备注单行卡（对齐设计稿 qn-card + qn-remark） */
  @Builder
  RemarkCard() {
    Row({ space: 10 }) {
      Text('订单备注')
        .fontSize(14)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)

      TextInput({ text: this.remark, placeholder: '选填，请输入备注信息' })
        .fontSize(13)
        .fontColor($r('app.color.color_ink'))
        .placeholderFont({ size: 13 })
        .placeholderColor($r('app.color.color_text_4'))
        .maxLength(50)
        .backgroundColor(Color.Transparent)
        .layoutWeight(1)
        .onChange((v: string) => { this.remark = v; })
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(VerticalAlign.Center)
  }

  /** 金额汇总卡（对齐设计稿 qn-card + qn-sum-card） */
  @Builder
  AmountDetail() {
    Column({ space: 0 }) {
      // 商品金额
      Row() {
        Text('商品金额')
          .fontSize(13)
          .fontColor($r('app.color.color_text_2'))
        Blank()
        Text(`¥${this.totalAmount.toFixed(2)}`)
          .fontSize(13)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .padding({ top: 6, bottom: 6 })

      // 运费
      Row() {
        Text('运费')
          .fontSize(13)
          .fontColor($r('app.color.color_text_2'))
        Blank()
        Text(`¥${this.totalFreight.toFixed(2)}`)
          .fontSize(13)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .padding({ top: 6, bottom: 6 })

      // 优惠券
      if (this.discount > 0) {
        Row() {
          Text('优惠券')
            .fontSize(13)
            .fontColor($r('app.color.color_text_2'))
          Blank()
          Text(`-¥${this.discount.toFixed(2)}`)
            .fontSize(13)
            .fontColor($r('app.color.color_green_deep'))
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .padding({ top: 6, bottom: 6 })
      }

      // 合计行
      Row() {
        Text('合计')
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        Blank()
        Row({ space: 1 }) {
          Text('¥')
            .fontSize(14)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
          Text(this.formatPriceInt(this.payable))
            .fontSize(24)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
        }
        .alignItems(VerticalAlign.Bottom)
      }
      .width('100%')
      .padding({ top: 12 })
      .margin({ top: 6 })
      .border({ width: { top: 1 }, color: { top: $r('app.color.color_line') } })
      .alignItems(VerticalAlign.Bottom)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 底部固定提交栏（对齐设计稿 qn-submit-bar） */
  @Builder
  BottomSubmitBar() {
    Row({ space: 12 }) {
      // 合计金额
      Column({ space: 0 }) {
        Text('合计')
          .fontSize(12)
          .fontColor($r('app.color.color_text_3'))
          .fontWeight(FontWeight.Medium)
        Row({ space: 1 }) {
          Text('¥')
            .fontSize(13)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
          Text(this.formatPriceInt(this.payable))
            .fontSize(22)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
        }
        .alignItems(VerticalAlign.Bottom)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 提交订单按钮（墨黑底）
      Text('提交订单')
        .fontSize(15)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .height(46)
        .padding({ left: 30, right: 30 })
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor(this.isSubmitting ? $r('app.color.color_text_4') : $r('app.color.color_cta_black'))
        .textAlign(TextAlign.Center)
        .onClick(() => { this.onSubmitOrder(); })
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_NAV)
    .alignItems(VerticalAlign.Center)
  }
}
