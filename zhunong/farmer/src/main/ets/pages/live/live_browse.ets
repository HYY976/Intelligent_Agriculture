/**
 * live_browse - 直播浏览页（spec 3.2.1 / 3.2.4.3 / spec 16.5 完善）
 *
 * 卖家可观看其他主播直播，学习经营
 * - 顶部导航栏：返回 + 标题 + 排序选项 + 我要开播按钮
 * - 我要开播横幅：黄色渐变背景 + 文案 + 立即开播按钮
 * - 直播分类筛选：全部分类 + 5 个分类胶囊
 * - 直播卡片列表：封面 + 状态标签 + 标题 + 主播信息 + 进入按钮
 * - 卖家端入口在顶部导航"直播"Tab
 */

import { Logger, AppConstants, NavigationHelper, RouteName, PageResult, FontUtil, ModeStore } from 'common';
import type { CurrentModeKey } from 'common';
import { LiveListItem, LiveSortBy } from '../../model/FarmerLiveModels';
import { LiveManageRepository } from '../../repository/LiveManageRepository';
import { ImageUtil } from '../../utils/ImageUtil';
import { LiveStatusBroadcaster } from './live_room';

/** 排序选项 */
interface SortOption {
  value: LiveSortBy;
  label: string;
}

/** 分类选项 */
interface CategoryOption {
  value: string;
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
  /** 当前分类筛选 */
  @Local currentCategory: string = 'all';
  /** 当前模式（spec 16.6：老人模式字体放大） */
  @Local modeRef: CurrentModeKey = ModeStore.connectModeRef();

  /** 排序选项 */
  private sortOptions: SortOption[] = [
    { value: 'hot', label: '热门' },
    { value: 'newest', label: '最新' }
  ];

  /** 分类选项（spec 16.5：新增直播分类筛选） */
  private categoryOptions: CategoryOption[] = [
    { value: 'all', label: '全部' },
    { value: 'fresh', label: '生鲜' },
    { value: 'grain', label: '粮油' },
    { value: 'meat', label: '肉禽' },
    { value: 'tea', label: '茶饮' },
    { value: 'other', label: '其他' }
  ];

  async aboutToAppear(): Promise<void> {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'live_browse_appear' });
    await this.loadList();
  }

  /** spec 16.11/16.14：页面再次显示时刷新（新创建直播/结束直播后回到列表同步状态） */
  onPageShow(): void {
    // spec 16.14：重置到第一页并重新加载，确保新创建的直播间能置顶展示
    this.page = 1;
    this.refreshForEndedLives();
    this.loadList();
  }

  /** spec 16.10：将已结束的直播状态从 living 改为 ended（保留列表项，仅切换状态） */
  private refreshForEndedLives(): void {
    let changed: number = 0;
    this.liveList = this.liveList.map((it: LiveListItem): LiveListItem => {
      if (it.status === 'living' && LiveStatusBroadcaster.isEnded(it.liveId)) {
        changed++;
        return {
          liveId: it.liveId,
          title: it.title,
          coverImage: it.coverImage,
          farmerName: it.farmerName,
          farmerAvatar: it.farmerAvatar,
          status: 'ended',
          onlineCount: it.onlineCount,
          totalViewUv: it.totalViewUv,
          category: it.category
        };
      }
      return it;
    });
    if (changed > 0) {
      Logger.info(AppConstants.SCENE_FARMER, {
        action: 'live_list_sync_ended',
        msg: `changed=${changed}`
      });
    }
  }

  /** spec 16.6：当前是否老年大字模式 */
  private isElder(): boolean {
    return FontUtil.isElder(this.modeRef.value);
  }

  /** 加载列表 */
  private async loadList(): Promise<void> {
    this.isLoading = true;
    try {
      const result: PageResult<LiveListItem> = await LiveManageRepository.getLiveList(this.page, 10, this.sortBy);
      let list: LiveListItem[] = result.list;
      // 本地分类筛选
      if (this.currentCategory !== 'all') {
        list = list.filter((it: LiveListItem): boolean => it.category === this.currentCategory);
      }
      if (this.page === 1) {
        this.liveList = list;
      } else {
        this.liveList = this.liveList.concat(list);
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

  /** 切换分类 */
  private async onCategoryChange(c: string): Promise<void> {
    this.currentCategory = c;
    this.page = 1;
    await this.loadList();
  }

  /**
   * 进入直播间
   * spec 16.13：若点击的是当前用户自己创建且仍在直播中的直播，以 broadcaster 身份进入
   */
  private gotoLiveRoom(liveId: string): void {
    const createdLive: LiveListItem | undefined = LiveManageRepository.getCreatedLiveById(liveId);
    const isOwnLiving: boolean = createdLive !== undefined && createdLive.status === 'living';
    const role: string = isOwnLiving ? 'broadcaster' : 'viewer';
    Logger.info(AppConstants.SCENE_FARMER, { action: 'goto_live_room', liveId, role });
    const param: LiveRoomParam = { liveId: liveId, role: role };
    NavigationHelper.push(RouteName.FARMER_LIVE_ROOM, param);
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        // spec 16.9：分类筛选条固定置顶（移出 Scroll），所有分类下内容顶部对齐
        this.CategoryFilter()
        Scroll() {
          Column({ space: 12 }) {
            this.StartLiveBanner()
            this.LiveListArea()
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 0, bottom: 12 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
    .onShown(() => {
      // spec 16.10/16.15：从直播间/创建直播返回后刷新列表，确保新创建的直播间置顶展示
      this.page = 1;
      this.refreshForEndedLives();
      this.loadList();
    })
  }

  /** 顶部导航栏（返回 + 标题 + 排序选项） */
  @Builder
  TopBar() {
    Row() {
      Text('‹')
        .fontSize(FontUtil.s(28, this.isElder()))
        .fontColor($r('app.color.color_ink'))
        .width(32)
        .textAlign(TextAlign.Center)
        .onClick(() => NavigationHelper.pop())
      Text('直播')
        .fontSize(FontUtil.s(20, this.isElder()))
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .margin({ left: 8 })
      ForEach(this.sortOptions, (opt: SortOption) => {
        Text(opt.label)
          .fontSize(FontUtil.s(12, this.isElder()))
          .fontColor(this.sortBy === opt.value ? Color.White : $r('app.color.color_text_secondary'))
          .fontWeight(this.sortBy === opt.value ? FontWeight.Bold : FontWeight.Normal)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(this.sortBy === opt.value ? $r('app.color.color_cta_black') : $r('app.color.color_bg_card'))
          .borderRadius(14)
          .margin({ left: 4 })
          .onClick(() => { this.onSortChange(opt.value); })
      }, (opt: SortOption) => opt.value)
    }
    .width('100%')
    .height(44)
    .padding({ left: 12, right: 12, top: 0, bottom: 0 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** 我要开播横幅（spec 16.5：完善页面，增加开播引导） */
  @Builder
  StartLiveBanner() {
    Row({ space: 12 }) {
      Column({ space: 4 }) {
        Text('开启你的直播')
          .fontSize(FontUtil.s(17, this.isElder()))
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
        Text('展示农产品从田间到餐桌的过程，让买家更信赖')
          .fontSize(FontUtil.s(12, this.isElder()))
          .fontColor('rgba(255,255,255,0.85)')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .lineHeight(18)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      // 立即开播按钮
      Button('立即开播')
        .height(38)
        .borderRadius(19)
        .backgroundColor(Color.White)
        .fontColor($r('app.color.color_live'))
        .fontSize(FontUtil.s(14, this.isElder()))
        .fontWeight(FontWeight.Bold)
        .padding({ left: 18, right: 18 })
        .onClick(() => NavigationHelper.push(RouteName.FARMER_LIVE_CREATE))
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 16, bottom: 16 })
    .borderRadius(16)
    .linearGradient({
      angle: 135,
      colors: [[$r('app.color.color_live'), 0.0], ['#B71C1C', 1.0]]
    })
    .alignItems(VerticalAlign.Center)
  }

  /** 分类筛选条（spec 16.9：固定置顶，所有标签等高对齐，横向可滚动） */
  @Builder
  CategoryFilter() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.categoryOptions, (opt: CategoryOption) => {
          Text(opt.label)
            .fontSize(FontUtil.s(13, this.isElder()))
            .fontColor(this.currentCategory === opt.value ? Color.White : $r('app.color.color_text_secondary'))
            .fontWeight(this.currentCategory === opt.value ? FontWeight.Bold : FontWeight.Normal)
            .padding({ left: 14, right: 14, top: 8, bottom: 8 })
            .height(36)
            .backgroundColor(this.currentCategory === opt.value ? $r('app.color.color_cta_black') : $r('app.color.color_bg_card'))
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
    .padding({ top: 0, bottom: 0 })
    .align(Alignment.Start)
    .backgroundColor($r('app.color.color_bg_page'))
  }

  /** 直播列表区域 */
  @Builder
  LiveListArea() {
    if (this.liveList.length === 0 && this.isLoading) {
      Column({ space: 8 }) {
        LoadingProgress().width(48).height(48)
        Text('加载中...')
          .fontSize(FontUtil.s(13, this.isElder()))
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')
      .padding({ top: 40, bottom: 40 })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    } else if (this.liveList.length === 0) {
      // 空状态
      Column({ space: 12 }) {
        Text('📺')
          .fontSize(64)
        Text('该分类下暂无直播')
          .fontSize(FontUtil.s(16, this.isElder()))
          .fontColor($r('app.color.color_text_secondary'))
          .fontWeight(FontWeight.Bold)
        Text('快去开启你的第一场直播吧')
          .fontSize(FontUtil.s(13, this.isElder()))
          .fontColor($r('app.color.color_text_hint'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Button('去开播')
          .height(40)
          .borderRadius(20)
          .backgroundColor($r('app.color.color_cta_black'))
          .fontColor(Color.White)
          .fontSize(FontUtil.s(14, this.isElder()))
          .padding({ left: 24, right: 24 })
          .margin({ top: 12 })
          .onClick(() => {
            NavigationHelper.push(RouteName.FARMER_LIVE_CREATE);
          })
      }
      .width('100%')
      .padding({ top: 40, bottom: 40 })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    } else {
      Column({ space: 12 }) {
        ForEach(this.liveList, (item: LiveListItem, _idx: number) => {
          this.LiveCard(item)
        }, (item: LiveListItem) => item.liveId)
      }
      .width('100%')
    }
  }

  /** 单个直播卡片（封面 + 信息 + 操作） */
  @Builder
  LiveCard(item: LiveListItem) {
    Column({ space: 0 }) {
      // 1. 封面区
      Stack() {
        // spec 16.8：显示封面图，若有 file:///http(s) URI 则渲染真实图片，否则使用 ImageUtil 解析 Mock 封面 key
        if (item.coverImage.startsWith('file://') || item.coverImage.startsWith('http://') || item.coverImage.startsWith('https://')) {
          Image(item.coverImage)
            .width('100%')
            .height(160)
            .objectFit(ImageFit.Cover)
        } else {
          Image(ImageUtil.get(item.coverImage))
            .width('100%')
            .height(160)
            .objectFit(ImageFit.Cover)
        }

        // 直播状态标签（左上）
        if (item.status === 'living') {
          Row({ space: 4 }) {
            Text('🔴')
              .fontSize(10)
            Text('直播中')
              .fontSize(FontUtil.s(11, this.isElder()))
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
              .fontSize(FontUtil.s(11, this.isElder()))
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
          }
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(10)
          .backgroundColor('rgba(255,152,0,0.85)')
          .position({ x: 12, y: 12 })
        } else if (item.status === 'ended') {
          // spec 16.10：直播结束后状态切换为"已结束"
          Row({ space: 4 }) {
            Text('已结束')
              .fontSize(FontUtil.s(11, this.isElder()))
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
          }
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(10)
          .backgroundColor('rgba(150,150,150,0.85)')
          .position({ x: 12, y: 12 })
        }

        // 观看人数（左下）
        Row({ space: 4 }) {
          Text('👁')
            .fontSize(10)
          Text(`${item.onlineCount ?? item.totalViewUv}`)
            .fontSize(FontUtil.s(11, this.isElder()))
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
          .fontSize(FontUtil.s(15, this.isElder()))
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
            .fontSize(FontUtil.s(13, this.isElder()))
            .fontColor($r('app.color.color_text_secondary'))
            .layoutWeight(1)
          Text(`累计 ${item.totalViewUv}`)
            .fontSize(FontUtil.s(12, this.isElder()))
            .fontColor($r('app.color.color_text_hint'))
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 进入按钮
        Button(item.status === 'living' ? '进入直播间' : (item.status === 'preview' ? '查看预告' : '观看回放'))
          .width('100%')
          .height(40)
          .borderRadius(20)
          .backgroundColor(item.status === 'living' ? $r('app.color.color_cta_black') : $r('app.color.color_text_hint'))
          .fontColor(Color.White)
          .fontSize(FontUtil.s(14, this.isElder()))
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
