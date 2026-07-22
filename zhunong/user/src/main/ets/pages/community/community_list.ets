/**
 * community_list - 社区列表页（Tab 内嵌 + 独立路由双用）
 * 遵循 spec 3.1.3.2：
 *  - 顶部话题分类 Tab（横向滚动）：全部/种植技术/销路讨论/乡村生活/互助问答
 *  - 排序切换：最新/最热
 *  - 帖子列表：单列卡片流，LazyForEach + IDataSource + 分页
 *  - 帖子卡片：作者头像+昵称+发布时间+话题标签+标题+内容预览(2行)+图片九宫格(前3)+点赞/评论/收藏数
 *  - 右下角悬浮"+"按钮 → 发帖页
 *  - 点击帖子卡片 → 帖子详情页
 *
 * 导出 CommunityContent 供 home_page Tab 内嵌使用
 * 同时作为独立路由（pages/community/community_list）
 */

import { Logger, AppConstants, UserRoutes, ToastUtil, RouteName, NavigationHelper } from 'common';
import { Topic, PostListItem, PostSortBy } from '../../model/CommunityModels';
import { MOCK_TOPICS } from '../../mock/CommunityMock';
import { CommunityDataSource } from '../../viewmodel/CommunityDataSource';
import { ImageUtil } from '../../utils/ImageUtil';

/** 跳转帖子详情的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface PostDetailParam {
  postId: string;
}

/** 社区内容组件（可复用于 Tab 与独立页） */
@ComponentV2
export struct CommunityContent {
  /** 当前话题 ID */
  @Local currentTopicId: string = 'all';
  /** 当前排序 */
  @Local currentSortBy: PostSortBy = 'latest';
  /** 是否下拉刷新 */
  @Local isRefreshing: boolean = false;
  /** 帖子数据源 */
  private postDataSource: CommunityDataSource = new CommunityDataSource();
  /** 话题列表 */
  private topics: Topic[] = MOCK_TOPICS;

  async aboutToAppear(): Promise<void> {
    await this.postDataSource.refresh();
    Logger.info(AppConstants.SCENE_USER, { action: 'community_list_appear' });
  }

  /** 切换话题 */
  private async onTopicChange(topicId: string): Promise<void> {
    this.currentTopicId = topicId;
    this.postDataSource.setFilter(topicId, undefined, this.currentSortBy);
    await this.postDataSource.refresh();
  }

  /** 切换排序 */
  private async onSortChange(): Promise<void> {
    this.currentSortBy = this.currentSortBy === 'latest' ? 'hottest' : 'latest';
    this.postDataSource.setFilter(undefined, undefined, this.currentSortBy);
    await this.postDataSource.refresh();
  }

  /** 下拉刷新 */
  private async onRefresh(): Promise<void> {
    this.isRefreshing = true;
    await this.postDataSource.refresh();
    this.isRefreshing = false;
  }

  /** 跳转帖子详情 */
  private gotoPostDetail(postId: string): void {
    const param: PostDetailParam = { postId: postId };
    NavigationHelper.push(RouteName.USER_POST_DETAIL, param);
  }

  /** 跳转发帖页 */
  private gotoPostCreate(): void {
    NavigationHelper.push(RouteName.USER_POST_CREATE);
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        // 顶部话题 Tab + 排序按钮
        this.TopicBar()
        // 帖子列表
        Refresh({ refreshing: $$this.isRefreshing }) {
          List({ space: 12 }) {
            LazyForEach(this.postDataSource, (item: PostListItem, index: number) => {
              ListItem() {
                PostCard({
                  item: item,
                  onCardClick: (postId: string) => {
                    this.gotoPostDetail(postId);
                  }
                })
              }
            }, (item: PostListItem) => item.postId + `_${item.likeCount}_${item.commentCount}`)
          }
          .width('100%')
          .height('100%')
          .padding({ left: 12, right: 12, top: 8, bottom: 80 })
          .cachedCount(AppConstants.LIST_CACHED_COUNT)
          .onReachEnd(() => {
            this.postDataSource.loadMore();
          })
        }
        .onRefreshing(() => {
          this.onRefresh();
        })
        .layoutWeight(1)
        .width('100%')
      }
      .width('100%')
      .height('100%')

      // 右下角悬浮发帖按钮
      Text('+')
        .fontSize(32)
        .fontColor(Color.White)
        .width(56)
        .height(56)
        .borderRadius(28)
        .backgroundColor($r('app.color.color_primary'))
        .textAlign(TextAlign.Center)
        .shadow({ radius: 12, color: 'rgba(76,175,80,0.4)', offsetX: 0, offsetY: 4 })
        .margin({ right: 20, bottom: 24 })
        .onClick(() => {
          this.gotoPostCreate();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.color_bg_page'))
  }

  /** 顶部话题 Tab + 排序按钮 */
  @Builder
  TopicBar() {
    Row({ space: 8 }) {
      // 话题横向滚动 Tab
      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.topics, (topic: Topic) => {
            Text(topic.name)
              .fontSize(13)
              .fontColor(this.currentTopicId === topic.topicId ? Color.White : $r('app.color.color_text_primary'))
              .backgroundColor(this.currentTopicId === topic.topicId ? $r('app.color.color_primary') : $r('app.color.color_bg_card'))
              .padding({ left: 14, right: 14, top: 6, bottom: 6 })
              .borderRadius(16)
              .onClick(() => {
                this.onTopicChange(topic.topicId);
              })
          }, (topic: Topic) => topic.topicId)
        }
        .padding({ left: 12, right: 12 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .layoutWeight(1)

      // 排序按钮
      Row({ space: 4 }) {
        Text(this.currentSortBy === 'latest' ? '最新' : '最热')
          .fontSize(12)
        Text(this.currentSortBy === 'latest' ? '🕐' : '🔥')
          .fontSize(13)
      }
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .borderRadius(16)
      .backgroundColor($r('app.color.color_bg_card'))
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.onSortChange();
      })
    }
    .width('100%')
    .height(48)
    .padding({ left: 8, right: 12 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }
}

/**
 * PostCard - 帖子卡片组件（单列卡片流）
 * spec 3.1.3.2：作者头像+昵称+发布时间+话题标签+标题+内容预览(2行)+图片九宫格(前3)+互动数
 */
@ComponentV2
struct PostCard {
  /** 帖子数据 */
  @Param item: PostListItem | null = null;
  /** 点击回调 */
  @Event onCardClick: (postId: string) => void = () => {};

  build() {
    Column({ space: 10 }) {
      // 作者信息行
      Row({ space: 8 }) {
        Image(this.item ? ImageUtil.get(this.item.authorAvatar) : ImageUtil.getDefaultAvatar())
          .width(36)
          .height(36)
          .borderRadius(18)
        Column({ space: 2 }) {
          Row({ space: 4 }) {
            Text(this.item ? this.item.authorNickname : '')
              .fontSize(13)
              .fontColor($r('app.color.color_text_primary'))
              .fontWeight(FontWeight.Medium)
            // 卖家标识（橙色 V 标）
            if (this.item && this.item.authorType === 'farmer') {
              Text('卖')
                .fontSize(9)
                .fontColor(Color.White)
                .backgroundColor($r('app.color.color_secondary'))
                .padding({ left: 3, right: 3, top: 1, bottom: 1 })
                .borderRadius(3)
            }
          }
          .alignItems(VerticalAlign.Center)
          Text(this.item ? this.formatTime(this.item.createdAt) : '')
            .fontSize(11)
            .fontColor($r('app.color.color_text_hint'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        // 话题标签
        if (this.item) {
          Text(`#${this.item.topicName}`)
            .fontSize(11)
            .fontColor($r('app.color.color_primary'))
            .backgroundColor('rgba(76,175,80,0.1)')
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .borderRadius(10)
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 帖子标题
      Text(this.item ? this.item.title : '')
        .fontSize(15)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Bold)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 内容预览（2行）
      Text(this.item ? this.item.contentPreview : '')
        .fontSize(13)
        .fontColor($r('app.color.color_text_secondary'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .lineHeight(20)

      // 图片九宫格（列表展示前3张）
      if (this.item && this.item.images.length > 0) {
        this.ImageGrid(this.item.images)
      }

      // 互动数据栏
      Row({ space: 16 }) {
        this.InteractionItem('❤️', this.item ? this.item.likeCount : 0, this.item ? this.item.isLiked : false)
        this.InteractionItem('💬', this.item ? this.item.commentCount : 0, false)
        this.InteractionItem('⭐', this.item ? this.item.favoriteCount : 0, this.item ? this.item.isFavorited : false)
        Blank()
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      if (this.item) {
        this.onCardClick(this.item.postId);
      }
    })
  }

  /** 图片九宫格（列表展示前3张缩略） */
  @Builder
  ImageGrid(images: string[]) {
    Row({ space: 6 }) {
      ForEach(images.slice(0, 3), (imgKey: string, idx: number) => {
        Stack({ alignContent: Alignment.Bottom }) {
          Image(ImageUtil.get(imgKey))
            .width(96)
            .height(96)
            .borderRadius(8)
            .objectFit(ImageFit.Cover)
          // 第3张若超过3张，显示+N
          if (idx === 2 && images.length > 3) {
            Column()
              .width(96)
              .height(96)
              .borderRadius(8)
              .backgroundColor('rgba(0,0,0,0.5)')
            Text(`+${images.length - 3}`)
              .fontSize(20)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
              .position({ right: 30, bottom: 30 })
          }
        }
        .width(96)
        .height(96)
      }, (imgKey: string, idx: number) => imgKey + idx)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  /** 互动项 */
  @Builder
  InteractionItem(icon: string, count: number, isActive: boolean) {
    Row({ space: 4 }) {
      Text(icon)
        .fontSize(14)
      Text(this.formatCount(count))
        .fontSize(12)
        .fontColor(isActive ? $r('app.color.color_primary') : $r('app.color.color_text_secondary'))
    }
    .alignItems(VerticalAlign.Center)
  }

  /** 格式化数字（>=10000 显示万） */
  private formatCount(count: number): string {
    if (count >= 10000) {
      return `${(count / 10000).toFixed(1)}万`;
    }
    return `${count}`;
  }

  /** 格式化时间（x分钟前/x小时前/x天前） */
  private formatTime(timestamp: number): string {
    const diff: number = Date.now() - timestamp;
    const minutes: number = Math.floor(diff / 60000);
    if (minutes < 1) {
      return '刚刚';
    }
    if (minutes < 60) {
      return `${minutes}分钟前`;
    }
    const hours: number = Math.floor(minutes / 60);
    if (hours < 24) {
      return `${hours}小时前`;
    }
    const days: number = Math.floor(hours / 24);
    if (days < 30) {
      return `${days}天前`;
    }
    const date: Date = new Date(timestamp);
    return `${date.getMonth() + 1}月${date.getDate()}日`;
  }
}

/** 独立路由入口（pages/community/community_list） */
@ComponentV2
export struct CommunityList {
  build() {
    NavDestination() {
      Column() {
        CommunityContent()
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
  }
}
