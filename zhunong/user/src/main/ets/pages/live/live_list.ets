﻿﻿﻿﻿﻿/**
 * live_list - 直播浏览页（排版对齐农户端 live_browse.ets）
 *  - 顶部导航栏：返回 + 标题"智农直播" + 排序选项（热门/最新）+ 搜索入口
 *  - 分类筛选条：横向滚动胶囊（全部/生鲜/粮油/肉禽/茶饮/其他），选中黑底白字
 *  - 直播卡片列表（List 单列）：封面(160px) + 状态标签 + 观看人数 + 标题 + 主播信息 + 进入按钮
 *  - 点击进入直播间 pages/live/live_room?liveId=xxx
 * 数据源：LiveDataSource（LazyForEach + IDataSource）
 */

import { RouteName, NavigationHelper, Logger, AppConstants, ListStateView } from 'common';
import { LiveListItem, LiveCategory, getLiveCategoryLabel } from '../../model/LiveModels';
import { LiveStatus } from 'common';
import { LiveDataSource } from '../../viewmodel/LiveDataSource';
import { ImageUtil } from '../../utils/ImageUtil';
import { ReplaceableImage } from '../../components/ReplaceableImage';

/** 跳转直播间的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface LiveRoomParam {
  liveId: string;
}

/** 排序选项（对齐农户端 SortOption） */
interface SortOption {
  value: 'hot' | 'newest';
  label: string;
}

/** 分类选项（对齐农户端 CategoryOption） */
interface CategoryOption {
  value: string;
  label: string;
}

@ComponentV2
export struct LiveList {
  /** 直播列表数据源 */
  private liveDataSource: LiveDataSource = new LiveDataSource();
  /** 当前排序 */
  @Local sortBy: 'hot' | 'newest' = 'hot';
  /** 当前分类筛选 */
  @Local currentCategory: string = 'all';
  /** 帖子总数（@Local 驱动 UI 刷新） */
  @Local liveCount: number = 0;
  /** 是否正在加载 */
  @Local isLoadingData: boolean = true;
  /** 是否加载失败 */
  @Local hasLoadFailed: boolean = false;

  /** 排序选项（对齐农户端：热门/最新） */
  private sortOptions: SortOption[] = [
    { value: 'hot', label: '热门' },
    { value: 'newest', label: '最新' }
  ];

  /** 分类选项（对齐农户端：全部/生鲜/粮油/肉禽/茶饮/其他） */
  private categoryOptions: CategoryOption[] = [
    { value: 'all', label: '全部' },
    { value: 'fresh', label: '生鲜' },
    { value: 'grain', label: '粮油' },
    { value: 'meat', label: '肉禽' },
    { value: 'tea', label: '茶饮' },
    { value: 'other', label: '其他' }
  ];

  async aboutToAppear(): Promise<void> {
    await this.refresh();
    Logger.info(AppConstants.SCENE_USER, { action: 'live_list_appear' });
  }

  /** 刷新（spec 10.11.4：交由 DataSource.refresh 处理分页/状态） */
  private async refresh(): Promise<void> {
    this.isLoadingData = true;
    this.hasLoadFailed = false;
    try {
      await this.liveDataSource.refresh();
      this.liveCount = this.liveDataSource.totalCount();
      this.hasLoadFailed = this.liveDataSource.getLoadFailed();
    } catch (err) {
      Logger.error(AppConstants.SCENE_USER, { action: 'live_list_refresh_fail', error: (err as Error).message });
      this.hasLoadFailed = true;
    } finally {
      this.isLoadingData = false;
    }
  }

  /** 切换排序（对齐农户端 onSortChange） */
  private async onSortChange(s: 'hot' | 'newest'): Promise<void> {
    this.sortBy = s;
    // 重置筛选并刷新
    this.liveDataSource.setFilter(undefined, undefined, undefined);
    await this.refresh();
  }

  /** 切换分类（对齐农户端 onCategoryChange） */
  private async onCategoryChange(c: string): Promise<void> {
    this.currentCategory = c;
    const category: LiveCategory | undefined = c === 'all' ? undefined : c as LiveCategory;
    this.liveDataSource.setFilter(undefined, category, undefined);
    await this.refresh();
  }

  /** 返回上一页 */
  private goBack(): void {
    NavigationHelper.pop();
  }

  /** 跳转搜索页 */
  private gotoSearch(): void {
    NavigationHelper.push(RouteName.USER_SEARCH_PAGE);
  }

  /** 进入直播间 */
  private enterLiveRoom(liveId: string): void {
    const param: LiveRoomParam = { liveId: liveId };
    NavigationHelper.push(RouteName.USER_LIVE_ROOM, param);
  }

  /** 预约直播（Mock） */
  private reserveLive(liveId: string): void {
    Logger.info(AppConstants.SCENE_USER, { action: 'live_reserve', liveId: liveId });
  }

  /** 格式化数字（>=10000 显示万） */
  private formatCount(count: number): string {
    if (count >= 10000) {
      return `${(count / 10000).toFixed(1)}万`;
    }
    return `${count}`;
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        this.CategoryFilter()
        this.LiveListArea()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
    .onShown(() => {
      // 页面显示时刷新（实时同步农户端开播的直播）
      this.refresh();
    })
  }

  /** 顶部导航栏（对齐农户端 TopBar：返回 + 标题 + 排序选项 + 搜索） */
  @Builder
  TopBar() {
    Row() {
      Text('‹')
        .fontSize(28)
        .fontColor($r('app.color.color_ink'))
        .width(32)
        .textAlign(TextAlign.Center)
        .onClick(() => this.goBack())
      Text('智农直播')
        .fontSize(18)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .margin({ left: 8 })
      ForEach(this.sortOptions, (opt: SortOption) => {
        Text(opt.label)
          .fontSize(12)
          .fontColor(this.sortBy === opt.value ? Color.White : $r('app.color.color_text_2'))
          .fontWeight(this.sortBy === opt.value ? FontWeight.Bold : FontWeight.Normal)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(this.sortBy === opt.value ? $r('app.color.color_ink') : $r('app.color.color_bg_card'))
          .borderRadius(14)
          .margin({ left: 4 })
          .onClick(() => { this.onSortChange(opt.value); })
      }, (opt: SortOption) => opt.value)
      Text('🔍')
        .fontSize(16)
        .fontColor($r('app.color.color_ink'))
        .width(32)
        .height(32)
        .textAlign(TextAlign.Center)
        .margin({ left: 8 })
        .onClick(() => this.gotoSearch())
    }
    .width('100%')
    .height(56)
    .padding({ left: 12, right: 12 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** 分类筛选条（对齐农户端 CategoryFilter：横向滚动胶囊，选中黑底白字） */
  @Builder
  CategoryFilter() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.categoryOptions, (opt: CategoryOption) => {
          Text(opt.label)
            .fontSize(13)
            .fontColor(this.currentCategory === opt.value ? Color.White : $r('app.color.color_text_2'))
            .fontWeight(this.currentCategory === opt.value ? FontWeight.Bold : FontWeight.Normal)
            .padding({ left: 14, right: 14, top: 8, bottom: 8 })
            .height(36)
            .backgroundColor(this.currentCategory === opt.value ? $r('app.color.color_ink') : $r('app.color.color_bg_card'))
            .borderRadius(18)
            .textAlign(TextAlign.Center)
            .onClick(() => { this.onCategoryChange(opt.value); })
        }, (opt: CategoryOption) => opt.value)
      }
      .padding({ left: 16, right: 16 })
      .height(36)
      .alignItems(VerticalAlign.Center)
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .height(40)
    .backgroundColor($r('app.color.color_bg_page'))
  }

  /** 直播列表区域（对齐农户端 LiveListArea） */
  @Builder
  LiveListArea() {
    if (this.hasLoadFailed) {
      ListStateView({ state: 'error', onRefresh: () => this.refresh() })
    } else if (this.isLoadingData) {
      ListStateView({ state: 'loading' })
    } else if (this.liveCount === 0) {
      ListStateView({ state: 'empty', emptyUseEmoji: true, emptyEmoji: '📺', emptyText: '该分类下暂无直播' })
    } else {
      List({ space: 12 }) {
        LazyForEach(this.liveDataSource, (item: LiveListItem, index: number) => {
          ListItem() {
            this.LiveCard(item)
          }
        }, (item: LiveListItem) => item.liveId + `_${item.status}_${item.likeCount}`)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 16, right: 16, top: 8, bottom: 12 })
      .scrollBar(BarState.Off)
      .cachedCount(AppConstants.LIST_CACHED_COUNT)
      .onReachEnd(() => {
        this.liveDataSource.loadMore();
      })
    }
  }

  /** 单个直播卡片（对齐农户端 LiveCard：封面 + 状态标签 + 观看人数 + 标题 + 主播信息 + 进入按钮） */
  @Builder
  LiveCard(item: LiveListItem) {
    Column({ space: 0 }) {
      // 1. 封面区（对齐农户端：160px 高 + 状态标签 + 观看人数）
      Stack() {
        ReplaceableImage({ imageKey: item.coverImage, imgWidth: '100%', imgHeight: 160, imgFit: ImageFit.Cover })

        // 直播状态标签（左上，对齐农户端三状态差异化）
        if (item.status === 'living') {
          Row({ space: 4 }) {
            Text('🔴')
              .fontSize(10)
            Text('直播中')
              .fontSize(11)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
          }
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(10)
          .backgroundColor('rgba(244,67,54,0.85)')
          .position({ x: 12, y: 12 })
        } else if (item.status === 'preview') {
          Row({ space: 4 }) {
            Text('预告')
              .fontSize(11)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
          }
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(10)
          .backgroundColor('rgba(255,152,0,0.85)')
          .position({ x: 12, y: 12 })
        } else if (item.status === 'ended') {
          Row({ space: 4 }) {
            Text('已结束')
              .fontSize(11)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
          }
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(10)
          .backgroundColor('rgba(150,150,150,0.85)')
          .position({ x: 12, y: 12 })
        }

        // 观看人数（左下，对齐农户端）
        Row({ space: 4 }) {
          Text('👁')
            .fontSize(10)
          Text(item.status === 'living' ? this.formatCount(item.onlineCount) : this.formatCount(item.totalViewUv))
            .fontSize(11)
            .fontColor(Color.White)
        }
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .borderRadius(10)
        .backgroundColor('rgba(0,0,0,0.5)')
        .position({ x: 12, y: 124 })

        // 分类标签（右下，对齐农户端）
        Text(getLiveCategoryLabel(item.category))
          .fontSize(11)
          .fontColor(Color.White)
          .backgroundColor('rgba(0,0,0,0.4)')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(10)
          .position({ right: 12, bottom: 12 })
      }
      .width('100%')
      .height(160)

      // 2. 信息区（对齐农户端：标题 + 主播信息 + 进入按钮）
      Column({ space: 10 }) {
        // 直播标题
        Text(item.title)
          .fontSize(15)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Medium)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        // 主播信息行（对齐农户端：头像emoji + 昵称 + 累计观看）
        Row({ space: 8 }) {
          Image(ImageUtil.get(item.anchorAvatar))
            .width(24)
            .height(24)
            .borderRadius(12)
            .objectFit(ImageFit.Cover)
            .backgroundColor($r('app.color.color_yellow_soft'))
          Text(item.anchorName)
            .fontSize(13)
            .fontColor($r('app.color.color_text_2'))
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(`累计 ${this.formatCount(item.totalViewUv)}`)
            .fontSize(12)
            .fontColor($r('app.color.color_text_4'))
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 进入按钮（对齐农户端：三状态差异化文案 + 全宽胶囊）
        Text(this.primaryActionLabel(item.status))
          .width('100%')
          .height(40)
          .borderRadius(20)
          .backgroundColor(item.status === 'living' ? $r('app.color.color_ink') : $r('app.color.color_text_4'))
          .fontColor(Color.White)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            if (item.status === 'preview') {
              this.reserveLive(item.liveId);
            } else {
              this.enterLiveRoom(item.liveId);
            }
          })
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 12, bottom: 14 })
      .backgroundColor($r('app.color.color_bg_card'))
    }
    .width('100%')
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.08)', offsetX: 0, offsetY: 2 })
  }

  /** 主操作按钮文案（对齐农户端：三状态差异化） */
  private primaryActionLabel(status: LiveStatus): string {
    if (status === 'living') {
      return '进入直播间';
    }
    if (status === 'preview') {
      return '查看预告';
    }
    return '观看回放';
  }
}
