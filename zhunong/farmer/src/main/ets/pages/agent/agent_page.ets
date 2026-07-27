/**
 * agent_page - 智能体页（spec 3.2.1 / 8.3）
 *
 * 对齐设计稿 pages/farmer-agent.html：
 *  - 顶部栏：返回 + "AI 助手" + 清空对话
 *  - 黄色助手介绍卡（头像 + 名称 + 在线状态）
 *  - 对话区域（AI 消息 + 用户消息 + 建议卡片）
 *  - 快捷提问芯片（5个：销量/采摘/病虫害/话术/价格）
 *  - 底部输入栏（语音 + 输入框 + 发送）
 *
 * spec 8.3：AI 农业顾问对话式交互
 */

import { Logger, AppConstants, ToastUtil, NavigationHelper, RouteName } from 'common';
import { ImageUtil } from '../../utils/ImageUtil';
import { BailianClient } from '../../utils/BailianClient';

/** 消息角色 */
type ChatRole = 'ai' | 'user';

/** 消息类型 */
type ChatMessageType = 'text' | 'suggest' | 'quote';

/** 聊天消息 */
interface ChatMessage {
  /** 消息 ID */
  msgId: string;
  /** 角色 */
  role: ChatRole;
  /** 消息类型 */
  type: ChatMessageType;
  /** 文本内容 */
  content: string;
  /** 引用块内容（话术） */
  quote?: string;
  /** 建议卡片（仅 type=suggest 时） */
  suggest?: ChatSuggest;
}

/** 建议卡片 */
interface ChatSuggest {
  /** 标题 */
  title: string;
  /** 描述 */
  desc: string;
  /** 预期提升百分比 */
  uplift: string;
  /** 按钮文案 */
  btnLabel: string;
  /** 跳转路由 */
  route: string;
}

/** 快捷提问项 */
interface QuickPrompt {
  /** 图标 emoji */
  icon: string;
  /** 提示文案 */
  label: string;
  /** 发送内容 */
  content: string;
}

@ComponentV2
export struct AgentPage {
  /** 消息列表 */
  @Local messages: ChatMessage[] = [];
  /** 输入框文本 */
  @Local inputText: string = '';
  /** 是否正在思考 */
  @Local isThinking: boolean = false;
  /** 滚动控制器 */
  private scroller: Scroller = new Scroller();
  /** 百炼智能体会话 ID（首轮为空，由百炼返回后填充，用于多轮对话） */
  private sessionId: string = '';

  /** 快捷提问 */
  private quickPrompts: QuickPrompt[] = [
    { icon: '📈', label: '如何提高销量?', content: '最近草莓销量下降了, 怎么办?' },
    { icon: '🌾', label: '今天适合采摘吗?', content: '今天适合采摘吗?' },
    { icon: '🐛', label: '病虫害防治', content: '番茄叶子发黄, 怎么防治?' },
    { icon: '📹', label: '直播话术', content: '帮我写个草莓直播话术' },
    { icon: '💰', label: '价格建议', content: '草莓定价多少合适?' }
  ];

  aboutToAppear(): void {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'agent_page_appear' });
    this.initConversation();
  }

  /** 初始化对话 */
  private initConversation(): void {
    this.sessionId = '';
    this.messages = [
      {
        msgId: 'm1',
        role: 'ai',
        type: 'text',
        content: '你好, 王大叔! 我是你的AI农业助手。有什么可以帮你的吗? 可以问我种植技巧、销售建议、直播话术等问题。'
      }
    ];
  }

  /** 清空对话 */
  private clearConversation(): void {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'agent_clear_chat' });
    this.initConversation();
    ToastUtil.info('已清空对话');
  }

  /** 发送消息 */
  private async sendMessage(text: string): Promise<void> {
    if (text.trim().length === 0 || this.isThinking) {
      return;
    }
    // 添加用户消息
    const userMsg: ChatMessage = {
      msgId: `u${Date.now()}`,
      role: 'user',
      type: 'text',
      content: text.trim()
    };
    this.messages.push(userMsg);
    this.inputText = '';
    Logger.info(AppConstants.SCENE_FARMER, { action: 'agent_user_send', msg: text.trim() });

    // 调用百炼 AI 助手智能体
    this.isThinking = true;
    try {
      const result = await BailianClient.chatWithAgent(text.trim(), this.sessionId);
      this.sessionId = result.sessionId;
      this.isThinking = false;
      const aiMsg: ChatMessage = {
        msgId: `a${Date.now()}`,
        role: 'ai',
        type: 'text',
        content: result.text.length > 0 ? result.text : '我暂时无法回答这个问题，请稍后重试。'
      };
      this.messages.push(aiMsg);
    } catch (err) {
      this.isThinking = false;
      const errMsg: string = (err as Error).message ?? 'AI 助手调用失败';
      Logger.error(AppConstants.SCENE_FARMER, { action: 'agent_call_fail', error: errMsg });
      const aiMsg: ChatMessage = {
        msgId: `a${Date.now()}`,
        role: 'ai',
        type: 'text',
        content: `抱歉，AI 助手暂时无法响应：${errMsg}`
      };
      this.messages.push(aiMsg);
      ToastUtil.info(`AI 助手调用失败：${errMsg}`);
    }
  }

  /** 点击建议卡片按钮 */
  private onSuggestClick(route: string): void {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'agent_suggest_click', url: route });
    if (route.length > 0) {
      NavigationHelper.push(route);
    }
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        this.AgentIntroCard()
        this.ChatArea()
        this.QuickChipsBar()
        this.InputBar()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 顶部导航栏 */
  @Builder
  TopBar() {
    Row() {
      Text('‹')
        .fontSize(28)
        .fontColor($r('app.color.color_text_primary'))
        .width(40)
        .height(40)
        .textAlign(TextAlign.Center)
        .onClick(() => NavigationHelper.pop())
      Text('AI 助手')
        .fontSize(18)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Text('清空')
        .fontSize(12)
        .fontColor($r('app.color.color_text_secondary'))
        .width(40)
        .height(40)
        .textAlign(TextAlign.Center)
        .onClick(() => this.clearConversation())
    }
    .width('100%')
    .height(56)
    .padding({ left: 12, right: 12 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** 黄色助手介绍卡 */
  @Builder
  AgentIntroCard() {
    Row({ space: 12 }) {
      // AI 头像
      Image(ImageUtil.get('mascot_farmer'))
        .width(48)
        .height(48)
        .borderRadius(24)
        .objectFit(ImageFit.Cover)
        .border({ width: 2, color: Color.White })
      // 名称 + 副标题
      Column({ space: 2 }) {
        Text('趣农AI助手')
          .fontSize(16)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        Text('你的智能农业顾问')
          .fontSize(12)
          .fontColor('rgba(26,26,26,0.6)')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      // 在线状态
      Row({ space: 4 }) {
        Text('')
          .width(6)
          .height(6)
          .borderRadius(3)
          .backgroundColor($r('app.color.color_primary'))
        Text('在线')
          .fontSize(11)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Medium)
      }
      .padding({ left: 8, right: 10, top: 4, bottom: 4 })
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor('rgba(255,255,255,0.5)')
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_yellow'))
    .alignItems(VerticalAlign.Center)
  }

  /** 对话区域 */
  @Builder
  ChatArea() {
    Scroll(this.scroller) {
      Column({ space: 16 }) {
        ForEach(this.messages, (msg: ChatMessage) => {
          this.AiMessage(msg)
          this.UserMessage(msg)
        }, (msg: ChatMessage) => msg.msgId)
        // 思考中提示
        this.ThinkingIndicator()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .align(Alignment.TopStart)
  }

  /** AI 消息（左侧 + 头像） */
  @Builder
  AiMessage(msg: ChatMessage) {
    Row({ space: 8 }) {
      // AI 头像
      Image(ImageUtil.get('mascot_farmer'))
        .width(32)
        .height(32)
        .borderRadius(16)
        .objectFit(ImageFit.Cover)
      // 消息气泡 + 建议卡片
      Column({ space: 8 }) {
        // 气泡
        Column({ space: 8 }) {
          Text(msg.content)
            .fontSize(13)
            .fontColor($r('app.color.color_text_primary'))
            .lineHeight(20)
          // 引用块（话术）
          if (msg.quote) {
            Text(msg.quote)
              .fontSize(12)
              .fontColor('rgba(26,26,26,0.7)')
              .fontStyle(FontStyle.Italic)
              .lineHeight(18)
              .padding(10)
              .borderRadius(8)
              .backgroundColor('rgba(255,255,255,0.6)')
              .border({ width: 1, color: 'rgba(26,26,26,0.1)' })
              .width('100%')
          }
        }
        .padding(12)
        .borderRadius(AppConstants.RADIUS_LG)
        .backgroundColor($r('app.color.color_bg_card'))
        .shadow(AppConstants.SHADOW_CARD)
        .alignItems(HorizontalAlign.Start)

        // 建议卡片
        if (msg.type === 'suggest' && msg.suggest) {
          this.SuggestCard(msg.suggest)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .visibility(msg.role === 'ai' ? Visibility.Visible : Visibility.None)
  }

  /** 用户消息（右侧 + 头像） */
  @Builder
  UserMessage(msg: ChatMessage) {
    Row({ space: 8 }) {
      // 消息气泡
      Column() {
        Text(msg.content)
          .fontSize(13)
          .fontColor($r('app.color.color_ink'))
          .lineHeight(20)
      }
      .padding(12)
      .borderRadius(AppConstants.RADIUS_LG)
      .backgroundColor($r('app.color.color_yellow'))
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 用户头像
      Image(ImageUtil.get('avatar_farmer'))
        .width(32)
        .height(32)
        .borderRadius(16)
        .objectFit(ImageFit.Cover)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .visibility(msg.role === 'user' ? Visibility.Visible : Visibility.None)
  }

  /** 建议卡片 */
  @Builder
  SuggestCard(suggest: ChatSuggest) {
    Column({ space: 8 }) {
      // 标题行
      Row({ space: 6 }) {
        Text('✨')
          .fontSize(16)
        Text(suggest.title)
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 描述行（含预期提升）
      Row({ space: 4 }) {
        Text('↑')
          .fontSize(11)
          .fontColor($r('app.color.color_primary'))
        Text('预计提升')
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
        Text(suggest.uplift)
          .fontSize(11)
          .fontColor($r('app.color.color_primary'))
          .fontWeight(FontWeight.Bold)
        Text('销量')
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
        Blank()
        Text(suggest.desc)
          .fontSize(11)
          .fontColor($r('app.color.color_text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 操作按钮
      Row({ space: 4 }) {
        Text(suggest.btnLabel)
          .fontSize(12)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        Text('›')
          .fontSize(12)
          .fontColor($r('app.color.color_ink'))
      }
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor($r('app.color.color_yellow'))
      .onClick(() => this.onSuggestClick(suggest.route))
    }
    .width('100%')
    .padding(12)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_yellow_tint'))
    .border({ width: 1, color: $r('app.color.color_yellow_soft') })
    .alignItems(HorizontalAlign.Start)
  }

  /** 思考中指示器 */
  @Builder
  ThinkingIndicator() {
    Row({ space: 8 }) {
      Image(ImageUtil.get('mascot_farmer'))
        .width(32)
        .height(32)
        .borderRadius(16)
        .objectFit(ImageFit.Cover)
      Row({ space: 4 }) {
        Text('.')
          .fontSize(20)
          .fontColor($r('app.color.color_text_hint'))
        Text('.')
          .fontSize(20)
          .fontColor($r('app.color.color_text_hint'))
        Text('.')
          .fontSize(20)
          .fontColor($r('app.color.color_text_hint'))
      }
      .padding(12)
      .borderRadius(AppConstants.RADIUS_LG)
      .backgroundColor($r('app.color.color_bg_card'))
      .shadow(AppConstants.SHADOW_CARD)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .visibility(this.isThinking ? Visibility.Visible : Visibility.None)
  }

  /** 快捷提问芯片栏 */
  @Builder
  QuickChipsBar() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.quickPrompts, (prompt: QuickPrompt) => {
          Row({ space: 4 }) {
            Text(prompt.icon)
              .fontSize(11)
            Text(prompt.label)
              .fontSize(11)
              .fontColor($r('app.color.color_text_secondary'))
          }
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_bg_card'))
          .border({ width: 1, color: $r('app.color.color_divider') })
          .onClick(() => { this.sendMessage(prompt.content); })
        }, (prompt: QuickPrompt) => prompt.label)
      }
      .padding({ left: 16, right: 16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }

  /** 底部输入栏 */
  @Builder
  InputBar() {
    Row({ space: 8 }) {
      // 语音按钮
      Text('🎤')
        .fontSize(20)
        .width(36)
        .height(36)
        .borderRadius(18)
        .backgroundColor($r('app.color.color_bg_card'))
        .textAlign(TextAlign.Center)
        .onClick(() => ToastUtil.info('语音输入功能开发中'))
      // 输入框
      TextInput({ text: this.inputText, placeholder: '输入你的问题...' })
        .layoutWeight(1)
        .height(36)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor($r('app.color.color_bg_card'))
        .padding({ left: 14, right: 14 })
        .fontSize(13)
        .onChange((v: string) => { this.inputText = v; })
        .onSubmit(() => { this.sendMessage(this.inputText); })
      // 发送按钮
      Text('↑')
        .fontSize(18)
        .fontColor(Color.White)
        .width(36)
        .height(36)
        .borderRadius(18)
        .backgroundColor($r('app.color.color_cta_black'))
        .textAlign(TextAlign.Center)
        .onClick(() => { this.sendMessage(this.inputText); })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }
}
