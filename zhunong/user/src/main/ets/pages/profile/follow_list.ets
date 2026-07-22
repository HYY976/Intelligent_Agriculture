/**
 * follow_list - 我的关注页
 * 遵循 spec 3.1.3.5：关注的卖家列表，支持取消关注
 *
 * spec 10.11.4 Step 2：ForEach → LazyForEach + keyGenerator + cachedCount
 */

import { AppConstants, ToastUtil, NavigationHelper, ListStateView } from 'common';
import { FollowItem } from '../../model/ProfileModels';
import { removeMockFollow } from '../../mock/ProfileMock';
import { FollowListDataSource } from '../../viewmodel/FollowListDataSource';
import { ImageUtil } from '../../utils/ImageUtil';

@ComponentV2
export struct FollowList {
  /** 关注数据源（spec 10.11.4：LazyForEach 替代 ForEach） */
  private dataSource: FollowListDataSource = new FollowListDataSource();
  /** 列表是否为空 */
  @Local isEmpty: boolean = true;

  async aboutToAppear(): Promise<void> {
    await this.refreshList();
  }

  /** 刷新列表（spec 10.11.4：异步 refresh + 空状态同步） */
  private async refreshList(): Promise<void> {
    await this.dataSource.refresh();
    this.isEmpty = this.dataSource.totalCount() === 0;
  }

  /** 取消关注 */
  private async onRemove(follow: FollowItem): Promise<void> {
    removeMockFollow(follow.followId);
    ToastUtil.success('已取消关注');
    await this.refreshList();
  }

  private gotoShop(follow: FollowItem): void {
    ToastUtil.show('店铺主页将在后续阶段实现');
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部栏
        Row() {
          Text('‹').fontSize(28).fontColor($r('app.color.color_text_primary')).onClick(() => { NavigationHelper.pop(); })
          Text('我的关注').fontSize(18).fontColor($r('app.color.color_text_primary')).fontWeight(FontWeight.Medium).layoutWeight(1).textAlign(TextAlign.Center)
          Text('').width(28)
        }
        .width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor($r('app.color.color_bg_card')).alignItems(VerticalAlign.Center)

        // 关注列表（spec 10.11.4 Step 4：4 态状态机 error / loading / empty / list）
        if (this.dataSource.getLoadFailed()) {
          ListStateView({ state: 'error', onRefresh: () => this.refreshList() })
        } else if (this.dataSource.getIsFirstLoad()) {
          ListStateView({ state: 'loading' })
        } else if (this.dataSource.totalCount() === 0) {
          ListStateView({ state: 'empty', emptyText: '暂无关注', emptyDesc: '关注喜欢的卖家，不错过新品' })
        } else {
          List({ space: 12 }) {
            LazyForEach(this.dataSource, (follow: FollowItem, _i: number) => {
              ListItem() {
                Row({ space: 12 }) {
                  Image(ImageUtil.get(follow.avatar)).width(56).height(56).borderRadius(28)
                  Column({ space: 4 }) {
                    Row({ space: 6 }) {
                      Text(follow.farmerName).fontSize(14).fontColor($r('app.color.color_text_primary')).fontWeight(FontWeight.Medium)
                      if (follow.certified) {
                        Text('✓').fontSize(10).fontColor(Color.White).backgroundColor($r('app.color.color_secondary')).borderRadius(8).padding({ left: 4, right: 4, top: 1, bottom: 1 })
                      }
                    }
                    Text(follow.shopIntro).fontSize(11).fontColor($r('app.color.color_text_secondary')).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                    Row({ space: 12 }) {
                      Text(`粉丝 ${this.formatCount(follow.fansCount)}`).fontSize(11).fontColor($r('app.color.color_text_hint'))
                      Text(`商品 ${follow.productCount}`).fontSize(11).fontColor($r('app.color.color_text_hint'))
                    }
                  }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                  Button('已关注').height(30).borderRadius(15).backgroundColor($r('app.color.color_bg_page')).fontColor($r('app.color.color_text_secondary')).fontSize(12).padding({ left: 12, right: 12 }).onClick(() => { this.onRemove(follow); })
                }.width('100%').padding(12).backgroundColor($r('app.color.color_bg_card')).borderRadius(12).onClick(() => { this.gotoShop(follow); })
              }
            }, (follow: FollowItem) => follow.followId)
          }
          .width('100%').layoutWeight(1).padding({ left: 12, right: 12, top: 12 }).scrollBar(BarState.Off)
          .cachedCount(AppConstants.LIST_CACHED_COUNT)
        }
      }
      .width('100%').height('100%').backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  private formatCount(count: number): string {
    if (count >= 10000) { return `${(count / 10000).toFixed(1)}万`; }
    return `${count}`;
  }

}
