/**
 * QnStatRow - 统计行组件
 * 对齐设计稿 .qn-stat-row：N 等分加粗数字 + 灰色标签
 * spec 15.4.1：13 个公共组件之一
 */

/** 统计项数据 */
interface QnStatItem {
  /** 数字（如 "128" / "5.6万"） */
  num: string;
  /** 标签（如 "关注" / "粉丝"） */
  lab: string;
}

@ComponentV2
export struct QnStatRow {
  /** 统计项数组（通常 3-4 项） */
  @Param stats: QnStatItem[] = [];

  build() {
    Row() {
      ForEach(this.stats, (item: QnStatItem, index: number) => {
        Column({ space: 2 }) {
          Text(item.num)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.color_ink'))
          Text(item.lab)
            .fontSize(11)
            .fontColor($r('app.color.color_text_3'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }, (item: QnStatItem, index: number) => `${item.lab}_${index}`)
    }
    .width('100%')
  }
}
