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
        // 直播画面背景
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

        // 顶部信息栏
        Column() {
          Row({ space: 8 }) {
            Text('‹')
              .fontSize(28)
              .fontColor(Color.White)
              .onClick(() => NavigationHelper.pop())
            // 主播信息
            Text('👤')
              .fontSize(24)
              .width(36)
              .height(36)
              .borderRadius(18)
              .backgroundColor($r('app.color.color_primary'))
              .textAlign(TextAlign.Center)
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
                  .fontColor('rgba(255,255,255,0.7)')
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
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        }
        .width('100%')
        .align(Alignment.Top)

        // 弹幕区
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
        .padding({ left: 12, bottom: 80, top: 80 })
        .align(Alignment.Start)

        // 底部操作栏
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
              .backgroundColor($r('app.color.color_secondary'))
              .fontColor(Color.White)
              .fontSize(13)
              .padding({ left: 16, right: 16 })
              .onClick(() => { this.sendComment(); })
            if (this.role === 'viewer') {
              Text('🎁')
                .fontSize(24)
                .width(40)
                .height(40)
                .textAlign(TextAlign.Center)
                .onClick(() => { this.giftPanelOpen = !this.giftPanelOpen; })
            }
            if (this.role === 'broadcaster') {
              Text('🛒')
                .fontSize(24)
                .width(40)
                .height(40)
                .textAlign(TextAlign.Center)
                .onClick(() => { this.bagPanelOpen = !this.bagPanelOpen; })
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
        .padding({ left: 12, right: 12, bottom: 12, top: 8 })
        .backgroundColor('rgba(0,0,0,0.5)')
        .align(Alignment.Bottom)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#000000')
    }
    .hideTitleBar(true)
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
