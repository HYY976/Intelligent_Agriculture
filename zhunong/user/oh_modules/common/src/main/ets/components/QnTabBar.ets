/**
 * QnTabBar - 底部 5 Tab 导航组件
 * 对齐设计稿 .qn-tabbar：白条高 64vp，5 列，中间黑色圆角方块 FAB 发布键
 * spec 15.4.1：13 个公共组件之一
 * 激活态：墨黑加粗文字 + 黄色图标；未激活：#999
 */

import { AppConstants } from '../constants/AppConstants';

/** 角色类型（决定 Tab 文案） */
export type QnTabBarRole = 'user' | 'farmer';

/** Tab 项数据 */
interface QnTabItem {
  /** 图标 emoji（设计稿使用 SVG，此处用 emoji 兜底，后续可替换为 Resource） */
  icon: string;
  /** 文字 */
  label: string;
  /** 红点（消息 Tab） */
  dot?: boolean;
}

@ComponentV2
export struct QnTabBar {
  /** 当前激活 Tab 索引（0-4） */
  @Param activeIndex: number = 0;
  /** 角色（决定 Tab 文案） */
  @Param role: QnTabBarRole = 'user';
  /** Tab 切换回调 */
  @Event onTabChange: (i: number) => void = () => {};
  /** 中间 FAB 发布键点击回调 */
  @Event onFabClick: () => void = () => {};

  /** 获取 Tab 配置（按角色） */
  private getTabs(): QnTabItem[] {
    if (this.role === 'farmer') {
      return [
        { icon: '🏠', label: '首页' },
        { icon: '📦', label: '商品' },
        { icon: '➕', label: '' }, // FAB 占位
        { icon: '💰', label: '收入' },
        { icon: '👤', label: '我的' }
      ];
    }
    return [
      { icon: '🏠', label: '首页' },
      { icon: '💬', label: '社区' },
      { icon: '➕', label: '' }, // FAB 占位
      { icon: '🛒', label: '购物车' },
      { icon: '👤', label: '我的' }
    ];
  }

  build() {
    Row() {
      ForEach(this.getTabs(), (tab: QnTabItem, index: number) => {
        if (index === 2) {
          // 中间 FAB 发布键（黑色圆角方块）
          Text(tab.icon || '➕')
            .fontSize(20)
            .fontColor(Color.White)
            .width(AppConstants.FAB_WIDTH)
            .height(AppConstants.FAB_HEIGHT)
            .borderRadius(AppConstants.RADIUS_MD)
            .backgroundColor($r('app.color.color_ink'))
            .shadow(AppConstants.SHADOW_FAB)
            .textAlign(TextAlign.Center)
            .margin({ top: 4 })
            .onClick(() => this.onFabClick())
        } else {
          // 普通 Tab 项
          Column({ space: 2 }) {
            Text(tab.icon)
              .fontSize(24)
              .fontColor(this.activeIndex === index ? $r('app.color.color_yellow_deep') : $r('app.color.color_text_3'))
            Text(tab.label)
              .fontSize(10)
              .fontWeight(this.activeIndex === index ? FontWeight.Bold : FontWeight.Medium)
              .fontColor(this.activeIndex === index ? $r('app.color.color_ink') : $r('app.color.color_text_3'))
          }
          .layoutWeight(1)
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => this.onTabChange(index))
        }
      }, (tab: QnTabItem, index: number) => `tab_${index}_${tab.label}`)
    }
    .width('100%')
    .height(AppConstants.TABBAR_HEIGHT)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_NAV)
    .padding({ left: 8, right: 8, bottom: 8 })
  }
}
