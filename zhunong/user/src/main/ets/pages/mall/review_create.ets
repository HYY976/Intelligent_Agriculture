/**
 * review_create - 评价提交页
 * 遵循 spec 3.1.4.1 + UI 复刻 review-create.html：
 *  - 顶部栏：返回（白圆）+ 居中标题 + "发布"黄色文字按钮
 *  - 商品信息卡（64×64 缩略图 + 标题 + 规格 + 价格）
 *  - 整体评分卡（5 大星 + 评分文案 + 3 子维度小星：物流/质量/服务）
 *  - 评价内容卡（多行输入 + 字数计数 0/500）
 *  - 图片上传卡（3 列 80×80 网格 + 虚线添加框 + 最多9张）
 *  - 匿名评价卡（Toggle 开关）
 */

import { RouteName, NavigationHelper, Logger, AppConstants, ToastUtil } from 'common';
import { getMockOrderById } from '../../mock/OrderMock';
import { Order, OrderItem, SubOrder, OrderItemSpec } from '../../model/OrderModels';
import { ImageUtil } from '../../utils/ImageUtil';
import { StarRating } from '../../components/StarRating';

/** 子维度评分项配置 */
interface SubRateItem {
  key: string;
  label: string;
}

@ComponentV2
export struct ReviewCreate {
  @Local orderId: string = '';
  @Local order: Order | null = null;
  @Local items: OrderItem[] = [];
  /** 整体评分 */
  @Local rating: number = 5;
  /** 子维度评分（物流速度/商品质量/服务态度） */
  @Local logisticsRating: number = 5;
  @Local qualityRating: number = 5;
  @Local serviceRating: number = 5;
  @Local content: string = '';
  @Local selectedImages: string[] = [];
  @Local isSubmitting: boolean = false;
  /** 匿名评价 */
  @Local anonymous: boolean = true;
  /** 图片最大数（对齐设计稿"最多9张"） */
  private readonly IMAGE_MAX: number = 9;
  /** 内容最大字数 */
  private readonly CONTENT_MAX: number = 500;
  /** 可选评价图片池 */
  private imagePool: string[] = ['prod_vegetable_1', 'prod_vegetable_2', 'prod_fruit_1', 'prod_rice_1', 'prod_tea_1', 'prod_honey_1', 'prod_nut_1', 'prod_chili_1', 'prod_eggs_1'];
  /** 子维度配置 */
  private subRates: SubRateItem[] = [
    { key: 'logistics', label: '物流速度' },
    { key: 'quality', label: '商品质量' },
    { key: 'service', label: '服务态度' }
  ];

  aboutToAppear(): void {
    const params: Record<string, string> = NavigationHelper.getParam<Record<string, string>>() as Record<string, string>;
    if (params) {
      this.orderId = params.orderId ?? '';
    }
    this.order = getMockOrderById(this.orderId);
    if (this.order) {
      this.order.subOrders.forEach((so: SubOrder) => {
        so.items.forEach((it: OrderItem) => {
          this.items.push(it);
        });
      });
    }
  }

  /** 提交评价 */
  private onSubmit(): void {
    if (this.content.trim().length === 0) {
      ToastUtil.warning('请填写评价内容');
      return;
    }
    this.isSubmitting = true;
    Logger.info(AppConstants.SCENE_USER, JSON.stringify({
      action: 'review_submit',
      orderId: this.orderId,
      rating: this.rating,
      logisticsRating: this.logisticsRating,
      qualityRating: this.qualityRating,
      serviceRating: this.serviceRating,
      imageCount: this.selectedImages.length,
      anonymous: this.anonymous
    }));
    setTimeout(() => {
      this.isSubmitting = false;
      ToastUtil.success('评价提交成功');
      NavigationHelper.pop();
    }, 600);
  }

  /** 切换图片选中 */
  private toggleImage(imgKey: string): void {
    const idx: number = this.selectedImages.indexOf(imgKey);
    if (idx >= 0) {
      this.selectedImages.splice(idx, 1);
    } else {
      if (this.selectedImages.length >= this.IMAGE_MAX) {
        ToastUtil.warning(`最多上传${this.IMAGE_MAX}张图片`);
        return;
      }
      this.selectedImages.push(imgKey);
    }
  }

  /** 切换匿名 */
  private toggleAnonymous(): void {
    this.anonymous = !this.anonymous;
  }

  /** 获取子维度评分 */
  private getSubRating(key: string): number {
    if (key === 'logistics') {
      return this.logisticsRating;
    }
    if (key === 'quality') {
      return this.qualityRating;
    }
    return this.serviceRating;
  }

  /** 设置子维度评分 */
  private setSubRating(key: string, value: number): void {
    if (key === 'logistics') {
      this.logisticsRating = value;
    } else if (key === 'quality') {
      this.qualityRating = value;
    } else {
      this.serviceRating = value;
    }
  }

  /** 整体评分文案 */
  private getRatingText(): string {
    return `${this.rating}分 · ${this.getRatingLabel()}`;
  }

  private getRatingLabel(): string {
    switch (this.rating) {
      case 1: return '非常差';
      case 2: return '差';
      case 3: return '一般';
      case 4: return '很满意';
      case 5: return '非常好';
      default: return '';
    }
  }

  /** 格式化规格 */
  private formatSpecs(specs?: OrderItemSpec[]): string {
    if (!specs || specs.length === 0) {
      return '';
    }
    return `规格：${specs.map((s: OrderItemSpec) => s.value).join(' / ')}`;
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部栏（对齐设计稿 qn-topbar）
        Row() {
          Text('‹')
            .fontSize(20)
            .fontColor($r('app.color.color_ink'))
            .width(32)
            .height(32)
            .textAlign(TextAlign.Center)
            .borderRadius(AppConstants.RADIUS_PILL)
            .backgroundColor($r('app.color.color_bg_card'))
            .shadow(AppConstants.SHADOW_CARD)
            .onClick(() => { NavigationHelper.pop(); })

          Text('发表评价')
            .fontSize(17)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          // 发布按钮（黄色文字）
          Text('发布')
            .fontSize(14)
            .fontColor(this.canSubmit()
              ? $r('app.color.color_yellow_deep')
              : $r('app.color.color_text_4'))
            .fontWeight(FontWeight.Bold)
            .padding({ left: 4, right: 4, top: 6, bottom: 6 })
            .onClick(() => {
              if (this.canSubmit()) {
                this.onSubmit();
              }
            })
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor($r('app.color.color_bg_page'))
        .alignItems(VerticalAlign.Center)

        Scroll() {
          Column({ space: 12 }) {
            // 1. 商品信息卡（对齐设计稿 qn-card + qn-prod）
            ForEach(this.items, (item: OrderItem, _i: number) => {
              this.ProductCard(item)
            }, (item: OrderItem) => item.productId + (item.skuId ?? ''))

            // 2. 星级评分卡（对齐设计稿 qn-card + qn-rate-*）
            this.RatingCard()

            // 3. 评价内容卡（对齐设计稿 qn-card + qn-textarea）
            this.ContentCard()

            // 4. 图片上传卡（对齐设计稿 qn-card + qn-upload-*）
            this.UploadCard()

            // 5. 匿名评价卡（对齐设计稿 qn-card + qn-anon-row）
            this.AnonymousCard()
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 24 })
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor($r('app.color.color_bg_page'))
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 是否可提交 */
  private canSubmit(): boolean {
    return !this.isSubmitting && this.content.trim().length > 0;
  }

  /** 商品信息卡（对齐设计稿 qn-prod） */
  @Builder
  ProductCard(item: OrderItem) {
    Row({ space: 12 }) {
      // 商品图（64×64 RADIUS_MD）
      Image(ImageUtil.get(item.image))
        .width(64)
        .height(64)
        .borderRadius(AppConstants.RADIUS_MD)
        .objectFit(ImageFit.Cover)
        .backgroundColor($r('app.color.color_fill'))

      Column({ space: 4 }) {
        Text(item.title)
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Medium)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.formatSpecs(item.specs))
          .fontSize(12)
          .fontColor($r('app.color.color_text_3'))
        // 价格（¥11px + 15px 800 红）
        Row({ space: 1 }) {
          Text('¥')
            .fontSize(11)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
          Text(item.price.toFixed(2))
            .fontSize(15)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
        }
        .alignItems(VerticalAlign.Bottom)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(VerticalAlign.Center)
  }

  /** 星级评分卡（对齐设计稿 qn-rate-* + qn-sub-rate） */
  @Builder
  RatingCard() {
    Column({ space: 0 }) {
      // 整体评分标签
      Text('整体评分')
        .fontSize(15)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)

      // 5 大星
      Row({ space: 12 }) {
        StarRating({
          rating: this.rating,
          starSize: 32,
          interactive: true,
          onRatingChange: (r: number) => { this.rating = r; }
        })
      }
      .margin({ top: 12 })

      // 评分文案
      Text(this.getRatingText())
        .fontSize(13)
        .fontColor($r('app.color.color_green_deep'))
        .fontWeight(FontWeight.Medium)
        .margin({ top: 8 })
        .alignSelf(ItemAlign.Start)

      // 分隔线
      Divider()
        .color($r('app.color.color_line'))
        .strokeWidth(1)
        .margin({ top: 14 })

      // 子维度评分
      ForEach(this.subRates, (sub: SubRateItem, idx: number) => {
        this.SubRateRow(sub, idx)
      }, (sub: SubRateItem) => sub.key)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 子维度评分行（对齐设计稿 qn-sub-row） */
  @Builder
  SubRateRow(sub: SubRateItem, idx: number) {
    Column({ space: 0 }) {
      Row() {
        Text(sub.label)
          .fontSize(14)
          .fontColor($r('app.color.color_ink_2'))
          .layoutWeight(1)
        StarRating({
          rating: this.getSubRating(sub.key),
          starSize: 16,
          interactive: true,
          onRatingChange: (r: number) => { this.setSubRating(sub.key, r); }
        })
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)

      if (idx < this.subRates.length - 1) {
        Divider()
          .color($r('app.color.color_line'))
          .strokeWidth(1)
      }
    }
    .width('100%')
  }

  /** 评价内容卡（对齐设计稿 qn-textarea-wrap） */
  @Builder
  ContentCard() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      TextArea({ text: this.content, placeholder: '说说商品怎么样吧～' })
        .fontSize(14)
        .fontColor($r('app.color.color_ink'))
        .placeholderFont({ size: 14 })
        .placeholderColor($r('app.color.color_text_4'))
        .maxLength(this.CONTENT_MAX)
        .height(120)
        .backgroundColor($r('app.color.color_fill'))
        .borderRadius(AppConstants.RADIUS_MD)
        .padding(12)
        .onChange((v: string) => { this.content = v; })

      // 字数计数
      Text(`${this.content.length}/${this.CONTENT_MAX}`)
        .fontSize(11)
        .fontColor($r('app.color.color_text_4'))
        .margin({ right: 12, bottom: 10 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 图片上传卡（对齐设计稿 qn-upload-*） */
  @Builder
  UploadCard() {
    Column({ space: 12 }) {
      // 标题行
      Row() {
        Text('添加图片')
          .fontSize(13)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Medium)
        Text(`最多${this.IMAGE_MAX}张`)
          .fontSize(11)
          .fontColor($r('app.color.color_text_3'))
          .margin({ left: 6 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)

      // 图片网格（3 列 80×80 + 8px gap）
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.imagePool.slice(0, this.IMAGE_MAX), (imgKey: string, _i: number) => {
          Stack({ alignContent: Alignment.TopEnd }) {
            Image(ImageUtil.get(imgKey))
              .width(80)
              .height(80)
              .borderRadius(AppConstants.RADIUS_MD)
              .objectFit(ImageFit.Cover)
              .backgroundColor($r('app.color.color_fill'))

            // 选中标记
            Text(this.selectedImages.indexOf(imgKey) >= 0 ? '✓' : '')
              .fontSize(12)
              .fontColor(Color.White)
              .width(20)
              .height(20)
              .textAlign(TextAlign.Center)
              .borderRadius(AppConstants.RADIUS_PILL)
              .backgroundColor(this.selectedImages.indexOf(imgKey) >= 0
                ? $r('app.color.color_cta_black')
                : Color.Transparent)
              .margin({ top: 4, right: 4 })
          }
          .width(80)
          .height(80)
          .margin({ right: 8, bottom: 8 })
          .onClick(() => { this.toggleImage(imgKey); })
        }, (imgKey: string, idx: number) => `${imgKey}_${idx}`)

        // 添加框（虚线边框）
        if (this.selectedImages.length < this.IMAGE_MAX) {
          Column({ space: 4 }) {
            Text('+')
              .fontSize(24)
              .fontColor($r('app.color.color_text_4'))
          }
          .width(80)
          .height(80)
          .borderRadius(AppConstants.RADIUS_MD)
          .backgroundColor($r('app.color.color_bg_card'))
          .borderWidth(1.5)
          .borderColor('#E0E0E0')
          .borderStyle(BorderStyle.Dashed)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .margin({ right: 8, bottom: 8 })
          .onClick(() => { ToastUtil.show('图片上传功能开发中'); })
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 匿名评价卡（对齐设计稿 qn-anon-row + qn-toggle） */
  @Builder
  AnonymousCard() {
    Row() {
      Text('匿名评价')
        .fontSize(15)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)

      // Toggle 开关
      Row() {
        Stack({ alignContent: Alignment.Start }) {
          // 滑块
          Column()
            .width(20)
            .height(20)
            .borderRadius(AppConstants.RADIUS_PILL)
            .backgroundColor(Color.White)
            .shadow({ radius: 3, color: 'rgba(0,0,0,0.15)', offsetX: 0, offsetY: 1 })
            .margin({ left: 2, top: 2 })
            .offset({ x: this.anonymous ? 20 : 0 })
        }
        .width(44)
        .height(24)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor(this.anonymous ? $r('app.color.color_green') : '#E0E0E0')
      }
      .onClick(() => { this.toggleAnonymous(); })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(VerticalAlign.Center)
  }
}
