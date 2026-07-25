/**
 * payment - 收银台（支付页，对齐 payment.html 设计稿）
 *
 * - 顶栏：圆形返回键 + 居中"收银台"
 * - 黄色金额英雄卡：支付金额 + 订单号
 * - 收货地址卡：姓名 + 电话 + 地址
 * - 商品清单卡：缩略图 + 名称 + 规格 + 价格 + 数量
 * - 优惠与配送卡：优惠券 + 配送方式 + 积分抵扣(开关)
 * - 费用汇总卡：商品总额 + 优惠 + 积分 + 运费 + 实付
 * - 支付方式卡：微信支付(推荐) + 支付宝 + 银联云闪付 + 余额支付
 * - 底部固定支付栏：实付金额 + 确认支付按钮
 *
 * 路由参数：orderId + buyNow
 */

import { RouteName, NavigationHelper, Logger, AppConstants, ToastUtil } from 'common';
import { Order, OrderItem, OrderItemSpec, PaymentMethod } from '../../model/OrderModels';
import { Address } from '../../model/ProfileModels';
import { getMockOrderById, updateMockOrderStatus } from '../../mock/OrderMock';
import { getMockAddressById } from '../../mock/ProfileMock';
import { clearSelectedCartItems } from '../../mock/CartMock';
import { ImageUtil } from '../../utils/ImageUtil';

/** 路由参数：订单 ID + 是否立即购买（导航参数统一为 string） */
interface PaymentNavParam {
  orderId: string;
  buyNow: string;
}

/** 跳转订单详情的路由参数 */
interface OrderDetailParam {
  orderId: string;
}

/** 支付方式选项 */
interface PaymentOption {
  method: PaymentMethod;
  name: string;
  desc: string;
  icon: string;
  iconColor: string;
  recommended: boolean;
  disabled: boolean;
}

@ComponentV2
export struct Payment {
  /** 订单 ID */
  @Local orderId: string = '';
  /** 是否立即购买（非购物车结算） */
  @Local buyNow: boolean = false;
  /** 订单数据 */
  @Local order: Order | null = null;
  /** 收货地址 */
  @Local address: Address | null = null;
  /** 选中的支付方式 */
  @Local selectedMethod: PaymentMethod = 'wechat_mock';
  /** 积分抵扣开关 */
  @Local pointsEnabled: boolean = true;
  /** 是否正在支付 */
  @Local isPaying: boolean = false;
  /** 是否正在加载 */
  @Local isLoading: boolean = true;

  aboutToAppear(): void {
    const params = NavigationHelper.getParam<PaymentNavParam>();
    if (params && params.orderId) {
      this.orderId = params.orderId;
    }
    if (params && params.buyNow) {
      this.buyNow = params.buyNow === 'true';
    }
    this.loadOrder();
  }

  /** 加载订单数据 */
  private loadOrder(): void {
    this.isLoading = true;
    const order: Order | null = getMockOrderById(this.orderId);
    if (!order) {
      ToastUtil.error('订单不存在');
      NavigationHelper.pop();
      return;
    }
    this.order = order;
    // 获取收货地址（从第一个子订单的 addressId）
    if (order.subOrders.length > 0) {
      const addr: Address | null = getMockAddressById(order.subOrders[0].addressId);
      this.address = addr;
    }
    this.isLoading = false;
    Logger.info(AppConstants.SCENE_USER, JSON.stringify({
      action: 'payment_appear',
      orderId: this.orderId,
      amount: order.totalAmount
    }));
  }

  /** 确认支付 */
  private async onConfirmPayment(): Promise<void> {
    if (this.isPaying) {
      return;
    }
    this.isPaying = true;
    try {
      // Mock 支付：直接成功
      updateMockOrderStatus(this.orderId, 'pending_shipment');
      // 清除购物车已选商品（非立即购买场景）
      if (!this.buyNow) {
        clearSelectedCartItems();
      }
      ToastUtil.success('支付成功');
      Logger.info(AppConstants.SCENE_USER, JSON.stringify({
        action: 'payment_success',
        orderId: this.orderId,
        method: this.selectedMethod
      }));
      // 跳转订单详情
      setTimeout(() => {
        const param: OrderDetailParam = { orderId: this.orderId };
        NavigationHelper.replace(RouteName.USER_ORDER_DETAIL, param);
      }, 800);
    } catch (err) {
      Logger.error(AppConstants.SCENE_USER, {
        action: 'payment_fail',
        error: (err as Error).message
      });
      ToastUtil.error('支付失败，请重试');
    } finally {
      this.isPaying = false;
    }
  }

  /** 计算商品总额 */
  private get merchandiseTotal(): number {
    if (!this.order) {
      return 0;
    }
    let total: number = 0;
    this.order.subOrders.forEach((so) => {
      total += so.subtotal;
    });
    return total;
  }

  /** 计算运费 */
  private get freightTotal(): number {
    if (!this.order) {
      return 0;
    }
    let total: number = 0;
    this.order.subOrders.forEach((so) => {
      total += so.freight;
    });
    return total;
  }

  /** 积分抵扣金额 */
  private get pointsDiscount(): number {
    if (!this.pointsEnabled) {
      return 0;
    }
    return 2;
  }

  /** 优惠券抵扣 */
  private get couponDiscount(): number {
    return this.order?.couponDiscount ?? 0;
  }

  /** 实付金额 */
  private get payableAmount(): number {
    if (!this.order) {
      return 0;
    }
    return this.order.totalAmount - this.pointsDiscount;
  }

  /** 所有商品项（跨子订单合并） */
  private get allItems(): OrderItem[] {
    if (!this.order) {
      return [];
    }
    const items: OrderItem[] = [];
    this.order.subOrders.forEach((so) => {
      so.items.forEach((it) => {
        items.push(it);
      });
    });
    return items;
  }

  /** 商品总件数 */
  private get itemCount(): number {
    return this.allItems.reduce((sum: number, it: OrderItem) => sum + it.quantity, 0);
  }

  /** 格式化规格 */
  private formatSpecs(specs?: OrderItemSpec[]): string {
    if (!specs || specs.length === 0) {
      return '';
    }
    return '规格 · ' + specs.map((s) => s.value).join(' / ');
  }

  /** 格式化价格 */
  private formatPrice(price: number): string {
    return price.toFixed(2);
  }

  /** 格式化手机号（脱敏） */
  private maskPhone(phone: string): string {
    if (phone.length < 7) {
      return phone;
    }
    return phone.substring(0, 3) + '****' + phone.substring(phone.length - 4);
  }

  /** 支付方式列表 */
  private get paymentOptions(): PaymentOption[] {
    const options: PaymentOption[] = [
      {
        method: 'wechat_mock',
        name: '微信支付',
        desc: '亿万用户都在用，安全便捷',
        icon: '💬',
        iconColor: '#07C160',
        recommended: true,
        disabled: false
      },
      {
        method: 'alipay_mock',
        name: '支付宝',
        desc: '花呗 / 余额宝均可支付',
        icon: '¥',
        iconColor: '#1677FF',
        recommended: false,
        disabled: false
      },
      {
        method: 'unionpay_mock',
        name: '银联云闪付',
        desc: '支持各大银行储蓄 / 信用卡',
        icon: '⟁',
        iconColor: '#E60012',
        recommended: false,
        disabled: false
      },
      {
        method: 'balance_mock',
        name: '余额支付',
        desc: '可用 ¥0.00，余额不足',
        icon: '◉',
        iconColor: '#999999',
        recommended: false,
        disabled: true
      }
    ];
    return options;
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        if (this.isLoading || !this.order) {
          Column({ space: 12 }) {
            LoadingProgress()
              .width(40)
              .height(40)
              .color($r('app.color.color_primary'))
            Text('加载中...')
              .fontSize(13)
              .fontColor($r('app.color.color_text_3'))
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          Scroll() {
            Column({ space: 12 }) {
              this.AmountHeroCard()
              if (this.address) {
                this.AddressCard()
              }
              this.GoodsListCard()
              this.PromotionsCard()
              this.CostSummaryCard()
              this.PaymentMethodCard()
              // 底部留白
              Column().height(88)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 16 })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)

          // 底部固定支付栏
          this.PayBar()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_cream'))
    }
    .hideTitleBar(true)
  }

  /** 顶部导航：圆形返回键 + 居中"收银台" */
  @Builder
  TopBar() {
    Row() {
      Stack() {
        Text('‹')
          .fontSize(22)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .width(32)
      .height(32)
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor($r('app.color.color_bg_card'))
      .shadow(AppConstants.SHADOW_CARD)
      .onClick(() => NavigationHelper.pop())

      Text('收银台')
        .fontSize(17)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 占位
      Column().width(32).height(32)
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16, top: 4, bottom: 10 })
    .alignItems(VerticalAlign.Center)
  }

  /** 黄色金额英雄卡 */
  @Builder
  AmountHeroCard() {
    Column({ space: 6 }) {
      Text('支付金额')
        .fontSize(13)
        .fontColor($r('app.color.color_ink_2'))
      Row({ space: 2 }) {
        Text('¥')
          .fontSize(16)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        Text(this.formatPrice(this.payableAmount))
          .fontSize(36)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .alignItems(VerticalAlign.Bottom)

      Row({ space: 6 }) {
        Text(`订单号 ${this.orderId}`)
          .fontSize(11)
          .fontColor($r('app.color.color_text_3'))
        Text('⧉')
          .fontSize(13)
          .fontColor($r('app.color.color_text_3'))
          .onClick(() => {
            ToastUtil.success('已复制');
          })
      }
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 20, bottom: 20 })
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_primary'))
    .alignItems(HorizontalAlign.Start)
  }

  /** 收货地址卡 */
  @Builder
  AddressCard() {
    Row({ space: 12 }) {
      // 黄色圆形定位图标
      Stack() {
        Text('◎')
          .fontSize(19)
          .fontColor($r('app.color.color_primary'))
          .fontWeight(FontWeight.Bold)
      }
      .width(36)
      .height(36)
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor($r('app.color.color_yellow_tint'))
      .alignContent(Alignment.Center)

      Column({ space: 4 }) {
        Row({ space: 6 }) {
          Text(this.address!.receiverName)
            .fontSize(14)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
          Text(this.maskPhone(this.address!.phone))
            .fontSize(13)
            .fontColor($r('app.color.color_text_2'))
          if (this.address!.isDefault) {
            Text('默认')
              .fontSize(10)
              .fontColor($r('app.color.color_ink'))
              .backgroundColor($r('app.color.color_primary'))
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(AppConstants.RADIUS_XS)
              .fontWeight(FontWeight.Bold)
          }
        }
        .alignItems(VerticalAlign.Center)

        Text(`${this.address!.province}${this.address!.city}${this.address!.district}${this.address!.detail}`)
          .fontSize(12)
          .fontColor($r('app.color.color_text_2'))
          .maxLines(2)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(VerticalAlign.Center)
  }

  /** 商品清单卡 */
  @Builder
  GoodsListCard() {
    Column({ space: 12 }) {
      Row() {
        Text('商品明细')
          .fontSize(15)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text(`共${this.itemCount}件`)
          .fontSize(12)
          .fontColor($r('app.color.color_text_3'))
      }
      .width('100%')

      ForEach(this.allItems, (item: OrderItem) => {
        this.GoodsItemRow(item)
      }, (item: OrderItem) => `${item.productId}_${item.skuId ?? ''}_${item.quantity}`)
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 商品行 */
  @Builder
  GoodsItemRow(item: OrderItem) {
    Row({ space: 10 }) {
      // 缩略图
      Image(ImageUtil.get(item.image))
        .width(56)
        .height(56)
        .borderRadius(AppConstants.RADIUS_SM)
        .objectFit(ImageFit.Cover)

      Column({ space: 4 }) {
        Text(item.title)
          .fontSize(13)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (item.specs && item.specs.length > 0) {
          Text(this.formatSpecs(item.specs))
            .fontSize(11)
            .fontColor($r('app.color.color_text_3'))
            .maxLines(1)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Column({ space: 2 }) {
        Row({ space: 1 }) {
          Text('¥')
            .fontSize(11)
            .fontColor($r('app.color.color_ink'))
          Text(this.formatPrice(item.price))
            .fontSize(14)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
        }
        .alignItems(VerticalAlign.Bottom)
        Text(`×${item.quantity}`)
          .fontSize(11)
          .fontColor($r('app.color.color_text_3'))
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  /** 优惠与配送卡 */
  @Builder
  PromotionsCard() {
    Column({ space: 0 }) {
      // 优惠券
      Row({ space: 10 }) {
        Stack() {
          Text('🎟')
            .fontSize(16)
        }
        .width(28)
        .height(28)
        .borderRadius(AppConstants.RADIUS_XS)
        .backgroundColor($r('app.color.color_yellow_tint'))
        .alignContent(Alignment.Center)

        Column() {
          Text('优惠券')
            .fontSize(14)
            .fontColor($r('app.color.color_ink'))
          if (this.couponDiscount > 0) {
            Text(`满${this.merchandiseTotal.toFixed(0)}减${this.couponDiscount}`)
              .fontSize(11)
              .fontColor($r('app.color.color_text_3'))
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        if (this.couponDiscount > 0) {
          Text(`-¥${this.formatPrice(this.couponDiscount)}`)
            .fontSize(13)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
        }
        Text('›')
          .fontSize(16)
          .fontColor($r('app.color.color_text_4'))
      }
      .width('100%')
      .padding({ top: 12, bottom: 12 })
      .alignItems(VerticalAlign.Center)

      Divider().color($r('app.color.color_line')).strokeWidth(1)

      // 配送方式
      Row({ space: 10 }) {
        Stack() {
          Text('🚚')
            .fontSize(16)
        }
        .width(28)
        .height(28)
        .borderRadius(AppConstants.RADIUS_XS)
        .backgroundColor($r('app.color.color_green_soft'))
        .alignContent(Alignment.Center)

        Column() {
          Text('配送方式')
            .fontSize(14)
            .fontColor($r('app.color.color_ink'))
          Text('顺丰冷链')
            .fontSize(11)
            .fontColor($r('app.color.color_text_3'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.freightTotal === 0 ? '免运费' : `¥${this.formatPrice(this.freightTotal)}`)
          .fontSize(13)
          .fontColor($r('app.color.color_text_2'))
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .padding({ top: 12, bottom: 12 })
      .alignItems(VerticalAlign.Center)

      Divider().color($r('app.color.color_line')).strokeWidth(1)

      // 积分抵扣
      Row({ space: 10 }) {
        Stack() {
          Text('✦')
            .fontSize(16)
        }
        .width(28)
        .height(28)
        .borderRadius(AppConstants.RADIUS_XS)
        .backgroundColor($r('app.color.color_yellow_tint'))
        .alignContent(Alignment.Center)

        Column() {
          Text('积分抵扣')
            .fontSize(14)
            .fontColor($r('app.color.color_ink'))
          Text('可用200积分')
            .fontSize(11)
            .fontColor($r('app.color.color_text_3'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        if (this.pointsEnabled) {
          Text(`-¥${this.formatPrice(this.pointsDiscount)}`)
            .fontSize(13)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
        }

        // Toggle 开关
        Stack() {
          Row() {
            Column()
              .width(20)
              .height(20)
              .borderRadius(AppConstants.RADIUS_PILL)
              .backgroundColor(Color.White)
          }
          .width('100%')
          .height('100%')
          .justifyContent(this.pointsEnabled ? FlexAlign.End : FlexAlign.Start)
          .padding({ left: 2, right: 2 })
          .alignItems(VerticalAlign.Center)
        }
        .width(44)
        .height(24)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor(this.pointsEnabled ? $r('app.color.color_green') : $r('app.color.color_text_4'))
        .onClick(() => { this.pointsEnabled = !this.pointsEnabled; })
      }
      .width('100%')
      .padding({ top: 12, bottom: 12 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 费用汇总卡 */
  @Builder
  CostSummaryCard() {
    Column({ space: 8 }) {
      this.SummaryRow('商品总额', `¥${this.formatPrice(this.merchandiseTotal)}`, false)
      if (this.couponDiscount > 0) {
        this.SummaryRow('优惠券', `-¥${this.formatPrice(this.couponDiscount)}`, true)
      }
      if (this.pointsEnabled && this.pointsDiscount > 0) {
        this.SummaryRow('积分抵扣', `-¥${this.formatPrice(this.pointsDiscount)}`, true)
      }
      this.SummaryRow('运费', this.freightTotal === 0 ? '¥0.00' : `¥${this.formatPrice(this.freightTotal)}`, false)

      Divider().color($r('app.color.color_line')).strokeWidth(1).margin({ top: 4 })

      Row() {
        Text('实付')
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Medium)
        Blank()
        Row({ space: 1 }) {
          Text('¥')
            .fontSize(14)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
          Text(this.formatPrice(this.payableAmount))
            .fontSize(22)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
        }
        .alignItems(VerticalAlign.Bottom)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 汇总行 */
  @Builder
  SummaryRow(label: string, value: string, isDiscount: boolean) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor($r('app.color.color_text_2'))
      Blank()
      Text(value)
        .fontSize(13)
        .fontColor(isDiscount ? $r('app.color.color_live') : $r('app.color.color_ink_2'))
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  /** 支付方式卡 */
  @Builder
  PaymentMethodCard() {
    Column({ space: 0 }) {
      Text('支付方式')
        .fontSize(15)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 6 })

      ForEach(this.paymentOptions, (opt: PaymentOption) => {
        this.PaymentItemRow(opt)
      }, (opt: PaymentOption) => opt.method)
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 支付方式行 */
  @Builder
  PaymentItemRow(opt: PaymentOption) {
    Row({ space: 12 }) {
      // 图标
      Stack() {
        Text(opt.icon)
          .fontSize(20)
          .fontColor(opt.iconColor)
      }
      .width(36)
      .height(36)
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor($r('app.color.color_fill'))
      .alignContent(Alignment.Center)

      Column({ space: 2 }) {
        Row({ space: 6 }) {
          Text(opt.name)
            .fontSize(14)
            .fontColor(opt.disabled ? $r('app.color.color_text_3') : $r('app.color.color_ink'))
            .fontWeight(FontWeight.Medium)
          if (opt.recommended) {
            Text('推荐')
              .fontSize(10)
              .fontColor($r('app.color.color_green_deep'))
              .backgroundColor($r('app.color.color_green_soft'))
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(AppConstants.RADIUS_XS)
              .fontWeight(FontWeight.Bold)
          }
        }
        .alignItems(VerticalAlign.Center)
        Text(opt.desc)
          .fontSize(11)
          .fontColor($r('app.color.color_text_3'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 单选圆圈
      Stack() {
        if (this.selectedMethod === opt.method && !opt.disabled) {
          Column()
            .width(18)
            .height(18)
            .borderRadius(AppConstants.RADIUS_PILL)
            .backgroundColor($r('app.color.color_green'))
        }
      }
      .width(24)
      .height(24)
      .borderRadius(AppConstants.RADIUS_PILL)
      .border({
        width: this.selectedMethod === opt.method && !opt.disabled ? 0 : 2,
        color: $r('app.color.color_text_4')
      })
      .alignContent(Alignment.Center)
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .alignItems(VerticalAlign.Center)
    .opacity(opt.disabled ? 0.4 : 1)
    .onClick(() => {
      if (!opt.disabled) {
        this.selectedMethod = opt.method;
      }
    })
  }

  /** 底部固定支付栏 */
  @Builder
  PayBar() {
    Row({ space: 16 }) {
      Column({ space: 0 }) {
        Text('实付')
          .fontSize(11)
          .fontColor($r('app.color.color_text_3'))
        Row({ space: 1 }) {
          Text('¥')
            .fontSize(14)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
          Text(this.formatPrice(this.payableAmount))
            .fontSize(22)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
        }
        .alignItems(VerticalAlign.Bottom)
      }
      .alignItems(HorizontalAlign.Start)

      Blank()

      // 确认支付按钮
      Row({ space: 6 }) {
        Text(this.isPaying ? '支付中...' : '确认支付')
          .fontSize(15)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
        if (!this.isPaying) {
          Text('→')
            .fontSize(16)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
        }
      }
      .height(46)
      .padding({ left: 28, right: 28 })
      .borderRadius(AppConstants.RADIUS_MD)
      .backgroundColor(this.isPaying ? $r('app.color.color_text_4') : $r('app.color.color_ink'))
      .alignItems(VerticalAlign.Center)
      .opacity(this.isPaying ? 0.6 : 1)
      .onClick(() => { if (!this.isPaying) this.onConfirmPayment(); })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.color_cream'))
    .alignItems(VerticalAlign.Center)
  }
}
