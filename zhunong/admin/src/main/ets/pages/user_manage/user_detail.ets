/**
 * user_detail - 用户详情（spec 3.3.1 / 10.8.3.1）
 *
 * 基本信息 + 多维度历史 + 封禁/解封/重置密码操作
 * - Tab 切换：买家订单 / 卖家订单 / 发布商品 / 发布帖子 / 发布直播 / 登录设备
 * - 底部固定操作栏：封禁按钮（弹 AlertDialog 选原因+时长+描述）/ 解封按钮 / 重置密码按钮
 *
 * 越权防御（spec 10.8.8）：aboutToAppear 校验 super_admin / user_admin
 */

import { Logger, AppConstants, ToastUtil, TokenStore, AdminRoutes, NavigationHelper, RouteName, ListStateView } from 'common';
import { AdminInfo } from 'common';
import {
  UserDetailAggregate,
  UserRecord,
  UserBanRequest,
  BanDuration,
  AdminRole,
  LoginDeviceRecord,
  USER_TYPE_LABELS,
  USER_STATUS_LABELS,
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
  /** 是否显示封禁弹窗 */
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

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        if (this.loadFailed) {
          ListStateView({ state: 'error', onRefresh: () => this.loadDetail() })
        } else if (this.isLoading && !this.aggregate) {
          ListStateView({ state: 'loading' })
        } else if (this.aggregate) {
          // 基本信息
          this.UserInfoCard(this.aggregate.user)
          // 统计栏
          this.StatsBar(this.aggregate)
          // Tab 切换
          this.TabBar()
          // 内容区
          this.ContentArea()
          // 底部操作栏
          this.BottomActionBar(this.aggregate.user)
        }
        // 封禁弹窗
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
      Text('用户详情')
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

  /** 用户基本信息卡 */
  @Builder
  UserInfoCard(user: UserRecord) {
    Column({ space: 8 }) {
      Row({ space: 12 }) {
        Stack() {
          Text(user.nickname.charAt(0))
            .fontSize(32)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
        }
        .width(64)
        .height(64)
        .borderRadius(32)
        .backgroundColor(user.userType === 'farmer' ? $r('app.color.color_secondary') : $r('app.color.color_primary'))

        Column({ space: 4 }) {
          Row({ space: 6 }) {
            Text(user.nickname)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.color_text_primary'))
            Text(USER_TYPE_LABELS[user.userType])
              .fontSize(11)
              .fontColor(user.userType === 'farmer' ? $r('app.color.color_secondary') : $r('app.color.color_primary'))
              .backgroundColor(user.userType === 'farmer' ? 'rgba(255,152,0,0.12)' : 'rgba(76,175,80,0.12)')
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(4)
            Text(USER_STATUS_LABELS[user.status])
              .fontSize(11)
              .fontColor(user.status === 'banned' ? $r('app.color.color_error') : $r('app.color.color_primary'))
              .backgroundColor(user.status === 'banned' ? 'rgba(244,67,54,0.12)' : 'rgba(76,175,80,0.12)')
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(4)
          }
          Text(`手机号：${user.phone}`)
            .fontSize(13)
            .fontColor($r('app.color.color_text_secondary'))
          Text(`账号 ID：${user.userId}`)
            .fontSize(12)
            .fontColor($r('app.color.color_text_hint'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      // 详细字段
      Column({ space: 4 }) {
        Row({ space: 8 }) {
          Text('注册时间：').fontSize(12).fontColor($r('app.color.color_text_hint'))
          Text(this.formatTime(user.createdAt)).fontSize(12).fontColor($r('app.color.color_text_secondary'))
        }
        Row({ space: 8 }) {
          Text('最后登录：').fontSize(12).fontColor($r('app.color.color_text_hint'))
          Text(this.formatTime(user.lastLoginAt)).fontSize(12).fontColor($r('app.color.color_text_secondary'))
        }
        if (user.lastLoginIp) {
          Row({ space: 8 }) {
            Text('最后登录 IP：').fontSize(12).fontColor($r('app.color.color_text_hint'))
            Text(user.lastLoginIp).fontSize(12).fontColor($r('app.color.color_text_secondary'))
          }
        }
        if (user.status === 'banned') {
          Row({ space: 8 }) {
            Text('封禁原因：').fontSize(12).fontColor($r('app.color.color_error'))
            Text(user.banReason || '-').fontSize(12).fontColor($r('app.color.color_error'))
          }
          Row({ space: 8 }) {
            Text('到期时间：').fontSize(12).fontColor($r('app.color.color_error'))
            Text(this.formatTime(user.banUntil)).fontSize(12).fontColor($r('app.color.color_error'))
          }
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(12)
    .margin({ left: 12, right: 12, top: 12 })
  }

  /** 统计栏 */
  @Builder
  StatsBar(agg: UserDetailAggregate) {
    Row({ space: 8 }) {
      this.StatItem('买家订单', agg.buyerOrderCount.toString())
      this.StatItem('卖家订单', agg.farmerOrderCount.toString())
      this.StatItem('商品', agg.publishedProducts.toString())
      this.StatItem('帖子', agg.publishedPosts.toString())
      this.StatItem('直播', agg.publishedLives.toString())
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 12 })
  }

  @Builder
  StatItem(label: string, value: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(18)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Bold)
      Text(label)
        .fontSize(10)
        .fontColor($r('app.color.color_text_secondary'))
    }
    .layoutWeight(1)
    .padding({ top: 12, bottom: 12 })
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(HorizontalAlign.Center)
  }

  /** Tab 栏 */
  @Builder
  TabBar() {
    Scroll() {
      Row({ space: 4 }) {
        ForEach(this.tabOptions, (opt: TabOption) => {
          Text(opt.label)
            .fontSize(12)
            .fontColor(this.currentTab === opt.value ? Color.White : $r('app.color.color_text_secondary'))
            .backgroundColor(this.currentTab === opt.value ? $r('app.color.color_primary') : $r('app.color.color_bg_card'))
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(14)
            .onClick(() => {
              this.currentTab = opt.value;
            })
        }, (opt: TabOption) => opt.value)
      }
      .padding({ left: 12, right: 12 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .padding({ top: 12, bottom: 8 })
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
    List({ space: 8 }) {
      ForEach(devices, (device: LoginDeviceRecord, index: number) => {
        ListItem() {
          Row({ space: 12 }) {
            Text('📱').fontSize(24)
            Column({ space: 4 }) {
              Text(device.deviceName)
                .fontSize(14)
                .fontColor($r('app.color.color_text_primary'))
                .fontWeight(FontWeight.Medium)
              Text(`${device.ipAddress} · ${device.location || ''}`)
                .fontSize(12)
                .fontColor($r('app.color.color_text_secondary'))
              Text(this.formatTime(device.loginAt))
                .fontSize(11)
                .fontColor($r('app.color.color_text_hint'))
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')
          .padding(12)
          .backgroundColor($r('app.color.color_bg_card'))
          .borderRadius(12)
          .alignItems(VerticalAlign.Center)
        }
      }, (device: LoginDeviceRecord, index: number) => `${device.deviceName}_${index}`)
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 12, right: 12, top: 8, bottom: 12 })
  }

  /** 占位内容（其他 Tab 后续接入） */
  @Builder
  PlaceholderContent() {
    Column({ space: 12 }) {
      Text('📊')
        .fontSize(64)
      Text('该 Tab 数据待后端接入')
        .fontSize(14)
        .fontColor($r('app.color.color_text_secondary'))
      Text('现阶段仅展示登录设备 Tab')
        .fontSize(12)
        .fontColor($r('app.color.color_text_hint'))
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  /** 底部操作栏 */
  @Builder
  BottomActionBar(user: UserRecord) {
    Row({ space: 8 }) {
      // 重置密码按钮（始终可用）
      Button('重置密码')
        .layoutWeight(1)
        .height(44)
        .borderRadius(22)
        .backgroundColor($r('app.color.color_bg_page'))
        .fontColor($r('app.color.color_text_primary'))
        .fontSize(14)
        .enabled(!this.isOperating)
        .onClick(() => {
          this.showResetDialog = true;
        })

      // 封禁/解封按钮（根据状态切换）
      if (user.status === 'banned') {
        Button('解封账号')
          .layoutWeight(1)
          .height(44)
          .borderRadius(22)
          .backgroundColor($r('app.color.color_primary'))
          .fontColor(Color.White)
          .fontSize(14)
          .enabled(!this.isOperating)
          .onClick(() => {
            this.doUnban();
          })
      } else {
        Button('封禁账号')
          .layoutWeight(1)
          .height(44)
          .borderRadius(22)
          .backgroundColor($r('app.color.color_error'))
          .fontColor(Color.White)
          .fontSize(14)
          .enabled(!this.isOperating)
          .onClick(() => {
            this.showBanDialog = true;
          })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.color_bg_card'))
    .border({ width: { top: 1 }, color: $r('app.color.color_divider') })
  }

  /** 封禁弹窗 */
  @Builder
  BanDialog() {
    Stack({ alignContent: Alignment.Center }) {
      // 遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => {
          this.showBanDialog = false;
        })

      // 弹窗内容
      Column({ space: 12 }) {
        Text('封禁用户')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.color_text_primary'))

        // 预设原因
        Text('封禁原因').fontSize(13).fontColor($r('app.color.color_text_secondary'))
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(PRESET_BAN_REASONS, (reason: string) => {
            Text(reason)
              .fontSize(12)
              .fontColor(this.banReason === reason ? Color.White : $r('app.color.color_text_secondary'))
              .backgroundColor(this.banReason === reason ? $r('app.color.color_error') : $r('app.color.color_bg_page'))
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .margin({ right: 6, bottom: 6 })
              .borderRadius(12)
              .onClick(() => {
                this.banReason = reason;
              })
          }, (reason: string) => reason)
        }
        .width('100%')

        // 封禁时长
        Text('封禁时长').fontSize(13).fontColor($r('app.color.color_text_secondary'))
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.durationOptions, (opt: DurationOption) => {
            Text(opt.label)
              .fontSize(12)
              .fontColor(this.banDuration === opt.value ? Color.White : $r('app.color.color_text_secondary'))
              .backgroundColor(this.banDuration === opt.value ? $r('app.color.color_error') : $r('app.color.color_bg_page'))
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .margin({ right: 6, bottom: 6 })
              .borderRadius(12)
              .onClick(() => {
                this.banDuration = opt.value;
              })
          }, (opt: DurationOption) => opt.value)
        }
        .width('100%')

        // 自定义描述
        Text('自定义描述（选"其他"时必填）').fontSize(13).fontColor($r('app.color.color_text_secondary'))
        TextArea({ text: this.banDescription, placeholder: '最多 200 字' })
          .width('100%')
          .height(80)
          .fontSize(13)
          .backgroundColor($r('app.color.color_bg_page'))
          .borderRadius(8)
          .maxLength(200)
          .onChange((value: string) => {
            this.banDescription = value;
          })

        // 操作按钮
        Row({ space: 12 }) {
          Button('取消')
            .layoutWeight(1)
            .height(40)
            .borderRadius(20)
            .backgroundColor($r('app.color.color_bg_page'))
            .fontColor($r('app.color.color_text_secondary'))
            .fontSize(14)
            .enabled(!this.isOperating)
            .onClick(() => {
              this.showBanDialog = false;
              this.banDescription = '';
            })
          Button('确认封禁')
            .layoutWeight(1)
            .height(40)
            .borderRadius(20)
            .backgroundColor($r('app.color.color_error'))
            .fontColor(Color.White)
            .fontSize(14)
            .enabled(!this.isOperating)
            .onClick(() => {
              this.doBan();
            })
        }
        .width('100%')
      }
      .width('80%')
      .padding(20)
      .backgroundColor($r('app.color.color_bg_card'))
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
  }

  /** 重置密码确认弹窗 */
  @Builder
  ResetPasswordDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => {
          this.showResetDialog = false;
        })

      Column({ space: 12 }) {
        Text('确认重置密码')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.color_text_primary'))
        Text('将该用户密码重置为默认密码 zhunong@123，用户下次登录时将强制修改。')
          .fontSize(13)
          .fontColor($r('app.color.color_text_secondary'))

        Row({ space: 12 }) {
          Button('取消')
            .layoutWeight(1)
            .height(40)
            .borderRadius(20)
            .backgroundColor($r('app.color.color_bg_page'))
            .fontColor($r('app.color.color_text_secondary'))
            .fontSize(14)
            .enabled(!this.isOperating)
            .onClick(() => {
              this.showResetDialog = false;
            })
          Button('确认重置')
            .layoutWeight(1)
            .height(40)
            .borderRadius(20)
            .backgroundColor($r('app.color.color_primary'))
            .fontColor(Color.White)
            .fontSize(14)
            .enabled(!this.isOperating)
            .onClick(() => {
              this.doResetPassword();
            })
        }
        .width('100%')
      }
      .width('80%')
      .padding(20)
      .backgroundColor($r('app.color.color_bg_card'))
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
  }
}

/** BanDuration 转数字（用于日志 quantity 字段，永久返回 0） */
function days2num(d: BanDuration): number {
  if (d === '1d') return 1;
  if (d === '7d') return 7;
  if (d === '30d') return 30;
  return 0;
}
