/**
 * setting - 设置页
 * 遵循 spec 3.1.3.5：账号设置/消息通知/主题模式/字号模式/关于我们/退出登录
 */

import { TokenStore, ModeStore, ThemeStore, Logger, AppConstants, ToastUtil, UserRoutes, RouteName, NavigationHelper } from 'common';
import type { CurrentModeKey, CurrentThemeKey } from 'common';

/** 设置项数据结构 */
interface SettingItem {
  label: string;
  valueText: string;
  hasArrow: boolean;
}

@ComponentV2
export struct Setting {
  /** 当前模式（标准/老年大字）— spec 10.18：@Local modeRef 持有 AppStorageV2 共享 ref，@Trace value 变更自动刷新 */
  @Local modeRef: CurrentModeKey = ModeStore.connectModeRef();
  /** 当前主题 — spec 10.18：@Local themeRef 持有 AppStorageV2 共享 ref */
  @Local themeRef: CurrentThemeKey = ThemeStore.connectThemeRef();

  async aboutToAppear(): Promise<void> {
    // spec 10.18：modeRef/themeRef 通过 connectXxxRef() 持有共享实例，无需手动 getMode/getTheme
  }

  /** 切换字号模式（标准 ↔ 老年大字）spec 10.18：setMode 已通过共享 ref 自动同步，无需手动赋值 */
  private async toggleMode(): Promise<void> {
    const prev: string = this.modeRef.value;
    await ModeStore.toggleMode();
    Logger.info(AppConstants.SCENE_USER, { action: 'mode_toggle', from: prev, to: this.modeRef.value });
    ToastUtil.success(this.modeRef.value === AppConstants.MODE_ELDER ? '已切换老年大字模式' : '已切换标准模式');
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
        // 顶部栏
        Row() {
          Text('‹').fontSize(28).fontColor($r('app.color.color_text_primary')).onClick(() => { NavigationHelper.pop(); })
          Text('设置').fontSize(18).fontColor($r('app.color.color_text_primary')).fontWeight(FontWeight.Medium).layoutWeight(1).textAlign(TextAlign.Center)
          Text('').width(28)
        }
        .width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor($r('app.color.color_bg_card')).alignItems(VerticalAlign.Center)

        Scroll() {
          Column({ space: 12 }) {
            // 账号设置
            this.SettingGroup('账号', [
              { label: '修改密码', valueText: '', hasArrow: true },
              { label: '修改手机号', valueText: '', hasArrow: true },
              { label: '账号绑定', valueText: '', hasArrow: true }
            ])

            // 通用设置
            this.SettingGroup('通用', [
              { label: '消息通知', valueText: '已开启', hasArrow: true },
              { label: '字号模式', valueText: this.modeRef.value === AppConstants.MODE_ELDER ? '老年大字' : '标准', hasArrow: true }
            ])

            // 主题模式
            this.SettingGroup('主题', [
              { label: '深色模式', valueText: this.themeRef.value === AppConstants.THEME_DARK ? '深色' : (this.themeRef.value === AppConstants.THEME_LIGHT ? '浅色' : '跟随系统'), hasArrow: true }
            ])

            // 关于
            this.SettingGroup('关于', [
              { label: '关于我们', valueText: '', hasArrow: true },
              { label: '版本号', valueText: 'v1.0.0', hasArrow: false },
              { label: '用户协议', valueText: '', hasArrow: true },
              { label: '隐私政策', valueText: '', hasArrow: true }
            ])

            // 快捷切换：字号模式
            Column({ space: 8 }) {
              Text('字号模式快捷切换').fontSize(13).fontColor($r('app.color.color_text_secondary')).alignSelf(ItemAlign.Start)
              Row() {
                Text(this.modeRef.value === AppConstants.MODE_STANDARD ? '✓ 标准模式' : '标准模式')
                  .fontSize(13).fontColor(this.modeRef.value === AppConstants.MODE_STANDARD ? $r('app.color.color_primary') : $r('app.color.color_text_secondary'))
                  .layoutWeight(1).textAlign(TextAlign.Center)
                  .padding({ top: 10, bottom: 10 }).backgroundColor($r('app.color.color_bg_page')).borderRadius(8)
                  .onClick(() => { if (this.modeRef.value !== AppConstants.MODE_STANDARD) { this.toggleMode(); } })
                Text('  ')
                Text(this.modeRef.value === AppConstants.MODE_ELDER ? '✓ 老年大字' : '老年大字')
                  .fontSize(13).fontColor(this.modeRef.value === AppConstants.MODE_ELDER ? $r('app.color.color_primary') : $r('app.color.color_text_secondary'))
                  .layoutWeight(1).textAlign(TextAlign.Center)
                  .padding({ top: 10, bottom: 10 }).backgroundColor($r('app.color.color_bg_page')).borderRadius(8)
                  .onClick(() => { if (this.modeRef.value !== AppConstants.MODE_ELDER) { this.toggleMode(); } })
              }.width('100%')
            }
            .width('100%').padding(16).backgroundColor($r('app.color.color_bg_card')).borderRadius(12).margin({ left: 12, right: 12 }).alignItems(HorizontalAlign.Start)

            // 退出登录
            Button('退出登录')
              .width('100%').height(48).borderRadius(24)
              .backgroundColor($r('app.color.color_bg_card')).fontColor($r('app.color.color_error')).fontSize(15)
              .margin({ top: 16 })
              .onClick(() => { this.doLogout(); })
          }
          .width('100%').padding({ left: 12, right: 12, top: 12, bottom: 24 })
        }
        .layoutWeight(1).width('100%').backgroundColor($r('app.color.color_bg_page')).scrollBar(BarState.Off)
      }
      .width('100%').height('100%').backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 设置项分组 */
  @Builder
  SettingGroup(groupTitle: string, items: SettingItem[]) {
    Column({ space: 0 }) {
      Text(groupTitle).fontSize(13).fontColor($r('app.color.color_text_secondary')).alignSelf(ItemAlign.Start).margin({ bottom: 8 })
      ForEach(items, (item: SettingItem, _i: number) => {
        Row() {
          Text(item.label).fontSize(14).fontColor($r('app.color.color_text_primary')).layoutWeight(1)
          if (item.valueText.length > 0) {
            Text(item.valueText).fontSize(13).fontColor($r('app.color.color_text_hint'))
          }
          if (item.hasArrow) {
            Text(' ›').fontSize(14).fontColor($r('app.color.color_text_hint'))
          }
        }
        .width('100%').height(52).padding({ left: 16, right: 16 }).backgroundColor($r('app.color.color_bg_card')).alignItems(VerticalAlign.Center)
        .onClick(() => { ToastUtil.show('该功能将在后续阶段实现'); })
      }, (item: SettingItem, i: number) => `${item.label}_${i}`)
    }
    .width('100%').backgroundColor($r('app.color.color_bg_card')).borderRadius(12).padding({ top: 12, bottom: 4 })
  }
}
