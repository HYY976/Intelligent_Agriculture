/**
 * wallet - 我的钱包页
 * 遵循 spec 3.1.3.5：余额/累计消费/累计节省/优惠券数
 */

import { UserRoutes, RouteName, NavigationHelper } from 'common';
import { WalletInfo } from '../../model/ProfileModels';
import { MOCK_WALLET } from '../../mock/ProfileMock';

/** 钱包交易明细项 */
interface WalletTransaction {
  type: string;
  desc: string;
  amount: number;
  time: string;
}

@ComponentV2
export struct Wallet {
  @Local wallet: WalletInfo = MOCK_WALLET;
  /** 交易明细 Mock 数据 */
  private transactions: WalletTransaction[] = [
    { type: '消费', desc: '购买有机青菜', amount: -9.90, time: '2026-07-15 14:32' },
    { type: '消费', desc: '购买冰糖橙', amount: -29.90, time: '2026-07-14 10:15' },
    { type: '充值', desc: '账户充值', amount: 100.00, time: '2026-07-10 09:00' },
    { type: '退款', desc: '订单退款', amount: 45.90, time: '2026-07-08 16:20' },
    { type: '优惠', desc: '新人优惠券', amount: 10.00, time: '2026-07-01 00:00' }
  ];

  build() {
    NavDestination() {
      Column() {
        Row() {
          Text('‹').fontSize(28).fontColor($r('app.color.color_text_primary')).onClick(() => { NavigationHelper.pop(); })
          Text('我的钱包').fontSize(18).fontColor($r('app.color.color_text_primary')).fontWeight(FontWeight.Medium).layoutWeight(1).textAlign(TextAlign.Center)
          Text('').width(28)
        }
        .width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor($r('app.color.color_bg_card')).alignItems(VerticalAlign.Center)

        Scroll() {
          Column({ space: 12 }) {
            // 余额卡片
            Column({ space: 8 }) {
              Text('账户余额（元）').fontSize(13).fontColor('rgba(255,255,255,0.85)')
              Text(this.wallet.balance.toFixed(2)).fontSize(40).fontColor(Color.White).fontWeight(FontWeight.Bold)
              Row({ space: 24 }) {
                Text('充值').fontSize(13).fontColor(Color.White).padding({ left: 20, right: 20, top: 8, bottom: 8 }).backgroundColor('rgba(255,255,255,0.25)').borderRadius(16)
                Text('提现').fontSize(13).fontColor(Color.White).padding({ left: 20, right: 20, top: 8, bottom: 8 }).backgroundColor('rgba(255,255,255,0.25)').borderRadius(16)
              }.margin({ top: 8 })
            }
            .width('100%').padding(24).alignItems(HorizontalAlign.Center)
            .linearGradient({ angle: 135, colors: [[$r('app.color.color_secondary'), 0], [$r('app.color.color_price'), 1]] })
            .borderRadius(16).margin({ left: 12, right: 12, top: 12 })

            // 统计卡片
            Row() {
              this.StatItem('累计消费', `¥${this.wallet.totalSpent.toFixed(2)}`)
              this.StatItem('累计节省', `¥${this.wallet.totalSaved.toFixed(2)}`)
              this.StatItem('优惠券', `${this.wallet.couponCount}张`)
            }
            .width('100%').padding(16).backgroundColor($r('app.color.color_bg_card')).borderRadius(12).margin({ left: 12, right: 12 })

            // 明细列表（Mock 占位）
            Column({ space: 0 }) {
              Text('交易明细').fontSize(14).fontColor($r('app.color.color_text_primary')).fontWeight(FontWeight.Medium).alignSelf(ItemAlign.Start).margin({ bottom: 12 })
              ForEach(this.transactions, (item: WalletTransaction, _i: number) => {
                Row() {
                  Column({ space: 2 }) {
                    Text(item.desc).fontSize(13).fontColor($r('app.color.color_text_primary'))
                    Text(item.time).fontSize(11).fontColor($r('app.color.color_text_hint'))
                  }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                  Text(`${item.amount > 0 ? '+' : ''}¥${item.amount.toFixed(2)}`).fontSize(14).fontColor(item.amount > 0 ? $r('app.color.color_primary') : $r('app.color.color_price')).fontWeight(FontWeight.Medium)
                }.width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor($r('app.color.color_bg_card')).alignItems(VerticalAlign.Center)
              }, (item: WalletTransaction, i: number) => `${item.desc}_${i}`)
            }
            .width('100%').padding(16).backgroundColor($r('app.color.color_bg_card')).borderRadius(12).margin({ left: 12, right: 12 }).alignItems(HorizontalAlign.Start)

            // 跳转优惠券
            Row() {
              Text('🎟️ 我的优惠券').fontSize(14).fontColor($r('app.color.color_text_primary')).layoutWeight(1)
              Text(`${this.wallet.couponCount}张 ›`).fontSize(13).fontColor($r('app.color.color_text_secondary'))
            }.width('100%').height(52).padding({ left: 16, right: 16 }).backgroundColor($r('app.color.color_bg_card')).borderRadius(12).margin({ left: 12, right: 12 }).alignItems(VerticalAlign.Center)
            .onClick(() => { NavigationHelper.push(RouteName.USER_COUPON_LIST); })
          }
          .width('100%').padding({ bottom: 24 })
        }
        .layoutWeight(1).width('100%').backgroundColor($r('app.color.color_bg_page')).scrollBar(BarState.Off)
      }
      .width('100%').height('100%').backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  @Builder
  StatItem(label: string, value: string) {
    Column({ space: 4 }) {
      Text(value).fontSize(16).fontColor($r('app.color.color_text_primary')).fontWeight(FontWeight.Bold)
      Text(label).fontSize(11).fontColor($r('app.color.color_text_secondary'))
    }.layoutWeight(1).alignItems(HorizontalAlign.Center)
  }
}
