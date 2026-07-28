﻿﻿﻿/**
 * wallet - 我的钱包页
 * 遵循 spec 3.1.3.5 + 设计稿 wallet.html 1:1 复刻：
 *  - 顶栏：白色圆形返回按钮 + 居中标题"我的钱包"
 *  - 余额英雄卡（黄色渐变 + 黄色阴影）：账户余额(元) + 显隐按钮 + 大号金额 + 充值/提现 mini 按钮 + 右下角硬币装饰
 *  - 统计行卡（4 等分 + 竖向分隔线）：本月支出 / 累计优惠 / 积分 / 优惠券
 *  - 交易记录卡：标题 + 查看更多 + 5 行交易明细（彩色图标 + 标题 + 时间 + 收支金额）
 */

import { Logger, AppConstants, ToastUtil, NavigationHelper, RouteName } from 'common';
import { WalletInfo, WalletTransaction, WalletTxIconTheme } from '../../model/ProfileModels';
import { MOCK_WALLET, MOCK_WALLET_TRANSACTIONS } from '../../mock/ProfileMock';

@ComponentV2
export struct Wallet {
  @Local wallet: WalletInfo = MOCK_WALLET;
  /** 交易明细 Mock 数据 */
  private transactions: WalletTransaction[] = MOCK_WALLET_TRANSACTIONS;
  /** 是否显示余额（眼睛切换） */
  @Local showBalance: boolean = true;

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
          Text('我的钱包')
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

        // ===== 内容区（对齐设计稿 qn-wallet-body） =====
        Scroll() {
          Column({ space: 12 }) {
            // 1. 余额英雄卡（对齐设计稿 qn-hero）
            this.BalanceHeroCard()

            // 2. 统计行卡（对齐设计稿 qn-stat-card，4 等分 + 分隔线）
            this.StatCard()

            // 3. 交易记录卡（对齐设计稿 qn-tx-card）
            this.TransactionCard()
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 4, bottom: 28 })
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor($r('app.color.color_bg_page'))
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 余额英雄卡（对齐设计稿 qn-hero） */
  @Builder
  BalanceHeroCard() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      // 黄色渐变背景 + 黄色阴影
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 135,
          colors: [[$r('app.color.color_yellow'), 0.0], [$r('app.color.color_yellow_deep'), 1.0]]
        })

      // 卡片内容
      Column() {
        // 顶行：账户余额(元) + 显隐按钮
        Row() {
          Text('账户余额(元)')
            .fontSize(12)
            .fontColor('rgba(26,26,26,0.65)')
            .fontWeight(FontWeight.Medium)

          Blank()

          // 显隐按钮（对齐设计稿 qn-eye-btn）
          Row() {
            Text(this.showBalance ? '👁️' : '🙈').fontSize(16)
          }
          .width(28)
          .height(28)
          .borderRadius(AppConstants.RADIUS_PILL)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.showBalance = !this.showBalance;
            Logger.info(AppConstants.SCENE_USER, { action: 'wallet_eye_toggle', msg: `showBalance=${this.showBalance}` });
          })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 大号金额（对齐设计稿 qn-hero-amount 32px Bold）
        Text(this.showBalance ? this.formatBalance(this.wallet.balance) : '****')
          .fontSize(32)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .margin({ top: 10 })
          .letterSpacing(0.5)

        // 充值 / 提现 mini 按钮（对齐设计稿 qn-hero-actions）
        Row({ space: 10 }) {
          // 充值按钮（黑底白字 pill）
          Row({ space: 5 }) {
            Text('＋').fontSize(15).fontColor(Color.White).fontWeight(FontWeight.Bold)
            Text('充值').fontSize(13).fontColor(Color.White).fontWeight(FontWeight.Bold)
          }
          .height(32)
          .padding({ left: 18, right: 18 })
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_ink'))
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            ToastUtil.info('充值功能开发中');
            Logger.info(AppConstants.SCENE_USER, { action: 'wallet_recharge_click' });
          })

          // 提现按钮（白底黑字 pill，对齐设计稿 qn-mini-line）
          Row({ space: 5 }) {
            Text('↑').fontSize(15).fontColor($r('app.color.color_ink')).fontWeight(FontWeight.Bold)
            Text('提现').fontSize(13).fontColor($r('app.color.color_ink')).fontWeight(FontWeight.Bold)
          }
          .height(32)
          .padding({ left: 18, right: 18 })
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor(Color.White)
          .border({ width: 1, color: 'rgba(26,26,26,0.08)' })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            ToastUtil.info('提现功能开发中');
            Logger.info(AppConstants.SCENE_USER, { action: 'wallet_withdraw_click' });
          })
        }
        .margin({ top: 18 })
      }
      .width('100%')
      .padding(20)
      .alignItems(HorizontalAlign.Start)

      // 右下角装饰硬币（对齐设计稿 qn-hero-deco，半透明 emoji）
      Text('🪙')
        .fontSize(96)
        .opacity(0.18)
        .position({ x: '62%', y: '42%' })
    }
    .width('100%')
    .height(168)
    .borderRadius(AppConstants.RADIUS_LG)
    .clip(true)
    .shadow(AppConstants.SHADOW_YELLOW)
  }

  /** 统计行卡（对齐设计稿 qn-stat-card，4 等分 + 竖向分隔线） */
  @Builder
  StatCard() {
    Row() {
      // 本月支出
      this.StatItem(`¥${this.wallet.monthSpent}`, '本月支出')
      this.StatDivider()
      // 累计优惠
      this.StatItem(`¥${this.wallet.totalDiscount}`, '累计优惠')
      this.StatDivider()
      // 积分
      this.StatItem(`${this.wallet.points}`, '积分')
      this.StatDivider()
      // 优惠券
      this.StatItem(`${this.wallet.couponCount}张`, '优惠券')
    }
    .width('100%')
    .padding({ top: 16, bottom: 16, left: 8, right: 8 })
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(VerticalAlign.Center)
  }

  /** 统计项（对齐设计稿 qn-stat） */
  @Builder
  StatItem(num: string, lab: string) {
    Column({ space: 4 }) {
      Text(num)
        .fontSize(18)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
      Text(lab)
        .fontSize(11)
        .fontColor($r('app.color.color_text_3'))
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  /** 统计分隔线（对齐设计稿 qn-stat-div） */
  @Builder
  StatDivider() {
    Column()
      .width(1)
      .height(32)
      .backgroundColor($r('app.color.color_line'))
  }

  /** 交易记录卡（对齐设计稿 qn-tx-card） */
  @Builder
  TransactionCard() {
    Column({ space: 0 }) {
      // 区块标题（对齐设计稿 qn-section-head）
      Row() {
        Text('交易记录')
          .fontSize(16)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        Blank()
        Row({ space: 2 }) {
          Text('查看更多')
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
          Text('›').fontSize(14).fontColor($r('app.color.color_text_3'))
        }
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          ToastUtil.info('更多交易记录开发中');
          Logger.info(AppConstants.SCENE_USER, { action: 'wallet_tx_more_click' });
        })
      }
      .width('100%')
      .padding({ bottom: 4 })
      .alignItems(VerticalAlign.Center)

      // 交易列表
      ForEach(this.transactions, (item: WalletTransaction, idx: number) => {
        this.TransactionRow(item)
        if (idx < this.transactions.length - 1) {
          Divider()
            .color($r('app.color.color_line'))
            .strokeWidth(1)
        }
      }, (item: WalletTransaction) => `${item.txId}_${item.title}`)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 交易明细行（对齐设计稿 qn-tx-row，52px 高） */
  @Builder
  TransactionRow(item: WalletTransaction) {
    Row() {
      // 左侧：图标 + 标题/时间
      Row({ space: 12 }) {
        // 彩色图标底（对齐设计稿 qn-tx-ico，32×32 圆形）
        Row() {
          Text(item.icon).fontSize(17)
        }
        .width(32)
        .height(32)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor(this.getIconBgColor(item.iconTheme))
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)

        // 标题 + 时间
        Column({ space: 2 }) {
          Text(item.title)
            .fontSize(14)
            .fontColor($r('app.color.color_ink_2'))
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
          Text(item.time)
            .fontSize(11)
            .fontColor($r('app.color.color_text_3'))
        }
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .alignItems(VerticalAlign.Center)

      // 右侧：金额（红=支出 / 绿=收入）
      Text(this.formatAmount(item))
        .fontSize(14)
        .fontColor(item.amount < 0 ? $r('app.color.color_live') : $r('app.color.color_green_deep'))
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .height(52)
    .alignItems(VerticalAlign.Center)
  }

  /** 获取图标底色（对齐设计稿 qn-ico-*） */
  private getIconBgColor(theme: WalletTxIconTheme): ResourceColor {
    switch (theme) {
      case 'red': return $r('app.color.color_live_soft');
      case 'green': return $r('app.color.color_green_soft');
      case 'blue': return $r('app.color.color_info_soft');
      case 'yellow': return $r('app.color.color_yellow_soft');
      default: return $r('app.color.color_fill');
    }
  }

  /** 格式化余额（千分位，对齐设计稿 1,288.50） */
  private formatBalance(amount: number): string {
    const parts: string[] = amount.toFixed(2).split('.');
    const intPart: string = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    return `${intPart}.${parts[1]}`;
  }

  /** 格式化金额（支出 -¥29.9 / 收入 +¥200.00 / 积分 +288） */
  private formatAmount(item: WalletTransaction): string {
    if (item.isInt) {
      // 整数（积分）
      return `+${Math.abs(item.amount)}`;
    }
    const sign: string = item.amount < 0 ? '-' : '+';
    return `${sign}¥${Math.abs(item.amount).toFixed(2)}`;
  }
}
