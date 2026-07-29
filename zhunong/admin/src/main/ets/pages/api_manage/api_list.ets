/**
 * api_list - API 接口列表（UI 复刻 qunong-harmony-app/pages/api-list.html）
 * 遵循 spec 3.3.2 / 10.8.3.2：
 *  - 顶栏：圆形返回键 + 居中 "API管理" + 接口计数
 *  - 搜索栏（防抖 300ms）：胶囊形白底 + 搜索图标 + placeholder
 *  - LazyForEach 分页 API 列表
 *  - 列表项：方法 Tag（GET 绿/POST 蓝/PUT 橙/DELETE 红）+ 路径 + "查看 ›" + 描述
 *    + 3 列指标（调用次数/成功率/平均耗时，顶部虚线分隔）+ 2 按钮（查看详情线框 + 限流配置黄边）
 *  - 点击 → `pages/api_manage/api_detail?apiId=xxx`
 *  - 限流配置按钮 → `pages/api_manage/rate_limit?apiId=xxx`
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
    Logger.info(AppConstants.SCENE_ADMIN, { action: 'api_list_appear', adminId: adminInfo.adminId });
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

  /** 方法 Tag 背景色（spec：GET 绿 / POST 蓝 / PUT 橙 / DELETE 红） */
  private methodBg(method: HttpMethod): ResourceColor {
    if (method === 'GET') {
      return $r('app.color.color_green');
    } else if (method === 'POST') {
      return $r('app.color.color_info');
    } else if (method === 'PUT') {
      return $r('app.color.color_warn');
    }
    return $r('app.color.color_live');
  }

  /** 方法 Tag 文字色 */
  private methodColor(method: HttpMethod): ResourceColor {
    if (method === 'GET') {
      return $r('app.color.color_ink');
    }
    return Color.White;
  }

  /** 格式化响应时间 */
  private formatResponseTime(ms: number): string {
    if (ms < 1000) {
      return `${ms}ms`;
    }
    return `${(ms / 1000).toFixed(2)}s`;
  }

  /** 计算成功率（1 - 错误率） */
  private formatSuccessRate(errorRate: number): string {
    const successRate: number = (1 - errorRate) * 100;
    return `${successRate.toFixed(1)}%`;
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
          this.EmptyState()
        } else {
          this.ApiListView()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_cream'))
    }
    .hideTitleBar(true)
  }

  /** 顶部导航：圆形返回键 + 居中标题 + 接口计数 */
  @Builder
  TopBar() {
    Row() {
      // 圆形返回键
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

      // 居中标题
      Text('API管理')
        .fontSize(17)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 接口计数
      Text(`共${this.dataSource.totalCount()}个`)
        .fontSize(12)
        .fontColor($r('app.color.color_text_3'))
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16, top: 4, bottom: 10 })
    .alignItems(VerticalAlign.Center)
  }

  /** 搜索栏（胶囊形白底 + 搜索图标 + 防抖 300ms） */
  @Builder
  SearchBar() {
    Row({ space: 8 }) {
      Image($r('app.media.icon_search'))
        .width(16)
        .height(16)
        .fillColor($r('app.color.color_text_3'))
      TextInput({ text: this.inputText, placeholder: '搜索接口路径/名称' })
        .layoutWeight(1)
        .height(40)
        .fontSize(13)
        .fontColor($r('app.color.color_ink'))
        .backgroundColor(Color.Transparent)
        .placeholderColor($r('app.color.color_text_3'))
        .onChange((value: string) => {
          this.onInputChange(value);
        })
    }
    .width('100%')
    .height(40)
    .padding({ left: 16, right: 16 })
    .borderRadius(AppConstants.RADIUS_PILL)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .margin({ left: 16, right: 16, top: 4, bottom: 12 })
    .alignItems(VerticalAlign.Center)
  }

  /** API 列表 */
  @Builder
  ApiListView() {
    List({ space: 10 }) {
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
              .fontColor($r('app.color.color_text_2'))
          }
          .width('100%')
          .height(48)
          .justifyContent(FlexAlign.Center)
        } else if (this.dataSource.getHasMore()) {
          Text('上拉加载更多')
            .fontSize(12)
            .fontColor($r('app.color.color_text_4'))
            .width('100%')
            .height(48)
            .textAlign(TextAlign.Center)
            .onClick(() => this.dataSource.loadMore())
        } else {
          Text('没有更多了')
            .fontSize(12)
            .fontColor($r('app.color.color_text_4'))
            .width('100%')
            .height(48)
            .textAlign(TextAlign.Center)
        }
      }
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 16, right: 16 })
    .cachedCount(AppConstants.LIST_CACHED_COUNT)
    .onReachEnd(() => this.dataSource.loadMore())
  }

  /** API 卡片（对齐 api-list.html 设计） */
  @Builder
  ApiItemCard(api: ApiInfo) {
    Column({ space: 10 }) {
      // 第一行：方法 Tag + 路径 + "查看 ›"
      Row({ space: 8 }) {
        Text(api.method)
          .fontSize(11)
          .fontColor(this.methodColor(api.method))
          .backgroundColor(this.methodBg(api.method))
          .padding({ left: 7, right: 7, top: 2, bottom: 2 })
          .borderRadius(AppConstants.RADIUS_XS)
          .fontWeight(FontWeight.Bold)

        Text(api.path)
          .fontSize(13)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // "查看 ›" 链接
        Row({ space: 1 }) {
          Text('查看')
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
          Text('›')
            .fontSize(14)
            .fontColor($r('app.color.color_text_3'))
        }
        .alignItems(VerticalAlign.Center)
        .onClick(() => this.gotoDetail(api.apiId))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 第二行：描述
      Text(api.description)
        .fontSize(13)
        .fontColor($r('app.color.color_text_2'))
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 第三行：3 列指标（顶部虚线分隔）
      Row() {
        Column({ space: 3 }) {
          Text(`${api.todayRequestCount.toLocaleString()}`)
            .fontSize(14)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
          Text('调用次数')
            .fontSize(10)
            .fontColor($r('app.color.color_text_3'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column({ space: 3 }) {
          Text(this.formatSuccessRate(api.errorRate))
            .fontSize(14)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
          Text('成功率')
            .fontSize(10)
            .fontColor($r('app.color.color_text_3'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column({ space: 3 }) {
          Text(this.formatResponseTime(api.avgResponseTime))
            .fontSize(14)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
          Text('平均耗时')
            .fontSize(10)
            .fontColor($r('app.color.color_text_3'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .padding({ top: 10 })
      .border({ width: { top: 1 }, color: $r('app.color.color_line'), style: BorderStyle.Dashed })

      // 第四行：2 按钮（查看详情线框 + 限流配置黄边）
      Row({ space: 8 }) {
        Text('查看详情')
          .layoutWeight(1)
          .height(32)
          .borderRadius(AppConstants.RADIUS_SM)
          .backgroundColor($r('app.color.color_bg_card'))
          .border({ width: 1, color: $r('app.color.color_line_2') })
          .fontColor($r('app.color.color_text_2'))
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .onClick(() => this.gotoDetail(api.apiId))

        Text('限流配置')
          .layoutWeight(1)
          .height(32)
          .borderRadius(AppConstants.RADIUS_SM)
          .backgroundColor($r('app.color.color_bg_card'))
          .border({ width: 1, color: $r('app.color.color_yellow') })
          .fontColor($r('app.color.color_ink'))
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .onClick(() => this.gotoRateLimit(api.apiId))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(14)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .onClick(() => {
      this.gotoDetail(api.apiId);
    })
  }

  /** 空状态（自定义，替代 ListStateView emptyEmoji） */
  @Builder
  EmptyState() {
    Column({ space: 12 }) {
      Image($r('app.media.icon_api'))
        .width(48)
        .height(48)
        .fillColor($r('app.color.color_text_4'))
      Text('暂无 API 数据')
        .fontSize(13)
        .fontColor($r('app.color.color_text_3'))
      Text('刷新')
        .fontSize(13)
        .fontColor($r('app.color.color_info'))
        .fontWeight(FontWeight.Bold)
        .padding({ left: 16, right: 16, top: 6, bottom: 6 })
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor($r('app.color.color_info_soft'))
        .onClick(() => this.refresh())
    }
    .width('100%')
    .padding({ top: 64, bottom: 64 })
    .alignItems(HorizontalAlign.Center)
  }

}
