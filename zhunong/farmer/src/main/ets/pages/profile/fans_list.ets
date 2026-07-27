/**
 * fans_list - 粉丝列表（spec 3.2.4.5）
 *
 * 对齐设计稿 pages/fans-list.html：
 *  - 顶部导航栏（圆形返回键 + 居中标题 + 右侧粉丝总数）
 *  - 黄色渐变统计条（总粉丝 / 本月新增 / 互动率）
 *  - 粉丝卡（白底圆角 + 阴影）：头像 + 昵称 + 关注时间 + 右侧"互相关注/回关"按钮
 *
 * 双向关注体系：spec 3.2.4.5 卖家关注数 + 粉丝数在主页展示
 */

import { Logger, AppConstants, NavigationHelper, ListStateView, ToastUtil } from 'common';
import { FanInfo, FarmerProfile } from '../../model/FarmerModels';
import { FansListDataSource } from '../../viewmodel/FansListDataSource';
import { FarmerRepository } from '../../repository/FarmerRepository';
import { MOCK_FARMER_ID } from '../../mock/FarmerMock';
import { ImageUtil } from '../../utils/ImageUtil';

@ComponentV2
export struct FansList {
  /** 列表数据源（spec 10.11.4 Step 3：BaseDataSource + LazyForEach） */
  private dataSource: FansListDataSource = new FansListDataSource();
  /** 列表是否为空（用于三态空态判断） */
  @Local isEmpty: boolean = true;
  /** 卖家信息（用于顶部统计条数据） */
  @Local profile: FarmerProfile | null = null;

  async aboutToAppear(): Promise<void> {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'fans_list_appear' });
    await this.refresh();
    await this.loadProfile();
  }

  /** 加载卖家信息（用于顶部统计条） */
  private async loadProfile(): Promise<void> {
    try {
      this.profile = await FarmerRepository.getMyProfile(MOCK_FARMER_ID);
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'load_profile_fail', error: (err as Error).message });
    }
  }

  /** 刷新 */
  private async refresh(): Promise<void> {
    await this.dataSource.refresh();
    this.isEmpty = this.dataSource.totalCount() === 0;
  }

  /** 格式化相对时间（"3天前"/"1周前"/"2个月前"） */
  private formatRelative(ts: number): string {
    const diff: number = Date.now() - ts;
    const day: number = Math.floor(diff / 86400000);
    if (day < 1) {
      return '今天';
    }
    if (day < 7) {
      return `${day}天前`;
    }
    if (day < 30) {
      return `${Math.floor(day / 7)}周前`;
    }
    if (day < 365) {
      return `${Math.floor(day / 30)}个月前`;
    }
    return `${Math.floor(day / 365)}年前`;
  }

  /** 切换关注状态 */
  private toggleFollow(fan: FanInfo): void {
    fan.isMutual = !fan.isMutual;
    Logger.info(AppConstants.SCENE_FARMER, { action: fan.isMutual ? 'follow_mutual' : 'follow_cancel', userId: fan.userId });
    if (fan.isMutual) {
      ToastUtil.success(`已回关 ${fan.nickname}`);
    } else {
      ToastUtil.info(`已取消关注 ${fan.nickname}`);
    }
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        this.StatsBar()
        this.FansListArea()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_cream'))
    }
    .hideTitleBar(true)
  }

  /** 顶部导航栏（圆形白底返回键 + 居中标题 + 右侧总数） */
  @Builder
  TopBar() {
    Row() {
      // 圆形返回键
      Text('‹')
        .fontSize(20)
        .fontColor($r('app.color.color_ink'))
        .width(32)
        .height(32)
        .borderRadius(16)
        .backgroundColor($r('app.color.color_bg_card'))
        .shadow(AppConstants.SHADOW_CARD)
        .textAlign(TextAlign.Center)
        .onClick(() => NavigationHelper.pop())
      // 居中标题
      Text('我的粉丝')
        .fontSize(17)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      // 右侧粉丝总数
      Text(`${this.profile?.fansCount ?? this.dataSource.totalCount()}`)
        .fontSize(12)
        .fontColor($r('app.color.color_text_3'))
        .fontWeight(FontWeight.Medium)
        .width(32)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16, bottom: 10 })
    .alignItems(VerticalAlign.Center)
  }

  /** 黄色统计条（总粉丝 / 本月新增 / 互动率） */
  @Builder
  StatsBar() {
    Row() {
      this.StatItem(`${this.profile?.fansCount ?? this.dataSource.totalCount()}`, '总粉丝')
      this.StatSep()
      this.StatItem(`+${this.profile?.monthlyNewFans ?? 0}`, '本月新增')
      this.StatSep()
      this.StatItem(`${this.profile?.interactionRate ?? 0}%`, '互动率')
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .borderRadius(AppConstants.RADIUS_LG)
    .linearGradient({
      angle: 135,
      colors: [[$r('app.color.color_yellow'), 0.0], [$r('app.color.color_yellow_deep'), 1.0]]
    })
    .shadow({ radius: 18, color: 'rgba(255,217,61,0.35)', offsetX: 0, offsetY: 6 })
    .margin({ left: 16, right: 16, bottom: 14 })
  }

  /** 单个统计项 */
  @Builder
  StatItem(value: string, label: string) {
    Column({ space: 2 }) {
      Text(value)
        .fontSize(17)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
      Text(label)
        .fontSize(11)
        .fontColor('rgba(51,51,51,0.75)')
        .fontWeight(FontWeight.Medium)
    }
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)
  }

  /** 统计项分隔竖线 */
  @Builder
  StatSep() {
    Column()
      .width(1)
      .height(24)
      .backgroundColor('rgba(26,26,26,0.12)')
  }

  /** 粉丝列表区（4 态） */
  @Builder
  FansListArea() {
    if (this.dataSource.getLoadFailed()) {
      ListStateView({ state: 'error', onRefresh: () => this.refresh() })
    } else if (this.dataSource.getIsFirstLoad()) {
      ListStateView({ state: 'loading' })
    } else if (this.dataSource.totalCount() === 0) {
      ListStateView({ state: 'empty', emptyUseEmoji: true, emptyEmoji: '👥', emptyText: '暂无粉丝' })
    } else {
      List({ space: 10 }) {
        LazyForEach(this.dataSource, (fan: FanInfo) => {
          ListItem() {
            this.FanCard(fan)
          }
        }, (fan: FanInfo) => fan.userId + `_${fan.isMutual ? 1 : 0}`)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 16, right: 16, bottom: 16 })
      .scrollBar(BarState.Off)
      .cachedCount(AppConstants.LIST_CACHED_COUNT)
      .onReachEnd(() => {
        this.dataSource.loadMore();
      })
    }
  }

  /** 粉丝卡片（白底圆角 + 阴影） */
  @Builder
  FanCard(fan: FanInfo) {
    Row({ space: 12 }) {
      // 头像（spec 16.11：支持 emoji 头像，每个粉丝显示不同头像）
      if (fan.avatar && fan.avatar.length <= 4 && /[\p{Emoji_Presentation}\p{Extended_Pictographic}]/u.test(fan.avatar)) {
        // emoji 头像：用 Text 渲染，圆形背景
        Text(fan.avatar)
          .fontSize(24)
          .width(40)
          .height(40)
          .textAlign(TextAlign.Center)
          .borderRadius(20)
          .backgroundColor($r('app.color.color_fill'))
      } else {
        // 图片头像：使用 ImageUtil 加载
        Image(ImageUtil.get(fan.avatar))
          .width(40)
          .height(40)
          .borderRadius(20)
          .objectFit(ImageFit.Cover)
          .backgroundColor($r('app.color.color_fill'))
      }
      // 中间信息
      Column({ space: 3 }) {
        Row({ space: 6 }) {
          Text(fan.nickname)
            .fontSize(14)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (fan.isNew) {
            // 新粉标签
            Text('NEW')
              .fontSize(9)
              .fontColor($r('app.color.color_green_deep'))
              .backgroundColor($r('app.color.color_green_soft'))
              .padding({ left: 6, right: 6, top: 1, bottom: 1 })
              .borderRadius(AppConstants.RADIUS_PILL)
              .fontWeight(FontWeight.Bold)
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        // 关注时间子行
        Row({ space: 4 }) {
          Text('关注了你')
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
          Text('·')
            .fontSize(12)
            .fontColor($r('app.color.color_text_4'))
          Text(this.formatRelative(fan.followedAt))
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      // 右侧按钮
      this.FollowButton(fan)
    }
    .width('100%')
    .padding(14)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      Logger.info(AppConstants.SCENE_FARMER, { action: 'goto_chat', userId: fan.userId });
      ToastUtil.info('打开聊天功能开发中');
    })
  }

  /** 关注按钮（互相关注 / 回关） */
  @Builder
  FollowButton(fan: FanInfo) {
    Row({ space: 3 }) {
      Text(fan.isMutual ? '✓' : '+')
        .fontSize(13)
        .fontColor(fan.isMutual ? $r('app.color.color_text_3') : $r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
      Text(fan.isMutual ? '互相关注' : '回关')
        .fontSize(12)
        .fontColor(fan.isMutual ? $r('app.color.color_text_2') : $r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
    }
    .height(30)
    .padding({ left: 14, right: 14 })
    .borderRadius(AppConstants.RADIUS_PILL)
    .backgroundColor(fan.isMutual ? $r('app.color.color_fill') : $r('app.color.color_yellow'))
    .alignItems(VerticalAlign.Center)
    .onClick(() => this.toggleFollow(fan))
  }
}
