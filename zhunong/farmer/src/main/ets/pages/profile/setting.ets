/**
 * setting - 设置页（spec 3.2.4.5）
 *
 * 同用户端设置（主题/字号/退出登录）
 * - 主题切换：跟随系统 / 浅色 / 深色
 * - 字号切换：标准 / 老年大字（仅卖家端生效，spec 3.2.3.2）
 * - 清除缓存
 * - 退出登录
 */

import { Logger, AppConstants, ToastUtil, ModeStore, ThemeStore, TokenStore, FarmerRoutes, NavigationHelper, RouteName } from 'common';
import type { CurrentModeKey, CurrentThemeKey } from 'common';

/** 主题选项 */
interface ThemeOption {
  value: string;
  label: string;
}

/** 字号选项 */
interface FontSizeOption {
  value: string;
  label: string;
}

/** 设置项 */
interface SettingItem {
  label: string;
  desc: string;
  icon: string;
  action: 'theme' | 'fontSize' | 'clearCache' | 'about' | 'feedback' | 'logout';
}

@ComponentV2
export struct Setting {
  /** 当前主题 — spec 10.18：@Local themeRef 持有 AppStorageV2 共享 ref，@Trace value 变更自动刷新 */
  @Local themeRef: CurrentThemeKey = ThemeStore.connectThemeRef();
  /** 当前模式（标准 / 老年大字）— spec 10.18：@Local modeRef 持有 AppStorageV2 共享 ref */
  @Local modeRef: CurrentModeKey = ModeStore.connectModeRef();
  /** 当前版本号 */
  @Local readonly version: string = 'v1.0.0';
  /** 缓存大小 */
  @Local cacheSize: string = '12.3 MB';

  /** 主题选项 */
  private themeOptions: ThemeOption[] = [
    { value: 'system', label: '跟随系统' },
    { value: 'light', label: '浅色' },
    { value: 'dark', label: '深色' }
  ];

  /** 字号选项 */
  private fontSizeOptions: FontSizeOption[] = [
    { value: AppConstants.MODE_STANDARD, label: '标准' },
    { value: AppConstants.MODE_ELDER, label: '老年大字' }
  ];

  /** 退出登录确认弹窗显示状态（spec 10.16：方案 C 自建模态，替代 V1 CustomDialogController） */
  @Local showLogoutDialog: boolean = false;

  async aboutToAppear(): Promise<void> {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'setting_appear' });
    // spec 10.18：modeRef 通过 connectModeRef() 持有共享实例，无需手动 getMode
  }

  /** 切换主题 */
  private async onThemeChange(theme: string): Promise<void> {
    this.themeRef.value = theme;
    Logger.info(AppConstants.SCENE_FARMER, { action: 'theme_change', theme });
    ToastUtil.success('主题已切换');
  }

  /** 切换字号模式 */
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
    this.cacheSize = '0 MB';
    ToastUtil.success('缓存已清除');
    Logger.info(AppConstants.SCENE_FARMER, { action: 'clear_cache' });
  }

  /** 退出登录：打开确认弹窗（spec 10.16：方案 C 自建模态 @Local show 控制） */
  private logout(): void {
    this.showLogoutDialog = true;
  }

  /** 执行退出登录（方案 C 自建模态确认回调） */
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

  build() {
    NavDestination() {
      Stack() {
        Column() {
          this.TopBar()
          Scroll() {
            Column({ space: 16 }) {
              this.ThemeSection()
              this.FontSizeSection()
              this.OtherSection()
              this.AboutSection()
              this.LogoutButton()
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 24 })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.color_bg_page'))

        // 退出登录确认弹窗（spec 10.16：方案 C 自建模态）
        if (this.showLogoutDialog) {
          this.LogoutConfirmDialog()
        }
      }
      .width('100%')
      .height('100%')
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
      Text('设置')
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

  /** 主题设置 */
  @Builder
  ThemeSection() {
    Column({ space: 12 }) {
      Text('主题')
        .fontSize(14)
        .fontColor($r('app.color.color_text_secondary'))
        .alignSelf(ItemAlign.Start)
      Row() {
        ForEach(this.themeOptions, (opt: ThemeOption) => {
          Text(opt.label)
            .fontSize(13)
            .fontColor(this.themeRef.value === opt.value ? Color.White : $r('app.color.color_text_primary'))
            .backgroundColor(this.themeRef.value === opt.value ? $r('app.color.color_primary') : $r('app.color.color_bg_page'))
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .borderRadius(16)
            .margin({ right: 8 })
            .onClick(() => { this.onThemeChange(opt.value); })
        }, (opt: ThemeOption) => opt.value)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 字号模式设置 */
  @Builder
  FontSizeSection() {
    Column({ space: 12 }) {
      Text('字号模式（仅卖家端生效）')
        .fontSize(14)
        .fontColor($r('app.color.color_text_secondary'))
        .alignSelf(ItemAlign.Start)
      Row() {
        ForEach(this.fontSizeOptions, (opt: FontSizeOption) => {
          Text(opt.label)
            .fontSize(13)
            .fontColor(this.modeRef.value === opt.value ? Color.White : $r('app.color.color_text_primary'))
            .backgroundColor(this.modeRef.value === opt.value ? $r('app.color.color_secondary') : $r('app.color.color_bg_page'))
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .borderRadius(16)
            .margin({ right: 8 })
            .onClick(() => { this.onModeChange(opt.value); })
        }, (opt: FontSizeOption) => opt.value)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 其他设置项 */
  @Builder
  OtherSection() {
    Column({ space: 0 }) {
      this.SettingRow('🧹', '清除缓存', this.cacheSize, () => this.clearCache())
      Divider().strokeWidth(0.5).color($r('app.color.color_divider')).margin({ left: 56 })
      this.SettingRow('💬', '意见反馈', '', () => {
        ToastUtil.info('意见反馈功能开发中');
      })
      Divider().strokeWidth(0.5).color($r('app.color.color_divider')).margin({ left: 56 })
      this.SettingRow('ℹ️', '关于我们', this.version, () => {
        ToastUtil.info('助农卖家 v1.0.0');
      })
    }
    .width('100%')
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 设置项 */
  @Builder
  SettingRow(icon: string, label: string, value: string, action: () => void) {
    Row({ space: 12 }) {
      Text(icon)
        .fontSize(20)
        .width(32)
        .height(32)
        .borderRadius(16)
        .backgroundColor($r('app.color.color_bg_page'))
        .textAlign(TextAlign.Center)
      Text(label)
        .fontSize(14)
        .fontColor($r('app.color.color_text_primary'))
        .layoutWeight(1)
      if (value.length > 0) {
        Text(value)
          .fontSize(12)
          .fontColor($r('app.color.color_text_hint'))
      }
      Text('›')
        .fontSize(20)
        .fontColor($r('app.color.color_text_hint'))
    }
    .width('100%')
    .padding({ left: 12, right: 16, top: 12, bottom: 12 })
    .onClick(() => action())
  }

  /** 关于信息 */
  @Builder
  AboutSection() {
    Column({ space: 4 }) {
      Text('助农卖家')
        .fontSize(13)
        .fontColor($r('app.color.color_text_secondary'))
      Text(this.version)
        .fontSize(11)
        .fontColor($r('app.color.color_text_hint'))
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .alignItems(HorizontalAlign.Center)
  }

  /** 退出登录按钮 */
  @Builder
  LogoutButton() {
    Button('退出登录')
      .width('100%')
      .height(48)
      .borderRadius(24)
      .backgroundColor($r('app.color.color_bg_card'))
      .fontColor($r('app.color.color_error'))
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
      .onClick(() => this.logout())
  }

  /** 退出登录确认弹窗（spec 10.16：方案 C 自建模态，视觉对齐 admin/api_key.ets RevokeConfirmDialog） */
  @Builder
  LogoutConfirmDialog() {
    Stack({ alignContent: Alignment.Center }) {
      // 遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => { this.showLogoutDialog = false; })

      // 对话框内容
      Column({ space: 12 }) {
        Text('退出登录')
          .fontSize(16)
          .fontColor($r('app.color.color_error'))
          .fontWeight(FontWeight.Medium)
        Text('确定要退出当前账号吗？')
          .fontSize(12)
          .fontColor($r('app.color.color_text_secondary'))
          .width('100%')
          .textAlign(TextAlign.Center)
        Row({ space: 8 }) {
          Button('取消')
            .layoutWeight(1)
            .height(40)
            .borderRadius(20)
            .backgroundColor($r('app.color.color_bg_page'))
            .fontColor($r('app.color.color_text_primary'))
            .fontSize(14)
            .onClick(() => { this.showLogoutDialog = false; })
          Button('确定')
            .layoutWeight(1)
            .height(40)
            .borderRadius(20)
            .backgroundColor($r('app.color.color_error'))
            .fontColor(Color.White)
            .fontSize(14)
            .onClick(() => { this.doLogout(); })
        }
        .width('100%')
      }
      .width('80%')
      .padding(20)
      .borderRadius(12)
      .backgroundColor($r('app.color.color_bg_card'))
    }
    .width('100%')
    .height('100%')
  }
}
