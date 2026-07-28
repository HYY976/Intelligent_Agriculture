/**
 * setting - 设置页（spec 3.2.4.5）
 *
 * 对齐设计稿 pages/farmer-setting.html：
 *  - 顶部导航（圆形返回键 + 居中标题 + 占位）
 *  - 个人信息卡（spec 16.9：头像/姓名可修改，从相册选头像）
 *  - 字号模式卡（segmented control: 标准 / 老年大字 + 提示文案，全局生效）
 *  - 其他设置卡（清除缓存 / 意见反馈 / 关于我们，彩色图标）
 *  - 退出登录按钮（白底卡片 + 红字）
 *  - 退出确认弹窗（居中 + 遮罩）
 *
 * spec 10.18：@Local modeRef 持有 AppStorageV2 共享 ref，@Trace value 变更自动刷新
 * spec 10.16：方案 C 自建模态（@Local show + Stack + @Builder）
 * spec 16.9：移除主题模式卡；内容上移贴顶；字号切换通过 ModeStore 广播全局生效
 */

import { Logger, AppConstants, ToastUtil, ModeStore, TokenStore, NavigationHelper, RouteName, FontUtil } from 'common';
import type { CurrentModeKey, UserInfo } from 'common';
import { ImagePickerUtil } from '../../utils/ImagePickerUtil';

/** 字号选项 */
interface FontSizeOption {
  value: string;
  label: string;
}

/** 图标底色 */
type IconTone = 'orange' | 'green' | 'blue' | 'soft';

/** 设置项 */
interface SettingItem {
  /** 主标题 */
  label: string;
  /** 图标 emoji */
  icon: string;
  /** 图标底色 */
  tone: IconTone;
  /** 右侧值文案（可空） */
  value: string;
  /** 是否显示箭头 */
  showArrow: boolean;
  /** 点击行为 */
  action: 'clearCache' | 'feedback' | 'about';
}

@ComponentV2
export struct Setting {
  /** 当前模式 — spec 10.18：@Local modeRef 持有 AppStorageV2 共享 ref（spec 16.9：移除主题模式） */
  @Local modeRef: CurrentModeKey = ModeStore.connectModeRef();
  /** 版本号 */
  @Local readonly version: string = 'v1.0.0';
  /** 缓存大小 */
  @Local cacheSize: string = '23.5MB';

  /** spec 16.9：个人信息（姓名/头像），从 TokenStore 读取 */
  @Local userName: string = '';
  @Local avatarUrl: string = '';
  /** 姓名编辑输入框临时值 */
  @Local nameInput: string = '';
  /** 姓名编辑弹窗 */
  @Local showNameDialog: boolean = false;

  /** 字号选项 */
  private fontSizeOptions: FontSizeOption[] = [
    { value: AppConstants.MODE_STANDARD, label: '标准' },
    { value: AppConstants.MODE_ELDER, label: '老年大字' }
  ];

  /** 其他设置项 */
  private otherItems: SettingItem[] = [
    { label: '清除缓存', icon: '🧹', tone: 'orange', value: '23.5MB', showArrow: true, action: 'clearCache' },
    { label: '意见反馈', icon: '💬', tone: 'green', value: '', showArrow: true, action: 'feedback' },
    { label: '关于我们', icon: 'ℹ', tone: 'blue', value: 'v1.0.0', showArrow: true, action: 'about' }
  ];

  /** 退出登录确认弹窗显示状态（spec 10.16：方案 C 自建模态） */
  @Local showLogoutDialog: boolean = false;

  async aboutToAppear(): Promise<void> {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'setting_appear' });
    await this.loadUserInfo();
  }

  /** spec 16.9：加载注册用户信息（姓名/头像） */
  private async loadUserInfo(): Promise<void> {
    try {
      const user: UserInfo | null = await TokenStore.getUserInfo();
      if (user) {
        this.userName = user.nickname && user.nickname.length > 0 ? user.nickname : '未设置';
        this.avatarUrl = user.avatar;
        this.nameInput = user.nickname ?? '';
      }
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'load_user_info_fail', error: (err as Error).message });
    }
  }

  /** spec 16.9：保存姓名到 TokenStore */
  private async saveUserName(): Promise<void> {
    const trimmed: string = this.nameInput.trim();
    if (trimmed.length === 0) {
      ToastUtil.warning('请输入姓名');
      return;
    }
    try {
      const user: UserInfo | null = await TokenStore.getUserInfo();
      if (user) {
        const updated: UserInfo = {
          userId: user.userId,
          phone: user.phone,
          nickname: trimmed,
          avatar: this.avatarUrl,
          userType: user.userType,
          status: user.status,
          createdAt: user.createdAt,
          lastLoginAt: user.lastLoginAt
        };
        await TokenStore.setUserInfo(updated);
        this.userName = trimmed;
        this.showNameDialog = false;
        ToastUtil.success('姓名已更新');
        Logger.info(AppConstants.SCENE_FARMER, { action: 'user_name_updated', name: trimmed });
      }
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'save_user_name_fail', error: (err as Error).message });
      ToastUtil.error('保存失败');
    }
  }

  /** spec 16.9：从相册选择头像 */
  private pickAvatar(): void {
    ImagePickerUtil.pickSingleImage(
      (uri: string) => {
        this.avatarUrl = uri;
        this.persistAvatar(uri);
      },
      (msg: string) => {
        ToastUtil.warning(msg);
      }
    );
  }

  /** spec 16.9：保存头像 URI 到 TokenStore */
  private async persistAvatar(uri: string): Promise<void> {
    try {
      const user: UserInfo | null = await TokenStore.getUserInfo();
      if (user) {
        const updated: UserInfo = {
          userId: user.userId,
          phone: user.phone,
          nickname: user.nickname,
          avatar: uri,
          userType: user.userType,
          status: user.status,
          createdAt: user.createdAt,
          lastLoginAt: user.lastLoginAt
        };
        await TokenStore.setUserInfo(updated);
        ToastUtil.success('头像已更新');
        Logger.info(AppConstants.SCENE_FARMER, { action: 'avatar_updated' });
      }
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'save_avatar_fail', error: (err as Error).message });
    }
  }

  /** spec 16.6：当前是否老年大字模式 */
  private isElder(): boolean {
    return FontUtil.isElder(this.modeRef.value);
  }

  /** 切换字号模式（spec 16.9：全局生效，ModeStore 通过 AppStorageV2 广播到所有页面） */
  private async onModeChange(mode: string): Promise<void> {
    if (mode === this.modeRef.value) {
      return;
    }
    const prev: string = this.modeRef.value;
    if (mode === AppConstants.MODE_ELDER) {
      await ModeStore.setMode(AppConstants.MODE_ELDER);
    } else {
      await ModeStore.setMode(AppConstants.MODE_STANDARD);
    }
    Logger.info(AppConstants.SCENE_FARMER, { action: 'mode_change', from: prev, to: this.modeRef.value });
    ToastUtil.success(`已切换到${this.modeRef.value === AppConstants.MODE_ELDER ? '老年大字' : '标准'}模式`);
  }

  /** 清除缓存 */
  private async clearCache(): Promise<void> {
    this.cacheSize = '0MB';
    ToastUtil.success('缓存已清除');
    Logger.info(AppConstants.SCENE_FARMER, { action: 'clear_cache' });
  }

  /** 处理其他设置项点击 */
  private onOtherItemTap(action: string): void {
    switch (action) {
      case 'clearCache':
        this.clearCache();
        break;
      case 'feedback':
        ToastUtil.info('意见反馈功能开发中');
        break;
      case 'about':
        ToastUtil.info('智农卖家 v1.0.0');
        break;
      default:
        break;
    }
  }

  /** 退出登录：打开确认弹窗 */
  private logout(): void {
    this.showLogoutDialog = true;
  }

  /** 执行退出登录 */
  private async doLogout(): Promise<void> {
    this.showLogoutDialog = false;
    try {
      await TokenStore.clearAuth();
      Logger.info(AppConstants.SCENE_FARMER, { action: 'logout_success' });
      ToastUtil.success('已退出登录');
      NavigationHelper.replace(RouteName.FARMER_SPLASH);
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'logout_fail', error: (err as Error).message });
    }
  }

  /** 取图标底色 */
  private toneBg(tone: IconTone): Resource {
    switch (tone) {
      case 'orange': return $r('app.color.color_warn_soft');
      case 'green': return $r('app.color.color_green_soft');
      case 'blue': return $r('app.color.color_info_soft');
      case 'soft':
      default: return $r('app.color.color_fill');
    }
  }

  /** 取图标前景色 */
  private toneFg(tone: IconTone): Resource {
    switch (tone) {
      case 'orange': return $r('app.color.color_warn');
      case 'green': return $r('app.color.color_green_deep');
      case 'blue': return $r('app.color.color_info');
      case 'soft':
      default: return $r('app.color.color_text_2');
    }
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          this.TopBar()
          Scroll() {
            Column({ space: 12 }) {
              // spec 16.9：个人信息卡置顶（姓名/头像可修改），原主题模式卡已移除
              this.PersonalInfoCard()
              this.FontSizeCard()
              this.OtherSettingsCard()
              this.LogoutButton()
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 0, bottom: 16 })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.color_cream'))

        // 退出登录确认弹窗（spec 10.16：方案 C 自建模态）
        if (this.showLogoutDialog) {
          this.LogoutConfirmDialog()
        }
        // spec 16.9：姓名编辑弹窗
        if (this.showNameDialog) {
          this.NameEditDialog()
        }
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
  }

  /** spec 16.9：个人信息卡（姓名/头像修改） */
  @Builder
  PersonalInfoCard() {
    Column({ space: 14 }) {
      Row() {
        Text('个人信息')
          .fontSize(FontUtil.s(16, this.isElder()))
          .fontColor($r('app.color.color_ink_2'))
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
      }
      .width('100%')

      // 头像行
      Row({ space: 12 }) {
        Text('头像')
          .fontSize(FontUtil.s(15, this.isElder()))
          .fontColor($r('app.color.color_text_2'))
          .layoutWeight(1)
        Row({ space: 10 }) {
          if (this.avatarUrl.length > 0 &&
              (this.avatarUrl.startsWith('file://') || this.avatarUrl.startsWith('http'))) {
            Image(this.avatarUrl)
              .width(48)
              .height(48)
              .borderRadius(24)
          } else {
            Text('👤')
              .fontSize(24)
              .width(48)
              .height(48)
              .fontColor($r('app.color.color_text_3'))
              .backgroundColor($r('app.color.color_fill'))
              .borderRadius(24)
              .textAlign(TextAlign.Center)
          }
          Text('更换')
            .fontSize(FontUtil.s(14, this.isElder()))
            .fontColor($r('app.color.color_cta_black'))
            .onClick(() => { this.pickAvatar(); })
        }
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')

      Divider().strokeWidth(1).color($r('app.color.color_line'))

      // 姓名行
      Row({ space: 12 }) {
        Text('姓名')
          .fontSize(FontUtil.s(15, this.isElder()))
          .fontColor($r('app.color.color_text_2'))
          .layoutWeight(1)
        Text(this.userName)
          .fontSize(FontUtil.s(15, this.isElder()))
          .fontColor($r('app.color.color_text_3'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: 160 })
        Text('编辑')
          .fontSize(FontUtil.s(14, this.isElder()))
          .fontColor($r('app.color.color_cta_black'))
          .onClick(() => {
            this.nameInput = this.userName === '未设置' ? '' : this.userName;
            this.showNameDialog = true;
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** spec 16.9：姓名编辑弹窗 */
  @Builder
  NameEditDialog() {
    Stack() {
      // 遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => { this.showNameDialog = false; })

      // 弹窗主体
      Column({ space: 16 }) {
        Text('修改姓名')
          .fontSize(FontUtil.s(17, this.isElder()))
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)

        TextInput({ text: this.nameInput })
          .width('100%')
          .height(44)
          .borderRadius(8)
          .backgroundColor($r('app.color.color_bg_page'))
          .padding({ left: 12, right: 12 })
          .fontSize(FontUtil.s(15, this.isElder()))
          .onChange((v: string) => { this.nameInput = v; })

        Row({ space: 12 }) {
          Button('取消')
            .layoutWeight(1)
            .height(40)
            .borderRadius(20)
            .backgroundColor($r('app.color.color_fill'))
            .fontColor($r('app.color.color_text_2'))
            .fontSize(FontUtil.s(14, this.isElder()))
            .onClick(() => { this.showNameDialog = false; })
          Button('保存')
            .layoutWeight(1)
            .height(40)
            .borderRadius(20)
            .backgroundColor($r('app.color.color_cta_black'))
            .fontColor(Color.White)
            .fontSize(FontUtil.s(14, this.isElder()))
            .onClick(() => { this.saveUserName(); })
        }
        .width('100%')
      }
      .width('80%')
      .padding(20)
      .borderRadius(16)
      .backgroundColor($r('app.color.color_bg_card'))
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.Center)
  }

  /** 顶部导航（圆形返回键 + 居中标题 + 占位） */
  @Builder
  TopBar() {
    Row() {
      Text('‹')
        .fontSize(FontUtil.s(20, this.isElder()))
        .fontColor($r('app.color.color_ink'))
        .width(32)
        .height(32)
        .borderRadius(16)
        .backgroundColor($r('app.color.color_bg_card'))
        .shadow(AppConstants.SHADOW_CARD)
        .textAlign(TextAlign.Center)
        .onClick(() => NavigationHelper.pop())
      Text('设置')
        .fontSize(FontUtil.s(19, this.isElder()))
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      // 占位（保持标题居中）
      Text('')
        .width(32)
        .height(32)
    }
    .width('100%')
    .height(44)
    .padding({ left: 16, right: 16, top: 0, bottom: 0 })
    .alignItems(VerticalAlign.Center)
  }

  /** 字号模式卡（segmented control + 提示文案，spec 16.9：全局生效） */
  @Builder
  FontSizeCard() {
    Column({ space: 8 }) {
      Row() {
        Text('字号模式')
          .fontSize(FontUtil.s(16, this.isElder()))
          .fontColor($r('app.color.color_ink_2'))
          .fontWeight(FontWeight.Medium)
        Blank()
        // 胶囊分段选项组
        Row({ space: 0 }) {
          ForEach(this.fontSizeOptions, (opt: FontSizeOption) => {
            Text(opt.label)
              .fontSize(FontUtil.s(13, this.isElder()))
              .fontColor(this.modeRef.value === opt.value ? $r('app.color.color_ink') : $r('app.color.color_text_3'))
              .backgroundColor(this.modeRef.value === opt.value ? $r('app.color.color_yellow') : Color.Transparent)
              .fontWeight(this.modeRef.value === opt.value ? FontWeight.Bold : FontWeight.Medium)
              .padding({ left: 12, right: 12, top: 5, bottom: 5 })
              .borderRadius(AppConstants.RADIUS_PILL)
              .onClick(() => { this.onModeChange(opt.value); })
          }, (opt: FontSizeOption) => opt.value)
        }
        .padding(2)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor($r('app.color.color_fill'))
      }
      .width('100%')
      .height(48)
      .alignItems(VerticalAlign.Center)
      // 提示文案
      Text('老年大字模式仅卖家端生效，字体全局放大')
        .fontSize(FontUtil.s(12, this.isElder()))
        .fontColor($r('app.color.color_text_3'))
        .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 0, bottom: 14 })
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 其他设置卡（清除缓存 / 意见反馈 / 关于我们） */
  @Builder
  OtherSettingsCard() {
    Column({ space: 0 }) {
      ForEach(this.otherItems, (item: SettingItem, idx: number) => {
        this.SettingRow(item)
        if (idx < this.otherItems.length - 1) {
          Divider()
            .strokeWidth(1)
            .color($r('app.color.color_line'))
        }
      }, (item: SettingItem) => item.label)
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 单个设置行 */
  @Builder
  SettingRow(item: SettingItem) {
    Row({ space: 12 }) {
      // 彩色图标
      Text(item.icon)
        .fontSize(FontUtil.s(20, this.isElder()))
        .width(40)
        .height(40)
        .borderRadius(AppConstants.RADIUS_SM)
        .backgroundColor(this.toneBg(item.tone))
        .fontColor(this.toneFg(item.tone))
        .textAlign(TextAlign.Center)
      // 标题
      Text(item.label)
        .fontSize(FontUtil.s(16, this.isElder()))
        .fontColor($r('app.color.color_ink_2'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
      // 右侧值
      if (item.value.length > 0) {
        Text(item.value)
          .fontSize(FontUtil.s(13, this.isElder()))
          .fontColor($r('app.color.color_text_3'))
      }
      // 箭头
      if (item.showArrow) {
        Text('›')
          .fontSize(FontUtil.s(22, this.isElder()))
          .fontColor($r('app.color.color_text_4'))
      }
    }
    .width('100%')
    .height(60)
    .alignItems(VerticalAlign.Center)
    .onClick(() => this.onOtherItemTap(item.action))
  }

  /** 退出登录按钮 */
  @Builder
  LogoutButton() {
    Row() {
      Text('退出登录')
        .fontSize(FontUtil.s(17, this.isElder()))
        .fontColor($r('app.color.color_live'))
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .height(52)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .onClick(() => this.logout())
  }

  /** 退出登录确认弹窗（spec 10.16：方案 C 自建模态） */
  @Builder
  LogoutConfirmDialog() {
    Stack({ alignContent: Alignment.Center }) {
      // 遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(26,26,26,0.45)')
        .onClick(() => { this.showLogoutDialog = false; })

      // 对话框内容
      Column({ space: 8 }) {
        // 标题
        Text('确认退出登录？')
          .fontSize(FontUtil.s(18, this.isElder()))
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        // 描述
        Text('退出后需要重新登录才能继续使用智农智农服务，是否确认退出当前账号？')
          .fontSize(FontUtil.s(14, this.isElder()))
          .fontColor($r('app.color.color_text_3'))
          .lineHeight(20)
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ bottom: 12 })
        // 操作按钮
        Row({ space: 12 }) {
          // 取消
          Button('取消')
            .layoutWeight(1)
            .height(46)
            .borderRadius(AppConstants.RADIUS_MD)
            .backgroundColor($r('app.color.color_bg_card'))
            .fontColor($r('app.color.color_text_2'))
            .fontSize(FontUtil.s(16, this.isElder()))
            .fontWeight(FontWeight.Bold)
            .border({ width: 1, color: $r('app.color.color_line_2') })
            .onClick(() => { this.showLogoutDialog = false; })
          // 确定
          Button('确定')
            .layoutWeight(1)
            .height(46)
            .borderRadius(AppConstants.RADIUS_MD)
            .backgroundColor($r('app.color.color_live'))
            .fontColor(Color.White)
            .fontSize(FontUtil.s(16, this.isElder()))
            .fontWeight(FontWeight.Bold)
            .onClick(() => { this.doLogout(); })
        }
        .width('100%')
      }
      .width('calc(100% - 64px)')
      .padding(24)
      .borderRadius(AppConstants.RADIUS_LG)
      .backgroundColor($r('app.color.color_bg_card'))
      .shadow(AppConstants.SHADOW_FLOAT)
    }
    .width('100%')
    .height('100%')
  }
}
