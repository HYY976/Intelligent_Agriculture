/**
 * user_list - 用户列表（UI 复刻 qunong-harmony-app/pages/admin-users.html）
 * 遵循 spec 3.3.1 / 10.8.3.1：
 *  - 多条件搜索 + 分页 + 跳转用户详情
 *  - 搜索字段：账号 / 手机号 / 昵称 / 类型 / 状态
 *  - LazyForEach 分页（spec 7.3.1）
 *  - 兜底状态：SkeletonLoader / EmptyState / NetworkError
 *
 * UI 设计要点（对齐 admin-users.html）：
 *  - 顶栏：圆形返回键 + 居中标题 "用户管理" + 右侧 "导出" 文字按钮
 *  - 搜索栏：胶囊形（40h 白底阴影）+ 搜索图标 + placeholder
 *  - 3 列统计卡：总用户 / 消费者 / 农户（带竖线分隔）
 *  - 角色筛选 Tab：横滑胶囊（全部/消费者/农户/待审核）+ 计数徽标，激活态墨黑底
 *  - 用户卡：40×40 头像 + 昵称 + 类型 pill + 手机号 + 状态 pill + 右侧操作按钮（详情/审核/解封）
 *  - 加载更多：full-width 灰底胶囊 + 下箭头
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

/** 角色筛选项（对齐设计稿：全部/消费者/农户/待审核） */
interface RoleFilterOption {
  /** 筛选值 */
  value: 'all' | UserRecordType | 'pending';
  /** 标签 */
  label: string;
  /** 计数（运行时填充） */
  count: number;
}

/** 统计项 */
interface StatItem {
  /** 数值 */
  num: string;
  /** 标签 */
  lab: string;
}

@ComponentV2
export struct UserList {
  /** 列表数据源（spec 10.11.4 Step 4：BaseDataSource + LazyForEach + 4 态状态机） */
  private dataSource: UserListDataSource = new UserListDataSource();
  /** 搜索关键字（账号/昵称/手机号） */
  @Local keyword: string = '';
  /** 当前角色筛选 */
  @Local roleFilter: 'all' | UserRecordType | 'pending' = 'all';
  /** 统计行数据（Mock，后续接入真实统计接口） */
  @Local stats: StatItem[] = [
    { num: '8,926', lab: '总用户' },
    { num: '6,532', lab: '消费者' },
    { num: '2,394', lab: '农户' }
  ];

  /** 角色筛选选项（计数动态计算） */
  private getRoleOptions(): RoleFilterOption[] {
    return [
      { value: 'all', label: '全部', count: 8926 },
      { value: 'user', label: '消费者', count: 6532 },
      { value: 'farmer', label: '农户', count: 2394 },
      { value: 'pending', label: '待审核', count: 12 }
    ];
  }

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
    // 将角色筛选映射为 typeFilter / statusFilter
    if (this.roleFilter === 'pending') {
      this.dataSource.setUserType('all');
      this.dataSource.setStatus('all');
    } else {
      this.dataSource.setUserType(this.roleFilter);
      this.dataSource.setStatus('all');
    }
    await this.dataSource.refresh();
  }

  /** 切换角色筛选 */
  private async onRoleChange(value: 'all' | UserRecordType | 'pending'): Promise<void> {
    this.roleFilter = value;
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

  /** 获取用户头像资源（按类型返回不同头像） */
  private getAvatarResource(user: UserRecord): Resource {
    return user.userType === 'farmer' ? $r('app.media.avatar_farmer') : $r('app.media.avatar_customer');
  }

  /** 是否为待审核用户（Mock：userId 以 "pending_" 开头或 farmer 类型且未认证） */
  private isPendingUser(user: UserRecord): boolean {
    return user.status === 'active' && user.userType === 'farmer' && user.userId.indexOf('pending') >= 0;
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        this.SearchBar()
        this.StatsCard()
        this.RoleTabs()
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
      .backgroundColor($r('app.color.color_cream'))
    }
    .hideTitleBar(true)
  }

  /** 顶部导航：圆形返回键 + 居中标题 + 右侧"导出"文字按钮 */
  @Builder
  TopBar() {
    Row() {
      // 左侧返回键（32×32 圆形白底阴影）
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
      Text('用户管理')
        .fontSize(17)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 右侧"导出"文字按钮
      Row({ space: 4 }) {
        Text('↓')
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
        Text('导出')
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .width(48)
      .height(32)
      .justifyContent(FlexAlign.End)
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        ToastUtil.info('导出功能开发中');
      })
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16, top: 4, bottom: 10 })
    .alignItems(VerticalAlign.Center)
  }

  /** 搜索栏（胶囊形） */
  @Builder
  SearchBar() {
    Row({ space: 8 }) {
      Text('🔍')
        .fontSize(14)
        .fontColor($r('app.color.color_text_3'))
      TextInput({ text: this.keyword, placeholder: '搜索用户昵称/手机号' })
        .layoutWeight(1)
        .height(40)
        .fontSize(13)
        .backgroundColor(Color.Transparent)
        .placeholderColor($r('app.color.color_text_3'))
        .placeholderFont({ size: 13 })
        .onChange((value: string) => {
          this.keyword = value;
        })
        .onSubmit(() => {
          this.refresh();
        })
    }
    .width('100%')
    .height(40)
    .padding({ left: 16, right: 16 })
    .borderRadius(AppConstants.RADIUS_PILL)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(VerticalAlign.Center)
    .margin({ left: 16, right: 16 })
  }

  /** 3 列统计卡（总用户 / 消费者 / 农户） */
  @Builder
  StatsCard() {
    Row() {
      ForEach(this.stats, (stat: StatItem, index: number) => {
        Row() {
          Column({ space: 4 }) {
            Text(stat.num)
              .fontSize(21)
              .fontColor($r('app.color.color_ink'))
              .fontWeight(FontWeight.Bold)
              .letterSpacing(0.3)
            Text(stat.lab)
              .fontSize(11)
              .fontColor($r('app.color.color_text_3'))
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          // 除最后一项外，右侧加竖线
          if (index < this.stats.length - 1) {
            Column()
              .width(1)
              .height(30)
              .backgroundColor($r('app.color.color_line'))
          }
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }, (stat: StatItem, index: number) => `${stat.lab}_${index}`)
    }
    .width('100%')
    .padding({ top: 16, bottom: 16 })
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .margin({ left: 16, right: 16, top: 12 })
    .alignItems(VerticalAlign.Center)
  }

  /** 角色筛选 Tab（横滑胶囊 + 计数徽标） */
  @Builder
  RoleTabs() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.getRoleOptions(), (opt: RoleFilterOption) => {
          Row({ space: 6 }) {
            Text(opt.label)
              .fontSize(13)
              .fontColor(this.roleFilter === opt.value ? Color.White : $r('app.color.color_text_2'))
              .fontWeight(FontWeight.Medium)
            // 计数徽标
            Text(`${opt.count}`)
              .fontSize(11)
              .fontColor(this.roleFilter === opt.value ? Color.White : $r('app.color.color_text_3'))
              .fontWeight(FontWeight.Bold)
              .backgroundColor(this.roleFilter === opt.value ? 'rgba(255,255,255,0.18)' : $r('app.color.color_fill'))
              .padding({ left: 7, right: 7, top: 1, bottom: 1 })
              .borderRadius(AppConstants.RADIUS_PILL)
          }
          .height(34)
          .padding({ left: 14, right: 14 })
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor(this.roleFilter === opt.value ? $r('app.color.color_cta_black') : $r('app.color.color_bg_card'))
          .shadow(AppConstants.SHADOW_CARD)
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.onRoleChange(opt.value);
          })
        }, (opt: RoleFilterOption) => opt.value)
      }
      .padding({ left: 16, right: 16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .margin({ top: 12 })
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
              .fontColor($r('app.color.color_text_2'))
          }
          .width('100%')
          .height(48)
          .justifyContent(FlexAlign.Center)
        } else if (this.dataSource.getHasMore()) {
          this.LoadMoreButton()
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
    .padding({ left: 16, right: 16, top: 12 })
    .cachedCount(AppConstants.LIST_CACHED_COUNT)
    .onReachEnd(() => this.dataSource.loadMore())
  }

  /** 加载更多按钮（灰底胶囊 + 下箭头） */
  @Builder
  LoadMoreButton() {
    Row({ space: 6 }) {
      Text('加载更多')
        .fontSize(13)
        .fontColor($r('app.color.color_text_2'))
        .fontWeight(FontWeight.Medium)
      Text('↓')
        .fontSize(14)
        .fontColor($r('app.color.color_text_2'))
    }
    .width('100%')
    .height(42)
    .borderRadius(AppConstants.RADIUS_MD)
    .backgroundColor($r('app.color.color_fill'))
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .onClick(() => this.dataSource.loadMore())
  }

  /** 用户卡片（紧凑型：40 头像 + 名称 + 类型 pill + 手机 + 状态 pill + 操作按钮） */
  @Builder
  UserItemCard(user: UserRecord) {
    Row({ space: 12 }) {
      // 头像（40×40 圆形）
      Image(this.getAvatarResource(user))
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor($r('app.color.color_fill'))
        .objectFit(ImageFit.Cover)

      // 中间信息列
      Column({ space: 6 }) {
        // 第一行：昵称 + 类型 pill
        Row({ space: 8 }) {
          Text(user.nickname)
            .fontSize(15)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .constraintSize({ maxWidth: 120 })
          this.UserTypePill(user.userType)
        }
        .alignItems(VerticalAlign.Center)

        // 第二行：手机号 + 状态 pill
        Row({ space: 8 }) {
          Text(this.maskPhone(user.phone))
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
          this.UserStatusPill(user)
        }
        .alignItems(VerticalAlign.Center)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 右侧操作按钮（根据状态切换）
      this.ActionButton(user)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 11, bottom: 11 })
    .borderRadius(AppConstants.RADIUS_MD)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.gotoDetail(user.userId);
    })
  }

  /** 用户类型 pill（消费者=蓝 / 农户=绿） */
  @Builder
  UserTypePill(type: UserRecordType) {
    Text(USER_TYPE_LABELS[type])
      .fontSize(11)
      .fontColor(type === 'farmer' ? $r('app.color.color_green_deep') : $r('app.color.color_info'))
      .backgroundColor(type === 'farmer' ? $r('app.color.color_green_soft') : $r('app.color.color_info_soft'))
      .padding({ left: 10, right: 10, top: 3, bottom: 3 })
      .borderRadius(AppConstants.RADIUS_PILL)
      .fontWeight(FontWeight.Medium)
  }

  /** 用户状态 pill（正常=绿 / 待审核=黄 / 已封禁=红 / 已认证=绿） */
  @Builder
  UserStatusPill(user: UserRecord) {
    if (user.status === 'banned') {
      Text('已封禁')
        .fontSize(11)
        .fontColor($r('app.color.color_live'))
        .backgroundColor($r('app.color.color_live_soft'))
        .padding({ left: 10, right: 10, top: 3, bottom: 3 })
        .borderRadius(AppConstants.RADIUS_PILL)
        .fontWeight(FontWeight.Medium)
    } else if (this.isPendingUser(user)) {
      Text('待审核')
        .fontSize(11)
        .fontColor($r('app.color.color_yellow_text'))
        .backgroundColor($r('app.color.color_yellow_soft'))
        .padding({ left: 10, right: 10, top: 3, bottom: 3 })
        .borderRadius(AppConstants.RADIUS_PILL)
        .fontWeight(FontWeight.Medium)
    } else if (user.userType === 'farmer') {
      Text('已认证')
        .fontSize(11)
        .fontColor($r('app.color.color_green_deep'))
        .backgroundColor($r('app.color.color_green_soft'))
        .padding({ left: 10, right: 10, top: 3, bottom: 3 })
        .borderRadius(AppConstants.RADIUS_PILL)
        .fontWeight(FontWeight.Medium)
    } else {
      Text('正常')
        .fontSize(11)
        .fontColor($r('app.color.color_green_deep'))
        .backgroundColor($r('app.color.color_green_soft'))
        .padding({ left: 10, right: 10, top: 3, bottom: 3 })
        .borderRadius(AppConstants.RADIUS_PILL)
        .fontWeight(FontWeight.Medium)
    }
  }

  /** 操作按钮（待审核=黄底"审核" / 已封禁=线框"解封" / 默认=线框"详情"） */
  @Builder
  ActionButton(user: UserRecord) {
    if (this.isPendingUser(user)) {
      Text('审核')
        .fontSize(12)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .backgroundColor($r('app.color.color_yellow'))
        .height(30)
        .padding({ left: 13, right: 13 })
        .borderRadius(AppConstants.RADIUS_SM)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.gotoDetail(user.userId);
        })
    } else if (user.status === 'banned') {
      Text('解封')
        .fontSize(12)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .backgroundColor($r('app.color.color_bg_card'))
        .border({ width: 1, color: $r('app.color.color_line_2') })
        .height(30)
        .padding({ left: 13, right: 13 })
        .borderRadius(AppConstants.RADIUS_SM)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.gotoDetail(user.userId);
        })
    } else {
      Text('详情')
        .fontSize(12)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .backgroundColor($r('app.color.color_bg_card'))
        .border({ width: 1, color: $r('app.color.color_line_2') })
        .height(30)
        .padding({ left: 13, right: 13 })
        .borderRadius(AppConstants.RADIUS_SM)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.gotoDetail(user.userId);
        })
    }
  }
}
