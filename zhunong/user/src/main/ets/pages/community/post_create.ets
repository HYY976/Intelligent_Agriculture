/**
 * post_create - 发帖页（对齐设计稿 pages/post-create.html）
 *  - 顶部栏：圆形返回按钮 + 居中标题"发布帖子" + 右侧黄色"发布"文字按钮
 *  - 话题选择卡：白卡 + 胶囊标签流（灰底默认，黄底选中）
 *  - 标题输入卡：18px 粗体输入 + 分割线 + 字数统计
 *  - 正文输入卡：textarea(160高) + 分割线 + 字数统计
 *  - 图片区卡：白卡 + 标签 + "最多9张"提示 + 3列固定80×80网格 + 虚线添加框
 *  - 底部发布按钮：黑底白字 + 箭头图标（46高 + 圆角14）
 * spec 3.1.3.2
 */

import { Logger, AppConstants, ToastUtil, NavigationHelper } from 'common';
import { Topic } from '../../model/CommunityModels';
import { MOCK_TOPICS, createMockPost } from '../../mock/CommunityMock';
import { ImageUtil } from '../../utils/ImageUtil';

/** 可选图片池（Mock：从现有商品图中选择） */
const IMAGE_POOL: string[] = [
  'prod_vegetable_1', 'prod_vegetable_2', 'prod_fruit_1', 'prod_fruit_2',
  'prod_rice_1', 'prod_egg_1', 'prod_tea_1', 'prod_nut_1',
  'prod_honey_1', 'prod_meat_1', 'prod_dried_1', 'prod_mushroom_1',
  'prod_chili_1', 'prod_corn_1', 'prod_bean_1'
];

@ComponentV2
export struct PostCreate {
  /** 标题 */
  @Local title: string = '';
  /** 正文 */
  @Local content: string = '';
  /** 已选图片 key 数组（最多9张） */
  @Local selectedImages: string[] = [];
  /** 当前话题 ID */
  @Local currentTopicId: string = '';
  /** 是否显示图片选择弹窗 */
  @Local showImageSheet: boolean = false;
  /** 是否正在提交 */
  @Local isSubmitting: boolean = false;
  /** spec 16.12：当前用户头像（默认 '🙂'） */
  @Local currentAvatar: string = '🙂';
  /** 话题列表（不含"全部"） */
  private topics: Topic[] = MOCK_TOPICS.filter((t: Topic) => t.topicId !== 'all');

  /** 标题最大长度（对齐设计稿 maxlength=50） */
  private readonly TITLE_MAX: number = 50;
  /** 正文最大长度 */
  private readonly CONTENT_MAX: number = 5000;
  /** 图片最大数量 */
  private readonly IMAGE_MAX: number = 9;

  /** 返回 */
  private goBack(): void {
    NavigationHelper.pop();
  }

  /** 获取当前话题名 */
  private currentTopicName(): string {
    const topic: Topic | undefined = this.topics.find((t: Topic) => t.topicId === this.currentTopicId);
    return topic ? topic.name : '';
  }

  /** 选择话题（对齐设计稿：点击胶囊标签切换） */
  private onTopicSelect(topicId: string): void {
    this.currentTopicId = topicId;
  }

  /** 切换图片选中状态 */
  private onToggleImage(imgKey: string): void {
    const idx: number = this.selectedImages.indexOf(imgKey);
    if (idx >= 0) {
      this.selectedImages.splice(idx, 1);
    } else {
      if (this.selectedImages.length >= this.IMAGE_MAX) {
        ToastUtil.warning(`最多只能选择${this.IMAGE_MAX}张图片`);
        return;
      }
      this.selectedImages.push(imgKey);
    }
  }

  /** 移除已选图片 */
  private onRemoveImage(index: number): void {
    this.selectedImages.splice(index, 1);
  }

  /** 打开图片选择弹窗 */
  private onOpenImagePicker(): void {
    if (this.selectedImages.length >= this.IMAGE_MAX) {
      ToastUtil.warning(`最多只能选择${this.IMAGE_MAX}张图片`);
      return;
    }
    this.showImageSheet = true;
  }

  /** 表单校验 */
  private validate(): boolean {
    if (this.title.trim().length === 0) {
      ToastUtil.error('请输入帖子标题');
      return false;
    }
    if (this.title.length > this.TITLE_MAX) {
      ToastUtil.error(`标题不能超过${this.TITLE_MAX}字`);
      return false;
    }
    if (this.content.trim().length === 0) {
      ToastUtil.error('请输入帖子正文');
      return false;
    }
    if (this.content.length > this.CONTENT_MAX) {
      ToastUtil.error(`正文不能超过${this.CONTENT_MAX}字`);
      return false;
    }
    if (this.currentTopicId.length === 0) {
      ToastUtil.error('请选择话题');
      return false;
    }
    return true;
  }

  /** 提交发帖 */
  private onSubmit(): void {
    if (!this.validate()) {
      return;
    }
    if (this.isSubmitting) {
      return;
    }
    this.isSubmitting = true;
    try {
      createMockPost(this.title.trim(), this.content.trim(), this.currentTopicId, this.currentTopicName(), this.selectedImages, this.currentAvatar);
      ToastUtil.success('发布成功');
      Logger.info(AppConstants.SCENE_USER, JSON.stringify({
        action: 'post_create_submit',
        titleLength: this.title.length,
        contentLength: this.content.length,
        imageCount: this.selectedImages.length,
        topicId: this.currentTopicId
      }));
      NavigationHelper.pop();
    } catch (err) {
      ToastUtil.error('发布失败，请重试');
      Logger.error(AppConstants.SCENE_USER, JSON.stringify({
        action: 'post_create_fail',
        error: (err as Error).message
      }));
    } finally {
      this.isSubmitting = false;
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部导航栏（对齐设计稿 qn-topbar）
        this.TopBar()
        // 表单内容（对齐设计稿 qn-pc-body）
        Scroll() {
          Column({ space: 12 }) {
            // 1. 话题选择卡
            this.TopicCard()
            // 2. 标题输入卡
            this.TitleCard()
            // 3. 正文输入卡
            this.ContentCard()
            // 4. 图片区卡
            this.ImageCard()
            // 5. 发布按钮
            this.PublishButton()
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 16 })
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
      // 图片选择弹窗
      .bindSheet($$this.showImageSheet, this.ImageSheet(), {
        height: '60%',
        dragBar: true,
        backgroundColor: $r('app.color.color_bg_card')
      })
    }
    .hideTitleBar(true)
  }

  /** 顶部导航栏（对齐设计稿 qn-topbar：圆形返回 + 居中标题 + 黄色发布） */
  @Builder
  TopBar() {
    Row() {
      // 左：圆形返回按钮（对齐设计稿 qn-icon-btn：白底圆 + 软阴影）
      Text('←')
        .fontSize(18)
        .fontColor($r('app.color.color_ink'))
        .width(32)
        .height(32)
        .textAlign(TextAlign.Center)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor($r('app.color.color_bg_card'))
        .shadow(AppConstants.SHADOW_CARD)
        .onClick(() => {
          this.goBack();
        })

      // 中：居中标题"发布帖子"（对齐设计稿 qn-title-center：17px 700）
      Text('发布帖子')
        .fontSize(17)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 右：发布文字按钮（对齐设计稿 qn-pc-top-publish：14px 700 黄色）
      Text('发布')
        .fontSize(14)
        .fontColor(this.isSubmitting ? $r('app.color.color_text_4') : $r('app.color.color_yellow_deep'))
        .fontWeight(FontWeight.Bold)
        .width(48)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.onSubmit();
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 10 })
    .alignItems(VerticalAlign.Center)
  }

  /** 话题选择卡（对齐设计稿 qn-card + qn-pc-tags） */
  @Builder
  TopicCard() {
    Column({ space: 0 }) {
      // 小标题（对齐设计稿 qn-pc-label：13px 600）
      Text('选择话题')
        .fontSize(13)
        .fontColor($r('app.color.color_ink_2'))
        .fontWeight(FontWeight.Medium)
        .width('100%')

      // 话题胶囊标签流（对齐设计稿 qn-pc-tags：flex-wrap + 8px gap）
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.topics, (topic: Topic) => {
          Text(`#${topic.name}`)
            .fontSize(13)
            .fontColor(this.currentTopicId === topic.topicId ? $r('app.color.color_ink') : $r('app.color.color_text_2'))
            .fontWeight(this.currentTopicId === topic.topicId ? FontWeight.Bold : FontWeight.Medium)
            .padding({ left: 14, right: 14, top: 7, bottom: 7 })
            .borderRadius(AppConstants.RADIUS_PILL)
            .backgroundColor(this.currentTopicId === topic.topicId ? $r('app.color.color_primary') : $r('app.color.color_fill'))
            .margin({ right: 8, top: 8 })
            .onClick(() => {
              this.onTopicSelect(topic.topicId);
            })
        }, (topic: Topic) => topic.topicId)
      }
      .width('100%')
      .margin({ top: 4 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 标题输入卡（对齐设计稿 qn-card + qn-pc-title-input） */
  @Builder
  TitleCard() {
    Column({ space: 0 }) {
      // 标题输入（对齐设计稿 qn-pc-title-input：18px 700）
      TextInput({ text: this.title, placeholder: '写个吸引人的标题...' })
        .fontSize(18)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .placeholderColor($r('app.color.color_text_4'))
        .placeholderFont({ size: 18, weight: FontWeight.Medium })
        .backgroundColor(Color.Transparent)
        .borderRadius(0)
        .padding(0)
        .maxLength(this.TITLE_MAX)
        .onChange((value: string) => {
          this.title = value;
        })

      // 分割线（对齐设计稿 qn-pc-card-divider）
      Row()
        .width('100%')
        .height(1)
        .backgroundColor($r('app.color.color_divider'))
        .margin({ top: 10 })

      // 字数统计（对齐设计稿 qn-pc-count-row：11px text-3 右对齐）
      Row() {
        Text(`${this.title.length}/${this.TITLE_MAX}`)
          .fontSize(11)
          .fontColor(this.title.length > this.TITLE_MAX ? $r('app.color.color_live') : $r('app.color.color_text_3'))
      }
      .width('100%')
      .margin({ top: 8 })
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 正文输入卡（对齐设计稿 qn-card + qn-pc-textarea） */
  @Builder
  ContentCard() {
    Column({ space: 0 }) {
      // 正文 textarea（对齐设计稿 qn-pc-textarea：14px 160高 1.6行高）
      TextArea({ text: this.content, placeholder: '分享你的智农故事、种植经验或乡村见闻...' })
        .fontSize(14)
        .fontColor($r('app.color.color_ink'))
        .placeholderColor($r('app.color.color_text_4'))
        .backgroundColor(Color.Transparent)
        .borderRadius(0)
        .padding(0)
        .height(160)
        .maxLength(this.CONTENT_MAX)
        .onChange((value: string) => {
          this.content = value;
        })

      // 分割线
      Row()
        .width('100%')
        .height(1)
        .backgroundColor($r('app.color.color_divider'))
        .margin({ top: 10 })

      // 字数统计
      Row() {
        Text(`${this.content.length}/${this.CONTENT_MAX}`)
          .fontSize(11)
          .fontColor(this.content.length > this.CONTENT_MAX ? $r('app.color.color_live') : $r('app.color.color_text_3'))
      }
      .width('100%')
      .margin({ top: 8 })
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 图片区卡（对齐设计稿 qn-card + qn-pc-img-grid） */
  @Builder
  ImageCard() {
    Column({ space: 0 }) {
      // 标签行（对齐设计稿 qn-pc-label：添加图片 + 最多9张）
      Row() {
        Text('添加图片')
          .fontSize(13)
          .fontColor($r('app.color.color_ink_2'))
          .fontWeight(FontWeight.Medium)
        Blank()
        Text('最多9张')
          .fontSize(11)
          .fontColor($r('app.color.color_text_3'))
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')

      // 图片网格（对齐设计稿 qn-pc-img-grid：3列 80×80 + 8px gap）
      Grid() {
        // 已选图片
        ForEach(this.selectedImages, (imgKey: string, idx: number) => {
          GridItem() {
            Stack({ alignContent: Alignment.TopEnd }) {
              Image(ImageUtil.get(imgKey))
                .width(80)
                .height(80)
                .borderRadius(AppConstants.RADIUS_MD)
                .objectFit(ImageFit.Cover)

              // 删除按钮（对齐设计稿 qn-pc-img-del：右上角半透明圆）
              Text('✕')
                .fontSize(12)
                .fontColor(Color.White)
                .width(20)
                .height(20)
                .textAlign(TextAlign.Center)
                .borderRadius(AppConstants.RADIUS_PILL)
                .backgroundColor('rgba(26,26,26,0.55)')
                .margin({ top: 4, right: 4 })
                .onClick(() => {
                  this.onRemoveImage(idx);
                })
            }
            .width(80)
            .height(80)
            .borderRadius(AppConstants.RADIUS_MD)
            .clip(true)
          }
        }, (imgKey: string, idx: number) => `${imgKey}_${idx}`)

        // 添加框（对齐设计稿 qn-pc-addimg：虚线边框 + 相机图标 + 添加图片文字）
        if (this.selectedImages.length < this.IMAGE_MAX) {
          GridItem() {
            Column({ space: 4 }) {
              Text('📷')
                .fontSize(24)
              Text('添加图片')
                .fontSize(10)
                .fontColor($r('app.color.color_text_3'))
            }
            .width(80)
            .height(80)
            .borderRadius(AppConstants.RADIUS_MD)
            .backgroundColor($r('app.color.color_bg_page'))
            .borderWidth(1.5)
            .borderColor($r('app.color.color_line_2'))
            .borderStyle(BorderStyle.Dashed)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .onClick(() => {
              this.onOpenImagePicker();
            })
          }
        }
      }
      .columnsTemplate('80px 80px 80px')
      .columnsGap(8)
      .rowsGap(8)
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 发布按钮（对齐设计稿 qn-pc-publish2：黑底白字 + 箭头图标） */
  @Builder
  PublishButton() {
    Row({ space: 6 }) {
      Text('发布帖子')
        .fontSize(15)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
      Text('→')
        .fontSize(18)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .height(46)
    .borderRadius(AppConstants.RADIUS_MD)
    .backgroundColor(this.isSubmitting ? $r('app.color.color_text_4') : $r('app.color.color_ink'))
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.onSubmit();
    })
  }

  /** 图片选择弹窗（对齐设计稿：3列网格图片池） */
  @Builder
  ImageSheet() {
    Column({ space: 0 }) {
      // 标题行
      Row() {
        Text(`选择图片（已选 ${this.selectedImages.length}/${this.IMAGE_MAX}）`)
          .fontSize(16)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text('完成')
          .fontSize(14)
          .fontColor($r('app.color.color_yellow_deep'))
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            this.showImageSheet = false;
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      // 图片池网格
      Grid() {
        ForEach(IMAGE_POOL, (imgKey: string) => {
          GridItem() {
            this.ImagePickerItem(imgKey)
          }
        }, (imgKey: string) => imgKey)
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsGap(8)
      .columnsGap(8)
      .padding({ left: 16, right: 16, bottom: 24 })
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  /** 图片选择项 */
  @Builder
  ImagePickerItem(imgKey: string) {
    Stack({ alignContent: Alignment.TopEnd }) {
      Image(ImageUtil.get(imgKey))
        .width('100%')
        .aspectRatio(1)
        .borderRadius(AppConstants.RADIUS_SM)
        .objectFit(ImageFit.Cover)

      // 选中标记
      if (this.selectedImages.indexOf(imgKey) >= 0) {
        Column()
          .width('100%')
          .height('100%')
          .borderRadius(AppConstants.RADIUS_SM)
          .backgroundColor('rgba(255,226,52,0.35)')

        Text('✓')
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .width(22)
          .height(22)
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_primary'))
          .textAlign(TextAlign.Center)
          .margin({ top: 4, right: 4 })
      }
    }
    .width('100%')
    .aspectRatio(1)
    .onClick(() => {
      this.onToggleImage(imgKey);
    })
  }
}
