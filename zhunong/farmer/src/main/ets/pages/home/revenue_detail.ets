/**
 * revenue_detail - 营收明细列表（spec 3.2.3.3）
 *
 * - 列表项：订单号 + 商品名 + 买家名 + 金额 + 状态 + 下单时间
 * - 支持时间范围筛选（今日/本月/本年/累计）
 * - 支持按状态筛选（待结算/已结算/已提现）
 * - LazyForEach 分页加载
 */

import { Logger, AppConstants, NavigationHelper, ListStateView } from 'common';
import {
  RevenueRecord,
  RevenueRange,
  RevenueRecordStatus,
  REVENUE_RANGE_LABELS,
  REVENUE_STATUS_LABELS
} from '../../model/FarmerModels';
import { RevenueDetailDataSource } from '../../viewmodel/RevenueDetailDataSource';

/** 状态筛选项 */
interface StatusFilterOption {
  value: RevenueRecordStatus | 'all';
  label: string;
}

/** 时间范围筛选项 */
interface RangeFilterOption {
  value: RevenueRange;
  label: string;
}

@ComponentV2
export struct RevenueDetail {
  /** 列表数据源（spec 10.11.4 Step 3：BaseDataSource + LazyForEach） */
  private dataSource: RevenueDetailDataSource = new RevenueDetailDataSource();
  /** 列表是否为空（用于三态空态判断） */
  @Local isEmpty: boolean = true;
  /** 当前时间范围 */
  @Local range: RevenueRange = 'today';
  /** 当前状态筛选 */
  @Local statusFilter: RevenueRecordStatus | 'all' = 'all';
  /** 总金额（当前已加载列表汇总，spec 3.2.3.3 列表头部展示） */
  @Local totalAmount: number = 0;

  /** 时间范围选项 */
  private rangeOptions: RangeFilterOption[] = [
    { value: 'today', label: '今日' },
    { value: 'month', label: '本月' },
    { value: 'year', label: '本年' },
    { value: 'total', label: '累计' }
  ];

  /** 状态选项 */
  private statusOptions: StatusFilterOption[] = [
    { value: 'all', label: '全部' },
    { value: 'pending', label: '待结算' },
    { value: 'settled', label: '已结算' },
    { value: 'withdrawn', label: '已提现' }
  ];

  async aboutToAppear(): Promise<void> {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'revenue_detail_appear' });
    await this.refresh();
  }

  /** 刷新 */
  private async refresh(): Promise<void> {
    this.dataSource.setRange(this.range);
    this.dataSource.setStatus(this.statusFilter);
    await this.dataSource.refresh();
    this.isEmpty = this.dataSource.totalCount() === 0;
    // spec 3.2.3.3：累计当前已加载列表金额，用于头部汇总展示
    const records: RevenueRecord[] = this.dataSource.getRecords();
    this.totalAmount = records.reduce((sum: number, r: RevenueRecord): number => sum + r.amount, 0);
  }

  /** 切换时间范围 */
  private async onRangeChange(r: RevenueRange): Promise<void> {
    this.range = r;
    await this.refresh();
  }

  /** 切换状态 */
  private async onStatusChange(s: RevenueRecordStatus | 'all'): Promise<void> {
    this.statusFilter = s;
    await this.refresh();
  }

  /** 格式化时间 */
  private formatTime(ts: number): string {
    const d: Date = new Date(ts);
    const yyyy: number = d.getFullYear();
    const mm: string = `${d.getMonth() + 1}`.padStart(2, '0');
    const dd: string = `${d.getDate()}`.padStart(2, '0');
    const hh: string = `${d.getHours()}`.padStart(2, '0');
    const mi: string = `${d.getMinutes()}`.padStart(2, '0');
    return `${yyyy}-${mm}-${dd} ${hh}:${mi}`;
  }

  /** 状态颜色 */
  private statusColor(status: RevenueRecordStatus): Resource {
    if (status === 'pending') {
      return $r('app.color.color_secondary');
    } else if (status === 'settled') {
      return $r('app.color.color_primary');
    }
    return $r('app.color.color_text_hint');
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        this.FilterBar()
        this.TotalSummary()
        this.RecordList()
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
      Text('营收明细')
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

  /** 筛选栏 */
  @Builder
  FilterBar() {
    Column({ space: 8 }) {
      // 时间范围
      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.rangeOptions, (opt: RangeFilterOption) => {
            Text(opt.label)
              .fontSize(12)
              .fontColor(this.range === opt.value ? Color.White : $r('app.color.color_text_secondary'))
              .backgroundColor(this.range === opt.value ? $r('app.color.color_primary') : $r('app.color.color_bg_card'))
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .borderRadius(14)
              .onClick(() => { this.onRangeChange(opt.value); })
          }, (opt: RangeFilterOption) => opt.value)
        }
        .padding({ left: 12, right: 12 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      // 状态
      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.statusOptions, (opt: StatusFilterOption) => {
            Text(opt.label)
              .fontSize(12)
              .fontColor(this.statusFilter === opt.value ? Color.White : $r('app.color.color_text_secondary'))
              .backgroundColor(this.statusFilter === opt.value ? $r('app.color.color_secondary') : $r('app.color.color_bg_card'))
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
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 汇总 */
  @Builder
  TotalSummary() {
    Row() {
      Column({ space: 4 }) {
        Text(REVENUE_RANGE_LABELS[this.range])
          .fontSize(12)
          .fontColor($r('app.color.color_text_secondary'))
        Text(`¥${this.totalAmount.toFixed(2)}`)
          .fontSize(20)
          .fontColor($r('app.color.color_price'))
          .fontWeight(FontWeight.Bold)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text(`${this.dataSource.totalCount()} 笔`)
        .fontSize(12)
        .fontColor($r('app.color.color_text_hint'))
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 列表 */
  @Builder
  RecordList() {
    if (this.dataSource.getLoadFailed()) {
      ListStateView({ state: 'error', onRefresh: () => this.refresh() })
    } else if (this.dataSource.getIsFirstLoad()) {
      ListStateView({ state: 'loading' })
    } else if (this.dataSource.totalCount() === 0) {
      ListStateView({ state: 'empty', emptyUseEmoji: true, emptyEmoji: '📭', emptyText: '暂无营收明细' })
    } else {
      List({ space: 8 }) {
        LazyForEach(this.dataSource, (record: RevenueRecord) => {
          ListItem() {
            this.RecordCard(record)
          }
          .onClick(() => {
            Logger.info(AppConstants.SCENE_FARMER, { action: 'record_click', recordId: record.recordId });
          })
        }, (record: RevenueRecord) => `${record.recordId}_${record.status}_${record.createdAt}`)
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

  /** 单条营收明细 */
  @Builder
  RecordCard(record: RevenueRecord) {
    Column({ space: 8 }) {
      Row() {
        Text(record.productTitle ?? '商品')
          .fontSize(14)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        Text(`¥${record.amount.toFixed(2)}`)
          .fontSize(15)
          .fontColor($r('app.color.color_price'))
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      Row() {
        Text(record.type === 'order' ? '订单' : '礼物')
          .fontSize(11)
          .fontColor($r('app.color.color_text_secondary'))
          .backgroundColor($r('app.color.color_bg_page'))
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(4)
        Text(`买家：${record.buyerNickname ?? '-'}`)
          .fontSize(11)
          .fontColor($r('app.color.color_text_secondary'))
          .margin({ left: 8 })
          .layoutWeight(1)
        Text(this.formatTime(record.createdAt))
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')
      Row() {
        Text(`订单号：${record.orderId}`)
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
          .layoutWeight(1)
        Text(REVENUE_STATUS_LABELS[record.status])
          .fontSize(11)
          .fontColor(this.statusColor(record.status))
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
    }
    .width('100%')
    .padding(12)
    .borderRadius(8)
    .backgroundColor($r('app.color.color_bg_card'))
  }
}
