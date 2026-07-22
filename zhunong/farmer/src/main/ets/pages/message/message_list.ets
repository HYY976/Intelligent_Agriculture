/**
 * message_list - 消息会话列表（spec 3.2.4.4 / 4.1.10）
 *
 * 与用户端消息互通的买卖家聊天会话界面
 * 结构与用户端消息Tab一致（私信会话 + 系统通知会话）
 * WebSocket 长连接 + 离线消息缓存
 */

import { Logger, AppConstants, FarmerRoutes, NavigationHelper, RouteName } from 'common';
import { ChatSession, WsMessage, WsConnectionState, SessionListResult } from '../../model/FarmerMessageModels';
import { MessageRepository } from '../../repository/MessageRepository';
import { FarmerWsClient } from '../../utils/WsClient';
import { MOCK_FARMER_ID } from '../../mock/FarmerMock';

/** 跳转聊天详情页的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface ChatDetailParam {
  sessionId: string;
  peerId: string;
  peerNickname: string;
  peerAvatar: string;
}

@ComponentV2
export struct MessageList {
  /** 会话列表 */
  @Local sessions: ChatSession[] = [];
  /** 总未读数 */
  @Local totalUnread: number = 0;
  /** 是否正在加载 */
  @Local isLoading: boolean = false;
  /** WebSocket 连接状态 */
  @Local wsState: WsConnectionState = 'disconnected';

  async aboutToAppear(): Promise<void> {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'message_list_appear' });
    await this.loadSessions();
    this.connectWs();
  }

  aboutToDisappear(): void {
    // 离开页面时不主动断开 WsClient（单例维持全局连接）
  }

  /** 加载会话列表 */
  private async loadSessions(): Promise<void> {
    this.isLoading = true;
    try {
      const result: SessionListResult = await MessageRepository.getSessions(MOCK_FARMER_ID);
      this.sessions = result.list;
      this.totalUnread = result.totalUnread;
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'load_sessions_fail', error: (err as Error).message });
    } finally {
      this.isLoading = false;
    }
  }

  /** 建立 WebSocket 连接（spec 3.1.3.3） */
  private connectWs(): void {
    FarmerWsClient.onMessage((msg: WsMessage) => {
      Logger.info(AppConstants.SCENE_FARMER, { action: 'ws_msg_recv', sessionId: msg.sessionId });
      // 收到消息后刷新会话列表
      this.loadSessions();
    });
    FarmerWsClient.onStateChange((state: WsConnectionState) => {
      this.wsState = state;
    });
    FarmerWsClient.connect();
  }

  /** 进入聊天详情 */
  private gotoChatDetail(session: ChatSession): void {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'goto_chat', sessionId: session.sessionId });
    const peerId: string = session.userAId === MOCK_FARMER_ID ? session.userBId : session.userAId;
    const peerNickname: string = session.peerNickname ?? '会话';
    const peerAvatar: string = session.peerAvatar ?? '';
    const param: ChatDetailParam = {
      sessionId: session.sessionId,
      peerId: peerId,
      peerNickname: peerNickname,
      peerAvatar: peerAvatar
    };
    NavigationHelper.push(RouteName.FARMER_CHAT_DETAIL, param);
  }

  /** 格式化时间 */
  private formatTime(ts: number | undefined): string {
    if (!ts) {
      return '';
    }
    const d: Date = new Date(ts);
    const now: number = Date.now();
    const diff: number = now - ts;
    if (diff < 60000) {
      return '刚刚';
    } else if (diff < 3600000) {
      return `${Math.floor(diff / 60000)}分钟前`;
    } else if (diff < 86400000) {
      return `${Math.floor(diff / 3600000)}小时前`;
    }
    return `${d.getMonth() + 1}-${d.getDate()}`;
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        this.WsStateBanner()
        this.SessionList()
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
      Text('消息')
        .fontSize(18)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
      if (this.totalUnread > 0) {
        Text(`${this.totalUnread}`)
          .fontSize(10)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.color_error'))
          .height(16)
          .borderRadius(8)
          .padding({ left: 6, right: 6 })
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** WebSocket 状态横幅 */
  @Builder
  WsStateBanner() {
    if (this.wsState === 'mock') {
      Row({ space: 8 }) {
        Text('🟡')
          .fontSize(12)
        Text('当前为 Mock 模式（后端 WebSocket 未部署）')
          .fontSize(11)
          .fontColor($r('app.color.color_text_secondary'))
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 6, bottom: 6 })
      .backgroundColor('rgba(255,213,79,0.15)')
    } else if (this.wsState === 'connected') {
      Row({ space: 8 }) {
        Text('🟢')
          .fontSize(12)
        Text('已连接')
          .fontSize(11)
          .fontColor($r('app.color.color_primary'))
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 6, bottom: 6 })
      .backgroundColor('rgba(139,195,74,0.1)')
    }
  }

  /** 会话列表 */
  @Builder
  SessionList() {
    if (this.sessions.length === 0 && !this.isLoading) {
      Column({ space: 8 }) {
        Text('✉️')
          .fontSize(48)
        Text('暂无会话')
          .fontSize(14)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    } else {
      List({ space: 0 }) {
        ForEach(this.sessions, (session: ChatSession, _idx: number) => {
          ListItem() {
            this.SessionCard(session)
          }
          .onClick(() => this.gotoChatDetail(session))
        }, (session: ChatSession) => session.sessionId)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 12, right: 12, top: 8 })
      .scrollBar(BarState.Off)
      .divider({
        strokeWidth: 0.5,
        color: $r('app.color.color_divider'),
        startMargin: 76,
        endMargin: 12
      })
    }
  }

  /** 会话卡片 */
  @Builder
  SessionCard(session: ChatSession) {
    Row({ space: 12 }) {
      // 头像（系统通知用系统头像，私信用买家头像）
      Stack() {
        Text(session.type === 'system' ? '📢' : '👤')
          .fontSize(20)
        if (session.unreadCountB > 0) {
          Text(`${session.unreadCountB}`)
            .fontSize(10)
            .fontColor(Color.White)
            .backgroundColor($r('app.color.color_error'))
            .height(16)
            .borderRadius(8)
            .padding({ left: 4, right: 4 })
            .textAlign(TextAlign.Center)
            .position({ x: 28, y: -4 })
        }
      }
      .width(48)
      .height(48)
      .borderRadius(24)
      .backgroundColor(session.type === 'system' ? $r('app.color.color_accent_gold') : $r('app.color.color_primary_light'))
      .alignContent(Alignment.Center)

      Column({ space: 4 }) {
        Row() {
          Text(session.peerNickname ?? '未知')
            .fontSize(14)
            .fontColor($r('app.color.color_text_primary'))
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.formatTime(session.lastMessageAt))
            .fontSize(11)
            .fontColor($r('app.color.color_text_hint'))
        }
        .width('100%')
        Text(session.lastMessage ?? '')
          .fontSize(12)
          .fontColor($r('app.color.color_text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
  }
}
