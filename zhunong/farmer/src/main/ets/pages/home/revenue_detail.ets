/**
 * revenue_detail - 营收明细列表页
 * 对齐设计稿 pages/revenue-detail.html：
 *  - 顶部导航栏：返回键 + "营收明细"标题 + 隐藏占位
 *  - 筛选栏：时间范围（今日/本月/本年/累计）+ 结算状态（全部/待结算/已结算/已提现）
 *  - 汇总英雄卡：本月营收 ¥12,680.50 + 186笔
 *  - 营收记录列表：每条 = 名称+类型胶囊 | +¥金额 / 买家+订单号 | 状态胶囊+时间
 *
 * spec 3.2.3.3 / 4.1.7
 */

import { Logger, AppConstants, NavigationHelper, ListStateView } from 'common';
import {
  RevenueRecord,
  RevenueRange,
  RevenueRecordStatus,
  RevenueType,
  REVENUE_RANGE_LABELS,
  REVENUE_STATUS_LABELS,
  REVENUE_TYPE_LABELS
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
  /** 列表数据源（spec 10.11.4：BaseDataSource + LazyForEach） */
  private dataSource: RevenueDetailDataSource = new RevenueDetailDataSource();
  /** 列表是否为空 */
  @Local isEmpty: boolean = true;
  /** 当前时间范围 */
  @Local range: RevenueRange = 'month';
  /** 当前状态筛选 */
  @Local statusFilter: RevenueRecordStatus | 'all' = 'all';
  /** 总金额（当前已加载列表汇总） */
  @Local totalAmount: number = 0;
  /** Mock 汇总笔数 */
  @Local totalCount: number = 186;
  /** Mock 汇总金额 */
  @Local summaryAmount: number = 12680.50;

  /** 时间范围选项（对齐设计稿 qn-rev-tag） */
  private rangeOptions: RangeFilterOption[] = [
    { value: 'today', label: '今日' },
    { value: 'month', label: '本月' },
    { value: 'year', label: '本年' },
    { value: 'total', label: '累计' }
  ];

  /** 状态选项（对齐设计稿 qn-rev-tag） */
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

  /** 格式化时间（MM-dd HH:mm） */
  private formatTime(ts: number): string {
    const d: Date = new Date(ts);
    const mm: string = `${d.getMonth() + 1}`.padStart(2, '0');
    const dd: string = `${d.getDate()}`.padStart(2, '0');
    const hh: string = `${d.getHours()}`.padStart(2, '0');
    const mi: string = `${d.getMinutes()}`.padStart(2, '0');
    return `${mm}-${dd} ${hh}:${mi}`;
  }

  /** 获取范围标签 */
  private getRangeLabel(): string {
    return REVENUE_RANGE_LABELS[this.range].replace('营收', '');
  }

  build() {
    NavDestination() {
      Column() {
        // 1. 顶部导航栏
        this.TopBar()
        // 2. 筛选栏
        this.FilterBar()
        // 3. 汇总英雄卡
        this.SummaryHero()
        // 4. 营收记录列表
        this.RecordList()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 顶部导航栏（对齐 qn-topbar：返回键 + 居中标题 + 占位） */
  @Builder
  TopBar() {
    Row() {
      // 返回键（对齐 qn-icon-btn：圆形白底阴影）
      Row() {
        Text('‹')
          .fontSize(22)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .width(32)
      .height(32)
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor($r('app.color.color_bg_card'))
      .shadow(AppConstants.SHADOW_CARD)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => NavigationHelper.pop())

      // 居中标题
      Text('营收明细')
        .fontSize(17)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 占位（保持标题居中）
      Row()
        .width(32)
        .height(32)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 10 })
    .alignItems(VerticalAlign.Center)
  }

  /** 筛选栏（对齐 qn-rev-filter：两行标签） */
  @Builder
  FilterBar() {
    Column({ space: 8 }) {
      // 时间范围
      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.rangeOptions, (opt: RangeFilterOption) => {
            Text(opt.label)
              .fontSize(12)
              .fontColor(this.range === opt.value ? Color.White : $r('app.color.color_text_2'))
              .fontWeight(this.range === opt.value ? FontWeight.Bold : FontWeight.Medium)
              .backgroundColor(this.range === opt.value ? $r('app.color.color_ink') : $r('app.color.color_fill'))
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .borderRadius(AppConstants.RADIUS_PILL)
              .onClick(() => { this.onRangeChange(opt.value); })
          }, (opt: RangeFilterOption) => opt.value)
        }
        .padding({ left: 16, right: 16 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')

      // 结算状态
      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.statusOptions, (opt: StatusFilterOption) => {
            Text(opt.label)
              .fontSize(12)
              .fontColor(this.statusFilter === opt.value ? Color.White : $r('app.color.color_text_2'))
              .fontWeight(this.statusFilter === opt.value ? FontWeight.Bold : FontWeight.Medium)
              .backgroundColor(this.statusFilter === opt.value ? $r('app.color.color_ink') : $r('app.color.color_fill'))
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .borderRadius(AppConstants.RADIUS_PILL)
              .onClick(() => { this.onStatusChange(opt.value); })
          }, (opt: StatusFilterOption) => opt.value)
        }
        .padding({ left: 16, right: 16 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('100%')
    .padding({ top: 4, bottom: 8 })
  }

  /** 汇总英雄卡（对齐 qn-rev-hero：黄色背景 + 营收金额 + 笔数） */
  @Builder
  SummaryHero() {
    Row() {
      // 左侧：标签 + 金额
      Column({ space: 4 }) {
        Text(`${this.getRangeLabel()}营收`)
          .fontSize(12)
          .fontColor('rgba(26,26,26,0.7)')
        Row() {
          Text('¥')
            .fontSize(18)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .margin({ right: 2 })
          Text(this.summaryAmount.toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 }))
            .fontSize(26)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 右侧：笔数胶囊
      Row() {
        Text(`${this.totalCount}`)
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        Text('笔')
          .fontSize(11)
          .fontColor('rgba(26,26,26,0.7)')
          .margin({ left: 1 })
      }
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor('rgba(255,255,255,0.5)')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .margin({ left: 16, right: 16 })
    .borderRadius(AppConstants.RADIUS_LG)
    .linearGradient({
      angle: 135,
      colors: [['#FFE234', 0], ['#FFD93D', 1]]
    })
    .alignItems(VerticalAlign.Center)
  }

  /** 营收记录列表（对齐 qn-rev-list） */
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
        // 列表标题
        ListItem() {
          Row() {
            Text('营收记录')
              .fontSize(16)
              .fontColor($r('app.color.color_ink'))
              .fontWeight(FontWeight.Bold)
            Blank()
            Text(`共 ${this.totalCount} 笔 · 按时间倒序`)
              .fontSize(11)
              .fontColor($r('app.color.color_text_3'))
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 4, bottom: 4 })
        }

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
      .padding({ left: 16, right: 16, top: 4, bottom: 16 })
      .scrollBar(BarState.Off)
      .cachedCount(AppConstants.LIST_CACHED_COUNT)
      .onReachEnd(() => {
        this.dataSource.loadMore();
      })
    }
  }

  /** 单条营收记录卡（对齐 qn-rev-card） */
  @Builder
  RecordCard(record: RevenueRecord) {
    Column({ space: 8 }) {
      // 顶部行：名称 + 类型胶囊 | 金额
      Row() {
        Row({ space: 8 }) {
          Text(record.productTitle ?? '收入')
            .fontSize(14)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          // 类型胶囊
          Text(REVENUE_TYPE_LABELS[record.type])
            .fontSize(10)
            .fontColor(this.getTypeTextColor(record.type))
            .fontWeight(FontWeight.Medium)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(AppConstants.RADIUS_PILL)
            .backgroundColor(this.getTypeBgColor(record.type))
        }
        .layoutWeight(1)
        .alignItems(VerticalAlign.Center)

        // 金额（退款为负）
        Row() {
          Text(record.type === 'refund' ? '-' : '+')
            .fontSize(13)
            .fontColor(record.type === 'refund' ? $r('app.color.color_text_2') : $r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
          Text('¥')
            .fontSize(11)
            .fontColor(record.type === 'refund' ? $r('app.color.color_text_2') : $r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
          Text(record.amount.toFixed(2))
            .fontSize(14)
            .fontColor(record.type === 'refund' ? $r('app.color.color_text_2') : $r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
        }
        .alignItems(VerticalAlign.Bottom)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 底部行：买家+订单号 | 状态胶囊+时间
      Row() {
        Column({ space: 2 }) {
          Text(record.buyerNickname ?? '-')
            .fontSize(11)
            .fontColor($r('app.color.color_text_2'))
          Text(`订单号 #${record.orderId}`)
            .fontSize(11)
            .fontColor($r('app.color.color_text_3'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column({ space: 2 }) {
          // 状态胶囊
          Text(REVENUE_STATUS_LABELS[record.status])
            .fontSize(10)
            .fontColor(this.getStatusTextColor(record.status))
            .fontWeight(FontWeight.Medium)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(AppConstants.RADIUS_PILL)
            .backgroundColor(this.getStatusBgColor(record.status))
          Text(this.formatTime(record.createdAt))
            .fontSize(11)
            .fontColor($r('app.color.color_text_3'))
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .padding(14)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 获取类型文字色 */
  private getTypeTextColor(type: RevenueType): Resource {
    if (type === 'order') {
      return $r('app.color.color_green_deep');
    } else if (type === 'gift') {
      return $r('app.color.color_yellow_text');
    } else if (type === 'refund') {
      return $r('app.color.color_live');
    }
    return $r('app.color.color_text_2');
  }

  /** 获取类型背景色 */
  private getTypeBgColor(type: RevenueType): Resource {
    if (type === 'order') {
      return $r('app.color.color_pill_sale');
    } else if (type === 'gift') {
      return $r('app.color.color_pill_live');
    } else if (type === 'refund') {
      return $r('app.color.color_pill_refund');
    }
    return $r('app.color.color_fill');
  }

  /** 获取状态文字色 */
  private getStatusTextColor(status: RevenueRecordStatus): Resource {
    if (status === 'pending') {
      return $r('app.color.color_warn');
    } else if (status === 'settled') {
      return $r('app.color.color_green_deep');
    }
    return $r('app.color.color_text_2');
  }

  /** 获取状态背景色 */
  private getStatusBgColor(status: RevenueRecordStatus): Resource {
    if (status === 'pending') {
      return $r('app.color.color_pill_pending');
    } else if (status === 'settled') {
      return $r('app.color.color_pill_settled');
    }
    return $r('app.color.color_pill_withdrawn');
  }
}
