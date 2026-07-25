/**
 * revenue_stats - 收入统计页
 * 对齐设计稿 pages/farmer-income.html：
 *  - 顶部栏："收入统计"标题 + 黄色"提现"按钮
 *  - 黄色总收入英雄卡（累计总收入 ¥38,560.00 + 本月¥12,860 + 15.3%↑ + 可提现¥8,230 + 装饰圆）
 *  - 时段切换胶囊Tab（7天/30天/全年，墨黑选中态）
 *  - 趋势折线图卡（收入趋势 + 日均¥428 + Canvas 折线图 + 最高点气泡）
 *  - 收入构成卡（环形图 + 图例 商品销售65%/直播打赏22%/体验预约13%）
 *  - 最近收入卡（5条记录：图标+名称+类型胶囊+金额+时间）
 *  - 底部 5 Tab 导航（首页激活）
 *
 * spec 3.2.4.5 / 4.2.2
 */

import { Logger, AppConstants, NavigationHelper, RouteName } from 'common';
import { FarmerProfile, IncomeComposition, IncomeTrendPoint, IncomeSegment, RevenueRecord } from '../../model/FarmerModels';
import { FarmerRepository } from '../../repository/FarmerRepository';
import { RevenueRepository } from '../../repository/RevenueRepository';
import { MOCK_FARMER_ID, getMockIncomeComposition, getMockIncomeTrend, MOCK_REVENUE_RECORDS } from '../../mock/FarmerMock';

/** 时段切换项 */
interface SegmentOption {
  value: IncomeSegment;
  label: string;
}

/** 最近收入展示项（对齐设计稿 qn-income-row） */
interface IncomeDisplayItem {
  /** 图标 emoji */
  icon: string;
  /** 图标背景色 class */
  iconColor: string;
  /** 名称 */
  name: string;
  /** 类型胶囊文案 */
  typeLabel: string;
  /** 类型胶囊颜色（green/yellow/gray） */
  typeColor: string;
  /** 金额（含正负号） */
  amountText: string;
  /** 时间文案 */
  timeText: string;
}

@ComponentV2
export struct RevenueStats {
  /** 当前底部 Tab（首页激活） */
  @Local currentTab: number = 0;
  /** 卖家信息 */
  @Local profile: FarmerProfile | null = null;
  /** 当前时段 */
  @Local segment: IncomeSegment = '30d';
  /** 收入构成 */
  @Local composition: IncomeComposition[] = [];
  /** 趋势数据 */
  @Local trendPoints: IncomeTrendPoint[] = [];
  /** 最近收入列表 */
  @Local recentIncomes: IncomeDisplayItem[] = [];
  /** 累计总收入 */
  @Local totalRevenue: number = 38560.00;
  /** 本月收入 */
  @Local monthRevenue: number = 12860.00;
  /** 可提现金额 */
  @Local availableAmount: number = 8230.00;
  /** 同比增长 */
  @Local growthRate: number = 15.3;
  /** 日均收入 */
  @Local dailyAvg: number = 428;

  /** 时段选项（对齐设计稿 qn-segment） */
  private segmentOptions: SegmentOption[] = [
    { value: '7d', label: '7天' },
    { value: '30d', label: '30天' },
    { value: 'year', label: '全年' }
  ];

  async aboutToAppear(): Promise<void> {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'revenue_stats_appear' });
    await this.loadData();
  }

  /** 加载数据 */
  private async loadData(): Promise<void> {
    try {
      this.profile = await FarmerRepository.getMyProfile(MOCK_FARMER_ID);
      this.totalRevenue = this.profile.totalRevenue;
      this.availableAmount = this.profile.availableBalance;
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'load_profile_fail', error: (err as Error).message });
    }
    this.composition = getMockIncomeComposition();
    this.trendPoints = getMockIncomeTrend(this.segment);
    this.recentIncomes = this.buildRecentIncomes();
    this.dailyAvg = this.calcDailyAvg();
  }

  /** 构建最近收入展示列表（对齐设计稿 5 条记录） */
  private buildRecentIncomes(): IncomeDisplayItem[] {
    const records: RevenueRecord[] = MOCK_REVENUE_RECORDS.slice(0, 5);
    return records.map((r: RevenueRecord): IncomeDisplayItem => {
      let icon: string = '📦';
      let iconColor: string = 'green';
      let typeColor: string = 'green';
      if (r.type === 'gift') {
        icon = '♥';
        iconColor = 'yellow';
        typeColor = 'yellow';
      } else if (r.type === 'booking') {
        icon = '📍';
        iconColor = 'blue';
        typeColor = 'gray';
      } else if (r.type === 'refund') {
        icon = '↩';
        iconColor = 'red';
        typeColor = 'gray';
      }
      const isRefund: boolean = r.type === 'refund';
      const sign: string = isRefund ? '-' : '+';
      return {
        icon,
        iconColor,
        name: r.productTitle ?? '收入',
        typeLabel: this.getTypeLabel(r.type),
        typeColor,
        amountText: `${sign}¥${r.amount.toFixed(2)}`,
        timeText: this.formatTime(r.createdAt)
      };
    });
  }

  /** 获取类型文案 */
  private getTypeLabel(type: string): string {
    if (type === 'order') {
      return '商品销售';
    } else if (type === 'gift') {
      return '直播打赏';
    } else if (type === 'booking') {
      return '体验预约';
    }
    return '退款';
  }

  /** 计算日均 */
  private calcDailyAvg(): number {
    if (this.trendPoints.length === 0) {
      return 0;
    }
    const sum: number = this.trendPoints.reduce((s: number, p: IncomeTrendPoint): number => s + p.value, 0);
    return Math.round(sum / this.trendPoints.length);
  }

  /** 切换时段 */
  private onSegmentChange(s: IncomeSegment): void {
    this.segment = s;
    this.trendPoints = getMockIncomeTrend(s);
    this.dailyAvg = this.calcDailyAvg();
    Logger.info(AppConstants.SCENE_FARMER, { action: 'segment_change', range: s });
  }

  /** 格式化时间（今天/昨天 + HH:mm） */
  private formatTime(ts: number): string {
    const now: Date = new Date();
    const d: Date = new Date(ts);
    const todayStart: number = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    const yesterdayStart: number = todayStart - 86400000;
    const hh: string = `${d.getHours()}`.padStart(2, '0');
    const mi: string = `${d.getMinutes()}`.padStart(2, '0');
    if (ts >= todayStart) {
      return `今天 ${hh}:${mi}`;
    } else if (ts >= yesterdayStart) {
      return `昨天 ${hh}:${mi}`;
    }
    const mm: string = `${d.getMonth() + 1}`.padStart(2, '0');
    const dd: string = `${d.getDate()}`.padStart(2, '0');
    return `${mm}-${dd} ${hh}:${mi}`;
  }

  /** 格式化金额（千分位） */
  private formatAmount(amount: number): string {
    const parts: string[] = amount.toFixed(2).split('.');
    parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    return parts.join('.');
  }

  build() {
    NavDestination() {
      Column() {
        // 1. 顶部栏
        this.TopBar()
        // 2. 内容滚动区
        Scroll() {
          Column({ space: 12 }) {
            // a) 黄色总收入英雄卡
            this.IncomeHeroCard()
            // b) 时段切换
            this.SegmentBar()
            // c) 趋势折线图卡
            this.TrendChartCard()
            // d) 收入构成卡
            this.CompositionCard()
            // e) 最近收入卡
            this.RecentIncomeCard()
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 80 })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        // 3. 底部 5 Tab
        this.BottomTabBar()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 顶部栏（对齐 qn-topbar：标题 + 黄色提现按钮） */
  @Builder
  TopBar() {
    Row() {
      Text('收入统计')
        .fontSize(18)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .letterSpacing(0.5)
      Blank()
      Row({ space: 5 }) {
        Text('💳')
          .fontSize(13)
        Text('提现')
          .fontSize(13)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .height(32)
      .padding({ left: 14, right: 14 })
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor($r('app.color.color_yellow'))
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        Logger.info(AppConstants.SCENE_FARMER, { action: 'goto_withdraw' });
        NavigationHelper.push(RouteName.FARMER_WITHDRAW);
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 10 })
    .alignItems(VerticalAlign.Center)
  }

  /** 黄色总收入英雄卡（对齐 qn-card-yellow qn-income-hero） */
  @Builder
  IncomeHeroCard() {
    Stack({ alignContent: Alignment.TopEnd }) {
      // 右上角装饰圆（对齐 qn-income-hero::after）
      Column()
        .width(132)
        .height(132)
        .borderRadius(66)
        .backgroundColor('rgba(255,255,255,0.22)')
        .position({ right: -32, top: -32 })
        .hitTestBehavior(HitTestMode.Transparent)
      // 右下角装饰圆（对齐 qn-income-hero::before）
      Column()
        .width(96)
        .height(96)
        .borderRadius(48)
        .backgroundColor('rgba(255,255,255,0.14)')
        .position({ right: 40, bottom: -46 })
        .hitTestBehavior(HitTestMode.Transparent)

      // 主内容
      Column() {
        // 顶部行：累计总收入 + 钱包图标
        Row() {
          Text('累计总收入')
            .fontSize(13)
            .fontColor($r('app.color.color_ink_2'))
            .fontWeight(FontWeight.Medium)
          Blank()
          Row() {
            Text('💰')
              .fontSize(16)
          }
          .width(32)
          .height(32)
          .borderRadius(16)
          .backgroundColor('rgba(255,255,255,0.55)')
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')

        // 总金额大字
        Row() {
          Text('¥')
            .fontSize(20)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .margin({ right: 2 })
          Text(this.formatAmount(this.totalRevenue))
            .fontSize(32)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .letterSpacing(-0.5)
        }
        .margin({ top: 6 })

        // 数据行：本月 + 增长率 + 可提现
        Row({ space: 10 }) {
          Row() {
            Text('本月 ')
              .fontSize(13)
              .fontColor($r('app.color.color_ink_2'))
              .fontWeight(FontWeight.Medium)
            Text(`¥${this.monthRevenue.toLocaleString()}`)
              .fontSize(13)
              .fontColor($r('app.color.color_ink'))
              .fontWeight(FontWeight.Bold)
          }
          // 增长率胶囊（绿色 + ↑）
          Row({ space: 2 }) {
            Text('↑')
              .fontSize(10)
              .fontColor($r('app.color.color_green_deep'))
              .fontWeight(FontWeight.Bold)
            Text(`${this.growthRate}%`)
              .fontSize(11)
              .fontColor($r('app.color.color_green_deep'))
              .fontWeight(FontWeight.Bold)
          }
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_green_soft'))
          .alignItems(VerticalAlign.Center)
          Row() {
            Text('可提现 ')
              .fontSize(13)
              .fontColor($r('app.color.color_ink_2'))
              .fontWeight(FontWeight.Medium)
            Text(`¥${this.availableAmount.toLocaleString()}`)
              .fontSize(13)
              .fontColor($r('app.color.color_ink'))
              .fontWeight(FontWeight.Bold)
          }
        }
        .margin({ top: 16 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding(18)
    }
    .width('100%')
    .borderRadius(AppConstants.RADIUS_LG)
    .linearGradient({
      angle: 135,
      colors: [['#FFE234', 0], ['#FFD93D', 1]]
    })
    .shadow({ radius: 18, color: 'rgba(255,217,61,0.35)', offsetX: 0, offsetY: 6 })
  }

  /** 时段切换胶囊Tab（对齐 qn-segment：7天/30天/全年） */
  @Builder
  SegmentBar() {
    Row() {
      ForEach(this.segmentOptions, (opt: SegmentOption) => {
        Text(opt.label)
          .fontSize(13)
          .fontColor(this.segment === opt.value ? Color.White : $r('app.color.color_text_2'))
          .fontWeight(this.segment === opt.value ? FontWeight.Bold : FontWeight.Medium)
          .backgroundColor(this.segment === opt.value ? $r('app.color.color_ink') : Color.Transparent)
          .layoutWeight(1)
          .height(34)
          .textAlign(TextAlign.Center)
          .borderRadius(AppConstants.RADIUS_PILL)
          .onClick(() => { this.onSegmentChange(opt.value); })
      }, (opt: SegmentOption) => opt.value)
    }
    .width('100%')
    .padding({ left: 3, right: 3, top: 3, bottom: 3 })
    .borderRadius(AppConstants.RADIUS_PILL)
    .backgroundColor($r('app.color.color_fill'))
  }

  /** 趋势折线图卡（对齐 qn-card：收入趋势 + 日均¥428 + 折线图） */
  @Builder
  TrendChartCard() {
    Column() {
      // 标题行
      Row() {
        Text('收入趋势')
          .fontSize(16)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        Blank()
        Row() {
          Text('日均 ')
            .fontSize(12)
            .fontColor($r('app.color.color_text_2'))
          Text(`¥${this.dailyAvg}`)
            .fontSize(12)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
        }
      }
      .width('100%')
      .padding({ bottom: 6 })

      // Canvas 折线图
      TrendChartCanvas({ points: this.trendPoints })
        .width('100%')
        .height(140)
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 收入构成卡（对齐 qn-card：环形图 + 图例） */
  @Builder
  CompositionCard() {
    Row({ space: 16 }) {
      // 环形图（Canvas）
      DonutChartCanvas({ composition: this.composition, centerAmount: this.monthRevenue })
        .width(116)
        .height(116)

      // 图例列表
      Column({ space: 10 }) {
        ForEach(this.composition, (item: IncomeComposition) => {
          Row() {
            // 色点
            Column()
              .width(10)
              .height(10)
              .borderRadius(5)
              .backgroundColor(item.color)
            // 名称
            Text(item.label)
              .fontSize(12)
              .fontColor($r('app.color.color_text_2'))
              .margin({ left: 6 })
              .layoutWeight(1)
            // 金额
            Text(`¥${item.amount.toLocaleString()}`)
              .fontSize(12)
              .fontColor($r('app.color.color_ink'))
              .fontWeight(FontWeight.Medium)
            // 百分比
            Text(`${item.percent}%`)
              .fontSize(12)
              .fontColor($r('app.color.color_text_3'))
              .margin({ left: 8 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }, (item: IncomeComposition) => item.type)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(VerticalAlign.Center)
  }

  /** 最近收入卡（对齐 qn-card：5条收入记录） */
  @Builder
  RecentIncomeCard() {
    Column() {
      // 标题行
      Row() {
        Text('最近收入')
          .fontSize(16)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        Blank()
        Row() {
          Text('查看全部')
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
          Text('›')
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
        }
        .onClick(() => {
          Logger.info(AppConstants.SCENE_FARMER, { action: 'goto_revenue_detail' });
          NavigationHelper.push(RouteName.FARMER_REVENUE_DETAIL);
        })
      }
      .width('100%')
      .padding({ bottom: 6 })

      // 收入记录列表
      ForEach(this.recentIncomes, (item: IncomeDisplayItem, idx: number) => {
        Row({ space: 12 }) {
          // 图标圆形背景
          Row() {
            Text(item.icon)
              .fontSize(16)
          }
          .width(36)
          .height(36)
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor(this.getIconBgColor(item.iconColor))
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)

          // 名称 + 类型胶囊
          Column({ space: 4 }) {
            Text(item.name)
              .fontSize(13)
              .fontColor($r('app.color.color_ink'))
              .fontWeight(FontWeight.Medium)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Row() {
              Text(item.typeLabel)
                .fontSize(10)
                .fontColor(this.getTypeTextColor(item.typeColor))
                .fontWeight(FontWeight.Medium)
                .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                .borderRadius(AppConstants.RADIUS_PILL)
                .backgroundColor(this.getTypeBgColor(item.typeColor))
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // 金额 + 时间
          Column({ space: 2 }) {
            Text(item.amountText)
              .fontSize(13)
              .fontColor($r('app.color.color_live'))
              .fontWeight(FontWeight.Bold)
            Text(item.timeText)
              .fontSize(11)
              .fontColor($r('app.color.color_text_3'))
          }
          .alignItems(HorizontalAlign.End)
        }
        .width('100%')
        .padding({ top: 10, bottom: 10 })
        .border({ width: { bottom: idx === this.recentIncomes.length - 1 ? 0 : 0.5 }, color: $r('app.color.color_line') })
        .alignItems(VerticalAlign.Center)
      }, (item: IncomeDisplayItem, idx: number) => `${item.name}_${idx}`)
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 获取图标背景色 */
  private getIconBgColor(colorKey: string): Resource {
    if (colorKey === 'green') {
      return $r('app.color.color_green_soft');
    } else if (colorKey === 'yellow') {
      return $r('app.color.color_yellow_soft');
    } else if (colorKey === 'blue') {
      return $r('app.color.color_info_soft');
    }
    return $r('app.color.color_live_soft');
  }

  /** 获取类型文字色 */
  private getTypeTextColor(colorKey: string): Resource {
    if (colorKey === 'green') {
      return $r('app.color.color_green_deep');
    } else if (colorKey === 'yellow') {
      return $r('app.color.color_yellow_text');
    }
    return $r('app.color.color_text_2');
  }

  /** 获取类型背景色 */
  private getTypeBgColor(colorKey: string): Resource {
    if (colorKey === 'green') {
      return $r('app.color.color_green_soft');
    } else if (colorKey === 'yellow') {
      return $r('app.color.color_yellow_soft');
    }
    return $r('app.color.color_fill');
  }

  /** 底部 5 Tab 导航（对齐 qn-tabbar，首页激活） */
  @Builder
  BottomTabBar() {
    Row() {
      this.BottomTabItem('首页', '🏠', 0)
      this.BottomTabItem('社区', '💬', 1)
      this.BottomTabItem('直播', '📹', 2)
      this.BottomTabItem('消息', '✉️', 3)
      this.BottomTabItem('个人', '👤', 4)
    }
    .width('100%')
    .height(64)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_NAV)
    .padding({ left: 8, right: 8, bottom: 8 })
  }

  /** 底部 Tab 项 */
  @Builder
  BottomTabItem(label: string, icon: string, index: number) {
    Column({ space: 2 }) {
      Text(icon)
        .fontSize(24)
        .fontColor(this.currentTab === index ? $r('app.color.color_yellow_deep') : $r('app.color.color_text_3'))
      Text(label)
        .fontSize(10)
        .fontColor(this.currentTab === index ? $r('app.color.color_ink') : $r('app.color.color_text_3'))
        .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Medium)
    }
    .layoutWeight(1)
    .height(64)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      if (index === 0) {
        NavigationHelper.pop();
        return;
      }
      this.currentTab = index;
      if (index === 1) {
        NavigationHelper.push(RouteName.FARMER_COMMUNITY_LIST);
      } else if (index === 2) {
        NavigationHelper.push(RouteName.FARMER_LIVE_CREATE);
      } else if (index === 3) {
        NavigationHelper.push(RouteName.FARMER_MESSAGE_LIST);
      } else if (index === 4) {
        NavigationHelper.push(RouteName.FARMER_SELLER_PROFILE);
      }
    })
  }
}

/**
 * TrendCoord - 折线图坐标点（X/Y 坐标 + 原始数据点）
 * 用于 Canvas 自绘时缓存所有数据点的渲染坐标
 */
interface TrendCoord {
  /** X 轴坐标 */
  x: number;
  /** Y 轴坐标 */
  y: number;
  /** 原始数据点 */
  point: IncomeTrendPoint;
}

/**
 * TrendChartCanvas - 收入趋势折线图（Canvas 自绘）
 * 对齐设计稿 qn-chart-box svg：绿色折线 + 渐变填充 + 数据点 + 最高点气泡
 */
@ComponentV2
struct TrendChartCanvas {
  /** 数据点 */
  @Param points: IncomeTrendPoint[] = [];
  /** Canvas 渲染上下文设置 */
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  /** Canvas 渲染上下文 */
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  build() {
    Canvas(this.context)
      .width('100%')
      .height(140)
      .onReady(() => {
        this.drawChart();
      })
  }

  /** 绘制折线图 */
  private drawChart(): void {
    const ctx: CanvasRenderingContext2D = this.context;
    if (this.points.length === 0) {
      return;
    }
    const w: number = 330;
    const h: number = 140;
    const padL: number = 14;
    const padR: number = 14;
    const padT: number = 24;
    const padB: number = 24;
    const chartW: number = w - padL - padR;
    const chartH: number = h - padT - padB;

    // 计算最大值
    const maxVal: number = Math.max(...this.points.map((p: IncomeTrendPoint): number => p.value));
    const minVal: number = 0;
    const range: number = maxVal - minVal || 1;

    // 计算各点坐标
    const step: number = chartW / (this.points.length - 1);
    const coords: TrendCoord[] = this.points.map(
      (p: IncomeTrendPoint, i: number): TrendCoord => {
        const x: number = padL + step * i;
        const y: number = padT + chartH - ((p.value - minVal) / range) * chartH;
        return { x, y, point: p };
      }
    );

    // 1. 水平虚线网格
    ctx.strokeStyle = '#F0F0F0';
    ctx.lineWidth = 1;
    ctx.setLineDash([3, 3]);
    for (let i: number = 1; i <= 2; i++) {
      const y: number = padT + (chartH / 3) * i;
      ctx.beginPath();
      ctx.moveTo(padL, y);
      ctx.lineTo(w - padR, y);
      ctx.stroke();
    }
    ctx.setLineDash([]);

    // 2. 渐变填充区域
    const gradient: CanvasGradient = ctx.createLinearGradient(0, padT, 0, padT + chartH);
    gradient.addColorStop(0, 'rgba(126,211,33,0.30)');
    gradient.addColorStop(1, 'rgba(126,211,33,0)');
    ctx.fillStyle = gradient;
    ctx.beginPath();
    ctx.moveTo(coords[0].x, padT + chartH);
    coords.forEach((c: TrendCoord, i: number) => {
      if (i === 0) {
        ctx.lineTo(c.x, c.y);
      } else {
        const prev: TrendCoord = coords[i - 1];
        const cpX: number = (prev.x + c.x) / 2;
        ctx.bezierCurveTo(cpX, prev.y, cpX, c.y, c.x, c.y);
      }
    });
    ctx.lineTo(coords[coords.length - 1].x, padT + chartH);
    ctx.closePath();
    ctx.fill();

    // 3. 折线
    ctx.strokeStyle = '#7ED321';
    ctx.lineWidth = 2.5;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.beginPath();
    coords.forEach((c: TrendCoord, i: number) => {
      if (i === 0) {
        ctx.moveTo(c.x, c.y);
      } else {
        const prev: TrendCoord = coords[i - 1];
        const cpX: number = (prev.x + c.x) / 2;
        ctx.bezierCurveTo(cpX, prev.y, cpX, c.y, c.x, c.y);
      }
    });
    ctx.stroke();

    // 4. 数据点
    coords.forEach((c: TrendCoord) => {
      if (c.point.isToday) {
        // 今日高亮点：外圈光晕 + 实心点
        ctx.fillStyle = 'rgba(126,211,33,0.18)';
        ctx.beginPath();
        ctx.arc(c.x, c.y, 6, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = '#7ED321';
        ctx.beginPath();
        ctx.arc(c.x, c.y, 4, 0, Math.PI * 2);
        ctx.fill();
        ctx.strokeStyle = '#FFFFFF';
        ctx.lineWidth = 2;
        ctx.stroke();
        // 气泡标注（手动绘制圆角矩形）
        ctx.fillStyle = '#1A1A1A';
        ctx.beginPath();
        ctx.moveTo(c.x - 26 + 9, c.y - 22);
        ctx.lineTo(c.x + 26 - 9, c.y - 22);
        ctx.arcTo(c.x + 26, c.y - 22, c.x + 26, c.y - 22 + 9, 9);
        ctx.lineTo(c.x + 26, c.y - 22 + 18 - 9);
        ctx.arcTo(c.x + 26, c.y - 4, c.x + 26 - 9, c.y - 4, 9);
        ctx.lineTo(c.x - 26 + 9, c.y - 4);
        ctx.arcTo(c.x - 26, c.y - 4, c.x - 26, c.y - 4 - 9, 9);
        ctx.lineTo(c.x - 26, c.y - 22 + 9);
        ctx.arcTo(c.x - 26, c.y - 22, c.x - 26 + 9, c.y - 22, 9);
        ctx.fill();
        // 气泡箭头
        ctx.beginPath();
        ctx.moveTo(c.x - 5, c.y - 4);
        ctx.lineTo(c.x + 5, c.y - 4);
        ctx.lineTo(c.x, c.y + 1);
        ctx.closePath();
        ctx.fill();
        // 气泡文字
        ctx.fillStyle = '#FFFFFF';
        ctx.font = '700 11px HarmonyOS Sans SC, sans-serif';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(`¥${c.point.value.toLocaleString()}`, c.x, c.y - 13);
      } else {
        // 普通数据点
        ctx.fillStyle = '#FFFFFF';
        ctx.beginPath();
        ctx.arc(c.x, c.y, 3, 0, Math.PI * 2);
        ctx.fill();
        ctx.strokeStyle = '#7ED321';
        ctx.lineWidth = 2;
        ctx.stroke();
      }
    });

    // 5. X 轴标签
    ctx.fillStyle = '#999999';
    ctx.font = '10px HarmonyOS Sans SC, sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';
    coords.forEach((c: TrendCoord) => {
      if (c.point.isToday) {
        ctx.fillStyle = '#5BB315';
        ctx.font = '700 10px HarmonyOS Sans SC, sans-serif';
      } else {
        ctx.fillStyle = '#999999';
        ctx.font = '10px HarmonyOS Sans SC, sans-serif';
      }
      ctx.fillText(c.point.label, c.x, h - 14);
    });
  }
}

/**
 * DonutChartCanvas - 收入构成环形图（Canvas 自绘）
 * 对齐设计稿 svg 环形图：3段弧 + 中心文字
 */
@ComponentV2
struct DonutChartCanvas {
  /** 构成数据 */
  @Param composition: IncomeComposition[] = [];
  /** 中心金额 */
  @Param centerAmount: number = 0;
  /** Canvas 渲染上下文设置 */
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  /** Canvas 渲染上下文 */
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  build() {
    Canvas(this.context)
      .width(116)
      .height(116)
      .onReady(() => {
        this.drawDonut();
      })
  }

  /** 绘制环形图 */
  private drawDonut(): void {
    const ctx: CanvasRenderingContext2D = this.context;
    const w: number = 116;
    const h: number = 116;
    const cx: number = w / 2;
    const cy: number = h / 2;
    const radius: number = 40;
    const lineWidth: number = 14;

    // 背景圆环
    ctx.strokeStyle = '#F6F6F4';
    ctx.lineWidth = lineWidth;
    ctx.beginPath();
    ctx.arc(cx, cy, radius, 0, Math.PI * 2);
    ctx.stroke();

    // 绘制各段弧
    let startAngle: number = -Math.PI / 2;
    const total: number = this.composition.reduce((s: number, c: IncomeComposition): number => s + c.percent, 0);
    this.composition.forEach((item: IncomeComposition) => {
      const arcAngle: number = (item.percent / total) * Math.PI * 2;
      ctx.strokeStyle = item.color;
      ctx.lineWidth = lineWidth;
      ctx.lineCap = 'butt';
      ctx.beginPath();
      ctx.arc(cx, cy, radius, startAngle, startAngle + arcAngle);
      ctx.stroke();
      startAngle += arcAngle;
    });

    // 中心文字：金额
    ctx.fillStyle = '#1A1A1A';
    ctx.font = '800 12px HarmonyOS Sans SC, sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(`¥${this.centerAmount.toLocaleString()}`, cx, cy - 6);
    // 中心文字：本月收入
    ctx.fillStyle = '#999999';
    ctx.font = '8.5px HarmonyOS Sans SC, sans-serif';
    ctx.fillText('本月收入', cx, cy + 10);
  }
}
