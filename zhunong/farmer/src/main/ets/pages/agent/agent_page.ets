/**
 * agent_page - 智能体页（spec 3.2.1 / 8.3）
 *
 * 现阶段仅搭建空白页面 + 预留全局接口调用层
 * 预留 AI 场景接口：
 *  - 智能商品介绍（TTS 语音合成）→ AiAgentClient.tts
 *  - 智能商品顺序推荐 → AiAgentClient.recommend
 *
 * 现阶段 Mock 策略：
 *  - TTS：返回预设音频文件 URL
 *  - 商品推荐：返回该卖家销量 Top5 商品
 */

import { Logger, AppConstants, ToastUtil, NavigationHelper, RouteName } from 'common';
import { AiTtsRequest, AiTtsResponse, AiRecommendRequest, AiRecommendResponse, AiRecommendItem } from '../../model/AiModels';
import { AiAgentClient } from '../../utils/AiAgentClient';
import { FarmerProductItem } from '../../model/FarmerModels';
import { MOCK_FARMER_ID, MOCK_FARMER_PRODUCTS } from '../../mock/FarmerMock';

/** 推荐商品展示项（含商品基础信息） */
interface RecommendDisplayItem {
  productId: string;
  reason: string;
  priority: number;
  productTitle: string;
  productPrice: number;
}

/** 音色选项 */
interface VoiceOption {
  value: string;
  label: string;
}

/** 商品选项（用于 Select 下拉） */
interface ProductOption {
  productId: string;
  title: string;
}

@ComponentV2
export struct AgentPage {
  /** 推荐结果列表 */
  @Local recommendList: RecommendDisplayItem[] = [];
  /** 是否正在加载推荐 */
  @Local isLoadingRecommend: boolean = false;
  /** 是否正在生成 TTS */
  @Local isGeneratingTts: boolean = false;
  /** TTS 输入文本 */
  @Local ttsText: string = '';
  /** 选中的音色 */
  @Local voiceType: string = 'female';
  /** TTS 结果 URL */
  @Local ttsAudioUrl: string = '';
  /** TTS 时长 */
  @Local ttsDuration: number = 0;
  /** 选中的商品 ID（用于 TTS） */
  @Local selectedProductId: string = '';

  /** 音色选项 */
  private voiceOptions: VoiceOption[] = [
    { value: 'female', label: '女声' },
    { value: 'male', label: '男声' },
    { value: 'dialect', label: '方言' }
  ];

  /** 商品选项（Mock：卖家在售商品） */
  private productOptions: ProductOption[] = MOCK_FARMER_PRODUCTS
    .filter((p: FarmerProductItem): boolean => p.status === 'approved')
    .map((p: FarmerProductItem): ProductOption => { return { productId: p.productId, title: p.title }; });

  async aboutToAppear(): Promise<void> {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'agent_page_appear' });
    if (this.productOptions.length > 0) {
      this.selectedProductId = this.productOptions[0].productId;
    }
  }

  /** 调用 TTS 接口（spec 8.3.1） */
  private async generateTts(): Promise<void> {
    if (this.ttsText.length === 0) {
      ToastUtil.warning('请输入待合成文本');
      return;
    }
    if (this.selectedProductId.length === 0) {
      ToastUtil.warning('请选择商品');
      return;
    }
    this.isGeneratingTts = true;
    this.ttsAudioUrl = '';
    try {
      const request: AiTtsRequest = {
        productId: this.selectedProductId,
        text: this.ttsText,
        voiceType: this.voiceType
      };
      const response: AiTtsResponse = await AiAgentClient.tts(request);
      this.ttsAudioUrl = response.audioUrl;
      this.ttsDuration = response.duration;
      ToastUtil.success(`语音合成完成，时长 ${response.duration}s`);
      Logger.info(AppConstants.SCENE_FARMER, { action: 'tts_success', duration: response.duration });
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'tts_fail', error: (err as Error).message });
      ToastUtil.error('语音合成失败');
    } finally {
      this.isGeneratingTts = false;
    }
  }

  /** 调用商品推荐接口（spec 8.3.2） */
  private async generateRecommend(): Promise<void> {
    this.isLoadingRecommend = true;
    this.recommendList = [];
    try {
      const request: AiRecommendRequest = {
        farmerId: MOCK_FARMER_ID,
        context: 'opening'
      };
      const response: AiRecommendResponse = await AiAgentClient.recommend(request);
      this.recommendList = response.recommendations.map((r: AiRecommendItem): RecommendDisplayItem => {
        const product: FarmerProductItem | undefined = MOCK_FARMER_PRODUCTS.find((p: FarmerProductItem): boolean => p.productId === r.productId);
        return {
          productId: r.productId,
          reason: r.reason,
          priority: r.priority,
          productTitle: product?.title ?? '商品',
          productPrice: product?.price ?? 0
        };
      });
      ToastUtil.success(`已生成 ${response.recommendations.length} 个推荐商品`);
      Logger.info(AppConstants.SCENE_FARMER, { action: 'recommend_success', count: response.recommendations.length });
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'recommend_fail', error: (err as Error).message });
      ToastUtil.error('推荐生成失败');
    } finally {
      this.isLoadingRecommend = false;
    }
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        Scroll() {
          Column({ space: 16 }) {
            this.HeaderCard()
            this.TtsCard()
            this.RecommendCard()
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 24 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
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
      Text('AI 智能体')
        .fontSize(18)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** 头部说明卡 */
  @Builder
  HeaderCard() {
    Column({ space: 8 }) {
      Text('🤖')
        .fontSize(48)
      Text('AI 智能体助手')
        .fontSize(18)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Bold)
      Text('为卖家提供智能商品介绍语音合成与商品顺序推荐')
        .fontSize(12)
        .fontColor($r('app.color.color_text_secondary'))
        .textAlign(TextAlign.Center)
      Text('当前阶段：接口层完整预留 + Mock 数据')
        .fontSize(11)
        .fontColor($r('app.color.color_text_hint'))
        .margin({ top: 4 })
    }
    .width('100%')
    .padding(20)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(HorizontalAlign.Center)
  }

  /** TTS 卡片（spec 8.3.1） */
  @Builder
  TtsCard() {
    Column({ space: 12 }) {
      Row() {
        Text('🔊 智能商品介绍 TTS')
          .fontSize(14)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text('spec 8.3.1')
          .fontSize(10)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')

      // 商品选择
      Column({ space: 6 }) {
        Text('选择商品')
          .fontSize(12)
          .fontColor($r('app.color.color_text_secondary'))
          .alignSelf(ItemAlign.Start)
        Select(this.productOptions.map((p: ProductOption): SelectOption => { return { value: p.title }; }))
          .selected(this.productOptions.findIndex((p: ProductOption) => p.productId === this.selectedProductId))
          .value(this.productOptions.find((p: ProductOption) => p.productId === this.selectedProductId)?.title ?? '请选择商品')
          .height(44)
          .borderRadius(8)
          .backgroundColor($r('app.color.color_bg_page'))
          .onSelect((idx: number) => {
            this.selectedProductId = this.productOptions[idx].productId;
          })
      }
      .width('100%')

      // 音色选择
      Column({ space: 6 }) {
        Text('音色')
          .fontSize(12)
          .fontColor($r('app.color.color_text_secondary'))
          .alignSelf(ItemAlign.Start)
        Row() {
          ForEach(this.voiceOptions, (opt: VoiceOption) => {
            Text(opt.label)
              .fontSize(12)
              .fontColor(this.voiceType === opt.value ? Color.White : $r('app.color.color_text_primary'))
              .backgroundColor(this.voiceType === opt.value ? $r('app.color.color_primary') : $r('app.color.color_bg_page'))
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .borderRadius(14)
              .margin({ right: 8 })
              .onClick(() => { this.voiceType = opt.value; })
          }, (opt: VoiceOption) => opt.value)
        }
        .width('100%')
      }
      .width('100%')

      // 待合成文本
      Column({ space: 6 }) {
        Text('介绍文案')
          .fontSize(12)
          .fontColor($r('app.color.color_text_secondary'))
          .alignSelf(ItemAlign.Start)
        TextArea({ text: this.ttsText, placeholder: '输入商品介绍文案，如：高山有机青菜，新鲜采摘，富含维生素...' })
          .height(80)
          .borderRadius(8)
          .backgroundColor($r('app.color.color_bg_page'))
          .padding({ left: 12, right: 12, top: 10, bottom: 10 })
          .fontSize(13)
          .maxLength(500)
          .onChange((v: string) => { this.ttsText = v; })
      }
      .width('100%')

      // 生成按钮
      Button(this.isGeneratingTts ? '合成中...' : '生成语音')
        .width('100%')
        .height(40)
        .borderRadius(20)
        .backgroundColor(this.isGeneratingTts ? $r('app.color.color_button_disabled') : $r('app.color.color_secondary'))
        .fontColor(Color.White)
        .fontSize(13)
        .enabled(!this.isGeneratingTts)
        .onClick(() => { this.generateTts(); })

      // TTS 结果
      if (this.ttsAudioUrl.length > 0) {
        Row({ space: 8 }) {
          Text('🔊')
            .fontSize(20)
          Column({ space: 2 }) {
            Text('合成成功')
              .fontSize(12)
              .fontColor($r('app.color.color_primary'))
              .fontWeight(FontWeight.Medium)
            Text(`时长：${this.ttsDuration}s · URL: ${this.ttsAudioUrl}`)
              .fontSize(10)
              .fontColor($r('app.color.color_text_hint'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding(10)
        .borderRadius(8)
        .backgroundColor($r('app.color.color_primary_light'))
        .opacity(0.3)
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 商品推荐卡片（spec 8.3.2） */
  @Builder
  RecommendCard() {
    Column({ space: 12 }) {
      Row() {
        Text('🎯 智能商品顺序推荐')
          .fontSize(14)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text('spec 8.3.2')
          .fontSize(10)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')
      Text('根据商品销量与直播间上下文，智能推荐讲解顺序')
        .fontSize(11)
        .fontColor($r('app.color.color_text_secondary'))
        .width('100%')

      Button(this.isLoadingRecommend ? '推荐中...' : '生成推荐')
        .width('100%')
        .height(40)
        .borderRadius(20)
        .backgroundColor(this.isLoadingRecommend ? $r('app.color.color_button_disabled') : $r('app.color.color_primary'))
        .fontColor(Color.White)
        .fontSize(13)
        .enabled(!this.isLoadingRecommend)
        .onClick(() => { this.generateRecommend(); })

      // 推荐结果
      ForEach(this.recommendList, (item: RecommendDisplayItem, _idx: number) => {
        Row({ space: 8 }) {
          Text(`${item.priority}`)
            .fontSize(14)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .width(28)
            .height(28)
            .borderRadius(14)
            .backgroundColor($r('app.color.color_secondary'))
            .textAlign(TextAlign.Center)
          Column({ space: 2 }) {
            Text(item.productTitle)
              .fontSize(13)
              .fontColor($r('app.color.color_text_primary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(item.reason)
              .fontSize(11)
              .fontColor($r('app.color.color_text_secondary'))
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Text(`¥${item.productPrice.toFixed(2)}`)
            .fontSize(12)
            .fontColor($r('app.color.color_price'))
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .padding(10)
        .borderRadius(8)
        .backgroundColor($r('app.color.color_bg_page'))
      }, (item: RecommendDisplayItem) => item.productId)
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }
}
