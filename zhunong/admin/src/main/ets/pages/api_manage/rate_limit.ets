/**
 * rate_limit - 限流配置（spec 3.3.2 / 10.8.3.2，对齐 rate-limit.html 设计稿）
 *
 * - 顶栏：圆形返回键 + 居中标题"限流配置"
 * - API 信息卡：方法 pill + 路径 + 描述 + "当前峰值 N QPS"
 * - 配置表单卡：QPS阈值 / 并发数限制 / 熔断阈值 / 恢复时间（label 左 + 输入框右 + tip）
 * - 当前状态卡：浅绿底 + 绿色对勾 + "当前状态：正常运行"
 * - 底部固定保存按钮（黑底"保存配置"）
 *
 * 越权防御（spec 10.8.8）：aboutToAppear 校验 super_admin / api_admin
 */

import { Logger, AppConstants, ToastUtil, TokenStore, AdminRoutes, NavigationHelper, RouteName, RouterParam, ListStateView } from 'common';
import { AdminInfo } from 'common';
import {
  ApiInfo,
  RateLimitConfig,
  RateLimitUpdateRequest,
  HttpMethod,
  AdminRole
} from '../../model/AdminModels';
import { ApiRepository } from '../../repository/ApiRepository';

@ComponentV2
export struct RateLimit {
  /** 路由参数：API ID */
  @Local apiId: string = '';
  /** API 基础信息（顶部展示） */
  @Local apiInfo: ApiInfo | null = null;
  /** 当前限流配置 */
  @Local config: RateLimitConfig | null = null;
  /** 表单：QPS 阈值 */
  @Local qpsLimit: string = '';
  /** 表单：并发数限制 */
  @Local concurrentLimit: string = '';
  /** 表单：熔断阈值（百分比，0~100） */
  @Local circuitBreakThreshold: string = '';
  /** 表单：恢复时间（秒） */
  @Local recoveryTime: string = '';
  /** 是否正在加载 */
  @Local isLoading: boolean = false;
  /** 是否正在保存 */
  @Local isSaving: boolean = false;
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
    const params = NavigationHelper.getParam<Record<string, string>>();
    if (params && params.apiId) {
      this.apiId = params.apiId;
    }
    Logger.info(AppConstants.SCENE_ADMIN, { action: 'rate_limit_appear', adminId: adminInfo.adminId, apiId: this.apiId });
    await this.loadConfig();
  }

  /** 加载配置 */
  private async loadConfig(): Promise<void> {
    if (this.apiId.length === 0) {
      ToastUtil.warning('缺少接口 ID');
      NavigationHelper.pop();
      return;
    }
    this.isLoading = true;
    this.loadFailed = false;
    try {
      // 并行拉取 API 详情 + 限流配置
      const detail = await ApiRepository.getApiDetail(this.apiId);
      if (detail) {
        this.apiInfo = detail.apiInfo;
      }
      const cfg: RateLimitConfig | null = await ApiRepository.getRateLimitConfig(this.apiId);
      if (cfg) {
        this.config = cfg;
        this.qpsLimit = `${cfg.qpsLimit}`;
        this.concurrentLimit = `${cfg.concurrentLimit}`;
        this.circuitBreakThreshold = `${(cfg.circuitBreakThreshold * 100).toFixed(1)}`;
        this.recoveryTime = `${cfg.recoveryTime}`;
      } else {
        // 兜底默认值
        this.qpsLimit = '200';
        this.concurrentLimit = '50';
        this.circuitBreakThreshold = '5.0';
        this.recoveryTime = '30';
      }
    } catch (err) {
      this.loadFailed = true;
      Logger.error(AppConstants.SCENE_ADMIN, { action: 'load_rate_limit_fail', error: (err as Error).message });
    } finally {
      this.isLoading = false;
    }
  }

  /** 表单校验 */
  private validateForm(): boolean {
    const qps: number = parseInt(this.qpsLimit, 10);
    if (isNaN(qps) || qps <= 0) {
      ToastUtil.warning('QPS 阈值需为正整数');
      return false;
    }
    if (qps > 100000) {
      ToastUtil.warning('QPS 阈值不能超过 100000');
      return false;
    }
    const concurrent: number = parseInt(this.concurrentLimit, 10);
    if (isNaN(concurrent) || concurrent <= 0) {
      ToastUtil.warning('并发数限制需为正整数');
      return false;
    }
    if (concurrent > 10000) {
      ToastUtil.warning('并发数限制不能超过 10000');
      return false;
    }
    const threshold: number = parseFloat(this.circuitBreakThreshold);
    if (isNaN(threshold) || threshold < 0 || threshold > 100) {
      ToastUtil.warning('熔断阈值需在 0~100 之间');
      return false;
    }
    const recovery: number = parseInt(this.recoveryTime, 10);
    if (isNaN(recovery) || recovery <= 0) {
      ToastUtil.warning('恢复时间需为正整数');
      return false;
    }
    return true;
  }

  /** 保存配置 */
  private async saveConfig(): Promise<void> {
    if (!this.validateForm()) {
      return;
    }
    this.isSaving = true;
    try {
      const qps: number = parseInt(this.qpsLimit, 10);
      const concurrent: number = parseInt(this.concurrentLimit, 10);
      const threshold: number = parseFloat(this.circuitBreakThreshold) / 100;
      const recovery: number = parseInt(this.recoveryTime, 10);
      const req: RateLimitUpdateRequest = {
        apiId: this.apiId,
        qpsLimit: qps,
        concurrentLimit: concurrent,
        circuitBreakThreshold: threshold,
        recoveryTime: recovery
      };
      await ApiRepository.updateRateLimit(req);
      ToastUtil.success('保存成功');
      Logger.info(AppConstants.SCENE_ADMIN, { action: 'rate_limit_save', apiId: this.apiId, qps, concurrent, threshold, recovery });
      NavigationHelper.pop();
    } catch (err) {
      Logger.error(AppConstants.SCENE_ADMIN, { action: 'rate_limit_save_fail', error: (err as Error).message });
      ToastUtil.error('保存失败');
    } finally {
      this.isSaving = false;
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

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        if (this.loadFailed) {
          ListStateView({ state: 'error', onRefresh: () => this.loadConfig() })
        } else if (this.isLoading || !this.apiInfo) {
          ListStateView({ state: 'loading' })
        } else {
          Scroll() {
            Column({ space: 12 }) {
              this.ApiInfoCard()
              this.ConfigFormCard()
              this.StatusCard()
              // 底部留白，避免被固定按钮遮挡
              Column().height(88)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 4, bottom: 16 })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)

          // 底部固定保存按钮
          this.SaveBar()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_cream'))
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

      Text('限流配置')
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

  /** API 信息卡（方法 pill + 路径 + 描述 + 当前峰值 QPS） */
  @Builder
  ApiInfoCard() {
    Column({ space: 6 }) {
      // 方法 pill + 路径
      Row({ space: 10 }) {
        Text(this.apiInfo!.method)
          .fontSize(12)
          .fontColor(this.methodColor(this.apiInfo!.method))
          .backgroundColor(this.methodBg(this.apiInfo!.method))
          .padding({ left: 12, right: 12, top: 4, bottom: 4 })
          .borderRadius(AppConstants.RADIUS_PILL)
          .fontWeight(FontWeight.Bold)

        Text(this.apiInfo!.path)
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 描述
      Text(this.apiInfo!.description)
        .fontSize(13)
        .fontColor($r('app.color.color_text_3'))
        .width('100%')

      // 当前峰值 QPS
      if (this.config) {
        Text(`当前峰值 ${this.config.currentQps} QPS`)
          .fontSize(12)
          .fontColor($r('app.color.color_text_3'))
          .margin({ top: 6 })
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 配置表单卡（对齐设计稿：label 左 + 输入框右 + tip） */
  @Builder
  ConfigFormCard() {
    Column() {
      Text('限流配置')
        .fontSize(16)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 14 })

      // QPS 阈值
      this.FormField('QPS阈值', this.qpsLimit, '次/秒', '建议设为峰值的1.5倍', (v: string) => { this.qpsLimit = v; })

      Divider().color($r('app.color.color_line')).strokeWidth(1)

      // 并发数限制
      this.FormField('并发数限制', this.concurrentLimit, '', '同时处理的请求数', (v: string) => { this.concurrentLimit = v; })

      Divider().color($r('app.color.color_line')).strokeWidth(1)

      // 熔断阈值
      this.FormField('熔断阈值', this.circuitBreakThreshold, '%', '错误率超阈值自动熔断保护', (v: string) => { this.circuitBreakThreshold = v; })

      Divider().color($r('app.color.color_line')).strokeWidth(1)

      // 恢复时间
      this.FormField('恢复时间', this.recoveryTime, '秒', '', (v: string) => { this.recoveryTime = v; })
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 表单字段（label 左 + 输入框右 + tip 下） */
  @Builder
  FormField(label: string, value: string, unit: string, tip: string, onChange: (v: string) => void) {
    Column() {
      Row() {
        Text(label)
          .fontSize(15)
          .fontColor($r('app.color.color_ink_2'))
          .fontWeight(FontWeight.Medium)

        Blank()

        // 输入框（灰底，右对齐数字 + 单位）
        Row({ space: 4 }) {
          TextInput({ text: value })
            .width(64)
            .height(38)
            .backgroundColor(Color.Transparent)
            .textAlign(TextAlign.End)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.color_ink'))
            .type(InputType.Number)
            .padding({ top: 0, bottom: 0 })
            .onChange((v: string) => { onChange(v); })

          if (unit.length > 0) {
            Text(unit)
              .fontSize(12)
              .fontColor($r('app.color.color_text_3'))
          }
        }
        .height(38)
        .padding({ left: 12, right: 12 })
        .borderRadius(AppConstants.RADIUS_SM)
        .backgroundColor($r('app.color.color_fill'))
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (tip.length > 0) {
        Text(tip)
          .fontSize(11)
          .fontColor($r('app.color.color_text_3'))
          .margin({ top: 7 })
          .width('100%')
      }
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .alignItems(HorizontalAlign.Start)
  }

  /** 当前状态卡（浅绿底 + 绿色对勾 + 状态文案） */
  @Builder
  StatusCard() {
    Row({ space: 12 }) {
      // 绿色圆形对勾图标
      Stack() {
        Text('✓')
          .fontSize(20)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
      }
      .width(36)
      .height(36)
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor($r('app.color.color_secondary'))

      Column({ space: 2 }) {
        Text('当前状态：正常运行')
          .fontSize(15)
          .fontColor($r('app.color.color_green_deep'))
          .fontWeight(FontWeight.Bold)
        Text('限流规则已生效')
          .fontSize(12)
          .fontColor('#5B8A2E')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .borderRadius(AppConstants.RADIUS_MD)
    .backgroundColor($r('app.color.color_green_soft'))
    .alignItems(VerticalAlign.Center)
  }

  /** 底部固定保存按钮栏 */
  @Builder
  SaveBar() {
    Column() {
      Button(this.isSaving ? '保存中...' : '保存配置')
        .width('100%')
        .height(46)
        .borderRadius(AppConstants.RADIUS_MD)
        .backgroundColor(this.isSaving ? $r('app.color.color_text_4') : $r('app.color.color_ink'))
        .fontColor(Color.White)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .enabled(!this.isSaving)
        .onClick(() => { this.saveConfig(); })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.color_cream'))
  }
}
