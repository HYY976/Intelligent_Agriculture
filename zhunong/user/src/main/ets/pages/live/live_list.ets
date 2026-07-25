/**
 * live_list - 直播浏览页（仿抖音短视频直播架构）
 * 遵循 spec 3.1.4.2：
 *  - 全屏上下滑动切换直播间（Swiper 竖向）
 *  - 直播状态三态：预告（预约按钮）/ 直播中（占位流+互动入口）/ 已结束（回放封面+"直播已结束"）
 *  - 顶部返回 + 标题 + 搜索入口
 *  - 点击卡片进入完整直播间 pages/live/live_room?liveId=xxx
 * 数据源：LiveDataSource（LazyForEach + IDataSource）
 */

import { UserRoutes, RouteName, NavigationHelper, Logger, AppConstants } from 'common';
import { LiveListItem, getLiveStatusLabel, getLiveCategoryLabel } from '../../model/LiveModels';
import { LiveDataSource } from '../../viewmodel/LiveDataSource';
import { ImageUtil } from '../../utils/ImageUtil';

/** 跳转直播间的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface LiveRoomParam {
  liveId: string;
}

@ComponentV2
export struct LiveList {
  /** 直播列表数据源 */
  private liveDataSource: LiveDataSource = new LiveDataSource();
  /** 当前 Swiper 索引 */
  @Local currentIndex: number = 0;

  async aboutToAppear(): Promise<void> {
    await this.liveDataSource.refresh();
    Logger.info(AppConstants.SCENE_USER, { action: 'live_list_appear' });
  }

  /** 返回上一页 */
  private goBack(): void {
    NavigationHelper.pop();
  }

  /** 跳转搜索页 */
  private gotoSearch(): void {
    NavigationHelper.push(RouteName.USER_SEARCH_PAGE);
  }

  /** 进入直播间 */
  private enterLiveRoom(liveId: string): void {
    const param: LiveRoomParam = { liveId: liveId };
    NavigationHelper.push(RouteName.USER_LIVE_ROOM, param);
  }

  /** 预约直播（Mock） */
  private reserveLive(liveId: string): void {
    Logger.info(AppConstants.SCENE_USER, { action: 'live_reserve', liveId: liveId });
  }

  /** Swiper 切换 */
  private onSwiperChange(index: number): void {
    this.currentIndex = index;
    Logger.info(AppConstants.SCENE_USER, { action: 'live_swiper_change', index: index });
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        // 全屏直播流 Swiper（竖向）spec 15.6.4：空状态处理
        if (this.liveDataSource.totalCount() === 0) {
          // 空状态 spec 15.6.4：引导文案 + 主 CTA 按钮
          Column({ space: 12 }) {
            Text('📺')
              .fontSize(64)
            Text('暂无直播')
              .fontSize(18)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
            Text('暂无正在直播的内容，稍后再来看看吧')
              .fontSize(13)
              .fontColor('rgba(255,255,255,0.7)')
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Button('刷新看看')
              .height(40)
              .borderRadius(20)
              .backgroundColor($r('app.color.color_cta_black'))
              .fontColor(Color.White)
              .fontSize(14)
              .padding({ left: 24, right: 24 })
              .margin({ top: 12 })
              .onClick(async () => {
                await this.liveDataSource.refresh();
              })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .padding({ left: 32, right: 32 })
        } else {
          Swiper() {
            LazyForEach(this.liveDataSource, (item: LiveListItem, index: number) => {
              LiveRoomCard({
                item: item,
                onEnter: (liveId: string) => {
                  this.enterLiveRoom(liveId);
                },
                onReserve: (liveId: string) => {
                  this.reserveLive(liveId);
                }
              })
            }, (item: LiveListItem) => item.liveId + `_${item.status}_${item.likeCount}`)
          }
          .vertical(true)
          .indicator(false)
          .loop(false)
          .cachedCount(AppConstants.LIST_CACHED_COUNT)
          .width('100%')
          .height('100%')
          .onChange((index: number) => {
            this.onSwiperChange(index);
          })
        }

        // 顶部导航栏（半透明浮层）
        this.TopBar()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_panel_dark'))
    }
    .hideTitleBar(true)
  }

  /** 顶部导航栏（半透明浮层，避开状态栏） */
  @Builder
  TopBar() {
    Row({ space: 16 }) {
      // 返回按钮
      Text('←')
        .fontSize(24)
        .fontColor(Color.White)
        .onClick(() => {
          this.goBack();
        })

      // 标题
      Text('助农直播')
        .fontSize(18)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)

      // 搜索入口
      Text('🔍')
        .fontSize(20)
        .fontColor(Color.White)
        .onClick(() => {
          this.gotoSearch();
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16, top: 36 })
    .alignItems(VerticalAlign.Center)
  }
}

/**
 * LiveRoomCard - 直播间卡片（Swiper 内单页）
 * 全屏背景图 + 渐变遮罩 + 顶部主播信息 + 底部标题/互动 + 右侧操作按钮
 * 三状态差异化展示（spec 3.1.4.2）
 */
@ComponentV2
struct LiveRoomCard {
  /** 直播数据 */
  @Param item: LiveListItem | null = null;
  /** 进入直播间回调 */
  @Event onEnter: (liveId: string) => void = () => {};
  /** 预约直播回调 */
  @Event onReserve: (liveId: string) => void = () => {};

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      // 全屏背景图（直播封面/回放封面）
      Stack() {
        Image(this.item ? ImageUtil.get(this.item.coverImage) : ImageUtil.getDefaultProduct())
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
        // 黑色渐变遮罩（顶部+底部，增强文字可读性）
        Column() {
          Column()
            .width('100%')
            .height(120)
            .linearGradient({
              direction: GradientDirection.Bottom,
              colors: [['rgba(0,0,0,0.5)', 0], ['rgba(0,0,0,0)', 1]]
            })
          Blank()
          Column()
            .width('100%')
            .height(280)
            .linearGradient({
              direction: GradientDirection.Top,
              colors: [['rgba(0,0,0,0.6)', 0], ['rgba(0,0,0,0)', 1]]
            })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('100%')
      .height('100%')

      // 顶部主播信息栏
      if (this.item) {
        this.TopAnchorBar(this.item)
      }

      // 底部内容区：标题 + 介绍 + 状态标签 + 操作按钮
      if (this.item) {
        this.BottomContent(this.item)
      }

      // 右侧悬浮操作按钮
      if (this.item) {
        this.RightActions(this.item)
      }
    }
    .width('100%')
    .height('100%')
  }

  /** 顶部主播信息栏 */
  @Builder
  TopAnchorBar(item: LiveListItem) {
    Row({ space: 8 }) {
      // 主播头像
      Image(ImageUtil.get(item.anchorAvatar))
        .width(40)
        .height(40)
        .borderRadius(20)
        .border({ width: 2, color: Color.White })
      // 主播昵称
      Text(item.anchorName)
        .fontSize(14)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      // 关注按钮 spec 15.6.4：未关注态黄底黑字
      Text(item.isFollowing ? '已关注' : '+ 关注')
        .fontSize(12)
        .fontColor(item.isFollowing ? Color.White : $r('app.color.color_text_primary'))
        .backgroundColor(item.isFollowing ? 'rgba(255,255,255,0.2)' : $r('app.color.color_card_yellow'))
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .borderRadius(12)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 100 })
    .alignItems(VerticalAlign.Center)
  }

  /** 底部内容区 */
  @Builder
  BottomContent(item: LiveListItem) {
    Column({ space: 8 }) {
      // 状态标签 + 分类标签 + 在线人数
      Row({ space: 8 }) {
        // 状态标签（三状态差异化）
        Text(getLiveStatusLabel(item.status))
          .fontSize(11)
          .fontColor(Color.White)
          .backgroundColor(this.statusColor(item.status))
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(4)
        // 分类标签
        Text(getLiveCategoryLabel(item.category))
          .fontSize(11)
          .fontColor(Color.White)
          .backgroundColor('rgba(255,255,255,0.2)')
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(4)
        // 在线人数 / 累计 UV
        Text(this.formatViewCount(item))
          .fontSize(11)
          .fontColor(Color.White)
      }
      .alignItems(VerticalAlign.Center)

      // 直播标题
      Text(item.title)
        .fontSize(16)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 开播介绍
      Text(item.intro)
        .fontSize(12)
        .fontColor('rgba(255,255,255,0.85)')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 主操作按钮（三状态差异化）
      this.PrimaryAction(item)
    }
    .width('100%')
    .padding({ left: 16, right: 72, bottom: 40 })
    .alignItems(HorizontalAlign.Start)
  }

  /** 主操作按钮：直播中→进入直播间 / 预告→预约 / 已结束→观看回放 */
  @Builder
  PrimaryAction(item: LiveListItem) {
    Text(this.primaryActionLabel(item.status))
      .fontSize(14)
      .fontColor(Color.White)
      .backgroundColor($r('app.color.color_cta_black'))
      .padding({ left: 20, right: 20, top: 8, bottom: 8 })
      .borderRadius(20)
      .onClick(() => {
        if (item.status === 'preview') {
          this.onReserve(item.liveId);
        } else {
          this.onEnter(item.liveId);
        }
      })
  }

  /** 右侧悬浮操作按钮（点赞/分享） */
  @Builder
  RightActions(item: LiveListItem) {
    Column({ space: 20 }) {
      // 点赞数
      Column({ space: 4 }) {
        Text('❤️')
          .fontSize(32)
        Text(this.formatCount(item.likeCount))
          .fontSize(11)
          .fontColor(Color.White)
      }
      .alignItems(HorizontalAlign.Center)

      // 分享
      Column({ space: 4 }) {
        Text('分享')
          .fontSize(11)
          .fontColor(Color.White)
        Text('🔗')
          .fontSize(28)
      }
      .alignItems(HorizontalAlign.Center)

      // 商品袋入口 spec 15.6.4：黄色背景 + 黑字
      if (item.productBag.length > 0) {
        Column({ space: 4 }) {
          Text('🛍️')
            .fontSize(32)
          Text(`${item.productBag.length}件`)
            .fontSize(11)
            .fontColor($r('app.color.color_text_primary'))
        }
        .alignItems(HorizontalAlign.Center)
        .padding({ left: 8, right: 8, top: 6, bottom: 6 })
        .borderRadius(24)
        .backgroundColor($r('app.color.color_card_yellow'))
        .onClick(() => {
          this.onEnter(item.liveId);
        })
      }
    }
    .position({ right: 12, bottom: 160 })
    .alignItems(HorizontalAlign.Center)
  }

  /** 状态标签背景色 */
  private statusColor(status: string): Resource | string {
    if (status === 'living') {
      return $r('app.color.color_error');
    }
    if (status === 'preview') {
      return $r('app.color.color_secondary');
    }
    return 'rgba(255,255,255,0.3)';
  }

  /** 主操作按钮文案 */
  private primaryActionLabel(status: string): string {
    if (status === 'living') {
      return '进入直播间 →';
    }
    if (status === 'preview') {
      return '📅 预约直播';
    }
    return '▶ 观看回放';
  }

  /** 格式化观看人数文案 */
  private formatViewCount(item: LiveListItem): string {
    if (item.status === 'living') {
      return `🔥 ${this.formatCount(item.onlineCount)} 人正在观看`;
    }
    if (item.status === 'ended') {
      return `回放 · ${this.formatCount(item.totalViewUv)} 次观看`;
    }
    return `预约 ${this.formatCount(item.likeCount)} 人`;
  }

  /** 格式化数字（>=10000 显示万） */
  private formatCount(count: number): string {
    if (count >= 10000) {
      return `${(count / 10000).toFixed(1)}万`;
    }
    return `${count}`;
  }
}
