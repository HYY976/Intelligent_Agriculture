/**
 * address_list - 收货地址列表页
 * 遵循 spec 3.1.3.5 + 设计稿 address-list.html 1:1 复刻：
 *  - 顶栏：白色圆形返回按钮 + 居中标题"收货地址" + 右侧"管理"文字
 *  - 地址卡：白底圆角卡 + 默认地址左侧 3px 绿色竖条 + 姓名/电话/默认标签 + 地址文本 + 编辑/删除操作
 *  - 右下角 FAB：56×56 黑色圆形"+"浮动按钮
 *  - 底部固定栏：白底 + 全宽"新增地址"黑色按钮
 *
 * spec 10.11.4 Step 2：ForEach → LazyForEach + keyGenerator + cachedCount
 */

import { Logger, AppConstants, ToastUtil, RouteName, NavigationHelper, ListStateView } from 'common';
import { Address } from '../../model/ProfileModels';
import { setMockDefaultAddress, deleteMockAddress } from '../../mock/ProfileMock';
import { AddressListDataSource } from '../../viewmodel/AddressListDataSource';

/** 地址列表参数 */
interface AddressListParam {
  from?: string;
}

/** 跳转地址编辑的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface AddressEditParam {
  addressId: string;
}

@ComponentV2
export struct AddressList {
  /** 地址列表数据源（spec 10.11.4：LazyForEach 替代 ForEach） */
  private dataSource: AddressListDataSource = new AddressListDataSource();
  /** 列表是否为空 */
  @Local isEmpty: boolean = true;
  /** 来源（order_confirm 选择地址时使用） */
  @Local from: string = '';

  async aboutToAppear(): Promise<void> {
    const params: AddressListParam | undefined = NavigationHelper.getParam<AddressListParam>();
    if (params && params.from) {
      this.from = params.from;
    }
    await this.refreshList();
  }

  /** 刷新列表（spec 10.11.4：异步 refresh + 空状态同步） */
  private async refreshList(): Promise<void> {
    await this.dataSource.refresh();
    this.isEmpty = this.dataSource.totalCount() === 0;
  }

  /** 新增地址 */
  private gotoAdd(): void {
    NavigationHelper.push(RouteName.USER_ADDRESS_EDIT);
  }

  /** 编辑地址 */
  private gotoEdit(address: Address): void {
    const param: AddressEditParam = { addressId: address.addressId };
    NavigationHelper.push(RouteName.USER_ADDRESS_EDIT, param);
  }

  /** 设为默认 */
  private async setDefault(address: Address): Promise<void> {
    setMockDefaultAddress(address.addressId);
    ToastUtil.success('已设为默认');
    await this.refreshList();
  }

  /** 删除地址 */
  private async onDelete(address: Address): Promise<void> {
    deleteMockAddress(address.addressId);
    ToastUtil.success('已删除');
    await this.refreshList();
  }

  /** 选择地址（从订单确认页进入时） */
  private onSelect(address: Address): void {
    if (this.from === 'order_confirm') {
      Logger.info(AppConstants.SCENE_USER, { action: 'select_address', addressId: address.addressId });
      NavigationHelper.pop();
    }
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.BottomEnd }) {
        // 主内容区
        Column() {
          this.TopBar()

          // 地址列表（spec 10.11.4 Step 4：4 态状态机 error / loading / empty / list）
          if (this.dataSource.getLoadFailed()) {
            ListStateView({ state: 'error', onRefresh: () => this.refreshList() })
          } else if (this.dataSource.getIsFirstLoad()) {
            ListStateView({ state: 'loading' })
          } else if (this.dataSource.totalCount() === 0) {
            this.EmptyView()
          } else {
            List({ space: 10 }) {
              LazyForEach(this.dataSource, (addr: Address, _i: number) => {
                ListItem() {
                  this.AddressCard(addr)
                }
              }, (addr: Address) => addr.addressId + `_${addr.isDefault}`)
            }
            .width('100%')
            .layoutWeight(1)
            .padding({ left: 16, right: 16, top: 12, bottom: 100 })
            .scrollBar(BarState.Off)
            .cachedCount(AppConstants.LIST_CACHED_COUNT)
          }

          // 底部固定新增按钮栏（对齐设计稿 qn-addr-footbar）
          this.BottomBar()
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.color_bg_page'))

        // 右下角 FAB（对齐设计稿 qn-addr-fab：56×56 黑色圆形）
        Row() {
          Text('+')
            .fontSize(26)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
        }
        .width(56)
        .height(56)
        .borderRadius(28)
        .backgroundColor($r('app.color.color_ink'))
        .shadow(AppConstants.SHADOW_FAB)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .margin({ right: 16, bottom: 78 })
        .onClick(() => { this.gotoAdd(); })
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
  }

  /** 顶栏（对齐设计稿 qn-topbar） */
  @Builder
  TopBar() {
    Row() {
      // 返回按钮（白色圆形）
      Row() {
        Text('‹')
          .fontSize(22)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .width(32)
      .height(32)
      .borderRadius(16)
      .backgroundColor($r('app.color.color_bg_card'))
      .shadow(AppConstants.SHADOW_CARD)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { NavigationHelper.pop(); })

      // 居中标题
      Text('收货地址')
        .fontSize(17)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 右侧"管理"文字
      Text('管理')
        .fontSize(14)
        .fontColor($r('app.color.color_text_3'))
        .fontWeight(FontWeight.Medium)
        .width(32)
        .textAlign(TextAlign.Center)
        .onClick(() => { ToastUtil.show('管理功能开发中'); })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 10 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** 地址卡片（对齐设计稿 qn-addr-card） */
  @Builder
  AddressCard(addr: Address) {
    Stack({ alignContent: Alignment.Start }) {
      // 卡片内容（白底圆角 + 阴影）
      Column({ space: 0 }) {
        // 顶行：姓名 + 电话 + 默认标签
        Row({ space: 10 }) {
          Text(addr.receiverName)
            .fontSize(16)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)

          Text(addr.phone)
            .fontSize(13)
            .fontColor($r('app.color.color_text_2'))

          Blank()

          // 默认标签（对齐设计稿 qn-pill-green）
          if (addr.isDefault) {
            Text('默认')
              .fontSize(11)
              .fontColor($r('app.color.color_green_deep'))
              .fontWeight(FontWeight.Bold)
              .padding({ left: 10, right: 10, top: 3, bottom: 3 })
              .borderRadius(AppConstants.RADIUS_PILL)
              .backgroundColor($r('app.color.color_green_soft'))
          }

          // 标签（家/学校/公司）
          if (addr.tag && addr.tag.length > 0) {
            Text(addr.tag)
              .fontSize(11)
              .fontColor($r('app.color.color_yellow_text'))
              .fontWeight(FontWeight.Bold)
              .padding({ left: 10, right: 10, top: 3, bottom: 3 })
              .borderRadius(AppConstants.RADIUS_PILL)
              .backgroundColor($r('app.color.color_yellow_soft'))
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 地址文本
        Text(`${addr.province}${addr.city}${addr.district} ${addr.detail}`)
          .fontSize(13)
          .fontColor($r('app.color.color_ink_2'))
          .margin({ top: 8 })
          .maxLines(2)

        // 分割线（对齐设计稿 qn-addr-divider）
        Divider()
          .color($r('app.color.color_line'))
          .strokeWidth(1)
          .margin({ top: 12, bottom: 10 })

        // 操作行（右对齐，对齐设计稿 qn-addr-actions）
        Row({ space: 22 }) {
          Blank()
          // 设为默认（非默认地址才显示）
          if (!addr.isDefault) {
            Row({ space: 4 }) {
              Text('⭐')
                .fontSize(14)
              Text('设为默认')
                .fontSize(13)
                .fontColor($r('app.color.color_text_3'))
            }
            .alignItems(VerticalAlign.Center)
            .onClick(() => { this.setDefault(addr); })
          }
          // 编辑
          Row({ space: 4 }) {
            Text('✏️')
              .fontSize(14)
            Text('编辑')
              .fontSize(13)
              .fontColor($r('app.color.color_text_3'))
          }
          .alignItems(VerticalAlign.Center)
          .onClick(() => { this.gotoEdit(addr); })

          // 删除
          Row({ space: 4 }) {
            Text('🗑️')
              .fontSize(14)
            Text('删除')
              .fontSize(13)
              .fontColor($r('app.color.color_text_3'))
          }
          .alignItems(VerticalAlign.Center)
          .onClick(() => { this.onDelete(addr); })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding(16)
      .backgroundColor($r('app.color.color_bg_card'))

      // 默认地址左侧 3px 绿色竖条（对齐设计稿 qn-addr-card.is-default::before）
      if (addr.isDefault) {
        Column()
          .width(3)
          .height('100%')
          .backgroundColor($r('app.color.color_green'))
      }
    }
    .width('100%')
    .borderRadius(AppConstants.RADIUS_LG)
    .clip(true)
    .shadow(AppConstants.SHADOW_CARD)
    .onClick(() => { this.onSelect(addr); })
  }

  /** 底部固定新增按钮栏（对齐设计稿 qn-addr-footbar） */
  @Builder
  BottomBar() {
    Row() {
      Button('新增地址')
        .width('100%')
        .height(46)
        .borderRadius(AppConstants.RADIUS_MD)
        .backgroundColor($r('app.color.color_ink'))
        .fontColor(Color.White)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .onClick(() => { this.gotoAdd(); })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_NAV)
  }

  /** 空状态（spec 10.13：4 态状态机） */
  @Builder
  EmptyView() {
    Column({ space: 12 }) {
      Text('📍')
        .fontSize(64)
      Text('暂无收货地址')
        .fontSize(14)
        .fontColor($r('app.color.color_text_secondary'))
      Button('新增地址')
        .height(36)
        .borderRadius(18)
        .backgroundColor($r('app.color.color_cta_black'))
        .fontColor(Color.White)
        .fontSize(14)
        .onClick(() => this.gotoAdd())
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
