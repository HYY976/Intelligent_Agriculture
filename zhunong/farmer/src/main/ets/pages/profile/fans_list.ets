/**
 * fans_list - 粉丝列表（spec 3.2.4.5）
 *
 * 粉丝列表展示：粉丝头像 + 昵称 + 关注时间
 * 双向关注体系（spec 3.2.4.5：卖家关注数 + 粉丝数在主页展示）
 */

import { Logger, AppConstants, NavigationHelper, ListStateView } from 'common';
import { FanInfo } from '../../model/FarmerModels';
import { FansListDataSource } from '../../viewmodel/FansListDataSource';

@ComponentV2
export struct FansList {
  /** 列表数据源（spec 10.11.4 Step 3：BaseDataSource + LazyForEach） */
  private dataSource: FansListDataSource = new FansListDataSource();
  /** 列表是否为空（用于三态空态判断） */
  @Local isEmpty: boolean = true;

  async aboutToAppear(): Promise<void> {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'fans_list_appear' });
    await this.refresh();
  }

  /** 刷新 */
  private async refresh(): Promise<void> {
    await this.dataSource.refresh();
    this.isEmpty = this.dataSource.totalCount() === 0;
  }

  /** 格式化时间 */
  private formatTime(ts: number): string {
    const d: Date = new Date(ts);
    const yyyy: number = d.getFullYear();
    const mm: string = `${d.getMonth() + 1}`.padStart(2, '0');
    const dd: string = `${d.getDate()}`.padStart(2, '0');
    return `${yyyy}-${mm}-${dd}`;
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        this.FansList()
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
      Text('粉丝列表')
        .fontSize(18)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
      Text(`${this.dataSource.totalCount()} 人`)
        .fontSize(12)
        .fontColor($r('app.color.color_text_secondary'))
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** 粉丝列表 */
  @Builder
  FansList() {
    if (this.dataSource.getLoadFailed()) {
      ListStateView({ state: 'error', onRefresh: () => this.refresh() })
    } else if (this.dataSource.getIsFirstLoad()) {
      ListStateView({ state: 'loading' })
    } else if (this.dataSource.totalCount() === 0) {
      ListStateView({ state: 'empty', emptyUseEmoji: true, emptyEmoji: '👥', emptyText: '暂无粉丝' })
    } else {
      List({ space: 0 }) {
        LazyForEach(this.dataSource, (fan: FanInfo, index: number) => {
          ListItem() {
            this.FanCard(fan)
          }
        }, (fan: FanInfo) => fan.userId + `_${fan.followedAt}`)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 12, right: 12, top: 8 })
      .scrollBar(BarState.Off)
      .cachedCount(AppConstants.LIST_CACHED_COUNT)
      .onReachEnd(() => {
        this.dataSource.loadMore();
      })
      .divider({
        strokeWidth: 0.5,
        color: $r('app.color.color_divider'),
        startMargin: 76,
        endMargin: 12
      })
    }
  }

  /** 粉丝卡片 */
  @Builder
  FanCard(fan: FanInfo) {
    Row({ space: 12 }) {
      Text('👤')
        .fontSize(24)
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor($r('app.color.color_primary_light'))
        .textAlign(TextAlign.Center)
      Column({ space: 4 }) {
        Text(fan.nickname)
          .fontSize(14)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Medium)
        Text(`关注于 ${this.formatTime(fan.followedAt)}`)
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text('发消息')
        .fontSize(12)
        .fontColor($r('app.color.color_secondary'))
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .borderRadius(14)
        .backgroundColor('rgba(255,152,0,0.1)')
        .onClick(() => {
          Logger.info(AppConstants.SCENE_FARMER, { action: 'goto_chat', userId: fan.userId });
        })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
  }
}
