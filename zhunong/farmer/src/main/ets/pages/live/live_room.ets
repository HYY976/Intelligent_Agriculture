/**
 * live_room - 直播间页（spec 3.2.4.3）
 *
 * 卖家端直播间界面与用户端一致，但额外显示：
 *  - 实时观看人数
 *  - 实时收入数据
 *  - 商品袋管理（添加/移除商品）
 *  - 结束直播按钮
 *
 * 角色参数：
 *  - role=broadcaster：主播端，显示收入/商品袋/结束按钮
 *  - role=viewer：观众端，仅观看
 */

import { Logger, AppConstants, ToastUtil, NavigationHelper, RouteName } from 'common';
import { LiveManageItem } from '../../model/FarmerModels';
import { LiveComment, Gift } from '../../model/FarmerLiveModels';
import { LiveManageRepository } from '../../repository/LiveManageRepository';
import { MOCK_LIVE_MANAGE_LIST } from '../../mock/FarmerMock';
import { MOCK_LIVE_COMMENTS, MOCK_GIFTS } from '../../mock/FarmerLiveMock';

/** 弹幕消息本地存储 */
interface DanmakuMessage {
  commentId: string;
  nickname: string;
  content: string;
}

@ComponentV2
export struct LiveRoom {
  /** 直播 ID */
  @Local liveId: string = '';
  /** 当前角色 */
  @Local role: 'broadcaster' | 'viewer' = 'viewer';
  /** 直播信息 */
  @Local liveInfo: LiveManageItem | null = null;
  /** 实时观看人数 */
  @Local onlineCount: number = 0;
  /** 实时累计收入（礼物 + 订单） */
  @Local totalIncome: number = 0;
  /** 弹幕列表 */
  @Local danmakuList: DanmakuMessage[] = [];
  /** 评论输入 */
  @Local inputComment: string = '';
  /** 礼物面板是否展开 */
  @Local giftPanelOpen: boolean = false;
  /** 商品袋面板是否展开 */
  @Local bagPanelOpen: boolean = false;
  /** 礼物列表 */
  @Local gifts: Gift[] = MOCK_GIFTS;
  /** 商品袋 */
  @Local productBag: string[] = [];
  /** 弹幕推送定时器（Mock） */
  private danmakuTimer: number = -1;

  async aboutToAppear(): Promise<void> {
    const params: Record<string, string> = NavigationHelper.getParam<Record<string, string>>() ?? {};
    this.liveId = params?.liveId ?? '';
    const roleParam: string = params?.role ?? 'viewer';
    this.role = roleParam === 'broadcaster' ? 'broadcaster' : 'viewer';
    Logger.info(AppConstants.SCENE_FARMER, { action: 'live_room_appear', liveId: this.liveId, role: this.role });
    await this.loadLiveInfo();
    await this.loadComments();
    await this.loadGifts();
    if (this.role === 'broadcaster') {
      this.startMockIncome();
    }
    this.startMockDanmaku();
  }

  aboutToDisappear(): void {
    if (this.danmakuTimer !== -1) {
      clearInterval(this.danmakuTimer);
      this.danmakuTimer = -1;
    }
  }

  /** 加载直播信息（Mock：从本地列表查询） */
  private async loadLiveInfo(): Promise<void> {
    const found: LiveManageItem | undefined = MOCK_LIVE_MANAGE_LIST.find(
      (l: LiveManageItem): boolean => l.liveId === this.liveId
    );
    if (found) {
      this.liveInfo = found;
      this.onlineCount = found.totalViewUv;
      this.totalIncome = found.totalGiftIncome + found.totalOrderIncome;
      this.productBag = [];
    }
  }

  /** 加载评论 */
  private async loadComments(): Promise<void> {
    try {
      const comments: LiveComment[] = await LiveManageRepository.getLiveComments(this.liveId);
      this.danmakuList = comments.map((c: LiveComment): DanmakuMessage => {
        return {
          commentId: c.commentId,
          nickname: c.nickname,
          content: c.content
        };
      });
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'load_comments_fail', error: (err as Error).message });
    }
  }

  /** 加载礼物列表 */
  private async loadGifts(): Promise<void> {
    try {
      this.gifts = await LiveManageRepository.getGifts();
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'load_gifts_fail', error: (err as Error).message });
    }
  }

  /** Mock 弹幕推送（每 5 秒推送一条本地 Mock 评论） */
  private startMockDanmaku(): void {
    let idx: number = 0;
    this.danmakuTimer = setInterval(() => {
      if (MOCK_LIVE_COMMENTS.length === 0) {
        return;
      }
      const c: LiveComment = MOCK_LIVE_COMMENTS[idx % MOCK_LIVE_COMMENTS.length];
      idx++;
      const newMsg: DanmakuMessage = {
        commentId: `local_${Date.now()}`,
        nickname: c.nickname,
        content: c.content
      };
      this.danmakuList = this.danmakuList.concat([newMsg]).slice(-50);
      // 观看人数 +1
      this.onlineCount++;
    }, 5000);
  }

  /** Mock 实时收入推送（主播端，每 8 秒增长） */
  private startMockIncome(): void {
    setInterval(() => {
      const giftIncome: number = Math.floor(Math.random() * 10) + 1;
      this.totalIncome += giftIncome;
      Logger.info(AppConstants.SCENE_FARMER, { action: 'mock_income_push', giftIncome });
    }, 8000);
  }

  /** 发送评论 */
  private async sendComment(): Promise<void> {
    if (this.inputComment.length === 0) {
      return;
    }
    const newMsg: DanmakuMessage = {
      commentId: `me_${Date.now()}`,
      nickname: this.role === 'broadcaster' ? '主播' : '我',
      content: this.inputComment
    };
    this.danmakuList = this.danmakuList.concat([newMsg]).slice(-50);
    this.inputComment = '';
  }

  /** 送礼物（观众端） */
  private async sendGift(gift: Gift): Promise<void> {
    ToastUtil.success(`已送出 ${gift.icon} ${gift.name}`);
    Logger.info(AppConstants.SCENE_FARMER, { action: 'send_gift', giftId: gift.giftId });
    this.giftPanelOpen = false;
    if (this.role === 'viewer') {
      this.totalIncome += gift.price;
    }
  }

  /** 结束直播（主播端） */
  private async endLive(): Promise<void> {
    try {
      await LiveManageRepository.endLive(this.liveId);
      ToastUtil.success('直播已结束');
      Logger.info(AppConstants.SCENE_FARMER, { action: 'live_end_success', liveId: this.liveId });
      NavigationHelper.pop();
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'live_end_fail', error: (err as Error).message });
      ToastUtil.error('结束直播失败');
    }
  }

  build() {
    NavDestination() {
      Stack() {
        // 直播画面背景（全屏黑底）
        Column() {
          Text('📹')
            .fontSize(120)
          Text(this.liveInfo?.title ?? '直播间')
            .fontSize(16)
            .fontColor(Color.White)
            .margin({ top: 12 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#1A1A1A')

        // 主内容层（参考抖音直播间布局）
        Column() {
          // 顶部主播信息栏（固定高度，不遮挡内容）
          this.TopAnchorBar()

          // 中间区域：左侧弹幕 + 右侧操作按钮（水平分布）
          Row() {
            // 左侧弹幕区（占60%宽度）
            this.DanmakuList()
            // 中间空白弹性区
            Column().layoutWeight(1).height('100%')
            // 右侧悬浮操作（固定宽度，垂直居中）
            this.RightActions()
          }
          .layoutWeight(1)
          .width('100%')

          // 底部互动栏（固定高度，不遮挡内容）
          this.BottomActionBar()
        }
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#000000')
    }
    .hideTitleBar(true)
  }

  /** 顶部主播信息栏 spec 15.6.2 / 15.6.3 */
  @Builder
  TopAnchorBar() {
    Column({ space: 6 }) {
      Row({ space: 10 }) {
        // 返回按钮
        Text('‹')
          .fontSize(28)
          .fontColor(Color.White)
          .onClick(() => NavigationHelper.pop())

        // 主播头像
        Text('👤')
          .fontSize(20)
          .fontColor(Color.White)
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor($r('app.color.color_cta_black'))
          .textAlign(TextAlign.Center)

        // 昵称 + 在线人数
        Column({ space: 2 }) {
          Text(this.liveInfo?.title ?? '主播')
            .fontSize(13)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
          Row({ space: 4 }) {
            Text('👁')
              .fontSize(10)
            Text(`${this.onlineCount}`)
              .fontSize(11)
              .fontColor('rgba(255,255,255,0.8)')
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 收入（主播端）
        if (this.role === 'broadcaster') {
          Text(`💰 ¥${this.totalIncome.toFixed(2)}`)
            .fontSize(12)
            .fontColor($r('app.color.color_accent_gold'))
            .backgroundColor('rgba(0,0,0,0.5)')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(10)
        }

        // 关注按钮（观众端）spec 15.6.3：黄底黑字
        if (this.role === 'viewer') {
          Text('+ 关注')
            .fontSize(12)
            .fontColor($r('app.color.color_text_primary'))
            .backgroundColor($r('app.color.color_card_yellow'))
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(14)
            .onClick(() => {
              ToastUtil.success('已关注主播');
              Logger.info(AppConstants.SCENE_FARMER, { action: 'live_follow', liveId: this.liveId });
            })
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 36, bottom: 12 })
    .align(Alignment.Top)
  }

  /** 弹幕区 spec 15.6.2：左侧竖排 */
  @Builder
  DanmakuList() {
    Column() {
      Scroll() {
        Column({ space: 6 }) {
          ForEach(this.danmakuList, (msg: DanmakuMessage, _idx: number) => {
            Row({ space: 6 }) {
              Text(`${msg.nickname}:`)
                .fontSize(12)
                .fontColor($r('app.color.color_accent_gold'))
              Text(msg.content)
                .fontSize(12)
                .fontColor(Color.White)
                .layoutWeight(1)
            }
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('rgba(0,0,0,0.3)')
            .borderRadius(10)
          }, (msg: DanmakuMessage) => msg.commentId)
        }
        .width('100%')
      }
      .width('60%')
      .height('40%')
      .align(Alignment.Start)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 12, bottom: 80, top: 120 })
    .align(Alignment.Start)
  }

  /** 右侧悬浮操作（垂直居中排列，参考抖音布局） */
  @Builder
  RightActions() {
    Column({ space: 18 }) {
      // 点赞
      Column({ space: 4 }) {
        Text('❤️')
          .fontSize(36)
          .onClick(() => {
            this.onlineCount++;
            ToastUtil.success('已点赞');
          })
        Text(`${this.onlineCount}`)
          .fontSize(11)
          .fontColor(Color.White)
      }
      .alignItems(HorizontalAlign.Center)

      // 商品袋入口 spec 15.6.3：黄色购物车
      Column({ space: 4 }) {
        Text('🛒')
          .fontSize(36)
        Text(`${this.productBag.length}件`)
          .fontSize(11)
          .fontColor($r('app.color.color_text_primary'))
      }
      .alignItems(HorizontalAlign.Center)
      .padding({ left: 8, right: 8, top: 6, bottom: 6 })
      .borderRadius(24)
      .backgroundColor($r('app.color.color_card_yellow'))
      .onClick(() => {
        if (this.role === 'broadcaster') {
          this.bagPanelOpen = !this.bagPanelOpen;
        } else {
          ToastUtil.info('商品袋开发中');
        }
      })

      // 礼物（观众端）
      if (this.role === 'viewer') {
        Column({ space: 4 }) {
          Text('🎁')
            .fontSize(36)
          Text('送礼')
            .fontSize(11)
            .fontColor(Color.White)
        }
        .alignItems(HorizontalAlign.Center)
        .onClick(() => { this.giftPanelOpen = !this.giftPanelOpen; })
      }

      // 分享
      Column({ space: 4 }) {
        Text('🔗')
          .fontSize(32)
        Text('分享')
          .fontSize(11)
          .fontColor(Color.White)
      }
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        ToastUtil.info('分享功能开发中');
      })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width(80)
    .height('100%')
    .padding({ right: 12, top: 20, bottom: 20 })
  }

  /** 底部互动栏 spec 15.6.2 */
  /** 底部互动栏（固定高度，参考抖音布局） */
  @Builder
  BottomActionBar() {
    Column({ space: 8 }) {
      // 礼物面板（观众端）
      if (this.giftPanelOpen && this.role === 'viewer') {
        this.GiftPanel()
      }
      // 商品袋面板（主播端）
      if (this.bagPanelOpen && this.role === 'broadcaster') {
        this.ProductBagPanel()
      }
      // 主操作行
      Row({ space: 8 }) {
        TextInput({ text: this.inputComment, placeholder: '说点什么...' })
          .height(40)
          .borderRadius(20)
          .backgroundColor('rgba(255,255,255,0.9)')
          .padding({ left: 16, right: 16 })
          .fontSize(13)
          .layoutWeight(1)
          .onChange((v: string) => { this.inputComment = v; })
        Button('发送')
          .height(40)
          .borderRadius(20)
          .backgroundColor($r('app.color.color_cta_black'))
          .fontColor(Color.White)
          .fontSize(13)
          .padding({ left: 16, right: 16 })
          .onClick(() => { this.sendComment(); })
        if (this.role === 'broadcaster') {
          Button('🔴 结束直播')
            .height(40)
            .borderRadius(20)
            .backgroundColor($r('app.color.color_error'))
            .fontColor(Color.White)
            .fontSize(13)
            .padding({ left: 12, right: 12 })
            .onClick(() => { this.endLive(); })
        }
      }
      .width('100%')
    }
    .width('100%')
    .height(80)
    .padding({ left: 16, right: 16, bottom: 16, top: 12 })
    .linearGradient({
      direction: GradientDirection.Top,
      colors: [['rgba(0,0,0,0)', 0], ['rgba(0,0,0,0.7)', 1]]
    })
  }

  /** 礼物面板 */
  @Builder
  GiftPanel() {
    Column({ space: 8 }) {
      Text('送礼物')
        .fontSize(12)
        .fontColor(Color.White)
        .alignSelf(ItemAlign.Start)
      Grid() {
        ForEach(this.gifts, (gift: Gift, _idx: number) => {
          GridItem() {
            Column({ space: 4 }) {
              Text(gift.icon)
                .fontSize(28)
              Text(gift.name)
                .fontSize(11)
                .fontColor(Color.White)
              Text(`¥${gift.price}`)
                .fontSize(10)
                .fontColor($r('app.color.color_accent_gold'))
            }
            .width('100%')
            .padding(8)
            .borderRadius(8)
            .backgroundColor('rgba(255,255,255,0.1)')
            .alignItems(HorizontalAlign.Center)
            .onClick(() => { this.sendGift(gift); })
          }
        }, (gift: Gift) => gift.giftId)
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .columnsGap(8)
      .rowsGap(8)
      .width('100%')
      .height(160)
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor('rgba(0,0,0,0.7)')
  }

  /** 商品袋面板（主播端） */
  @Builder
  ProductBagPanel() {
    Column({ space: 8 }) {
      Text(`商品袋（${this.productBag.length} 件）`)
        .fontSize(12)
        .fontColor(Color.White)
        .alignSelf(ItemAlign.Start)
      if (this.productBag.length === 0) {
        Text('商品袋为空')
          .fontSize(11)
          .fontColor('rgba(255,255,255,0.5)')
      } else {
        ForEach(this.productBag, (pid: string, idx: number) => {
          Row({ space: 8 }) {
            Text('🌾')
              .fontSize(20)
            Text(`商品 ${pid}`)
              .fontSize(12)
              .fontColor(Color.White)
              .layoutWeight(1)
            Text('移除')
              .fontSize(11)
              .fontColor($r('app.color.color_error'))
              .onClick(() => { this.productBag.splice(idx, 1); })
          }
          .width('100%')
          .padding(8)
          .borderRadius(8)
          .backgroundColor('rgba(255,255,255,0.1)')
        }, (pid: string) => pid)
      }
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor('rgba(0,0,0,0.7)')
  }
}
