/**
 * address_list - 收货地址列表页
 * 遵循 spec 3.1.3.5：地址管理（增删改查 + 默认地址 + 编辑跳转）
 *
 * spec 10.11.4 Step 2：ForEach → LazyForEach + keyGenerator + cachedCount
 */

import { UserRoutes, Logger, AppConstants, ToastUtil, RouteName, NavigationHelper, ListStateView } from 'common';
import { Address } from '../../model/ProfileModels';
import { setMockDefaultAddress, deleteMockAddress, getMockDefaultAddress } from '../../mock/ProfileMock';
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
      Logger.info(AppConstants.SCENE_USER, JSON.stringify({ action: 'select_address', addressId: address.addressId }));
      NavigationHelper.pop();
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部栏
        Row() {
          Text('‹').fontSize(28).fontColor($r('app.color.color_text_primary')).onClick(() => { NavigationHelper.pop(); })
          Text('收货地址').fontSize(18).fontColor($r('app.color.color_text_primary')).fontWeight(FontWeight.Medium).layoutWeight(1).textAlign(TextAlign.Center)
          Text('+').fontSize(28).fontColor($r('app.color.color_primary')).onClick(() => { this.gotoAdd(); })
        }
        .width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor($r('app.color.color_bg_card')).alignItems(VerticalAlign.Center)

        // 地址列表（spec 10.11.4 Step 4：4 态状态机 error / loading / empty / list）
        if (this.dataSource.getLoadFailed()) {
          ListStateView({ state: 'error', onRefresh: () => this.refreshList() })
        } else if (this.dataSource.getIsFirstLoad()) {
          ListStateView({ state: 'loading' })
        } else if (this.dataSource.totalCount() === 0) {
          this.EmptyView()
        } else {
        List({ space: 12 }) {
          LazyForEach(this.dataSource, (addr: Address, _i: number) => {
            ListItem() {
              Column({ space: 8 }) {
                Row({ space: 8 }) {
                  Text(addr.receiverName).fontSize(14).fontColor($r('app.color.color_text_primary')).fontWeight(FontWeight.Medium)
                  Text(addr.phone).fontSize(13).fontColor($r('app.color.color_text_secondary'))
                  if (addr.isDefault) {
                    Text('默认').fontSize(10).fontColor(Color.White).backgroundColor($r('app.color.color_primary')).borderRadius(4).padding({ left: 4, right: 4, top: 1, bottom: 1 })
                  }
                  if (addr.tag && addr.tag.length > 0) {
                    Text(addr.tag).fontSize(10).fontColor($r('app.color.color_secondary')).border({ width: 1, color: $r('app.color.color_secondary') }).borderRadius(4).padding({ left: 4, right: 4, top: 1, bottom: 1 })
                  }
                }
                Text(`${addr.province}${addr.city}${addr.district} ${addr.detail}`).fontSize(12).fontColor($r('app.color.color_text_secondary'))
                Divider().color($r('app.color.color_divider'))
                Row() {
                  if (!addr.isDefault) {
                    Text('设为默认').fontSize(12).fontColor($r('app.color.color_text_secondary')).onClick(() => { this.setDefault(addr); })
                  }
                  Blank()
                  Text('编辑').fontSize(12).fontColor($r('app.color.color_text_secondary')).margin({ right: 16 }).onClick(() => { this.gotoEdit(addr); })
                  Text('删除').fontSize(12).fontColor($r('app.color.color_error')).onClick(() => { this.onDelete(addr); })
                }.width('100%')
              }
              .width('100%').padding(16).backgroundColor($r('app.color.color_bg_card')).borderRadius(12)
              .onClick(() => { this.onSelect(addr); })
            }
          }, (addr: Address) => addr.addressId + `_${addr.isDefault}`)
        }
        .width('100%').layoutWeight(1).padding({ left: 12, right: 12, top: 12 }).scrollBar(BarState.Off)
        .cachedCount(AppConstants.LIST_CACHED_COUNT)
        }

        // 底部新增按钮
        Button('+ 新增收货地址')
          .width('90%').height(44).borderRadius(22).backgroundColor($r('app.color.color_primary')).fontColor(Color.White).fontSize(15)
          .margin({ bottom: 16 })
          .onClick(() => { this.gotoAdd(); })
      }
      .width('100%').height('100%').backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
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
        .backgroundColor($r('app.color.color_primary'))
        .fontColor(Color.White)
        .fontSize(14)
        .onClick(() => this.gotoAdd())
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

}
