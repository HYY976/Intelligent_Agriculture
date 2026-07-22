/**
 * api_list - API 接口列表（spec 3.3.2 / 10.8.3.2）
 *
 * 路径搜索（防抖 300ms）+ 分页 + 跳转 API 详情 / 限流配置
 * - 列表项：接口路径 + 方法 Tag（GET/POST/PUT/DELETE 颜色区分）+ 描述
 *   + 今日请求量 + 错误率 + 平均响应时间
 * - 点击 → `pages/api_manage/api_detail?apiId=xxx`
 * - 右侧操作：限流配置按钮 → `pages/api_manage/rate_limit?apiId=xxx`
 *
 * 越权防御（spec 10.8.8）：aboutToAppear 校验 super_admin / api_admin
 * 全部 Mock 数据（spec 10.8.3.2）
 */

import { Logger, AppConstants, ToastUtil, TokenStore, NavigationHelper, RouteName, ListStateView } from 'common';
import { AdminInfo } from 'common';
import {
  ApiInfo,
  HttpMethod,
  AdminRole
} from '../../model/AdminModels';
import { ApiListDataSource } from '../../viewmodel/ApiListDataSource';

/** 跳转 API 详情 / 限流配置 的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface ApiIdParam {
  apiId: string;
}

/** 防抖定时器 ID */
let debounceId: number = -1;

@ComponentV2
export struct ApiList {
  /** 列表数据源（spec 10.11.4 Step 4：BaseDataSource + LazyForEach + 4 态状态机） */
  private dataSource: ApiListDataSource = new ApiListDataSource();
  /** 搜索关键字（接口路径 / 描述） */
  @Local keyword: string = '';
  /** 输入框临时值（防抖触发前） */
  @Local inputText: string = '';

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
    Logger.info(AppConstants.SCENE_ADMIN, { action: 'api_list_appear', adminId: adminInfo.adminId, role: adminInfo.role });
    await this.refresh();
  }

  /** 刷新 */
  private async refresh(): Promise<void> {
    this.dataSource.setKeyword(this.keyword);
    await this.dataSource.refresh();
  }

  /** 输入框变更（防抖 300ms，spec 10.8.3.2） */
  private onInputChange(value: string): void {
    this.inputText = value;
    if (debounceId !== -1) {
      clearTimeout(debounceId);
    }
    debounceId = setTimeout(() => {
      this.keyword = this.inputText;
      this.refresh();
      debounceId = -1;
    }, 300);
  }

  /** 跳转 API 详情 */
  private gotoDetail(apiId: string): void {
    const param: ApiIdParam = { apiId: apiId };
    NavigationHelper.push(RouteName.ADMIN_API_DETAIL, param);
  }

  /** 跳转限流配置 */
  private gotoRateLimit(apiId: string): void {
    const param: ApiIdParam = { apiId: apiId };
    NavigationHelper.push(RouteName.ADMIN_RATE_LIMIT, param);
  }

  /** 方法 Tag 背景色（spec 10.8.3.2：GET/POST/PUT/DELETE 颜色区分） */
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

  /** 错误率文字色（>0.1 红色告警） */
  private errorRateColor(rate: number): Resource {
    if (rate >= 0.1) {
      return $r('app.color.color_error');
    } else if (rate >= 0.05) {
      return $r('app.color.color_secondary');
    }
    return $r('app.color.color_text_hint');
  }

  /** 格式化响应时间 */
  private formatResponseTime(ms: number): string {
    if (ms < 1000) {
      return `${ms} ms`;
    }
    return `${(ms / 1000).toFixed(2)} s`;
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        this.SearchBar()
        // spec 10.11.4 Step 4：4 态状态机（error / loading / empty / list）
        if (this.dataSource.getLoadFailed()) {
          ListStateView({ state: 'error', onRefresh: () => this.refresh() })
        } else if (this.dataSource.getIsFirstLoad()) {
          ListStateView({ state: 'loading' })
        } else if (this.dataSource.totalCount() === 0) {
          ListStateView({ state: 'empty', emptyUseEmoji: true, emptyEmoji: '🔌', emptyText: '暂无 API 数据', emptyActionText: '刷新', onEmptyAction: () => this.refresh() })
        } else {
          this.ApiListView()
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
      Text('API 管理')
        .fontSize(18)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
      Text(`共 ${this.dataSource.totalCount()} 个`)
        .fontSize(12)
        .fontColor($r('app.color.color_text_secondary'))
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** 搜索栏（防抖 300ms） */
  @Builder
  SearchBar() {
    Row({ space: 8 }) {
      TextInput({ text: this.inputText, placeholder: '搜索接口路径 / 描述（防抖 300ms）' })
        .layoutWeight(1)
        .height(40)
        .fontSize(14)
        .backgroundColor($r('app.color.color_bg_page'))
        .borderRadius(20)
        .onChange((value: string) => {
          this.onInputChange(value);
        })
      Button('搜索')
        .height(40)
        .borderRadius(20)
        .backgroundColor($r('app.color.color_primary'))
        .fontColor(Color.White)
        .fontSize(14)
        .onClick(() => {
          this.keyword = this.inputText.trim();
          this.refresh();
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** API 列表 */
  @Builder
  ApiListView() {
    List({ space: 8 }) {
      LazyForEach(this.dataSource, (api: ApiInfo) => {
        ListItem() {
          this.ApiItemCard(api)
        }
      }, (api: ApiInfo) => `${api.apiId}_${api.todayRequestCount}_${api.errorRate}`)

      // 加载更多 / 加载中 / 没有更多
      ListItem() {
        if (this.dataSource.getIsLoading()) {
          Row({ space: 8 }) {
            LoadingProgress().width(20).height(20)
            Text('加载中...')
              .fontSize(12)
              .fontColor($r('app.color.color_text_secondary'))
          }
          .width('100%')
          .height(48)
          .justifyContent(FlexAlign.Center)
        } else if (this.dataSource.getHasMore()) {
          Text('上拉加载更多')
            .fontSize(12)
            .fontColor($r('app.color.color_text_hint'))
            .width('100%')
            .height(48)
            .textAlign(TextAlign.Center)
            .onClick(() => this.dataSource.loadMore())
        } else {
          Text('没有更多了')
            .fontSize(12)
            .fontColor($r('app.color.color_text_hint'))
            .width('100%')
            .height(48)
            .textAlign(TextAlign.Center)
        }
      }
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 12, right: 12, top: 8 })
    .cachedCount(AppConstants.LIST_CACHED_COUNT)
    .onReachEnd(() => this.dataSource.loadMore())
  }

  /** API 卡片 */
  @Builder
  ApiItemCard(api: ApiInfo) {
    Column({ space: 8 }) {
      // 第一行：方法 Tag + 路径 + 跳转箭头
      Row({ space: 8 }) {
        Text(api.method)
          .fontSize(11)
          .fontColor(this.methodColor(api.method))
          .backgroundColor(this.methodBg(api.method))
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(4)
          .fontWeight(FontWeight.Bold)
        Text(api.path)
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text('›')
          .fontSize(24)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 第二行：描述
      Text(api.description)
        .fontSize(12)
        .fontColor($r('app.color.color_text_secondary'))
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 第三行：指标
      Row({ space: 16 }) {
        Column({ space: 2 }) {
          Text('今日请求')
            .fontSize(10)
            .fontColor($r('app.color.color_text_hint'))
          Text(`${api.todayRequestCount}`)
            .fontSize(13)
            .fontColor($r('app.color.color_text_primary'))
            .fontWeight(FontWeight.Medium)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column({ space: 2 }) {
          Text('错误率')
            .fontSize(10)
            .fontColor($r('app.color.color_text_hint'))
          Text(`${(api.errorRate * 100).toFixed(2)}%`)
            .fontSize(13)
            .fontColor(this.errorRateColor(api.errorRate))
            .fontWeight(FontWeight.Medium)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column({ space: 2 }) {
          Text('平均响应')
            .fontSize(10)
            .fontColor($r('app.color.color_text_hint'))
          Text(this.formatResponseTime(api.avgResponseTime))
            .fontSize(13)
            .fontColor($r('app.color.color_text_primary'))
            .fontWeight(FontWeight.Medium)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      // 第四行：操作按钮
      Row({ space: 8 }) {
        Button('查看详情')
          .layoutWeight(1)
          .height(32)
          .borderRadius(16)
          .backgroundColor($r('app.color.color_bg_page'))
          .fontColor($r('app.color.color_text_primary'))
          .fontSize(12)
          .onClick(() => this.gotoDetail(api.apiId))
        Button('限流配置')
          .layoutWeight(1)
          .height(32)
          .borderRadius(16)
          .backgroundColor($r('app.color.color_bg_page'))
          .fontColor($r('app.color.color_secondary'))
          .fontSize(12)
          .onClick(() => this.gotoRateLimit(api.apiId))
      }
      .width('100%')
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
    .onClick(() => {
      this.gotoDetail(api.apiId);
    })
  }

}
