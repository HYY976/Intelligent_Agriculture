/**
 * post_create - 发帖页（spec 3.1.3.2）
 *  - 表单：标题 + 正文（最多5000字）+ 9张图片 + 话题选择
 *  - 不支持视频
 *  - 必填项校验：标题（1-60字）+ 正文（1-5000字）+ 话题（必选）
 *  - 图片从预设图库选择（Mock，不集成真实相册/相机）
 *  - 提交后回到社区列表
 */

import { Logger, AppConstants, ToastUtil, RouteName, NavigationHelper } from 'common';
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
  /** 是否显示话题选择弹窗 */
  @Local showTopicSheet: boolean = false;
  /** 是否显示图片选择弹窗 */
  @Local showImageSheet: boolean = false;
  /** 是否正在提交 */
  @Local isSubmitting: boolean = false;
  /** 话题列表（不含"全部"） */
  private topics: Topic[] = MOCK_TOPICS.filter((t: Topic) => t.topicId !== 'all');

  /** 标题最大长度 */
  private readonly TITLE_MAX: number = 60;
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

  /** 选择话题 */
  private onTopicSelect(topicId: string): void {
    this.currentTopicId = topicId;
    this.showTopicSheet = false;
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
      createMockPost(this.title.trim(), this.content.trim(), this.currentTopicId, this.currentTopicName(), this.selectedImages);
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
      Logger.error(AppConstants.SCENE_USER, { action: 'post_create_fail', error: (err as Error).message });
    } finally {
      this.isSubmitting = false;
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部导航栏
        this.TopBar()
        // 表单内容
        Scroll() {
          Column({ space: 16 }) {
            // 标题输入
            this.TitleSection()
            // 正文输入
            this.ContentSection()
            // 图片选择
            this.ImageSection()
            // 话题选择
            this.TopicSection()
          }
          .width('100%')
          .padding(16)
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
        // 底部发布按钮
        this.BottomActionBar()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
      // 话题选择弹窗
      .bindSheet($$this.showTopicSheet, this.TopicSheet(), {
        height: '40%',
        dragBar: true,
        backgroundColor: $r('app.color.color_bg_card')
      })
      // 图片选择弹窗
      .bindSheet($$this.showImageSheet, this.ImageSheet(), {
        height: '60%',
        dragBar: true,
        backgroundColor: $r('app.color.color_bg_card')
      })
    }
    .hideTitleBar(true)
  }

  /** 顶部导航栏 */
  @Builder
  TopBar() {
    Row({ space: 12 }) {
      Text('取消')
        .fontSize(15)
        .fontColor($r('app.color.color_text_secondary'))
        .onClick(() => {
          this.goBack();
        })
      Text('发帖')
        .fontSize(16)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Text('发布')
        .fontSize(15)
        .fontColor(this.isSubmitting ? $r('app.color.color_button_disabled') : $r('app.color.color_primary'))
        .fontWeight(FontWeight.Medium)
        .onClick(() => {
          this.onSubmit();
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** 标题输入区 */
  @Builder
  TitleSection() {
    Column({ space: 6 }) {
      Row({ space: 4 }) {
        Text('*')
          .fontSize(14)
          .fontColor($r('app.color.color_error'))
        Text('标题')
          .fontSize(14)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Medium)
        Blank()
        Text(`${this.title.length}/${this.TITLE_MAX}`)
          .fontSize(11)
          .fontColor(this.title.length > this.TITLE_MAX ? $r('app.color.color_error') : $r('app.color.color_text_hint'))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      TextInput({ text: this.title, placeholder: '请输入帖子标题（1-60字）' })
        .fontSize(14)
        .fontColor($r('app.color.color_text_primary'))
        .placeholderColor($r('app.color.color_text_hint'))
        .backgroundColor($r('app.color.color_bg_card'))
        .borderRadius(12)
        .padding({ left: 12, right: 12, top: 12, bottom: 12 })
        .maxLength(this.TITLE_MAX)
        .onChange((value: string) => {
          this.title = value;
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /** 正文输入区 */
  @Builder
  ContentSection() {
    Column({ space: 6 }) {
      Row({ space: 4 }) {
        Text('*')
          .fontSize(14)
          .fontColor($r('app.color.color_error'))
        Text('正文')
          .fontSize(14)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Medium)
        Blank()
        Text(`${this.content.length}/${this.CONTENT_MAX}`)
          .fontSize(11)
          .fontColor(this.content.length > this.CONTENT_MAX ? $r('app.color.color_error') : $r('app.color.color_text_hint'))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      TextArea({ text: this.content, placeholder: '分享你的种植经验、销路心得、乡村生活…（1-5000字）' })
        .fontSize(14)
        .fontColor($r('app.color.color_text_primary'))
        .placeholderColor($r('app.color.color_text_hint'))
        .backgroundColor($r('app.color.color_bg_card'))
        .borderRadius(12)
        .padding({ left: 12, right: 12, top: 12, bottom: 12 })
        .height(160)
        .maxLength(this.CONTENT_MAX)
        .onChange((value: string) => {
          this.content = value;
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /** 图片选择区 */
  @Builder
  ImageSection() {
    Column({ space: 8 }) {
      Row({ space: 4 }) {
        Text('图片（可选，最多9张）')
          .fontSize(14)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Medium)
        Blank()
        Text(`${this.selectedImages.length}/${this.IMAGE_MAX}`)
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 已选图片预览网格 + 添加按钮
      Grid() {
        ForEach(this.selectedImages, (imgKey: string, idx: number) => {
          GridItem() {
            Stack({ alignContent: Alignment.TopEnd }) {
              Image(ImageUtil.get(imgKey))
                .width('100%')
                .aspectRatio(1)
                .borderRadius(8)
                .objectFit(ImageFit.Cover)
              Text('✕')
                .fontSize(12)
                .fontColor(Color.White)
                .width(20)
                .height(20)
                .borderRadius(10)
                .backgroundColor('rgba(0,0,0,0.5)')
                .textAlign(TextAlign.Center)
                .margin({ top: 4, right: 4 })
                .onClick(() => {
                  this.onRemoveImage(idx);
                })
            }
            .width('100%')
            .aspectRatio(1)
          }
        }, (imgKey: string, idx: number) => imgKey + idx)
        // 添加按钮（未达9张时显示）
        if (this.selectedImages.length < this.IMAGE_MAX) {
          GridItem() {
            Column({ space: 4 }) {
              Text('+')
                .fontSize(28)
                .fontColor($r('app.color.color_text_hint'))
              Text('添加图片')
                .fontSize(10)
                .fontColor($r('app.color.color_text_hint'))
            }
            .width('100%')
            .aspectRatio(1)
            .borderRadius(8)
            .backgroundColor($r('app.color.color_bg_card'))
            .border({ width: 1, color: $r('app.color.color_divider') })
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .onClick(() => {
              this.showImageSheet = true;
            })
          }
        }
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsGap(8)
      .columnsGap(8)
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /** 话题选择区 */
  @Builder
  TopicSection() {
    Column({ space: 8 }) {
      Row({ space: 4 }) {
        Text('*')
          .fontSize(14)
          .fontColor($r('app.color.color_error'))
        Text('话题')
          .fontSize(14)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Medium)
      }
      .alignItems(VerticalAlign.Center)

      Row({ space: 8 }) {
        Text(this.currentTopicId.length > 0 ? `#${this.currentTopicName()}` : '请选择话题')
          .fontSize(13)
          .fontColor(this.currentTopicId.length > 0 ? $r('app.color.color_primary') : $r('app.color.color_text_hint'))
          .layoutWeight(1)
        Text('▾')
          .fontSize(12)
          .fontColor($r('app.color.color_text_secondary'))
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 12, bottom: 12 })
      .borderRadius(12)
      .backgroundColor($r('app.color.color_bg_card'))
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.showTopicSheet = true;
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /** 底部操作栏 */
  @Builder
  BottomActionBar() {
    Column() {
      Text('发布')
        .fontSize(15)
        .fontColor(Color.White)
        .width('100%')
        .height(48)
        .borderRadius(24)
        .backgroundColor(this.isSubmitting ? $r('app.color.color_button_disabled') : $r('app.color.color_primary'))
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.onSubmit();
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 32 })
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 话题选择弹窗 */
  @Builder
  TopicSheet() {
    Column({ space: 0 }) {
      Text('选择话题')
        .fontSize(16)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .padding({ left: 16, top: 12, bottom: 12 })

      List() {
        ForEach(this.topics, (topic: Topic) => {
          ListItem() {
            Row({ space: 8 }) {
              Text(topic.topicId === this.currentTopicId ? '✓' : '')
                .fontSize(16)
                .fontColor($r('app.color.color_primary'))
                .width(24)
              Text(`#${topic.name}`)
                .fontSize(15)
                .fontColor(topic.topicId === this.currentTopicId ? $r('app.color.color_primary') : $r('app.color.color_text_primary'))
                .layoutWeight(1)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .onClick(() => {
              this.onTopicSelect(topic.topicId);
            })
          }
        }, (topic: Topic) => topic.topicId)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
  }

  /** 图片选择弹窗 */
  @Builder
  ImageSheet() {
    Column({ space: 0 }) {
      Row() {
        Text('选择图片（已选 ' + this.selectedImages.length + '/' + this.IMAGE_MAX + '）')
          .fontSize(16)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text('完成')
          .fontSize(14)
          .fontColor($r('app.color.color_primary'))
          .onClick(() => {
            this.showImageSheet = false;
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

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
        .borderRadius(8)
        .objectFit(ImageFit.Cover)
      // 选中标记
      if (this.selectedImages.indexOf(imgKey) >= 0) {
        Column()
          .width('100%')
          .height('100%')
          .borderRadius(8)
          .backgroundColor('rgba(76,175,80,0.3)')
        Text('✓')
          .fontSize(14)
          .fontColor(Color.White)
          .width(20)
          .height(20)
          .borderRadius(10)
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
