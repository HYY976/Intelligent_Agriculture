/**
 * product_manage - 商品管理 Pro（spec 3.2.4.5 / 第3章 商品管理）
 *
 * 对齐设计稿 pages/product-mgmt-pro.html：
 *  - 顶部栏：返回 + "商品管理" + 黄色"新增"按钮
 *  - 4 KPI 卡片（2x2 网格）：在售商品/待审核/已下架/总库存（含趋势）
 *  - 近7天销量趋势卡（Canvas 折线图 + 较上周 +9.4%）
 *  - 商品竞争力五维雷达图卡（价格力80/品质90/销量75/好评95/复购70）
 *  - 库存健康分布环形图卡（充足60%/预警28%/紧缺12%）
 *  - 商品销量 TOP5 排行榜卡（带进度条）
 *  - 商品表现明细表卡（商品/销量/库存/转化率/编辑）
 *
 * spec 3.2.4.5：农户端商品管理专业版（含数据分析）
 */

import { Logger, AppConstants, NavigationHelper, RouteName, FontUtil, ModeStore, SharedProductStore, SharedProduct } from 'common';
import type { CurrentModeKey } from 'common';
import { ImageUtil } from '../../utils/ImageUtil';

/** KPI 项 */
interface KpiItem {
  /** 标签 */
  label: string;
  /** 数值 */
  value: string;
  /** 单位 */
  unit: string;
  /** 趋势文案 */
  trend: string;
  /** 是否下降 */
  isDown: boolean;
  /** 图标 emoji */
  icon: string;
  /** 图标背景色（yellow/blue/gray/green） */
  iconColor: 'yellow' | 'blue' | 'gray' | 'green';
}

/** 雷达图维度 */
interface RadarDimension {
  /** 维度名 */
  label: string;
  /** 数值（0-100） */
  value: number;
  /** 维度颜色 */
  color: string;
}

/** 库存健康度项 */
interface InventorySegment {
  /** 段名 */
  name: string;
  /** 数量 */
  count: number;
  /** 百分比 */
  percent: number;
  /** 颜色 */
  color: string;
}

/** 销量趋势点 */
interface SalesTrendPoint {
  /** X 轴标签 */
  label: string;
  /** 销量 */
  value: number;
}

/** TOP 商品排行项 */
interface TopProductItem {
  /** 排名 */
  rank: number;
  /** 商品名 */
  name: string;
  /** 商品图 key */
  imageKey: string;
  /** 销量 */
  sales: number;
  /** 进度条宽度百分比 */
  progress: number;
  /** 进度条颜色 */
  progressColor: string;
  /** 是否冠军（皇冠标） */
  isCrown: boolean;
}

/** 商品表现明细项 */
interface ProductPerfItem {
  /** 商品 ID */
  productId: string;
  /** 商品名 */
  name: string;
  /** 类目 */
  category: string;
  /** 商品图 key */
  imageKey: string;
  /** 销量 */
  sales: number;
  /** 库存 */
  stock: number;
  /** 是否库存紧缺 */
  isLow: boolean;
  /** 转化率（0-100） */
  conversion: number;
  /** 转化率进度条颜色 */
  conversionColor: string;
}

/** 跳转商品编辑页的路由参数 */
interface ProductEditParam {
  productId: string;
}

@ComponentV2
export struct ProductManage {
  /** 当前模式（spec 16.6：老人模式字体放大） */
  @Local modeRef: CurrentModeKey = ModeStore.connectModeRef();

  /** spec 16.10：放大查看的图表类型（null 表示不显示放大弹窗） */
  @Local enlargedChart: string | null = null;

  /** spec 16.6：当前是否老年大字模式 */
  private isElder(): boolean {
    return FontUtil.isElder(this.modeRef.value);
  }

  /** KPI 数据 */
  private kpiList: KpiItem[] = [
    { label: '在售商品', value: '48', unit: '件', trend: '5.2% 同比', isDown: false, icon: '🛍', iconColor: 'yellow' },
    { label: '待审核', value: '3', unit: '件', trend: '2 件新增', isDown: false, icon: '⏱', iconColor: 'blue' },
    { label: '已下架', value: '7', unit: '件', trend: '2 件减少', isDown: true, icon: '✕', iconColor: 'gray' },
    { label: '总库存', value: '12,580', unit: '', trend: '8.6% 同比', isDown: false, icon: '📦', iconColor: 'green' }
  ];

  /** 销量趋势数据（7天） */
  private salesTrend: SalesTrendPoint[] = [
    { label: '周一', value: 28 },
    { label: '周二', value: 35 },
    { label: '周三', value: 32 },
    { label: '周四', value: 42 },
    { label: '周五', value: 48 },
    { label: '周六', value: 56 },
    { label: '周日', value: 52 }
  ];

  /** 雷达图维度 */
  private radarDimensions: RadarDimension[] = [
    { label: '价格力', value: 80, color: '#FF9F1C' },
    { label: '品质', value: 90, color: '#7ED321' },
    { label: '销量', value: 75, color: '#4A90E2' },
    { label: '好评', value: 95, color: '#7ED321' },
    { label: '复购', value: 70, color: '#FF9F1C' }
  ];

  /** 库存健康度 */
  private inventorySegments: InventorySegment[] = [
    { name: '库存充足', count: 29, percent: 60, color: '#7ED321' },
    { name: '库存预警', count: 13, percent: 28, color: '#FFD93D' },
    { name: '库存紧缺', count: 6, percent: 12, color: '#FF4D4F' }
  ];

  /** TOP 商品排行 */
  private topProducts: TopProductItem[] = [
    { rank: 1, name: '红颜草莓', imageKey: 'prod_strawberry', sales: 412, progress: 100, progressColor: '#FFD93D', isCrown: true },
    { rank: 2, name: '有机番茄', imageKey: 'prod_tomato', sales: 318, progress: 77, progressColor: '#7ED321', isCrown: false },
    { rank: 3, name: '云雾毛尖', imageKey: 'prod_tea', sales: 256, progress: 62, progressColor: '#FF9F1C', isCrown: false },
    { rank: 4, name: '五常大米', imageKey: 'prod_rice', sales: 198, progress: 48, progressColor: '#8B4513', isCrown: false },
    { rank: 5, name: '土蜂蜜', imageKey: 'prod_honey', sales: 142, progress: 34, progressColor: '#999999', isCrown: false }
  ];

  /** 商品表现明细（spec 16.9：@Local 支持同步发布商品后刷新） */
  @Local perfList: ProductPerfItem[] = [
    {
      productId: 'p001',
      name: '红颜草莓',
      category: '新鲜果蔬',
      imageKey: 'prod_strawberry',
      sales: 412,
      stock: 1240,
      isLow: false,
      conversion: 72,
      conversionColor: '#7ED321'
    },
    {
      productId: 'p002',
      name: '有机番茄',
      category: '新鲜果蔬',
      imageKey: 'prod_tomato',
      sales: 318,
      stock: 860,
      isLow: false,
      conversion: 65,
      conversionColor: '#FFD93D'
    },
    {
      productId: 'p003',
      name: '云雾毛尖',
      category: '茶饮冲调',
      imageKey: 'prod_tea',
      sales: 256,
      stock: 42,
      isLow: true,
      conversion: 58,
      conversionColor: '#FF9F1C'
    },
    {
      productId: 'p004',
      name: '五常大米',
      category: '粮油调味',
      imageKey: 'prod_rice',
      sales: 198,
      stock: 520,
      isLow: false,
      conversion: 51,
      conversionColor: '#FF9F1C'
    },
    {
      productId: 'p005',
      name: '土蜂蜜',
      category: '特产滋补',
      imageKey: 'prod_honey',
      sales: 142,
      stock: 280,
      isLow: false,
      conversion: 44,
      conversionColor: '#FF9F1C'
    }
  ];

  aboutToAppear(): void {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'product_manage_pro_appear' });
    this.syncPublishedProducts();
  }

  onPageShow(): void {
    // spec 16.9：从发布页返回后刷新，确保新发布商品立即显示
    this.syncPublishedProducts();
  }

  /** spec 16.9：同步 SharedProductStore 中已发布商品到商品表现明细 */
  private async syncPublishedProducts(): Promise<void> {
    try {
      const shared: SharedProduct[] = await SharedProductStore.getAll();
      const existingIds: Set<string> = new Set<string>(this.perfList.map(
        (p: ProductPerfItem): string => p.productId
      ));
      shared.forEach((p: SharedProduct) => {
        if (!existingIds.has(p.productId)) {
          const category: string = this.categoryIdToName(p.categoryId);
          const isLow: boolean = p.stock < 50;
          this.perfList.unshift({
            productId: p.productId,
            name: p.title,
            category: category,
            imageKey: p.mainImages.length > 0 ? p.mainImages[0] : 'prod_default',
            sales: p.monthlySales,
            stock: p.stock,
            isLow: isLow,
            conversion: 0,
            conversionColor: '#FF9F1C'
          });
        }
      });
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, {
        action: 'product_manage_sync_fail',
        error: (err as Error).message
      });
    }
  }

  /** spec 16.9：categoryId → 类目名映射（与发布页保持一致） */
  private categoryIdToName(categoryId: string): string {
    const map: Record<string, string> = {
      'cat_vegetable': '新鲜果蔬',
      'cat_fruit': '时令水果',
      'cat_rice': '粮油调味',
      'cat_tea': '茶饮冲调',
      'cat_meat': '肉蛋禽类',
      'cat_honey': '特产滋补'
    };
    return map[categoryId] ?? '其他';
  }

  /** 跳转新增商品 */
  private gotoPublish(): void {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'goto_product_publish' });
    NavigationHelper.push(RouteName.FARMER_PRODUCT_PUBLISH);
  }

  /** 跳转编辑商品 */
  private gotoEdit(productId: string): void {
    const param: ProductEditParam = { productId: productId };
    Logger.info(AppConstants.SCENE_FARMER, { action: 'goto_product_edit', productId });
    NavigationHelper.push(RouteName.FARMER_PRODUCT_EDIT, param);
  }

  /** KPI 图标背景色 */
  private kpiIconBg(c: 'yellow' | 'blue' | 'gray' | 'green'): Resource {
    if (c === 'yellow') {
      return $r('app.color.color_pill_sale');
    } else if (c === 'blue') {
      return $r('app.color.color_pill_pending');
    } else if (c === 'green') {
      return $r('app.color.color_pill_settled');
    }
    return $r('app.color.color_pill_withdrawn');
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          this.TopBar()
          Scroll() {
            Column({ space: 16 }) {
              this.KpiGrid()
              this.SalesTrendCard()
              this.RadarCard()
              this.InventoryHealthCard()
              this.TopProductsCard()
              this.ProductPerfCard()
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

        // spec 16.10：图表放大弹窗（点击图表卡片触发）
        if (this.enlargedChart !== null) {
          this.ChartEnlargedDialog()
        }
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
  }

  /** spec 16.10：图表放大弹窗（全屏覆盖，重新绘制大尺寸图表） */
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
            .fontSize(18)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
          Text('×')
            .fontSize(28)
            .fontColor(Color.White)
            .width(40)
            .height(40)
            .textAlign(TextAlign.Center)
            .onClick(() => { this.enlargedChart = null; })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 放大的图表区域（白色背景，便于阅读）
        Column() {
          Scroll() {
            if (this.enlargedChart === 'sales_trend') {
              SalesTrendChartCanvas({ points: this.salesTrend })
                .width(680)
                .height(380)
            } else if (this.enlargedChart === 'radar') {
              RadarChartCanvas({ dimensions: this.radarDimensions })
                .width(640)
                .height(520)
            } else if (this.enlargedChart === 'donut') {
              DonutChartCanvas({ segments: this.inventorySegments, totalCount: 48 })
                .width(560)
                .height(560)
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')
        }
        .width('100%')
        .padding(20)
        .borderRadius(16)
        .backgroundColor($r('app.color.color_bg_card'))
      }
      .width('92%')
      .height('85%')
      .padding(20)
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.Center)
  }

  /** spec 16.10：放大弹窗标题 */
  private getEnlargedChartTitle(): string {
    if (this.enlargedChart === 'sales_trend') {
      return '近7天销量趋势（放大）';
    } else if (this.enlargedChart === 'radar') {
      return '商品竞争力雷达图（放大）';
    } else if (this.enlargedChart === 'donut') {
      return '库存健康分布（放大）';
    }
    return '图表放大';
  }

  /** 顶部导航栏：返回 + 标题 + 新增按钮 */
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
      Text('商品管理')
        .fontSize(FontUtil.s(19, this.isElder()))
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      // 黄色新增按钮
      Row({ space: 4 }) {
        Text('+')
          .fontSize(FontUtil.s(17, this.isElder()))
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        Text('新增')
          .fontSize(FontUtil.s(14, this.isElder()))
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .height(32)
      .padding({ left: 12, right: 12 })
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor($r('app.color.color_yellow'))
      .onClick(() => this.gotoPublish())
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
      ForEach(this.kpiList, (kpi: KpiItem) => {
        GridItem() {
          this.KpiCard(kpi)
        }
      }, (kpi: KpiItem) => kpi.label)
    }
    .columnsTemplate('1fr 1fr')
    .rowsGap(12)
    .columnsGap(12)
    .width('100%')
    .height(220)
  }

  /** 单个 KPI 卡 */
  @Builder
  KpiCard(kpi: KpiItem) {
    Column({ space: 8 }) {
      // 顶部行：标签 + 图标
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

      // 数值大字
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

      // 趋势
      Row({ space: 4 }) {
        Text(kpi.isDown ? '↓' : '↑')
          .fontSize(FontUtil.s(12, this.isElder()))
          .fontColor(kpi.isDown ? $r('app.color.color_live') : $r('app.color.color_primary'))
          .fontWeight(FontWeight.Bold)
        Text(kpi.trend)
          .fontSize(FontUtil.s(12, this.isElder()))
          .fontColor(kpi.isDown ? $r('app.color.color_live') : $r('app.color.color_primary'))
      }
    }
    .width('100%')
    .padding(14)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 近7天销量趋势卡 */
  @Builder
  SalesTrendCard() {
    Column({ space: 12 }) {
      // 标题行
      Row() {
        Text('近7天销量趋势')
          .fontSize(FontUtil.s(17, this.isElder()))
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Row({ space: 4 }) {
          Text('较上周')
            .fontSize(FontUtil.s(14, this.isElder()))
            .fontColor($r('app.color.color_text_hint'))
          Text('+9.4%')
            .fontSize(FontUtil.s(14, this.isElder()))
            .fontColor($r('app.color.color_green_deep'))
            .fontWeight(FontWeight.Bold)
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 折线图（spec 16.8：固定宽度，支持横向滑动；spec 16.10：点击放大）
      Scroll() {
        SalesTrendChartCanvas({ points: this.salesTrend })
          .width(380)
          .height(160)
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .onClick(() => { this.enlargedChart = 'sales_trend'; })
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 商品竞争力雷达图卡（spec 16.8：横向滚动拓宽可用面积） */
  @Builder
  RadarCard() {
    Column({ space: 12 }) {
      // 标题行
      Row() {
        Text('商品竞争力')
          .fontSize(FontUtil.s(17, this.isElder()))
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text('综合 82')
          .fontSize(FontUtil.s(14, this.isElder()))
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_yellow'))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 雷达图（spec 16.8：固定宽度，支持横向滑动；spec 16.10：点击放大）
      Scroll() {
        RadarChartCanvas({ dimensions: this.radarDimensions })
          .width(360)
          .height(260)
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .onClick(() => { this.enlargedChart = 'radar'; })

      // 图例（垂直排列，避免遮挡）
      Scroll() {
        Row({ space: 16 }) {
          ForEach(this.radarDimensions, (dim: RadarDimension) => {
            Column({ space: 4 }) {
              Row({ space: 6 }) {
                Text('')
                  .width(14)
                  .height(14)
                  .borderRadius(7)
                  .backgroundColor(dim.color)
                Text(dim.label)
                  .fontSize(FontUtil.s(14, this.isElder()))
                  .fontColor($r('app.color.color_text_secondary'))
              }
              Text(`${dim.value}`)
                .fontSize(FontUtil.s(15, this.isElder()))
                .fontColor($r('app.color.color_text_primary'))
                .fontWeight(FontWeight.Bold)
            }
            .alignItems(HorizontalAlign.Start)
          }, (dim: RadarDimension) => dim.label)
        }
        .padding({ top: 4, bottom: 4 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 库存健康分布环形图卡 */
  @Builder
  InventoryHealthCard() {
    Column({ space: 12 }) {
      // 标题行
      Row() {
        Text('库存健康分布')
          .fontSize(FontUtil.s(17, this.isElder()))
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Row({ space: 4 }) {
          Text('共')
            .fontSize(FontUtil.s(14, this.isElder()))
            .fontColor($r('app.color.color_text_hint'))
          Text('48')
            .fontSize(FontUtil.s(14, this.isElder()))
            .fontColor($r('app.color.color_text_primary'))
            .fontWeight(FontWeight.Bold)
          Text('SKU')
            .fontSize(FontUtil.s(14, this.isElder()))
            .fontColor($r('app.color.color_text_hint'))
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 环形图 + 图例（spec 16.8：横向滚动避免标签遮挡；spec 16.10：点击放大）
      Scroll() {
        Row({ space: 20 }) {
          DonutChartCanvas({ segments: this.inventorySegments, totalCount: 48 })
          // 图例列表（垂直排列，确保不重叠）
          Column({ space: 14 }) {
            ForEach(this.inventorySegments, (seg: InventorySegment) => {
              Column({ space: 6 }) {
                // 第一行：色点 + 名称
                Row({ space: 10 }) {
                  Column()
                    .width(16)
                    .height(16)
                    .borderRadius(8)
                    .backgroundColor(seg.color)
                  Text(seg.name)
                    .fontSize(FontUtil.s(16, this.isElder()))
                    .fontColor($r('app.color.color_text_secondary'))
                    .fontWeight(FontWeight.Medium)
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)

                // 第二行：数量 + 百分比
                Row({ space: 6 }) {
                  Text(`${seg.count}`)
                    .fontSize(FontUtil.s(17, this.isElder()))
                    .fontColor($r('app.color.color_text_primary'))
                    .fontWeight(FontWeight.Bold)
                  Text(`SKU · ${seg.percent}%`)
                    .fontSize(FontUtil.s(14, this.isElder()))
                    .fontColor($r('app.color.color_text_hint'))
                }
              }
              .width(150)
              .alignItems(HorizontalAlign.Start)
              .padding({ bottom: 4 })
            }, (seg: InventorySegment) => seg.name)
          }
          .alignItems(HorizontalAlign.Start)
          .justifyContent(FlexAlign.Center)
        }
        .padding({ left: 4, right: 4 })
      }
      .onClick(() => { this.enlargedChart = 'donut'; })
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 商品销量 TOP5 排行榜卡 */
  @Builder
  TopProductsCard() {
    Column({ space: 12 }) {
      // 标题行
      Row() {
        Text('商品销量 TOP5')
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

      // 排行列表
      ForEach(this.topProducts, (item: TopProductItem) => {
        this.TopProductRow(item)
      }, (item: TopProductItem) => `${item.rank}_${item.name}`)
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 单条 TOP 排行 */
  @Builder
  TopProductRow(item: TopProductItem) {
    Row({ space: 10 }) {
      // 排名号
      Text(`${item.rank}`)
        .fontSize(item.rank <= 3 ? FontUtil.s(17, this.isElder()) : FontUtil.s(14, this.isElder()))
        .fontColor(item.rank === 1 ? '#FFD93D' : (item.rank === 2 ? '#7ED321' : (item.rank === 3 ? '#FF9F1C' : '#999999')))
        .fontWeight(FontWeight.Bold)
        .width(24)
        .textAlign(TextAlign.Center)
      // 商品图（含皇冠标）
      Stack() {
        Image(ImageUtil.get(item.imageKey))
          .width(40)
          .height(40)
          .borderRadius(8)
          .objectFit(ImageFit.Cover)
        if (item.isCrown) {
          Text('冠')
            .fontSize(FontUtil.s(10, this.isElder()))
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .backgroundColor($r('app.color.color_yellow'))
            .padding({ left: 3, right: 3, top: 1, bottom: 1 })
            .borderRadius(4)
            .position({ x: -4, y: -4 })
        }
      }
      .width(40)
      .height(40)
      // 商品名 + 进度条
      Column({ space: 4 }) {
        Text(item.name)
          .fontSize(FontUtil.s(14, this.isElder()))
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Medium)
        // 进度条
        Stack({ alignContent: Alignment.Start }) {
          // 底层灰轨
          Column()
            .width('100%')
            .height(5)
            .borderRadius(2)
            .backgroundColor($r('app.color.color_bg_page'))
          // 上层彩色进度
          Column()
            .width(`${item.progress}%`)
            .height(5)
            .borderRadius(2)
            .backgroundColor(item.progressColor)
        }
        .width('100%')
        .height(5)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      // 销量
      Row() {
        Text(`${item.sales}`)
          .fontSize(FontUtil.s(14, this.isElder()))
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Bold)
        Text('件')
          .fontSize(FontUtil.s(11, this.isElder()))
          .fontColor($r('app.color.color_text_hint'))
      }
      .alignItems(VerticalAlign.Bottom)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  /** 商品表现明细表卡 */
  @Builder
  ProductPerfCard() {
    Column({ space: 12 }) {
      // 标题行
      Row() {
        Text('商品表现明细')
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

      // 表头
      Row() {
        Text('商品')
          .fontSize(FontUtil.s(13, this.isElder()))
          .fontColor($r('app.color.color_text_hint'))
          .layoutWeight(2)
        Text('销量')
          .fontSize(FontUtil.s(13, this.isElder()))
          .fontColor($r('app.color.color_text_hint'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text('库存')
          .fontSize(FontUtil.s(13, this.isElder()))
          .fontColor($r('app.color.color_text_hint'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text('转化率')
          .fontSize(FontUtil.s(13, this.isElder()))
          .fontColor($r('app.color.color_text_hint'))
          .layoutWeight(1.5)
          .textAlign(TextAlign.Center)
        Text('')
          .layoutWeight(0.6)
      }
      .width('100%')
      .padding({ bottom: 8 })
      .border({ width: { bottom: 1 }, color: $r('app.color.color_divider') })

      // 数据行
      ForEach(this.perfList, (item: ProductPerfItem) => {
        this.PerfRow(item)
      }, (item: ProductPerfItem) => item.productId)
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 单条商品表现行 */
  @Builder
  PerfRow(item: ProductPerfItem) {
    Row() {
      // 商品列（图 + 名 + 类目）
      Row({ space: 8 }) {
        Image(ImageUtil.get(item.imageKey))
          .width(36)
          .height(36)
          .borderRadius(6)
          .objectFit(ImageFit.Cover)
        Column({ space: 2 }) {
          Text(item.name)
            .fontSize(FontUtil.s(13, this.isElder()))
            .fontColor($r('app.color.color_text_primary'))
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(item.category)
            .fontSize(FontUtil.s(11, this.isElder()))
            .fontColor($r('app.color.color_text_hint'))
        }
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(2)
      .alignItems(VerticalAlign.Center)

      // 销量
      Text(`${item.sales}`)
        .fontSize(FontUtil.s(13, this.isElder()))
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 库存（紧缺时红色）
      Row() {
        Text(`${item.stock}`)
          .fontSize(FontUtil.s(13, this.isElder()))
          .fontColor(item.isLow ? $r('app.color.color_live') : $r('app.color.color_text_primary'))
          .fontWeight(item.isLow ? FontWeight.Bold : FontWeight.Medium)
        if (item.isLow) {
          Text('紧缺')
            .fontSize(FontUtil.s(10, this.isElder()))
            .fontColor(Color.White)
            .backgroundColor($r('app.color.color_live'))
            .padding({ left: 3, right: 3, top: 1, bottom: 1 })
            .borderRadius(3)
            .margin({ left: 2 })
        }
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      // 转化率（带迷你进度条）
      Column({ space: 2 }) {
        Stack({ alignContent: Alignment.Start }) {
          Column()
            .width('100%')
            .height(4)
            .borderRadius(2)
            .backgroundColor($r('app.color.color_bg_page'))
          Column()
            .width(`${item.conversion}%`)
            .height(4)
            .borderRadius(2)
            .backgroundColor(item.conversionColor)
        }
        .width('100%')
        .height(4)
        Text(`${item.conversion}%`)
          .fontSize(FontUtil.s(11, this.isElder()))
          .fontColor($r('app.color.color_text_hint'))
      }
      .layoutWeight(1.5)
      .alignItems(HorizontalAlign.Center)

      // 编辑按钮
      Text('✎')
        .fontSize(FontUtil.s(16, this.isElder()))
        .fontColor($r('app.color.color_text_secondary'))
        .layoutWeight(0.6)
        .textAlign(TextAlign.Center)
        .onClick(() => this.gotoEdit(item.productId))
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .alignItems(VerticalAlign.Center)
    .border({ width: { bottom: 1 }, color: $r('app.color.color_divider') })
  }
}

/**
 * SalesTrendChartCanvas - 销量趋势折线图（Canvas 自绘）
 * 对齐设计稿：黄色折线 + 渐变填充 + 数据点
 */
@ComponentV2
struct SalesTrendChartCanvas {
  /** 数据点 */
  @Param points: SalesTrendPoint[] = [];
  /** Canvas 设置 */
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  /** Canvas 上下文 */
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  build() {
    Canvas(this.context)
      .width(330)
      .height(140)
      .onReady(() => {
        this.drawChart();
      })
  }

  private drawChart(): void {
    const ctx: CanvasRenderingContext2D = this.context;
    if (this.points.length === 0) {
      return;
    }
    const w: number = 330;
    const h: number = 140;
    const padL: number = 14;
    const padR: number = 14;
    const padT: number = 16;
    const padB: number = 26;
    const chartW: number = w - padL - padR;
    const chartH: number = h - padT - padB;

    const maxVal: number = Math.max(...this.points.map((p: SalesTrendPoint): number => p.value)) * 1.15;
    const minVal: number = 0;
    const range: number = maxVal - minVal || 1;

    const step: number = chartW / (this.points.length - 1);
    const coords: SalesCoord[] = this.points.map(
      (p: SalesTrendPoint, i: number): SalesCoord => {
        const x: number = padL + step * i;
        const y: number = padT + chartH - ((p.value - minVal) / range) * chartH;
        return { x, y, value: p.value, label: p.label };
      }
    );

    // 1. 网格线
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

    // 2. 渐变填充
    const gradient: CanvasGradient = ctx.createLinearGradient(0, padT, 0, padT + chartH);
    gradient.addColorStop(0, 'rgba(255,217,61,0.45)');
    gradient.addColorStop(1, 'rgba(255,217,61,0)');
    ctx.fillStyle = gradient;
    ctx.beginPath();
    ctx.moveTo(coords[0].x, padT + chartH);
    coords.forEach((c: SalesCoord, i: number) => {
      if (i === 0) {
        ctx.lineTo(c.x, c.y);
      } else {
        const prev: SalesCoord = coords[i - 1];
        const cpX: number = (prev.x + c.x) / 2;
        ctx.bezierCurveTo(cpX, prev.y, cpX, c.y, c.x, c.y);
      }
    });
    ctx.lineTo(coords[coords.length - 1].x, padT + chartH);
    ctx.closePath();
    ctx.fill();

    // 3. 折线
    ctx.strokeStyle = '#FFD93D';
    ctx.lineWidth = 2.6;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.beginPath();
    coords.forEach((c: SalesCoord, i: number) => {
      if (i === 0) {
        ctx.moveTo(c.x, c.y);
      } else {
        const prev: SalesCoord = coords[i - 1];
        const cpX: number = (prev.x + c.x) / 2;
        ctx.bezierCurveTo(cpX, prev.y, cpX, c.y, c.x, c.y);
      }
    });
    ctx.stroke();

    // 4. 数据点
    coords.forEach((c: SalesCoord) => {
      ctx.fillStyle = '#FFFFFF';
      ctx.beginPath();
      ctx.arc(c.x, c.y, 3, 0, Math.PI * 2);
      ctx.fill();
      ctx.strokeStyle = '#FFD93D';
      ctx.lineWidth = 2;
      ctx.stroke();
    });

    // 5. X 轴标签（spec 16.9：放大字号到 16px 提升可读性）
    ctx.fillStyle = '#999999';
    ctx.font = '16px HarmonyOS Sans SC, sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';
    coords.forEach((c: SalesCoord) => {
      ctx.fillText(c.label, c.x, h - padB + 6);
    });
  }
}

/** SalesCoord - 销量折线图坐标点 */
interface SalesCoord {
  x: number;
  y: number;
  value: number;
  label: string;
}

/**
 * RadarChartCanvas - 五维雷达图（Canvas 自绘）
 * 对齐设计稿：同心五边形网格 + 数据多边形 + 顶点圆 + 维度标签
 */
@ComponentV2
struct RadarChartCanvas {
  /** 维度数据 */
  @Param dimensions: RadarDimension[] = [];
  /** Canvas 设置 */
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  /** Canvas 上下文 */
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  build() {
    Canvas(this.context)
      .width(330)
      .height(240)
      .onReady(() => {
        this.drawRadar();
      })
  }

  private drawRadar(): void {
    const ctx: CanvasRenderingContext2D = this.context;
    if (this.dimensions.length === 0) {
      return;
    }
    const w: number = 330;
    const h: number = 240;
    const cx: number = w / 2;
    const cy: number = h / 2 + 10;
    const maxRadius: number = 88;
    const n: number = this.dimensions.length;
    const angleStep: number = (Math.PI * 2) / n;
    const startAngle: number = -Math.PI / 2; // 顶部开始

    // 1. 同心五边形网格（5层）
    ctx.strokeStyle = '#F0F0F0';
    ctx.lineWidth = 1;
    for (let layer: number = 1; layer <= 5; layer++) {
      const r: number = (maxRadius * layer) / 5;
      ctx.beginPath();
      for (let i: number = 0; i < n; i++) {
        const angle: number = startAngle + angleStep * i;
        const x: number = cx + r * Math.cos(angle);
        const y: number = cy + r * Math.sin(angle);
        if (i === 0) {
          ctx.moveTo(x, y);
        } else {
          ctx.lineTo(x, y);
        }
      }
      ctx.closePath();
      ctx.stroke();
    }

    // 2. 轴线（从中心到顶点）
    ctx.strokeStyle = '#E8E8E8';
    ctx.lineWidth = 1;
    for (let i: number = 0; i < n; i++) {
      const angle: number = startAngle + angleStep * i;
      ctx.beginPath();
      ctx.moveTo(cx, cy);
      ctx.lineTo(cx + maxRadius * Math.cos(angle), cy + maxRadius * Math.sin(angle));
      ctx.stroke();
    }

    // 3. 数据多边形
    ctx.fillStyle = 'rgba(255,217,61,0.45)';
    ctx.strokeStyle = '#FFD93D';
    ctx.lineWidth = 2.2;
    ctx.lineJoin = 'round';
    ctx.beginPath();
    for (let i: number = 0; i < n; i++) {
      const dim: RadarDimension = this.dimensions[i];
      const angle: number = startAngle + angleStep * i;
      const r: number = (maxRadius * dim.value) / 100;
      const x: number = cx + r * Math.cos(angle);
      const y: number = cy + r * Math.sin(angle);
      if (i === 0) {
        ctx.moveTo(x, y);
      } else {
        ctx.lineTo(x, y);
      }
    }
    ctx.closePath();
    ctx.fill();
    ctx.stroke();

    // 4. 数据顶点圆
    for (let i: number = 0; i < n; i++) {
      const dim: RadarDimension = this.dimensions[i];
      const angle: number = startAngle + angleStep * i;
      const r: number = (maxRadius * dim.value) / 100;
      const x: number = cx + r * Math.cos(angle);
      const y: number = cy + r * Math.sin(angle);
      ctx.fillStyle = '#FFD93D';
      ctx.beginPath();
      ctx.arc(x, y, 4, 0, Math.PI * 2);
      ctx.fill();
      ctx.strokeStyle = '#1A1A1A';
      ctx.lineWidth = 1.8;
      ctx.stroke();
    }

    // 5. 维度标签 + 数值（spec 16.9：放大字号提升可读性）
    ctx.font = '700 17px HarmonyOS Sans SC, sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    for (let i: number = 0; i < n; i++) {
      const dim: RadarDimension = this.dimensions[i];
      const angle: number = startAngle + angleStep * i;
      const labelR: number = maxRadius + 22;
      const valueR: number = maxRadius + 40;
      const lx: number = cx + labelR * Math.cos(angle);
      const ly: number = cy + labelR * Math.sin(angle);
      const vx: number = cx + valueR * Math.cos(angle);
      const vy: number = cy + valueR * Math.sin(angle);
      // 标签
      ctx.fillStyle = '#1A1A1A';
      ctx.fillText(dim.label, lx, ly);
      // 数值
      ctx.fillStyle = dim.color;
      ctx.font = '700 16px HarmonyOS Sans SC, sans-serif';
      ctx.fillText(`${dim.value}`, vx, vy);
      ctx.font = '700 17px HarmonyOS Sans SC, sans-serif';
    }
  }
}

/**
 * DonutChartCanvas - 库存健康度环形图（Canvas 自绘）
 * 对齐设计稿：背景环 + 多段彩色弧 + 中心数字
 */
@ComponentV2
struct DonutChartCanvas {
  /** 段数据 */
  @Param segments: InventorySegment[] = [];
  /** 中心总数 */
  @Param totalCount: number = 0;
  /** Canvas 设置 */
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  /** Canvas 上下文 */
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  build() {
    Canvas(this.context)
      .width(150)
      .height(150)
      .onReady(() => {
        this.drawDonut();
      })
  }

  private drawDonut(): void {
    const ctx: CanvasRenderingContext2D = this.context;
    if (this.segments.length === 0) {
      return;
    }
    const w: number = 150;
    const h: number = 150;
    const cx: number = w / 2;
    const cy: number = h / 2;
    const radius: number = 56;
    const lineWidth: number = 18;

    // spec 16.8：先清空画布避免重绘叠加
    ctx.clearRect(0, 0, w, h);

    // 1. 背景环
    ctx.strokeStyle = '#F6F6F4';
    ctx.lineWidth = lineWidth;
    ctx.beginPath();
    ctx.arc(cx, cy, radius, 0, Math.PI * 2);
    ctx.stroke();

    // 2. 各段弧
    let startAngle: number = -Math.PI / 2;
    this.segments.forEach((seg: InventorySegment) => {
      const sweepAngle: number = (seg.percent / 100) * Math.PI * 2;
      ctx.strokeStyle = seg.color;
      ctx.lineWidth = lineWidth;
      ctx.beginPath();
      ctx.arc(cx, cy, radius, startAngle, startAngle + sweepAngle);
      ctx.stroke();
      startAngle += sweepAngle;
    });

    // 3. 中心数字（spec 16.9：放大字号提升可读性）
    ctx.fillStyle = '#1A1A1A';
    ctx.font = '800 32px HarmonyOS Sans SC, sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(`${this.totalCount}`, cx, cy - 10);
    ctx.fillStyle = '#999999';
    ctx.font = '600 15px HarmonyOS Sans SC, sans-serif';
    ctx.fillText('SKU 总数', cx, cy + 16);
  }
}
