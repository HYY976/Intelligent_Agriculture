/**
 * chat_detail - 会话详情页（聊天界面）
 * 遵循 spec 3.1.3.3 + 设计稿 chat-detail.html 1:1 复刻：
 *  - 白色顶部头：返回箭头 + 对端头像 + 昵称 + 在线状态(绿点) + 更多按钮
 *  - 消息气泡区（灰底 color_fill）：白色入气泡(18 18 18 6) + 黄色出气泡(18 18 6 18) + 商品卡片消息
 *  - 底部输入栏（白底）：图片图标 + 胶囊输入框 + 黄色圆形发送按钮
 *  - 实时通信：WebSocket 长连接（WsClient）
 *  - 离线消息：PreferencesUtil 本地缓存，上线后还原
 *
 * 路由参数：sessionId=xxx
 */

import { Logger, AppConstants, ToastUtil, PreferencesUtil, RouteName, NavigationHelper } from 'common';
import { ChatSession, ChatMessage, MessageContentType, WsMessage, WsConnectionState } from '../../model/MessageModels';
import { getMockSessionById, getMockMessagesBySessionId, sendMockMessage, simulateMockReply, markSessionRead, MOCK_SELF_USER_ID } from '../../mock/MessageMock';
import { WsClient } from '../../utils/WsClient';
import { ImageUtil } from '../../utils/ImageUtil';

/** 离线缓存 key 前缀（按 sessionId 持久化） */
const CACHE_KEY_PREFIX: string = 'chat_cache_';

/** "+"扩展面板图片候选（Mock：从已有商品图挑选） */
const MOCK_IMAGE_KEYS: string[] = ['prod_vegetable_1', 'prod_fruit_1', 'prod_egg_1', 'prod_rice_1'];

@ComponentV2
export struct ChatDetail {
  /** 会话 ID（路由参数） */
  @Local sessionId: string = '';
  /** 会话信息 */
  @Local session: ChatSession | null = null;
  /** 消息列表 */
  @Local messages: ChatMessage[] = [];
  /** 输入框文字 */
  @Local inputText: string = '';
  /** WebSocket 连接状态 */
  @Local wsState: WsConnectionState = 'disconnected';
  /** 是否显示"+"扩展面板 */
  @Local showPlusPanel: boolean = false;
  /** 是否已恢复离线缓存 */
  @Local cacheRestored: boolean = false;

  /** 消息列表 Scroller（自动滚到底） */
  private msgScroller: Scroller = new Scroller();
  /** WebSocket 消息监听器（aboutToDisappear 时注销） */
  private wsMessageListener: ((msg: WsMessage) => void) | null = null;
  /** WebSocket 状态监听器 */
  private wsStateListener: ((state: WsConnectionState) => void) | null = null;

  async aboutToAppear(): Promise<void> {
    const params: Record<string, string> | undefined = NavigationHelper.getParam<Record<string, string>>();
    if (params) {
      this.sessionId = params.sessionId ?? '';
    }
    if (this.sessionId.length === 0) {
      ToastUtil.error('会话不存在');
      NavigationHelper.pop();
      return;
    }

    this.session = getMockSessionById(this.sessionId);
    if (!this.session) {
      ToastUtil.error('会话不存在');
      NavigationHelper.pop();
      return;
    }

    // 1. 先尝试还原离线缓存
    await this.restoreCache();
    // 2. 加载 Mock 消息（缓存为空时使用）
    if (this.messages.length === 0) {
      this.messages = getMockMessagesBySessionId(this.sessionId);
    }
    // 3. 标记会话已读
    markSessionRead(this.sessionId);
    // 4. 连接 WebSocket + 注册监听
    this.initWebSocket();
    // 5. 滚动到底部
    this.scrollToBottom(200);

    Logger.info(AppConstants.SCENE_USER, {
      action: 'chat_detail_appear',
      sessionId: this.sessionId,
      msgCount: this.messages.length,
      cacheRestored: this.cacheRestored
    });
  }

  aboutToDisappear(): void {
    // 注销 WebSocket 监听器（不断开连接，全局单例保持）
    if (this.wsMessageListener) {
      WsClient.offMessage(this.wsMessageListener);
      this.wsMessageListener = null;
    }
    if (this.wsStateListener) {
      WsClient.offStateChange(this.wsStateListener);
      this.wsStateListener = null;
    }
    // 缓存当前会话消息
    this.saveCache();
    Logger.info(AppConstants.SCENE_USER, { action: 'chat_detail_disappear', sessionId: this.sessionId });
  }

  /** 初始化 WebSocket 连接与监听 */
  private initWebSocket(): void {
    this.wsMessageListener = (msg: WsMessage) => {
      this.onWsMessage(msg);
    };
    WsClient.onMessage(this.wsMessageListener);

    this.wsStateListener = (state: WsConnectionState) => {
      this.wsState = state;
    };
    WsClient.onStateChange(this.wsStateListener);

    this.wsState = WsClient.getState();
    WsClient.connect();
  }

  /** 处理收到的 WebSocket 消息 */
  private onWsMessage(msg: WsMessage): void {
    if (msg.sessionId !== this.sessionId) {
      return;
    }
    const isSelf: boolean = msg.fromUserId === MOCK_SELF_USER_ID;
    const newMsg: ChatMessage = {
      messageId: `ws_${msg.timestamp}_${Math.floor(Math.random() * 1000)}`,
      sessionId: msg.sessionId,
      senderId: msg.fromUserId,
      receiverId: msg.toUserId,
      contentType: msg.contentType ? msg.contentType : 'text',
      content: msg.content,
      isSelf: isSelf,
      isRead: true,
      createdAt: msg.timestamp
    };
    const exists: boolean = this.messages.some((m: ChatMessage) =>
      m.content === newMsg.content && Math.abs(m.createdAt - newMsg.createdAt) < 1000
    );
    if (!exists) {
      this.messages.push(newMsg);
      this.scrollToBottom(100);
    }
  }

  /** 还原离线缓存 */
  private async restoreCache(): Promise<void> {
    try {
      const cacheKey: string = `${CACHE_KEY_PREFIX}${this.sessionId}`;
      const cacheStr: string = await PreferencesUtil.getString(cacheKey, '');
      if (cacheStr.length > 0) {
        const parsed: ChatMessage[] = JSON.parse(cacheStr) as ChatMessage[];
        if (parsed.length > 0) {
          this.messages = parsed;
          this.cacheRestored = true;
          Logger.info(AppConstants.SCENE_USER, { action: 'chat_cache_restore', sessionId: this.sessionId, count: parsed.length });
        }
      }
    } catch (err) {
      Logger.error(AppConstants.SCENE_USER, { action: 'chat_cache_restore_fail', error: (err as Error).message });
    }
  }

  /** 保存当前消息到离线缓存 */
  private async saveCache(): Promise<void> {
    if (this.messages.length === 0) {
      return;
    }
    try {
      const cacheKey: string = `${CACHE_KEY_PREFIX}${this.sessionId}`;
      const cacheStr: string = JSON.stringify(this.messages);
      await PreferencesUtil.putString(cacheKey, cacheStr);
    } catch (err) {
      Logger.error(AppConstants.SCENE_USER, { action: 'chat_cache_save_fail', error: (err as Error).message });
    }
  }

  /** 滚动到底部 */
  private scrollToBottom(delay: number = 100): void {
    setTimeout(() => {
      this.msgScroller.scrollEdge(Edge.Bottom);
    }, delay);
  }

  /** 发送文字消息 */
  private onSendText(): void {
    const text: string = this.inputText.trim();
    if (text.length === 0) {
      return;
    }
    this.sendMessage(text, 'text');
    this.inputText = '';
    this.showPlusPanel = false;
  }

  /** 发送图片消息（Mock：从候选图列表中选） */
  private onSendImage(imageKey: string): void {
    this.sendMessage(imageKey, 'image');
    this.showPlusPanel = false;
  }

  /** 统一发送消息入口 */
  private sendMessage(content: string, contentType: MessageContentType): void {
    const newMsg: ChatMessage = sendMockMessage(this.sessionId, content, contentType);
    this.messages.push(newMsg);
    this.scrollToBottom(100);

    if (this.session) {
      const wsMsg: WsMessage = {
        type: this.session.type === 'system' ? 'notification' : 'chat',
        sessionId: this.sessionId,
        fromUserId: MOCK_SELF_USER_ID,
        toUserId: this.session.userBId,
        content: content,
        contentType: contentType,
        timestamp: newMsg.createdAt
      };
      WsClient.send(wsMsg);
    }

    Logger.info(AppConstants.SCENE_USER, {
      action: 'chat_send_msg',
      sessionId: this.sessionId,
      contentType: contentType,
      length: content.length
    });

    // Mock 模式：模拟对方回复（仅有聊天记录的会话）
    if (this.wsState === 'mock' && this.session && this.session.hasChat) {
      setTimeout(() => {
        const reply: ChatMessage | null = simulateMockReply(this.sessionId);
        if (reply) {
          this.messages.push(reply);
          this.scrollToBottom(100);
          this.saveCache();
        }
      }, 1500 + Math.floor(Math.random() * 1500));
    }

    this.saveCache();
  }

  /** 切换"+"扩展面板 */
  private onTogglePlusPanel(): void {
    this.showPlusPanel = !this.showPlusPanel;
  }

  /** 返回 */
  private goBack(): void {
    NavigationHelper.pop();
  }

  build() {
    NavDestination() {
      Column() {
        // 白色顶部头（对齐设计稿 qn-chat-header）
        this.ChatHeader()
        // 消息气泡列表（对齐设计稿 qn-chat-body）
        this.MessageList()
        // 底部输入栏（对齐设计稿 qn-inputbar）
        this.InputBar()
        // "+"扩展面板
        if (this.showPlusPanel) {
          this.PlusPanel()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_fill'))
    }
    .hideTitleBar(true)
  }

  /** 白色顶部头（对齐设计稿 qn-chat-header: 状态栏 + 导航栏） */
  @Builder
  ChatHeader() {
    Column() {
      // 导航栏（对齐设计稿 qn-chat-topbar）
      Row() {
        // 返回箭头按钮（对齐设计稿 qn-chat-back）
        Row() {
          Text('‹')
            .fontSize(24)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
        }
        .width(32)
        .height(32)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .onClick(() => { this.goBack(); })

        // 对端头像 + 昵称 + 在线状态（对齐设计稿 qn-chat-head）
        Row({ space: 8 }) {
          if (this.session) {
            Image(ImageUtil.get(this.session.peerAvatar))
              .width(32)
              .height(32)
              .borderRadius(AppConstants.RADIUS_PILL)
              .objectFit(ImageFit.Cover)
              .backgroundColor($r('app.color.color_fill'))
          }
          Column({ space: 1 }) {
            Text(this.session ? this.session.peerNickname : '')
              .fontSize(15)
              .fontColor($r('app.color.color_ink'))
              .fontWeight(FontWeight.Bold)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Row({ space: 4 }) {
              // 在线状态圆点（对齐设计稿 qn-chat-dot 6×6 绿色）
              Column()
                .width(6)
                .height(6)
                .borderRadius(3)
                .backgroundColor(this.getWsStateColor())
              Text(this.getWsStateText())
                .fontSize(11)
                .fontColor($r('app.color.color_text_3'))
            }
            .alignItems(VerticalAlign.Center)
          }
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)

        // 更多按钮（对齐设计稿 qn-chat-more）
        Row() {
          Text('⋯')
            .fontSize(22)
            .fontColor($r('app.color.color_ink'))
        }
        .width(32)
        .height(32)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .onClick(() => { ToastUtil.info('更多功能开发中'); })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 6, bottom: 8 })
      .backgroundColor($r('app.color.color_bg_card'))
      .border({ width: { bottom: 1 }, color: $r('app.color.color_line') })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
  }

  /** 消息气泡列表（对齐设计稿 qn-chat-body: 灰底 + 16px padding + 16px gap） */
  @Builder
  MessageList() {
    List({ scroller: this.msgScroller, space: 16 }) {
      // 顶部时间提示（对齐设计稿首条消息上方时间）
      if (this.messages.length > 0) {
        ListItem() {
          Text(this.formatTime(this.messages[0].createdAt))
            .fontSize(11)
            .fontColor($r('app.color.color_text_3'))
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
        }
      }

      ForEach(this.messages, (msg: ChatMessage, index: number) => {
        ListItem() {
          this.MessageBubble(msg)
        }
      }, (msg: ChatMessage, index: number) => msg.messageId + `_${msg.isRead}_${index}`)
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .scrollBar(BarState.Off)
    .cachedCount(AppConstants.LIST_CACHED_COUNT)
  }

  /** 单条消息行（对齐设计稿 qn-msg: 入/出 + 头像 + 气泡 + 时间） */
  @Builder
  MessageBubble(msg: ChatMessage) {
    Row() {
      if (msg.isSelf) {
        // 自己消息：右侧气泡（对齐设计稿 qn-msg-out）
        Blank()
        Column({ space: 4 }) {
          this.BubbleContent(msg, true)
          Text(this.formatTime(msg.createdAt))
            .fontSize(11)
            .fontColor($r('app.color.color_text_3'))
            .padding({ right: 4 })
        }
        .alignItems(HorizontalAlign.End)
        .constraintSize({ maxWidth: '75%' })
      } else {
        // 对方消息：左侧头像 + 气泡（对齐设计稿 qn-msg-in）
        Image(this.session ? ImageUtil.get(this.session.peerAvatar) : ImageUtil.getDefaultAvatar())
          .width(36)
          .height(36)
          .borderRadius(AppConstants.RADIUS_PILL)
          .objectFit(ImageFit.Cover)
          .backgroundColor($r('app.color.color_fill'))
          .margin({ top: 2 })

        Column({ space: 4 }) {
          this.BubbleContent(msg, false)
          Text(this.formatTime(msg.createdAt))
            .fontSize(11)
            .fontColor($r('app.color.color_text_3'))
            .padding({ left: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 8 })
        .constraintSize({ maxWidth: '75%' })

        Blank()
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  /** 气泡内容（根据 contentType 渲染，对齐设计稿 qn-msg-bubble） */
  @Builder
  BubbleContent(msg: ChatMessage, isSelf: boolean) {
    if (msg.contentType === 'text') {
      // 文字气泡（对齐设计稿 qn-msg-bubble-in 白底 / qn-msg-bubble-out 黄底）
      Text(msg.content)
        .fontSize(14)
        .fontColor($r('app.color.color_ink'))
        .lineHeight(21)
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor(isSelf ? $r('app.color.color_yellow') : $r('app.color.color_bg_card'))
        .borderRadius({
          topLeft: 18,
          topRight: 18,
          bottomLeft: isSelf ? 18 : 6,
          bottomRight: isSelf ? 6 : 18
        })
    } else if (msg.contentType === 'emoji') {
      // 表情消息（大号 emoji，无气泡背景）
      Text(msg.content)
        .fontSize(32)
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
    } else if (msg.contentType === 'image') {
      // 图片消息（对齐设计稿 qn-msg-card-img）
      Image(ImageUtil.get(msg.content))
        .width(160)
        .height(160)
        .borderRadius(AppConstants.RADIUS_MD)
        .objectFit(ImageFit.Cover)
    } else if (msg.contentType === 'product') {
      // 商品卡片消息（对齐设计稿 qn-msg-card: 白底 + 边框 + 图+名+价）
      Row({ space: 10 }) {
        Image(ImageUtil.get(msg.productImage ?? 'prod_fruit_1'))
          .width(56)
          .height(56)
          .borderRadius(AppConstants.RADIUS_SM)
          .objectFit(ImageFit.Cover)
          .backgroundColor($r('app.color.color_fill'))

        Column({ space: 6 }) {
          Text(msg.productName ?? msg.content)
            .fontSize(13)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 价格行（对齐设计稿 qn-price: ¥12px + 整数18px 红色）
          Row({ space: 1 }) {
            Text('¥')
              .fontSize(12)
              .fontColor($r('app.color.color_live'))
              .fontWeight(FontWeight.Bold)
              .baselineOffset(3)
            Text(msg.productPrice !== undefined ? msg.productPrice.toFixed(2) : '0.00')
              .fontSize(18)
              .fontColor($r('app.color.color_live'))
              .fontWeight(FontWeight.Bold)
          }
          .alignItems(VerticalAlign.Bottom)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .padding(10)
      .backgroundColor($r('app.color.color_bg_card'))
      .borderRadius(AppConstants.RADIUS_MD)
      .border({ width: 1, color: $r('app.color.color_line') })
      .constraintSize({ minWidth: 210 })
      .alignItems(VerticalAlign.Center)
    }
  }

  /** 底部输入栏（对齐设计稿 qn-inputbar: 图片图标 + 胶囊输入框 + 黄色发送按钮） */
  @Builder
  InputBar() {
    Row({ space: 8 }) {
      // 图片图标按钮（对齐设计稿 qn-inputbar-ico 36×36）
      Row() {
        Text('🖼️')
          .fontSize(22)
      }
      .width(36)
      .height(36)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { this.onTogglePlusPanel(); })

      // 胶囊输入框（对齐设计稿 qn-inputbar-field: fill 底 + pill 圆角）
      TextInput({ text: this.inputText, placeholder: '输入消息...' })
        .fontSize(14)
        .fontColor($r('app.color.color_ink'))
        .backgroundColor($r('app.color.color_fill'))
        .borderRadius(AppConstants.RADIUS_PILL)
        .height(36)
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
        .onChange((value: string) => {
          this.inputText = value;
        })
        .onSubmit(() => {
          this.onSendText();
        })

      // 黄色圆形发送按钮（对齐设计稿 qn-inputbar-send: 黄底 + pill + ➤图标）
      Row() {
        Text('➤')
          .fontSize(18)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .width(36)
      .height(36)
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor($r('app.color.color_yellow'))
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { this.onSendText(); })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 10 })
    .backgroundColor($r('app.color.color_bg_card'))
    .border({ width: { top: 1 }, color: $r('app.color.color_line') })
    .alignItems(VerticalAlign.Center)
  }

  /** "+"扩展面板（图片选择 Mock，对齐设计稿图片选择器） */
  @Builder
  PlusPanel() {
    Column({ space: 12 }) {
      Text('图片')
        .fontSize(12)
        .fontColor($r('app.color.color_text_2'))
        .alignSelf(ItemAlign.Start)
        .padding({ left: 12, top: 12 })

      // Mock 图片候选网格
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(MOCK_IMAGE_KEYS, (imgKey: string) => {
          Image(ImageUtil.get(imgKey))
            .width(72)
            .height(72)
            .borderRadius(AppConstants.RADIUS_SM)
            .objectFit(ImageFit.Cover)
            .margin({ right: 8, bottom: 8 })
            .onClick(() => {
              this.onSendImage(imgKey);
            })
        }, (imgKey: string) => imgKey)
      }
      .width('100%')
      .padding({ left: 12, right: 12 })

      // 相机占位
      Row({ space: 8 }) {
        Text('📷')
          .fontSize(24)
        Text('拍照')
          .fontSize(13)
          .fontColor($r('app.color.color_ink'))
      }
      .width('100%')
      .height(48)
      .padding({ left: 12 })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        ToastUtil.show('相机功能将在后续阶段接入');
      })
    }
    .width('100%')
    .height(220)
    .backgroundColor($r('app.color.color_bg_card'))
    .border({ width: { top: 1 }, color: $r('app.color.color_line') })
  }

  /** 获取 WebSocket 状态文案（对齐设计稿 qn-chat-head-status: 在线） */
  private getWsStateText(): string {
    switch (this.wsState) {
      case 'connected': return '在线';
      case 'connecting': return '连接中...';
      case 'reconnecting': return '重连中...';
      case 'mock': return '在线';
      default: return '未连接';
    }
  }

  /** 获取 WebSocket 状态圆点颜色（对齐设计稿 qn-chat-dot: 绿色） */
  private getWsStateColor(): ResourceColor {
    switch (this.wsState) {
      case 'connected': return $r('app.color.color_green');
      case 'mock': return $r('app.color.color_green');
      case 'connecting': return $r('app.color.color_yellow_text');
      case 'reconnecting': return $r('app.color.color_yellow_text');
      default: return $r('app.color.color_text_4');
    }
  }

  /** 格式化时间（HH:mm，对齐设计稿 qn-msg-time） */
  private formatTime(timestamp: number): string {
    const d: Date = new Date(timestamp);
    const h: string = d.getHours() < 10 ? `0${d.getHours()}` : `${d.getHours()}`;
    const m: string = d.getMinutes() < 10 ? `0${d.getMinutes()}` : `${d.getMinutes()}`;
    return `${h}:${m}`;
  }
}
