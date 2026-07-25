/**
 * user_booking - 体验预约页（spec 3.1.4.3 扩展）
 * 对齐设计稿 pages/user-booking.html：
 *  - 顶部栏：返回 + 标题"体验预约" + 客服图标
 *  - 农场英雄卡片：180 高图片 + 渐变遮罩 + 距离胶囊 + 名称叠层 + 绿色 pill 标签 + 评分 + 价格行
 *  - 预约表单卡：
 *    1) 选择日期（横滑 7 个日期胶囊，黄色选中态 + 红色今日标记）
 *    2) 选择时段（上午/下午/全天 3 胶囊，黄色选中态）
 *    3) 预约人数（步进器：减号 + 数字 + 加号 + 单价副文案）
 *    4) 联系人信息（姓名 + 手机号输入框，左侧带图标）
 *  - 体验详情卡：标题 + 4 项体验包含（绿色 ✓ 图标） + 橙色温馨提示框
 *  - 底部固定预约栏：合计金额 + 立即预约（墨黑底）
 *
 * 设计稿底部 5 Tab 导航省略：本页由 POI 详情 push 进入，与 order_confirm 同属流程子页
 */

import { NavigationHelper, Logger, AppConstants, ToastUtil, RouteName } from 'common';
import { BookingExperience, BookingDate, BookingSlot, BookingInclude } from '../../model/TravelModels';
import { getMockBookingByPoiId } from '../../mock/TravelMock';
import { ImageUtil } from '../../utils/ImageUtil';

@ComponentV2
export struct UserBooking {
  /** POI ID */
  @Local poiId: string = '';
  /** 预约体验数据（对齐设计稿 hero + form + includes） */
  @Local booking: BookingExperience | null = null;
  /** 选中的日期 ID（对齐设计稿 .qn-date.is-on） */
  @Local selectedDateId: string = '';
  /** 选中的时段 ID（对齐设计稿 .qn-slot.is-on） */
  @Local selectedSlotId: 'morning' | 'afternoon' | 'fullday' = 'morning';
  /** 预约人数（对齐设计稿 .qn-step-num "2人"） */
  @Local peopleCount: number = 2;
  /** 联系人姓名 */
  @Local contactName: string = '';
  /** 联系人手机号 */
  @Local contactPhone: string = '';

  aboutToAppear(): void {
    const params: Record<string, string> = NavigationHelper.getParam<Record<string, string>>() as Record<string, string>;
    if (params) {
      this.poiId = params.poiId ?? '';
    }
    this.loadBookingData();
  }

  /** 加载预约数据 */
  private loadBookingData(): void {
    const data: BookingExperience | null = getMockBookingByPoiId(this.poiId);
    if (!data) {
      ToastUtil.error('该点位暂未开放预约');
      NavigationHelper.pop();
      return;
    }
    this.booking = data;
    // 默认选中第 3 天（周六，对齐设计稿 .qn-date.is-on）
    if (data.dateList.length >= 3) {
      this.selectedDateId = data.dateList[2].dateId;
    } else if (data.dateList.length > 0) {
      this.selectedDateId = data.dateList[0].dateId;
    }
    Logger.info(AppConstants.SCENE_USER, {
      action: 'booking_page_view',
      poiId: this.poiId
    });
  }

  /** 返回 */
  private goBack(): void {
    NavigationHelper.pop();
  }

  /** 联系客服 */
  private onContactService(): void {
    ToastUtil.info('客服功能开发中');
  }

  /** 选择日期 */
  private onDateSelect(date: BookingDate): void {
    this.selectedDateId = date.dateId;
    Logger.info(AppConstants.SCENE_USER, {
      action: 'booking_date_select',
      poiId: this.poiId,
      tab: date.dateId
    });
  }

  /** 选择时段 */
  private onSlotSelect(slot: BookingSlot): void {
    this.selectedSlotId = slot.slotId;
    Logger.info(AppConstants.SCENE_USER, {
      action: 'booking_slot_select',
      poiId: this.poiId,
      tab: slot.slotId
    });
  }

  /** 减少人数（最少 1） */
  private onPeopleMinus(): void {
    if (this.peopleCount > 1) {
      this.peopleCount--;
    }
  }

  /** 增加人数（最多 20） */
  private onPeoplePlus(): void {
    if (this.peopleCount < 20) {
      this.peopleCount++;
    }
  }

  /** 提交预约 */
  private onSubmitBooking(): void {
    if (this.contactName.length === 0) {
      ToastUtil.error('请输入联系人姓名');
      return;
    }
    if (this.contactPhone.length === 0) {
      ToastUtil.error('请输入手机号');
      return;
    }
    if (!/^1\d{10}$/.test(this.contactPhone)) {
      ToastUtil.error('手机号格式不正确');
      return;
    }
    const totalPrice: number = (this.booking ? this.booking.pricePerPerson : 0) * this.peopleCount;
    ToastUtil.success(`预约成功！合计 ¥${totalPrice}（开发中）`);
    Logger.info(AppConstants.SCENE_USER, {
      action: 'booking_submit',
      poiId: this.poiId,
      amount: totalPrice,
      quantity: this.peopleCount
    });
    NavigationHelper.pop();
  }

  build() {
    NavDestination() {
      Column() {
        if (this.booking) {
          // 1. 顶部栏
          this.TopBar()
          // 2. 内容滚动区
          Scroll() {
            Column({ space: 12 }) {
              // 3. 农场英雄卡片
              this.HeroCard(this.booking)
              // 4. 预约表单卡
              this.FormCard(this.booking)
              // 5. 体验详情卡
              this.IncludeCard(this.booking)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 100 })
            .alignItems(HorizontalAlign.Start)
          }
          .layoutWeight(1)
          .width('100%')
          .scrollBar(BarState.Off)
          // 6. 底部固定预约栏
          this.BottomBookBar(this.booking)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 顶部栏（对齐设计稿 .qn-topbar：返回 + 标题 + 客服） */
  @Builder
  TopBar() {
    Row() {
      // 返回按钮
      Row() {
        Text('‹')
          .fontSize(22)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .width(32)
      .height(32)
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor($r('app.color.color_bg_card'))
      .shadow(AppConstants.SHADOW_CARD)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { this.goBack(); })

      // 居中标题
      Text('体验预约')
        .fontSize(17)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 客服按钮
      Row() {
        Text('🎧')
          .fontSize(16)
          .fontColor($r('app.color.color_ink'))
      }
      .width(32)
      .height(32)
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor($r('app.color.color_bg_card'))
      .shadow(AppConstants.SHADOW_CARD)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { this.onContactService(); })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 50, bottom: 10 })
    .alignItems(VerticalAlign.Center)
  }

  /** 农场英雄卡片（对齐设计稿 .qn-hero：图 180 + 遮罩 + 距离 + 名称 + 标签 + 评分 + 价格行） */
  @Builder
  HeroCard(booking: BookingExperience) {
    Column({ space: 0 }) {
      // 顶部媒体区
      Stack({ alignContent: Alignment.TopStart }) {
        // 图片 180 高
        Image(ImageUtil.get(booking.coverImage))
          .width('100%')
          .height(180)
          .objectFit(ImageFit.Cover)

        // 渐变遮罩（上薄下厚，对齐设计稿 .qn-hero-mask）
        Column()
          .width('100%')
          .height(180)
          .linearGradient({
            direction: GradientDirection.Bottom,
            colors: [
              ['rgba(0,0,0,0.15)', 0],
              ['rgba(0,0,0,0)', 0.38],
              ['rgba(0,0,0,0)', 0.52],
              ['rgba(0,0,0,0.66)', 1]
            ]
          })

        // 右上距离胶囊（对齐设计稿 .qn-hero-dist）
        Row({ space: 3 }) {
          Text('📍')
            .fontSize(11)
          Text(booking.distanceText)
            .fontSize(11)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
        }
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor('rgba(26,26,26,0.55)')
        .position({ right: 12, top: 12 })

        // 左下名称 + 标签 + 评分（对齐设计稿 .qn-hero-info）
        Column({ space: 8 }) {
          // 名称
          Text(booking.poiName)
            .fontSize(22)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)

          // 绿色标签行
          Row({ space: 6 }) {
            ForEach(booking.tags, (tag: string) => {
              Text(tag)
                .fontSize(11)
                .fontColor($r('app.color.color_green_deep'))
                .fontWeight(FontWeight.Bold)
                .padding({ left: 9, right: 9, top: 3, bottom: 3 })
                .borderRadius(AppConstants.RADIUS_PILL)
                .backgroundColor($r('app.color.color_green_soft'))
            }, (tag: string) => tag)
          }
          .alignItems(VerticalAlign.Center)

          // 评分行
          Row({ space: 6 }) {
            Text('★')
              .fontSize(14)
              .fontColor($r('app.color.color_yellow_deep'))
            Text(`${booking.rating.toFixed(1)}分`)
              .fontSize(12)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
            Text('·')
              .fontSize(12)
              .fontColor('rgba(255,255,255,0.92)')
            Text(booking.bookingCountText)
              .fontSize(12)
              .fontColor('rgba(255,255,255,0.92)')
              .fontWeight(FontWeight.Bold)
          }
          .alignItems(VerticalAlign.Center)
        }
        .alignItems(HorizontalAlign.Start)
        .position({ left: 16, right: 16, bottom: 14 })
      }
      .width('100%')
      .height(180)

      // 底部价格行（对齐设计稿 .qn-hero-price）
      Row() {
        // 左侧价格 ¥58/人起
        Row({ space: 1 }) {
          Text('¥')
            .fontSize(12)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
            .baselineOffset(8)
          Text(`${booking.pricePerPerson}`)
            .fontSize(26)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
          Text('/人起')
            .fontSize(13)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
        }
        .alignItems(VerticalAlign.Bottom)

        // 右侧副文案
        Text(booking.priceSubtitle)
          .fontSize(12)
          .fontColor($r('app.color.color_text_3'))
          .layoutWeight(1)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 16 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .borderRadius(AppConstants.RADIUS_LG)
    .clip(true)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 预约表单卡（对齐设计稿 .qn-card：日期 + 时段 + 人数 + 联系人） */
  @Builder
  FormCard(booking: BookingExperience) {
    Column({ space: 18 }) {
      // 1. 选择日期
      this.DateField(booking)
      Divider().color($r('app.color.color_line')).width('100%')
      // 2. 选择时段
      this.SlotField(booking)
      Divider().color($r('app.color.color_line')).width('100%')
      // 3. 预约人数
      this.PeopleField(booking)
      Divider().color($r('app.color.color_line')).width('100%')
      // 4. 联系人信息
      this.ContactField()
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 日期字段（对齐设计稿 .qn-field + .qn-date-list 7 胶囊横滑） */
  @Builder
  DateField(booking: BookingExperience) {
    Column({ space: 11 }) {
      // 字段标签
      Row({ space: 6 }) {
        Text('📅')
          .fontSize(14)
        Text('选择日期')
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        Text('· 未来7天可约')
          .fontSize(11)
          .fontColor($r('app.color.color_text_3'))
      }
      .alignItems(VerticalAlign.Center)

      // 横滑日期列表
      Scroll() {
        Row({ space: 8 }) {
          ForEach(booking.dateList, (date: BookingDate) => {
            Column({ space: 3 }) {
              // 星期
              Text(date.weekLabel)
                .fontSize(11)
                .fontColor(this.getDateWeekColor(date))
                .fontWeight(FontWeight.Bold)
              // 日号
              Text(date.dayLabel)
                .fontSize(18)
                .fontColor(this.selectedDateId === date.dateId ? $r('app.color.color_ink') : $r('app.color.color_ink'))
                .fontWeight(FontWeight.Bold)
                .lineHeight(1)
            }
            .width(52)
            .padding({ top: 10, bottom: 10 })
            .borderRadius(AppConstants.RADIUS_MD)
            .backgroundColor(this.selectedDateId === date.dateId ? $r('app.color.color_yellow') : $r('app.color.color_fill'))
            .shadow(this.selectedDateId === date.dateId ? AppConstants.SHADOW_YELLOW : { radius: 0, color: Color.Transparent, offsetX: 0, offsetY: 0 })
            .alignItems(HorizontalAlign.Center)
            .onClick(() => { this.onDateSelect(date); })
          }, (date: BookingDate) => date.dateId)
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /** 时段字段（对齐设计稿 .qn-field + .qn-slot-row 3 胶囊） */
  @Builder
  SlotField(booking: BookingExperience) {
    Column({ space: 11 }) {
      Row({ space: 6 }) {
        Text('🕐')
          .fontSize(14)
        Text('选择时段')
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .alignItems(VerticalAlign.Center)

      Row({ space: 10 }) {
        ForEach(booking.slotList, (slot: BookingSlot) => {
          Column({ space: 2 }) {
            Text(slot.name)
              .fontSize(13)
              .fontColor($r('app.color.color_ink'))
              .fontWeight(FontWeight.Bold)
            Text(slot.timeRange)
              .fontSize(11)
              .fontColor(this.selectedSlotId === slot.slotId ? $r('app.color.color_ink_2') : $r('app.color.color_text_3'))
          }
          .layoutWeight(1)
          .padding({ top: 11, bottom: 11 })
          .borderRadius(AppConstants.RADIUS_MD)
          .backgroundColor(this.selectedSlotId === slot.slotId ? $r('app.color.color_yellow') : $r('app.color.color_fill'))
          .shadow(this.selectedSlotId === slot.slotId ? AppConstants.SHADOW_YELLOW : { radius: 0, color: Color.Transparent, offsetX: 0, offsetY: 0 })
          .alignItems(HorizontalAlign.Center)
          .onClick(() => { this.onSlotSelect(slot); })
        }, (slot: BookingSlot) => slot.slotId)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /** 人数字段（对齐设计稿 .qn-field + .qn-stepper-row） */
  @Builder
  PeopleField(booking: BookingExperience) {
    Column({ space: 11 }) {
      Row({ space: 6 }) {
        Text('👥')
          .fontSize(14)
        Text('预约人数')
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .alignItems(VerticalAlign.Center)

      Row() {
        // 步进器
        Row({ space: 16 }) {
          // 减号按钮
          Row() {
            Text('−')
              .fontSize(20)
              .fontColor(this.peopleCount > 1 ? $r('app.color.color_ink') : $r('app.color.color_text_3'))
              .fontWeight(FontWeight.Bold)
          }
          .width(32)
          .height(32)
          .borderRadius(16)
          .backgroundColor($r('app.color.color_fill'))
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .onClick(() => { this.onPeopleMinus(); })

          // 数字
          Text(`${this.peopleCount}人`)
            .fontSize(18)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
            .constraintSize({ minWidth: 42 })

          // 加号按钮
          Row() {
            Text('+')
              .fontSize(20)
              .fontColor($r('app.color.color_ink'))
              .fontWeight(FontWeight.Bold)
          }
          .width(32)
          .height(32)
          .borderRadius(16)
          .backgroundColor($r('app.color.color_fill'))
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .onClick(() => { this.onPeoplePlus(); })
        }
        .alignItems(VerticalAlign.Center)

        // 右侧单价副文案
        Text(`¥${booking.pricePerPerson}/人`)
          .fontSize(12)
          .fontColor($r('app.color.color_text_3'))
          .layoutWeight(1)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /** 联系人字段（对齐设计稿 .qn-field + .qn-input-wrap） */
  @Builder
  ContactField() {
    Column({ space: 11 }) {
      Row({ space: 6 }) {
        Text('👤')
          .fontSize(14)
        Text('联系人信息')
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .alignItems(VerticalAlign.Center)

      // 姓名输入框（带左侧图标）
      Row({ space: 10 }) {
        Text('👤')
          .fontSize(16)
          .fontColor($r('app.color.color_text_3'))
        TextInput({ text: this.contactName, placeholder: '请输入联系人姓名' })
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .placeholderFont({ size: 14 })
          .placeholderColor($r('app.color.color_text_4'))
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .height(46)
          .padding({ left: 0, right: 0 })
          .onChange((value: string) => {
            this.contactName = value;
          })
      }
      .width('100%')
      .height(46)
      .padding({ left: 16, right: 16 })
      .borderRadius(AppConstants.RADIUS_MD)
      .backgroundColor($r('app.color.color_fill'))
      .alignItems(VerticalAlign.Center)

      // 手机号输入框（带左侧图标）
      Row({ space: 10 }) {
        Text('📱')
          .fontSize(16)
          .fontColor($r('app.color.color_text_3'))
        TextInput({ text: this.contactPhone, placeholder: '请输入手机号' })
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .placeholderFont({ size: 14 })
          .placeholderColor($r('app.color.color_text_4'))
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .height(46)
          .padding({ left: 0, right: 0 })
          .type(InputType.PhoneNumber)
          .maxLength(11)
          .onChange((value: string) => {
            this.contactPhone = value;
          })
      }
      .width('100%')
      .height(46)
      .padding({ left: 16, right: 16 })
      .borderRadius(AppConstants.RADIUS_MD)
      .backgroundColor($r('app.color.color_fill'))
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /** 体验详情卡（对齐设计稿 .qn-card：标题 + 4 项 ✓ + 温馨提示） */
  @Builder
  IncludeCard(booking: BookingExperience) {
    Column({ space: 0 }) {
      // 字段标题
      Row({ space: 6 }) {
        Text('✓')
          .fontSize(14)
          .fontColor($r('app.color.color_green_deep'))
          .fontWeight(FontWeight.Bold)
        Text('体验包含')
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .alignItems(VerticalAlign.Center)

      // 体验包含列表
      ForEach(booking.includeList, (item: BookingInclude, idx: number) => {
        Row({ space: 10 }) {
          Text('✓')
            .fontSize(16)
            .fontColor($r('app.color.color_green_deep'))
            .fontWeight(FontWeight.Bold)
          Text(item.text)
            .fontSize(14)
            .fontColor($r('app.color.color_ink_2'))
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ top: 9, bottom: 9 })
        .alignItems(VerticalAlign.Center)
      }, (item: BookingInclude, idx: number) => `${idx}_${item.text.substring(0, 6)}`)

      // 温馨提示框（对齐设计稿 .qn-tip 橙色底）
      Row({ space: 8 }) {
        Text('⚠')
          .fontSize(16)
          .fontColor($r('app.color.color_warn'))
        Text(booking.tips)
          .fontSize(12)
          .fontColor('#9A5200')
          .lineHeight(18)
          .layoutWeight(1)
      }
      .width('100%')
      .padding(12)
      .margin({ top: 14 })
      .borderRadius(AppConstants.RADIUS_MD)
      .backgroundColor($r('app.color.color_warn_soft'))
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 底部固定预约栏（对齐设计稿 .qn-bookbar：合计 + 立即预约） */
  @Builder
  BottomBookBar(booking: BookingExperience) {
    Row() {
      // 左侧：合计金额 + 副文案
      Column({ space: 3 }) {
        Row({ space: 1 }) {
          Text('¥')
            .fontSize(14)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
            .baselineOffset(8)
          Text(`${booking.pricePerPerson * this.peopleCount}`)
            .fontSize(26)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
        }
        .alignItems(VerticalAlign.Bottom)
        Text(`合计 · ${this.peopleCount}人×¥${booking.pricePerPerson}`)
          .fontSize(11)
          .fontColor($r('app.color.color_text_3'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 右侧：立即预约按钮（墨黑底）
      Row() {
        Text('立即预约')
          .fontSize(16)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
      }
      .height(46)
      .padding({ left: 26, right: 26 })
      .borderRadius(AppConstants.RADIUS_MD)
      .backgroundColor($r('app.color.color_ink'))
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { this.onSubmitBooking(); })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 32 })
    .backgroundColor($r('app.color.color_bg_card'))
    .border({ width: { top: 1 }, color: $r('app.color.color_line') })
    .alignItems(VerticalAlign.Center)
  }

  /** 日期星期色（对齐设计稿：今日红色 / 选中态 ink-2 / 默认 text-3） */
  private getDateWeekColor(date: BookingDate): ResourceColor {
    if (this.selectedDateId === date.dateId) {
      return $r('app.color.color_ink_2');
    }
    if (date.isToday) {
      return $r('app.color.color_live');
    }
    return $r('app.color.color_text_3');
  }
}
