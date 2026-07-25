/**
 * live_browse - 直播浏览页（spec 3.2.1 / 3.2.4.3）
 *
 * 卖家可观看其他主播直播，学习经营
 * - 顶部导航栏：返回 + 标题 + 排序选项
 * - 直播卡片列表：封面 + 状态标签 + 标题 + 主播信息 + 进入按钮
 * - 卖家端入口在顶部导航"直播"Tab
 */

import { Logger, AppConstants, NavigationHelper, RouteName, PageResult } from 'common';
import { LiveListItem, LiveSortBy } from '../../model/FarmerLiveModels';
import { LiveManageRepository } from '../../repository/LiveManageRepository';

/** 排序选项 */
interface SortOption {
  value: LiveSortBy;
  label: string;
}

/** 跳转直播间页的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface LiveRoomParam {
  liveId: string;
  role: string;
}

@ComponentV2
export struct LiveBrowse {
  /** 直播列表 */
  @Local liveList: LiveListItem[] = [];
  /** 当前页码 */
  @Local page: number = 1;
  /** 排序方式 */
  @Local sortBy: LiveSortBy = 'hot';
  /** 是否正在加载 */
  @Local isLoading: boolean = false;

  /** 排序选项 */
  private sortOptions: SortOption[] = [
    { value: 'hot', label: '热门' },
    { value: 'newest', label: '最新' }
  ];

  async aboutToAppear(): Promise<void> {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'live_browse_appear' });
    await this.loadList();
  }

  /** 加载列表 */
  private async loadList(): Promise<void> {
    this.isLoading = true;
    try {
      const result: PageResult<LiveListItem> = await LiveManageRepository.getLiveList(this.page, 10, this.sortBy);
      if (this.page === 1) {
        this.liveList = result.list;
      } else {
        this.liveList = this.liveList.concat(result.list);
      }
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'load_live_list_fail', error: (err as Error).message });
    } finally {
      this.isLoading = false;
    }
  }

  /** 切换排序 */
  private async onSortChange(s: LiveSortBy): Promise<void> {
    this.sortBy = s;
    this.page = 1;
    await this.loadList();
  }

  /** 进入直播间 */
  private gotoLiveRoom(liveId: string): void {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'goto_live_room', liveId });
    const param: LiveRoomParam = { liveId: liveId, role: 'viewer' };
    NavigationHelper.push(RouteName.FARMER_LIVE_ROOM, param);
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        this.LiveListArea()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 顶部导航栏（返回 + 标题 + 排序选项） */
  @Builder
  TopBar() {
    Row() {
      Text('‹')
        .fontSize(28)
        .fontColor($r('app.color.color_ink'))
        .onClick(() => NavigationHelper.pop())
      Text('直播')
        .fontSize(18)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .margin({ left: 8 })
      ForEach(this.sortOptions, (opt: SortOption) => {
        Text(opt.label)
          .fontSize(12)
          .fontColor(this.sortBy === opt.value ? Color.White : $r('app.color.color_text_secondary'))
          .fontWeight(this.sortBy === opt.value ? FontWeight.Bold : FontWeight.Normal)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(this.sortBy === opt.value ? $r('app.color.color_cta_black') : $r('app.color.color_bg_card'))
          .borderRadius(14)
          .margin({ left: 6 })
          .onClick(() => { this.onSortChange(opt.value); })
      }, (opt: SortOption) => opt.value)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** 直播列表区域 */
  @Builder
  LiveListArea() {
    if (this.liveList.length === 0 && this.isLoading) {
      Column({ space: 8 }) {
        LoadingProgress().width(48).height(48)
        Text('加载中...')
          .fontSize(13)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    } else if (this.liveList.length === 0) {
      // 空状态
      Column({ space: 12 }) {
        Text('📺')
          .fontSize(64)
        Text('暂无直播')
          .fontSize(16)
          .fontColor($r('app.color.color_text_secondary'))
          .fontWeight(FontWeight.Bold)
        Text('直播间空空如也，快去开启你的第一场直播吧')
          .fontSize(13)
          .fontColor($r('app.color.color_text_hint'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Button('去开播')
          .height(40)
          .borderRadius(20)
          .backgroundColor($r('app.color.color_cta_black'))
          .fontColor(Color.White)
          .fontSize(14)
          .padding({ left: 24, right: 24 })
          .margin({ top: 12 })
          .onClick(() => {
            NavigationHelper.push(RouteName.FARMER_LIVE_CREATE);
          })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .padding({ left: 32, right: 32 })
    } else {
      Scroll() {
        Column({ space: 12 }) {
          ForEach(this.liveList, (item: LiveListItem, _idx: number) => {
            this.LiveCard(item)
          }, (item: LiveListItem) => item.liveId)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
  }

  /** 单个直播卡片（封面 + 信息 + 操作） */
  @Builder
  LiveCard(item: LiveListItem) {
    Column({ space: 0 }) {
      // 1. 封面区
      Stack() {
        Column() {
          Text('📹')
            .fontSize(48)
          Text(item.status === 'living' ? '直播中' : (item.status === 'preview' ? '预告' : '回放'))
            .fontSize(14)
            .fontColor(Color.White)
            .margin({ top: 8 })
        }
        .width('100%')
        .height(160)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(item.status === 'living' ? '#1A3A1A' : '#2A2A2A')

        // 直播状态标签（左上）
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
        }

        // 观看人数（左下）
        Row({ space: 4 }) {
          Text('👁')
            .fontSize(10)
          Text(`${item.onlineCount ?? item.totalViewUv}`)
            .fontSize(11)
            .fontColor(Color.White)
        }
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .borderRadius(10)
        .backgroundColor('rgba(0,0,0,0.5)')
        .position({ x: 12, y: 124 })
      }
      .width('100%')
      .height(160)

      // 2. 信息区
      Column({ space: 10 }) {
        // 标题
        Text(item.title)
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Medium)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        // 主播信息
        Row({ space: 8 }) {
          Text('👤')
            .fontSize(16)
          Text(item.farmerName)
            .fontSize(12)
            .fontColor($r('app.color.color_text_secondary'))
            .layoutWeight(1)
          Text(`累计 ${item.totalViewUv}`)
            .fontSize(11)
            .fontColor($r('app.color.color_text_hint'))
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 进入按钮
        Button(item.status === 'living' ? '进入直播间' : (item.status === 'preview' ? '查看预告' : '观看回放'))
          .width('100%')
          .height(36)
          .borderRadius(18)
          .backgroundColor(item.status === 'living' ? $r('app.color.color_cta_black') : $r('app.color.color_text_hint'))
          .fontColor(Color.White)
          .fontSize(13)
          .onClick(() => this.gotoLiveRoom(item.liveId))
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
}
