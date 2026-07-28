/**
 * live_room - 直播间页（对齐设计稿 user-live.html）
 *  - 全屏直播背景图 + 渐变遮罩
 *  - 顶部：圆形毛玻璃返回 + LIVE 胶囊(闪烁圆点) + 观看人数 + 圆形分享
 *  - 右侧互动列：点赞(红渐变) + 礼物(黄渐变) + 购物车(白底带角标)
 *  - 右侧聊天气泡：半透明毛玻璃 + 彩色圆点
 *  - 底部白色浮层：主播信息(黄色光环头像) + 商品卡 + 输入栏(黄发送按钮)
 *  - 保留：商品袋弹窗 / 礼物面板弹窗 / 评论发送 / 关注 / 点赞
 */

import { RouteName, NavigationHelper, Logger, AppConstants, ToastUtil } from 'common';
import { LiveInfo, LiveComment, LiveGift, LiveBagItem } from '../../model/LiveModels';
import { getMockLiveById, getMockLiveComments, getMockLiveBag, MOCK_GIFTS, toggleMockFollow, sendMockGift, likeMockLive } from '../../mock/LiveMock';
import { ImageUtil } from '../../utils/ImageUtil';
import { ReplaceableImage } from '../../components/ReplaceableImage';

/** 跳转商品详情的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface ProductDetailParam {
  productId: string;
}

/** 聊天气泡展示数据（对齐设计稿 qn-chat-bubble） */
interface ChatBubbleData {
  /** 评论 ID */
  commentId: string;
  /** 用户昵称 */
  nickname: string;
  /** 评论内容 */
  content: string;
  /** 头像圆点颜色（#RRGGBB） */
  dotColor: string;
}

/** 商品卡数据（对齐设计稿 qn-live-prod） */
interface LiveProductCard {
  /** 商品 ID */
  productId: string;
  /** 商品名 */
  name: string;
  /** 主图 key */
  mainImage: string;
  /** 价格 */
  price: number;
}

@ComponentV2
export struct LiveRoom {
  /** 直播 ID */
  @Local liveId: string = '';
  /** 直播详情 */
  @Local live: LiveInfo | null = null;
  /** 评论列表 */
  @Local comments: LiveComment[] = [];
  /** 商品袋 */
  @Local bags: LiveBagItem[] = [];
  /** 礼物列表 */
  @Local gifts: LiveGift[] = MOCK_GIFTS;
  /** 输入框文案 */
  @Local inputText: string = '';
  /** 是否显示商品袋弹窗 */
  @Local showBagPanel: boolean = false;
  /** 是否显示礼物面板弹窗 */
  @Local showGiftPanel: boolean = false;
  /** 用户金币余额（Mock） */
  @Local coins: number = 888;
  /** 当前点赞数 */
  @Local likeCount: number = 0;
  /** 是否已关注 */
  @Local isFollowing: boolean = false;
  /** 礼物特效（最近一次送礼，触发动画） */
  @Local giftEffect: LiveGift | null = null;

  /** 聊天气泡颜色池（对齐设计稿：4 种彩色圆点） */
  private readonly chatColors: string[] = ['#FF6B6B', '#7ED321', '#4A90E2', '#FF9F1C'];

  aboutToAppear(): void {
    const params: Record<string, string> = NavigationHelper.getParam<Record<string, string>>() as Record<string, string>;
    if (params) {
      this.liveId = params.liveId ?? '';
    }
    this.loadLiveDetail();
  }

  /** 加载直播间数据 */
  private loadLiveDetail(): void {
    const live: LiveInfo | null = getMockLiveById(this.liveId);
    if (!live) {
      ToastUtil.error('直播间不存在');
      NavigationHelper.pop();
      return;
    }
    this.live = live;
    this.likeCount = live.likeCount;
    this.isFollowing = live.isFollowing;
    this.comments = getMockLiveComments(this.liveId, 20);
    this.bags = getMockLiveBag(this.liveId);
    Logger.info(AppConstants.SCENE_USER, {
      action: 'live_room_view',
      liveId: this.liveId,
      count: this.comments.length
    });
  }

  /** 返回上一页 */
  private goBack(): void {
    NavigationHelper.pop();
  }

  /** 切换关注 */
  private onToggleFollow(): void {
    const newFollowing: boolean = toggleMockFollow(this.liveId);
    this.isFollowing = newFollowing;
    ToastUtil.success(newFollowing ? '已关注主播' : '已取消关注');
    Logger.info(AppConstants.SCENE_USER, {
      action: 'live_follow_toggle',
      liveId: this.liveId,
      following: newFollowing
    });
  }

  /** 点赞 */
  private onLike(): void {
    this.likeCount = likeMockLive(this.liveId);
  }

  /** 发送评论 */
  private onSendComment(): void {
    const text: string = this.inputText.trim();
    if (text.length === 0) {
      ToastUtil.warning('请输入评论内容');
      return;
    }
    const newComment: LiveComment = {
      commentId: `self_${Date.now()}`,
      liveId: this.liveId,
      userId: 'u_self',
      nickname: '我',
      avatar: 'avatar_default',
      content: text,
      isSelf: true,
      createdAt: Date.now()
    };
    this.comments.push(newComment);
    this.inputText = '';
    Logger.info(AppConstants.SCENE_USER, {
      action: 'live_comment_send',
      liveId: this.liveId,
      length: text.length
    });
  }

  /** 送礼物 */
  private onSendGift(gift: LiveGift): void {
    if (this.coins < gift.price) {
      ToastUtil.error('金币不足');
      return;
    }
    this.coins -= gift.price;
    sendMockGift(this.liveId, gift, 1, '我');
    this.giftEffect = gift;
    setTimeout(() => {
      this.giftEffect = null;
    }, 1200);
    this.showGiftPanel = false;
    ToastUtil.success(`送出 ${gift.icon} ${gift.name} x1`);
    Logger.info(AppConstants.SCENE_USER, {
      action: 'live_gift_send',
      liveId: this.liveId,
      giftId: gift.giftId,
      amount: gift.price
    });
  }

  /** 商品袋点击 → 跳商品详情 */
  private onBagItemClick(productId: string): void {
    this.showBagPanel = false;
    const param: ProductDetailParam = { productId: productId };
    NavigationHelper.push(RouteName.USER_PRODUCT_DETAIL, param);
  }

  /** 立即购买（底部商品卡） */
  private onBuyNow(): void {
    if (this.bags.length === 0) {
      return;
    }
    const bag: LiveBagItem = this.bags[0];
    this.onBagItemClick(bag.productId);
  }

  /** 跳转主播店铺（复用商品详情入口） */
  private gotoShop(): void {
    if (this.live && this.live.productBag.length > 0) {
      const param: ProductDetailParam = { productId: this.live.productBag[0] };
      NavigationHelper.push(RouteName.USER_PRODUCT_DETAIL, param);
    }
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        // 1. 全屏直播背景 + 渐变遮罩（对齐设计稿 qn-live-bg + qn-live-gradient）
        if (this.live) {
          this.LiveBackground()
        }

        // 2. 顶部叠加层（对齐设计稿 qn-live-top）
        if (this.live) {
          this.TopOverlay()
        }

        // 3. 右侧互动按钮列（对齐设计稿 qn-live-actions）
        if (this.live) {
          this.RightActionColumn()
        }

        // 4. 右侧浮动聊天（对齐设计稿 qn-live-chat）
        if (this.live) {
          this.ChatBubbles()
        }

        // 5. 底部白色浮层（对齐设计稿 qn-live-bottom）
        if (this.live) {
          this.BottomPanel()
        }

        // 6. 礼物特效浮层
        if (this.giftEffect) {
          this.GiftEffectOverlay(this.giftEffect)
        }

        // 7. 预告状态遮罩
        if (this.live && this.live.status === 'preview') {
          this.PreviewOverlay(this.live)
        }

        // 8. 已结束状态遮罩
        if (this.live && this.live.status === 'ended') {
          this.EndedOverlay(this.live)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#000000')
      // 商品袋弹窗
      .bindSheet($$this.showBagPanel, this.BagSheetBuilder(), {
        height: '60%',
        dragBar: true,
        backgroundColor: $r('app.color.color_bg_card')
      })
      // 礼物面板弹窗
      .bindSheet($$this.showGiftPanel, this.GiftSheetBuilder(), {
        height: '50%',
        dragBar: true,
        backgroundColor: $r('app.color.color_bg_card')
      })
    }
    .hideTitleBar(true)
  }

  /** 全屏直播背景 + 渐变遮罩（对齐设计稿 qn-live-bg + qn-live-gradient） */
  @Builder
  LiveBackground() {
    Stack() {
      // 背景图（占位直播画面）
      ReplaceableImage({ imageKey: this.live!.coverImage, imgWidth: '100%', imgHeight: '100%', imgFit: ImageFit.Cover })

      // 渐变遮罩（顶底深、中间透，对齐设计稿 qn-live-gradient）
      Column() {
        // 顶部渐变
        Column()
          .width('100%')
          .height(160)
          .linearGradient({
            direction: GradientDirection.Bottom,
            colors: [['rgba(0,0,0,0.55)', 0], ['rgba(0,0,0,0.18)', 0.5], ['rgba(0,0,0,0)', 1]]
          })
        Blank()
        // 底部渐变
        Column()
          .width('100%')
          .height(200)
          .linearGradient({
            direction: GradientDirection.Top,
            colors: [['rgba(0,0,0,0.45)', 0], ['rgba(0,0,0,0.18)', 0.5], ['rgba(0,0,0,0)', 1]]
          })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
    .height('100%')
  }

  /** 顶部叠加层（对齐设计稿 qn-live-top：圆形返回 + LIVE胶囊 + 观看人数 + 圆形分享） */
  @Builder
  TopOverlay() {
    Row() {
      // 左：圆形毛玻璃返回按钮（对齐设计稿 qn-live-circle）
      Text('←')
        .fontSize(22)
        .fontColor(Color.White)
        .width(36)
        .height(36)
        .textAlign(TextAlign.Center)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor('rgba(26,26,26,0.42)')
        .onClick(() => {
          this.goBack();
        })

      // 中：LIVE 胶囊 + 观看人数（对齐设计稿 qn-live-top-center）
      Row({ space: 8 }) {
        // LIVE 胶囊（对齐设计稿 qn-live-pill：红底 + 白色闪烁圆点）
        Row({ space: 5 }) {
          Text('●')
            .fontSize(8)
            .fontColor(Color.White)
          Text('LIVE')
            .fontSize(11)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
        }
        .padding({ left: 9, right: 10, top: 4, bottom: 4 })
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor($r('app.color.color_live'))
        .shadow({ radius: 8, color: 'rgba(255,77,79,0.45)', offsetX: 0, offsetY: 2 })

        // 观看人数
        Text(`${this.formatCount(this.live!.onlineCount)}人在看`)
          .fontSize(13)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)

      // 右：圆形毛玻璃分享按钮（对齐设计稿 qn-live-circle）
      Text('↗')
        .fontSize(18)
        .fontColor(Color.White)
        .width(36)
        .height(36)
        .textAlign(TextAlign.Center)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor('rgba(26,26,26,0.42)')
        .onClick(() => {
          ToastUtil.info('分享功能开发中');
        })
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 44, bottom: 12 })
    .alignItems(VerticalAlign.Center)
  }

  /** 右侧互动按钮列（对齐设计稿 qn-live-actions：点赞 + 礼物 + 购物车） */
  @Builder
  RightActionColumn() {
    Column({ space: 16 }) {
      // 点赞（对齐设计稿 qn-live-ico.like：红渐变圆）
      Column({ space: 3 }) {
        Text('♥')
          .fontSize(24)
          .fontColor(Color.White)
          .width(46)
          .height(46)
          .textAlign(TextAlign.Center)
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor('#FF4D4F')
          .shadow({ radius: 12, color: 'rgba(0,0,0,0.28)', offsetX: 0, offsetY: 4 })
          .onClick(() => {
            this.onLike();
          })
        Text(this.formatCount(this.likeCount))
          .fontSize(11)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
      }
      .alignItems(HorizontalAlign.Center)

      // 礼物（对齐设计稿 qn-live-ico.gift：黄渐变圆）
      Column({ space: 3 }) {
        Text('🎁')
          .fontSize(22)
          .width(46)
          .height(46)
          .textAlign(TextAlign.Center)
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_primary'))
          .shadow({ radius: 12, color: 'rgba(0,0,0,0.28)', offsetX: 0, offsetY: 4 })
          .onClick(() => {
            this.showGiftPanel = true;
          })
        Text('礼物')
          .fontSize(11)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
      }
      .alignItems(HorizontalAlign.Center)

      // 购物车（对齐设计稿 qn-live-ico.cart：白底圆 + 红色角标）
      Stack({ alignContent: Alignment.TopEnd }) {
        Column({ space: 3 }) {
          Text('🛒')
            .fontSize(22)
            .width(46)
            .height(46)
            .textAlign(TextAlign.Center)
            .borderRadius(AppConstants.RADIUS_PILL)
            .backgroundColor(Color.White)
            .shadow({ radius: 12, color: 'rgba(0,0,0,0.28)', offsetX: 0, offsetY: 4 })
          Text('购物车')
            .fontSize(11)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
        }
        .alignItems(HorizontalAlign.Center)

        // 角标（对齐设计稿 qn-badge）
        if (this.bags.length > 0) {
          Text(`${this.bags.length}`)
            .fontSize(10)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .height(17)
            .padding({ left: 4, right: 4 })
            .borderRadius(AppConstants.RADIUS_PILL)
            .backgroundColor($r('app.color.color_live'))
            .border({ width: 2, color: Color.White })
            .textAlign(TextAlign.Center)
            .markAnchor({ x: 17, y: 0 })
            .position({ x: 32, y: -4 })
        }
      }
      .width(46)
      .onClick(() => {
        this.showBagPanel = true;
      })
    }
    .position({ right: 12, bottom: 330 })
    .alignItems(HorizontalAlign.Center)
  }

  /** 右侧浮动聊天气泡（对齐设计稿 qn-live-chat） */
  @Builder
  ChatBubbles() {
    Column({ space: 8 }) {
      ForEach(this.getChatBubbles(), (bubble: ChatBubbleData, index: number) => {
        Row({ space: 6 }) {
          // 彩色圆点（对齐设计稿 qn-chat-dot）
          Text('')
            .width(18)
            .height(18)
            .borderRadius(AppConstants.RADIUS_PILL)
            .backgroundColor(bubble.dotColor)
            .border({ width: 1.5, color: 'rgba(255,255,255,0.5)' })
          // 评论文字
          Text(bubble.content)
            .fontSize(12)
            .fontColor(Color.White)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .padding({ left: 5, right: 12, top: 5, bottom: 5 })
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor('rgba(26,26,26,0.42)')
        .alignItems(VerticalAlign.Center)
      }, (bubble: ChatBubbleData) => `${bubble.commentId}_${bubble.content}`)
    }
    .position({ right: 12, bottom: 210 })
    .alignItems(HorizontalAlign.End)
  }

  /** 底部白色浮层（对齐设计稿 qn-live-bottom：主播信息 + 商品卡 + 输入栏） */
  @Builder
  BottomPanel() {
    Column() {
      // 主播信息行（对齐设计稿 qn-streamer-row）
      this.StreamerRow()

      // 商品卡（对齐设计稿 qn-live-prod）
      if (this.bags.length > 0) {
        this.LiveProductCardView(this.bags[0])
      }

      // 底部输入栏（对齐设计稿 qn-live-input）
      this.InputBar()
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius({ topLeft: AppConstants.RADIUS_LG, topRight: AppConstants.RADIUS_LG })
    .shadow({ radius: 24, color: 'rgba(0,0,0,0.2)', offsetX: 0, offsetY: -6 })
    .markAnchor({ x: 0, y: '100%' })
    .position({ x: 0, y: '100%' })
  }

  /** 主播信息行（对齐设计稿 qn-streamer-row：头像黄色光环 + 名称 + 地址 + 正在讲解 + 关注） */
  @Builder
  StreamerRow() {
    Row({ space: 10 }) {
      // 头像（对齐设计稿 qn-avatar-ring：双层光环）
      Stack() {
        Image(ImageUtil.get(this.live!.anchorAvatar))
          .width(40)
          .height(40)
          .borderRadius(AppConstants.RADIUS_PILL)
          .objectFit(ImageFit.Cover)
          .border({ width: 3, color: $r('app.color.color_bg_card') })
      }
      .width(46)
      .height(46)
      .borderRadius(AppConstants.RADIUS_PILL)
      .border({ width: 3, color: $r('app.color.color_yellow') })
      .alignContent(Alignment.Center)
      .onClick(() => {
        this.gotoShop();
      })

      // 名称 + 地址
      Column({ space: 3 }) {
        Text(this.live!.anchorName)
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.live!.intro)
          .fontSize(11)
          .fontColor($r('app.color.color_text_3'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // "正在讲解" 绿色胶囊（对齐设计稿 qn-pill-green）
      Row({ space: 3 }) {
        Text('✓')
          .fontSize(10)
          .fontColor($r('app.color.color_green_deep'))
        Text('正在讲解')
          .fontSize(11)
          .fontColor($r('app.color.color_green_deep'))
          .fontWeight(FontWeight.Bold)
      }
      .padding({ left: 7, right: 7, top: 3, bottom: 3 })
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor($r('app.color.color_green_soft'))

      // 关注按钮（对齐设计稿 qn-follow-btn：黄底黑字）
      Text(this.isFollowing ? '已关注' : '+ 关注')
        .fontSize(12)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .height(30)
        .padding({ left: 16, right: 16 })
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor(this.isFollowing ? $r('app.color.color_fill') : $r('app.color.color_primary'))
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.onToggleFollow();
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  /** 商品卡（对齐设计稿 qn-live-prod：60×60 图 + 名称 + 价格 + 立即购买） */
  @Builder
  LiveProductCardView(bag: LiveBagItem) {
    Row({ space: 10 }) {
      // 商品缩略图（对齐设计稿 qn-prod-thumb：60×60 圆角）
      Image(ImageUtil.get(bag.mainImage))
        .width(60)
        .height(60)
        .borderRadius(AppConstants.RADIUS_SM)
        .objectFit(ImageFit.Cover)

      // 商品信息（对齐设计稿 qn-prod-info）
      Column({ space: 3 }) {
        Text(bag.title)
          .fontSize(13)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        // 价格（对齐设计稿 qn-prod-price：¥小 + 数字大）
        Row({ space: 1 }) {
          Text('¥')
            .fontSize(11)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
          Text(bag.price.toFixed(1))
            .fontSize(17)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
        }
        .alignItems(VerticalAlign.Bottom)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 立即购买按钮（对齐设计稿 qn-btn-buy：黑底白字胶囊）
      Text('立即购买')
        .fontSize(13)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .height(38)
        .padding({ left: 16, right: 16 })
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor($r('app.color.color_ink'))
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.onBuyNow();
        })
    }
    .width('100%')
    .padding(8)
    .margin({ top: 12 })
    .borderRadius(AppConstants.RADIUS_MD)
    .backgroundColor($r('app.color.color_fill'))
    .alignItems(VerticalAlign.Center)
  }

  /** 底部输入栏（对齐设计稿 qn-live-input：输入框 + 表情 + 黄色发送） */
  @Builder
  InputBar() {
    Row({ space: 8 }) {
      // 输入框（对齐设计稿 qn-input-field：胶囊形灰底）
      TextInput({ text: this.inputText, placeholder: '说点什么...' })
        .fontSize(13)
        .fontColor($r('app.color.color_ink'))
        .placeholderColor($r('app.color.color_text_4'))
        .placeholderFont({ size: 13 })
        .backgroundColor($r('app.color.color_fill'))
        .borderRadius(AppConstants.RADIUS_PILL)
        .padding({ left: 14, right: 14 })
        .height(36)
        .layoutWeight(1)
        .onChange((value: string) => {
          this.inputText = value;
        })
        .onSubmit(() => {
          this.onSendComment();
        })

      // 表情图标（对齐设计稿 qn-input-ico：圆形灰底）
      Text('😊')
        .fontSize(18)
        .width(36)
        .height(36)
        .textAlign(TextAlign.Center)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor($r('app.color.color_fill'))

      // 发送按钮（对齐设计稿 qn-send-btn：黄底黑字胶囊）
      Text('发送')
        .fontSize(13)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .height(36)
        .padding({ left: 16, right: 16 })
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor($r('app.color.color_primary'))
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.onSendComment();
        })
    }
    .width('100%')
    .margin({ top: 12 })
    .alignItems(VerticalAlign.Center)
  }

  /** 商品袋弹窗内容 */
  @Builder
  BagSheetBuilder() {
    Column({ space: 0 }) {
      // 标题栏
      Row() {
        Text(`直播间商品 (${this.bags.length})`)
          .fontSize(16)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text('✕')
          .fontSize(20)
          .fontColor($r('app.color.color_text_3'))
          .onClick(() => {
            this.showBagPanel = false;
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      // 商品列表
      List({ space: 8 }) {
        ForEach(this.bags, (bag: LiveBagItem) => {
          ListItem() {
            this.BagItemRow(bag)
          }
        }, (bag: LiveBagItem) => bag.productId)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 16, right: 16, bottom: 16 })
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
  }

  /** 商品袋商品行 */
  @Builder
  BagItemRow(bag: LiveBagItem) {
    Row({ space: 12 }) {
      // 序号徽章
      Text(`${bag.seq}`)
        .fontSize(12)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.color_ink'))
        .width(22)
        .height(22)
        .borderRadius(AppConstants.RADIUS_PILL)
        .textAlign(TextAlign.Center)
      // 商品图
      Image(ImageUtil.get(bag.mainImage))
        .width(56)
        .height(56)
        .borderRadius(AppConstants.RADIUS_SM)
        .objectFit(ImageFit.Cover)
      // 标题 + 价格
      Column({ space: 4 }) {
        Text(bag.title)
          .fontSize(13)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Medium)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 1 }) {
          Text('¥')
            .fontSize(11)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
          Text(bag.price.toFixed(1))
            .fontSize(16)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
        }
        .alignItems(VerticalAlign.Bottom)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 查看详情按钮
      Text('查看')
        .fontSize(12)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.color_ink'))
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .borderRadius(AppConstants.RADIUS_SM)
    }
    .width('100%')
    .padding(12)
    .borderRadius(AppConstants.RADIUS_MD)
    .backgroundColor($r('app.color.color_fill'))
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.onBagItemClick(bag.productId);
    })
  }

  /** 礼物面板弹窗内容 */
  @Builder
  GiftSheetBuilder() {
    Column({ space: 0 }) {
      // 标题栏 + 金币余额
      Row() {
        Text('选择礼物')
          .fontSize(16)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text(`金币余额: ${this.coins}`)
          .fontSize(13)
          .fontColor($r('app.color.color_accent_gold'))
          .fontWeight(FontWeight.Bold)
        Text('✕')
          .fontSize(20)
          .fontColor($r('app.color.color_text_3'))
          .margin({ left: 12 })
          .onClick(() => {
            this.showGiftPanel = false;
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      // 礼物网格（3列）
      Grid() {
        ForEach(this.gifts, (gift: LiveGift) => {
          GridItem() {
            this.GiftGridItem(gift)
          }
        }, (gift: LiveGift) => gift.giftId)
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsGap(12)
      .columnsGap(12)
      .padding({ left: 16, right: 16, bottom: 24 })
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  /** 礼物网格项 */
  @Builder
  GiftGridItem(gift: LiveGift) {
    Column({ space: 6 }) {
      Text(gift.icon)
        .fontSize(40)
      Text(gift.name)
        .fontSize(12)
        .fontColor($r('app.color.color_ink'))
      Text(`💰 ${gift.price}`)
        .fontSize(11)
        .fontColor($r('app.color.color_accent_gold'))
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .borderRadius(AppConstants.RADIUS_MD)
    .backgroundColor($r('app.color.color_fill'))
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.onSendGift(gift);
    })
  }

  /** 礼物特效浮层 */
  @Builder
  GiftEffectOverlay(gift: LiveGift) {
    Column({ space: 8 }) {
      Text(gift.icon)
        .fontSize(80)
        .scale({ x: 1.2, y: 1.2 })
        .opacity(0.95)
      Text(`送出 ${gift.name}`)
        .fontSize(16)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('rgba(0,0,0,0.3)')
  }

  /** 预告状态遮罩 */
  @Builder
  PreviewOverlay(live: LiveInfo) {
    Column({ space: 8 }) {
      Text('📅 即将开播')
        .fontSize(20)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
      Text('主播正在准备中，点击预约开播提醒')
        .fontSize(13)
        .fontColor('rgba(255,255,255,0.8)')
      Text('预约直播')
        .fontSize(14)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.color_ink'))
        .padding({ left: 24, right: 24, top: 10, bottom: 10 })
        .borderRadius(AppConstants.RADIUS_PILL)
        .margin({ top: 12 })
        .onClick(() => {
          ToastUtil.success('预约成功，开播将提醒您');
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('rgba(0,0,0,0.4)')
  }

  /** 已结束状态遮罩 */
  @Builder
  EndedOverlay(live: LiveInfo) {
    Column({ space: 8 }) {
      Text('直播已结束')
        .fontSize(20)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
      Text(`累计观看 ${this.formatCount(live.totalViewUv)} 次`)
        .fontSize(13)
        .fontColor('rgba(255,255,255,0.8)')
      Text('返回列表')
        .fontSize(14)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.color_ink'))
        .padding({ left: 24, right: 24, top: 10, bottom: 10 })
        .borderRadius(AppConstants.RADIUS_PILL)
        .margin({ top: 12 })
        .onClick(() => {
          this.goBack();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('rgba(0,0,0,0.5)')
  }

  /** 获取聊天气泡展示数据（取最近 4 条，对齐设计稿 qn-live-chat） */
  private getChatBubbles(): ChatBubbleData[] {
    const list: ChatBubbleData[] = [];
    const recent: LiveComment[] = this.comments.slice(-4);
    recent.forEach((comment: LiveComment, index: number) => {
      list.push({
        commentId: comment.commentId,
        nickname: comment.nickname,
        content: comment.content,
        dotColor: this.chatColors[index % this.chatColors.length]
      });
    });
    return list;
  }

  /** 格式化数字（>=10000 显示万） */
  private formatCount(count: number): string {
    if (count >= 10000) {
      return `${(count / 10000).toFixed(1)}万`;
    }
    return `${count}`;
  }
}
