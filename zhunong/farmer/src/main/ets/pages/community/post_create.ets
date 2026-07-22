/**
 * post_create - 发帖页（spec 3.2.4.2）
 *
 * 卖家发帖昵称带"卖家"V标
 * 字段：话题选择 + 标题 + 正文 + 图片（最多9张）
 */

import { Logger, AppConstants, ToastUtil, NavigationHelper, RouteName } from 'common';
import { Topic } from '../../model/FarmerCommunityModels';
import { CommunityRepository } from '../../repository/CommunityRepository';
import { MOCK_FARMER_ID } from '../../mock/FarmerMock';
import { PRESET_TOPICS } from '../../model/FarmerCommunityModels';

@ComponentV2
export struct PostCreate {
  /** 话题 ID */
  @Local topicId: string = 't1';
  /** 标题 */
  @Local title: string = '';
  /** 正文 */
  @Local content: string = '';
  /** 图片 key 数组 */
  @Local images: string[] = [];
  /** 是否正在提交 */
  @Local isSubmitting: boolean = false;
  /** 话题列表 */
  @Local topics: Topic[] = PRESET_TOPICS;

  /** 图片预设 key */
  private imageKeys: string[] = [
    'post_farm_1', 'post_vegetable_1', 'post_soil_1',
    'post_orange_1', 'post_chicken_1', 'post_tomato_1',
    'post_tea_1', 'post_pick_1', 'post_orchard_1'
  ];

  /** 添加图片 */
  private addImage(): void {
    if (this.images.length >= 9) {
      ToastUtil.warning('最多 9 张图片');
      return;
    }
    const idx: number = this.images.length;
    this.images.push(this.imageKeys[idx % this.imageKeys.length]);
  }

  /** 删除图片 */
  private removeImage(index: number): void {
    this.images.splice(index, 1);
  }

  /** 校验 */
  private validateForm(): boolean {
    if (this.title.length === 0) {
      ToastUtil.warning('请填写标题');
      return false;
    }
    if (this.content.length === 0) {
      ToastUtil.warning('请填写内容');
      return false;
    }
    return true;
  }

  /** 提交发帖 */
  private async submitPost(): Promise<void> {
    if (!this.validateForm()) {
      return;
    }
    this.isSubmitting = true;
    try {
      const postId: string = await CommunityRepository.createPost(
        MOCK_FARMER_ID,
        this.topicId,
        this.title,
        this.content,
        this.images
      );
      ToastUtil.success('发帖成功');
      Logger.info(AppConstants.SCENE_FARMER, { action: 'post_create_success', postId, topicId: this.topicId });
      NavigationHelper.pop();
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'post_create_fail', error: (err as Error).message });
      ToastUtil.error('发帖失败');
    } finally {
      this.isSubmitting = false;
    }
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        Scroll() {
          Column({ space: 16 }) {
            this.TopicSection()
            this.TitleSection()
            this.ContentSection()
            this.ImagesSection()
            this.SubmitButton()
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 24 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
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
      Text('发布帖子')
        .fontSize(18)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
      Row({ space: 4 }) {
        Text('卖家')
          .fontSize(10)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.color_secondary'))
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(6)
        Text('V')
          .fontSize(10)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.color_secondary'))
          .width(16)
          .height(16)
          .borderRadius(8)
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** 话题选择 */
  @Builder
  TopicSection() {
    Column({ space: 12 }) {
      Text('选择话题')
        .fontSize(14)
        .fontColor($r('app.color.color_text_secondary'))
        .alignSelf(ItemAlign.Start)
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.topics, (topic: Topic, _idx: number) => {
          Text(topic.name)
            .fontSize(13)
            .fontColor(this.topicId === topic.topicId ? Color.White : $r('app.color.color_text_primary'))
            .backgroundColor(this.topicId === topic.topicId ? $r('app.color.color_primary') : $r('app.color.color_bg_page'))
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(14)
            .margin({ right: 8, bottom: 8 })
            .onClick(() => { this.topicId = topic.topicId; })
        }, (topic: Topic) => topic.topicId)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 标题 */
  @Builder
  TitleSection() {
    Column({ space: 12 }) {
      Row() {
        Text('* 标题')
          .fontSize(14)
          .fontColor($r('app.color.color_text_secondary'))
        Blank()
        Text(`${this.title.length}/50`)
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')
      TextInput({ text: this.title, placeholder: '一句话概括你的话题' })
        .height(44)
        .borderRadius(8)
        .backgroundColor($r('app.color.color_bg_page'))
        .padding({ left: 12, right: 12 })
        .fontSize(14)
        .maxLength(50)
        .onChange((v: string) => { this.title = v; })
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 正文 */
  @Builder
  ContentSection() {
    Column({ space: 12 }) {
      Row() {
        Text('* 正文')
          .fontSize(14)
          .fontColor($r('app.color.color_text_secondary'))
        Blank()
        Text(`${this.content.length}/5000`)
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')
      TextArea({ text: this.content, placeholder: '分享你的故事、经验或问题...' })
        .height(160)
        .borderRadius(8)
        .backgroundColor($r('app.color.color_bg_page'))
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .fontSize(14)
        .maxLength(5000)
        .onChange((v: string) => { this.content = v; })
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 图片 */
  @Builder
  ImagesSection() {
    Column({ space: 12 }) {
      Row() {
        Text('图片（可选）')
          .fontSize(14)
          .fontColor($r('app.color.color_text_secondary'))
        Blank()
        Text(`${this.images.length}/9`)
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')
      Grid() {
        ForEach(this.images, (imgKey: string, idx: number) => {
          GridItem() {
            Stack() {
              Text('🖼')
                .fontSize(24)
              Text('×')
                .fontSize(14)
                .fontColor(Color.White)
                .backgroundColor('rgba(0,0,0,0.6)')
                .width(20)
                .height(20)
                .borderRadius(10)
                .textAlign(TextAlign.Center)
                .position({ x: '70%', y: 4 })
                .onClick(() => { this.removeImage(idx); })
            }
            .width('100%')
            .height(96)
            .borderRadius(8)
            .backgroundColor($r('app.color.color_primary_light'))
            .alignContent(Alignment.Center)
          }
        }, (imgKey: string, idx: number) => `${imgKey}_${idx}`)
        if (this.images.length < 9) {
          GridItem() {
            Stack() {
              Text('+')
                .fontSize(36)
                .fontColor($r('app.color.color_text_hint'))
            }
            .width('100%')
            .height(96)
            .borderRadius(8)
            .backgroundColor($r('app.color.color_bg_page'))
            .alignContent(Alignment.Center)
            .onClick(() => { this.addImage(); })
          }
        }
      }
      .columnsTemplate('1fr 1fr 1fr')
      .columnsGap(8)
      .rowsGap(8)
      .width('100%')
      .height(96)
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 提交按钮 */
  @Builder
  SubmitButton() {
    Button(this.isSubmitting ? '发布中...' : '发布帖子')
      .width('100%')
      .height(48)
      .borderRadius(24)
      .backgroundColor(this.isSubmitting ? $r('app.color.color_button_disabled') : $r('app.color.color_secondary'))
      .fontColor(Color.White)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .enabled(!this.isSubmitting)
      .onClick(() => { this.submitPost(); })
  }
}
