/**
 * OrderStatusBadge - 订单状态徽章组件
 * 用于订单列表/订单详情显示订单状态
 */

import { OrderStatus } from 'common';
import { getOrderStatusLabel, getOrderStatusColor } from '../model/OrderModels';

@ComponentV2
export struct OrderStatusBadge {
  /** 订单状态 */
  @Param status: OrderStatus = 'pending_payment';

  build() {
    Text(getOrderStatusLabel(this.status))
      .fontSize(12)
      .fontColor($r(`app.color.${getOrderStatusColor(this.status)}`))
      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
      .borderRadius(10)
      .backgroundColor($r('app.color.color_bg_page'))
  }
}
