/**
 * community_list - 社区列表页（对齐设计稿 user-community.html）
 *  - 顶部栏：标题"社区" + 搜索图标按钮
 *  - 分类 Tab：胶囊形（白底阴影，选中黑底白字）+ 黄色下划线条
 *  - 双列瀑布流笔记：封面图(可变高度) + 标题 + 作者头像 + 点赞数
 *  - 点击笔记 → 帖子详情页
 *
 * 导出 CommunityContent 供 home_page Tab 内嵌使用
 * 同时作为独立路由（pages/community/community_list）
 */

import { Logger, AppConstants, RouteName, NavigationHelper } from 'common';
import { Topic, PostListItem, PostSortBy } from '../../model/CommunityModels';
import { MOCK_TOPICS } from '../../mock/CommunityMock';
import { CommunityDataSource } from '../../viewmodel/CommunityDataSource';
import { ImageUtil } from '../../utils/ImageUtil';

/** 跳转帖子详情的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface PostDetailParam {
  postId: string;
}

/** 分类 Tab 配置项（对齐设计稿 qn-cat-tab） */
interface CategoryTab {
  /** Tab ID */
  tabId: string;
  /** Tab 名称 */
  label: string;
}

/** 社区内容组件（可复用于 Tab 与独立页） */
@ComponentV2
export struct CommunityContent {
  /** 当前分类 Tab */
  @Local currentTab: string = 'recommend';
  /** 帖子数据源 */
  private postDataSource: CommunityDataSource = new CommunityDataSource();
  /** 分类 Tab 列表（对齐设计稿：推荐/关注/附近/助农日记） */
  private readonly categoryTabs: CategoryTab[] = [
    { tabId: 'recommend', label: '推荐' },
    { tabId: 'follow', label: '关注' },
    { tabId: 'nearby', label: '附近' },
    { tabId: 'diary', label: '助农日记' }
  ];

  async aboutToAppear(): Promise<void> {
    await this.postDataSource.refresh();
    Logger.info(AppConstants.SCENE_USER, { action: 'community_list_appear', tab: this.currentTab });
  }

  /** 切换分类 Tab */
  private async onTabChange(tabId: string): Promise<void> {
    this.currentTab = tabId;
    // "关注"和"附近"暂时复用全部数据（Mock 阶段）
    const topicId: string | undefined = tabId === 'diary' ? 't001' : undefined;
    this.postDataSource.setFilter(topicId, undefined, 'latest');
    await this.postDataSource.refresh();
    Logger.info(AppConstants.SCENE_USER, { action: 'community_tab_change', tab: tabId });
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

  build() {
    Column() {
      // 顶部栏（对齐设计稿 qn-topbar：标题 + 搜索图标）
      this.TopBar()

      // 分类 Tab 栏（对齐设计稿 qn-cat-tabs + qn-cat-bar）
      this.CategoryTabBar()

      // 双列瀑布流笔记（对齐设计稿 qn-falls）
      this.WaterfallList()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.color_bg_page'))
  }

  /** 顶部栏（对齐设计稿 qn-topbar：标题"社区" + 搜索图标按钮） */
  @Builder
  TopBar() {
    Row() {
      Text('社区')
        .fontSize(18)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)

      // 搜索图标按钮（对齐设计稿 qn-icon-btn：白底圆 + 软阴影）
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
    .padding({ left: 16, right: 16, top: 4, bottom: 10 })
    .alignItems(VerticalAlign.Center)
  }

  /** 分类 Tab 栏（对齐设计稿 qn-cat-tabs：胶囊形 + 黄色下划线） */
  @Builder
  CategoryTabBar() {
    Column() {
      // Tab 横向滚动
      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.categoryTabs, (tab: CategoryTab) => {
            Text(tab.label)
              .fontSize(13)
              .fontColor(this.currentTab === tab.tabId ? Color.White : $r('app.color.color_text_2'))
              .fontWeight(this.currentTab === tab.tabId ? FontWeight.Bold : FontWeight.Medium)
              .padding({ left: 16, right: 16, top: 7, bottom: 7 })
              .borderRadius(AppConstants.RADIUS_PILL)
              .backgroundColor(this.currentTab === tab.tabId ? $r('app.color.color_ink') : $r('app.color.color_bg_card'))
              .shadow(this.currentTab === tab.tabId ? { radius: 0, color: Color.Transparent, offsetX: 0, offsetY: 0 } : AppConstants.SHADOW_CARD)
              .onClick(() => {
                this.onTabChange(tab.tabId);
              })
          }, (tab: CategoryTab) => tab.tabId)
        }
        .padding({ left: 16, right: 16 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .padding({ top: 2, bottom: 10 })

      // 黄色下划线条（对齐设计稿 qn-cat-bar）
      Row()
        .width('100%')
        .height(3)
        .backgroundColor($r('app.color.color_primary'))
        .borderRadius(AppConstants.RADIUS_PILL)
        .margin({ left: 16, right: 16, bottom: 6 })
    }
    .width('100%')
  }

  /** 双列瀑布流笔记（对齐设计稿 qn-falls：column-count 2 + column-gap 10） */
  @Builder
  WaterfallList() {
    WaterFlow() {
      LazyForEach(this.postDataSource, (item: PostListItem, index: number) => {
        FlowItem() {
          NoteCard({
            item: item,
            onCardClick: (postId: string) => {
              this.gotoPostDetail(postId);
            }
          })
        }
      }, (item: PostListItem) => item.postId + `_${item.likeCount}_${item.commentCount}`)
    }
    .columnsTemplate('1fr 1fr')
    .columnsGap(10)
    .rowsGap(10)
    .padding({ left: 16, right: 16, top: 6, bottom: 16 })
    .width('100%')
    .layoutWeight(1)
    .cachedCount(AppConstants.LIST_CACHED_COUNT)
    .onReachEnd(() => {
      this.postDataSource.loadMore();
    })
  }
}

/**
 * NoteCard - 瀑布流笔记卡片（对齐设计稿 qn-note）
 * 封面图(可变高度) + 标题(2行) + 作者头像 + 点赞数
 */
@ComponentV2
struct NoteCard {
  /** 帖子数据 */
  @Param item: PostListItem | null = null;
  /** 点击回调 */
  @Event onCardClick: (postId: string) => void = () => {};

  build() {
    Column() {
      // 封面图（对齐设计稿 qn-note-cover：可变高度，根据图片原始比例）
      if (this.item && this.item.images.length > 0) {
        Image(ImageUtil.get(this.item.images[0]))
          .width('100%')
          .objectFit(ImageFit.Cover)
          .borderRadius({ topLeft: AppConstants.RADIUS_MD, topRight: AppConstants.RADIUS_MD })
          .backgroundColor($r('app.color.color_fill'))
      } else {
        // 无图笔记：显示默认占位
        Row()
          .width('100%')
          .height(120)
          .backgroundColor($r('app.color.color_fill'))
          .borderRadius({ topLeft: AppConstants.RADIUS_MD, topRight: AppConstants.RADIUS_MD })
      }

      // 笔记内容区（对齐设计稿 qn-note-body）
      Column() {
        // 标题（对齐设计稿 qn-note-title：13px 2行省略）
        Text(this.item ? this.item.title : '')
          .fontSize(13)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Medium)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .lineHeight(18)
          .width('100%')

        // 底部行：头像 + 作者名 + 点赞（对齐设计稿 qn-note-foot）
        Row({ space: 5 }) {
          Image(this.item ? ImageUtil.get(this.item.authorAvatar) : ImageUtil.getDefaultAvatar())
            .width(20)
            .height(20)
            .borderRadius(AppConstants.RADIUS_PILL)
            .objectFit(ImageFit.Cover)

          Text(this.item ? this.item.authorNickname : '')
            .fontSize(11)
            .fontColor($r('app.color.color_text_3'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          // 点赞数（对齐设计稿 qn-note-like）
          Row({ space: 2 }) {
            Text('♥')
              .fontSize(12)
              .fontColor(this.item && this.item.isLiked ? $r('app.color.color_live') : $r('app.color.color_text_3'))
            Text(this.formatCount(this.item ? this.item.likeCount : 0))
              .fontSize(11)
              .fontColor($r('app.color.color_text_3'))
          }
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .margin({ top: 9 })
        .alignItems(VerticalAlign.Center)
      }
      .padding({ left: 10, right: 10, top: 9, bottom: 10 })
    }
    .width('100%')
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_MD)
    .shadow(AppConstants.SHADOW_CARD)
    .clip(true)
    .onClick(() => {
      if (this.item) {
        this.onCardClick(this.item.postId);
      }
    })
  }

  /** 格式化数字（>=10000 显示万） */
  private formatCount(count: number): string {
    if (count >= 10000) {
      return `${(count / 10000).toFixed(1)}万`;
    }
    return `${count}`;
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
  }
}
