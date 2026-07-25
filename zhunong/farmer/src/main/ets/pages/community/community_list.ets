/**
 * community_list - 社区列表（spec 3.2.4.2）
 *
 * 与用户端社区互通（共用同一套社区数据）
 * 卖家可发布答疑、回复买家帖子
 * 卖家发帖时昵称带"卖家"标识（橙色V标）
 * 其余结构与用户端社区一致（话题Tab + 最新/最热排序 + 无限嵌套评论）
 */

import { Logger, AppConstants, FarmerRoutes, NavigationHelper, RouteName, PageResult, ListStateView } from 'common';
import { Post, Topic, PostSortBy } from '../../model/FarmerCommunityModels';
import { CommunityRepository } from '../../repository/CommunityRepository';
import { FarmerCommunityListDataSource } from '../../viewmodel/FarmerCommunityListDataSource';
import { PRESET_TOPICS } from '../../model/FarmerCommunityModels';

/** 排序选项 */
interface SortOption {
  value: PostSortBy;
  label: string;
}

/** 跳转帖子详情页的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface PostDetailParam {
  postId: string;
}

@ComponentV2
export struct CommunityList {
  /** 帖子数据源（spec 10.11.4 Step 3：LazyForEach 替代 ForEach） */
  private postDataSource: FarmerCommunityListDataSource = new FarmerCommunityListDataSource();
  /** 列表是否为空 */
  @Local isEmpty: boolean = true;
  /** 当前话题 ID */
  @Local currentTopicId: string = 't0';
  /** 当前排序 */
  @Local sortBy: PostSortBy = 'latest';
  /** 话题列表 */
  @Local topics: Topic[] = PRESET_TOPICS;

  /** 排序选项 */
  private sortOptions: SortOption[] = [
    { value: 'latest', label: '最新' },
    { value: 'hot', label: '最热' }
  ];

  async aboutToAppear(): Promise<void> {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'community_list_appear' });
    this.postDataSource.setFilter(this.currentTopicId, this.sortBy);
    // 首次加载数据，使用 try-catch 确保异常不会阻塞渲染
    try {
      await this.refresh();
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'community_list_init_fail', error: (err as Error).message });
    }
  }

  /** 页面显示时刷新数据（解决从发帖页返回后列表不更新的问题） */
  async onPageShow(): Promise<void> {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'community_list_onPageShow' });
    try {
      await this.refresh();
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'community_list_onPageShow_fail', error: (err as Error).message });
    }
  }

  /** 刷新（spec 10.11.4 Step 3：交由 DataSource.refresh 处理分页/状态） */
  private async refresh(): Promise<void> {
    await this.postDataSource.refresh();
    this.isEmpty = this.postDataSource.totalCount() === 0;
  }

  /** 切换话题 */
  private async onTopicChange(topicId: string): Promise<void> {
    this.currentTopicId = topicId;
    this.postDataSource.setFilter(topicId, undefined);
    await this.refresh();
  }

  /** 切换排序 */
  private async onSortChange(s: PostSortBy): Promise<void> {
    this.sortBy = s;
    this.postDataSource.setFilter(undefined, s);
    await this.refresh();
  }

  /** 跳转帖子详情 */
  private gotoPostDetail(postId: string): void {
    const param: PostDetailParam = { postId: postId };
    NavigationHelper.push(RouteName.FARMER_POST_DETAIL, param);
  }

  /** 跳转发帖页 */
  private gotoPostCreate(): void {
    NavigationHelper.push(RouteName.FARMER_POST_CREATE);
  }

  /** 格式化时间 */
  private formatTime(ts: number): string {
    const d: Date = new Date(ts);
    const now: number = Date.now();
    const diff: number = now - ts;
    if (diff < 60000) {
      return '刚刚';
    } else if (diff < 3600000) {
      return `${Math.floor(diff / 60000)}分钟前`;
    } else if (diff < 86400000) {
      return `${Math.floor(diff / 3600000)}小时前`;
    }
    return `${d.getMonth() + 1}-${d.getDate()}`;
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        this.TopicTabBar()
        this.SortBar()
        this.PostList()
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
      Text('社区')
        .fontSize(18)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
      Text('✏️')
        .fontSize(22)
        .onClick(() => this.gotoPostCreate())
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** 话题 Tab */
  @Builder
  TopicTabBar() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.topics, (topic: Topic, _idx: number) => {
          Text(topic.name)
            .fontSize(13)
            .fontColor(this.currentTopicId === topic.topicId ? Color.White : $r('app.color.color_text_secondary'))
            .backgroundColor(this.currentTopicId === topic.topicId ? $r('app.color.color_cta_black') : $r('app.color.color_bg_card'))
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(14)
            .onClick(() => { this.onTopicChange(topic.topicId); })
        }, (topic: Topic) => topic.topicId)
      }
      .padding({ left: 12, right: 12 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .height(40)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 排序栏 */
  @Builder
  SortBar() {
    Row({ space: 16 }) {
      ForEach(this.sortOptions, (opt: SortOption) => {
        Text(opt.label)
          .fontSize(13)
          .fontColor(this.sortBy === opt.value ? $r('app.color.color_cta_black') : $r('app.color.color_text_secondary'))
          .fontWeight(this.sortBy === opt.value ? FontWeight.Bold : FontWeight.Normal)
          .onClick(() => { this.onSortChange(opt.value); })
      }, (opt: SortOption) => opt.value)
      Blank()
      Text(`共 ${this.postDataSource.totalCount()} 条`)
        .fontSize(11)
        .fontColor($r('app.color.color_text_hint'))
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 帖子列表 */
  @Builder
  PostList() {
    if (this.postDataSource.getLoadFailed()) {
      ListStateView({ state: 'error', onRefresh: () => this.refresh() })
    } else if (this.postDataSource.getIsFirstLoad()) {
      ListStateView({ state: 'loading' })
    } else if (this.postDataSource.totalCount() === 0) {
      ListStateView({ state: 'empty', emptyUseEmoji: true, emptyEmoji: '💬', emptyText: '暂无帖子' })
    } else {
      List({ space: 12 }) {
        LazyForEach(this.postDataSource, (post: Post, index: number) => {
          ListItem() {
            this.PostCard(post)
          }
          .onClick(() => this.gotoPostDetail(post.postId))
        }, (post: Post) => post.postId + `_${post.likeCount}_${post.commentCount}`)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 12, right: 12, top: 8, bottom: 12 })
      .scrollBar(BarState.Off)
      .cachedCount(AppConstants.LIST_CACHED_COUNT)
      .onReachEnd(() => {
        this.postDataSource.loadMore();
      })
    }
  }

  /** 帖子卡片 */
  @Builder
  PostCard(post: Post) {
    Column({ space: 8 }) {
      // 作者信息
      Row({ space: 8 }) {
        Text('👤')
          .fontSize(20)
          .width(32)
          .height(32)
          .borderRadius(16)
          .backgroundColor($r('app.color.color_card_yellow'))
          .textAlign(TextAlign.Center)
        Column({ space: 2 }) {
          Row({ space: 4 }) {
            Text(post.authorNickname ?? '匿名')
              .fontSize(13)
              .fontColor($r('app.color.color_text_primary'))
              .fontWeight(FontWeight.Medium)
            // 卖家 V 标
            if (post.isSeller === true) {
              Text('V')
                .fontSize(9)
                .fontColor(Color.White)
                .backgroundColor($r('app.color.color_cta_black'))
                .width(14)
                .height(14)
                .borderRadius(7)
                .textAlign(TextAlign.Center)
            }
          }
          Text(this.formatTime(post.createdAt))
            .fontSize(11)
            .fontColor($r('app.color.color_text_hint'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      // 帖子标题
      Text(post.title)
        .fontSize(15)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      // 帖子内容
      Text(post.content)
        .fontSize(13)
        .fontColor($r('app.color.color_text_secondary'))
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      // 图片网格（最多展示3张）
      if (post.images.length > 0) {
        Grid() {
          ForEach(post.images.slice(0, 3), (img: string, idx: number) => {
            GridItem() {
              Stack() {
                Text('🖼')
                  .fontSize(20)
                if (idx === 2 && post.images.length > 3) {
                  Text(`+${post.images.length - 3}`)
                    .fontSize(12)
                    .fontColor(Color.White)
                    .backgroundColor('rgba(0,0,0,0.5)')
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .borderRadius(8)
                    .position({ x: 60, y: 4 })
                }
              }
              .width('100%')
              .height(80)
              .borderRadius(6)
              .backgroundColor($r('app.color.color_bg_page'))
              .alignContent(Alignment.Center)
            }
          }, (img: string, idx: number) => `${img}_${idx}`)
        }
        .columnsTemplate('1fr 1fr 1fr')
        .columnsGap(6)
        .rowsGap(6)
        .width('100%')
        .height(80)
      }

      // 互动栏
      Row({ space: 16 }) {
        Row({ space: 4 }) {
          Text('👍')
            .fontSize(14)
          Text(`${post.likeCount}`)
            .fontSize(11)
            .fontColor($r('app.color.color_text_hint'))
        }
        Row({ space: 4 }) {
          Text('💬')
            .fontSize(14)
          Text(`${post.commentCount}`)
            .fontSize(11)
            .fontColor($r('app.color.color_text_hint'))
        }
        Row({ space: 4 }) {
          Text('⭐')
            .fontSize(14)
          Text(`${post.favoriteCount}`)
            .fontSize(11)
            .fontColor($r('app.color.color_text_hint'))
        }
        Blank()
        Text('🔗')
          .fontSize(14)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }
}
