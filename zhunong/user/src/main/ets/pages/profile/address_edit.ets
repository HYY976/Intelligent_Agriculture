/**
 * address_edit - 地址编辑/新增页
 * 表单：收货人 + 电话 + 省市区 + 详细地址 + 标签 + 默认地址开关
 */

import { Logger, AppConstants, ToastUtil, NavigationHelper } from 'common';
import { Address } from '../../model/ProfileModels';
import { MOCK_ADDRESSES, saveMockAddress } from '../../mock/ProfileMock';

/** 地址编辑页参数 */
interface AddressEditParam {
  addressId?: string;
}

@ComponentV2
export struct AddressEdit {
  @Local addressId: string = '';
  @Local isEdit: boolean = false;
  @Local receiverName: string = '';
  @Local phone: string = '';
  @Local province: string = '';
  @Local city: string = '';
  @Local district: string = '';
  @Local detail: string = '';
  @Local tag: string = '';
  @Local isDefault: boolean = false;

  aboutToAppear(): void {
    const params: AddressEditParam | undefined = NavigationHelper.getParam<AddressEditParam>();
    if (params && params.addressId) {
      this.addressId = params.addressId;
      this.isEdit = true;
      const found: Address | undefined = MOCK_ADDRESSES.find((a) => a.addressId === this.addressId);
      if (found) {
        this.receiverName = found.receiverName;
        this.phone = found.phone;
        this.province = found.province;
        this.city = found.city;
        this.district = found.district;
        this.detail = found.detail;
        this.tag = found.tag ?? '';
        this.isDefault = found.isDefault;
      }
    }
  }

  /** 保存 */
  private onSave(): void {
    if (this.receiverName.trim().length === 0) { ToastUtil.warning('请输入收货人姓名'); return; }
    if (this.phone.trim().length < 11) { ToastUtil.warning('请输入正确的手机号'); return; }
    if (this.province.trim().length === 0) { ToastUtil.warning('请选择省市区'); return; }
    if (this.detail.trim().length === 0) { ToastUtil.warning('请输入详细地址'); return; }
    const address: Address = {
      addressId: this.addressId.length > 0 ? this.addressId : `addr${Date.now()}`,
      receiverName: this.receiverName,
      phone: this.phone,
      province: this.province,
      city: this.city,
      district: this.district,
      detail: this.detail,
      isDefault: this.isDefault,
      tag: this.tag.length > 0 ? this.tag : undefined
    };
    saveMockAddress(address);
    Logger.info(AppConstants.SCENE_USER, JSON.stringify({ action: 'address_save', addressId: address.addressId, isEdit: this.isEdit }));
    ToastUtil.success('保存成功');
    NavigationHelper.pop();
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部栏
        Row() {
          Text('‹').fontSize(28).fontColor($r('app.color.color_text_primary')).onClick(() => { NavigationHelper.pop(); })
          Text(this.isEdit ? '编辑地址' : '新增地址').fontSize(18).fontColor($r('app.color.color_text_primary')).fontWeight(FontWeight.Medium).layoutWeight(1).textAlign(TextAlign.Center)
          Text('保存').fontSize(15).fontColor($r('app.color.color_primary')).onClick(() => { this.onSave(); })
        }
        .width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor($r('app.color.color_bg_card')).alignItems(VerticalAlign.Center)

        Scroll() {
          Column({ space: 12 }) {
            // 收货人
            this.FormInput('收货人', '请输入收货人姓名', this.receiverName, (v: string) => { this.receiverName = v; })
            // 电话
            this.FormInput('手机号', '请输入手机号', this.phone, (v: string) => { this.phone = v; })
            // 省市区
            Column({ space: 8 }) {
              Text('所在地区').fontSize(14).fontColor($r('app.color.color_text_primary')).alignSelf(ItemAlign.Start)
              Row() {
                TextInput({ text: this.province, placeholder: '省' }).fontSize(13).layoutWeight(1).height(40).backgroundColor($r('app.color.color_bg_page')).borderRadius(8).padding({ left: 12, right: 12 }).onChange((v: string) => { this.province = v; })
                Text(' ').width(8)
                TextInput({ text: this.city, placeholder: '市' }).fontSize(13).layoutWeight(1).height(40).backgroundColor($r('app.color.color_bg_page')).borderRadius(8).padding({ left: 12, right: 12 }).onChange((v: string) => { this.city = v; })
                Text(' ').width(8)
                TextInput({ text: this.district, placeholder: '区/县' }).fontSize(13).layoutWeight(1).height(40).backgroundColor($r('app.color.color_bg_page')).borderRadius(8).padding({ left: 12, right: 12 }).onChange((v: string) => { this.district = v; })
              }.width('100%')
            }
            .width('100%').padding(16).backgroundColor($r('app.color.color_bg_card')).borderRadius(12).margin({ left: 12, right: 12 }).alignItems(HorizontalAlign.Start)
            // 详细地址
            Column({ space: 8 }) {
              Text('详细地址').fontSize(14).fontColor($r('app.color.color_text_primary')).alignSelf(ItemAlign.Start)
              TextArea({ text: this.detail, placeholder: '请输入详细地址（街道、楼栋、门牌号）' }).fontSize(13).height(80).backgroundColor($r('app.color.color_bg_page')).borderRadius(8).padding(12).onChange((v: string) => { this.detail = v; })
            }
            .width('100%').padding(16).backgroundColor($r('app.color.color_bg_card')).borderRadius(12).margin({ left: 12, right: 12 }).alignItems(HorizontalAlign.Start)
            // 标签
            Column({ space: 8 }) {
              Text('标签').fontSize(14).fontColor($r('app.color.color_text_primary')).alignSelf(ItemAlign.Start)
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(['家', '公司', '学校', '其他'], (t: string, _i: number) => {
                  Text(t).fontSize(13).fontColor(this.tag === t ? Color.White : $r('app.color.color_text_secondary'))
                    .backgroundColor(this.tag === t ? $r('app.color.color_primary') : $r('app.color.color_bg_page'))
                    .padding({ left: 14, right: 14, top: 8, bottom: 8 }).margin({ right: 8, bottom: 8 }).borderRadius(16)
                    .onClick(() => { this.tag = this.tag === t ? '' : t; })
                }, (t: string) => t)
              }.width('100%')
            }
            .width('100%').padding(16).backgroundColor($r('app.color.color_bg_card')).borderRadius(12).margin({ left: 12, right: 12 }).alignItems(HorizontalAlign.Start)
            // 默认地址开关
            Row() {
              Text('设为默认地址').fontSize(14).fontColor($r('app.color.color_text_primary')).layoutWeight(1)
              Text(this.isDefault ? '✓' : '○').fontSize(20).fontColor(this.isDefault ? $r('app.color.color_primary') : $r('app.color.color_text_hint'))
                .onClick(() => { this.isDefault = !this.isDefault; })
            }
            .width('100%').height(52).padding({ left: 16, right: 16 }).backgroundColor($r('app.color.color_bg_card')).borderRadius(12).margin({ left: 12, right: 12 }).alignItems(VerticalAlign.Center)
          }
          .width('100%').padding({ top: 12, bottom: 24 })
        }
        .layoutWeight(1).width('100%').backgroundColor($r('app.color.color_bg_page')).scrollBar(BarState.Off)
      }
      .width('100%').height('100%').backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 表单输入项 */
  @Builder
  FormInput(label: string, placeholder: string, value: string, onChange: (v: string) => void) {
    Row() {
      Text(label).fontSize(14).fontColor($r('app.color.color_text_primary')).width(72)
      TextInput({ text: value, placeholder: placeholder }).fontSize(13).layoutWeight(1).height(40).backgroundColor($r('app.color.color_bg_page')).borderRadius(8).padding({ left: 12, right: 12 }).onChange((v: string) => { onChange(v); })
    }
    .width('100%').height(52).padding({ left: 16, right: 16 }).backgroundColor($r('app.color.color_bg_card')).borderRadius(12).margin({ left: 12, right: 12 }).alignItems(VerticalAlign.Center)
  }
}
