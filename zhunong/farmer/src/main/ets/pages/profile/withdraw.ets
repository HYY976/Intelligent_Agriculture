/**
 * withdraw - 提现页（spec 3.2.4.5 / 9.3）
 *
 * - 顶部：可提现余额 + 冻结金额
 * - 中部：提现表单（金额 + 收款账号 Mock）
 * - 下部：提现记录列表
 *
 * 提现规则（spec 9.3）：
 *  - 订单确认收货后即可提现，无后台审核
 *  - 提现后状态变为"已提现"
 */

import { Logger, AppConstants, ToastUtil, NavigationHelper, RouteName, PageResult } from 'common';
import { Withdrawal, FarmerProfile } from '../../model/FarmerModels';
import { RevenueRepository } from '../../repository/RevenueRepository';
import { FarmerRepository } from '../../repository/FarmerRepository';
import { MOCK_FARMER_ID } from '../../mock/FarmerMock';

@ComponentV2
export struct Withdraw {
  /** 可提现余额 */
  @Local availableBalance: number = 0;
  /** 冻结金额 */
  @Local frozenBalance: number = 0;
  /** 提现金额输入 */
  @Local amountStr: string = '';
  /** 收款账号输入 */
  @Local account: string = '';
  /** 是否正在提交 */
  @Local isSubmitting: boolean = false;
  /** 提现记录列表 */
  @Local withdrawals: Withdrawal[] = [];
  /** 当前页码 */
  @Local page: number = 1;
  /** 是否正在加载记录 */
  @Local isLoadingRecords: boolean = false;
  /** 是否还有更多 */
  @Local hasMore: boolean = true;

  async aboutToAppear(): Promise<void> {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'withdraw_appear' });
    await this.loadBalance();
    await this.refreshRecords();
  }

  /** 加载余额 */
  private async loadBalance(): Promise<void> {
    try {
      const profile: FarmerProfile = await FarmerRepository.getMyProfile(MOCK_FARMER_ID);
      this.availableBalance = profile.availableBalance;
      this.frozenBalance = profile.frozenBalance;
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'load_balance_fail', error: (err as Error).message });
    }
  }

  /** 刷新提现记录 */
  private async refreshRecords(): Promise<void> {
    this.page = 1;
    this.withdrawals = [];
    this.hasMore = true;
    await this.loadMoreRecords();
  }

  /** 加载更多提现记录 */
  private async loadMoreRecords(): Promise<void> {
    if (this.isLoadingRecords || !this.hasMore) {
      return;
    }
    this.isLoadingRecords = true;
    try {
      const result: PageResult<Withdrawal> = await RevenueRepository.getWithdrawals(MOCK_FARMER_ID, this.page, 20);
      if (this.page === 1) {
        this.withdrawals = result.list;
      } else {
        this.withdrawals = this.withdrawals.concat(result.list);
      }
      this.hasMore = result.hasMore;
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'load_withdrawals_fail', error: (err as Error).message });
    } finally {
      this.isLoadingRecords = false;
    }
  }

  /** 全部提现 */
  private fillAllBalance(): void {
    this.amountStr = this.availableBalance.toFixed(2);
  }

  /** 校验 */
  private validateForm(): boolean {
    const amount: number = parseFloat(this.amountStr);
    if (isNaN(amount) || amount <= 0) {
      ToastUtil.warning('请输入有效的提现金额');
      return false;
    }
    if (amount > this.availableBalance) {
      ToastUtil.warning('提现金额不能超过可提现余额');
      return false;
    }
    if (this.account.length === 0) {
      ToastUtil.warning('请填写收款账号');
      return false;
    }
    return true;
  }

  /** 提交提现 */
  private async submitWithdraw(): Promise<void> {
    if (!this.validateForm()) {
      return;
    }
    this.isSubmitting = true;
    try {
      const amount: number = parseFloat(this.amountStr);
      await RevenueRepository.requestWithdraw(MOCK_FARMER_ID, amount, this.account);
      ToastUtil.success('提现申请已提交');
      Logger.info(AppConstants.SCENE_FARMER, { action: 'withdraw_success', amount });
      // 更新本地余额
      this.availableBalance -= amount;
      this.amountStr = '';
      // 刷新记录
      await this.refreshRecords();
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'withdraw_fail', error: (err as Error).message });
      ToastUtil.error('提现失败');
    } finally {
      this.isSubmitting = false;
    }
  }

  /** 格式化时间 */
  private formatTime(ts: number): string {
    const d: Date = new Date(ts);
    const yyyy: number = d.getFullYear();
    const mm: string = `${d.getMonth() + 1}`.padStart(2, '0');
    const dd: string = `${d.getDate()}`.padStart(2, '0');
    const hh: string = `${d.getHours()}`.padStart(2, '0');
    const mi: string = `${d.getMinutes()}`.padStart(2, '0');
    return `${yyyy}-${mm}-${dd} ${hh}:${mi}`;
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        Scroll() {
          Column({ space: 16 }) {
            this.BalanceCard()
            this.WithdrawFormCard()
            this.WithdrawRecordsSection()
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 24 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
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
      Text('提现')
        .fontSize(18)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** 余额卡片 */
  @Builder
  BalanceCard() {
    Column({ space: 12 }) {
      Text('可提现余额（元）')
        .fontSize(12)
        .fontColor('rgba(255,255,255,0.7)')
        .alignSelf(ItemAlign.Start)
      Text(`¥${this.availableBalance.toFixed(2)}`)
        .fontSize(32)
        .fontColor($r('app.color.color_text_on_dark'))
        .fontWeight(FontWeight.Bold)
      Row() {
        Column({ space: 2 }) {
          Text(`¥${this.frozenBalance.toFixed(2)}`)
            .fontSize(14)
            .fontColor('rgba(255,213,79,0.9)')
          Text('冻结金额')
            .fontSize(10)
            .fontColor('rgba(255,255,255,0.6)')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text('订单确认收货后即可提现，无审核')
          .fontSize(10)
          .fontColor('rgba(255,255,255,0.5)')
      }
      .width('100%')
    }
    .width('100%')
    .padding(20)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_panel_dark'))
  }

  /** 提现表单 */
  @Builder
  WithdrawFormCard() {
    Column({ space: 12 }) {
      Text('提现申请')
        .fontSize(14)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)
      Column({ space: 6 }) {
        Row() {
          Text('* 提现金额（元）')
            .fontSize(13)
            .fontColor($r('app.color.color_text_primary'))
            .layoutWeight(1)
          Text('全部提现')
            .fontSize(11)
            .fontColor($r('app.color.color_secondary'))
            .onClick(() => this.fillAllBalance())
        }
        .width('100%')
        TextInput({ text: this.amountStr, placeholder: '0.00' })
          .type(InputType.Number)
          .height(44)
          .borderRadius(8)
          .backgroundColor($r('app.color.color_bg_page'))
          .padding({ left: 12, right: 12 })
          .fontSize(14)
          .onChange((v: string) => { this.amountStr = v; })
      }
      .width('100%')
      Column({ space: 6 }) {
        Text('* 收款账号')
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
          .alignSelf(ItemAlign.Start)
        TextInput({ text: this.account, placeholder: '请输入收款账号（Mock）' })
          .height(44)
          .borderRadius(8)
          .backgroundColor($r('app.color.color_bg_page'))
          .padding({ left: 12, right: 12 })
          .fontSize(14)
          .maxLength(32)
          .onChange((v: string) => { this.account = v; })
      }
      .width('100%')
      Button(this.isSubmitting ? '提交中...' : '立即提现')
        .width('100%')
        .height(44)
        .borderRadius(22)
        .backgroundColor(this.isSubmitting ? $r('app.color.color_button_disabled') : $r('app.color.color_secondary'))
        .fontColor(Color.White)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .enabled(!this.isSubmitting)
        .onClick(() => this.submitWithdraw())
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 提现记录 */
  @Builder
  WithdrawRecordsSection() {
    Column({ space: 12 }) {
      Text(`提现记录 ${this.withdrawals.length}`)
        .fontSize(14)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)

      if (this.withdrawals.length === 0) {
        Text('暂无提现记录')
          .fontSize(12)
          .fontColor($r('app.color.color_text_hint'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 12, bottom: 12 })
      } else {
        ForEach(this.withdrawals, (record: Withdrawal, _idx: number) => {
          Row({ space: 12 }) {
            Column({ space: 2 }) {
              Text(`¥${record.amount.toFixed(2)}`)
                .fontSize(14)
                .fontColor($r('app.color.color_price'))
                .fontWeight(FontWeight.Bold)
              Text(`账号：${record.account}`)
                .fontSize(11)
                .fontColor($r('app.color.color_text_hint'))
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            Column({ space: 2 }) {
              Text('已完成')
                .fontSize(11)
                .fontColor($r('app.color.color_primary'))
                .fontWeight(FontWeight.Medium)
              Text(this.formatTime(record.createdAt))
                .fontSize(10)
                .fontColor($r('app.color.color_text_hint'))
            }
            .alignItems(HorizontalAlign.End)
          }
          .width('100%')
          .padding({ top: 10, bottom: 10 })
          .borderRadius(8)
          .backgroundColor($r('app.color.color_bg_page'))
        }, (record: Withdrawal) => record.withdrawalId)
        if (this.hasMore) {
          Text(this.isLoadingRecords ? '加载中...' : '上拉加载更多')
            .fontSize(11)
            .fontColor($r('app.color.color_text_hint'))
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 8, bottom: 8 })
            .onClick(() => {
              this.page++;
              this.loadMoreRecords();
            })
        }
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }
}
