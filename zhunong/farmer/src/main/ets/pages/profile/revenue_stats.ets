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

import { Logger, AppConstants, NavigationHelper, RouteName, FontUtil, ModeStore } from 'common';
import type { CurrentModeKey } from 'common';
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
  /** spec 16.10：放大查看的图表类型（null 表示不显示放大弹窗） */
  @Local enlargedChart: string | null = null;
  /** 当前模式（spec 16.6：老人模式字体放大） */
  @Local modeRef: CurrentModeKey = ModeStore.connectModeRef();

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

  /** spec 16.6：当前是否老年大字模式 */
  private isElder(): boolean {
    return FontUtil.isElder(this.modeRef.value);
  }

  /** 加载数据 */
  private async loadData(): Promise<void> {
    try {
      this.profile = await FarmerRepository.getMyProfile(MOCK_FARMER_ID);
      // 字段可能 undefined（Mock 数据不完整），用 ?? 0 兜底避免 toLocaleString 崩溃
      this.totalRevenue = this.profile.totalRevenue ?? 0;
      this.availableAmount = this.profile.availableBalance ?? 0;
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
      Stack() {
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

        // spec 16.10：图表放大弹窗
        if (this.enlargedChart !== null) {
          this.ChartEnlargedDialog()
        }
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
  }

  /** spec 16.10：图表放大弹窗（全屏覆盖，重新绘制大尺寸图表；spec 16.12：对齐 product_manage 弹窗样式） */
  @Builder
  ChartEnlargedDialog() {
    Stack() {
      // 遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.85)')
        .onClick(() => { this.enlargedChart = null; })

      // 弹窗主体
      Column({ space: 16 }) {
        // 顶部标题 + 关闭按钮
        Row() {
          Text(this.getEnlargedChartTitle())
            .fontSize(22)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
          Text('×')
            .fontSize(32)
            .fontColor(Color.White)
            .width(44)
            .height(44)
            .textAlign(TextAlign.Center)
            .onClick(() => { this.enlargedChart = null; })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 放大的图表区域（白色背景，便于阅读）
        Column() {
          Scroll() {
            if (this.enlargedChart === 'trend') {
              // spec 16.12：放大弹窗传更大尺寸 + 字号（对齐 product_manage 销量趋势图）
              TrendChartCanvas({
                points: this.trendPoints,
                canvasWidth: 680,
                canvasHeight: 400,
                labelFontSize: 42,
                bubbleFontSize: 44
              })
                .width(680)
                .height(400)
            } else if (this.enlargedChart === 'composition') {
              Row({ space: 30 }) {
                // spec 16.12：放大弹窗传更大尺寸 + 字号（对齐 product_manage 环形图）
                DonutChartCanvas({
                  composition: this.composition,
                  centerAmount: this.monthRevenue,
                  canvasWidth: 560,
                  canvasHeight: 560,
                  amountFontSize: 56,
                  labelFontSize: 40
                })
                  .width(560)
                  .height(560)
                Column({ space: 16 }) {
                  ForEach(this.composition, (item: IncomeComposition) => {
                    Column({ space: 6 }) {
                      Row({ space: 10 }) {
                        Column()
                          .width(20)
                          .height(20)
                          .borderRadius(10)
                          .backgroundColor(item.color)
                        Text(item.label)
                          .fontSize(18)
                          .fontColor($r('app.color.color_text_2'))
                          .fontWeight(FontWeight.Medium)
                        Text(`${item.percent}%`)
                          .fontSize(18)
                          .fontColor($r('app.color.color_accent_gold'))
                          .fontWeight(FontWeight.Bold)
                      }
                      .width('100%')
                      .alignItems(VerticalAlign.Center)
                      Text(`¥${item.amount.toLocaleString()}`)
                        .fontSize(20)
                        .fontColor($r('app.color.color_ink'))
                        .fontWeight(FontWeight.Bold)
                        .width('100%')
                    }
                    .width(220)
                    .alignItems(HorizontalAlign.Start)
                    .padding({ bottom: 6 })
                  }, (item: IncomeComposition) => item.type)
                }
                .alignItems(HorizontalAlign.Start)
                .justifyContent(FlexAlign.Center)
              }
              .padding(20)
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .padding(20)
        .borderRadius(16)
        .backgroundColor($r('app.color.color_bg_card'))
      }
      .width('92%')
      .height('88%')
      .padding(20)
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.Center)
  }

  /** spec 16.10：放大弹窗标题 */
  private getEnlargedChartTitle(): string {
    if (this.enlargedChart === 'trend') {
      return '收入趋势（放大）';
    } else if (this.enlargedChart === 'composition') {
      return '收入构成（放大）';
    }
    return '图表放大';
  }

  /** 顶部栏（对齐 qn-topbar：标题 + 黄色提现按钮） */
  @Builder
  TopBar() {
    Row() {
      Text('收入统计')
        .fontSize(FontUtil.s(18, this.isElder()))
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .letterSpacing(0.5)
      Blank()
      Row({ space: 5 }) {
        Text('💳')
          .fontSize(FontUtil.s(15, this.isElder()))
        Text('提现')
          .fontSize(FontUtil.s(15, this.isElder()))
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .height(36)
      .padding({ left: 16, right: 16 })
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
            .fontSize(FontUtil.s(15, this.isElder()))
            .fontColor($r('app.color.color_ink_2'))
            .fontWeight(FontWeight.Medium)
          Blank()
          Row() {
            Text('💰')
              .fontSize(FontUtil.s(18, this.isElder()))
          }
          .width(36)
          .height(36)
          .borderRadius(18)
          .backgroundColor('rgba(255,255,255,0.55)')
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')

        // 总金额大字
        Row() {
          Text('¥')
            .fontSize(FontUtil.s(22, this.isElder()))
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .margin({ right: 2 })
          Text(this.formatAmount(this.totalRevenue))
            .fontSize(FontUtil.s(34, this.isElder()))
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .letterSpacing(-0.5)
        }
        .margin({ top: 6 })

        // 数据行：本月 + 增长率 + 可提现
        Row({ space: 10 }) {
          Row() {
            Text('本月 ')
              .fontSize(FontUtil.s(15, this.isElder()))
              .fontColor($r('app.color.color_ink_2'))
              .fontWeight(FontWeight.Medium)
            Text(`¥${this.monthRevenue.toLocaleString()}`)
              .fontSize(FontUtil.s(15, this.isElder()))
              .fontColor($r('app.color.color_ink'))
              .fontWeight(FontWeight.Bold)
          }
          // 增长率胶囊（绿色 + ↑）
          Row({ space: 2 }) {
            Text('↑')
              .fontSize(FontUtil.s(12, this.isElder()))
              .fontColor($r('app.color.color_green_deep'))
              .fontWeight(FontWeight.Bold)
            Text(`${this.growthRate}%`)
              .fontSize(FontUtil.s(13, this.isElder()))
              .fontColor($r('app.color.color_green_deep'))
              .fontWeight(FontWeight.Bold)
          }
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_green_soft'))
          .alignItems(VerticalAlign.Center)
          Row() {
            Text('可提现 ')
              .fontSize(FontUtil.s(15, this.isElder()))
              .fontColor($r('app.color.color_ink_2'))
              .fontWeight(FontWeight.Medium)
            Text(`¥${this.availableAmount.toLocaleString()}`)
              .fontSize(FontUtil.s(15, this.isElder()))
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
          .fontSize(FontUtil.s(15, this.isElder()))
          .fontColor(this.segment === opt.value ? Color.White : $r('app.color.color_text_2'))
          .fontWeight(this.segment === opt.value ? FontWeight.Bold : FontWeight.Medium)
          .backgroundColor(this.segment === opt.value ? $r('app.color.color_ink') : Color.Transparent)
          .layoutWeight(1)
          .height(38)
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

  /** 趋势折线图卡（对齐 qn-card：收入趋势 + 日均 + 折线图，spec 16.8：横向滚动拓宽可用面积） */
  @Builder
  TrendChartCard() {
    Column() {
      // 标题行
      Row() {
        Text('收入趋势')
          .fontSize(FontUtil.s(18, this.isElder()))
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        Blank()
        Row() {
          Text('日均 ')
            .fontSize(FontUtil.s(15, this.isElder()))
            .fontColor($r('app.color.color_text_2'))
          Text(`¥${this.dailyAvg}`)
            .fontSize(FontUtil.s(15, this.isElder()))
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
        }
      }
      .width('100%')
      .padding({ bottom: 8 })

      // Canvas 折线图（spec 16.8：固定宽度，支持横向滑动；spec 16.10：点击放大）
      Scroll() {
        TrendChartCanvas({
          points: this.trendPoints,
          canvasWidth: 400,
          canvasHeight: 160
        })
          .width(400)
          .height(160)
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .onClick(() => { this.enlargedChart = 'trend'; })
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 收入构成卡（对齐 qn-card：环形图 + 图例，spec 16.8：横向滚动避免遮挡） */
  @Builder
  CompositionCard() {
    Scroll() {
      Row({ space: 20 }) {
        // 环形图（Canvas）固定尺寸
        DonutChartCanvas({ composition: this.composition, centerAmount: this.monthRevenue })
          .width(180)
          .height(180)

        // 图例列表（垂直排列，确保不重叠）
        Column({ space: 16 }) {
          ForEach(this.composition, (item: IncomeComposition) => {
            Column({ space: 6 }) {
              // 第一行：色点 + 名称 + 百分比
              Row({ space: 10 }) {
                // 色点
                Column()
                  .width(16)
                  .height(16)
                  .borderRadius(8)
                  .backgroundColor(item.color)
                // 名称
                Text(item.label)
                  .fontSize(FontUtil.s(16, this.isElder()))
                  .fontColor($r('app.color.color_text_2'))
                  .fontWeight(FontWeight.Medium)
                // 百分比
                Text(`${item.percent}%`)
                  .fontSize(FontUtil.s(16, this.isElder()))
                  .fontColor($r('app.color.color_accent_gold'))
                  .fontWeight(FontWeight.Bold)
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)

              // 第二行：金额
              Text(`¥${item.amount.toLocaleString()}`)
                .fontSize(FontUtil.s(18, this.isElder()))
                .fontColor($r('app.color.color_ink'))
                .fontWeight(FontWeight.Bold)
                .width('100%')
            }
            .width(160)
            .alignItems(HorizontalAlign.Start)
            .padding({ bottom: 4 })
          }, (item: IncomeComposition) => item.type)
        }
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Center)
      }
      .padding(16)
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .onClick(() => { this.enlargedChart = 'composition'; })
  }

  /** 最近收入卡（对齐 qn-card：5条收入记录） */
  @Builder
  RecentIncomeCard() {
    Column() {
      // 标题行
      Row() {
        Text('最近收入')
          .fontSize(FontUtil.s(18, this.isElder()))
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        Blank()
        Row() {
          Text('查看全部')
            .fontSize(FontUtil.s(14, this.isElder()))
            .fontColor($r('app.color.color_text_3'))
          Text('›')
            .fontSize(FontUtil.s(14, this.isElder()))
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
              .fontSize(FontUtil.s(18, this.isElder()))
          }
          .width(40)
          .height(40)
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor(this.getIconBgColor(item.iconColor))
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)

          // 名称 + 类型胶囊
          Column({ space: 4 }) {
            Text(item.name)
              .fontSize(FontUtil.s(15, this.isElder()))
              .fontColor($r('app.color.color_ink'))
              .fontWeight(FontWeight.Medium)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Row() {
              Text(item.typeLabel)
                .fontSize(FontUtil.s(12, this.isElder()))
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
              .fontSize(FontUtil.s(15, this.isElder()))
              .fontColor($r('app.color.color_live'))
              .fontWeight(FontWeight.Bold)
            Text(item.timeText)
              .fontSize(FontUtil.s(12, this.isElder()))
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
 * spec 16.12：支持 canvasWidth/canvasHeight/labelFontSize 参数，放大弹窗可传更大值
 */
@ComponentV2
struct TrendChartCanvas {
  /** 数据点 */
  @Param points: IncomeTrendPoint[] = [];
  /** spec 16.12：Canvas 尺寸（默认 330x140，放大弹窗传更大值） */
  @Param canvasWidth: number = 330;
  @Param canvasHeight: number = 140;
  /** spec 16.12：字号（默认 26，放大弹窗传更大值） */
  @Param labelFontSize: number = 26;
  /** spec 16.12：气泡字号（默认 28，放大弹窗传更大值） */
  @Param bubbleFontSize: number = 28;
  /** Canvas 渲染上下文设置 */
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  /** Canvas 渲染上下文 */
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  /** spec 修复：数据加载后重绘折线图 */
  @Monitor('points')
  onPointsChange(monitor: IMonitor): void {
    this.drawChart();
  }

  build() {
    Canvas(this.context)
      .width(this.canvasWidth)
      .height(this.canvasHeight)
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
    const w: number = this.canvasWidth;
    const h: number = this.canvasHeight;
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
        // 气泡文字（spec 16.11/16.12：字号可配置，放大弹窗传更大值）
        ctx.fillStyle = '#FFFFFF';
        ctx.font = `700 ${this.bubbleFontSize}px HarmonyOS Sans SC, sans-serif`;
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

    // 5. X 轴标签（spec 16.11/16.12：字号可配置，放大弹窗传更大值）
    ctx.fillStyle = '#999999';
    ctx.font = `${this.labelFontSize}px HarmonyOS Sans SC, sans-serif`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';
    coords.forEach((c: TrendCoord) => {
      if (c.point.isToday) {
        ctx.fillStyle = '#5BB315';
        ctx.font = `700 ${this.labelFontSize}px HarmonyOS Sans SC, sans-serif`;
      } else {
        ctx.fillStyle = '#999999';
        ctx.font = `${this.labelFontSize}px HarmonyOS Sans SC, sans-serif`;
      }
      ctx.fillText(c.point.label, c.x, h - 16);
    });
  }
}

/**
 * DonutChartCanvas - 收入构成环形图（Canvas 自绘）
 * 对齐设计稿 svg 环形图：3段弧 + 中心文字
 * spec 16.8：放大图表尺寸与字号，修复统计无法正常显示问题
 * spec 16.12：支持 canvasWidth/canvasHeight/labelFontSize 参数，放大弹窗可传更大值
 */
@ComponentV2
struct DonutChartCanvas {
  /** 构成数据 */
  @Param composition: IncomeComposition[] = [];
  /** 中心金额 */
  @Param centerAmount: number = 0;
  /** spec 16.12：Canvas 尺寸（默认 180x180，放大弹窗传更大值） */
  @Param canvasWidth: number = 180;
  @Param canvasHeight: number = 180;
  /** spec 16.12：字号（默认 36/26，放大弹窗传更大值） */
  @Param amountFontSize: number = 36;
  @Param labelFontSize: number = 26;
  /** Canvas 渲染上下文设置 */
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  /** Canvas 渲染上下文 */
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  /** spec 修复：数据加载后重绘环形图 */
  @Monitor('composition')
  onCompositionChange(monitor: IMonitor): void {
    this.drawDonut();
  }

  build() {
    Canvas(this.context)
      .width(this.canvasWidth)
      .height(this.canvasHeight)
      .onReady(() => {
        this.drawDonut();
      })
  }

  /** 绘制环形图 */
  private drawDonut(): void {
    const ctx: CanvasRenderingContext2D = this.context;
    const w: number = this.canvasWidth;
    const h: number = this.canvasHeight;
    const cx: number = w / 2;
    const cy: number = h / 2;
    // spec 16.12：半径与线宽按尺寸比例缩放
    const radius: number = Math.min(w, h) * 0.36;
    const lineWidth: number = Math.min(w, h) * 0.12;

    // spec 16.8：先清空画布，避免重绘叠加导致显示异常
    ctx.clearRect(0, 0, w, h);

    // 背景圆环
    ctx.strokeStyle = '#F6F6F4';
    ctx.lineWidth = lineWidth;
    ctx.beginPath();
    ctx.arc(cx, cy, radius, 0, Math.PI * 2);
    ctx.stroke();

    // 绘制各段弧（spec 16.8：使用 round 线帽避免段间缝隙）
    if (this.composition.length === 0) {
      return;
    }
    let startAngle: number = -Math.PI / 2;
    const total: number = this.composition.reduce((s: number, c: IncomeComposition): number => s + c.percent, 0);
    if (total <= 0) {
      return;
    }
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

    // 中心文字：金额（spec 16.11/16.12：字号可配置，放大弹窗传更大值）
    ctx.fillStyle = '#1A1A1A';
    ctx.font = `800 ${this.amountFontSize}px HarmonyOS Sans SC, sans-serif`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(`¥${this.centerAmount.toLocaleString()}`, cx, cy - 12);
    // 中心文字：本月收入（spec 16.11/16.12：字号可配置）
    ctx.fillStyle = '#999999';
    ctx.font = `${this.labelFontSize}px HarmonyOS Sans SC, sans-serif`;
    ctx.fillText('本月收入', cx, cy + 18);
  }
}
