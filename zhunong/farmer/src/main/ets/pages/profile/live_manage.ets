/**
 * live_manage - 直播管理 Pro（spec 3.2.4.5 / 第4章 直播）
 *
 * 对齐设计稿 pages/live-management.html：
 *  - 顶部栏：返回 + "直播管理" + 黄色"开播"按钮（带脉冲点）
 *  - 4 KPI 卡片（2x2 网格）：累计场次/总观看/直播成交/新增粉丝
 *  - 直播概览卡（健康分仪表盘 + 近7天观看人数柱状图）
 *  - 直播记录列表（缩略图 + 标题 + 观看数 + 成交额 + 状态胶囊 + 数据按钮）
 *
 * spec 3.2.4.5：农户端直播管理专业版（含数据分析）
 */

import { Logger, AppConstants, NavigationHelper, RouteName, LiveStatus, FontUtil, ModeStore } from 'common';
import type { CurrentModeKey } from 'common';
import { ImageUtil } from '../../utils/ImageUtil';
import { LiveStatusBroadcaster } from '../live/live_room';

/** KPI 项 */
interface LiveKpiItem {
  /** 标签 */
  label: string;
  /** 数值 */
  value: string;
  /** 单位 */
  unit: string;
  /** 趋势百分比 */
  trend: string;
  /** 图标 emoji */
  icon: string;
  /** 图标背景色 */
  iconColor: 'red' | 'blue' | 'yellow' | 'green';
}

/** 直播记录项 */
interface LiveRecordItem {
  /** 直播 ID */
  liveId: string;
  /** 标题 */
  title: string;
  /** 封面图 key */
  coverKey: string;
  /** 日期 */
  date: string;
  /** 观看数 */
  viewCount: string;
  /** 成交额 */
  gmv: string;
  /** 状态：living/replay */
  status: 'living' | 'replay';
  /** 时长（回放） */
  duration?: string;
}

/** 7天观看数据 */
interface ViewBar {
  /** 日期标签 */
  label: string;
  /** 观看数（万） */
  value: number;
  /** 是否峰值 */
  isPeak: boolean;
}

@ComponentV2
export struct LiveManage {
  /** 当前模式（spec 16.6：老人模式字体放大） */
  @Local modeRef: CurrentModeKey = ModeStore.connectModeRef();

  /** spec 16.6：当前是否老年大字模式 */
  private isElder(): boolean {
    return FontUtil.isElder(this.modeRef.value);
  }

  /** KPI 数据 */
  private kpiList: LiveKpiItem[] = [
    { label: '累计场次', value: '128', unit: '场', trend: '12.5%', icon: '📹', iconColor: 'red' },
    { label: '总观看', value: '86.5', unit: '万', trend: '8.3%', icon: '👁', iconColor: 'blue' },
    { label: '直播成交', value: '23.6', unit: '万', trend: '15.2%', icon: '💰', iconColor: 'yellow' },
    { label: '新增粉丝', value: '8,920', unit: '', trend: '23.0%', icon: '👥', iconColor: 'green' }
  ];

  /** 7天观看数据 */
  private viewBars: ViewBar[] = [
    { label: '7/18', value: 1.2, isPeak: false },
    { label: '7/19', value: 1.8, isPeak: false },
    { label: '7/20', value: 1.5, isPeak: false },
    { label: '7/21', value: 2.4, isPeak: false },
    { label: '7/22', value: 3.1, isPeak: true },
    { label: '7/23', value: 2.0, isPeak: false },
    { label: '7/24', value: 2.8, isPeak: false }
  ];

  /** 直播记录（spec 16.9：改为 @Local 以响应结束直播状态同步） */
  @Local records: LiveRecordItem[] = [
    {
      liveId: 'l001',
      title: '草莓专场直播',
      coverKey: 'live_orchard',
      date: '07/24',
      viewCount: '1.2万观看',
      gmv: '¥8,560',
      status: 'living'
    },
    {
      liveId: 'l002',
      title: '春茶品鉴会',
      coverKey: 'live_orchard',
      date: '07/20',
      viewCount: '8,640观看',
      gmv: '¥12,300',
      status: 'replay',
      duration: '45:08'
    },
    {
      liveId: 'l003',
      title: '番茄采摘记',
      coverKey: 'live_orchard',
      date: '07/18',
      viewCount: '2.1万观看',
      gmv: '¥6,420',
      status: 'replay',
      duration: '28:33'
    },
    {
      liveId: 'l004',
      title: '蜜桃开园直播',
      coverKey: 'live_orchard',
      date: '07/15',
      viewCount: '3.5万观看',
      gmv: '¥18,900',
      status: 'replay',
      duration: '1:02:15'
    }
  ];

  aboutToAppear(): void {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'live_manage_pro_appear' });
    this.syncEndedLives();
  }

  /** spec 16.9：页面再次显示时同步结束直播状态 */
  onPageShow(): void {
    this.syncEndedLives();
  }

  /** spec 16.9：将已结束的直播状态从 living 改为 replay，与直播间结束动作同步 */
  private syncEndedLives(): void {
    let changed: number = 0;
    this.records = this.records.map((r: LiveRecordItem): LiveRecordItem => {
      if (r.status === 'living' && LiveStatusBroadcaster.isEnded(r.liveId)) {
        changed++;
        const updated: LiveRecordItem = {
          liveId: r.liveId,
          title: r.title,
          coverKey: r.coverKey,
          date: r.date,
          viewCount: r.viewCount,
          gmv: r.gmv,
          status: 'replay',
          duration: r.duration ?? '00:00'
        };
        return updated;
      }
      return r;
    });
    if (changed > 0) {
      Logger.info(AppConstants.SCENE_FARMER, {
        action: 'live_manage_sync_ended',
        count: changed
      });
    }
  }

  /** 跳转开播 */
  private gotoLiveCreate(): void {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'goto_live_create' });
    NavigationHelper.push(RouteName.FARMER_LIVE_CREATE);
  }

  /** 跳转直播数据详情 */
  private gotoLiveData(liveId: string): void {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'goto_live_data', liveId });
  }

  /** KPI 图标背景色 */
  private kpiIconBg(c: 'red' | 'blue' | 'yellow' | 'green'): Resource {
    if (c === 'red') {
      return $r('app.color.color_pill_refund');
    } else if (c === 'blue') {
      return $r('app.color.color_pill_pending');
    } else if (c === 'yellow') {
      return $r('app.color.color_pill_sale');
    }
    return $r('app.color.color_pill_settled');
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        Scroll() {
          Column({ space: 16 }) {
            this.KpiGrid()
            this.OverviewCard()
            this.LiveRecordCard()
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

  /** 顶部导航栏：返回 + 标题 + 开播按钮 */
  @Builder
  TopBar() {
    Row() {
      Text('‹')
        .fontSize(28)
        .fontColor($r('app.color.color_text_primary'))
        .width(40)
        .height(40)
        .textAlign(TextAlign.Center)
        .onClick(() => NavigationHelper.pop())
      Text('直播管理')
        .fontSize(FontUtil.s(19, this.isElder()))
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      // 黄色开播按钮（带脉冲点）
      Row({ space: 6 }) {
        Text('')
          .width(8)
          .height(8)
          .borderRadius(4)
          .backgroundColor($r('app.color.color_live'))
        Text('开播')
          .fontSize(FontUtil.s(14, this.isElder()))
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .height(32)
      .padding({ left: 12, right: 14 })
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor($r('app.color.color_yellow'))
      .onClick(() => this.gotoLiveCreate())
    }
    .width('100%')
    .height(56)
    .padding({ left: 12, right: 12 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** 4 KPI 卡片（2x2 网格） */
  @Builder
  KpiGrid() {
    Grid() {
      ForEach(this.kpiList, (kpi: LiveKpiItem) => {
        GridItem() {
          this.KpiCard(kpi)
        }
      }, (kpi: LiveKpiItem) => kpi.label)
    }
    .columnsTemplate('1fr 1fr')
    .rowsGap(12)
    .columnsGap(12)
    .width('100%')
    .height(220)
  }

  /** 单个 KPI 卡 */
  @Builder
  KpiCard(kpi: LiveKpiItem) {
    Column({ space: 8 }) {
      Row() {
        Text(kpi.label)
          .fontSize(FontUtil.s(14, this.isElder()))
          .fontColor($r('app.color.color_text_hint'))
          .layoutWeight(1)
        Text(kpi.icon)
          .fontSize(FontUtil.s(17, this.isElder()))
          .width(32)
          .height(32)
          .borderRadius(16)
          .backgroundColor(this.kpiIconBg(kpi.iconColor))
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row() {
        Text(kpi.value)
          .fontSize(FontUtil.s(26, this.isElder()))
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Bold)
        if (kpi.unit.length > 0) {
          Text(kpi.unit)
            .fontSize(FontUtil.s(14, this.isElder()))
            .fontColor($r('app.color.color_text_hint'))
            .margin({ left: 2 })
        }
      }
      .alignItems(VerticalAlign.Bottom)

      Row({ space: 4 }) {
        Text('↑')
          .fontSize(FontUtil.s(12, this.isElder()))
          .fontColor($r('app.color.color_primary'))
          .fontWeight(FontWeight.Bold)
        Text(kpi.trend)
          .fontSize(FontUtil.s(12, this.isElder()))
          .fontColor($r('app.color.color_primary'))
        Text('同比')
          .fontSize(FontUtil.s(12, this.isElder()))
          .fontColor($r('app.color.color_text_hint'))
      }
    }
    .width('100%')
    .padding(14)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 直播概览卡（健康分仪表盘 + 7天柱状图） */
  @Builder
  OverviewCard() {
    Column({ space: 12 }) {
      // 标题行
      Row() {
        Text('直播概览')
          .fontSize(FontUtil.s(17, this.isElder()))
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Row({ space: 4 }) {
          Text('健康分')
            .fontSize(FontUtil.s(14, this.isElder()))
            .fontColor($r('app.color.color_text_hint'))
          Text('86')
            .fontSize(FontUtil.s(14, this.isElder()))
            .fontColor($r('app.color.color_text_primary'))
            .fontWeight(FontWeight.Bold)
          Text('·')
            .fontSize(FontUtil.s(14, this.isElder()))
            .fontColor($r('app.color.color_text_hint'))
          Text('良好')
            .fontSize(FontUtil.s(14, this.isElder()))
            .fontColor($r('app.color.color_green_deep'))
            .fontWeight(FontWeight.Bold)
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 仪表盘 + 柱状图
      Row({ space: 16 }) {
        // 左：健康分仪表盘（简化版用 Stack 模拟）
        Column({ space: 6 }) {
          Stack() {
            Column() {
              Text('健康分')
                .fontSize(FontUtil.s(12, this.isElder()))
                .fontColor($r('app.color.color_text_hint'))
              Text('86')
                .fontSize(FontUtil.s(28, this.isElder()))
                .fontColor($r('app.color.color_text_primary'))
                .fontWeight(FontWeight.Bold)
              Text('良好')
                .fontSize(FontUtil.s(12, this.isElder()))
                .fontColor($r('app.color.color_green_deep'))
                .fontWeight(FontWeight.Bold)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .borderRadius(AppConstants.RADIUS_PILL)
                .backgroundColor($r('app.color.color_pill_sale'))
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Center)
            .justifyContent(FlexAlign.Center)
          }
          .width(96)
          .height(96)
          .borderRadius(48)
          .border({ width: 8, color: $r('app.color.color_pill_sale') })
          .alignContent(Alignment.Center)
          Text('直播健康分')
            .fontSize(FontUtil.s(13, this.isElder()))
            .fontColor($r('app.color.color_text_hint'))
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)

        // 右：7天柱状图
        Column({ space: 6 }) {
          Text('近7天观看人数（万）')
            .fontSize(FontUtil.s(13, this.isElder()))
            .fontColor($r('app.color.color_text_hint'))
          BarChartCanvas({ bars: this.viewBars })
        }
        .layoutWeight(1.6)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 直播记录列表卡 */
  @Builder
  LiveRecordCard() {
    Column({ space: 12 }) {
      // 标题行
      Row() {
        Text('直播记录')
          .fontSize(FontUtil.s(17, this.isElder()))
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text('全部 ›')
          .fontSize(FontUtil.s(14, this.isElder()))
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 直播记录列表
      ForEach(this.records, (record: LiveRecordItem) => {
        this.RecordRow(record)
      }, (record: LiveRecordItem) => record.liveId)
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 单条直播记录行 */
  @Builder
  RecordRow(record: LiveRecordItem) {
    Row({ space: 12 }) {
      // 缩略图（带状态标）
      Stack({ alignContent: Alignment.BottomEnd }) {
        Image(ImageUtil.get(record.coverKey))
          .width(72)
          .height(72)
          .borderRadius(10)
          .objectFit(ImageFit.Cover)
        if (record.status === 'living') {
          // LIVE 标
          Row({ space: 4 }) {
            Text('')
              .width(6)
              .height(6)
              .borderRadius(3)
              .backgroundColor(Color.White)
            Text('LIVE')
              .fontSize(FontUtil.s(11, this.isElder()))
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
          }
          .padding({ left: 6, right: 6, top: 3, bottom: 3 })
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_live'))
          .position({ x: 4, y: 4 })
        } else if (record.duration) {
          // 时长标
          Text(record.duration)
            .fontSize(FontUtil.s(11, this.isElder()))
            .fontColor(Color.White)
            .backgroundColor('rgba(0,0,0,0.6)')
            .padding({ left: 4, right: 4, top: 2, bottom: 2 })
            .borderRadius(4)
            .position({ x: 4, y: 52 })
        }
      }
      .width(72)
      .height(72)

      // 直播信息
      Column({ space: 6 }) {
        Text(record.title)
          .fontSize(FontUtil.s(15, this.isElder()))
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 6 }) {
          Text(record.date)
            .fontSize(FontUtil.s(12, this.isElder()))
            .fontColor($r('app.color.color_text_hint'))
          Text('·')
            .fontSize(FontUtil.s(12, this.isElder()))
            .fontColor($r('app.color.color_text_hint'))
          Text(record.viewCount)
            .fontSize(FontUtil.s(12, this.isElder()))
            .fontColor($r('app.color.color_text_hint'))
        }
        Row({ space: 4 }) {
          Text('成交')
            .fontSize(FontUtil.s(12, this.isElder()))
            .fontColor($r('app.color.color_text_hint'))
          Text(record.gmv)
            .fontSize(FontUtil.s(13, this.isElder()))
            .fontColor($r('app.color.color_price'))
            .fontWeight(FontWeight.Bold)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 右侧：状态胶囊 + 数据按钮
      Column({ space: 8 }) {
        // 状态胶囊
        Text(record.status === 'living' ? '进行中' : '回放')
          .fontSize(FontUtil.s(12, this.isElder()))
          .fontColor(record.status === 'living' ? $r('app.color.color_live') : $r('app.color.color_text_secondary'))
          .fontWeight(FontWeight.Bold)
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor(record.status === 'living' ? $r('app.color.color_pill_refund') : $r('app.color.color_pill_withdrawn'))
        // 数据按钮
        Row({ space: 4 }) {
          Text('数据')
            .fontSize(FontUtil.s(12, this.isElder()))
            .fontColor($r('app.color.color_text_secondary'))
          Text('›')
            .fontSize(FontUtil.s(12, this.isElder()))
            .fontColor($r('app.color.color_text_secondary'))
        }
        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
        .borderRadius(AppConstants.RADIUS_PILL)
        .border({ width: 1, color: $r('app.color.color_divider') })
        .onClick(() => this.gotoLiveData(record.liveId))
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .alignItems(VerticalAlign.Center)
    .border({ width: { bottom: 1 }, color: $r('app.color.color_divider') })
  }
}

/**
 * BarChartCanvas - 7天观看人数柱状图（Canvas 自绘）
 * 对齐设计稿：黄色柱子 + 峰值标注 + X 轴标签
 */
@ComponentV2
struct BarChartCanvas {
  /** 数据点 */
  @Param bars: ViewBar[] = [];
  /** Canvas 设置 */
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  /** Canvas 上下文 */
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  build() {
    Canvas(this.context)
      .width(220)
      .height(140)
      .onReady(() => {
        this.drawBars();
      })
  }

  private drawBars(): void {
    const ctx: CanvasRenderingContext2D = this.context;
    if (this.bars.length === 0) {
      return;
    }
    const w: number = 220;
    const h: number = 140;
    const padL: number = 8;
    const padR: number = 8;
    const padT: number = 22;
    const padB: number = 24;
    const chartW: number = w - padL - padR;
    const chartH: number = h - padT - padB;

    const maxVal: number = Math.max(...this.bars.map((b: ViewBar): number => b.value)) * 1.1;
    const barWidth: number = chartW / this.bars.length * 0.6;
    const barGap: number = chartW / this.bars.length * 0.4;

    // 1. 基线
    ctx.strokeStyle = '#F0F0F0';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(padL, padT + chartH);
    ctx.lineTo(w - padR, padT + chartH);
    ctx.stroke();

    // 2. 柱子
    this.bars.forEach((bar: ViewBar, i: number) => {
      const barH: number = (bar.value / maxVal) * chartH;
      const x: number = padL + i * (barWidth + barGap) + barGap / 2;
      const y: number = padT + chartH - barH;

      // 渐变填充
      const gradient: CanvasGradient = ctx.createLinearGradient(0, y, 0, padT + chartH);
      if (bar.isPeak) {
        gradient.addColorStop(0, '#FFD93D');
        gradient.addColorStop(1, '#FFD93D');
      } else {
        gradient.addColorStop(0, '#FFE234');
        gradient.addColorStop(1, '#FFD93D');
      }
      ctx.fillStyle = gradient;
      // 圆角矩形（顶部圆角）
      const r: number = 4;
      ctx.beginPath();
      ctx.moveTo(x, y + r);
      ctx.arcTo(x, y, x + r, y, r);
      ctx.lineTo(x + barWidth - r, y);
      ctx.arcTo(x + barWidth, y, x + barWidth, y + r, r);
      ctx.lineTo(x + barWidth, padT + chartH);
      ctx.lineTo(x, padT + chartH);
      ctx.closePath();
      ctx.fill();

      // 峰值标注
      if (bar.isPeak) {
        // 黑色气泡
        const bw: number = 64;
        const bh: number = 18;
        const bx: number = x + barWidth / 2 - bw / 2;
        const by: number = y - bh - 4;
        ctx.fillStyle = '#1A1A1A';
        ctx.beginPath();
        ctx.moveTo(bx + 7, by);
        ctx.lineTo(bx + bw - 7, by);
        ctx.arcTo(bx + bw, by, bx + bw, by + 7, 7);
        ctx.lineTo(bx + bw, by + bh - 7);
        ctx.arcTo(bx + bw, by + bh, bx + bw - 7, by + bh, 7);
        ctx.lineTo(bx + 7, by + bh);
        ctx.arcTo(bx, by + bh, bx, by + bh - 7, 7);
        ctx.lineTo(bx, by + 7);
        ctx.arcTo(bx, by, bx + 7, by, 7);
        ctx.fill();
        // 气泡文字
        ctx.fillStyle = '#FFE234';
        ctx.font = '800 13px HarmonyOS Sans SC, sans-serif';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(`峰值 ${bar.value}万`, bx + bw / 2, by + bh / 2);
      }

      // X 轴标签
      ctx.fillStyle = '#999999';
      ctx.font = '600 13px HarmonyOS Sans SC, sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'top';
      ctx.fillText(bar.label, x + barWidth / 2, h - padB + 6);
    });
  }
}
