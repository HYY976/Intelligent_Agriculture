/**
 * ListStateView - 长列表/详情页统一状态视图组件
 * 遵循 spec 2.3.5 + spec 10.13 + spec 10.14：
 *  - 将 4 态状态机推广时各页内联的 LoadingView/ErrorView @Builder 抽离为统一 common 组件
 *  - 支持 3 种渲染态：loading / error / empty（list/content 态由调用方在外层 if-else 自行渲染）
 *  - 视觉风格与 spec 10.13 v2.5 已落地内联 @Builder 一致：
 *    · loading：LoadingProgress(48) + 文案
 *    · error：⚠️(64) + 文案 + "刷新"主色按钮
 *    · empty：★ v2.9 双模式——image 模式（默认）Image(160×128)+title(16px)+desc(13px)+按钮 / emoji 模式 emoji(64)+文案+按钮
 *
 * spec 10.14（v2.6）：替换三端 47 处内联 @Builder 调用，消除重复代码
 * spec 10.17（v2.9）：empty 态增强为 image/emoji 双模式——image 模式（默认）吸收已删除的
 *  EmptyStateCard 插画能力（Image 160×128 + title 16px + desc 13px + 按钮）；
 *  emoji 模式（emptyUseEmoji=true）保留原 emoji 视觉，向后兼容 farmer/admin 现有空态
 *
 * 用法示例：
 * ```
 * if (this.dataSource.getLoadFailed()) {
 *   ListStateView({ state: 'error', onRefresh: () => this.refresh() })
 * } else if (this.dataSource.getIsFirstLoad()) {
 *   ListStateView({ state: 'loading' })
 * } else if (this.dataSource.totalCount() === 0) {
 *   // image 模式（默认）：插画 + 标题 + 描述 + 可选按钮
 *   ListStateView({ state: 'empty', emptyText: '购物车是空的', emptyDesc: '快去挑选心仪的农产品吧',
 *     emptyImage: $r('app.media.empty_cart'), emptyActionText: '去逛逛', onEmptyAction: () => this.gotoHome() })
 *   // emoji 模式：emptyUseEmoji=true
 *   ListStateView({ state: 'empty', emptyUseEmoji: true, emptyEmoji: '📦', emptyText: '暂无订单' })
 * } else {
 *   // LazyForEach 列表
 * }
 * ```
 */

/** 状态视图渲染态 */
export type ListState = 'loading' | 'error' | 'empty';

@ComponentV2
export struct ListStateView {
  /** 当前渲染态（默认 loading） */
  @Param state: ListState = 'loading';
  /** 加载中文案（默认 "加载中..."） */
  @Param loadingText: string = '加载中...';
  /** 错误文案（默认 "加载失败"） */
  @Param errorText: string = '加载失败';
  /** 错误态按钮文案（默认 "刷新"，与 spec 10.13 一致） */
  @Param errorButtonText: string = '刷新';
  /** 空态文案（默认 "暂无数据"） */
  @Param emptyText: string = '暂无数据';
  /** 空态 emoji（默认 🌾，emoji 模式下渲染 64px；各页可定制如 📦/📹/🛒/📋） */
  @Param emptyEmoji: string = '🌾';
  /** ★ v2.9 image 模式插画资源（默认 common HAR 的 empty_state.svg，三端共享；页面可覆盖如 cart 传 $r('app.media.empty_cart')） */
  @Param emptyImage: Resource = $r('app.media.empty_state');
  /** ★ v2.9 image 模式描述文案（13px secondary，空字符串则不展示） */
  @Param emptyDesc: string = '';
  /** ★ v2.9 模式开关：true=emoji 模式（emoji 64px）/ false=image 模式（默认，插画 160×128） */
  @Param emptyUseEmoji: boolean = false;
  /** 空态引导按钮文案（为空则不展示按钮） */
  @Param emptyActionText: string = '';
  /** 错误态刷新回调 */
  @Event onRefresh: () => void = () => {};
  /** 空态引导按钮回调 */
  @Event onEmptyAction: () => void = () => {};

  build() {
    Column() {
      if (this.state === 'loading') {
        this.LoadingContent()
      } else if (this.state === 'error') {
        this.ErrorContent()
      } else {
        this.EmptyContent()
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  /** 加载态 */
  @Builder
  LoadingContent() {
    Column({ space: 12 }) {
      LoadingProgress().width(48).height(48)
      Text(this.loadingText)
        .fontSize(14)
        .fontColor($r('app.color.color_text_secondary'))
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  /** 错误态 */
  @Builder
  ErrorContent() {
    Column({ space: 12 }) {
      Text('⚠️')
        .fontSize(64)
      Text(this.errorText)
        .fontSize(14)
        .fontColor($r('app.color.color_text_secondary'))
      Button(this.errorButtonText)
        .height(36)
        .borderRadius(18)
        .backgroundColor($r('app.color.color_primary'))
        .fontColor(Color.White)
        .fontSize(14)
        .onClick(() => this.onRefresh())
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  /** 空态（★ v2.9 双模式：image 模式默认 / emoji 模式 emptyUseEmoji=true） */
  @Builder
  EmptyContent() {
    if (this.emptyUseEmoji) {
      // emoji 模式：保留 v2.6 原视觉（emoji 64px + 文案 14px secondary + 可选按钮）
      Column({ space: 12 }) {
        Text(this.emptyEmoji)
          .fontSize(64)
        Text(this.emptyText)
          .fontSize(14)
          .fontColor($r('app.color.color_text_secondary'))
        if (this.emptyActionText.length > 0) {
          Button(this.emptyActionText)
            .height(36)
            .borderRadius(18)
            .backgroundColor($r('app.color.color_primary'))
            .fontColor(Color.White)
            .fontSize(14)
            .onClick(() => this.onEmptyAction())
        }
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    } else {
      // image 模式：吸收 EmptyStateCard 插画能力（Image 160×128 + title 16px primary + desc 13px secondary + 可选按钮）
      Column({ space: 12 }) {
        Image(this.emptyImage)
          .width(160)
          .height(128)
          .objectFit(ImageFit.Contain)
        Text(this.emptyText)
          .fontSize(16)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Medium)
        if (this.emptyDesc.length > 0) {
          Text(this.emptyDesc)
            .fontSize(13)
            .fontColor($r('app.color.color_text_secondary'))
        }
        if (this.emptyActionText.length > 0) {
          Button(this.emptyActionText)
            .height(36)
            .borderRadius(18)
            .backgroundColor($r('app.color.color_primary'))
            .fontColor(Color.White)
            .fontSize(14)
            .padding({ left: 24, right: 24 })
            .margin({ top: 8 })
            .onClick(() => this.onEmptyAction())
        }
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
  }
}
