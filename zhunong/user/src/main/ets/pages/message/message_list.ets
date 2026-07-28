/**
 * message_list - 消息列表页（Tab 内嵌 + 独立路由双用）
 * 遵循 spec 3.1.3.3 + 设计稿 message.html 1:1 复刻：
 *  - 顶栏：白色圆形返回按钮(route模式) / 标题(Tab模式) + 居中标题 + "全部已读"胶囊按钮
 *  - 快捷入口 4 圆形图标（订单消息/物流通知/直播提醒/系统公告）+ 红色角标
 *  - 5 Tab 切换栏（全部/系统/订单/互动/客服）+ 黄色下划线
 *  - 消息列表（白卡分组）：彩色圆形图标 + 分类标签 + 标题 + 未读红点 + 预览 + 时间
 *  - 长按弹出操作菜单（置顶/删除）
 *  - 4 态状态机：loading / error / empty / list
 *
 * spec 10.11.4 Step 2：ForEach → LazyForEach + keyGenerator + cachedCount
 * 导出 MessageContent 供 home_page Tab 内嵌使用，同时作为独立路由 pages/message/message_list
 */

import { Logger, AppConstants, ToastUtil, RouteName, NavigationHelper, ListStateView } from 'common';
import { ChatSession, MessageFilterTab, MessageTagTheme } from '../../model/MessageModels';
import { toggleMockSessionPinned, deleteMockSession, markAllSessionsRead, MOCK_QUICK_ENTRIES, QuickEntry } from '../../mock/MessageMock';
import { MessageListDataSource } from '../../viewmodel/MessageListDataSource';
import { ImageUtil } from '../../utils/ImageUtil';
import { WsClient } from '../../utils/WsClient';

/** 跳转聊天详情的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface ChatDetailParam {
  sessionId: string;
}

/** 筛选 Tab 配置项（对齐设计稿 qn-msg-tab 5 项） */
interface FilterTabItem {
  key: MessageFilterTab;
  label: string;
}

/** 筛选 Tab 列表（对齐设计稿 message.html: 全部/系统/订单/互动/客服） */
const FILTER_TABS: FilterTabItem[] = [
  { key: 'all', label: '全部' },
  { key: 'system', label: '系统' },
  { key: 'order', label: '订单' },
  { key: 'interact', label: '互动' },
  { key: 'service', label: '客服' }
];

/** 消息内容组件（可复用于 Tab 与独立页） */
@ComponentV2
export struct MessageContent {
  /** 是否显示返回按钮（route 模式 true / Tab 模式 false） */
  @Param showBack: boolean = false;
  /** 当前筛选 Tab */
  @Local currentFilter: MessageFilterTab = 'all';
  /** 列表是否为空（驱动空状态切换） */
  @Local isEmpty: boolean = true;
  /** 会话列表数据源（spec 10.11.4：LazyForEach 替代 ForEach） */
  private dataSource: MessageListDataSource = new MessageListDataSource();
  /** 长按操作菜单是否显示 */
  @Local showActionSheet: boolean = false;
  /** 长按选中的会话 */
  @Local actionSession: ChatSession | null = null;

  async aboutToAppear(): Promise<void> {
    await this.refreshSessions();
    // 触发 WebSocket 长连接（spec 10.3：消息 Tab 进入时确保 WsClient 已连接）
    WsClient.connect();
    Logger.info(AppConstants.SCENE_USER, { action: 'message_list_appear', total: this.dataSource.totalCount() });
  }

  /** 重新加载会话列表（spec 10.11.4：异步 refresh + 空状态同步） */
  private async refreshSessions(): Promise<void> {
    this.dataSource.setFilter(this.currentFilter);
    await this.dataSource.refresh();
    this.isEmpty = this.dataSource.totalCount() === 0;
  }

  /** 切换筛选 Tab */
  private async onFilterChange(tab: MessageFilterTab): Promise<void> {
    if (this.currentFilter === tab) {
      return;
    }
    this.currentFilter = tab;
    await this.refreshSessions();
    Logger.info(AppConstants.SCENE_USER, { action: 'message_filter_change', filter: tab });
  }

  /** 点击快捷入口切换到对应分类 Tab */
  private async onQuickEntryClick(entry: QuickEntry): Promise<void> {
    // 映射快捷入口分类到筛选 Tab
    let targetTab: MessageFilterTab = 'all';
    if (entry.category === 'order' || entry.category === 'logistics') {
      targetTab = 'order';
    } else if (entry.category === 'live' || entry.category === 'coupon' || entry.category === 'interact') {
      targetTab = 'interact';
    } else if (entry.category === 'system') {
      targetTab = 'system';
    } else if (entry.category === 'service') {
      targetTab = 'service';
    }
    await this.onFilterChange(targetTab);
    Logger.info(AppConstants.SCENE_USER, { action: 'message_quick_entry', category: entry.category, filter: targetTab });
  }

  /** 全部已读 */
  private async onMarkAllRead(): Promise<void> {
    markAllSessionsRead();
    ToastUtil.success('全部已标为已读');
    await this.refreshSessions();
    Logger.info(AppConstants.SCENE_USER, { action: 'message_mark_all_read' });
  }

  /** 点击会话进入详情（hasChat=true 才跳转） */
  private onSessionClick(session: ChatSession): void {
    if (session.hasChat) {
      const param: ChatDetailParam = { sessionId: session.sessionId };
      NavigationHelper.push(RouteName.USER_CHAT_DETAIL, param);
    } else {
      // 通知类消息，提示用户
      ToastUtil.info('暂无聊天记录');
    }
    Logger.info(AppConstants.SCENE_USER, { action: 'message_item_click', sessionId: session.sessionId, hasChat: session.hasChat });
  }

  /** 长按会话弹出操作菜单 */
  private onSessionLongPress(session: ChatSession): void {
    this.actionSession = session;
    this.showActionSheet = true;
  }

  /** 切换置顶 */
  private async onTogglePinned(): Promise<void> {
    if (!this.actionSession) {
      return;
    }
    const pinned: boolean = toggleMockSessionPinned(this.actionSession.sessionId);
    ToastUtil.success(pinned ? '已置顶' : '已取消置顶');
    this.showActionSheet = false;
    this.actionSession = null;
    await this.refreshSessions();
  }

  /** 删除会话 */
  private async onDeleteSession(): Promise<void> {
    if (!this.actionSession) {
      return;
    }
    const ok: boolean = deleteMockSession(this.actionSession.sessionId);
    if (ok) {
      ToastUtil.success('已删除');
    } else {
      ToastUtil.error('删除失败');
    }
    this.showActionSheet = false;
    this.actionSession = null;
    await this.refreshSessions();
  }

  /** 取消操作菜单 */
  private onCancelAction(): void {
    this.showActionSheet = false;
    this.actionSession = null;
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        // 顶部栏（对齐设计稿 qn-topbar）
        this.TopBar()
        // 快捷入口
        this.QuickGrid()
        // 筛选 Tab
        this.TabBar()
        // 会话列表（spec 10.11.4 Step 4：4 态状态机 error / loading / empty / list）
        if (this.dataSource.getLoadFailed()) {
          ListStateView({ state: 'error', onRefresh: () => this.refreshSessions() })
        } else if (this.dataSource.getIsFirstLoad()) {
          ListStateView({ state: 'loading' })
        } else if (this.dataSource.totalCount() === 0) {
          this.EmptyView()
        } else {
          this.SessionListView()
        }
      }
      .width('100%')
      .height('100%')

      // 底部操作菜单
      if (this.showActionSheet && this.actionSession) {
        this.ActionSheet()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.color_bg_page'))
  }

  /** 顶部栏（对齐设计稿 qn-topbar: 返回/标题/全部已读） */
  @Builder
  TopBar() {
    Row() {
      // 左侧：返回按钮（route 模式）或标题（Tab 模式）
      if (this.showBack) {
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
        Text('消息')
          .fontSize(17)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      } else {
        // Tab 模式：左对齐标题
        Text('消息')
          .fontSize(18)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
      }

      // 右侧：全部已读胶囊按钮（对齐设计稿 qn-msg-readall）
      Row({ space: 4 }) {
        Text('✓')
          .fontSize(12)
          .fontColor($r('app.color.color_green_deep'))
          .fontWeight(FontWeight.Bold)
        Text('全部已读')
          .fontSize(12)
          .fontColor($r('app.color.color_text_2'))
          .fontWeight(FontWeight.Bold)
      }
      .height(30)
      .padding({ left: 12, right: 12 })
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor($r('app.color.color_bg_card'))
      .shadow(AppConstants.SHADOW_CARD)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { this.onMarkAllRead(); })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 10 })
    .alignItems(VerticalAlign.Center)
  }

  /** 快捷入口 4 圆形图标（对齐设计稿 qn-quick-grid） */
  @Builder
  QuickGrid() {
    Row() {
      Column({ space: 0 }) {
        Row() {
          ForEach(MOCK_QUICK_ENTRIES, (entry: QuickEntry) => {
            Column({ space: 7 }) {
              // 圆形图标 + 角标
              Stack({ alignContent: Alignment.TopEnd }) {
                Row() {
                  Text(entry.icon)
                    .fontSize(22)
                    .fontColor(this.getThemeTextColor(entry.iconTheme))
                }
                .width(48)
                .height(48)
                .borderRadius(AppConstants.RADIUS_PILL)
                .backgroundColor(this.getThemeBgColor(entry.iconTheme))
                .justifyContent(FlexAlign.Center)
                .alignItems(VerticalAlign.Center)

                // 红色角标（对齐设计稿 qn-quick-badge）
                if (entry.badge > 0) {
                  Text(entry.badge > 99 ? '99+' : `${entry.badge}`)
                    .fontSize(10)
                    .fontColor(Color.White)
                    .fontWeight(FontWeight.Bold)
                    .height(18)
                    .padding({ left: 5, right: 5 })
                    .borderRadius(AppConstants.RADIUS_PILL)
                    .backgroundColor($r('app.color.color_live'))
                    .border({ width: 2, color: $r('app.color.color_bg_card') })
                    .textAlign(TextAlign.Center)
                    .offset({ x: 5, y: -5 })
                }
              }
              .width(48)
              .height(48)

              // 标签
              Text(entry.label)
                .fontSize(11)
                .fontColor($r('app.color.color_ink_2'))
                .fontWeight(FontWeight.Medium)
            }
            .alignItems(HorizontalAlign.Center)
            .layoutWeight(1)
            .onClick(() => { this.onQuickEntryClick(entry); })
          }, (entry: QuickEntry) => entry.category)
        }
        .width('100%')
        .padding({ left: 6, right: 6, top: 6, bottom: 0 })
      }
      .width('100%')
      .backgroundColor($r('app.color.color_bg_card'))
      .borderRadius(AppConstants.RADIUS_LG)
      .shadow(AppConstants.SHADOW_CARD)
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
  }

  /** 顶部 Tab 切换栏（对齐设计稿 qn-msg-tabs 5 项 + 黄色下划线） */
  @Builder
  TabBar() {
    Scroll() {
      Row({ space: 20 }) {
        ForEach(FILTER_TABS, (tab: FilterTabItem) => {
          Column({ space: 0 }) {
            Text(tab.label)
              .fontSize(this.currentFilter === tab.key ? 15 : 14)
              .fontColor(this.currentFilter === tab.key ? $r('app.color.color_ink') : $r('app.color.color_text_3'))
              .fontWeight(this.currentFilter === tab.key ? FontWeight.Bold : FontWeight.Medium)
              .padding({ top: 4, bottom: 6 })

            // 选中下划线（对齐设计稿 qn-msg-tab.is-active::after）
            Row()
              .width(this.currentFilter === tab.key ? 22 : 0)
              .height(3)
              .borderRadius(AppConstants.RADIUS_PILL)
              .backgroundColor($r('app.color.color_yellow_deep'))
          }
          .alignItems(HorizontalAlign.Center)
          .onClick(() => { this.onFilterChange(tab.key); })
        }, (tab: FilterTabItem) => tab.key)
      }
      .padding({ left: 16, right: 16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .margin({ top: 20 })
  }

  /** 会话列表（对齐设计稿 qn-msg-card 白卡分组） */
  @Builder
  SessionListView() {
    Scroll() {
      Column() {
        // 白卡分组
        Column({ space: 0 }) {
          LazyForEach(this.dataSource, (session: ChatSession) => {
            Column() {
              this.SessionItem(session)
              // 行间分割线（对齐设计稿 qn-msg-row + .qn-msg-row）
              Divider()
                .color($r('app.color.color_line'))
                .strokeWidth(1)
            }
          }, (session: ChatSession) => session.sessionId + `_${session.unreadCount}_${session.lastMessageAt}`)
        }
        .width('100%')
        .backgroundColor($r('app.color.color_bg_card'))
        .borderRadius(AppConstants.RADIUS_LG)
        .shadow(AppConstants.SHADOW_CARD)
        .margin({ top: 0 })
        .padding({ left: 16, right: 16, top: 0 })

        // 列表底部提示（对齐设计稿 qn-msg-foot）
        Text('没有更多消息了')
          .fontSize(11)
          .fontColor($r('app.color.color_text_4'))
          .margin({ top: 8, bottom: 4 })
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 0 })
    }
    .layoutWeight(1)
    .width('100%')
    .scrollBar(BarState.Off)
  }

  /** 单个会话项（对齐设计稿 qn-msg-row） */
  @Builder
  SessionItem(session: ChatSession) {
    Row({ space: 12 }) {
      // 彩色圆形图标（对齐设计稿 qn-msg-ico 44×44）
      Row() {
        Text(session.icon)
          .fontSize(22)
          .fontColor(this.getThemeTextColor(session.iconTheme))
      }
      .width(44)
      .height(44)
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor(this.getThemeBgColor(session.iconTheme))
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      // 中间：标签 + 标题 + 预览
      Column({ space: 5 }) {
        // 顶行：标签 + 标题 + 未读红点
        Row() {
          // 分类标签（对齐设计稿 qn-msg-tag）
          Text(session.tagLabel)
            .fontSize(10)
            .fontColor(this.getThemeTextColor(session.tagTheme))
            .fontWeight(FontWeight.Bold)
            .padding({ left: 6, right: 6, top: 1, bottom: 1 })
            .borderRadius(AppConstants.RADIUS_XS)
            .backgroundColor(this.getThemeBgColor(session.tagTheme))

          // 标题
          Text(session.title)
            .fontSize(15)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
            .margin({ left: 6 })

          // 未读红点（对齐设计稿 qn-msg-dot 8×8）
          if (session.unreadCount > 0) {
            Column()
              .width(8)
              .height(8)
              .borderRadius(4)
              .backgroundColor($r('app.color.color_live'))
              .margin({ left: 4, top: 7 })
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)

        // 底行：预览 + 时间
        Row({ space: 10 }) {
          Text(session.lastMessage)
            .fontSize(13)
            .fontColor($r('app.color.color_text_3'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          Text(this.formatRelativeTime(session.lastMessageAt))
            .fontSize(11)
            .fontColor($r('app.color.color_text_3'))
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ top: 2, bottom: 13 })
    .alignItems(VerticalAlign.Top)
    .onClick(() => { this.onSessionClick(session); })
    .gesture(
      LongPressGesture({ repeat: false, duration: 500 })
        .onAction(() => { this.onSessionLongPress(session); })
    )
  }

  /** 空状态 */
  @Builder
  EmptyView() {
    Column() {
      ListStateView({
        state: 'empty',
        emptyText: '暂无消息',
        emptyDesc: '与卖家沟通、订单通知都会显示在这里'
      })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  /** 底部操作菜单（置顶 / 删除 / 取消） */
  @Builder
  ActionSheet() {
    Column() {
      // 遮罩层
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(26,26,26,0.45)')
        .onClick(() => { this.onCancelAction(); })

      // 操作菜单
      Column({ space: 0 }) {
        Text(this.actionSession ? this.actionSession.title : '')
          .fontSize(13)
          .fontColor($r('app.color.color_text_3'))
          .padding({ top: 14, bottom: 14 })

        Divider()
          .color($r('app.color.color_line'))
          .strokeWidth(1)

        Text(this.actionSession && this.actionSession.isPinned ? '取消置顶' : '置顶会话')
          .fontSize(16)
          .fontColor($r('app.color.color_ink'))
          .width('100%')
          .height(50)
          .textAlign(TextAlign.Center)
          .onClick(() => { this.onTogglePinned(); })

        Divider()
          .color($r('app.color.color_line'))
          .strokeWidth(1)

        Text('删除会话')
          .fontSize(16)
          .fontColor($r('app.color.color_live'))
          .width('100%')
          .height(50)
          .textAlign(TextAlign.Center)
          .onClick(() => { this.onDeleteSession(); })

        Divider()
          .color($r('app.color.color_bg_page'))
          .strokeWidth(6)

        Text('取消')
          .fontSize(16)
          .fontColor($r('app.color.color_ink'))
          .width('100%')
          .height(50)
          .textAlign(TextAlign.Center)
          .onClick(() => { this.onCancelAction(); })
      }
      .width('100%')
      .backgroundColor($r('app.color.color_bg_card'))
      .borderRadius({ topLeft: AppConstants.RADIUS_XL, topRight: AppConstants.RADIUS_XL })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.End)
  }

  /** 获取主题背景色（对齐设计稿 qn-msg-ico.c-* / qn-msg-tag.t-*） */
  private getThemeBgColor(theme: MessageTagTheme): ResourceColor {
    switch (theme) {
      case 'yellow': return $r('app.color.color_yellow_soft');
      case 'green': return $r('app.color.color_green_soft');
      case 'red': return $r('app.color.color_live_soft');
      case 'blue': return $r('app.color.color_info_soft');
      case 'gray': return $r('app.color.color_fill');
      default: return $r('app.color.color_fill');
    }
  }

  /** 获取主题文字色（对齐设计稿 qn-msg-ico.c-* / qn-msg-tag.t-*） */
  private getThemeTextColor(theme: MessageTagTheme): ResourceColor {
    switch (theme) {
      case 'yellow': return $r('app.color.color_yellow_text');
      case 'green': return $r('app.color.color_green_deep');
      case 'red': return $r('app.color.color_live');
      case 'blue': return $r('app.color.color_info');
      case 'gray': return $r('app.color.color_text_2');
      default: return $r('app.color.color_text_2');
    }
  }

  /** 格式化相对时间（对齐设计稿: 10分钟前/25分钟前/1小时前/2小时前/昨天） */
  private formatRelativeTime(timestamp: number): string {
    const now: number = Date.now();
    const diff: number = now - timestamp;
    const minute: number = 60 * 1000;
    const hour: number = 60 * minute;
    const day: number = 24 * hour;

    if (diff < minute) {
      return '刚刚';
    }
    if (diff < hour) {
      return `${Math.floor(diff / minute)}分钟前`;
    }
    if (diff < day) {
      return `${Math.floor(diff / hour)}小时前`;
    }
    // 判断昨日
    const msgDate: Date = new Date(timestamp);
    const nowDate: Date = new Date(now);
    const yesterday: Date = new Date(nowDate.getFullYear(), nowDate.getMonth(), nowDate.getDate() - 1);
    if (yesterday.getFullYear() === msgDate.getFullYear()
      && yesterday.getMonth() === msgDate.getMonth()
      && yesterday.getDate() === msgDate.getDate()) {
      return '昨天';
    }
    return `${msgDate.getMonth() + 1}/${msgDate.getDate()}`;
  }
}

/** 独立路由入口（pages/message/message_list） */
@ComponentV2
export struct MessageList {
  build() {
    NavDestination() {
      MessageContent({ showBack: true })
    }
    .hideTitleBar(true)
  }
}
