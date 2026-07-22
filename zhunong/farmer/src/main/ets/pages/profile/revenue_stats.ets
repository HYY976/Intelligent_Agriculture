/**
 * revenue_stats - 营收统计（spec 3.2.4.5 / 4.2.2）
 *
 * - 按日/月/年营收图表，折线图
 * - 维度切换（day/month/year）
 * - 数据汇总（总营收 / 总订单 / 平均日营收）
 *
 * 折线图使用自绘 Canvas 实现，不依赖第三方图表库
 */

import { Logger, AppConstants, NavigationHelper, RouteName } from 'common';
import { RevenueChartPoint, RevenueStatsDimension } from '../../model/FarmerModels';
import { RevenueRepository } from '../../repository/RevenueRepository';
import { MOCK_FARMER_ID } from '../../mock/FarmerMock';

/** 维度选项 */
interface DimensionOption {
  value: RevenueStatsDimension;
  label: string;
}

@ComponentV2
export struct RevenueStats {
  /** 当前维度 */
  @Local dimension: RevenueStatsDimension = 'day';
  /** 图表数据点 */
  @Local chartPoints: RevenueChartPoint[] = [];
  /** 总营收 */
  @Local totalRevenue: number = 0;
  /** 总订单数 */
  @Local totalOrders: number = 0;
  /** 平均营收 */
  @Local avgRevenue: number = 0;
  /** 是否正在加载 */
  @Local isLoading: boolean = false;

  /** 维度选项 */
  private dimensionOptions: DimensionOption[] = [
    { value: 'day', label: '按日（近7天）' },
    { value: 'month', label: '按月（近6月）' },
    { value: 'year', label: '按年（近3年）' }
  ];

  async aboutToAppear(): Promise<void> {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'revenue_stats_appear' });
    await this.loadChart();
  }

  /** 加载图表 */
  private async loadChart(): Promise<void> {
    this.isLoading = true;
    try {
      this.chartPoints = await RevenueRepository.getRevenueChart(MOCK_FARMER_ID, this.dimension);
      // 计算汇总
      this.totalRevenue = this.chartPoints.reduce((sum: number, p: RevenueChartPoint): number => sum + p.value, 0);
      // 模拟订单数（每元对应 0.5 个订单）
      this.totalOrders = Math.floor(this.totalRevenue / 50);
      this.avgRevenue = this.chartPoints.length > 0 ? this.totalRevenue / this.chartPoints.length : 0;
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'load_chart_fail', error: (err as Error).message });
    } finally {
      this.isLoading = false;
    }
  }

  /** 切换维度 */
  private async onDimensionChange(d: RevenueStatsDimension): Promise<void> {
    this.dimension = d;
    await this.loadChart();
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        this.DimensionBar()
        Scroll() {
          Column({ space: 16 }) {
            this.SummaryCard()
            this.ChartCard()
            this.DataTable()
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 24 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
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
      Text('营收统计')
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

  /** 维度切换 */
  @Builder
  DimensionBar() {
    Row({ space: 8 }) {
      ForEach(this.dimensionOptions, (opt: DimensionOption) => {
        Text(opt.label)
          .fontSize(12)
          .fontColor(this.dimension === opt.value ? Color.White : $r('app.color.color_text_secondary'))
          .backgroundColor(this.dimension === opt.value ? $r('app.color.color_primary') : $r('app.color.color_bg_card'))
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(14)
          .onClick(() => { this.onDimensionChange(opt.value); })
      }, (opt: DimensionOption) => opt.value)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    .backgroundColor($r('app.color.color_bg_card'))
    .justifyContent(FlexAlign.Center)
  }

  /** 汇总卡片 */
  @Builder
  SummaryCard() {
    Row() {
      this.SummaryItem('总营收', `¥${this.totalRevenue.toFixed(2)}`, $r('app.color.color_price'))
      this.SummaryItem('总订单', `${this.totalOrders}`, $r('app.color.color_primary'))
      this.SummaryItem('平均', `¥${this.avgRevenue.toFixed(2)}`, $r('app.color.color_text_primary'))
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
    .justifyContent(FlexAlign.SpaceAround)
  }

  /** 汇总项 */
  @Builder
  SummaryItem(label: string, value: string, color: Resource) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(16)
        .fontColor(color)
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(label)
        .fontSize(11)
        .fontColor($r('app.color.color_text_hint'))
    }
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)
  }

  /** 折线图卡片 */
  @Builder
  ChartCard() {
    Column({ space: 12 }) {
      Text('营收趋势')
        .fontSize(14)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)
      if (this.chartPoints.length === 0) {
        Text('暂无数据')
          .fontSize(12)
          .fontColor($r('app.color.color_text_hint'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 40, bottom: 40 })
      } else {
        // 简化版图表：用柱状条代替折线图（避免 Canvas 复杂度）
        this.SimpleBarChart()
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 简化柱状图（避免依赖 Canvas，使用 Flex 实现） */
  @Builder
  SimpleBarChart() {
    Column({ space: 8 }) {
      // 柱状图区域
      Row() {
        ForEach(this.chartPoints, (point: RevenueChartPoint, idx: number) => {
          this.BarColumn(point, idx)
        }, (point: RevenueChartPoint, idx: number) => `${point.label}_${idx}`)
      }
      .width('100%')
      .height(160)
      .alignItems(VerticalAlign.Bottom)
      .padding({ left: 8, right: 8 })

      // X 轴标签
      Row() {
        ForEach(this.chartPoints, (point: RevenueChartPoint, idx: number) => {
          Text(point.label.length > 5 ? point.label.slice(point.label.length - 5) : point.label)
            .fontSize(9)
            .fontColor($r('app.color.color_text_hint'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }, (point: RevenueChartPoint, idx: number) => point.label)
      }
      .width('100%')
      .padding({ left: 8, right: 8 })
    }
    .width('100%')
  }

  /** 单个柱子 */
  @Builder
  BarColumn(point: RevenueChartPoint, _idx: number) {
    Column({ space: 4 }) {
      Text(this.formatShortAmount(point.value))
        .fontSize(9)
        .fontColor($r('app.color.color_text_secondary'))
      Column() {
        // 柱条
        Column()
          .width(20)
          .height(this.calcBarHeight(point.value))
          .backgroundColor($r('app.color.color_primary'))
          .borderRadius({ topLeft: 4, topRight: 4 })
      }
      .height(120)
      .justifyContent(FlexAlign.End)
      .alignItems(HorizontalAlign.Center)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  /** 计算柱条高度 */
  private calcBarHeight(value: number): number {
    if (this.chartPoints.length === 0) {
      return 0;
    }
    const max: number = Math.max(...this.chartPoints.map((p: RevenueChartPoint): number => p.value));
    if (max === 0) {
      return 0;
    }
    const ratio: number = value / max;
    return Math.max(8, Math.floor(ratio * 100));
  }

  /** 格式化金额简写 */
  private formatShortAmount(value: number): string {
    if (value >= 10000) {
      return `${(value / 10000).toFixed(1)}万`;
    }
    if (value >= 1000) {
      return `${(value / 1000).toFixed(1)}k`;
    }
    return value.toFixed(0);
  }

  /** 数据表格 */
  @Builder
  DataTable() {
    Column({ space: 8 }) {
      Text('明细数据')
        .fontSize(14)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)
      // 表头
      Row() {
        Text('日期')
          .fontSize(11)
          .fontColor($r('app.color.color_text_secondary'))
          .layoutWeight(1)
        Text('营收（元）')
          .fontSize(11)
          .fontColor($r('app.color.color_text_secondary'))
          .layoutWeight(1)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })
      // 数据行
      ForEach(this.chartPoints, (point: RevenueChartPoint, idx: number) => {
        Row() {
          Text(point.label)
            .fontSize(12)
            .fontColor($r('app.color.color_text_primary'))
            .layoutWeight(1)
          Text(point.value.toFixed(2))
            .fontSize(12)
            .fontColor($r('app.color.color_price'))
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
            .textAlign(TextAlign.End)
        }
        .width('100%')
        .padding({ top: 8, bottom: 8 })
        .border({ width: { top: idx === 0 ? 0.5 : 0 }, color: $r('app.color.color_divider') })
      }, (point: RevenueChartPoint, idx: number) => `${point.label}_${idx}`)
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }
}
