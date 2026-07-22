/**
 * review_create - 评价提交页
 * 遵循 spec 3.1.4.1：5星评分 + 文字评价 + 多图（最多5张）
 * 确认收货后7天内可评价一次
 */

import { RouteName, NavigationHelper, Logger, AppConstants, ToastUtil } from 'common';
import { getMockOrderById } from '../../mock/OrderMock';
import { getMockProductById } from '../../mock/ProductMock';
import { Order, OrderItem, SubOrder } from '../../model/OrderModels';
import { ImageUtil } from '../../utils/ImageUtil';
import { StarRating } from '../../components/StarRating';

@ComponentV2
export struct ReviewCreate {
  @Local orderId: string = '';
  @Local order: Order | null = null;
  @Local items: OrderItem[] = [];
  @Local rating: number = 5;
  @Local content: string = '';
  @Local selectedImages: string[] = [];
  @Local isSubmitting: boolean = false;
  /** 可选评价图片池 */
  private imagePool: string[] = ['prod_vegetable_1', 'prod_vegetable_2', 'prod_fruit_1', 'prod_rice_1', 'prod_tea_1', 'prod_honey_1'];

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
      imageCount: this.selectedImages.length
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
      if (this.selectedImages.length >= 5) {
        ToastUtil.warning('最多上传5张图片');
        return;
      }
      this.selectedImages.push(imgKey);
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部栏
        Row() {
          Text('‹').fontSize(28).fontColor($r('app.color.color_text_primary')).onClick(() => { NavigationHelper.pop(); })
          Text('发表评价').fontSize(18).fontColor($r('app.color.color_text_primary')).fontWeight(FontWeight.Medium).layoutWeight(1).textAlign(TextAlign.Center)
          Text('').width(28)
        }
        .width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor($r('app.color.color_bg_card')).alignItems(VerticalAlign.Center)

        Scroll() {
          Column({ space: 12 }) {
            // 商品列表
            ForEach(this.items, (item: OrderItem, _i: number) => {
              Row({ space: 10 }) {
                Image(ImageUtil.get(item.image)).width(56).height(56).borderRadius(8).objectFit(ImageFit.Cover)
                Text(item.title).fontSize(12).fontColor($r('app.color.color_text_primary')).maxLines(2).layoutWeight(1)
              }.width('100%').padding(16).backgroundColor($r('app.color.color_bg_card')).borderRadius(12).margin({ left: 12, right: 12, top: 12 })
            }, (item: OrderItem) => item.productId + (item.skuId ?? ''))

            // 星级评分
            Column({ space: 10 }) {
              Text('整体评分').fontSize(14).fontColor($r('app.color.color_text_primary')).fontWeight(FontWeight.Medium).alignSelf(ItemAlign.Start)
              Row({ space: 8 }) {
                StarRating({
                  rating: this.rating,
                  starSize: 36,
                  interactive: true,
                  onRatingChange: (r: number) => { this.rating = r; }
                })
                Text(this.getRatingText()).fontSize(14).fontColor($r('app.color.color_accent_gold')).fontWeight(FontWeight.Medium)
              }.alignItems(VerticalAlign.Center)
            }
            .width('100%').padding(16).backgroundColor($r('app.color.color_bg_card')).borderRadius(12).margin({ left: 12, right: 12 }).alignItems(HorizontalAlign.Start)

            // 评价内容
            Column({ space: 8 }) {
              Text('评价内容').fontSize(14).fontColor($r('app.color.color_text_primary')).fontWeight(FontWeight.Medium).alignSelf(ItemAlign.Start)
              TextArea({ text: this.content, placeholder: '说说商品怎么样吧～（至少5字）' })
                .fontSize(13).maxLength(500).height(120).backgroundColor($r('app.color.color_bg_page')).borderRadius(8)
                .padding(12).onChange((v: string) => { this.content = v; })
            }
            .width('100%').padding(16).backgroundColor($r('app.color.color_bg_card')).borderRadius(12).margin({ left: 12, right: 12 }).alignItems(HorizontalAlign.Start)

            // 图片选择
            Column({ space: 8 }) {
              Text(`添加图片（${this.selectedImages.length}/5）`).fontSize(14).fontColor($r('app.color.color_text_primary')).fontWeight(FontWeight.Medium).alignSelf(ItemAlign.Start)
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.imagePool, (imgKey: string, _i: number) => {
                  Stack({ alignContent: Alignment.TopEnd }) {
                    Image(ImageUtil.get(imgKey)).width(72).height(72).borderRadius(8).objectFit(ImageFit.Cover)
                    Text(this.selectedImages.indexOf(imgKey) >= 0 ? '✓' : '+')
                      .fontSize(16).fontColor(Color.White)
                      .width(20).height(20).textAlign(TextAlign.Center)
                      .backgroundColor(this.selectedImages.indexOf(imgKey) >= 0 ? $r('app.color.color_primary') : 'rgba(0,0,0,0.5)')
                      .borderRadius(10).offset({ x: 6, y: -6 })
                  }
                  .width(72).height(72).margin({ right: 8, bottom: 8 })
                  .onClick(() => { this.toggleImage(imgKey); })
                }, (imgKey: string) => imgKey)
              }
            }
            .width('100%').padding(16).backgroundColor($r('app.color.color_bg_card')).borderRadius(12).margin({ left: 12, right: 12 }).alignItems(HorizontalAlign.Start)
          }
          .width('100%').padding({ bottom: 80 })
        }
        .layoutWeight(1).width('100%').backgroundColor($r('app.color.color_bg_page')).scrollBar(BarState.Off)

        // 底部提交
        Row() {
          Button('提交评价')
            .width('100%').height(44).borderRadius(22).backgroundColor($r('app.color.color_secondary')).fontColor(Color.White).fontSize(15)
            .enabled(!this.isSubmitting && this.content.trim().length >= 5)
            .onClick(() => { this.onSubmit(); })
        }
        .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 8 }).backgroundColor($r('app.color.color_bg_card')).border({ width: { top: 0.5 }, color: $r('app.color.color_divider') })
      }
      .width('100%').height('100%').backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 评分文案 */
  private getRatingText(): string {
    switch (this.rating) {
      case 1: return '非常差';
      case 2: return '差';
      case 3: return '一般';
      case 4: return '好';
      case 5: return '非常好';
      default: return '';
    }
  }
}
