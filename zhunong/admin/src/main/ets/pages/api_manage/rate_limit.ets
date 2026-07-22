/**
 * rate_limit - 限流配置（spec 3.3.2 / 10.8.3.2）
 *
 * - 顶部显示当前 API 路径与方法
 * - 表单：QPS 阈值输入框（数字键盘）+ 并发数限制 + 熔断阈值
 * - 保存按钮 → 调 `ApiRepository.updateRateLimit()`
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
      } else {
        // 兜底默认值
        this.qpsLimit = '100';
        this.concurrentLimit = '50';
        this.circuitBreakThreshold = '5.0';
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
      const req: RateLimitUpdateRequest = {
        apiId: this.apiId,
        qpsLimit: qps,
        concurrentLimit: concurrent,
        circuitBreakThreshold: threshold
      };
      await ApiRepository.updateRateLimit(req);
      ToastUtil.success('保存成功');
      Logger.info(AppConstants.SCENE_ADMIN, { action: 'rate_limit_save', apiId: this.apiId, qps, concurrent, threshold });
      NavigationHelper.pop();
    } catch (err) {
      Logger.error(AppConstants.SCENE_ADMIN, { action: 'rate_limit_save_fail', error: (err as Error).message });
      ToastUtil.error('保存失败');
    } finally {
      this.isSaving = false;
    }
  }

  /** 方法 Tag 背景色 */
  private methodBg(method: HttpMethod): string {
    if (method === 'GET') {
      return 'rgba(76,175,80,0.15)';
    } else if (method === 'POST') {
      return 'rgba(33,150,243,0.15)';
    } else if (method === 'PUT') {
      return 'rgba(255,152,0,0.15)';
    }
    return 'rgba(244,67,54,0.15)';
  }

  /** 方法 Tag 文字色 */
  private methodColor(method: HttpMethod): string {
    if (method === 'GET') {
      return '#4CAF50';
    } else if (method === 'POST') {
      return '#2196F3';
    } else if (method === 'PUT') {
      return '#FF9800';
    }
    return '#F44336';
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
            Column({ space: 16 }) {
              this.ApiHeaderCard()
              this.ConfigFormCard()
              this.SaveButton()
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 24 })
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

  /** 顶部导航 */
  @Builder
  TopBar() {
    Row({ space: 12 }) {
      Text('‹')
        .fontSize(28)
        .fontColor($r('app.color.color_text_primary'))
        .onClick(() => NavigationHelper.pop())
      Text('限流配置')
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

  /** API 信息卡（顶部展示路径与方法） */
  @Builder
  ApiHeaderCard() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text(this.apiInfo!.method)
          .fontSize(11)
          .fontColor(this.methodColor(this.apiInfo!.method))
          .backgroundColor(this.methodBg(this.apiInfo!.method))
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(4)
          .fontWeight(FontWeight.Bold)
        Text(this.apiInfo!.path)
          .fontSize(14)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      Text(this.apiInfo!.description)
        .fontSize(12)
        .fontColor($r('app.color.color_text_secondary'))
        .width('100%')
      if (this.config) {
        Text(`当前配置 ID：${this.config.configId}`)
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
          .width('100%')
      }
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 配置表单卡 */
  @Builder
  ConfigFormCard() {
    Column({ space: 12 }) {
      Text('限流参数')
        .fontSize(14)
        .fontColor($r('app.color.color_text_secondary'))
        .alignSelf(ItemAlign.Start)

      // QPS 阈值
      Column({ space: 6 }) {
        Text('* QPS 阈值（每秒请求数）')
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
          .alignSelf(ItemAlign.Start)
        TextInput({ text: this.qpsLimit, placeholder: '请输入 QPS 阈值（1~100000）' })
          .height(44)
          .borderRadius(8)
          .backgroundColor($r('app.color.color_bg_page'))
          .padding({ left: 12, right: 12 })
          .fontSize(14)
          .type(InputType.Number)
          .onChange((v: string) => { this.qpsLimit = v; })
        Text('建议值：100 ~ 10000，登录类接口可设为 5000，订单类接口建议 500')
          .fontSize(10)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')

      // 并发数限制
      Column({ space: 6 }) {
        Text('* 并发数限制')
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
          .alignSelf(ItemAlign.Start)
        TextInput({ text: this.concurrentLimit, placeholder: '请输入并发数限制（1~10000）' })
          .height(44)
          .borderRadius(8)
          .backgroundColor($r('app.color.color_bg_page'))
          .padding({ left: 12, right: 12 })
          .fontSize(14)
          .type(InputType.Number)
          .onChange((v: string) => { this.concurrentLimit = v; })
        Text('同时处理的最大请求数，超过则排队等待')
          .fontSize(10)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')

      // 熔断阈值
      Column({ space: 6 }) {
        Text('* 熔断阈值（百分比）')
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
          .alignSelf(ItemAlign.Start)
        TextInput({ text: this.circuitBreakThreshold, placeholder: '请输入熔断阈值（0~100）' })
          .height(44)
          .borderRadius(8)
          .backgroundColor($r('app.color.color_bg_page'))
          .padding({ left: 12, right: 12 })
          .fontSize(14)
          .type(InputType.Number)
          .onChange((v: string) => { this.circuitBreakThreshold = v; })
        Text('错误率超过该阈值时触发熔断，建议 5.0% ~ 20.0%')
          .fontSize(10)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 保存按钮 */
  @Builder
  SaveButton() {
    Button(this.isSaving ? '保存中...' : '保存配置')
      .width('100%')
      .height(48)
      .borderRadius(24)
      .backgroundColor(this.isSaving ? $r('app.color.color_button_disabled') : $r('app.color.color_primary'))
      .fontColor(Color.White)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .enabled(!this.isSaving)
      .onClick(() => { this.saveConfig(); })
  }
}
