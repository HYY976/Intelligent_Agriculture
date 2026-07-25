/**
 * live_browse - 直播浏览页（spec 3.2.1 / 3.2.4.3）
 *
 * 与用户端直播浏览页相同（仿抖音短视频直播架构）
 * 卖家可观看其他主播直播，学习经营
 * - 全屏 Swiper 上下滑切换直播
 * - 当前在线 + 累计观看 + 主播信息 + 商品袋
 * - 卖家端入口在顶部导航"直播"Tab
 */

import { Logger, AppConstants, FarmerRoutes, NavigationHelper, RouteName, PageResult } from 'common';
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
      Stack() {
        // 全屏直播卡片 Swiper
        if (this.liveList.length === 0 && this.isLoading) {
          Column({ space: 8 }) {
            LoadingProgress().width(48).height(48)
            Text('加载中...')
              .fontSize(12)
              .fontColor(Color.White)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else if (this.liveList.length === 0) {
          // spec 15.6.4：空状态增加引导文案 + 主 CTA 按钮
          Column({ space: 12 }) {
            Text('📺')
              .fontSize(64)
            Text('暂无直播')
              .fontSize(18)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
            Text('直播间空空如也，快去开启你的第一场直播吧')
              .fontSize(13)
              .fontColor('rgba(255,255,255,0.7)')
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
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .padding({ left: 32, right: 32 })
        } else {
          Swiper() {
            ForEach(this.liveList, (item: LiveListItem, _idx: number) => {
              this.LiveCard(item)
            }, (item: LiveListItem) => item.liveId)
          }
          .vertical(true)
          .indicator(false)
          .width('100%')
          .height('100%')
        }

        // 顶部返回 + 排序栏（绝对定位浮层）
        Column() {
          Row() {
            Text('‹')
              .fontSize(28)
              .fontColor(Color.White)
              .onClick(() => NavigationHelper.pop())
            Blank()
            ForEach(this.sortOptions, (opt: SortOption) => {
              Text(opt.label)
                .fontSize(12)
                .fontColor(this.sortBy === opt.value ? $r('app.color.color_text_primary') : 'rgba(255,255,255,0.6)')
                .fontWeight(this.sortBy === opt.value ? FontWeight.Bold : FontWeight.Normal)
                .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                .backgroundColor(this.sortBy === opt.value ? $r('app.color.color_card_yellow') : 'rgba(0,0,0,0.3)')
                .borderRadius(14)
                .margin({ left: 6 })
                .onClick(() => { this.onSortChange(opt.value); })
            }, (opt: SortOption) => opt.value)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        }
        .width('100%')
        .align(Alignment.Top)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#000000')
    }
    .hideTitleBar(true)
  }

  /** 单个直播全屏卡片（仿抖音） */
  @Builder
  LiveCard(item: LiveListItem) {
    Stack() {
      // 背景封面图
      Column() {
        Text('📹')
          .fontSize(120)
        Text(item.status === 'living' ? '直播中' : (item.status === 'preview' ? '预告' : '回放'))
          .fontSize(16)
          .fontColor(Color.White)
          .margin({ top: 12 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(item.status === 'living' ? '#1A3A1A' : '#2A2A2A')

      // 顶部标签：直播状态
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
        .backgroundColor('rgba(244,67,54,0.8)')
        .position({ x: 16, y: 64 })
      }

      // 右侧操作栏（仿抖音）spec 15.6.4：商品袋入口改黄色
      Column({ space: 24 }) {
        Column({ space: 4 }) {
          Text('👁')
            .fontSize(28)
          Text(`${item.onlineCount ?? item.totalViewUv}`)
            .fontSize(11)
            .fontColor(Color.White)
        }
        .alignItems(HorizontalAlign.Center)
        Column({ space: 4 }) {
          Text('👍')
            .fontSize(28)
          Text(`${Math.floor(item.totalViewUv / 10)}`)
            .fontSize(11)
            .fontColor(Color.White)
        }
        .alignItems(HorizontalAlign.Center)
        // 商品袋入口 spec 15.6.4：黄色背景 + 黑字
        Column({ space: 4 }) {
          Text('🛒')
            .fontSize(28)
          Text('商品袋')
            .fontSize(11)
            .fontColor($r('app.color.color_text_primary'))
        }
        .alignItems(HorizontalAlign.Center)
        .padding({ left: 8, right: 8, top: 6, bottom: 6 })
        .borderRadius(24)
        .backgroundColor($r('app.color.color_card_yellow'))
      }
      .position({ x: '85%', y: '40%' })
      .alignItems(HorizontalAlign.Center)

      // 底部主播信息 + 商品袋入口
      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Text('👤')
            .fontSize(28)
            .width(40)
            .height(40)
            .borderRadius(20)
            .backgroundColor($r('app.color.color_cta_black'))
            .textAlign(TextAlign.Center)
          Column({ space: 2 }) {
            Text(item.farmerName)
              .fontSize(14)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Medium)
            Text(`累计观看 ${item.totalViewUv}`)
              .fontSize(11)
              .fontColor('rgba(255,255,255,0.7)')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Button('+ 关注')
            .height(28)
            .borderRadius(14)
            .backgroundColor($r('app.color.color_card_yellow'))
            .fontColor($r('app.color.color_text_primary'))
            .fontSize(11)
            .padding({ left: 12, right: 12 })
        }
        .width('100%')

        Text(item.title)
          .fontSize(13)
          .fontColor(Color.White)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Button(item.status === 'living' ? '进入直播间' : (item.status === 'preview' ? '查看预告' : '观看回放'))
          .width('100%')
          .height(40)
          .borderRadius(20)
          .backgroundColor($r('app.color.color_cta_black'))
          .fontColor(Color.White)
          .fontSize(13)
          .onClick(() => this.gotoLiveRoom(item.liveId))
      }
      .width('100%')
      .padding({ left: 16, right: 80, bottom: 24 })
      .align(Alignment.Bottom)
    }
    .width('100%')
    .height('100%')
  }
}
