/**
 * follow_list - 我的关注页
 * 遵循 spec 3.1.3.5 + 设计稿 follow.html 1:1 复刻：
 *  - 顶栏：白色圆形返回按钮 + 居中标题"我的关注"
 *  - 卖家卡片（垂直列表 + 10px 间距）：头像(48×48，白+黄双层环) + 中间信息(名称+V认证标+简介+粉丝/商品) + 右侧"已关注"灰色pill按钮
 *
 * spec 10.11.4 Step 2：ForEach → LazyForEach + keyGenerator + cachedCount
 */

import { AppConstants, ToastUtil, NavigationHelper, ListStateView, Logger } from 'common';
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
    ToastUtil.info('店铺主页将在后续阶段实现');
    Logger.info(AppConstants.SCENE_USER, { action: 'follow_shop_click', farmerId: follow.farmerId });
  }

  build() {
    NavDestination() {
      Column() {
        // ===== 顶部导航栏（对齐设计稿 qn-topbar） =====
        Row() {
          // 白色圆形返回按钮
          Row() {
            Text('‹').fontSize(22).fontColor($r('app.color.color_ink')).fontWeight(FontWeight.Bold)
          }
          .width(32)
          .height(32)
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_bg_card'))
          .shadow(AppConstants.SHADOW_CARD)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .onClick(() => { NavigationHelper.pop(); })

          // 居中标题
          Text('我的关注')
            .fontSize(17)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          // 右侧占位（保持标题居中）
          Row().width(32).height(32)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 4, bottom: 10 })
        .alignItems(VerticalAlign.Center)

        // ===== 关注列表（spec 10.11.4 Step 4：4 态状态机 error / loading / empty / list） =====
        if (this.dataSource.getLoadFailed()) {
          ListStateView({ state: 'error', onRefresh: () => this.refreshList() })
        } else if (this.dataSource.getIsFirstLoad()) {
          ListStateView({ state: 'loading' })
        } else if (this.dataSource.totalCount() === 0) {
          ListStateView({ state: 'empty', emptyText: '暂无关注', emptyDesc: '关注喜欢的卖家，不错过新品' })
        } else {
          List({ space: 10 }) {
            LazyForEach(this.dataSource, (follow: FollowItem) => {
              ListItem() {
                this.FollowCard(follow)
              }
            }, (follow: FollowItem) => follow.followId)
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 16, right: 16, top: 4, bottom: 16 })
          .scrollBar(BarState.Off)
          .cachedCount(AppConstants.LIST_CACHED_COUNT)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 卖家卡片（对齐设计稿 qn-follow-card） */
  @Builder
  FollowCard(follow: FollowItem) {
    Row({ space: 12 }) {
      // ===== 头像（48×48，白+黄双层环，对齐设计稿 qn-follow-avatar） =====
      Stack() {
        Image(ImageUtil.get(follow.avatar))
          .width(48)
          .height(48)
          .borderRadius(AppConstants.RADIUS_PILL)
          .objectFit(ImageFit.Cover)
          .backgroundColor($r('app.color.color_fill'))
          .border({ width: 3, color: Color.White })
      }
      .width(54)
      .height(54)
      .borderRadius(AppConstants.RADIUS_PILL)
      .border({ width: 2, color: $r('app.color.color_yellow') })

      // ===== 中间信息（对齐设计稿 qn-follow-mid） =====
      Column({ space: 3 }) {
        // 名称行 + V 认证标（对齐设计稿 qn-follow-name-row + qn-v-badge）
        Row({ space: 4 }) {
          Text(follow.farmerName)
            .fontSize(15)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          // V 认证标（14×14 绿色圆 + 白色对勾）
          if (follow.certified) {
            Row() {
              Text('✓')
                .fontSize(9)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Bold)
            }
            .width(14)
            .height(14)
            .borderRadius(AppConstants.RADIUS_PILL)
            .backgroundColor($r('app.color.color_green'))
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 简介（12px text_2，1 行，对齐设计稿 qn-follow-desc）
        Text(follow.shopIntro)
          .fontSize(12)
          .fontColor($r('app.color.color_text_2'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 元信息（粉丝数 · 商品数，对齐设计稿 qn-follow-meta）
        Row({ space: 4 }) {
          Text(`粉丝 ${this.formatCount(follow.fansCount)}`)
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
          Text('·')
            .fontSize(12)
            .fontColor($r('app.color.color_text_4'))
          Text(`${follow.productCount}件商品`)
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
        }
        .alignItems(VerticalAlign.Center)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // ===== 右侧"已关注"按钮（对齐设计稿 qn-follow-action + qn-btn-ghost qn-btn-pill） =====
      Text('已关注')
        .fontSize(13)
        .fontColor($r('app.color.color_text_2'))
        .fontWeight(FontWeight.Bold)
        .height(32)
        .padding({ left: 14, right: 14 })
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor($r('app.color.color_fill'))
        .textAlign(TextAlign.Center)
        .onClick(() => { this.onRemove(follow); })
    }
    .width('100%')
    .padding(14)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(VerticalAlign.Center)
    .onClick(() => { this.gotoShop(follow); })
  }

  /** 格式化数量（万+） */
  private formatCount(count: number): string {
    if (count >= 10000) { return `${(count / 10000).toFixed(1)}万`; }
    return `${count}`;
  }
}
