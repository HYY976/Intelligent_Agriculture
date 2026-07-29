/**
 * QnSectionHead - 区块标题组件
 * 对齐设计稿 .qn-section-head：左标题加粗 + 右"查看更多 >"
 * spec 15.4.1：13 个公共组件之一
 */

@ComponentV2
export struct QnSectionHead {
  /** 标题文字 */
  @Param title: string = '';
  /** 是否显示右侧"更多"链接（默认 true） */
  @Param showMore: boolean = true;
  /** 右侧链接文案（默认 "查看更多"） */
  @Param moreText: string = '查看更多';
  /** 标题点击回调 */
  @Event on_more: () => void = () => {};

  build() {
    Row() {
      // 左侧标题
      Text(this.title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.color_ink'))

      // 右侧"更多"
      if (this.showMore) {
        Row({ space: 2 }) {
          Text(this.moreText)
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
          Text('›')
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
        }
        .onClick(() => this.on_more())
      }
    }
    .width('100%')
    .padding({ top: 4, bottom: 12, left: 2, right: 2 })
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
  }
}
