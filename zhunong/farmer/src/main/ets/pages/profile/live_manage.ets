/**
 * live_manage - 直播管理（spec 3.2.4.5）
 *
 * 历史直播列表 + 数据统计
 * - 状态筛选（全部/直播中/预告/已结束）
 * - 数据展示：累计观看 UV / 礼物收入 / 订单收入
 */

import { Logger, AppConstants, LiveStatus, NavigationHelper, ListStateView } from 'common';
import { LiveManageItem, LIVE_STATUS_LABELS } from '../../model/FarmerModels';
import { LiveManageDataSource } from '../../viewmodel/LiveManageDataSource';

/** 状态筛选项 */
interface StatusFilterOption {
  value: string; // 'all' | LiveStatus
  label: string;
}

@ComponentV2
export struct LiveManage {
  /** 列表数据源（spec 10.11.4 Step 3：BaseDataSource + LazyForEach） */
  private dataSource: LiveManageDataSource = new LiveManageDataSource();
  /** 列表是否为空（用于三态空态判断） */
  @Local isEmpty: boolean = true;
  /** 当前状态筛选 */
  @Local statusFilter: string = 'all';

  /** 状态选项 */
  private statusOptions: StatusFilterOption[] = [
    { value: 'all', label: '全部' },
    { value: 'living', label: '直播中' },
    { value: 'preview', label: '预告' },
    { value: 'ended', label: '已结束' }
  ];

  async aboutToAppear(): Promise<void> {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'live_manage_appear' });
    await this.refresh();
  }

  /** 刷新 */
  private async refresh(): Promise<void> {
    this.dataSource.setStatus(this.statusFilter);
    await this.dataSource.refresh();
    this.isEmpty = this.dataSource.totalCount() === 0;
  }

  /** 切换状态筛选 */
  private async onStatusChange(s: string): Promise<void> {
    this.statusFilter = s;
    await this.refresh();
  }

  /** 格式化时间 */
  private formatTime(ts: number | undefined): string {
    if (!ts) {
      return '-';
    }
    const d: Date = new Date(ts);
    const yyyy: number = d.getFullYear();
    const mm: string = `${d.getMonth() + 1}`.padStart(2, '0');
    const dd: string = `${d.getDate()}`.padStart(2, '0');
    const hh: string = `${d.getHours()}`.padStart(2, '0');
    const mi: string = `${d.getMinutes()}`.padStart(2, '0');
    return `${yyyy}-${mm}-${dd} ${hh}:${mi}`;
  }

  /** 计算直播时长（分钟） */
  private calcDuration(start: number | undefined, end: number | undefined): string {
    if (!start || !end) {
      return '-';
    }
    const diff: number = end - start;
    const minutes: number = Math.floor(diff / 60000);
    const hours: number = Math.floor(minutes / 60);
    if (hours > 0) {
      return `${hours}小时${minutes % 60}分钟`;
    }
    return `${minutes}分钟`;
  }

  /** 状态颜色 */
  private statusColor(status: LiveStatus): Resource {
    if (status === 'living') {
      return $r('app.color.color_error');
    } else if (status === 'preview') {
      return $r('app.color.color_secondary');
    }
    return $r('app.color.color_text_hint');
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        this.StatusFilterBar()
        this.LiveList()
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
      Text('直播管理')
        .fontSize(18)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** 状态筛选 */
  @Builder
  StatusFilterBar() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.statusOptions, (opt: StatusFilterOption) => {
          Text(opt.label)
            .fontSize(12)
            .fontColor(this.statusFilter === opt.value ? Color.White : $r('app.color.color_text_secondary'))
            .backgroundColor(this.statusFilter === opt.value ? $r('app.color.color_primary') : $r('app.color.color_bg_card'))
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(14)
            .onClick(() => { this.onStatusChange(opt.value); })
        }, (opt: StatusFilterOption) => opt.value)
      }
      .padding({ left: 12, right: 12 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .height(44)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 直播列表 */
  @Builder
  LiveList() {
    if (this.dataSource.getLoadFailed()) {
      ListStateView({ state: 'error', onRefresh: () => this.refresh() })
    } else if (this.dataSource.getIsFirstLoad()) {
      ListStateView({ state: 'loading' })
    } else if (this.dataSource.totalCount() === 0) {
      ListStateView({ state: 'empty', emptyUseEmoji: true, emptyEmoji: '📹', emptyText: '暂无直播记录' })
    } else {
      List({ space: 12 }) {
        LazyForEach(this.dataSource, (live: LiveManageItem) => {
          ListItem() {
            this.LiveCard(live)
          }
        }, (live: LiveManageItem) => `${live.liveId}_${live.status}_${live.startTime ?? 0}`)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 12, right: 12, top: 8, bottom: 12 })
      .scrollBar(BarState.Off)
      .cachedCount(AppConstants.LIST_CACHED_COUNT)
      .onReachEnd(() => {
        this.dataSource.loadMore();
      })
    }
  }

  /** 直播卡片 */
  @Builder
  LiveCard(live: LiveManageItem) {
    Column({ space: 8 }) {
      Row({ space: 12 }) {
        Text('📹')
          .fontSize(28)
          .width(72)
          .height(72)
          .borderRadius(8)
          .backgroundColor($r('app.color.color_bg_panel_dark'))
          .textAlign(TextAlign.Center)
        Column({ space: 4 }) {
          Text(live.title)
            .fontSize(14)
            .fontColor($r('app.color.color_text_primary'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
          Row({ space: 8 }) {
            Text(LIVE_STATUS_LABELS[live.status])
              .fontSize(11)
              .fontColor(this.statusColor(live.status))
              .fontWeight(FontWeight.Medium)
            Text(`分类：${live.category}`)
              .fontSize(11)
              .fontColor($r('app.color.color_text_hint'))
          }
          .width('100%')
          Text(`开始：${this.formatTime(live.startTime)}`)
            .fontSize(11)
            .fontColor($r('app.color.color_text_hint'))
          Text(`时长：${this.calcDuration(live.startTime, live.endTime)}`)
            .fontSize(11)
            .fontColor($r('app.color.color_text_hint'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      // 数据统计行
      Row() {
        this.StatItem('观看 UV', `${live.totalViewUv}`)
        this.StatItem('礼物收入', `¥${live.totalGiftIncome.toFixed(2)}`)
        this.StatItem('订单收入', `¥${live.totalOrderIncome.toFixed(2)}`)
        this.StatItem('总收入', `¥${(live.totalGiftIncome + live.totalOrderIncome).toFixed(2)}`)
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })
      .borderRadius(8)
      .backgroundColor($r('app.color.color_bg_page'))
      .justifyContent(FlexAlign.SpaceAround)
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 统计项 */
  @Builder
  StatItem(label: string, value: string) {
    Column({ space: 2 }) {
      Text(value)
        .fontSize(12)
        .fontColor($r('app.color.color_price'))
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
      Text(label)
        .fontSize(10)
        .fontColor($r('app.color.color_text_hint'))
    }
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)
  }
}
