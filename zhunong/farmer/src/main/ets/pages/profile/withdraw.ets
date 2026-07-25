/**
 * withdraw - 提现页
 * 对齐设计稿 pages/withdraw.html：
 *  - 顶部导航栏：返回键 + "提现"标题 + 隐藏占位
 *  - 余额卡（深色面板 #1A1A1A：可提现余额(元) + 眼睛图标 + 8,680.50浅绿 + 冻结金额¥1,200.00 + 提现规则›）
 *  - 提现表单卡（提现金额 + ¥大字输入框 + 全部提现链接 + 分割线 + 收款账号输入框）
 *  - 立即提现按钮（黄色全宽）
 *  - 提现记录卡（提现记录 + 查看更多› + 4条记录：金额+状态胶囊 / 账号+时间）
 *
 * spec 3.2.4.5 / 9.3：订单确认收货后即可提现，无后台审核
 */

import { Logger, AppConstants, ToastUtil, NavigationHelper, PageResult } from 'common';
import { Withdrawal, FarmerProfile } from '../../model/FarmerModels';
import { RevenueRepository } from '../../repository/RevenueRepository';
import { FarmerRepository } from '../../repository/FarmerRepository';
import { MOCK_FARMER_ID, MOCK_WITHDRAWALS } from '../../mock/FarmerMock';

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
  /** 余额是否可见 */
  @Local balanceVisible: boolean = true;
  /** 提现记录列表 */
  @Local withdrawals: Withdrawal[] = [];

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
    try {
      const result: PageResult<Withdrawal> = await RevenueRepository.getWithdrawals(MOCK_FARMER_ID, 1, 20);
      this.withdrawals = result.list;
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'load_withdrawals_fail', error: (err as Error).message });
      this.withdrawals = MOCK_WITHDRAWALS.slice();
    }
  }

  /** 全部提现 */
  private fillAllBalance(): void {
    this.amountStr = this.availableBalance.toFixed(2);
  }

  /** 切换余额显隐 */
  private toggleBalanceVisible(): void {
    this.balanceVisible = !this.balanceVisible;
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
      this.availableBalance -= amount;
      this.amountStr = '';
      await this.refreshRecords();
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'withdraw_fail', error: (err as Error).message });
      ToastUtil.error('提现失败');
    } finally {
      this.isSubmitting = false;
    }
  }

  /** 格式化时间（yyyy-MM-dd HH:mm） */
  private formatTime(ts: number): string {
    const d: Date = new Date(ts);
    const yyyy: number = d.getFullYear();
    const mm: string = `${d.getMonth() + 1}`.padStart(2, '0');
    const dd: string = `${d.getDate()}`.padStart(2, '0');
    const hh: string = `${d.getHours()}`.padStart(2, '0');
    const mi: string = `${d.getMinutes()}`.padStart(2, '0');
    return `${yyyy}-${mm}-${dd} ${hh}:${mi}`;
  }

  /** 获取余额展示文案 */
  private getBalanceText(): string {
    if (!this.balanceVisible) {
      return '******';
    }
    return this.availableBalance.toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  }

  build() {
    NavDestination() {
      Column() {
        // 1. 顶部导航栏
        this.TopBar()
        // 2. 内容滚动区
        Scroll() {
          Column({ space: 12 }) {
            // a) 余额卡（深色面板）
            this.BalanceCard()
            // b) 提现表单卡
            this.WithdrawFormCard()
            // c) 立即提现按钮
            this.SubmitButton()
            // d) 提现记录卡
            this.WithdrawRecordsCard()
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 24 })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 顶部导航栏（对齐 qn-topbar：返回键 + 居中标题 + 占位） */
  @Builder
  TopBar() {
    Row() {
      // 返回键
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
      .onClick(() => NavigationHelper.pop())

      // 居中标题
      Text('提现')
        .fontSize(17)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 占位
      Row()
        .width(32)
        .height(32)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 10 })
    .alignItems(VerticalAlign.Center)
  }

  /** 余额卡（对齐 qn-balance-card：深黑底 + 余额 + 眼睛 + 冻结 + 规则） */
  @Builder
  BalanceCard() {
    Column() {
      // 顶部行：标签 + 眼睛图标
      Row() {
        Text('可提现余额(元)')
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.55)')
          .fontWeight(FontWeight.Medium)
        Blank()
        Row() {
          Text(this.balanceVisible ? '👁' : '🙈')
            .fontSize(16)
        }
        .width(30)
        .height(30)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .onClick(() => { this.toggleBalanceVisible(); })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      // 余额大字（浅绿 #81C784）
      Text(this.getBalanceText())
        .fontSize(32)
        .fontColor($r('app.color.color_green_mint'))
        .fontWeight(FontWeight.Bold)
        .letterSpacing(0.5)
        .margin({ top: 8 })

      // 底部行：冻结金额 + 提现规则
      Row() {
        Text(`冻结金额 ¥${this.frozenBalance.toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`)
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.5)')
        Blank()
        Row() {
          Text('提现规则')
            .fontSize(12)
            .fontColor('rgba(255,255,255,0.55)')
            .fontWeight(FontWeight.Medium)
          Text('›')
            .fontSize(12)
            .fontColor('rgba(255,255,255,0.55)')
        }
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .margin({ top: 16 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(20)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_dark_panel'))
    .shadow(AppConstants.SHADOW_FLOAT)
  }

  /** 提现表单卡（对齐 qn-card：提现金额 + ¥输入框 + 全部提现 + 收款账号） */
  @Builder
  WithdrawFormCard() {
    Column() {
      // 标题
      Text('提现金额')
        .fontSize(14)
        .fontColor($r('app.color.color_ink_2'))
        .fontWeight(FontWeight.Bold)
        .alignSelf(ItemAlign.Start)

      // ¥ + 金额输入框
      Row({ space: 8 }) {
        Text('¥')
          .fontSize(26)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        TextInput({ text: this.amountStr, placeholder: '0.00' })
          .type(InputType.Number)
          .fontSize(30)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .placeholderFont({ size: 30, weight: FontWeight.Bold })
          .placeholderColor($r('app.color.color_text_4'))
          .backgroundColor(Color.Transparent)
          .padding({ left: 0, right: 0 })
          .layoutWeight(1)
          .height(40)
          .onChange((v: string) => { this.amountStr = v; })
      }
      .width('100%')
      .margin({ top: 12 })
      .alignItems(VerticalAlign.Center)

      // 全部提现链接
      Row() {
        Text('全部提现')
          .fontSize(13)
          .fontColor($r('app.color.color_green_deep'))
          .fontWeight(FontWeight.Bold)
        Text('›')
          .fontSize(13)
          .fontColor($r('app.color.color_green_deep'))
          .fontWeight(FontWeight.Bold)
      }
      .alignSelf(ItemAlign.End)
      .margin({ top: 6 })
      .onClick(() => { this.fillAllBalance(); })

      // 分割线
      Divider()
        .strokeWidth(1)
        .color($r('app.color.color_line'))
        .margin({ top: 8 })

      // 收款账号行
      Row({ space: 12 }) {
        Text('收款账号')
          .fontSize(14)
          .fontColor($r('app.color.color_ink_2'))
          .fontWeight(FontWeight.Medium)
        TextInput({ text: this.account, placeholder: '请输入支付宝/银行卡' })
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .placeholderColor($r('app.color.color_text_4'))
          .backgroundColor(Color.Transparent)
          .padding({ left: 0, right: 0 })
          .layoutWeight(1)
          .height(48)
          .maxLength(32)
          .onChange((v: string) => { this.account = v; })
      }
      .width('100%')
      .height(48)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 立即提现按钮（对齐 qn-btn-yellow qn-btn-block：黄色全宽） */
  @Builder
  SubmitButton() {
    Row() {
      Text(this.isSubmitting ? '提交中...' : '立即提现')
        .fontSize(15)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .height(46)
    .borderRadius(AppConstants.RADIUS_MD)
    .backgroundColor(this.isSubmitting ? $r('app.color.color_text_4') : $r('app.color.color_yellow'))
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .opacity(this.isSubmitting ? 0.7 : 1)
    .onClick(() => { this.submitWithdraw(); })
  }

  /** 提现记录卡（对齐 qn-card qn-record-card：标题 + 查看更多 + 记录列表） */
  @Builder
  WithdrawRecordsCard() {
    Column() {
      // 标题行
      Row() {
        Text('提现记录')
          .fontSize(16)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        Blank()
        Row() {
          Text('查看更多')
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
          Text('›')
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
        }
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding({ top: 4, bottom: 12 })

      // 记录列表
      if (this.withdrawals.length === 0) {
        Text('暂无提现记录')
          .fontSize(12)
          .fontColor($r('app.color.color_text_3'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 24, bottom: 24 })
      } else {
        ForEach(this.withdrawals, (record: Withdrawal, idx: number) => {
          Column() {
            // 顶部行：金额 + 状态胶囊
            Row() {
              Text(`¥${record.amount.toFixed(2)}`)
                .fontSize(14)
                .fontColor($r('app.color.color_ink'))
                .fontWeight(FontWeight.Bold)
              Blank()
              // 状态胶囊（已完成 = 绿色 已到账）
              Text('已到账')
                .fontSize(10)
                .fontColor($r('app.color.color_green_deep'))
                .fontWeight(FontWeight.Medium)
                .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                .borderRadius(AppConstants.RADIUS_PILL)
                .backgroundColor($r('app.color.color_green_soft'))
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            // 底部行：账号 + 时间
            Row() {
              Text(record.account)
                .fontSize(11)
                .fontColor($r('app.color.color_text_3'))
              Blank()
              Text(this.formatTime(record.createdAt))
                .fontSize(11)
                .fontColor($r('app.color.color_text_3'))
            }
            .width('100%')
            .margin({ top: 2 })
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .height(52)
          .justifyContent(FlexAlign.Center)
          .border({ width: { bottom: idx === this.withdrawals.length - 1 ? 0 : 1 }, color: $r('app.color.color_line') })
        }, (record: Withdrawal) => record.withdrawalId)
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 8 })
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
  }
}
