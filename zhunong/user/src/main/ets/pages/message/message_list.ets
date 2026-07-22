/**
 * message_list - 消息列表页（Tab 内嵌 + 独立路由双用）
 * 遵循 spec 3.1.3.3：
 *  - 仿淘宝聊天会话列表
 *  - 顶部筛选 Tab：全部 / 私信 / 系统通知
 *  - 会话项：头像 + 会话名 + 最新消息预览 + 时间 + 未读数红点
 *  - 置顶会话置顶展示
 *  - 点击进入会话详情页 pages/message/chat_detail?sessionId=xxx
 *  - 长按弹出操作菜单（置顶/删除）
 *  - 空状态：插画 + 提示
 *
 * spec 10.11.4 Step 2：ForEach → LazyForEach + keyGenerator + cachedCount
 *
 * 导出 MessageContent 供 home_page Tab 内嵌使用
 * 同时作为独立路由（pages/message/message_list）
 */

import { Logger, AppConstants, UserRoutes, ToastUtil, RouteName, NavigationHelper, ListStateView } from 'common';
import { ChatSession, SessionType } from '../../model/MessageModels';
import { toggleMockSessionPinned, deleteMockSession } from '../../mock/MessageMock';
import { MessageListDataSource, MessageFilterTab } from '../../viewmodel/MessageListDataSource';
import { ImageUtil } from '../../utils/ImageUtil';
import { WsClient } from '../../utils/WsClient';

/** 跳转聊天详情的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface ChatDetailParam {
  sessionId: string;
}

/** 筛选 Tab 配置项 */
interface FilterTabItem {
  key: MessageFilterTab;
  label: string;
}

/** 筛选 Tab 列表 */
const FILTER_TABS: FilterTabItem[] = [
  { key: 'all', label: '全部' },
  { key: 'private', label: '私信' },
  { key: 'system', label: '系统通知' }
];

/** 消息内容组件（可复用于 Tab 与独立页） */
@ComponentV2
export struct MessageContent {
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
    // 触发 WebSocket 长连接（spec 10.3：消息 Tab 进入时确保 WsClient 已连接，
    // 已实现"真实连接失败自动切 Mock"兜底，后端未部署时不影响体验）
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

  /** 点击会话进入详情 */
  private gotoChatDetail(sessionId: string): void {
    const param: ChatDetailParam = { sessionId: sessionId };
    NavigationHelper.push(RouteName.USER_CHAT_DETAIL, param);
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
        // 顶部筛选 Tab
        this.FilterBar()
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

      // 底部操作菜单（bindSheet 模式）
      if (this.showActionSheet && this.actionSession) {
        this.ActionSheet()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.color_bg_page'))
  }

  /** 顶部筛选 Tab 栏 */
  @Builder
  FilterBar() {
    Row({ space: 0 }) {
      ForEach(FILTER_TABS, (tab: FilterTabItem) => {
        Column({ space: 4 }) {
          Text(tab.label)
            .fontSize(14)
            .fontColor(this.currentFilter === tab.key ? $r('app.color.color_primary') : $r('app.color.color_text_secondary'))
            .fontWeight(this.currentFilter === tab.key ? FontWeight.Bold : FontWeight.Normal)
          // 选中下划线
          Divider()
            .strokeWidth(this.currentFilter === tab.key ? 2 : 0)
            .color($r('app.color.color_primary'))
            .width(this.currentFilter === tab.key ? 24 : 0)
        }
        .padding({ top: 12, bottom: 8 })
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.onFilterChange(tab.key);
        })
      }, (tab: FilterTabItem) => tab.key)
    }
    .width('100%')
    .backgroundColor($r('app.color.color_bg_card'))
    .border({ width: { bottom: 0.5 }, color: $r('app.color.color_divider') })
  }

  /** 会话列表 */
  @Builder
  SessionListView() {
    List({ space: 0 }) {
      LazyForEach(this.dataSource, (session: ChatSession) => {
        ListItem() {
          this.SessionItem(session)
        }
      }, (session: ChatSession) => session.sessionId + `_${session.unreadCount}_${session.lastMessageAt}_${session.isPinned}`)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .cachedCount(AppConstants.LIST_CACHED_COUNT)
  }

  /** 单个会话项 */
  @Builder
  SessionItem(session: ChatSession) {
    Row({ space: 12 }) {
      // 头像 + 未读红点
      Stack({ alignContent: Alignment.TopEnd }) {
        Image(ImageUtil.get(session.peerAvatar))
          .width(48)
          .height(48)
          .borderRadius(24)
          .objectFit(ImageFit.Cover)

        if (session.unreadCount > 0) {
          Text(session.unreadCount > 99 ? '99+' : `${session.unreadCount}`)
            .fontSize(10)
            .fontColor(Color.White)
            .backgroundColor($r('app.color.color_error'))
            .borderRadius(9)
            .constraintSize({ minWidth: 18 })
            .height(18)
            .padding({ left: 4, right: 4 })
            .textAlign(TextAlign.Center)
            .offset({ x: -2, y: -2 })
        }
      }
      .width(48)
      .height(48)

      // 中间：昵称 + 最新消息
      Column({ space: 4 }) {
        Row() {
          Text(session.peerNickname)
            .fontSize(15)
            .fontColor($r('app.color.color_text_primary'))
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          // 系统通知子类型标签
          if (session.type === 'system' && session.noticeType) {
            Text(this.getNoticeTypeLabel(session.noticeType))
              .fontSize(10)
              .fontColor($r('app.color.color_primary'))
              .backgroundColor($r('app.color.color_bg_page'))
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(8)
              .margin({ left: 6 })
          }
          // 置顶标记
          if (session.isPinned) {
            Text('📌')
              .fontSize(11)
              .margin({ left: 4 })
          }
          Text(this.formatTime(session.lastMessageAt))
            .fontSize(11)
            .fontColor($r('app.color.color_text_hint'))
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Text(this.formatLastMessage(session))
          .fontSize(13)
          .fontColor($r('app.color.color_text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.gotoChatDetail(session.sessionId);
    })
    .gesture(
      LongPressGesture({ repeat: false, duration: 500 })
        .onAction(() => {
          this.onSessionLongPress(session);
        })
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
    .height('100%')
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
        .backgroundColor('rgba(0,0,0,0.4)')
        .onClick(() => {
          this.onCancelAction();
        })

      // 操作菜单
      Column({ space: 0 }) {
        // 标题
        Text(this.actionSession ? this.actionSession.peerNickname : '')
          .fontSize(13)
          .fontColor($r('app.color.color_text_hint'))
          .padding({ top: 14, bottom: 14 })

        Divider()
          .color($r('app.color.color_divider'))
          .strokeWidth(0.5)

        // 置顶 / 取消置顶
        Text(this.actionSession && this.actionSession.isPinned ? '取消置顶' : '置顶会话')
          .fontSize(16)
          .fontColor($r('app.color.color_text_primary'))
          .width('100%')
          .height(50)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.onTogglePinned();
          })

        Divider()
          .color($r('app.color.color_divider'))
          .strokeWidth(0.5)

        // 删除
        Text('删除会话')
          .fontSize(16)
          .fontColor($r('app.color.color_error'))
          .width('100%')
          .height(50)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.onDeleteSession();
          })

        Divider()
          .color($r('app.color.color_bg_page'))
          .strokeWidth(6)

        // 取消
        Text('取消')
          .fontSize(16)
          .fontColor($r('app.color.color_text_primary'))
          .width('100%')
          .height(50)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.onCancelAction();
          })
      }
      .width('100%')
      .backgroundColor($r('app.color.color_bg_card'))
      .borderRadius({ topLeft: 12, topRight: 12 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.End)
  }

  /** 格式化最新消息预览（图片/表情特殊处理） */
  private formatLastMessage(session: ChatSession): string {
    // 系统通知直接返回 lastMessage（已是文本）
    if (session.type === 'system') {
      return session.lastMessage;
    }
    // 私信会话：检查是否为图片/表情 key（Mock 中图片消息的 content 是 prod_xxx key）
    if (session.lastMessage.startsWith('prod_')) {
      return '[图片]';
    }
    return session.lastMessage;
  }

  /** 获取系统通知子类型标签 */
  private getNoticeTypeLabel(noticeType: string): string {
    switch (noticeType) {
      case 'order': return '订单';
      case 'logistics': return '物流';
      case 'activity': return '活动';
      case 'review': return '评价';
      default: return '通知';
    }
  }

  /** 格式化时间（今日显示 HH:mm，昨日显示"昨日"，更早显示 MM/DD） */
  private formatTime(timestamp: number): string {
    const now: Date = new Date();
    const msg: Date = new Date(timestamp);
    const isSameDay: boolean = now.getFullYear() === msg.getFullYear()
      && now.getMonth() === msg.getMonth()
      && now.getDate() === msg.getDate();
    if (isSameDay) {
      const h: string = msg.getHours() < 10 ? `0${msg.getHours()}` : `${msg.getHours()}`;
      const m: string = msg.getMinutes() < 10 ? `0${msg.getMinutes()}` : `${msg.getMinutes()}`;
      return `${h}:${m}`;
    }
    // 判断昨日
    const yesterday: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 1);
    const isYesterday: boolean = yesterday.getFullYear() === msg.getFullYear()
      && yesterday.getMonth() === msg.getMonth()
      && yesterday.getDate() === msg.getDate();
    if (isYesterday) {
      return '昨日';
    }
    return `${msg.getMonth() + 1}/${msg.getDate()}`;
  }
}

/** 独立路由入口（pages/message/message_list） */
@ComponentV2
export struct MessageList {
  build() {
    NavDestination() {
      Column() {
        // 顶部栏
        Row() {
          Text('‹')
            .fontSize(28)
            .fontColor($r('app.color.color_text_primary'))
            .onClick(() => {
              NavigationHelper.pop();
            })
          Text('消息')
            .fontSize(18)
            .fontColor($r('app.color.color_text_primary'))
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          Text('')
            .width(28)
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor($r('app.color.color_bg_card'))
        .alignItems(VerticalAlign.Center)

        // 消息内容
        MessageContent()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }
}
