/**
 * live_room - 直播间页（仿抖音沉浸式，纯 UI 模拟）
 * 遵循 spec 3.1.4.2 / 2.4.6.3：
 *  - 全屏黑底 + 直播画面区（占位图片轮播）
 *  - 顶部：主播头像 + 昵称 + 关注按钮 + 在线人数 + 关闭按钮
 *  - 右侧悬浮：商品袋 / 礼物 / 分享 / 点赞
 *  - 底部：评论输入框 + 发送按钮 + 评论气泡滚动（自动滚到底）
 *  - 商品袋弹窗（bindSheet）：列表 + 点击跳商品详情/直接下单
 *  - 礼物面板弹窗（bindSheet）：选择礼物 + 消耗金币 + 礼物特效动画
 *  - 现阶段纯 UI 模拟，不集成真实推拉流 SDK
 */

import { UserRoutes, RouteName, NavigationHelper, Logger, AppConstants, ToastUtil } from 'common';
import { LiveInfo, LiveComment, LiveGift, LiveBagItem, getLiveStatusLabel, getLiveCategoryLabel } from '../../model/LiveModels';
import { getMockLiveById, getMockLiveComments, getMockLiveBag, MOCK_GIFTS, toggleMockFollow, sendMockGift, likeMockLive } from '../../mock/LiveMock';
import { ImageUtil } from '../../utils/ImageUtil';

/** 跳转商品详情的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface ProductDetailParam {
  productId: string;
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
  /** 是否显示分享菜单 */
  @Local showShareMenu: boolean = false;
  /** 用户金币余额（Mock） */
  @Local coins: number = 888;
  /** 当前点赞数 */
  @Local likeCount: number = 0;
  /** 是否已关注 */
  @Local isFollowing: boolean = false;
  /** 当前轮播图索引 */
  @Local currentImageIndex: number = 0;
  /** 礼物特效（最近一次送礼，触发动画） */
  @Local giftEffect: LiveGift | null = null;
  /** 评论列表 Scroller（自动滚到底） */
  private commentScroller: Scroller = new Scroller();

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
    // 直播中加载评论；预告/已结束也加载回放评论
    this.comments = getMockLiveComments(this.liveId, 20);
    this.bags = getMockLiveBag(this.liveId);
    Logger.info(AppConstants.SCENE_USER, JSON.stringify({
      action: 'live_room_view',
      liveId: this.liveId,
      status: live.status,
      commentCount: this.comments.length,
      bagCount: this.bags.length
    }));
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
    Logger.info(AppConstants.SCENE_USER, { action: 'live_follow_toggle', liveId: this.liveId, following: newFollowing });
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
    // 自动滚到底部
    setTimeout(() => {
      this.commentScroller.scrollEdge(Edge.Bottom);
    }, 100);
    Logger.info(AppConstants.SCENE_USER, { action: 'live_comment_send', liveId: this.liveId, length: text.length });
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
    // 1.2 秒后清除特效
    setTimeout(() => {
      this.giftEffect = null;
    }, 1200);
    this.showGiftPanel = false;
    ToastUtil.success(`送出 ${gift.icon} ${gift.name} x1`);
    Logger.info(AppConstants.SCENE_USER, JSON.stringify({
      action: 'live_gift_send',
      liveId: this.liveId,
      giftId: gift.giftId,
      amount: gift.price
    }));
  }

  /** 商品袋点击 → 跳商品详情 */
  private onBagItemClick(productId: string): void {
    this.showBagPanel = false;
    const param: ProductDetailParam = { productId: productId };
    NavigationHelper.push(RouteName.USER_PRODUCT_DETAIL, param);
  }

  /** 跳转主播店铺主页（复用商品详情店铺入口，暂跳商品详情） */
  private gotoShop(): void {
    if (this.live && this.live.productBag.length > 0) {
      const param: ProductDetailParam = { productId: this.live.productBag[0] };
      NavigationHelper.push(RouteName.USER_PRODUCT_DETAIL, param);
    }
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        // 全屏黑底 + 直播画面区
        Stack() {
          // 占位直播画面（图片轮播：封面 + 商品图）
          if (this.live) {
            Swiper() {
              ForEach(this.liveImageList(this.live), (imgKey: string, idx: number) => {
                Image(ImageUtil.get(imgKey))
                  .width('100%')
                  .height('100%')
                  .objectFit(ImageFit.Cover)
              }, (imgKey: string) => imgKey)
            }
            .indicator(false)
            .loop(true)
            .interval(4000)
            .width('100%')
            .height('100%')
            .onChange((index: number) => {
              this.currentImageIndex = index;
            })
          }
          // 黑色渐变遮罩（顶/底，增强浮层文字可读性）
          Column() {
            Column()
              .width('100%')
              .height(140)
              .linearGradient({
                direction: GradientDirection.Bottom,
                colors: [['rgba(0,0,0,0.6)', 0], ['rgba(0,0,0,0)', 1]]
              })
            Blank()
            Column()
              .width('100%')
              .height(260)
              .linearGradient({
                direction: GradientDirection.Top,
                colors: [['rgba(0,0,0,0.7)', 0], ['rgba(0,0,0,0)', 1]]
              })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#000000')

        // 顶部主播信息栏
        if (this.live) {
          this.TopAnchorBar(this.live)
        }

        // 右侧悬浮操作
        if (this.live) {
          this.RightActions(this.live)
        }

        // 底部评论 + 输入栏
        if (this.live) {
          this.BottomCommentBar(this.live)
        }

        // 礼物特效动画浮层
        if (this.giftEffect) {
          this.GiftEffectOverlay(this.giftEffect)
        }

        // 预告状态遮罩（预约提示）
        if (this.live && this.live.status === 'preview') {
          this.PreviewOverlay(this.live)
        }

        // 已结束状态遮罩
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

  /** 直播画面轮播图列表（封面 + 商品袋主图） */
  private liveImageList(live: LiveInfo): string[] {
    const images: string[] = [live.coverImage];
    this.bags.forEach((b: LiveBagItem) => {
      if (images.indexOf(b.mainImage) < 0) {
        images.push(b.mainImage);
      }
    });
    return images;
  }

  /** 顶部主播信息栏 */
  @Builder
  TopAnchorBar(live: LiveInfo) {
    Row({ space: 10 }) {
      // 关闭按钮
      Text('✕')
        .fontSize(20)
        .fontColor(Color.White)
        .onClick(() => {
          this.goBack();
        })

      // 主播头像
      Image(ImageUtil.get(live.anchorAvatar))
        .width(40)
        .height(40)
        .borderRadius(20)
        .border({ width: 2, color: Color.White })
        .onClick(() => {
          this.gotoShop();
        })

      // 昵称 + 在线人数
      Column({ space: 2 }) {
        Text(live.anchorName)
          .fontSize(14)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
        Text(this.formatOnlineText(live))
          .fontSize(11)
          .fontColor('rgba(255,255,255,0.8)')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 关注按钮
      Text(this.isFollowing ? '已关注' : '+ 关注')
        .fontSize(12)
        .fontColor(this.isFollowing ? Color.White : $r('app.color.color_primary'))
        .backgroundColor(this.isFollowing ? 'rgba(255,255,255,0.2)' : Color.White)
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .borderRadius(14)
        .onClick(() => {
          this.onToggleFollow();
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16, top: 36 })
    .alignItems(VerticalAlign.Center)
  }

  /** 右侧悬浮操作（商品袋/礼物/分享/点赞） */
  @Builder
  RightActions(live: LiveInfo) {
    Column({ space: 22 }) {
      // 主播头像（小，跳店铺）
      Image(ImageUtil.get(live.anchorAvatar))
        .width(48)
        .height(48)
        .borderRadius(24)
        .border({ width: 2, color: Color.White })
        .onClick(() => {
          this.gotoShop();
        })

      // 点赞
      Column({ space: 4 }) {
        Text('❤️')
          .fontSize(34)
          .onClick(() => {
            this.onLike();
          })
        Text(this.formatCount(this.likeCount))
          .fontSize(11)
          .fontColor(Color.White)
      }
      .alignItems(HorizontalAlign.Center)

      // 商品袋
      Column({ space: 4 }) {
        Text('🛍️')
          .fontSize(34)
        Text(`${this.bags.length}件`)
          .fontSize(11)
          .fontColor(Color.White)
      }
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        this.showBagPanel = true;
      })

      // 礼物
      Column({ space: 4 }) {
        Text('🎁')
          .fontSize(34)
        Text('送礼')
          .fontSize(11)
          .fontColor(Color.White)
      }
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        this.showGiftPanel = true;
      })

      // 分享
      Column({ space: 4 }) {
        Text('分享')
          .fontSize(11)
          .fontColor(Color.White)
        Text('🔗')
          .fontSize(30)
      }
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        this.showShareMenu = true;
        ToastUtil.info('分享功能开发中');
      })
    }
    .position({ right: 12, bottom: 180 })
    .alignItems(HorizontalAlign.Center)
  }

  /** 底部评论 + 输入栏 */
  @Builder
  BottomCommentBar(live: LiveInfo) {
    Column({ space: 8 }) {
      // 评论列表（自动滚到底）
      List({ scroller: this.commentScroller }) {
        ForEach(this.comments, (comment: LiveComment) => {
          ListItem() {
            this.CommentBubble(comment)
          }
        }, (comment: LiveComment) => comment.commentId)
      }
      .width('100%')
      .height(180)
      .padding({ left: 12, right: 80 })
      .align(Alignment.Bottom)
      .scrollBar(BarState.Off)

      // 输入框 + 发送按钮 + 金币显示
      Row({ space: 8 }) {
        // 输入框
        TextInput({ text: this.inputText, placeholder: '说点什么…' })
          .fontSize(13)
          .fontColor(Color.White)
          .placeholderColor('rgba(255,255,255,0.6)')
          .placeholderFont({ size: 13 })
          .backgroundColor('rgba(255,255,255,0.15)')
          .borderRadius(20)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .layoutWeight(1)
          .onChange((value: string) => {
            this.inputText = value;
          })

        // 金币余额
        Text(`💰${this.coins}`)
          .fontSize(12)
          .fontColor($r('app.color.color_accent_gold'))
          .padding({ left: 8, right: 8, top: 6, bottom: 6 })

        // 发送按钮
        Text('发送')
          .fontSize(13)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.color_primary'))
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .borderRadius(16)
          .onClick(() => {
            this.onSendComment();
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12, bottom: 24 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /** 评论气泡（自己右侧绿色，他人左侧白色） */
  @Builder
  CommentBubble(comment: LiveComment) {
    Row({ space: 6 }) {
      if (!comment.isSelf) {
        // 他人：头像 + 气泡（左）
        Image(ImageUtil.get(comment.avatar))
          .width(24)
          .height(24)
          .borderRadius(12)
        Text(`${comment.nickname}: ${comment.content}`)
          .fontSize(12)
          .fontColor(Color.White)
          .backgroundColor('rgba(0,0,0,0.4)')
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .borderRadius(12)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      } else {
        // 自己：气泡（右，生机绿）
        Blank()
        Text(comment.content)
          .fontSize(12)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.color_primary'))
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .borderRadius(12)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
    }
    .width('100%')
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
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text('✕')
          .fontSize(20)
          .fontColor($r('app.color.color_text_secondary'))
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
        .backgroundColor($r('app.color.color_secondary'))
        .width(22)
        .height(22)
        .borderRadius(11)
        .textAlign(TextAlign.Center)
      // 商品图
      Image(ImageUtil.get(bag.mainImage))
        .width(56)
        .height(56)
        .borderRadius(8)
      // 标题 + 价格
      Column({ space: 4 }) {
        Text(bag.title)
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 2 }) {
          Text('¥')
            .fontSize(11)
            .fontColor($r('app.color.color_price'))
            .fontWeight(FontWeight.Bold)
          Text(bag.price.toFixed(2))
            .fontSize(16)
            .fontColor($r('app.color.color_price'))
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
        .backgroundColor($r('app.color.color_primary'))
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .borderRadius(12)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Center)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_page'))
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
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
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text(`金币余额: ${this.coins}`)
          .fontSize(13)
          .fontColor($r('app.color.color_accent_gold'))
          .fontWeight(FontWeight.Bold)
        Text('✕')
          .fontSize(20)
          .fontColor($r('app.color.color_text_secondary'))
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
        .fontColor($r('app.color.color_text_primary'))
      Text(`💰 ${gift.price}`)
        .fontSize(11)
        .fontColor($r('app.color.color_accent_gold'))
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_page'))
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
        .backgroundColor($r('app.color.color_secondary'))
        .padding({ left: 24, right: 24, top: 10, bottom: 10 })
        .borderRadius(20)
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
        .backgroundColor($r('app.color.color_primary'))
        .padding({ left: 24, right: 24, top: 10, bottom: 10 })
        .borderRadius(20)
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

  /** 格式化在线观看文案 */
  private formatOnlineText(live: LiveInfo): string {
    if (live.status === 'living') {
      return `🔥 ${this.formatCount(live.onlineCount)} 人观看`;
    }
    if (live.status === 'ended') {
      return `累计 ${this.formatCount(live.totalViewUv)} 次观看`;
    }
    return getLiveStatusLabel(live.status) + ' · ' + getLiveCategoryLabel(live.category);
  }

  /** 格式化数字（>=10000 显示万） */
  private formatCount(count: number): string {
    if (count >= 10000) {
      return `${(count / 10000).toFixed(1)}万`;
    }
    return `${count}`;
  }
}
