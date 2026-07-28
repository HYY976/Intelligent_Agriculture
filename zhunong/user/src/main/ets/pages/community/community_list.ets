/**
 * community_list - 社区列表页（排版对齐农户端 community_list.ets）
 *  - 顶部栏：标题"社区" + 搜索图标按钮
 *  - 话题 Tab 栏：横向滚动胶囊（全部/种植技术/销路讨论/乡村生活/互助问答），选中黑底白字
 *  - 排序栏：最新/最热 + 帖子总数
 *  - 帖子列表（List 单列）：作者信息 + 标题 + 内容 + 图片网格 + 互动栏（对齐农户端 PostCard）
 *  - 点击帖子 → 帖子详情页
 *
 * 导出 CommunityContent 供 home_page Tab 内嵌使用
 * 同时作为独立路由（pages/community/community_list）
 */

import { Logger, AppConstants, RouteName, NavigationHelper, ListStateView } from 'common';
import { Topic, PostListItem, PostSortBy } from '../../model/CommunityModels';
import { MOCK_TOPICS } from '../../mock/CommunityMock';
import { CommunityDataSource } from '../../viewmodel/CommunityDataSource';
import { ImageUtil } from '../../utils/ImageUtil';

/** 跳转帖子详情的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface PostDetailParam {
  postId: string;
}

/** 排序选项（对齐农户端 SortOption） */
interface SortOption {
  value: PostSortBy;
  label: string;
}

/** 社区内容组件（可复用于 Tab 与独立页） */
@ComponentV2
export struct CommunityContent {
  /** 当前话题 ID */
  @Local currentTopicId: string = 'all';
  /** 当前排序 */
  @Local sortBy: PostSortBy = 'latest';
  /** 话题列表 */
  @Local topics: Topic[] = MOCK_TOPICS;
  /** 帖子数据源 */
  private postDataSource: CommunityDataSource = new CommunityDataSource();
  /** 帖子总数（@Local 驱动 UI 刷新） */
  @Local postCount: number = 0;
  /** 是否正在加载 */
  @Local isLoadingData: boolean = true;
  /** 是否加载失败 */
  @Local hasLoadFailed: boolean = false;

  /** 排序选项（对齐农户端） */
  private sortOptions: SortOption[] = [
    { value: 'latest', label: '最新' },
    { value: 'hottest', label: '最热' }
  ];

  async aboutToAppear(): Promise<void> {
    await this.refresh();
    Logger.info(AppConstants.SCENE_USER, { action: 'community_list_appear', tab: this.currentTopicId });
  }

  /** 刷新（spec 10.11.4：交由 DataSource.refresh 处理分页/状态） */
  private async refresh(): Promise<void> {
    this.isLoadingData = true;
    this.hasLoadFailed = false;
    try {
      await this.postDataSource.refresh();
      this.postCount = this.postDataSource.totalCount();
      this.hasLoadFailed = this.postDataSource.getLoadFailed();
    } catch (err) {
      Logger.error(AppConstants.SCENE_USER, { action: 'community_list_refresh_fail', error: (err as Error).message });
      this.hasLoadFailed = true;
    } finally {
      this.isLoadingData = false;
    }
  }

  /** 切换话题 */
  private async onTopicChange(topicId: string): Promise<void> {
    this.currentTopicId = topicId;
    const filterTopicId: string | undefined = topicId === 'all' ? undefined : topicId;
    this.postDataSource.setFilter(filterTopicId, undefined, 'latest');
    this.sortBy = 'latest';
    await this.refresh();
    Logger.info(AppConstants.SCENE_USER, { action: 'community_topic_change', topicId: topicId });
  }

  /** 切换排序 */
  private async onSortChange(s: PostSortBy): Promise<void> {
    this.sortBy = s;
    this.postDataSource.setFilter(undefined, undefined, s);
    await this.refresh();
  }

  /** 跳转帖子详情 */
  private gotoPostDetail(postId: string): void {
    const param: PostDetailParam = { postId: postId };
    NavigationHelper.push(RouteName.USER_POST_DETAIL, param);
  }

  /** 跳转搜索页 */
  private gotoSearch(): void {
    NavigationHelper.push(RouteName.USER_SEARCH_PAGE);
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
    Column() {
      // 顶部栏（对齐农户端 qn-topbar：标题 + 搜索图标）
      this.TopBar()
      // 话题 Tab 栏（对齐农户端 TopicTabBar）
      this.TopicTabBar()
      // 排序栏（对齐农户端 SortBar）
      this.SortBar()
      // 帖子列表（对齐农户端 PostList：List 单列）
      this.PostList()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.color_bg_page'))
  }

  /** 顶部栏（对齐农户端 TopBar：标题"社区" + 搜索图标按钮） */
  @Builder
  TopBar() {
    Row({ space: 12 }) {
      Text('社区')
        .fontSize(18)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
      Text('🔍')
        .fontSize(16)
        .fontColor($r('app.color.color_ink'))
        .width(32)
        .height(32)
        .textAlign(TextAlign.Center)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor($r('app.color.color_bg_card'))
        .shadow(AppConstants.SHADOW_CARD)
        .onClick(() => {
          this.gotoSearch();
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
  }

  /** 话题 Tab 栏（对齐农户端 TopicTabBar：横向滚动胶囊，选中黑底白字） */
  @Builder
  TopicTabBar() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.topics, (topic: Topic, _idx: number) => {
          Text(topic.name)
            .fontSize(13)
            .fontColor(this.currentTopicId === topic.topicId ? Color.White : $r('app.color.color_text_2'))
            .backgroundColor(this.currentTopicId === topic.topicId ? $r('app.color.color_ink') : $r('app.color.color_bg_card'))
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

  /** 排序栏（对齐农户端 SortBar：最新/最热 + 帖子总数） */
  @Builder
  SortBar() {
    Row({ space: 16 }) {
      ForEach(this.sortOptions, (opt: SortOption) => {
        Text(opt.label)
          .fontSize(13)
          .fontColor(this.sortBy === opt.value ? $r('app.color.color_ink') : $r('app.color.color_text_2'))
          .fontWeight(this.sortBy === opt.value ? FontWeight.Bold : FontWeight.Normal)
          .onClick(() => { this.onSortChange(opt.value); })
      }, (opt: SortOption) => opt.value)
      Blank()
      Text(`共 ${this.postCount} 条`)
        .fontSize(11)
        .fontColor($r('app.color.color_text_4'))
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 帖子列表（对齐农户端 PostList：List 单列 + LazyForEach） */
  @Builder
  PostList() {
    if (this.hasLoadFailed) {
      ListStateView({ state: 'error', onRefresh: () => this.refresh() })
    } else if (this.isLoadingData) {
      ListStateView({ state: 'loading' })
    } else if (this.postCount === 0) {
      ListStateView({ state: 'empty', emptyUseEmoji: true, emptyEmoji: '💬', emptyText: '暂无帖子' })
    } else {
      List({ space: 12 }) {
        LazyForEach(this.postDataSource, (post: PostListItem, index: number) => {
          ListItem() {
            this.PostCard(post)
          }
          .onClick(() => this.gotoPostDetail(post.postId))
        }, (post: PostListItem) => post.postId + `_${post.likeCount}_${post.commentCount}`)
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

  /** spec 16.12：作者头像渲染 — emoji 用 Text，资源 key 用 Image */
  @Builder
  AuthorAvatar(avatar: string) {
    if (avatar.startsWith('avatar_')) {
      Image(ImageUtil.get(avatar))
        .width(32)
        .height(32)
        .borderRadius(16)
        .objectFit(ImageFit.Cover)
        .backgroundColor($r('app.color.color_yellow_soft'))
    } else {
      Row() {
        Text(avatar)
          .fontSize(18)
      }
      .width(32)
      .height(32)
      .borderRadius(16)
      .backgroundColor($r('app.color.color_yellow_soft'))
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
    }
  }

  /** 帖子卡片（对齐农户端 PostCard：作者信息 + 标题 + 内容 + 图片网格 + 互动栏） */
  @Builder
  PostCard(post: PostListItem) {
    Column({ space: 8 }) {
      // 作者信息行（对齐农户端：头像 32px + 昵称 + 卖家V标 + 时间；spec 16.12：emoji 头像用 Text，资源 key 用 Image）
      Row({ space: 8 }) {
        this.AuthorAvatar(post.authorAvatar)

        Column({ space: 2 }) {
          Row({ space: 4 }) {
            Text(post.authorNickname)
              .fontSize(13)
              .fontColor($r('app.color.color_ink'))
              .fontWeight(FontWeight.Medium)
            // 卖家 V 标（对齐农户端：farmer 作者带黑底白字 V 标）
            if (post.authorType === 'farmer') {
              Text('V')
                .fontSize(9)
                .fontColor(Color.White)
                .backgroundColor($r('app.color.color_ink'))
                .width(14)
                .height(14)
                .borderRadius(7)
                .textAlign(TextAlign.Center)
            }
          }
          Text(this.formatTime(post.createdAt))
            .fontSize(11)
            .fontColor($r('app.color.color_text_4'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      // 帖子标题（对齐农户端：15px Medium，最多2行）
      Text(post.title)
        .fontSize(15)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Medium)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      // 帖子内容预览（对齐农户端：13px，最多3行）
      Text(post.contentPreview)
        .fontSize(13)
        .fontColor($r('app.color.color_text_2'))
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      // 图片网格（对齐农户端：3列，每张80px高，最多展示3张，超3张显示+N）
      if (post.images.length > 0) {
        Grid() {
          ForEach(post.images.slice(0, 3), (img: string, idx: number) => {
            GridItem() {
              Stack() {
                Image(ImageUtil.get(img))
                  .width('100%')
                  .height(80)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(6)
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
              .backgroundColor($r('app.color.color_fill'))
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

      // 互动栏（对齐农户端：👍点赞 + 💬评论 + ⭐收藏 + 🔗分享）
      Row({ space: 16 }) {
        Row({ space: 4 }) {
          Text('👍')
            .fontSize(14)
          Text(`${post.likeCount}`)
            .fontSize(11)
            .fontColor($r('app.color.color_text_4'))
        }
        Row({ space: 4 }) {
          Text('💬')
            .fontSize(14)
          Text(`${post.commentCount}`)
            .fontSize(11)
            .fontColor($r('app.color.color_text_4'))
        }
        Row({ space: 4 }) {
          Text('⭐')
            .fontSize(14)
          Text(`${post.favoriteCount}`)
            .fontSize(11)
            .fontColor($r('app.color.color_text_4'))
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
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
    .onShown(() => {
      // 页面显示时由 CommunityContent 内部 aboutToAppear 处理，此处仅占位
    })
  }
}
