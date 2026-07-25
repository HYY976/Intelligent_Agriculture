/**
 * market_quote - 市场行情页（spec 3.2.4.5 / 第7章 行情中心）
 *
 * 对齐设计稿 pages/market-quote.html：
 *  - 顶部栏：返回 + "市场行情" + 筛选
 *  - 品类横滑胶囊（果蔬/粮油/禽蛋/茶饮/特产）
 *  - 黄色行情总览英雄卡（综合均价 + 景气指数仪表盘）
 *  - 近30天价格走势卡（双折线：今年 vs 去年，Canvas 自绘）
 *  - 热门行情卡（5条商品行 + sparkline 迷你折线 + 涨跌胶囊）
 *  - 价格预警卡（3条预警 + Toggle 开关 + 添加预警按钮）
 *
 * spec 3.2.4.5：农户端查看市场行情，辅助定价决策
 */

import { Logger, AppConstants, NavigationHelper, RouteName } from 'common';
import { ImageUtil } from '../../utils/ImageUtil';

/** 行情品类 */
type MarketCategory = 'fruit' | 'grain' | 'egg' | 'tea' | 'special';

/** 品类选项 */
interface CategoryOption {
  value: MarketCategory;
  label: string;
}

/** 价格走势数据点 */
interface PriceTrendPoint {
  /** X 轴标签 */
  label: string;
  /** 今年价格 */
  current: number;
  /** 去年价格 */
  lastYear: number;
}

/** 热门商品行情 */
interface HotQuoteItem {
  /** 商品名 */
  name: string;
  /** 商品图 key */
  imageKey: string;
  /** 价格 */
  price: number;
  /** 单位 */
  unit: string;
  /** 涨跌幅（正数涨/负数跌） */
  changePercent: number;
  /** sparkline 数据点 */
  spark: number[];
}

/** 价格预警项 */
interface PriceAlert {
  /** 预警 ID */
  alertId: string;
  /** 商品名 */
  name: string;
  /** 比较运算符（>= / <=） */
  operator: '>=' | '<=';
  /** 触发价格 */
  targetPrice: number;
  /** 单位 */
  unit: string;
  /** 是否启用 */
  enabled: boolean;
}

@ComponentV2
export struct MarketQuote {
  /** 当前品类 */
  @Local category: MarketCategory = 'fruit';
  /** 预警列表 */
  @Local alerts: PriceAlert[] = [];

  /** 品类选项 */
  private categoryOptions: CategoryOption[] = [
    { value: 'fruit', label: '果蔬' },
    { value: 'grain', label: '粮油' },
    { value: 'egg', label: '禽蛋' },
    { value: 'tea', label: '茶饮' },
    { value: 'special', label: '特产' }
  ];

  /** 价格走势数据（30天，7个采样点） */
  private trendPoints: PriceTrendPoint[] = [
    { label: '7/1', current: 9.2, lastYear: 9.8 },
    { label: '7/5', current: 10.1, lastYear: 10.2 },
    { label: '7/9', current: 11.3, lastYear: 10.8 },
    { label: '7/13', current: 12.5, lastYear: 11.4 },
    { label: '7/17', current: 14.2, lastYear: 12.0 },
    { label: '7/21', current: 15.2, lastYear: 11.6 },
    { label: '7/24', current: 12.8, lastYear: 11.2 }
  ];

  /** 热门行情数据 */
  private hotItems: HotQuoteItem[] = [
    {
      name: '红颜草莓',
      imageKey: 'prod_strawberry',
      price: 39.9,
      unit: '/斤',
      changePercent: 12.5,
      spark: [28, 30, 32, 35, 38, 39.9]
    },
    {
      name: '普罗旺斯番茄',
      imageKey: 'prod_tomato',
      price: 6.8,
      unit: '/斤',
      changePercent: -5.2,
      spark: [8.2, 7.8, 7.5, 7.2, 7.0, 6.8]
    },
    {
      name: '五常稻花香米',
      imageKey: 'prod_rice',
      price: 8.5,
      unit: '/kg',
      changePercent: 3.8,
      spark: [7.8, 8.0, 7.9, 8.2, 8.4, 8.5]
    },
    {
      name: '农家土鸡蛋',
      imageKey: 'prod_eggs',
      price: 18.9,
      unit: '/盒',
      changePercent: -2.1,
      spark: [19.5, 19.3, 19.4, 19.0, 19.0, 18.9]
    },
    {
      name: '云雾毛尖茶',
      imageKey: 'prod_tea',
      price: 128,
      unit: '/斤',
      changePercent: 8.6,
      spark: [110, 115, 118, 122, 125, 128]
    }
  ];

  aboutToAppear(): void {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'market_quote_appear', range: this.category });
    this.initAlerts();
  }

  /** 初始化预警数据 */
  private initAlerts(): void {
    this.alerts = [
      { alertId: 'a1', name: '红颜草莓', operator: '>=', targetPrice: 45, unit: '/斤', enabled: true },
      { alertId: 'a2', name: '五常稻花香米', operator: '<=', targetPrice: 7.5, unit: '/kg', enabled: true },
      { alertId: 'a3', name: '农家土鸡蛋', operator: '>=', targetPrice: 22, unit: '/盒', enabled: false }
    ];
  }

  /** 切换品类 */
  private onCategoryChange(c: MarketCategory): void {
    this.category = c;
    Logger.info(AppConstants.SCENE_FARMER, { action: 'market_category_change', range: c });
  }

  /** 切换预警开关 */
  private toggleAlert(alertId: string): void {
    const idx: number = this.alerts.findIndex((a: PriceAlert): boolean => a.alertId === alertId);
    if (idx >= 0) {
      this.alerts[idx].enabled = !this.alerts[idx].enabled;
      Logger.info(AppConstants.SCENE_FARMER, {
        action: 'alert_toggle',
        productId: alertId,
        msg: this.alerts[idx].enabled ? 'on' : 'off'
      });
    }
  }

  /** 获取品类综合均价 */
  private getAvgPrice(): number {
    return 12.8;
  }

  /** 获取品类标签 */
  private getCategoryLabel(): string {
    const opt: CategoryOption | undefined = this.categoryOptions.find((c: CategoryOption): boolean => c.value === this.category);
    return opt ? opt.label : '果蔬';
  }

  /** 涨跌颜色 */
  private changeColor(p: number): Resource {
    return p >= 0 ? $r('app.color.color_primary') : $r('app.color.color_live');
  }

  /** 涨跌箭头 */
  private changeArrow(p: number): string {
    return p >= 0 ? '↑' : '↓';
  }

  /** 涨跌文案 */
  private changeText(p: number): string {
    return `${this.changeArrow(p)}${Math.abs(p).toFixed(1)}%`;
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        this.CategoryBar()
        Scroll() {
          Column({ space: 16 }) {
            this.HeroCard()
            this.PriceTrendCard()
            this.HotQuoteCard()
            this.PriceAlertCard()
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

  /** 顶部导航栏 */
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
      Text('市场行情')
        .fontSize(18)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Text('⚙')
        .fontSize(20)
        .fontColor($r('app.color.color_text_primary'))
        .width(40)
        .height(40)
        .textAlign(TextAlign.Center)
        .onClick(() => Logger.info(AppConstants.SCENE_FARMER, { action: 'market_filter_click' }))
    }
    .width('100%')
    .height(56)
    .padding({ left: 12, right: 12 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** 品类横滑胶囊栏 */
  @Builder
  CategoryBar() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.categoryOptions, (opt: CategoryOption) => {
          Text(opt.label)
            .fontSize(13)
            .fontColor(this.category === opt.value ? $r('app.color.color_ink') : $r('app.color.color_text_secondary'))
            .fontWeight(this.category === opt.value ? FontWeight.Bold : FontWeight.Normal)
            .backgroundColor(this.category === opt.value ? $r('app.color.color_yellow') : $r('app.color.color_bg_card'))
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .borderRadius(AppConstants.RADIUS_PILL)
            .onClick(() => { this.onCategoryChange(opt.value); })
        }, (opt: CategoryOption) => opt.value)
      }
      .padding({ left: 16, right: 16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .height(44)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 黄色行情总览英雄卡（含景气指数仪表盘） */
  @Builder
  HeroCard() {
    Row() {
      // 左侧：品类 + 综合均价 + 涨幅
      Column({ space: 6 }) {
        Text(`${this.getCategoryLabel()} · 综合行情`)
          .fontSize(12)
          .fontColor('rgba(26,26,26,0.6)')
          .fontWeight(FontWeight.Medium)
        Row() {
          Text('¥')
            .fontSize(14)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .margin({ right: 2 })
          Text(this.getAvgPrice().toFixed(1))
            .fontSize(32)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
          Text('/斤')
            .fontSize(12)
            .fontColor('rgba(26,26,26,0.6)')
            .margin({ left: 4 })
        }
        .alignItems(VerticalAlign.Bottom)
        Row() {
          Text('综合均价 · 较昨日 ')
            .fontSize(11)
            .fontColor('rgba(26,26,26,0.6)')
          Text('↑8.3%')
            .fontSize(11)
            .fontColor($r('app.color.color_green_deep'))
            .fontWeight(FontWeight.Bold)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 右侧：景气指数仪表盘（半圆 SVG 替代 → Canvas 简化版）
      this.GaugeIndicator()
    }
    .width('100%')
    .padding(20)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_yellow'))
    .alignItems(VerticalAlign.Center)
  }

  /** 景气指数仪表盘（半圆 + 中心数字） */
  @Builder
  GaugeIndicator() {
    Stack() {
      // 半圆背景（用 Column + border 模拟）
      Column() {
        Text('78')
          .fontSize(28)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        Text('景气指数')
          .fontSize(10)
          .fontColor('rgba(26,26,26,0.6)')
          .fontWeight(FontWeight.Medium)
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .width(96)
    .height(76)
    .borderRadius(48)
    .border({ width: 6, color: 'rgba(26,26,26,0.12)' })
    .backgroundColor('rgba(255,255,255,0.4)')
    .alignContent(Alignment.Center)
  }

  /** 近30天价格走势卡（Canvas 双折线） */
  @Builder
  PriceTrendCard() {
    Column({ space: 12 }) {
      // 标题行
      Row() {
        Text('近30天价格走势')
          .fontSize(14)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Row({ space: 4 }) {
          Text('均价')
            .fontSize(11)
            .fontColor($r('app.color.color_text_hint'))
          Text(`¥${this.getAvgPrice().toFixed(1)}/斤`)
            .fontSize(11)
            .fontColor($r('app.color.color_text_primary'))
            .fontWeight(FontWeight.Bold)
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 折线图
      TrendChartCanvas({ points: this.trendPoints })
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 热门行情卡 */
  @Builder
  HotQuoteCard() {
    Column({ space: 12 }) {
      // 标题行
      Row() {
        Text('热门行情')
          .fontSize(14)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text('全部 ›')
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 商品列表
      ForEach(this.hotItems, (item: HotQuoteItem) => {
        this.HotQuoteRow(item)
      }, (item: HotQuoteItem) => item.name)
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 热门商品行 */
  @Builder
  HotQuoteRow(item: HotQuoteItem) {
    Row({ space: 12 }) {
      // 商品图
      Image(ImageUtil.get(item.imageKey))
        .width(48)
        .height(48)
        .borderRadius(8)
        .objectFit(ImageFit.Cover)

      // 商品信息
      Column({ space: 4 }) {
        Text(item.name)
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Medium)
        Row({ space: 6 }) {
          Text(`¥${item.price.toFixed(1)}`)
            .fontSize(13)
            .fontColor($r('app.color.color_price'))
            .fontWeight(FontWeight.Bold)
          Text(item.unit)
            .fontSize(10)
            .fontColor($r('app.color.color_text_hint'))
          // 涨跌胶囊
          Text(this.changeText(item.changePercent))
            .fontSize(10)
            .fontColor(this.changeColor(item.changePercent))
            .fontWeight(FontWeight.Bold)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(AppConstants.RADIUS_PILL)
            .backgroundColor(item.changePercent >= 0 ? $r('app.color.color_pill_sale') : $r('app.color.color_pill_refund'))
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // Sparkline 迷你折线
      SparkLineCanvas({ data: item.spark, isUp: item.changePercent >= 0 })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  /** 价格预警卡 */
  @Builder
  PriceAlertCard() {
    Column({ space: 12 }) {
      // 标题行
      Row() {
        Text('价格预警')
          .fontSize(14)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Row({ space: 4 }) {
          Text('已开启')
            .fontSize(11)
            .fontColor($r('app.color.color_text_hint'))
          Text(`${this.alerts.filter((a: PriceAlert): boolean => a.enabled).length}`)
            .fontSize(11)
            .fontColor($r('app.color.color_text_primary'))
            .fontWeight(FontWeight.Bold)
          Text('条')
            .fontSize(11)
            .fontColor($r('app.color.color_text_hint'))
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 预警列表
      ForEach(this.alerts, (alert: PriceAlert) => {
        this.AlertRow(alert)
      }, (alert: PriceAlert) => alert.alertId + (alert.enabled ? '_on' : '_off'))

      // 添加预警按钮
      Row({ space: 6 }) {
        Text('+')
          .fontSize(16)
          .fontColor($r('app.color.color_text_secondary'))
          .fontWeight(FontWeight.Bold)
        Text('添加预警')
          .fontSize(13)
          .fontColor($r('app.color.color_text_secondary'))
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .height(44)
      .borderRadius(AppConstants.RADIUS_MD)
      .backgroundColor($r('app.color.color_bg_page'))
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => Logger.info(AppConstants.SCENE_FARMER, { action: 'add_alert_click' }))
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 单条预警行 */
  @Builder
  AlertRow(alert: PriceAlert) {
    Row({ space: 12 }) {
      // 铃铛图标
      Text('🔔')
        .fontSize(17)
        .width(36)
        .height(36)
        .borderRadius(18)
        .backgroundColor(alert.enabled ? $r('app.color.color_pill_sale') : $r('app.color.color_bg_page'))
        .textAlign(TextAlign.Center)
      // 预警信息
      Column({ space: 2 }) {
        Text(alert.name)
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Medium)
        Row({ space: 4 }) {
          Text('当价格')
            .fontSize(11)
            .fontColor($r('app.color.color_text_hint'))
          Text(`${alert.operator}`)
            .fontSize(11)
            .fontColor($r('app.color.color_text_secondary'))
            .fontWeight(FontWeight.Bold)
          Text(`¥${alert.targetPrice.toFixed(1)}`)
            .fontSize(11)
            .fontColor($r('app.color.color_text_primary'))
            .fontWeight(FontWeight.Bold)
          Text(alert.unit)
            .fontSize(10)
            .fontColor($r('app.color.color_text_hint'))
          Text('时提醒')
            .fontSize(11)
            .fontColor($r('app.color.color_text_hint'))
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      // Toggle 开关
      this.ToggleSwitch(alert.enabled, alert.alertId)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  /** Toggle 开关（自绘，避免引入额外组件） */
  @Builder
  ToggleSwitch(on: boolean, alertId: string) {
    Stack() {
      // 圆点
      Text('')
        .width(20)
        .height(20)
        .borderRadius(10)
        .backgroundColor(Color.White)
        .shadow({ radius: 2, color: 'rgba(0,0,0,0.2)', offsetX: 0, offsetY: 1 })
        .position({ x: on ? 22 : 2, y: 2 })
    }
    .width(44)
    .height(24)
    .borderRadius(12)
    .backgroundColor(on ? $r('app.color.color_primary') : $r('app.color.color_text_hint'))
    .onClick(() => this.toggleAlert(alertId))
  }
}

/**
 * TrendChartCanvas - 价格走势双折线图（Canvas 自绘）
 * 对齐设计稿：今年黄色实线 + 去年灰色虚线 + 数据点 + 峰值气泡
 */
@ComponentV2
struct TrendChartCanvas {
  /** 数据点 */
  @Param points: PriceTrendPoint[] = [];
  /** Canvas 渲染上下文设置 */
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  /** Canvas 渲染上下文 */
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  build() {
    Canvas(this.context)
      .width('100%')
      .height(160)
      .onReady(() => {
        this.drawChart();
      })
  }

  /** 绘制双折线图 */
  private drawChart(): void {
    const ctx: CanvasRenderingContext2D = this.context;
    if (this.points.length === 0) {
      return;
    }
    const w: number = 330;
    const h: number = 160;
    const padL: number = 30;
    const padR: number = 14;
    const padT: number = 16;
    const padB: number = 28;
    const chartW: number = w - padL - padR;
    const chartH: number = h - padT - padB;

    // 计算最大/最小值
    const allVals: number[] = [];
    this.points.forEach((p: PriceTrendPoint) => {
      allVals.push(p.current);
      allVals.push(p.lastYear);
    });
    const maxVal: number = Math.max(...allVals) * 1.1;
    const minVal: number = Math.min(...allVals) * 0.9;
    const range: number = maxVal - minVal || 1;

    // 计算坐标
    const step: number = chartW / (this.points.length - 1);
    const currentCoords: TrendCoord[] = this.points.map(
      (p: PriceTrendPoint, i: number): TrendCoord => {
        const x: number = padL + step * i;
        const y: number = padT + chartH - ((p.current - minVal) / range) * chartH;
        return { x, y, value: p.current, label: p.label };
      }
    );
    const lastYearCoords: TrendCoord[] = this.points.map(
      (p: PriceTrendPoint, i: number): TrendCoord => {
        const x: number = padL + step * i;
        const y: number = padT + chartH - ((p.lastYear - minVal) / range) * chartH;
        return { x, y, value: p.lastYear, label: p.label };
      }
    );

    // 1. 水平参考网格线
    ctx.strokeStyle = '#F0F0F0';
    ctx.lineWidth = 1;
    ctx.setLineDash([3, 4]);
    for (let i: number = 1; i <= 2; i++) {
      const y: number = padT + (chartH / 3) * i;
      ctx.beginPath();
      ctx.moveTo(padL, y);
      ctx.lineTo(w - padR, y);
      ctx.stroke();
    }
    ctx.setLineDash([]);

    // 2. Y 轴价格标签
    ctx.fillStyle = '#999999';
    ctx.font = '600 9px HarmonyOS Sans SC, sans-serif';
    ctx.textAlign = 'end';
    ctx.textBaseline = 'middle';
    ctx.fillText(`¥${maxVal.toFixed(0)}`, padL - 4, padT);
    ctx.fillText(`¥${((maxVal + minVal) / 2).toFixed(0)}`, padL - 4, padT + chartH / 2);
    ctx.fillText(`¥${minVal.toFixed(0)}`, padL - 4, padT + chartH);

    // 3. 今年折线渐变填充
    const gradient: CanvasGradient = ctx.createLinearGradient(0, padT, 0, padT + chartH);
    gradient.addColorStop(0, 'rgba(255,217,61,0.42)');
    gradient.addColorStop(1, 'rgba(255,217,61,0)');
    ctx.fillStyle = gradient;
    ctx.beginPath();
    ctx.moveTo(currentCoords[0].x, padT + chartH);
    currentCoords.forEach((c: TrendCoord, i: number) => {
      if (i === 0) {
        ctx.lineTo(c.x, c.y);
      } else {
        const prev: TrendCoord = currentCoords[i - 1];
        const cpX: number = (prev.x + c.x) / 2;
        ctx.bezierCurveTo(cpX, prev.y, cpX, c.y, c.x, c.y);
      }
    });
    ctx.lineTo(currentCoords[currentCoords.length - 1].x, padT + chartH);
    ctx.closePath();
    ctx.fill();

    // 4. 去年虚线（灰）
    ctx.strokeStyle = '#BFBFBF';
    ctx.lineWidth = 1.8;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.setLineDash([4, 3]);
    ctx.beginPath();
    lastYearCoords.forEach((c: TrendCoord, i: number) => {
      if (i === 0) {
        ctx.moveTo(c.x, c.y);
      } else {
        ctx.lineTo(c.x, c.y);
      }
    });
    ctx.stroke();
    ctx.setLineDash([]);

    // 5. 今年实线（黄）
    ctx.strokeStyle = '#FFD93D';
    ctx.lineWidth = 2.6;
    ctx.beginPath();
    currentCoords.forEach((c: TrendCoord, i: number) => {
      if (i === 0) {
        ctx.moveTo(c.x, c.y);
      } else {
        const prev: TrendCoord = currentCoords[i - 1];
        const cpX: number = (prev.x + c.x) / 2;
        ctx.bezierCurveTo(cpX, prev.y, cpX, c.y, c.x, c.y);
      }
    });
    ctx.stroke();

    // 6. 去年数据点（白底灰边）
    lastYearCoords.forEach((c: TrendCoord) => {
      ctx.fillStyle = '#FFFFFF';
      ctx.beginPath();
      ctx.arc(c.x, c.y, 2, 0, Math.PI * 2);
      ctx.fill();
      ctx.strokeStyle = '#BFBFBF';
      ctx.lineWidth = 1.4;
      ctx.stroke();
    });

    // 7. 今年数据点（白底黄边）+ 峰值高亮
    currentCoords.forEach((c: TrendCoord) => {
      const isPeak: boolean = c.value === Math.max(...currentCoords.map((p: TrendCoord): number => p.value));
      if (isPeak) {
        // 峰值高亮：黄色实心点 + 黑边 + 气泡
        ctx.fillStyle = '#FFD93D';
        ctx.beginPath();
        ctx.arc(c.x, c.y, 4.4, 0, Math.PI * 2);
        ctx.fill();
        ctx.strokeStyle = '#1A1A1A';
        ctx.lineWidth = 2;
        ctx.stroke();
        // 气泡（圆角矩形）
        ctx.fillStyle = '#1A1A1A';
        const bw: number = 66;
        const bh: number = 16;
        const bx: number = c.x - bw / 2;
        const by: number = c.y - bh - 10;
        ctx.beginPath();
        ctx.moveTo(bx + 8, by);
        ctx.lineTo(bx + bw - 8, by);
        ctx.arcTo(bx + bw, by, bx + bw, by + 8, 8);
        ctx.lineTo(bx + bw, by + bh - 8);
        ctx.arcTo(bx + bw, by + bh, bx + bw - 8, by + bh, 8);
        ctx.lineTo(bx + 8, by + bh);
        ctx.arcTo(bx, by + bh, bx, by + bh - 8, 8);
        ctx.lineTo(bx, by + 8);
        ctx.arcTo(bx, by, bx + 8, by, 8);
        ctx.fill();
        // 气泡文字
        ctx.fillStyle = '#FFE234';
        ctx.font = '800 9.5px HarmonyOS Sans SC, sans-serif';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(`峰值 ¥${c.value.toFixed(1)}`, c.x, by + bh / 2);
      } else {
        ctx.fillStyle = '#FFFFFF';
        ctx.beginPath();
        ctx.arc(c.x, c.y, 2.6, 0, Math.PI * 2);
        ctx.fill();
        ctx.strokeStyle = '#FFD93D';
        ctx.lineWidth = 2;
        ctx.stroke();
      }
    });

    // 8. X 轴日期标签
    ctx.fillStyle = '#999999';
    ctx.font = '600 9px HarmonyOS Sans SC, sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';
    currentCoords.forEach((c: TrendCoord) => {
      ctx.fillText(c.label, c.x, h - padB + 8);
    });
  }
}

/**
 * TrendCoord - 折线图坐标点
 */
interface TrendCoord {
  /** X 轴坐标 */
  x: number;
  /** Y 轴坐标 */
  y: number;
  /** 数值 */
  value: number;
  /** X 轴标签 */
  label: string;
}

/**
 * SparkCoord - Sparkline 坐标点
 */
interface SparkCoord {
  /** X 轴坐标 */
  x: number;
  /** Y 轴坐标 */
  y: number;
}

/**
 * SparkLineCanvas - 迷你折线图（用于热门行情商品行）
 */
@ComponentV2
struct SparkLineCanvas {
  /** 数据点 */
  @Param data: number[] = [];
  /** 是否上涨（绿色）/下跌（红色） */
  @Param isUp: boolean = true;
  /** Canvas 渲染上下文设置 */
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  /** Canvas 渲染上下文 */
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  build() {
    Canvas(this.context)
      .width(56)
      .height(28)
      .onReady(() => {
        this.drawSpark();
      })
  }

  /** 绘制 sparkline */
  private drawSpark(): void {
    const ctx: CanvasRenderingContext2D = this.context;
    if (this.data.length === 0) {
      return;
    }
    const w: number = 56;
    const h: number = 28;
    const pad: number = 2;
    const chartW: number = w - pad * 2;
    const chartH: number = h - pad * 2;

    const maxVal: number = Math.max(...this.data);
    const minVal: number = Math.min(...this.data);
    const range: number = maxVal - minVal || 1;

    const step: number = chartW / (this.data.length - 1);
    const coords: SparkCoord[] = this.data.map(
      (v: number, i: number): SparkCoord => {
        const x: number = pad + step * i;
        const y: number = pad + chartH - ((v - minVal) / range) * chartH;
        return { x, y };
      }
    );

    const lineColor: string = this.isUp ? '#7ED321' : '#FF4D4F';
    const fillColor: string = this.isUp ? 'rgba(126,211,33,0.15)' : 'rgba(255,77,79,0.12)';

    // 填充区域
    ctx.fillStyle = fillColor;
    ctx.beginPath();
    ctx.moveTo(coords[0].x, h - pad);
    coords.forEach((c: SparkCoord) => {
      ctx.lineTo(c.x, c.y);
    });
    ctx.lineTo(coords[coords.length - 1].x, h - pad);
    ctx.closePath();
    ctx.fill();

    // 折线
    ctx.strokeStyle = lineColor;
    ctx.lineWidth = 1.8;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.beginPath();
    coords.forEach((c: SparkCoord, i: number) => {
      if (i === 0) {
        ctx.moveTo(c.x, c.y);
      } else {
        ctx.lineTo(c.x, c.y);
      }
    });
    ctx.stroke();

    // 末端点
    const last: SparkCoord = coords[coords.length - 1];
    ctx.fillStyle = lineColor;
    ctx.beginPath();
    ctx.arc(last.x, last.y, 2, 0, Math.PI * 2);
    ctx.fill();
  }
}
