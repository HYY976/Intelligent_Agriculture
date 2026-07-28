/**
 * setting - 设置页
 * 遵循 spec 3.1.3.5 + 设计稿 setting.html 1:1 复刻：
 *  - 顶栏：白色圆形返回按钮 + 居中标题"设置"
 *  - 3 个设置组卡（行高 56px + 1px 分割线 + 32×32 彩色图标）：
 *    1. 账号安全：修改头像和姓名(黄) + 修改密码(黄) + 绑定手机(绿, 显示手机号)
 *    2. 通知与偏好：消息通知(红, Toggle 绿色开关) + 深色模式(蓝, 3段胶囊组)
 *    3. 通用设置：清除缓存(橙, 23.5MB) + 意见反馈(绿) + 关于我们(蓝, v1.0.0) + 隐私政策(灰)
 *  - 退出登录按钮（白底红字全宽）
 * spec 16.12：新增"修改头像和姓名"功能，通过弹窗编辑并同步 TokenStore 全端生效
 */

import { TokenStore, ThemeStore, Logger, AppConstants, ToastUtil, RouteName, NavigationHelper } from 'common';
import type { CurrentThemeKey, UserInfo } from 'common';
import { ImageUtil } from '../../utils/ImageUtil';

/** 设置项图标主题色（对齐设计稿 qn-ico-*） */
type SettingIconTheme = 'yellow' | 'green' | 'blue' | 'red' | 'orange' | 'soft';

/** 深色模式选项 */
type DarkModeOption = 'system' | 'light' | 'dark';

/** 深色模式段控配置 */
interface DarkModeSeg {
  value: DarkModeOption;
  label: string;
}

/** spec 16.12：可选头像项（key + 预览资源） */
interface AvatarOption {
  key: string;
  label: string;
}

@ComponentV2
export struct Setting {
  /** 当前主题 — spec 10.18：@Local themeRef 持有 AppStorageV2 共享 ref */
  @Local themeRef: CurrentThemeKey = ThemeStore.connectThemeRef();
  /** 消息通知开关（本地态） */
  @Local notifyOn: boolean = true;
  /** 当前选中的深色模式段控 */
  @Local darkMode: DarkModeOption = 'light';
  /** spec 16.12：当前昵称（编辑弹窗用） */
  @Local editNickname: string = '';
  /** spec 16.12：当前头像 key（编辑弹窗用） */
  @Local editAvatarKey: string = 'avatar_default';
  /** spec 16.12：是否显示编辑头像姓名弹窗 */
  @Local showProfileEditor: boolean = false;

  /** 深色模式段控配置（对齐设计稿 qn-seg） */
  private darkModeSegs: DarkModeSeg[] = [
    { value: 'system', label: '跟随系统' },
    { value: 'light', label: '浅色' },
    { value: 'dark', label: '深色' }
  ];

  /** spec 16.12：可选头像列表 */
  private avatarOptions: AvatarOption[] = [
    { key: 'avatar_default', label: '默认' },
    { key: 'avatar_farmer_1', label: '农夫1' },
    { key: 'avatar_farmer_2', label: '农夫2' },
    { key: 'avatar_farmer_3', label: '农夫3' }
  ];

  async aboutToAppear(): Promise<void> {
    // 初始化深色模式选中项
    if (this.themeRef.value === AppConstants.THEME_DARK) {
      this.darkMode = 'dark';
    } else if (this.themeRef.value === AppConstants.THEME_SYSTEM) {
      this.darkMode = 'system';
    } else {
      this.darkMode = 'light';
    }
    // spec 16.12：预加载当前用户信息到编辑态
    const userInfo: UserInfo | null = await TokenStore.getUserInfo();
    if (userInfo) {
      this.editNickname = userInfo.nickname;
      this.editAvatarKey = userInfo.avatar || 'avatar_default';
    }
  }

  /** 切换深色模式段控 */
  private async onDarkModeChange(option: DarkModeOption): Promise<void> {
    if (this.darkMode === option) {
      return;
    }
    this.darkMode = option;
    const targetTheme: string = option === 'dark' ? AppConstants.THEME_DARK : (option === 'system' ? AppConstants.THEME_SYSTEM : AppConstants.THEME_LIGHT);
    await ThemeStore.setTheme(targetTheme);
    Logger.info(AppConstants.SCENE_USER, { action: 'theme_change', from: this.themeRef.value, to: targetTheme });
  }

  /** 切换消息通知 */
  private onNotifyToggle(): void {
    this.notifyOn = !this.notifyOn;
    Logger.info(AppConstants.SCENE_USER, { action: 'notify_toggle', msg: `notifyOn=${this.notifyOn}` });
    ToastUtil.success(this.notifyOn ? '已开启消息通知' : '已关闭消息通知');
  }

  /** spec 16.12：打开修改头像和姓名弹窗 */
  private async openProfileEditor(): Promise<void> {
    const userInfo: UserInfo | null = await TokenStore.getUserInfo();
    if (userInfo) {
      this.editNickname = userInfo.nickname;
      this.editAvatarKey = userInfo.avatar || 'avatar_default';
    }
    this.showProfileEditor = true;
  }

  /** spec 16.12：保存头像和姓名 → 持久化到 TokenStore，全端同步 */
  private async saveProfile(): Promise<void> {
    const trimmedName: string = this.editNickname.trim();
    if (trimmedName.length === 0) {
      ToastUtil.error('昵称不能为空');
      return;
    }
    const userInfo: UserInfo | null = await TokenStore.getUserInfo();
    if (!userInfo) {
      ToastUtil.error('请先登录');
      return;
    }
    const updated: UserInfo = {
      userId: userInfo.userId,
      phone: userInfo.phone,
      nickname: trimmedName,
      avatar: this.editAvatarKey,
      userType: userInfo.userType,
      status: userInfo.status,
      createdAt: userInfo.createdAt,
      lastLoginAt: userInfo.lastLoginAt
    };
    await TokenStore.setUserInfo(updated);
    this.showProfileEditor = false;
    ToastUtil.success('已保存，全端同步生效');
    Logger.info(AppConstants.SCENE_USER, { action: 'profile_updated', nickname: trimmedName, avatar: this.editAvatarKey });
  }

  /** 退出登录 */
  private async doLogout(): Promise<void> {
    await TokenStore.clearAuth();
    Logger.info(AppConstants.SCENE_USER, { action: 'logout' });
    ToastUtil.success('已退出登录');
    NavigationHelper.replace(RouteName.USER_LOGIN);
  }

  build() {
    NavDestination() {
      Column() {
        // ===== 顶部导航栏（对齐设计稿 qn-topbar） =====
        Row() {
          // 白色圆形返回按钮
          Row() {
            Text('‹').fontSize(22).fontColor($r('app.color.color_ink')).fontWeight(FontWeight.Bold)
          }
          .width(32)
          .height(32)
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_bg_card'))
          .shadow(AppConstants.SHADOW_CARD)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .onClick(() => { NavigationHelper.pop(); })

          // 居中标题
          Text('设置')
            .fontSize(17)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          // 右侧占位
          Row().width(32).height(32)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 4, bottom: 10 })
        .alignItems(VerticalAlign.Center)

        // ===== 内容区（对齐设计稿 qn-setting-body） =====
        Scroll() {
          Column({ space: 12 }) {
            // 1. 账号安全卡（对齐设计稿 第1组 qn-list-card；spec 16.12：增加修改头像和姓名）
            this.AccountCard()

            // 2. 通知与偏好卡（对齐设计稿 第2组）
            this.NotifyCard()

            // 3. 通用设置卡（对齐设计稿 第3组）
            this.GeneralCard()

            // 4. 退出登录按钮（对齐设计稿 qn-logout）
            Text('退出登录')
              .fontSize(16)
              .fontColor($r('app.color.color_live'))
              .fontWeight(FontWeight.Bold)
              .width('100%')
              .height(48)
              .textAlign(TextAlign.Center)
              .backgroundColor($r('app.color.color_bg_card'))
              .borderRadius(AppConstants.RADIUS_LG)
              .shadow(AppConstants.SHADOW_CARD)
              .margin({ top: 4 })
              .onClick(() => { this.doLogout(); })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 24 })
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor($r('app.color.color_bg_page'))
        .scrollBar(BarState.Off)

        // spec 16.12：修改头像和姓名弹窗
        if (this.showProfileEditor) {
          this.ProfileEditorDialog()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 账号安全卡（对齐设计稿 第1组；spec 16.12：增加"修改头像和姓名"行） */
  @Builder
  AccountCard() {
    Column({ space: 0 }) {
      // 修改头像和姓名（黄色图标，spec 16.12 新增）
      this.SettingRow('yellow', '👤', '修改头像和姓名', '', true, () => {
        this.openProfileEditor();
      })
      this.RowDivider()
      // 修改密码（黄色图标）
      this.SettingRow('yellow', '🔒', '修改密码', '', true, () => {
        ToastUtil.info('修改密码功能开发中');
      })
      this.RowDivider()
      // 绑定手机（绿色图标 + 手机号）
      this.SettingRow('green', '📱', '绑定手机', '138****8888', true, () => {
        ToastUtil.info('绑定手机功能开发中');
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** spec 16.12：修改头像和姓名弹窗 */
  @Builder
  ProfileEditorDialog() {
    Stack() {
      // 遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.85)')
        .onClick(() => { this.showProfileEditor = false; })

      // 弹窗主体
      Column({ space: 16 }) {
        // 顶部标题 + 关闭按钮
        Row() {
          Text('修改头像和姓名')
            .fontSize(18)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
          Text('×')
            .fontSize(28)
            .fontColor($r('app.color.color_text_3'))
            .width(40)
            .height(40)
            .textAlign(TextAlign.Center)
            .onClick(() => { this.showProfileEditor = false; })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 当前头像预览
        Column({ space: 8 }) {
          Text('当前头像')
            .fontSize(13)
            .fontColor($r('app.color.color_text_2'))
            .alignSelf(ItemAlign.Start)
          Image(ImageUtil.get(this.editAvatarKey))
            .width(80)
            .height(80)
            .borderRadius(40)
            .objectFit(ImageFit.Cover)
            .backgroundColor($r('app.color.color_fill'))
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)

        // 头像选择列表
        Column({ space: 8 }) {
          Text('选择新头像')
            .fontSize(13)
            .fontColor($r('app.color.color_text_2'))
            .alignSelf(ItemAlign.Start)
          Row({ space: 12 }) {
            ForEach(this.avatarOptions, (opt: AvatarOption) => {
              Stack() {
                Image(ImageUtil.get(opt.key))
                  .width(56)
                  .height(56)
                  .borderRadius(28)
                  .objectFit(ImageFit.Cover)
                  .backgroundColor($r('app.color.color_fill'))
                if (this.editAvatarKey === opt.key) {
                  // 选中标识：黄色环
                  Column()
                    .width(60)
                    .height(60)
                    .borderRadius(30)
                    .border({ width: 3, color: $r('app.color.color_yellow') })
                }
              }
              .width(60)
              .height(60)
              .onClick(() => { this.editAvatarKey = opt.key; })
            }, (opt: AvatarOption) => opt.key)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')

        // 昵称输入
        Column({ space: 8 }) {
          Text('昵称')
            .fontSize(13)
            .fontColor($r('app.color.color_text_2'))
            .alignSelf(ItemAlign.Start)
          TextInput({ text: this.editNickname, placeholder: '请输入新昵称' })
            .height(44)
            .borderRadius(8)
            .backgroundColor($r('app.color.color_bg_page'))
            .padding({ left: 12, right: 12 })
            .fontSize(15)
            .maxLength(20)
            .onChange((v: string) => { this.editNickname = v; })
        }
        .width('100%')

        // 保存按钮
        Button('保存')
          .width('100%')
          .height(44)
          .borderRadius(8)
          .backgroundColor($r('app.color.color_yellow_deep'))
          .fontColor(Color.White)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .onClick(() => { this.saveProfile(); })
      }
      .width('88%')
      .padding(20)
      .borderRadius(16)
      .backgroundColor($r('app.color.color_bg_card'))
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.Center)
  }

  /** 通知与偏好卡（对齐设计稿 第2组） */
  @Builder
  NotifyCard() {
    Column({ space: 0 }) {
      // 消息通知（红色图标 + Toggle 开关）
      Row() {
        Row({ space: 12 }) {
          this.IconBox('red', '🔔')
          Text('消息通知')
            .fontSize(15)
            .fontColor($r('app.color.color_ink_2'))
            .fontWeight(FontWeight.Medium)
        }
        .alignItems(VerticalAlign.Center)

        Blank()

        // Toggle 开关（44×24，对齐设计稿 qn-toggle）
        Stack({ alignContent: this.notifyOn ? Alignment.End : Alignment.Start }) {
          Column()
            .width(20)
            .height(20)
            .borderRadius(10)
            .backgroundColor(Color.White)
            .shadow({ radius: 3, color: 'rgba(0,0,0,0.15)', offsetX: 0, offsetY: 1 })
            .margin(2)
        }
        .width(44)
        .height(24)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor(this.notifyOn ? $r('app.color.color_green') : '#E0E0E0')
        .onClick(() => { this.onNotifyToggle(); })
      }
      .width('100%')
      .height(56)
      .alignItems(VerticalAlign.Center)

      this.RowDivider()

      // 深色模式（蓝色图标 + 3 段胶囊组）
      Row() {
        Row({ space: 12 }) {
          this.IconBox('blue', '🌙')
          Text('深色模式')
            .fontSize(15)
            .fontColor($r('app.color.color_ink_2'))
            .fontWeight(FontWeight.Medium)
        }
        .alignItems(VerticalAlign.Center)

        Blank()

        // 3 段胶囊组（对齐设计稿 qn-seg）
        Row({ space: 0 }) {
          ForEach(this.darkModeSegs, (seg: DarkModeSeg) => {
            Text(seg.label)
              .fontSize(12)
              .fontColor(this.darkMode === seg.value ? $r('app.color.color_ink') : $r('app.color.color_text_3'))
              .fontWeight(this.darkMode === seg.value ? FontWeight.Bold : FontWeight.Medium)
              .padding({ left: 12, right: 12, top: 5, bottom: 5 })
              .borderRadius(AppConstants.RADIUS_PILL)
              .backgroundColor(this.darkMode === seg.value ? $r('app.color.color_yellow') : Color.Transparent)
              .onClick(() => { this.onDarkModeChange(seg.value); })
          }, (seg: DarkModeSeg) => seg.value)
        }
        .padding(2)
        .backgroundColor($r('app.color.color_fill'))
        .borderRadius(AppConstants.RADIUS_PILL)
      }
      .width('100%')
      .height(56)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 通用设置卡（对齐设计稿 第3组） */
  @Builder
  GeneralCard() {
    Column({ space: 0 }) {
      // 清除缓存（橙色图标 + 23.5MB）
      this.SettingRow('orange', '🗑️', '清除缓存', '23.5MB', true, () => {
        ToastUtil.success('缓存已清除');
      })
      this.RowDivider()
      // 意见反馈（绿色图标）
      this.SettingRow('green', '💬', '意见反馈', '', true, () => {
        ToastUtil.info('意见反馈功能开发中');
      })
      this.RowDivider()
      // 关于我们（蓝色图标 + v1.0.0）
      this.SettingRow('blue', 'ℹ️', '关于我们', 'v1.0.0', true, () => {
        ToastUtil.info('趣农 v1.0.0 助农电商平台');
      })
      this.RowDivider()
      // 隐私政策（灰色图标）
      this.SettingRow('soft', '🛡️', '隐私政策', '', true, () => {
        ToastUtil.info('隐私政策页面开发中');
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 通用设置行（对齐设计稿 qn-set-row，56px 高） */
  @Builder
  SettingRow(theme: SettingIconTheme, icon: string, label: string, value: string, hasArrow: boolean, action: () => void) {
    Row() {
      // 左侧：图标 + 文本
      Row({ space: 12 }) {
        this.IconBox(theme, icon)
        Text(label)
          .fontSize(15)
          .fontColor($r('app.color.color_ink_2'))
          .fontWeight(FontWeight.Medium)
      }
      .alignItems(VerticalAlign.Center)

      Blank()

      // 右侧：值 + 箭头
      Row({ space: 6 }) {
        if (value.length > 0) {
          Text(value)
            .fontSize(13)
            .fontColor($r('app.color.color_text_3'))
        }
        if (hasArrow) {
          Text('›')
            .fontSize(20)
            .fontColor($r('app.color.color_text_4'))
        }
      }
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(56)
    .alignItems(VerticalAlign.Center)
    .onClick(() => { action(); })
  }

  /** 彩色图标底（对齐设计稿 qn-set-ico，32×32 + radius 10） */
  @Builder
  IconBox(theme: SettingIconTheme, icon: string) {
    Row() {
      Text(icon).fontSize(18)
    }
    .width(32)
    .height(32)
    .borderRadius(AppConstants.RADIUS_SM)
    .backgroundColor(this.getIconBgColor(theme))
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
  }

  /** 行间分割线（对齐设计稿 qn-divider） */
  @Builder
  RowDivider() {
    Divider()
      .color($r('app.color.color_line'))
      .strokeWidth(1)
  }

  /** 获取图标底色（对齐设计稿 qn-ico-*） */
  private getIconBgColor(theme: SettingIconTheme): ResourceColor {
    switch (theme) {
      case 'yellow': return $r('app.color.color_yellow_soft');
      case 'green': return $r('app.color.color_green_soft');
      case 'blue': return $r('app.color.color_info_soft');
      case 'red': return $r('app.color.color_live_soft');
      case 'orange': return $r('app.color.color_warn_soft');
      case 'soft': return $r('app.color.color_fill');
      default: return $r('app.color.color_fill');
    }
  }
}
