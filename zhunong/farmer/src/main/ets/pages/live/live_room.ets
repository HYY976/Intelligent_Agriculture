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

import { Logger, AppConstants, ToastUtil, NavigationHelper, RouteName, TokenStore } from 'common';
import { UserInfo } from 'common';
import { display } from '@kit.ArkUI';
import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { buffer } from '@kit.ArkTS';
import { HONEY_LIVE_BASE64 } from '../../utils/honey_live_base64';
import { LiveManageItem, FarmerProductItem } from '../../model/FarmerModels';
import { LiveComment, Gift, LiveListItem } from '../../model/FarmerLiveModels';
import { LiveManageRepository } from '../../repository/LiveManageRepository';
import { MOCK_LIVE_MANAGE_LIST, MOCK_FARMER_PRODUCTS, MOCK_FARMER_PROFILE } from '../../mock/FarmerMock';
import { MOCK_LIVE_COMMENTS, MOCK_GIFTS } from '../../mock/FarmerLiveMock';
import { ImageUtil } from '../../utils/ImageUtil';
import { ReplaceableImage } from '../../components/ReplaceableImage';

/** 弹幕消息本地存储 */
interface DanmakuMessage {
  commentId: string;
  nickname: string;
  content: string;
}

/** spec 16.10：直播间自定义挂链接 */
interface CustomLiveLink {
  linkId: string;
  title: string;
  url: string;
}

/** 直播状态广播（spec 16.9：跨页面同步结束直播状态） */
export class LiveStatusBroadcaster {
  static endedLiveIds: Set<string> = new Set<string>();
  static markEnded(liveId: string): void {
    LiveStatusBroadcaster.endedLiveIds.add(liveId);
  }
  static isEnded(liveId: string): boolean {
    return LiveStatusBroadcaster.endedLiveIds.has(liveId);
  }
}

@ComponentV2
export struct LiveRoom {
  /** 直播 ID */
  @Local liveId: string = '';
  /** 当前角色 */
  @Local role: 'broadcaster' | 'viewer' = 'viewer';
  /** 直播信息 */
  @Local liveInfo: LiveManageItem | null = null;
  /** 视频播放地址（运行时从 rawfile 复制到沙箱目录，避免 build 目录文件锁定） */
  @Local videoSrc: string = '';
  /** 主播昵称（spec 16.9：同步注册用户信息） */
  @Local anchorName: string = '主播';
  /** 主播头像 URI（spec 16.9：同步注册用户信息） */
  @Local anchorAvatar: string = '';
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
  /** 小黄车商品列表（spec：右下角显示正在卖的商品，spec 16.9：支持修改） */
  @Local cartProducts: FarmerProductItem[] = [];
  /** 小黄车是否展开 */
  @Local cartExpanded: boolean = false;
  /** spec 16.15：小黄车拖动位置 X（vp，相对屏幕左上角） */
  @Local cartPosX: number = 200;
  /** spec 16.15：小黄车拖动位置 Y（vp，相对屏幕左上角） */
  @Local cartPosY: number = 400;
  /** spec 16.15：拖动起始触摸点 X */
  private dragStartX: number = 0;
  /** spec 16.15：拖动起始触摸点 Y */
  private dragStartY: number = 0;
  /** spec 16.15：拖动起始时面板 X */
  private dragStartPosX: number = 0;
  /** spec 16.15：拖动起始时面板 Y */
  private dragStartPosY: number = 0;
  /** spec 16.15：是否已初始化小黄车默认位置 */
  private cartPosInitialized: boolean = false;
  /** spec 16.15：当前触摸是否已触发拖动（用于抑制点击事件） */
  @Local dragMoved: boolean = false;
  /** 小黄车编辑面板是否展开（spec 16.9：链接可修改） */
  @Local cartEditOpen: boolean = false;
  /** 可选商品池（spec 16.9：链接编辑用） */
  @Local candidateProducts: FarmerProductItem[] = [];
  /** spec 16.11：手动添加商品名称输入 */
  @Local newProductName: string = '';
  /** spec 16.11：手动添加商品价格输入 */
  @Local newProductPrice: string = '';
  /** spec 16.10：自定义挂链接输入弹窗是否展开 */
  @Local linkDialogOpen: boolean = false;
  /** spec 16.10：自定义链接标题输入 */
  @Local linkTitleInput: string = '';
  /** spec 16.10：自定义链接 URL 输入 */
  @Local linkUrlInput: string = '';
  /** spec 16.10：已挂载的自定义链接列表（外部展示用） */
  @Local customLinks: CustomLiveLink[] = [];
  /** 弹幕推送定时器（Mock） */
  private danmakuTimer: number = -1;
  /** spec 16.10：弹幕滚动控制器，自动滚到底部显示最新评论 */
  private danmakuScroller: Scroller = new Scroller();

  async aboutToAppear(): Promise<void> {
    const params: Record<string, string> = NavigationHelper.getParam<Record<string, string>>() ?? {};
    this.liveId = params?.liveId ?? '';
    const roleParam: string = params?.role ?? 'viewer';
    this.role = roleParam === 'broadcaster' ? 'broadcaster' : 'viewer';
    Logger.info(AppConstants.SCENE_FARMER, { action: 'live_room_appear', liveId: this.liveId, role: this.role });
    this.initCartPosition();
    await this.loadAnchorInfo();
    await this.loadLiveInfo();
    await this.loadVideoSrc();
    await this.loadComments();
    await this.loadGifts();
    if (this.role === 'broadcaster') {
      this.startMockIncome();
    }
    this.startMockDanmaku();
  }

  /** spec 16.9/16.15：加载注册用户信息作为主播昵称/头像，同步卖家中心个人信息 */
  private async loadAnchorInfo(): Promise<void> {
    try {
      const user: UserInfo | null = await TokenStore.getUserInfo();
      if (user) {
        this.anchorName = user.nickname && user.nickname.length > 0 ? user.nickname : MOCK_FARMER_PROFILE.shopName;
        this.anchorAvatar = user.avatar && user.avatar.length > 0 ? user.avatar : MOCK_FARMER_PROFILE.shopLogo;
      } else {
        // spec 16.15：TokenStore 无用户信息时，回退到卖家中心 Mock 同步
        this.anchorName = MOCK_FARMER_PROFILE.shopName;
        this.anchorAvatar = MOCK_FARMER_PROFILE.shopLogo;
      }
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'load_anchor_info_fail', error: (err as Error).message });
      // spec 16.15：异常时回退到卖家中心 Mock
      this.anchorName = MOCK_FARMER_PROFILE.shopName;
      this.anchorAvatar = MOCK_FARMER_PROFILE.shopLogo;
    }
  }

  aboutToDisappear(): void {
    if (this.danmakuTimer !== -1) {
      clearInterval(this.danmakuTimer);
      this.danmakuTimer = -1;
    }
  }

  /**
   * 加载直播信息（Mock：从本地列表查询）
   * spec 16.13：优先从 MOCK_LIVE_MANAGE_LIST 查询，未命中时回退到 CreatedLiveStore（用户刚创建的直播）
   */
  private async loadLiveInfo(): Promise<void> {
    const found: LiveManageItem | undefined = MOCK_LIVE_MANAGE_LIST.find(
      (l: LiveManageItem): boolean => l.liveId === this.liveId
    );
    if (found) {
      this.liveInfo = found;
      this.onlineCount = found.totalViewUv;
      this.totalIncome = found.totalGiftIncome + found.totalOrderIncome;
      this.productBag = [];
    } else {
      // spec 16.13：回退到 CreatedLiveStore（用户刚创建的直播，LiveListItem → LiveManageItem）
      const created: LiveListItem | undefined = LiveManageRepository.getCreatedLiveById(this.liveId);
      if (created) {
        const constructed: LiveManageItem = {
          liveId: created.liveId,
          title: created.title,
          coverImage: created.coverImage,
          category: created.category,
          status: created.status,
          startTime: Date.now(),
          totalViewUv: created.totalViewUv,
          totalGiftIncome: 0,
          totalOrderIncome: 0
        };
        this.liveInfo = constructed;
        this.onlineCount = created.onlineCount ?? 1;
        this.totalIncome = 0;
        this.productBag = [];
      }
    }
    // spec 16.9：可选商品池（已上架商品），用于链接编辑
    this.candidateProducts = MOCK_FARMER_PRODUCTS.filter(
      (p: FarmerProductItem): boolean => p.status === 'approved'
    );
    // spec：加载小黄车商品（默认取前 3 件已上架商品作为直播间售卖商品）
    this.cartProducts = this.candidateProducts.slice(0, 3);
  }

  /**
   * 加载视频源（运行时从 base64 解码写入沙箱目录，避免资源文件在 build 目录被锁定）
   */
  private async loadVideoSrc(): Promise<void> {
    if (!this.liveInfo || !this.liveInfo.videoUrl || this.liveInfo.videoUrl.length === 0) {
      return;
    }
    try {
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      const sandboxDir: string = context.filesDir;
      const destPath: string = `${sandboxDir}/honey_live.mp4`;

      // 检查沙箱目录是否已存在视频文件（避免重复解码）
      try {
        if (fs.accessSync(destPath)) {
          this.videoSrc = `file://${destPath}`;
          Logger.info(AppConstants.SCENE_FARMER, { action: 'video_src_cached', msg: destPath });
          return;
        }
      } catch (_e) {
        // 文件不存在，继续写入
      }

      // 从 base64 解码视频数据，写入沙箱目录
      const buf: buffer.Buffer = buffer.from(HONEY_LIVE_BASE64, 'base64');
      const file: fs.File = fs.openSync(destPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
      fs.writeSync(file.fd, buf.buffer);
      fs.closeSync(file);
      this.videoSrc = `file://${destPath}`;
      Logger.info(AppConstants.SCENE_FARMER, { action: 'video_src_decoded', msg: destPath, count: buf.length });
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'load_video_src_fail', error: (err as Error).message });
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
      // spec 16.10：自动滚动到底部显示最新弹幕
      this.scrollToDanmakuBottom();
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
      nickname: this.role === 'broadcaster' ? this.anchorName : '我',
      content: this.inputComment
    };
    this.danmakuList = this.danmakuList.concat([newMsg]).slice(-50);
    this.inputComment = '';
    // spec 16.10：发送后自动滚动到底部
    this.scrollToDanmakuBottom();
  }

  /** spec 16.10：弹幕滚动到底部 */
  private scrollToDanmakuBottom(): void {
    setTimeout(() => {
      try {
        this.danmakuScroller.scrollEdge(Edge.Bottom);
      } catch (err) {
        // 忽略滚动异常
      }
    }, 50);
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

  /** 结束直播（主播端，spec 16.9：同步状态广播，使直播列表页刷新） */
  private async endLive(): Promise<void> {
    try {
      await LiveManageRepository.endLive(this.liveId);
      LiveStatusBroadcaster.markEnded(this.liveId);
      ToastUtil.success('直播已结束');
      Logger.info(AppConstants.SCENE_FARMER, { action: 'live_end_success', liveId: this.liveId });
      NavigationHelper.pop();
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'live_end_fail', error: (err as Error).message });
      ToastUtil.error('结束直播失败');
    }
  }

  /** spec 16.9：从小黄车移除商品链接 */
  private removeCartProduct(productId: string): void {
    this.cartProducts = this.cartProducts.filter((p: FarmerProductItem): boolean => p.productId !== productId);
  }

  /** spec 16.15：初始化小黄车默认位置到屏幕右下角 */
  private initCartPosition(): void {
    if (this.cartPosInitialized) {
      return;
    }
    try {
      const screen: display.Display = display.getDefaultDisplaySync();
      const screenWidth: number = px2vp(screen.width);
      const screenHeight: number = px2vp(screen.height);
      // 默认右下角：面板宽 180，留 16vp 边距
      this.cartPosX = Math.max(0, screenWidth - 180 - 16);
      this.cartPosY = Math.max(0, screenHeight - 320);
      this.cartPosInitialized = true;
    } catch (err) {
      // 兜底默认值
      this.cartPosX = 200;
      this.cartPosY = 400;
      this.cartPosInitialized = true;
    }
  }

  /** spec 16.15：小黄车触摸事件处理，支持拖动移动位置 */
  private onCartTouch(event: TouchEvent): void {
    const touch: TouchObject = event.touches[0];
    const x: number = touch.x;
    const y: number = touch.y;
    if (event.type === TouchType.Down) {
      this.dragStartX = x;
      this.dragStartY = y;
      this.dragStartPosX = this.cartPosX;
      this.dragStartPosY = this.cartPosY;
      this.dragMoved = false;
    } else if (event.type === TouchType.Move) {
      const dx: number = x - this.dragStartX;
      const dy: number = y - this.dragStartY;
      // 仅当位移超过 5vp 才视为拖动，避免误触
      if (Math.abs(dx) > 5 || Math.abs(dy) > 5) {
        this.dragMoved = true;
        let newX: number = this.dragStartPosX + dx;
        let newY: number = this.dragStartPosY + dy;
        // 边界限制，避免拖出屏幕
        try {
          const screen: display.Display = display.getDefaultDisplaySync();
          const screenWidth: number = px2vp(screen.width);
          const screenHeight: number = px2vp(screen.height);
          newX = Math.max(0, Math.min(newX, screenWidth - 180));
          newY = Math.max(0, Math.min(newY, screenHeight - 80));
        } catch (_err) {
          // 兜底不限制
        }
        this.cartPosX = newX;
        this.cartPosY = newY;
      }
    }
  }

  /** spec 16.15：判断是否为纯点击（非拖动），用于抑制拖动后的点击事件 */
  private isPureClick(): boolean {
    const moved: boolean = this.dragMoved;
    // 消费后立即重置，确保下次触摸可重新判定
    this.dragMoved = false;
    return !moved;
  }

  /** spec 16.9：向小黄车添加商品链接 */
  private addCartProduct(productId: string): void {
    const exists: boolean = this.cartProducts.some((p: FarmerProductItem): boolean => p.productId === productId);
    if (exists) {
      ToastUtil.info('该商品已在小黄车');
      return;
    }
    const target: FarmerProductItem | undefined = this.candidateProducts.find(
      (p: FarmerProductItem): boolean => p.productId === productId
    );
    if (target) {
      this.cartProducts = this.cartProducts.concat([target]);
      // spec 16.14：关闭编辑面板，让用户直接看到新增的商品
      this.cartEditOpen = false;
      ToastUtil.success('已添加到小黄车');
    }
  }

  /** spec 16.11：手动输入内容上架商品到正在卖 */
  private addManualProduct(): void {
    const name: string = this.newProductName.trim();
    const priceStr: string = this.newProductPrice.trim();
    if (name.length === 0) {
      ToastUtil.warning('请输入商品名称');
      return;
    }
    const priceNum: number = parseFloat(priceStr);
    if (isNaN(priceNum) || priceNum <= 0) {
      ToastUtil.warning('请输入有效价格');
      return;
    }
    // 构造临时商品对象上架
    const manualProduct: FarmerProductItem = {
      productId: `manual_${Date.now()}`,
      title: name,
      mainImage: 'prod_default',
      price: priceNum,
      stock: 999,
      monthlySales: 0,
      monthlyGmv: 0,
      status: 'approved',
      createdAt: Date.now()
    };
    this.cartProducts = this.cartProducts.concat([manualProduct]);
    // 清空输入框
    this.newProductName = '';
    this.newProductPrice = '';
    // spec 16.14：关闭编辑面板，让用户直接看到新增的商品
    this.cartEditOpen = false;
    ToastUtil.success('已上架到正在卖');
  }

  build() {
    NavDestination() {
      Stack() {
        // 直播画面背景（spec：有视频时自动播放视频，否则显示封面图）
        Column() {
          if (this.liveInfo && this.liveInfo.videoUrl && this.liveInfo.videoUrl.length > 0 && this.videoSrc.length > 0) {
            // 蜂蜜直播间：自动循环播放视频（从沙箱目录读取，避免 build 目录文件锁定）
            Video({
              src: this.videoSrc,
              currentProgressRate: 1.0,
              previewUri: undefined
            })
              .width('100%')
              .height('100%')
              .autoPlay(true)
              .loop(true)
              .controls(false)
              .objectFit(ImageFit.Cover)
          } else if (this.liveInfo && this.liveInfo.coverImage) {
            // spec 16.8：支持 file:// / http(s):// 真实 URI 或 Mock 图片 key
            if (this.liveInfo.coverImage.startsWith('file://') ||
                this.liveInfo.coverImage.startsWith('http://') ||
                this.liveInfo.coverImage.startsWith('https://')) {
              Image(this.liveInfo.coverImage)
                .width('100%')
                .height('100%')
                .objectFit(ImageFit.Cover)
            } else {
              // 使用 ImageUtil 解析 Mock 封面 key
              ReplaceableImage({ imageKey: this.liveInfo.coverImage, imgWidth: '100%', imgHeight: '100%', imgFit: ImageFit.Cover })
            }
          } else {
            Text('📹')
              .fontSize(120)
            Text(this.liveInfo?.title ?? '直播间')
              .fontSize(16)
              .fontColor(Color.White)
              .margin({ top: 12 })
          }
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

          // 中间区域：仅右侧操作按钮（垂直居中）
          Row() {
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

        // spec 16.10：弹幕独立浮动层，绝对贴左下角，不与右侧按钮挤压
        this.DanmakuList()

        // spec：小黄车（右下角显示正在卖的商品，spec 16.11：支持编辑）
        if (this.cartProducts.length > 0) {
          this.SmallCart()
        }
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

        // 主播头像（spec 16.9：同步注册用户头像，spec 16.15：同步卖家中心 shopLogo）
        if (this.anchorAvatar.length > 0 &&
            (this.anchorAvatar.startsWith('file://') || this.anchorAvatar.startsWith('http'))) {
          Image(this.anchorAvatar)
            .width(40)
            .height(40)
            .borderRadius(20)
            .border({ width: 1, color: 'rgba(255,255,255,0.6)' })
            .objectFit(ImageFit.Cover)
        } else if (this.anchorAvatar.length > 0) {
          // spec 16.15：资源名头像（如 avatar_farmer），同步卖家中心 shopLogo
          ReplaceableImage({ imageKey: this.anchorAvatar, imgWidth: 40, imgHeight: 40, imgRadius: 20, imgFit: ImageFit.Cover })
            .border({ width: 1, color: 'rgba(255,255,255,0.6)' })
        } else {
          Text('👤')
            .fontSize(20)
            .fontColor(Color.White)
            .width(40)
            .height(40)
            .borderRadius(20)
            .backgroundColor($r('app.color.color_cta_black'))
            .textAlign(TextAlign.Center)
        }

        // 昵称 + 在线人数（spec 16.9：主播名同步注册用户昵称，spec 16.15：姓名字体颜色改为黑色）
        Column({ space: 2 }) {
          Text(this.anchorName)
            .fontSize(13)
            .fontColor(Color.Black)
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

  /** 弹幕区 spec 16.10：绝对贴左下角，独立浮动层，不遮盖任何信息 */
  @Builder
  DanmakuList() {
    // 绝对定位弹幕容器：贴左下角，宽度 60%，避开顶部主播栏和底部互动栏
    Stack() {
      Column() {
        Scroll(this.danmakuScroller) {
          Column({ space: 6 }) {
            ForEach(this.danmakuList, (msg: DanmakuMessage, _idx: number) => {
              Row({ space: 6 }) {
                Text(`${msg.nickname}:`)
                  .fontSize(13)
                  .fontColor($r('app.color.color_accent_gold'))
                  .fontWeight(FontWeight.Medium)
                Text(msg.content)
                  .fontSize(13)
                  .fontColor(Color.White)
                  .layoutWeight(1)
              }
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .backgroundColor('rgba(0,0,0,0.45)')
              .borderRadius(12)
            }, (msg: DanmakuMessage) => msg.commentId)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .height('100%')
        .align(Alignment.Bottom)
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.End)
    }
    .width('58%')
    .height('35%')
    // spec 16.11：y=52% 往下移动，x=2 往左贴边，不遮盖任何信息
    .position({ x: 2, y: '52%' })
    .alignContent(Alignment.BottomStart)
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

  /** spec：小黄车（右下角显示正在卖的商品，类似抖音直播间） */
  @Builder
  SmallCart() {
    Column() {
      if (this.cartExpanded) {
        // 展开状态：显示商品列表（spec 16.11：支持滚动，避免商品多时被遮挡）
        Column({ space: 8 }) {
          // 标题栏（spec 16.9：主播端显示"管理"链接编辑入口，spec 16.15：标题栏可拖动）
          Row() {
            Text('⠿')
              .fontSize(13)
              .fontColor('rgba(255,255,255,0.6)')
            Text('正在卖')
              .fontSize(13)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
            Blank()
            if (this.role === 'broadcaster') {
              Text('✏️ 管理')
                .fontSize(11)
                .fontColor($r('app.color.color_accent_gold'))
                .onClick(() => {
                  if (this.isPureClick()) {
                    this.cartEditOpen = !this.cartEditOpen;
                  }
                })
            }
            Text('✕')
              .fontSize(14)
              .fontColor(Color.White)
              .onClick(() => {
                if (this.isPureClick()) {
                  this.cartExpanded = false;
                }
              })
          }
          .width('100%')
          .onTouch((event: TouchEvent) => { this.onCartTouch(event); })

          // spec 16.9：链接编辑面板（主播端，可增删小黄车商品链接）
          if (this.role === 'broadcaster' && this.cartEditOpen) {
            this.CartEditPanel()
          }

          // spec 16.13：商品列表 - 用 Scroll 包裹支持上下滚动，移除 maxHeight 限制
          Scroll() {
            Column({ space: 4 }) {
              ForEach(this.cartProducts, (product: FarmerProductItem, _idx: number) => {
                Row({ space: 8 }) {
                  Text('🌾')
                    .fontSize(24)
                    .width(40)
                    .height(40)
                    .borderRadius(6)
                    .backgroundColor('rgba(255,255,255,0.15)')
                    .textAlign(TextAlign.Center)
                  Column({ space: 2 }) {
                    Text(product.title)
                      .fontSize(12)
                      .fontColor(Color.White)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(`¥${product.price.toFixed(2)}`)
                      .fontSize(13)
                      .fontColor($r('app.color.color_price'))
                      .fontWeight(FontWeight.Bold)
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  // spec 16.9：编辑模式下显示移除按钮
                  if (this.role === 'broadcaster' && this.cartEditOpen) {
                    Text('✕')
                      .fontSize(12)
                      .fontColor($r('app.color.color_error'))
                      .width(20)
                      .height(20)
                      .textAlign(TextAlign.Center)
                      .onClick(() => { this.removeCartProduct(product.productId); })
                  }
                }
                .width('100%')
                .padding({ top: 4, bottom: 4 })
              }, (product: FarmerProductItem) => product.productId)
            }
            .width('100%')
          }
          // spec 16.14：layoutWeight(1) 撑满剩余空间，商品多时可上下滚动
          .layoutWeight(1)
          .scrollable(ScrollDirection.Vertical)
          .scrollBar(BarState.Auto)
          .constraintSize({ minHeight: 100 })
        }
        // spec 16.14：面板高度增大（编辑模式 55%，非编辑 38%），确保 Scroll 有足够空间显示新增商品
        .width(180)
        .height(this.cartEditOpen ? '55%' : '38%')
        .padding(10)
        .borderRadius(12)
        .backgroundColor('rgba(0,0,0,0.85)')
      } else {
        // 收起状态：显示第一个商品的缩略信息（spec 16.15：支持拖动）
        if (this.cartProducts.length > 0) {
          Row({ space: 8 }) {
            Text('🛒')
              .fontSize(20)
            Column({ space: 1 }) {
              Text(this.cartProducts[0].title)
                .fontSize(11)
                .fontColor(Color.White)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .constraintSize({ maxWidth: 100 })
              Text(`¥${this.cartProducts[0].price.toFixed(2)}`)
                .fontSize(12)
                .fontColor($r('app.color.color_price'))
                .fontWeight(FontWeight.Bold)
            }
            .alignItems(HorizontalAlign.Start)
            // 展开提示
            Text('▾')
              .fontSize(12)
              .fontColor(Color.White)
          }
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .borderRadius(20)
          .onTouch((event: TouchEvent) => { this.onCartTouch(event); })
          .backgroundColor('rgba(0,0,0,0.7)')
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            // spec 16.15：拖动后不触发展开，仅纯点击才展开
            if (this.isPureClick()) {
              this.cartExpanded = true;
            }
          })
        }
      }
    }
    // spec 16.15：使用绝对位置定位，支持拖动移动
    .position({ x: this.cartPosX, y: this.cartPosY })
  }

  /** spec 16.10：保存自定义挂链接 */
  private saveCustomLink(): void {
    const title: string = this.linkTitleInput.trim();
    const url: string = this.linkUrlInput.trim();
    if (title.length === 0 || url.length === 0) {
      ToastUtil.warning('请填写链接标题和地址');
      return;
    }
    const link: CustomLiveLink = {
      linkId: `link_${Date.now()}`,
      title: title,
      url: url
    };
    this.customLinks = this.customLinks.concat([link]);
    this.linkTitleInput = '';
    this.linkUrlInput = '';
    this.linkDialogOpen = false;
    ToastUtil.success('链接已挂载');
  }

  /** spec 16.10：删除自定义挂链接 */
  private removeCustomLink(linkId: string): void {
    this.customLinks = this.customLinks.filter((l: CustomLiveLink): boolean => l.linkId !== linkId);
  }

  /** spec 16.10：自定义挂链接展示卡（直播间外部展示，可点击进入编辑） */
  @Builder
  CustomLinksCard() {
    Column({ space: 6 }) {
      // 链接列表
      ForEach(this.customLinks, (link: CustomLiveLink, _idx: number) => {
        Row({ space: 6 }) {
          Text('🔗')
            .fontSize(14)
          Text(link.title)
            .fontSize(11)
            .fontColor($r('app.color.color_info'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          if (this.role === 'broadcaster') {
            Text('✕')
              .fontSize(11)
              .fontColor($r('app.color.color_error'))
              .width(18)
              .height(18)
              .textAlign(TextAlign.Center)
              .onClick(() => { this.removeCustomLink(link.linkId); })
          }
        }
        .width('100%')
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .borderRadius(8)
        .backgroundColor('rgba(0,0,0,0.7)')
      }, (link: CustomLiveLink) => link.linkId)

      // 主播端：挂链接按钮
      if (this.role === 'broadcaster') {
        Row({ space: 4 }) {
          Text('➕')
            .fontSize(12)
          Text('挂链接')
            .fontSize(11)
            .fontColor($r('app.color.color_accent_gold'))
        }
        .width('100%')
        .padding({ left: 8, right: 8, top: 5, bottom: 5 })
        .borderRadius(8)
        .backgroundColor('rgba(255,215,0,0.15)')
        .border({ width: 1, color: 'rgba(255,215,0,0.4)' })
        .onClick(() => { this.linkDialogOpen = true; })
      }
    }
    .width(180)
    .position({ x: '52%', y: this.customLinks.length > 0 ? '64%' : '68%' })
  }

  /** spec 16.10：挂链接输入弹窗 */
  @Builder
  LinkInputDialog() {
    Stack() {
      // 遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.7)')
        .onClick(() => { this.linkDialogOpen = false; })

      // 弹窗主体
      Column({ space: 12 }) {
        Row() {
          Text('挂载链接')
            .fontSize(16)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
          Text('×')
            .fontSize(22)
            .fontColor(Color.White)
            .width(32)
            .height(32)
            .textAlign(TextAlign.Center)
            .onClick(() => { this.linkDialogOpen = false; })
        }
        .width('100%')

        // 链接标题输入
        Column({ space: 4 }) {
          Text('链接标题')
            .fontSize(12)
            .fontColor('rgba(255,255,255,0.7)')
          TextInput({ text: this.linkTitleInput, placeholder: '例如：商品购买链接' })
            .height(40)
            .borderRadius(8)
            .backgroundColor('rgba(255,255,255,0.95)')
            .padding({ left: 12, right: 12 })
            .fontSize(13)
            .onChange((v: string) => { this.linkTitleInput = v; })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        // 链接 URL 输入
        Column({ space: 4 }) {
          Text('链接地址')
            .fontSize(12)
            .fontColor('rgba(255,255,255,0.7)')
          TextInput({ text: this.linkUrlInput, placeholder: 'https:// 或商品 ID' })
            .height(40)
            .borderRadius(8)
            .backgroundColor('rgba(255,255,255,0.95)')
            .padding({ left: 12, right: 12 })
            .fontSize(13)
            .onChange((v: string) => { this.linkUrlInput = v; })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        // 确认按钮
        Button('确认挂载')
          .width('100%')
          .height(42)
          .borderRadius(21)
          .backgroundColor($r('app.color.color_cta_black'))
          .fontColor(Color.White)
          .fontSize(14)
          .onClick(() => { this.saveCustomLink(); })
      }
      .width('80%')
      .padding(20)
      .borderRadius(16)
      .backgroundColor('rgba(20,20,20,0.95)')
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.Center)
  }

  /** spec 16.9/16.11：小黄车链接编辑面板（主播端，可手动输入上架或选择候选商品） */
  @Builder
  CartEditPanel() {
    Column({ space: 6 }) {
      // 标题
      Text('正在卖 - 管理商品')
        .fontSize(11)
        .fontColor('rgba(255,255,255,0.9)')
        .alignSelf(ItemAlign.Start)

      // spec 16.11：手动输入区域（输入商品名称和价格，点击上架）
      Column({ space: 4 }) {
        Text('📝 手动上架')
          .fontSize(10)
          .fontColor($r('app.color.color_accent_gold'))
          .alignSelf(ItemAlign.Start)

        // 商品名称输入
        TextInput({ text: this.newProductName, placeholder: '输入商品名称' })
          .fontSize(11)
          .fontColor(Color.White)
          .placeholderColor('rgba(255,255,255,0.4)')
          .placeholderFont({ size: 11 })
          .height(28)
          .padding({ left: 8, right: 8 })
          .backgroundColor('rgba(255,255,255,0.1)')
          .borderRadius(6)
          .onChange((value: string) => { this.newProductName = value; })

        // 价格输入
        Row({ space: 6 }) {
          TextInput({ text: this.newProductPrice, placeholder: '价格' })
            .fontSize(11)
            .fontColor(Color.White)
            .placeholderColor('rgba(255,255,255,0.4)')
            .placeholderFont({ size: 11 })
            .height(28)
            .width(70)
            .padding({ left: 8, right: 8 })
            .backgroundColor('rgba(255,255,255,0.1)')
            .borderRadius(6)
            .type(InputType.Number)
            .onChange((value: string) => { this.newProductPrice = value; })

          // 上架按钮
          Text('上架')
            .fontSize(11)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .height(28)
            .padding({ left: 12, right: 12 })
            .borderRadius(6)
            .backgroundColor($r('app.color.color_cta_black'))
            .textAlign(TextAlign.Center)
            .onClick(() => { this.addManualProduct(); })
        }
      }
      .width('100%')
      .padding(6)
      .borderRadius(8)
      .backgroundColor('rgba(255,217,61,0.1)')

      // 分割线
      Divider()
        .color('rgba(255,255,255,0.15)')
        .strokeWidth(1)

      // 候选商品列表（可选）
      if (this.candidateProducts.length > 0) {
        Text('📦 可选商品')
          .fontSize(10)
          .fontColor('rgba(255,255,255,0.7)')
          .alignSelf(ItemAlign.Start)

        ForEach(this.candidateProducts, (product: FarmerProductItem, _idx: number) => {
          Row({ space: 6 }) {
            Text('🌾')
              .fontSize(16)
              .width(24)
              .height(24)
              .textAlign(TextAlign.Center)
            Text(product.title)
              .fontSize(11)
              .fontColor(Color.White)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
            Text(`¥${product.price.toFixed(2)}`)
              .fontSize(10)
              .fontColor($r('app.color.color_price'))
            Text(this.cartProducts.some((p: FarmerProductItem): boolean => p.productId === product.productId) ? '✓' : '+')
              .fontSize(12)
              .fontColor(this.cartProducts.some((p: FarmerProductItem): boolean => p.productId === product.productId)
                ? $r('app.color.color_text_secondary') : $r('app.color.color_accent_gold'))
              .width(20)
              .height(20)
              .textAlign(TextAlign.Center)
              .onClick(() => {
                if (this.cartProducts.some((p: FarmerProductItem): boolean => p.productId === product.productId)) {
                  this.removeCartProduct(product.productId);
                } else {
                  this.addCartProduct(product.productId);
                }
              })
          }
          .width('100%')
          .padding({ top: 3, bottom: 3 })
        }, (product: FarmerProductItem) => product.productId)
      }
    }
    .width('100%')
    .padding({ top: 6, bottom: 6, left: 6, right: 6 })
    .borderRadius(8)
    .backgroundColor('rgba(0,0,0,0.7)')
  }
}
