/**
 * address_edit - 地址编辑/新增页
 * 遵循 spec 3.1.3.5 + 设计稿 address-edit.html 1:1 复刻：
 *  - 顶栏：白色圆形返回按钮 + 居中标题
 *  - 表单卡：收件人/手机号/所在地区/详细地址（行高 56px + 1px 分割线）
 *  - 默认地址 Toggle 行（绿色开关 44×24）
 *  - 标签选择区（家/公司/学校，黄色选中态）
 *  - 底部固定保存按钮栏（黑色全宽按钮）
 */

import { Logger, AppConstants, ToastUtil, NavigationHelper, RouteName } from 'common';
import { Address } from '../../model/ProfileModels';
import { MOCK_ADDRESSES, saveMockAddress } from '../../mock/ProfileMock';

/** 地址编辑页参数 */
interface AddressEditParam {
  addressId?: string;
}

/** 标签选项 */
interface TagOption {
  label: string;
  value: string;
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

  /** 标签选项（对齐设计稿 qn-tag-list） */
  private tagOptions: TagOption[] = [
    { label: '家', value: '家' },
    { label: '公司', value: '公司' },
    { label: '学校', value: '学校' }
  ];

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
    Logger.info(AppConstants.SCENE_USER, { action: 'address_save', addressId: address.addressId });
    ToastUtil.success('保存成功');
    NavigationHelper.pop();
  }

  /** 获取地区显示文本 */
  private getRegionText(): string {
    if (this.province.length === 0 && this.city.length === 0 && this.district.length === 0) {
      return '请选择';
    }
    return `${this.province}${this.city}${this.district}`;
  }

  build() {
    NavDestination() {
      Column() {
        // 顶栏（对齐设计稿 qn-topbar）
        this.TopBar()

        // 内容区（对齐设计稿 qn-aedit-body）
        Scroll() {
          Column({ space: 12 }) {
            // 表单卡（对齐设计稿 qn-form-card）
            this.FormCard()

            // 默认地址 Toggle 行（对齐设计稿 qn-default-row）
            this.DefaultToggleRow()

            // 标签选择区（对齐设计稿 qn-tag-list）
            this.TagSelectCard()
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 4, bottom: 80 })
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor($r('app.color.color_bg_page'))
        .scrollBar(BarState.Off)

        // 底部固定保存按钮栏（对齐设计稿 qn-save-bar）
        this.BottomSaveBar()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
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
      Text(this.isEdit ? '编辑地址' : '新增地址')
        .fontSize(17)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 右侧占位（保持标题居中）
      Column().width(32)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 10 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** 表单卡（对齐设计稿 qn-form-card：行高 56px + 1px 分割线） */
  @Builder
  FormCard() {
    Column({ space: 0 }) {
      // 收件人
      this.FormRow('收件人', this.receiverName, '请输入姓名', (v: string) => { this.receiverName = v; })

      Divider().color($r('app.color.color_line')).strokeWidth(1)

      // 手机号
      this.FormRow('手机号', this.phone, '请输入手机号', (v: string) => { this.phone = v; })

      Divider().color($r('app.color.color_line')).strokeWidth(1)

      // 所在地区（三输入行，对齐设计稿 qn-region-row）
      Row({ space: 8 }) {
        Text('所在地区')
          .fontSize(15)
          .fontColor($r('app.color.color_ink_2'))
          .fontWeight(FontWeight.Medium)
          .width(72)

        TextInput({ text: this.province, placeholder: '省' })
          .fontSize(15)
          .layoutWeight(1)
          .height('100%')
          .backgroundColor(Color.Transparent)
          .padding(0)
          .onChange((v: string) => { this.province = v; })

        TextInput({ text: this.city, placeholder: '市' })
          .fontSize(15)
          .layoutWeight(1)
          .height('100%')
          .backgroundColor(Color.Transparent)
          .padding(0)
          .onChange((v: string) => { this.city = v; })

        TextInput({ text: this.district, placeholder: '区/县' })
          .fontSize(15)
          .layoutWeight(1)
          .height('100%')
          .backgroundColor(Color.Transparent)
          .padding(0)
          .onChange((v: string) => { this.district = v; })
      }
      .width('100%')
      .height(56)
      .alignItems(VerticalAlign.Center)

      Divider().color($r('app.color.color_line')).strokeWidth(1)

      // 详细地址
      Row({ space: 12 }) {
        Text('详细地址')
          .fontSize(15)
          .fontColor($r('app.color.color_ink_2'))
          .fontWeight(FontWeight.Medium)
          .width(72)

        TextInput({ text: this.detail, placeholder: '街道、楼牌号等' })
          .fontSize(15)
          .layoutWeight(1)
          .height('100%')
          .backgroundColor(Color.Transparent)
          .padding(0)
          .onChange((v: string) => { this.detail = v; })
      }
      .width('100%')
      .height(56)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 表单行（label + input，对齐设计稿 qn-form-row） */
  @Builder
  FormRow(label: string, value: string, placeholder: string, onChange: (v: string) => void) {
    Row({ space: 12 }) {
      Text(label)
        .fontSize(15)
        .fontColor($r('app.color.color_ink_2'))
        .fontWeight(FontWeight.Medium)
        .width(72)

      TextInput({ text: value, placeholder: placeholder })
        .fontSize(15)
        .layoutWeight(1)
        .height('100%')
        .backgroundColor(Color.Transparent)
        .padding(0)
        .onChange((v: string) => { onChange(v); })
    }
    .width('100%')
    .height(56)
    .alignItems(VerticalAlign.Center)
  }

  /** 默认地址 Toggle 行（对齐设计稿 qn-default-row + qn-toggle） */
  @Builder
  DefaultToggleRow() {
    Row() {
      Text('设为默认地址')
        .fontSize(15)
        .fontColor($r('app.color.color_ink_2'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)

      // Toggle 开关（44×24，对齐设计稿 qn-toggle）
      Stack({ alignContent: this.isDefault ? Alignment.End : Alignment.Start }) {
        Column()
          .width(20)
          .height(20)
          .borderRadius(10)
          .backgroundColor(Color.White)
          .shadow({ radius: 3, color: 'rgba(0,0,0,0.15)', offsetX: 0, offsetY: 1 })
          .margin(2)
      }
      .width(44)
      .height(24)
      .borderRadius(12)
      .backgroundColor(this.isDefault ? $r('app.color.color_green') : '#E0E0E0')
      .onClick(() => { this.isDefault = !this.isDefault; })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(VerticalAlign.Center)
  }

  /** 标签选择区（对齐设计稿 qn-tag-head + qn-tag-list） */
  @Builder
  TagSelectCard() {
    Column({ space: 12 }) {
      Text('标签')
        .fontSize(13)
        .fontColor($r('app.color.color_text_2'))
        .fontWeight(FontWeight.Bold)
        .alignSelf(ItemAlign.Start)

      Row({ space: 8 }) {
        ForEach(this.tagOptions, (opt: TagOption, _i: number) => {
          Text(opt.label)
            .fontSize(13)
            .fontColor(this.tag === opt.value ? $r('app.color.color_ink') : $r('app.color.color_text_2'))
            .fontWeight(this.tag === opt.value ? FontWeight.Bold : FontWeight.Medium)
            .padding({ left: 18, right: 18, top: 6, bottom: 6 })
            .borderRadius(AppConstants.RADIUS_PILL)
            .backgroundColor(this.tag === opt.value ? $r('app.color.color_yellow') : $r('app.color.color_fill'))
            .onClick(() => { this.tag = this.tag === opt.value ? '' : opt.value; })
        }, (opt: TagOption) => opt.value)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 底部固定保存按钮栏（对齐设计稿 qn-save-bar） */
  @Builder
  BottomSaveBar() {
    Row() {
      Button('保存地址')
        .width('100%')
        .height(46)
        .borderRadius(AppConstants.RADIUS_MD)
        .backgroundColor($r('app.color.color_ink'))
        .fontColor(Color.White)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .onClick(() => { this.onSave(); })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_NAV)
  }
}
