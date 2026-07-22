/**
 * chat_detail - 聊天详情（spec 3.2.4.4 / 4.1.10）
 *
 * 买卖家互通聊天界面
 * - 历史消息加载（分页）
 * - 实时消息接收（WebSocket）
 * - 离线时回退到 REST 接口兜底发送
 * - 卖家消息带"卖家"标识
 */

import { Logger, AppConstants, ToastUtil, NavigationHelper, RouteName } from 'common';
import { ChatMessage, WsMessage, WsConnectionState } from '../../model/FarmerMessageModels';
import { MessageRepository } from '../../repository/MessageRepository';
import { FarmerWsClient } from '../../utils/WsClient';
import { MOCK_FARMER_ID } from '../../mock/FarmerMock';

@ComponentV2
export struct ChatDetail {
  /** 会话 ID */
  @Local sessionId: string = '';
  /** 对方用户 ID */
  @Local peerId: string = '';
  /** 对方昵称 */
  @Local peerNickname: string = '';
  /** 对方头像 */
  @Local peerAvatar: string = '';
  /** 消息列表 */
  @Local messages: ChatMessage[] = [];
  /** 输入内容 */
  @Local inputText: string = '';
  /** 是否正在加载 */
  @Local isLoading: boolean = false;
  /** 是否正在发送 */
  @Local isSending: boolean = false;
  /** 当前页码 */
  @Local page: number = 1;
  /** WebSocket 连接状态 */
  @Local wsState: WsConnectionState = 'disconnected';

  async aboutToAppear(): Promise<void> {
    const params: Record<string, string> = NavigationHelper.getParam<Record<string, string>>() ?? {};
    this.sessionId = params?.sessionId ?? '';
    this.peerId = params?.peerId ?? '';
    // spec 10.9.2：message_list 已用 params 对象传值（不再 URL 编码），此处同步移除 decodeURIComponent 保持对称
    this.peerNickname = params?.peerNickname ?? '聊天';
    this.peerAvatar = params?.peerAvatar ?? '';
    Logger.info(AppConstants.SCENE_FARMER, { action: 'chat_detail_appear', sessionId: this.sessionId });
    await this.loadHistory();
    this.registerWsListener();
  }

  aboutToDisappear(): void {
    // 注销消息监听器，避免重复接收
    FarmerWsClient.offMessage(this.onWsMessage);
    FarmerWsClient.offStateChange(this.onWsStateChange);
  }

  /** 加载历史消息 */
  private async loadHistory(): Promise<void> {
    this.isLoading = true;
    try {
      const list: ChatMessage[] = await MessageRepository.getMessageHistory(this.sessionId, this.page, 50);
      this.messages = list;
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'load_history_fail', error: (err as Error).message });
    } finally {
      this.isLoading = false;
    }
  }

  /** 注册 WebSocket 监听器 */
  private registerWsListener(): void {
    FarmerWsClient.onMessage(this.onWsMessage);
    FarmerWsClient.onStateChange(this.onWsStateChange);
    // 自动建立连接（若尚未建立）
    if (FarmerWsClient.getState() === 'disconnected') {
      FarmerWsClient.connect();
    }
  }

  /** WebSocket 消息回调 */
  private onWsMessage = (msg: WsMessage): void => {
    if (msg.sessionId !== this.sessionId) {
      return;
    }
    // 收到对方消息，追加到列表
    const newMsg: ChatMessage = {
      messageId: `ws_${msg.timestamp}`,
      sessionId: msg.sessionId,
      senderId: msg.fromUserId,
      receiverId: msg.toUserId,
      contentType: msg.contentType,
      content: msg.content,
      isRead: true,
      createdAt: msg.timestamp,
      senderNickname: this.peerNickname,
      senderAvatar: this.peerAvatar
    };
    this.messages = this.messages.concat([newMsg]);
    Logger.info(AppConstants.SCENE_FARMER, { action: 'ws_msg_appended', messageId: newMsg.messageId });
  };

  /** WebSocket 状态变更回调 */
  private onWsStateChange = (state: WsConnectionState): void => {
    this.wsState = state;
  };

  /** 发送消息 */
  private async sendMessage(): Promise<void> {
    if (this.inputText.length === 0) {
      return;
    }
    const content: string = this.inputText;
    this.inputText = '';
    this.isSending = true;

    // 本地回声（乐观更新）
    const localMsg: ChatMessage = {
      messageId: `local_${Date.now()}`,
      sessionId: this.sessionId,
      senderId: MOCK_FARMER_ID,
      receiverId: this.peerId,
      contentType: 'text',
      content: content,
      isRead: true,
      createdAt: Date.now(),
      senderNickname: '青禾农庄',
      senderAvatar: 'avatar_farmer_1'
    };
    this.messages = this.messages.concat([localMsg]);

    try {
      // 优先尝试通过 WebSocket 发送
      const wsMsg: WsMessage = {
        type: 'chat',
        sessionId: this.sessionId,
        fromUserId: MOCK_FARMER_ID,
        toUserId: this.peerId,
        content: content,
        contentType: 'text',
        timestamp: Date.now()
      };
      const sent: boolean = await FarmerWsClient.send(wsMsg);
      if (!sent) {
        // WebSocket 发送失败，回退到 REST
        await MessageRepository.sendMessage(this.sessionId, MOCK_FARMER_ID, this.peerId, content, 'text');
      }
      Logger.info(AppConstants.SCENE_FARMER, { action: 'msg_send_success', sessionId: this.sessionId });
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'msg_send_fail', error: (err as Error).message });
      ToastUtil.error('发送失败');
      // 标记本地消息为失败状态（简化处理）
    } finally {
      this.isSending = false;
    }
  }

  /** 判断是否为自己发送的消息 */
  private isMine(msg: ChatMessage): boolean {
    return msg.senderId === MOCK_FARMER_ID;
  }

  /** 格式化时间 */
  private formatTime(ts: number): string {
    const d: Date = new Date(ts);
    const hh: string = `${d.getHours()}`.padStart(2, '0');
    const mi: string = `${d.getMinutes()}`.padStart(2, '0');
    return `${hh}:${mi}`;
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        this.MessageList()
        this.InputBar()
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
      Text('👤')
        .fontSize(20)
        .width(36)
        .height(36)
        .borderRadius(18)
        .backgroundColor($r('app.color.color_primary_light'))
        .textAlign(TextAlign.Center)
      Column({ space: 2 }) {
        Text(this.peerNickname)
          .fontSize(14)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Medium)
        Text(this.wsState === 'connected' ? '在线' : (this.wsState === 'mock' ? 'Mock 模式' : '离线'))
          .fontSize(10)
          .fontColor($r('app.color.color_text_hint'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .height(56)
    .padding({ left: 12, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** 消息列表 */
  @Builder
  MessageList() {
    if (this.messages.length === 0 && this.isLoading) {
      Column() {
        Text('加载中...')
          .fontSize(14)
          .fontColor($r('app.color.color_text_secondary'))
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    } else {
      List({ space: 12 }) {
        ForEach(this.messages, (msg: ChatMessage, _idx: number) => {
          ListItem() {
            this.MessageBubble(msg)
          }
        }, (msg: ChatMessage) => msg.messageId)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 12, right: 12, top: 12, bottom: 12 })
      .scrollBar(BarState.Off)
    }
  }

  /** 消息气泡 */
  @Builder
  MessageBubble(msg: ChatMessage) {
    Row({ space: 8 }) {
      if (this.isMine(msg)) {
        // 自己发的消息：右对齐
        Blank()
        Column({ space: 4 }) {
          Row({ space: 4 }) {
            Text('卖家')
              .fontSize(9)
              .fontColor(Color.White)
              .backgroundColor($r('app.color.color_secondary'))
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .borderRadius(4)
            Text(this.formatTime(msg.createdAt))
              .fontSize(10)
              .fontColor($r('app.color.color_text_hint'))
          }
          .width('100%')
          .justifyContent(FlexAlign.End)
          Text(msg.content)
            .fontSize(14)
            .fontColor(Color.White)
            .backgroundColor($r('app.color.color_primary'))
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .borderRadius(12)
        }
        .alignItems(HorizontalAlign.End)
        .constraintSize({ maxWidth: '70%' })
        Text('👤')
          .fontSize(20)
          .width(32)
          .height(32)
          .borderRadius(16)
          .backgroundColor($r('app.color.color_secondary'))
          .textAlign(TextAlign.Center)
      } else {
        // 对方消息：左对齐
        Text('👤')
          .fontSize(20)
          .width(32)
          .height(32)
          .borderRadius(16)
          .backgroundColor($r('app.color.color_primary_light'))
          .textAlign(TextAlign.Center)
        Column({ space: 4 }) {
          Row({ space: 4 }) {
            Text(msg.senderNickname ?? this.peerNickname)
              .fontSize(11)
              .fontColor($r('app.color.color_text_secondary'))
            Text(this.formatTime(msg.createdAt))
              .fontSize(10)
              .fontColor($r('app.color.color_text_hint'))
          }
          .width('100%')
          Text(msg.content)
            .fontSize(14)
            .fontColor($r('app.color.color_text_primary'))
            .backgroundColor($r('app.color.color_bg_card'))
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .borderRadius(12)
        }
        .alignItems(HorizontalAlign.Start)
        .constraintSize({ maxWidth: '70%' })
        Blank()
      }
    }
    .width('100%')
  }

  /** 底部输入栏 */
  @Builder
  InputBar() {
    Row({ space: 8 }) {
      TextInput({ text: this.inputText, placeholder: '输入消息...' })
        .height(36)
        .borderRadius(18)
        .backgroundColor($r('app.color.color_bg_card'))
        .padding({ left: 16, right: 16 })
        .fontSize(14)
        .layoutWeight(1)
        .onChange((v: string) => { this.inputText = v; })
        .onSubmit(() => { this.sendMessage(); })
      Button(this.isSending ? '...' : '发送')
        .height(36)
        .borderRadius(18)
        .backgroundColor(this.inputText.length > 0 ? $r('app.color.color_secondary') : $r('app.color.color_button_disabled'))
        .fontColor(Color.White)
        .fontSize(13)
        .padding({ left: 20, right: 20 })
        .enabled(this.inputText.length > 0 && !this.isSending)
        .onClick(() => { this.sendMessage(); })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }
}
