/**
 * user_detail - 用户详情（UI 复刻对齐 admin-users.html 设计语言）
 * 遵循 spec 3.3.1 / 10.8.3.1：
 *  - 基本信息 + 多维度历史 + 封禁/解封/重置密码操作
 *  - Tab 切换：买家订单 / 卖家订单 / 发布商品 / 发布帖子 / 发布直播 / 登录设备
 *  - 底部固定操作栏：封禁按钮（弹模态选原因+时长+描述）/ 解封按钮 / 重置密码按钮
 *
 * UI 设计要点（对齐设计语言）：
 *  - 顶栏：圆形返回键 + 居中标题 "用户详情"
 *  - 用户信息卡：白色卡 + 60 头像 + 名称 + 类型 pill + 状态 pill + 详细字段
 *  - 5 列统计栏（带竖线分隔）
 *  - Tab 横滑胶囊（激活态墨黑底）
 *  - 底部固定操作栏（重置密码=线框 / 封禁=红 / 解封=墨黑）
 *  - 封禁弹窗使用方案 C 模式（@Local showBanDialog + Stack 遮罩 + @Builder）
 *
 * 越权防御（spec 10.8.8）：aboutToAppear 校验 super_admin / user_admin
 */

import { Logger, AppConstants, ToastUtil, TokenStore, NavigationHelper, RouteName, ListStateView } from 'common';
import { AdminInfo } from 'common';
import {
  UserDetailAggregate,
  UserRecord,
  UserRecordType,
  UserBanRequest,
  BanDuration,
  AdminRole,
  LoginDeviceRecord,
  USER_TYPE_LABELS,
  BAN_DURATION_LABELS,
  PRESET_BAN_REASONS
} from '../../model/AdminModels';
import { UserRepository } from '../../repository/UserRepository';

/** Tab 选项 */
interface TabOption {
  value: string;
  label: string;
}

/** 封禁时长选项（避免元组字面量 + as 断言，遵循 spec 10.6.4 / 10.7.5） */
interface DurationOption {
  value: BanDuration;
  label: string;
}

/** 统计项 */
interface StatItemData {
  num: number;
  lab: string;
}

@ComponentV2
export struct UserDetail {
  /** 用户详情聚合数据 */
  @Local aggregate: UserDetailAggregate | null = null;
  /** 当前 Tab */
  @Local currentTab: string = 'devices';
  /** 是否正在加载 */
  @Local isLoading: boolean = false;
  /** 加载失败 */
  @Local loadFailed: boolean = false;
  /** 是否正在操作 */
  @Local isOperating: boolean = false;
  /** 是否显示封禁弹窗（方案 C：@Local + Stack + @Builder） */
  @Local showBanDialog: boolean = false;
  /** 封禁原因 */
  @Local banReason: string = PRESET_BAN_REASONS[0];
  /** 封禁描述 */
  @Local banDescription: string = '';
  /** 封禁时长 */
  @Local banDuration: BanDuration = '7d';
  /** 是否显示重置密码确认弹窗 */
  @Local showResetDialog: boolean = false;

  /** Tab 选项 */
  private tabOptions: TabOption[] = [
    { value: 'devices', label: '登录设备' },
    { value: 'buyer_orders', label: '买家订单' },
    { value: 'farmer_orders', label: '卖家订单' },
    { value: 'products', label: '发布商品' },
    { value: 'posts', label: '发布帖子' },
    { value: 'lives', label: '发布直播' }
  ];

  /** 封禁时长选项（spec 10.6.4：禁止元组字面量 + as 断言） */
  private durationOptions: DurationOption[] = [
    { value: '1d', label: BAN_DURATION_LABELS['1d'] },
    { value: '7d', label: BAN_DURATION_LABELS['7d'] },
    { value: '30d', label: BAN_DURATION_LABELS['30d'] },
    { value: 'permanent', label: BAN_DURATION_LABELS['permanent'] }
  ];

  /** 用户 ID（路由参数） */
  private userId: string = '';

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
    // 读取路由参数（spec 10.7.5：as Record<string, string> 模式）
    const params = NavigationHelper.getParam<Record<string, string>>() as Record<string, string>;
    if (params && params.userId) {
      this.userId = params.userId;
    }
    Logger.info(AppConstants.SCENE_ADMIN, {
      action: 'user_detail_appear',
      adminId: adminInfo.adminId,
      userId: this.userId
    });
    await this.loadDetail();
  }

  /** 加载用户详情 */
  private async loadDetail(): Promise<void> {
    if (this.userId.length === 0) {
      ToastUtil.error('用户 ID 缺失');
      NavigationHelper.pop();
      return;
    }
    this.isLoading = true;
    this.loadFailed = false;
    try {
      const result = await UserRepository.getUserDetail(this.userId);
      if (result) {
        this.aggregate = result;
      } else {
        ToastUtil.error('用户不存在');
        NavigationHelper.pop();
      }
    } catch (err) {
      this.loadFailed = true;
      Logger.error(AppConstants.SCENE_ADMIN, { action: 'load_user_detail_fail', error: (err as Error).message });
    } finally {
      this.isLoading = false;
    }
  }

  /** 执行封禁 */
  private async doBan(): Promise<void> {
    if (!this.aggregate) {
      return;
    }
    if (this.banReason === '其他' && this.banDescription.trim().length === 0) {
      ToastUtil.warning('选"其他"时需填写自定义描述');
      return;
    }
    this.isOperating = true;
    try {
      const req: UserBanRequest = {
        reason: this.banReason,
        duration: this.banDuration
      };
      if (this.banDescription.trim().length > 0) {
        req.description = this.banDescription.trim();
      }
      const ok: boolean = await UserRepository.banUser(this.userId, req);
      if (ok) {
        this.aggregate.user.status = 'banned';
        this.aggregate.user.banReason = this.banReason;
        if (req.description) {
          this.aggregate.user.banReason = `${this.banReason}：${req.description}`;
        }
        // 计算封禁到期时间
        if (this.banDuration === 'permanent') {
          this.aggregate.user.banUntil = 0;
        } else {
          const days: number = this.banDuration === '1d' ? 1 : (this.banDuration === '7d' ? 7 : 30);
          this.aggregate.user.banUntil = Date.now() + days * 86400000;
        }
        ToastUtil.success('已封禁');
        Logger.info(AppConstants.SCENE_ADMIN, {
          action: 'ban_user_success',
          userId: this.userId,
          reason: this.banReason,
          quantity: days2num(this.banDuration)
        });
        this.showBanDialog = false;
        this.banDescription = '';
      }
    } catch (err) {
      Logger.error(AppConstants.SCENE_ADMIN, { action: 'ban_user_fail', error: (err as Error).message });
      ToastUtil.error('封禁失败');
    } finally {
      this.isOperating = false;
    }
  }

  /** 执行解封 */
  private async doUnban(): Promise<void> {
    if (!this.aggregate) {
      return;
    }
    this.isOperating = true;
    try {
      const ok: boolean = await UserRepository.unbanUser(this.userId);
      if (ok) {
        this.aggregate.user.status = 'active';
        this.aggregate.user.banReason = undefined;
        this.aggregate.user.banUntil = undefined;
        ToastUtil.success('已解封');
        Logger.info(AppConstants.SCENE_ADMIN, { action: 'unban_user_success', userId: this.userId });
      }
    } catch (err) {
      Logger.error(AppConstants.SCENE_ADMIN, { action: 'unban_user_fail', error: (err as Error).message });
      ToastUtil.error('解封失败');
    } finally {
      this.isOperating = false;
    }
  }

  /** 执行重置密码 */
  private async doResetPassword(): Promise<void> {
    this.isOperating = true;
    try {
      const ok: boolean = await UserRepository.resetPassword(this.userId);
      if (ok) {
        ToastUtil.success('密码已重置为 zhunong@123');
        Logger.info(AppConstants.SCENE_ADMIN, { action: 'reset_password_success', userId: this.userId });
        this.showResetDialog = false;
      }
    } catch (err) {
      Logger.error(AppConstants.SCENE_ADMIN, { action: 'reset_password_fail', error: (err as Error).message });
      ToastUtil.error('重置失败');
    } finally {
      this.isOperating = false;
    }
  }

  /** 格式化时间 */
  private formatTime(ts: number | undefined): string {
    if (!ts || ts === 0) {
      return '永久';
    }
    const d: Date = new Date(ts);
    const y: number = d.getFullYear();
    const m: string = (d.getMonth() + 1).toString().padStart(2, '0');
    const day: string = d.getDate().toString().padStart(2, '0');
    const h: string = d.getHours().toString().padStart(2, '0');
    const min: string = d.getMinutes().toString().padStart(2, '0');
    return `${y}-${m}-${day} ${h}:${min}`;
  }

  /** 获取用户头像资源 */
  private getAvatarResource(user: UserRecord): Resource {
    return user.userType === 'farmer' ? $r('app.media.avatar_farmer') : $r('app.media.avatar_customer');
  }

  /** 构建统计项列表 */
  private buildStats(agg: UserDetailAggregate): StatItemData[] {
    return [
      { num: agg.buyerOrderCount, lab: '买家订单' },
      { num: agg.farmerOrderCount, lab: '卖家订单' },
      { num: agg.publishedProducts, lab: '商品' },
      { num: agg.publishedPosts, lab: '帖子' },
      { num: agg.publishedLives, lab: '直播' }
    ];
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          this.TopBar()
          if (this.loadFailed) {
            ListStateView({ state: 'error', onRefresh: () => this.loadDetail() })
          } else if (this.isLoading && !this.aggregate) {
            ListStateView({ state: 'loading' })
          } else if (this.aggregate) {
            // 滚动内容区
            Scroll() {
              Column({ space: 12 }) {
                // 基本信息
                this.UserInfoCard(this.aggregate.user)
                // 统计栏
                this.StatsBar(this.aggregate)
                // Tab 切换
                this.TabBar()
                // 内容区
                this.ContentArea()
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .padding({ bottom: 80 })
            }
            .width('100%')
            .layoutWeight(1)
            .scrollBar(BarState.Off)
            .align(Alignment.Top)
            // 底部操作栏
            this.BottomActionBar(this.aggregate.user)
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.color_cream'))

        // 封禁弹窗（方案 C：@Local showBanDialog + Stack + @Builder）
        if (this.showBanDialog) {
          this.BanDialog()
        }
        // 重置密码确认弹窗
        if (this.showResetDialog) {
          this.ResetPasswordDialog()
        }
      }
      .width('100%')
      .height('100%')
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

      Text('用户详情')
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

  /** 用户基本信息卡 */
  @Builder
  UserInfoCard(user: UserRecord) {
    Column({ space: 10 }) {
      // 头像 + 名称 + 类型 + 状态
      Row({ space: 14 }) {
        Image(this.getAvatarResource(user))
          .width(60)
          .height(60)
          .borderRadius(30)
          .backgroundColor($r('app.color.color_fill'))
          .objectFit(ImageFit.Cover)
          .border({ width: 2, color: $r('app.color.color_bg_card') })
          .shadow({ radius: 8, color: 'rgba(26,26,26,0.08)', offsetX: 0, offsetY: 2 })

        Column({ space: 6 }) {
          Row({ space: 8 }) {
            Text(user.nickname)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.color_ink'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .constraintSize({ maxWidth: 120 })
            this.UserTypePill(user.userType)
            this.UserStatusPill(user)
          }
          .alignItems(VerticalAlign.Center)

          Text(`手机号：${user.phone}`)
            .fontSize(13)
            .fontColor($r('app.color.color_text_2'))
          Text(`ID：${user.userId}`)
            .fontSize(12)
            .fontColor($r('app.color.color_text_4'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      Divider().color($r('app.color.color_line')).strokeWidth(1)

      // 详细字段
      Column({ space: 6 }) {
        Row({ space: 8 }) {
          Text('注册时间')
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
          Text(this.formatTime(user.createdAt))
            .fontSize(12)
            .fontColor($r('app.color.color_ink_2'))
            .fontWeight(FontWeight.Medium)
        }
        Row({ space: 8 }) {
          Text('最后登录')
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
          Text(this.formatTime(user.lastLoginAt))
            .fontSize(12)
            .fontColor($r('app.color.color_ink_2'))
            .fontWeight(FontWeight.Medium)
        }
        if (user.lastLoginIp) {
          Row({ space: 8 }) {
            Text('登录 IP')
              .fontSize(12)
              .fontColor($r('app.color.color_text_3'))
            Text(user.lastLoginIp)
              .fontSize(12)
              .fontColor($r('app.color.color_ink_2'))
              .fontWeight(FontWeight.Medium)
          }
        }
        if (user.status === 'banned') {
          Row({ space: 8 }) {
            Text('封禁原因')
              .fontSize(12)
              .fontColor($r('app.color.color_live'))
            Text(user.banReason || '-')
              .fontSize(12)
              .fontColor($r('app.color.color_live'))
              .fontWeight(FontWeight.Medium)
          }
          Row({ space: 8 }) {
            Text('到期时间')
              .fontSize(12)
              .fontColor($r('app.color.color_live'))
            Text(this.formatTime(user.banUntil))
              .fontSize(12)
              .fontColor($r('app.color.color_live'))
              .fontWeight(FontWeight.Medium)
          }
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .margin({ left: 16, right: 16, top: 8 })
    .alignItems(HorizontalAlign.Start)
  }

  /** 用户类型 pill */
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

  /** 用户状态 pill */
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

  /** 统计栏（5 列带竖线分隔） */
  @Builder
  StatsBar(agg: UserDetailAggregate) {
    Row() {
      ForEach(this.buildStats(agg), (stat: StatItemData, index: number) => {
        Row() {
          Column({ space: 4 }) {
            Text(`${stat.num}`)
              .fontSize(18)
              .fontColor($r('app.color.color_ink'))
              .fontWeight(FontWeight.Bold)
            Text(stat.lab)
              .fontSize(11)
              .fontColor($r('app.color.color_text_3'))
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          if (index < this.buildStats(agg).length - 1) {
            Column()
              .width(1)
              .height(28)
              .backgroundColor($r('app.color.color_line'))
          }
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }, (stat: StatItemData, index: number) => `${stat.lab}_${index}`)
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .margin({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
  }

  /** Tab 栏（横滑胶囊） */
  @Builder
  TabBar() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.tabOptions, (opt: TabOption) => {
          Text(opt.label)
            .fontSize(13)
            .fontColor(this.currentTab === opt.value ? Color.White : $r('app.color.color_text_2'))
            .fontWeight(this.currentTab === opt.value ? FontWeight.Bold : FontWeight.Medium)
            .backgroundColor(this.currentTab === opt.value ? $r('app.color.color_cta_black') : $r('app.color.color_bg_card'))
            .height(32)
            .padding({ left: 14, right: 14 })
            .borderRadius(AppConstants.RADIUS_PILL)
            .shadow(this.currentTab === opt.value ? { radius: 0, color: Color.Transparent, offsetX: 0, offsetY: 0 } : AppConstants.SHADOW_CARD)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.currentTab = opt.value;
            })
        }, (opt: TabOption) => opt.value)
      }
      .padding({ left: 16, right: 16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .margin({ top: 4 })
  }

  /** 内容区 */
  @Builder
  ContentArea() {
    if (this.aggregate) {
      if (this.currentTab === 'devices') {
        this.DevicesList(this.aggregate.loginDevices)
      } else {
        this.PlaceholderContent()
      }
    }
  }

  /** 登录设备列表 */
  @Builder
  DevicesList(devices: LoginDeviceRecord[]) {
    Column({ space: 8 }) {
      ForEach(devices, (device: LoginDeviceRecord, index: number) => {
        Row({ space: 12 }) {
          Stack() {
            Text('📱')
              .fontSize(22)
          }
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor($r('app.color.color_fill'))
          Column({ space: 4 }) {
            Text(device.deviceName)
              .fontSize(14)
              .fontColor($r('app.color.color_ink'))
              .fontWeight(FontWeight.Bold)
            Text(`${device.ipAddress} · ${device.location || ''}`)
              .fontSize(12)
              .fontColor($r('app.color.color_text_3'))
            Text(this.formatTime(device.loginAt))
              .fontSize(11)
              .fontColor($r('app.color.color_text_4'))
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding(12)
        .backgroundColor($r('app.color.color_bg_card'))
        .borderRadius(AppConstants.RADIUS_MD)
        .shadow(AppConstants.SHADOW_CARD)
        .alignItems(VerticalAlign.Center)
      }, (device: LoginDeviceRecord, index: number) => `${device.deviceName}_${index}`)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 12 })
    .alignItems(HorizontalAlign.Start)
  }

  /** 占位内容（其他 Tab 后续接入） */
  @Builder
  PlaceholderContent() {
    Column({ space: 12 }) {
      Text('📊')
        .fontSize(64)
      Text('该 Tab 数据待后端接入')
        .fontSize(14)
        .fontColor($r('app.color.color_text_2'))
      Text('现阶段仅展示登录设备 Tab')
        .fontSize(12)
        .fontColor($r('app.color.color_text_4'))
    }
    .width('100%')
    .padding({ top: 40, bottom: 40 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  /** 底部固定操作栏 */
  @Builder
  BottomActionBar(user: UserRecord) {
    Row({ space: 10 }) {
      // 重置密码按钮（线框样式）
      Text('重置密码')
        .layoutWeight(1)
        .height(46)
        .borderRadius(AppConstants.RADIUS_MD)
        .backgroundColor($r('app.color.color_bg_card'))
        .border({ width: 1, color: $r('app.color.color_line_2') })
        .fontColor($r('app.color.color_ink'))
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          if (!this.isOperating) {
            this.showResetDialog = true;
          }
        })

      // 封禁/解封按钮（根据状态切换）
      if (user.status === 'banned') {
        Text('解封账号')
          .layoutWeight(1)
          .height(46)
          .borderRadius(AppConstants.RADIUS_MD)
          .backgroundColor($r('app.color.color_cta_black'))
          .fontColor(Color.White)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            if (!this.isOperating) {
              this.doUnban();
            }
          })
      } else {
        Text('封禁账号')
          .layoutWeight(1)
          .height(46)
          .borderRadius(AppConstants.RADIUS_MD)
          .backgroundColor($r('app.color.color_live'))
          .fontColor(Color.White)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            if (!this.isOperating) {
              this.showBanDialog = true;
            }
          })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow({ radius: 12, color: 'rgba(26,26,26,0.05)', offsetX: 0, offsetY: -2 })
  }

  /** 封禁弹窗（方案 C：Stack + 遮罩 + @Builder） */
  @Builder
  BanDialog() {
    Stack() {
      // 遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => {
          this.showBanDialog = false;
        })

      // 弹窗内容
      Column({ space: 14 }) {
        Text('封禁用户')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.color_ink'))

        // 预设原因
        Text('封禁原因')
          .fontSize(13)
          .fontColor($r('app.color.color_text_2'))
          .fontWeight(FontWeight.Medium)
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(PRESET_BAN_REASONS, (reason: string) => {
            Text(reason)
              .fontSize(12)
              .fontColor(this.banReason === reason ? Color.White : $r('app.color.color_text_2'))
              .fontWeight(this.banReason === reason ? FontWeight.Bold : FontWeight.Medium)
              .backgroundColor(this.banReason === reason ? $r('app.color.color_live') : $r('app.color.color_fill'))
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .margin({ right: 6, bottom: 6 })
              .borderRadius(AppConstants.RADIUS_PILL)
              .onClick(() => {
                this.banReason = reason;
              })
          }, (reason: string) => reason)
        }
        .width('100%')

        // 封禁时长
        Text('封禁时长')
          .fontSize(13)
          .fontColor($r('app.color.color_text_2'))
          .fontWeight(FontWeight.Medium)
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.durationOptions, (opt: DurationOption) => {
            Text(opt.label)
              .fontSize(12)
              .fontColor(this.banDuration === opt.value ? Color.White : $r('app.color.color_text_2'))
              .fontWeight(this.banDuration === opt.value ? FontWeight.Bold : FontWeight.Medium)
              .backgroundColor(this.banDuration === opt.value ? $r('app.color.color_live') : $r('app.color.color_fill'))
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .margin({ right: 6, bottom: 6 })
              .borderRadius(AppConstants.RADIUS_PILL)
              .onClick(() => {
                this.banDuration = opt.value;
              })
          }, (opt: DurationOption) => opt.value)
        }
        .width('100%')

        // 自定义描述
        Text('自定义描述（选"其他"时必填）')
          .fontSize(13)
          .fontColor($r('app.color.color_text_2'))
          .fontWeight(FontWeight.Medium)
        TextArea({ text: this.banDescription, placeholder: '最多 200 字' })
          .width('100%')
          .height(80)
          .fontSize(13)
          .backgroundColor($r('app.color.color_fill'))
          .borderRadius(AppConstants.RADIUS_MD)
          .maxLength(200)
          .onChange((value: string) => {
            this.banDescription = value;
          })

        // 操作按钮
        Row({ space: 12 }) {
          Text('取消')
            .layoutWeight(1)
            .height(44)
            .borderRadius(AppConstants.RADIUS_MD)
            .backgroundColor($r('app.color.color_fill'))
            .fontColor($r('app.color.color_text_2'))
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              if (!this.isOperating) {
                this.showBanDialog = false;
                this.banDescription = '';
              }
            })
          Text(this.isOperating ? '处理中...' : '确认封禁')
            .layoutWeight(1)
            .height(44)
            .borderRadius(AppConstants.RADIUS_MD)
            .backgroundColor($r('app.color.color_live'))
            .fontColor(Color.White)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              if (!this.isOperating) {
                this.doBan();
              }
            })
        }
        .width('100%')
      }
      .width('85%')
      .padding(20)
      .backgroundColor($r('app.color.color_bg_card'))
      .borderRadius(AppConstants.RADIUS_XL)
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.Center)
  }

  /** 重置密码确认弹窗（方案 C） */
  @Builder
  ResetPasswordDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => {
          this.showResetDialog = false;
        })

      Column({ space: 14 }) {
        Text('确认重置密码')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.color_ink'))
        Text('将该用户密码重置为默认密码 zhunong@123，用户下次登录时将强制修改。')
          .fontSize(13)
          .fontColor($r('app.color.color_text_2'))
          .lineHeight(20)

        Row({ space: 12 }) {
          Text('取消')
            .layoutWeight(1)
            .height(44)
            .borderRadius(AppConstants.RADIUS_MD)
            .backgroundColor($r('app.color.color_fill'))
            .fontColor($r('app.color.color_text_2'))
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              if (!this.isOperating) {
                this.showResetDialog = false;
              }
            })
          Text(this.isOperating ? '处理中...' : '确认重置')
            .layoutWeight(1)
            .height(44)
            .borderRadius(AppConstants.RADIUS_MD)
            .backgroundColor($r('app.color.color_cta_black'))
            .fontColor(Color.White)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              if (!this.isOperating) {
                this.doResetPassword();
              }
            })
        }
        .width('100%')
      }
      .width('85%')
      .padding(20)
      .backgroundColor($r('app.color.color_bg_card'))
      .borderRadius(AppConstants.RADIUS_XL)
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.Center)
  }
}

/** BanDuration 转数字（用于日志 quantity 字段，永久返回 0） */
function days2num(d: BanDuration): number {
  if (d === '1d') return 1;
  if (d === '7d') return 7;
  if (d === '30d') return 30;
  return 0;
}
