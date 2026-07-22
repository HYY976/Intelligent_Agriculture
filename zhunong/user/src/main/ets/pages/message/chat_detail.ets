/**
 * chat_detail - 会话详情页（聊天界面）
 * 遵循 spec 3.1.3.3：
 *  - 仿淘宝聊天界面
 *  - 消息气泡（左右两侧，自己右侧绿色，对方左侧白色）
 *  - 支持文字 / 图片 / 表情消息
 *  - 底部输入框 + 发送按钮 + "+"扩展（图片/表情）
 *  - 实时通信：WebSocket 长连接（WsClient）
 *  - 离线消息：PreferencesUtil 本地缓存，上线后还原（Phase 6 后端补齐服务端缓存）
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

/** 快捷表情列表 */
const QUICK_EMOJIS: string[] = ['😀', '😂', '🙏', '👍', '🌹', '❤️', '😋', '😱', '💪', '🎉'];

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
  /** 是否显示表情面板 */
  @Local showEmojiPanel: boolean = false;
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
    // 注册消息接收监听
    this.wsMessageListener = (msg: WsMessage) => {
      this.onWsMessage(msg);
    };
    WsClient.onMessage(this.wsMessageListener);

    // 注册状态变更监听
    this.wsStateListener = (state: WsConnectionState) => {
      this.wsState = state;
    };
    WsClient.onStateChange(this.wsStateListener);

    // 当前状态同步
    this.wsState = WsClient.getState();

    // 触发连接（已连接会直接返回）
    WsClient.connect();
  }

  /** 处理收到的 WebSocket 消息 */
  private onWsMessage(msg: WsMessage): void {
    // 仅处理当前会话的消息
    if (msg.sessionId !== this.sessionId) {
      return;
    }
    // 转换为 ChatMessage 追加到列表
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
    // 去重（按 content + timestamp）
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
      ToastUtil.warning('请输入消息内容');
      return;
    }
    this.sendMessage(text, 'text');
    this.inputText = '';
    this.showEmojiPanel = false;
    this.showPlusPanel = false;
  }

  /** 发送表情消息 */
  private onSendEmoji(emoji: string): void {
    this.sendMessage(emoji, 'emoji');
  }

  /** 发送图片消息（Mock：从候选图列表中按序选） */
  private onSendImage(imageKey: string): void {
    this.sendMessage(imageKey, 'image');
    this.showPlusPanel = false;
  }

  /** 统一发送消息入口 */
  private sendMessage(content: string, contentType: MessageContentType): void {
    // 1. 本地追加（UI 立即显示）
    const newMsg: ChatMessage = sendMockMessage(this.sessionId, content, contentType);
    this.messages.push(newMsg);
    this.scrollToBottom(100);

    // 2. 通过 WebSocket 发送（Mock 状态下本地回声，不实际发到服务端）
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

    // 3. Mock 模式：模拟对方回复（仅私信会话）
    if (this.wsState === 'mock' && this.session && this.session.type === 'private') {
      setTimeout(() => {
        const reply: ChatMessage | null = simulateMockReply(this.sessionId);
        if (reply) {
          this.messages.push(reply);
          this.scrollToBottom(100);
          this.saveCache();
        }
      }, 1500 + Math.floor(Math.random() * 1500));
    }

    // 4. 异步缓存
    this.saveCache();
  }

  /** 切换表情面板 */
  private onToggleEmojiPanel(): void {
    this.showEmojiPanel = !this.showEmojiPanel;
    if (this.showEmojiPanel) {
      this.showPlusPanel = false;
    }
  }

  /** 切换"+"扩展面板 */
  private onTogglePlusPanel(): void {
    this.showPlusPanel = !this.showPlusPanel;
    if (this.showPlusPanel) {
      this.showEmojiPanel = false;
    }
  }

  /** 返回 */
  private goBack(): void {
    NavigationHelper.pop();
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部栏
        this.TopBar()
        // 消息列表
        this.MessageList()
        // 输入栏
        this.InputBar()
        // 扩展面板（表情 / "+"）
        if (this.showEmojiPanel) {
          this.EmojiPanel()
        }
        if (this.showPlusPanel) {
          this.PlusPanel()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 顶部栏（返回 + 对端昵称 + 连接状态指示） */
  @Builder
  TopBar() {
    Row({ space: 8 }) {
      Text('‹')
        .fontSize(28)
        .fontColor($r('app.color.color_text_primary'))
        .onClick(() => {
          this.goBack();
        })
      // 对端头像
      if (this.session) {
        Image(ImageUtil.get(this.session.peerAvatar))
          .width(32)
          .height(32)
          .borderRadius(16)
      }
      // 对端昵称 + 连接状态
      Column({ space: 2 }) {
        Text(this.session ? this.session.peerNickname : '')
          .fontSize(15)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.getWsStateText())
          .fontSize(10)
          .fontColor(this.getWsStateColor())
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 右侧功能按钮（预留：电话/视频）
      Text('⋯')
        .fontSize(22)
        .fontColor($r('app.color.color_text_secondary'))
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
    .border({ width: { bottom: 0.5 }, color: $r('app.color.color_divider') })
  }

  /** 消息列表 */
  @Builder
  MessageList() {
    List({ scroller: this.msgScroller, space: 16 }) {
      // 时间提示（首条消息上方）
      if (this.messages.length > 0) {
        ListItem() {
          Text(this.formatTime(this.messages[0].createdAt))
            .fontSize(11)
            .fontColor($r('app.color.color_text_hint'))
            .backgroundColor($r('app.color.color_bg_page'))
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(8)
            .margin({ top: 12 })
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
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .scrollBar(BarState.Off)
    .cachedCount(AppConstants.LIST_CACHED_COUNT)
  }

  /** 单条消息气泡 */
  @Builder
  MessageBubble(msg: ChatMessage) {
    Row() {
      if (msg.isSelf) {
        // 自己消息：右侧气泡
        Blank()
        this.Avatar(msg)
        Column({ space: 4 }) {
          this.BubbleContent(msg, true)
        }
        .alignItems(HorizontalAlign.End)
        .layoutWeight(0)
        .constraintSize({ maxWidth: '70%' })
      } else {
        // 对方消息：左侧气泡
        this.Avatar(msg)
        Column({ space: 4 }) {
          this.BubbleContent(msg, false)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(0)
        .constraintSize({ maxWidth: '70%' })
        Blank()
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  /** 头像 */
  @Builder
  Avatar(msg: ChatMessage) {
    if (msg.isSelf) {
      // 自己头像（默认兜底）
      Image(ImageUtil.getDefaultAvatar())
        .width(36)
        .height(36)
        .borderRadius(18)
    } else {
      // 对端头像
      Image(this.session ? ImageUtil.get(this.session.peerAvatar) : ImageUtil.getDefaultAvatar())
        .width(36)
        .height(36)
        .borderRadius(18)
    }
  }

  /** 气泡内容（根据 contentType 渲染） */
  @Builder
  BubbleContent(msg: ChatMessage, isSelf: boolean) {
    if (msg.contentType === 'text') {
      Text(msg.content)
        .fontSize(15)
        .fontColor(isSelf ? Color.White : $r('app.color.color_text_primary'))
        .lineHeight(22)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .backgroundColor(isSelf ? $r('app.color.color_primary') : $r('app.color.color_bg_card'))
        .borderRadius(12)
    } else if (msg.contentType === 'emoji') {
      Text(msg.content)
        .fontSize(32)
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
    } else if (msg.contentType === 'image') {
      Image(ImageUtil.get(msg.content))
        .width(160)
        .height(160)
        .borderRadius(8)
        .objectFit(ImageFit.Cover)
    }
  }

  /** 底部输入栏 */
  @Builder
  InputBar() {
    Column() {
      Row({ space: 8 }) {
        // 表情按钮
        Text('😊')
          .fontSize(24)
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.onToggleEmojiPanel();
          })

        // 输入框
        TextInput({ text: this.inputText, placeholder: '说点什么吧...' })
          .fontSize(14)
          .fontColor($r('app.color.color_text_primary'))
          .backgroundColor($r('app.color.color_bg_page'))
          .borderRadius(20)
          .height(40)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.inputText = value;
          })
          .onSubmit(() => {
            this.onSendText();
          })

        // "+"扩展按钮（输入框为空时显示）
        if (this.inputText.trim().length === 0) {
          Text('➕')
            .fontSize(22)
            .width(36)
            .height(36)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.onTogglePlusPanel();
            })
        } else {
          // 发送按钮
          Button('发送')
            .height(32)
            .borderRadius(16)
            .backgroundColor($r('app.color.color_primary'))
            .fontColor(Color.White)
            .fontSize(13)
            .padding({ left: 16, right: 16 })
            .onClick(() => {
              this.onSendText();
            })
        }
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .backgroundColor($r('app.color.color_bg_card'))
    .border({ width: { top: 0.5 }, color: $r('app.color.color_divider') })
  }

  /** 表情面板 */
  @Builder
  EmojiPanel() {
    Column() {
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(QUICK_EMOJIS, (emoji: string) => {
          Text(emoji)
            .fontSize(28)
            .width('20%')
            .height(48)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.onSendEmoji(emoji);
            })
        }, (emoji: string, i: number) => `${emoji}_${i}`)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 12, bottom: 12 })
    }
    .width('100%')
    .height(180)
    .backgroundColor($r('app.color.color_bg_card'))
    .border({ width: { top: 0.5 }, color: $r('app.color.color_divider') })
  }

  /** "+"扩展面板（图片选择 Mock） */
  @Builder
  PlusPanel() {
    Column({ space: 12 }) {
      Text('图片')
        .fontSize(12)
        .fontColor($r('app.color.color_text_secondary'))
        .alignSelf(ItemAlign.Start)
        .padding({ left: 12, top: 12 })

      // Mock 图片候选网格
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(MOCK_IMAGE_KEYS, (imgKey: string) => {
          Image(ImageUtil.get(imgKey))
            .width(72)
            .height(72)
            .borderRadius(8)
            .objectFit(ImageFit.Cover)
            .margin({ right: 8, bottom: 8 })
            .onClick(() => {
              this.onSendImage(imgKey);
            })
        }, (imgKey: string) => imgKey)
      }
      .width('100%')
      .padding({ left: 12, right: 12 })

      // 相机占位（Phase 6 接入 @ohos.multimedia.camera）
      Row({ space: 8 }) {
        Text('📷')
          .fontSize(24)
        Text('拍照')
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
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
    .border({ width: { top: 0.5 }, color: $r('app.color.color_divider') })
  }

  /** 获取 WebSocket 状态文案 */
  private getWsStateText(): string {
    switch (this.wsState) {
      case 'connected': return '在线';
      case 'connecting': return '连接中...';
      case 'reconnecting': return '重连中...';
      case 'mock': return '演示模式';
      default: return '未连接';
    }
  }

  /** 获取 WebSocket 状态颜色 */
  private getWsStateColor(): Resource {
    switch (this.wsState) {
      case 'connected': return $r('app.color.color_primary');
      case 'mock': return $r('app.color.color_text_hint');
      default: return $r('app.color.color_text_hint');
    }
  }

  /** 格式化时间（HH:mm） */
  private formatTime(timestamp: number): string {
    const d: Date = new Date(timestamp);
    const h: string = d.getHours() < 10 ? `0${d.getHours()}` : `${d.getHours()}`;
    const m: string = d.getMinutes() < 10 ? `0${d.getMinutes()}` : `${d.getMinutes()}`;
    return `${h}:${m}`;
  }
}
