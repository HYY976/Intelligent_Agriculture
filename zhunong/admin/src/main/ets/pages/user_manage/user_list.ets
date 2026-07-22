/**
 * user_list - 用户列表（spec 3.3.1 / 10.8.3.1）
 *
 * 多条件搜索 + 分页 + 跳转用户详情
 * - 搜索字段：账号 / 手机号 / 昵称 / 类型 / 状态
 * - LazyForEach 分页（spec 7.3.1）
 * - 兜底状态：SkeletonLoader / EmptyState / NetworkError
 *
 * 越权防御（spec 10.8.8）：aboutToAppear 校验 super_admin / user_admin
 */

import { Logger, AppConstants, ToastUtil, TokenStore, NavigationHelper, RouteName, ListStateView } from 'common';
import { AdminInfo } from 'common';
import {
  UserRecord,
  UserRecordType,
  UserRecordStatus,
  USER_TYPE_LABELS,
  USER_STATUS_LABELS,
  AdminRole
} from '../../model/AdminModels';
import { UserListDataSource } from '../../viewmodel/UserListDataSource';

/** 跳转用户详情的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface UserDetailParam {
  userId: string;
}

/** 类型筛选项 */
interface TypeFilterOption {
  value: 'all' | UserRecordType;
  label: string;
}

/** 状态筛选项 */
interface StatusFilterOption {
  value: 'all' | UserRecordStatus;
  label: string;
}

@ComponentV2
export struct UserList {
  /** 列表数据源（spec 10.11.4 Step 4：BaseDataSource + LazyForEach + 4 态状态机） */
  private dataSource: UserListDataSource = new UserListDataSource();
  /** 搜索关键字（账号/昵称） */
  @Local keyword: string = '';
  /** 手机号搜索 */
  @Local phone: string = '';
  /** 昵称搜索 */
  @Local nickname: string = '';
  /** 类型筛选 */
  @Local typeFilter: 'all' | UserRecordType = 'all';
  /** 状态筛选 */
  @Local statusFilter: 'all' | UserRecordStatus = 'all';
  /** 是否展开高级搜索 */
  @Local showAdvancedSearch: boolean = false;

  /** 类型选项 */
  private typeOptions: TypeFilterOption[] = [
    { value: 'all', label: '全部类型' },
    { value: 'user', label: '用户' },
    { value: 'farmer', label: '卖家' }
  ];

  /** 状态选项 */
  private statusOptions: StatusFilterOption[] = [
    { value: 'all', label: '全部状态' },
    { value: 'active', label: '正常' },
    { value: 'banned', label: '已封禁' }
  ];

  async aboutToAppear(): Promise<void> {
    // 越权防御（spec 10.8.8）
    const adminInfo: AdminInfo | null = await TokenStore.getAdminInfo();
    if (!adminInfo) {
      ToastUtil.warning('请先登录');
      NavigationHelper.replace(RouteName.ADMIN_LOGIN);
      return;
    }
    const allowedRoles: AdminRole[] = ['super_admin', 'user_admin'];
    if (allowedRoles.indexOf(adminInfo.role as AdminRole) < 0) {
      ToastUtil.warning('无权限访问该页面');
      NavigationHelper.pop();
      return;
    }
    Logger.info(AppConstants.SCENE_ADMIN, { action: 'user_list_appear', adminId: adminInfo.adminId, role: adminInfo.role });
    await this.refresh();
  }

  /** 刷新 */
  private async refresh(): Promise<void> {
    // spec 10.11.4 Step 4：多 setter 拆分模式，统一注入过滤条件后 refresh
    this.dataSource.setKeyword(this.keyword);
    this.dataSource.setPhone(this.phone);
    this.dataSource.setNickname(this.nickname);
    this.dataSource.setUserType(this.typeFilter);
    this.dataSource.setStatus(this.statusFilter);
    await this.dataSource.refresh();
  }

  /** 切换类型筛选 */
  private async onTypeChange(value: 'all' | UserRecordType): Promise<void> {
    this.typeFilter = value;
    await this.refresh();
  }

  /** 切换状态筛选 */
  private async onStatusChange(value: 'all' | UserRecordStatus): Promise<void> {
    this.statusFilter = value;
    await this.refresh();
  }

  /** 跳转用户详情 */
  private gotoDetail(userId: string): void {
    const param: UserDetailParam = { userId: userId };
    NavigationHelper.push(RouteName.ADMIN_USER_DETAIL, param);
  }

  /** 手机号脱敏 */
  private maskPhone(phone: string): string {
    if (phone.length < 7) {
      return phone;
    }
    return phone.substring(0, 3) + '****' + phone.substring(7);
  }

  /** 格式化时间 */
  private formatTime(ts: number): string {
    const d: Date = new Date(ts);
    const y: number = d.getFullYear();
    const m: string = (d.getMonth() + 1).toString().padStart(2, '0');
    const day: string = d.getDate().toString().padStart(2, '0');
    return `${y}-${m}-${day}`;
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        this.SearchBar()
        this.FilterBar()
        // spec 10.11.4 Step 4：4 态状态机（error / loading / empty / list）
        if (this.dataSource.getLoadFailed()) {
          ListStateView({ state: 'error', onRefresh: () => this.refresh() })
        } else if (this.dataSource.getIsFirstLoad()) {
          ListStateView({ state: 'loading' })
        } else if (this.dataSource.totalCount() === 0) {
          ListStateView({ state: 'empty', emptyUseEmoji: true, emptyEmoji: '📋', emptyText: '暂无用户数据', emptyActionText: '刷新', onEmptyAction: () => this.refresh() })
        } else {
          this.UserListView()
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
      Text('用户管理')
        .fontSize(18)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
      Text(`共 ${this.dataSource.totalCount()} 人`)
        .fontSize(12)
        .fontColor($r('app.color.color_text_secondary'))
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** 搜索栏 */
  @Builder
  SearchBar() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        TextInput({ text: this.keyword, placeholder: '搜索账号 / 昵称' })
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .backgroundColor($r('app.color.color_bg_page'))
          .borderRadius(20)
          .onChange((value: string) => {
            this.keyword = value;
          })
        Button('搜索')
          .height(40)
          .borderRadius(20)
          .backgroundColor($r('app.color.color_primary'))
          .fontColor(Color.White)
          .fontSize(14)
          .onClick(() => {
            this.refresh();
          })
        Button(this.showAdvancedSearch ? '收起' : '高级')
          .height(40)
          .borderRadius(20)
          .backgroundColor($r('app.color.color_bg_page'))
          .fontColor($r('app.color.color_text_primary'))
          .fontSize(14)
          .onClick(() => {
            this.showAdvancedSearch = !this.showAdvancedSearch;
          })
      }
      .width('100%')

      if (this.showAdvancedSearch) {
        Row({ space: 8 }) {
          TextInput({ text: this.phone, placeholder: '手机号' })
            .layoutWeight(1)
            .height(40)
            .fontSize(14)
            .type(InputType.Number)
            .backgroundColor($r('app.color.color_bg_page'))
            .borderRadius(20)
            .onChange((value: string) => {
              this.phone = value;
            })
          TextInput({ text: this.nickname, placeholder: '昵称' })
            .layoutWeight(1)
            .height(40)
            .fontSize(14)
            .backgroundColor($r('app.color.color_bg_page'))
            .borderRadius(20)
            .onChange((value: string) => {
              this.nickname = value;
            })
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 类型/状态筛选栏 */
  @Builder
  FilterBar() {
    Row({ space: 16 }) {
      // 类型筛选
      Row({ space: 4 }) {
        ForEach(this.typeOptions, (opt: TypeFilterOption) => {
          Text(opt.label)
            .fontSize(12)
            .fontColor(this.typeFilter === opt.value ? Color.White : $r('app.color.color_text_secondary'))
            .backgroundColor(this.typeFilter === opt.value ? $r('app.color.color_primary') : $r('app.color.color_bg_card'))
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .borderRadius(12)
            .onClick(() => {
              this.onTypeChange(opt.value);
            })
        }, (opt: TypeFilterOption) => opt.value)
      }
      .layoutWeight(1)

      // 状态筛选
      Row({ space: 4 }) {
        ForEach(this.statusOptions, (opt: StatusFilterOption) => {
          Text(opt.label)
            .fontSize(12)
            .fontColor(this.statusFilter === opt.value ? Color.White : $r('app.color.color_text_secondary'))
            .backgroundColor(this.statusFilter === opt.value ? $r('app.color.color_primary') : $r('app.color.color_bg_card'))
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .borderRadius(12)
            .onClick(() => {
              this.onStatusChange(opt.value);
            })
        }, (opt: StatusFilterOption) => opt.value)
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 用户列表 */
  @Builder
  UserListView() {
    List({ space: 8 }) {
      LazyForEach(this.dataSource, (user: UserRecord) => {
        ListItem() {
          this.UserItemCard(user)
        }
      }, (user: UserRecord) => `${user.userId}_${user.status}_${user.lastLoginAt}`)

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

  /** 用户卡片 */
  @Builder
  UserItemCard(user: UserRecord) {
    Row({ space: 12 }) {
      // 头像
      Stack() {
        Text(user.nickname.charAt(0))
          .fontSize(20)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
      }
      .width(48)
      .height(48)
      .borderRadius(24)
      .backgroundColor(user.userType === 'farmer' ? $r('app.color.color_secondary') : $r('app.color.color_primary'))

      // 信息列
      Column({ space: 4 }) {
        Row({ space: 6 }) {
          Text(user.nickname)
            .fontSize(14)
            .fontColor($r('app.color.color_text_primary'))
            .fontWeight(FontWeight.Medium)
          // 类型标签
          Text(USER_TYPE_LABELS[user.userType])
            .fontSize(10)
            .fontColor(user.userType === 'farmer' ? $r('app.color.color_secondary') : $r('app.color.color_primary'))
            .backgroundColor(user.userType === 'farmer' ? 'rgba(255,152,0,0.12)' : 'rgba(76,175,80,0.12)')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(4)
          // 状态标签
          Text(USER_STATUS_LABELS[user.status])
            .fontSize(10)
            .fontColor(user.status === 'banned' ? $r('app.color.color_error') : $r('app.color.color_primary'))
            .backgroundColor(user.status === 'banned' ? 'rgba(244,67,54,0.12)' : 'rgba(76,175,80,0.12)')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(4)
        }

        Text(this.maskPhone(user.phone))
          .fontSize(12)
          .fontColor($r('app.color.color_text_secondary'))
        Text(`注册：${this.formatTime(user.createdAt)} · ${user.userId}`)
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 查看按钮
      Text('›')
        .fontSize(24)
        .fontColor($r('app.color.color_text_hint'))
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.gotoDetail(user.userId);
    })
  }

}
