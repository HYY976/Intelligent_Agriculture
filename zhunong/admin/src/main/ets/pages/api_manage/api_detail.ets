/**
 * api_detail - API 详情（spec 3.3.2 / 10.8.3.2）
 *
 * - 接口基本信息卡：路径 + 方法 + 描述 + 创建时间
 * - 请求量趋势图（近 7 天，Mock 柱状图）
 * - 错误日志列表（Mock，最近 20 条，含时间 + 状态码 + 错误信息 + 客户端 IP）
 *
 * 越权防御（spec 10.8.8）：aboutToAppear 校验 super_admin / api_admin
 * 全部 Mock 数据（spec 10.8.3.2）
 */

import { Logger, AppConstants, ToastUtil, TokenStore, AdminRoutes, NavigationHelper, RouteName, RouterParam, ListStateView } from 'common';
import { AdminInfo } from 'common';
import {
  ApiDetailAggregate,
  ApiRequestTrendPoint,
  ApiErrorLog,
  HttpMethod,
  AdminRole
} from '../../model/AdminModels';
import { ApiRepository } from '../../repository/ApiRepository';

@ComponentV2
export struct ApiDetail {
  /** 路由参数：API ID */
  @Local apiId: string = '';
  /** 详情聚合数据 */
  @Local detail: ApiDetailAggregate | null = null;
  /** 是否正在加载 */
  @Local isLoading: boolean = false;
  /** 加载失败 */
  @Local loadFailed: boolean = false;

  async aboutToAppear(): Promise<void> {
    // 越权防御（spec 10.8.8）
    const adminInfo: AdminInfo | null = await TokenStore.getAdminInfo();
    if (!adminInfo) {
      ToastUtil.warning('请先登录');
      NavigationHelper.replace(RouteName.ADMIN_LOGIN);
      return;
    }
    const allowedRoles: AdminRole[] = ['super_admin', 'api_admin'];
    if (allowedRoles.indexOf(adminInfo.role as AdminRole) < 0) {
      ToastUtil.warning('无权限访问该页面');
      NavigationHelper.pop();
      return;
    }
    // 读取路由参数（spec 10.6.4：NavigationHelper.getParam as Record<string, string>）
    const params = NavigationHelper.getParam<Record<string, string>>();
    if (params && params.apiId) {
      this.apiId = params.apiId;
    }
    Logger.info(AppConstants.SCENE_ADMIN, { action: 'api_detail_appear', adminId: adminInfo.adminId, apiId: this.apiId });
    await this.loadDetail();
  }

  /** 加载详情 */
  private async loadDetail(): Promise<void> {
    if (this.apiId.length === 0) {
      ToastUtil.warning('缺少接口 ID');
      NavigationHelper.pop();
      return;
    }
    this.isLoading = true;
    this.loadFailed = false;
    try {
      this.detail = await ApiRepository.getApiDetail(this.apiId);
      if (!this.detail) {
        ToastUtil.warning('接口不存在');
        NavigationHelper.pop();
        return;
      }
    } catch (err) {
      this.loadFailed = true;
      Logger.error(AppConstants.SCENE_ADMIN, { action: 'load_api_detail_fail', error: (err as Error).message });
    } finally {
      this.isLoading = false;
    }
  }

  /** 方法 Tag 背景色 */
  private methodBg(method: HttpMethod): Resource {
    if (method === 'GET') {
      return $r('app.color.color_green_soft');
    } else if (method === 'POST') {
      return $r('app.color.color_info_soft');
    } else if (method === 'PUT') {
      return $r('app.color.color_warn_soft');
    }
    return $r('app.color.color_live_soft');
  }

  /** 方法 Tag 文字色 */
  private methodColor(method: HttpMethod): Resource {
    if (method === 'GET') {
      return $r('app.color.color_green_deep');
    } else if (method === 'POST') {
      return $r('app.color.color_info_deep');
    } else if (method === 'PUT') {
      return $r('app.color.color_warn_deep');
    }
    return $r('app.color.color_live');
  }

  /** 状态码文字色 */
  private statusCodeColor(code: number): Resource {
    if (code >= 500) {
      return $r('app.color.color_error');
    } else if (code >= 400) {
      return $r('app.color.color_secondary');
    }
    return $r('app.color.color_primary');
  }

  /** 格式化时间戳 */
  private formatTime(ts: number): string {
    const d: Date = new Date(ts);
    const y: number = d.getFullYear();
    const m: string = (d.getMonth() + 1).toString().padStart(2, '0');
    const day: string = d.getDate().toString().padStart(2, '0');
    const hh: string = d.getHours().toString().padStart(2, '0');
    const mi: string = d.getMinutes().toString().padStart(2, '0');
    return `${y}-${m}-${day} ${hh}:${mi}`;
  }

  /** 计算趋势图最大值（用于柱状图高度比例） */
  private trendMaxValue(): number {
    if (!this.detail || this.detail.trend.length === 0) {
      return 1;
    }
    let max: number = 0;
    for (const p of this.detail.trend) {
      if (p.requestCount > max) {
        max = p.requestCount;
      }
    }
    return max > 0 ? max : 1;
  }

  /** 计算单根柱子高度比例（0~1） */
  private barHeightRatio(point: ApiRequestTrendPoint): number {
    const max: number = this.trendMaxValue();
    if (max === 0) {
      return 0;
    }
    return Math.max(point.requestCount / max, 0.05); // 最小可见高度
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        if (this.loadFailed) {
          ListStateView({ state: 'error', onRefresh: () => this.loadDetail() })
        } else if (!this.detail) {
          ListStateView({ state: 'loading' })
        } else {
          Scroll() {
            Column({ space: 12 }) {
              this.InfoCard()
              this.TrendCard()
              this.ErrorLogCard()
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 12, bottom: 24 })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 顶部导航：圆形返回键 + 居中标题 */
  @Builder
  TopBar() {
    Row() {
      Stack() {
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
      .onClick(() => NavigationHelper.pop())

      Text('接口详情')
        .fontSize(17)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 占位保持标题居中
      Column().width(32).height(32)
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16, top: 4, bottom: 10 })
    .alignItems(VerticalAlign.Center)
  }

  /** 接口基本信息卡（对齐 api-detail.html：方法 pill + 路径 + 描述 + meta 行） */
  @Builder
  InfoCard() {
    Column({ space: 8 }) {
      // 方法 pill + 路径
      Row({ space: 8 }) {
        Text(this.detail!.apiInfo.method)
          .fontSize(11)
          .fontColor(this.methodColor(this.detail!.apiInfo.method))
          .backgroundColor(this.methodBg(this.detail!.apiInfo.method))
          .padding({ left: 7, right: 7, top: 2, bottom: 2 })
          .borderRadius(AppConstants.RADIUS_XS)
          .fontWeight(FontWeight.Bold)
        Text(this.detail!.apiInfo.path)
          .fontSize(13)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 描述
      Text(this.detail!.apiInfo.description)
        .fontSize(13)
        .fontColor($r('app.color.color_text_2'))
        .width('100%')

      // meta 行（请求方式 / 响应格式 / 鉴权 / 版本）
      Divider().color($r('app.color.color_line')).strokeWidth(1)
      this.MetaRow('请求方式', this.detail!.apiInfo.method)
      Divider().color($r('app.color.color_line')).strokeWidth(1)
      this.MetaRow('响应格式', 'JSON')
      Divider().color($r('app.color.color_line')).strokeWidth(1)
      this.MetaRow('鉴权', 'Bearer Token')
      Divider().color($r('app.color.color_line')).strokeWidth(1)
      this.MetaRow('版本', 'v1')
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** meta 行（label + value） */
  @Builder
  MetaRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor($r('app.color.color_text_3'))
      Blank()
      Text(value)
        .fontSize(13)
        .fontColor($r('app.color.color_ink_2'))
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .padding({ top: 9, bottom: 9 })
    .alignItems(VerticalAlign.Center)
  }

  /** 请求量趋势图（近 7 天，Mock 柱状图） */
  @Builder
  TrendCard() {
    Column({ space: 8 }) {
      Row() {
        Text('请求量趋势（近 7 天）')
          .fontSize(14)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
        Text('Mock')
          .fontSize(10)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')

      // 柱状图区
      Row({ space: 8 }) {
        ForEach(this.detail!.trend, (point: ApiRequestTrendPoint, _idx: number) => {
          Column({ space: 4 }) {
            // 数值
            Text(`${(point.requestCount / 1000).toFixed(1)}k`)
              .fontSize(9)
              .fontColor($r('app.color.color_text_secondary'))

            // 柱子
            Stack({ alignContent: Alignment.Bottom }) {
              Column()
                .width('100%')
                .height(`${this.barHeightRatio(point) * 100}%`)
                .backgroundColor($r('app.color.color_cta_black'))
                .borderRadius({ topLeft: 4, topRight: 4 })
            }
            .width('100%')
            .height(100)

            // 日期（MM-DD）
            Text(point.date.substring(5))
              .fontSize(9)
              .fontColor($r('app.color.color_text_hint'))
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        }, (point: ApiRequestTrendPoint) => point.date)
      }
      .width('100%')
      .height(140)
      .padding({ top: 4, bottom: 4 })
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 错误日志列表 */
  @Builder
  ErrorLogCard() {
    Column({ space: 8 }) {
      Row() {
        Text('错误日志')
          .fontSize(14)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
        Text(`最近 ${this.detail!.recentErrors.length} 条`)
          .fontSize(10)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')

      if (this.detail!.recentErrors.length === 0) {
        Text('暂无错误日志')
          .fontSize(12)
          .fontColor($r('app.color.color_text_hint'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 12, bottom: 12 })
      } else {
        ForEach(this.detail!.recentErrors, (log: ApiErrorLog) => {
          this.ErrorLogItem(log)
        }, (log: ApiErrorLog) => log.logId)
      }
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 错误日志项 */
  @Builder
  ErrorLogItem(log: ApiErrorLog) {
    Column({ space: 4 }) {
      Row({ space: 8 }) {
        Text(`${log.statusCode}`)
          .fontSize(12)
          .fontColor(this.statusCodeColor(log.statusCode))
          .fontWeight(FontWeight.Bold)
        Text(log.errorMessage)
          .fontSize(12)
          .fontColor($r('app.color.color_text_primary'))
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')

      Row({ space: 12 }) {
        Text(`IP：${log.clientIp}`)
          .fontSize(10)
          .fontColor($r('app.color.color_text_hint'))
          .layoutWeight(1)
        Text(this.formatTime(log.occurredAt))
          .fontSize(10)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .border({ width: { bottom: 0.5 }, color: $r('app.color.color_divider') })
  }
}
