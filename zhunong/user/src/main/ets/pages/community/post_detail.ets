/**
 * post_detail - 帖子详情页（对齐设计稿 pages/post-detail.html）
 *  - 顶部栏：圆形返回按钮（白底阴影）+ 圆形更多按钮
 *  - 作者信息行：头像(36) + 昵称(14/600) + 认证徽标(绿圆+白✓) + 时间 + 关注按钮(黄底胶囊)
 *  - 帖子标题(18/800) + 正文(14/1.7行高) + 图片(圆角14) + 话题标签(灰胶囊)
 *  - 互动栏：白卡 4 等分（点赞/评论/收藏/分享），点赞激活态红色
 *  - 评论区：评论列表 + 缩进回复（灰色竖线 + 浅灰底）
 *  - 底部固定评论输入栏：输入框(胶囊) + 表情按钮 + 发送按钮(黄底胶囊)
 * spec 3.1.3.2
 */

import { Logger, AppConstants, ToastUtil, NavigationHelper } from 'common';
import { PostDetail, Comment, ReportReason, REPORT_REASONS } from '../../model/CommunityModels';
import {
  getMockPostDetail, getMockComments, toggleMockPostLike, toggleMockPostFavorite,
  toggleMockCommentLike, addMockComment, addMockReply, submitMockReport
} from '../../mock/CommunityMock';
import { ImageUtil } from '../../utils/ImageUtil';

/** 帖子详情路由参数（ArkTS 严格模式要求具体 interface） */
interface PostDetailParam {
  postId: string;
}

@ComponentV2
export struct PostDetailPage {
  /** 帖子 ID */
  @Local postId: string = '';
  /** 帖子详情 */
  @Local post: PostDetail | null = null;
  /** 评论列表 */
  @Local comments: Comment[] = [];
  /** 输入框文案 */
  @Local inputText: string = '';
  /** 当前回复目标评论（null=普通一级评论） */
  @Local replyTarget: Comment | null = null;
  /** 是否显示举报弹窗 */
  @Local showReportSheet: boolean = false;
  /** 是否显示图片大图查看器 */
  @Local showImageViewer: boolean = false;
  /** 当前查看的图片索引 */
  @Local currentImageIndex: number = 0;
  /** 当前昵称（Mock） */
  @Local currentNickname: string = '我';
  /** 是否已关注作者 */
  @Local isFollowing: boolean = false;

  aboutToAppear(): void {
    const params: PostDetailParam | undefined = NavigationHelper.getParam<PostDetailParam>();
    if (params) {
      this.postId = params.postId ?? '';
    }
    this.loadPostDetail();
  }

  /** 加载帖子详情 + 评论 */
  private loadPostDetail(): void {
    this.post = getMockPostDetail(this.postId);
    if (!this.post) {
      ToastUtil.error('帖子不存在');
      NavigationHelper.pop();
      return;
    }
    this.comments = getMockComments(this.postId);
    Logger.info(AppConstants.SCENE_USER, JSON.stringify({
      action: 'post_detail_view',
      postId: this.postId,
      commentCount: this.comments.length
    }));
  }

  /** 返回 */
  private goBack(): void {
    NavigationHelper.pop();
  }

  /** 切换点赞 */
  private onToggleLike(): void {
    if (!this.post) {
      return;
    }
    const liked: boolean = toggleMockPostLike(this.postId);
    this.post.isLiked = liked;
    this.post.likeCount += liked ? 1 : -1;
  }

  /** 切换收藏 */
  private onToggleFavorite(): void {
    if (!this.post) {
      return;
    }
    const favorited: boolean = toggleMockPostFavorite(this.postId);
    this.post.isFavorited = favorited;
    this.post.favoriteCount += favorited ? 1 : -1;
    ToastUtil.success(favorited ? '已收藏' : '已取消收藏');
  }

  /** 分享 */
  private onShare(): void {
    ToastUtil.info('分享功能开发中');
    Logger.info(AppConstants.SCENE_USER, JSON.stringify({ action: 'post_share', postId: this.postId }));
  }

  /** 更多 → 举报 */
  private onMore(): void {
    this.showReportSheet = true;
  }

  /** 提交举报 */
  private onSubmitReport(reason: ReportReason): void {
    submitMockReport(this.postId, reason.label, '');
    this.showReportSheet = false;
    ToastUtil.success('举报已提交，将进入审核队列');
    Logger.info(AppConstants.SCENE_USER, JSON.stringify({
      action: 'post_report', postId: this.postId, reason: reason.label
    }));
  }

  /** 切换关注 */
  private onToggleFollow(): void {
    this.isFollowing = !this.isFollowing;
    ToastUtil.success(this.isFollowing ? '关注成功' : '已取消关注');
  }

  /** 点击评论的回复按钮 → 进入回复模式 */
  private onStartReply(comment: Comment): void {
    this.replyTarget = comment;
    this.inputText = '';
  }

  /** 取消回复 */
  private onCancelReply(): void {
    this.replyTarget = null;
    this.inputText = '';
  }

  /** 切换评论点赞 */
  private onToggleCommentLike(comment: Comment): void {
    const liked: boolean = toggleMockCommentLike(this.postId, comment.commentId);
    comment.isLiked = liked;
    comment.likeCount += liked ? 1 : -1;
  }

  /** 发送评论 / 回复 */
  private onSend(): void {
    const text: string = this.inputText.trim();
    if (text.length === 0) {
      ToastUtil.warning('请输入评论内容');
      return;
    }
    if (this.replyTarget) {
      const replyToNickname: string = this.replyTarget.authorNickname;
      const newReply: Comment | null = addMockReply(
        this.postId, this.replyTarget.commentId, replyToNickname, text, this.currentNickname
      );
      if (newReply) {
        this.comments = getMockComments(this.postId);
        ToastUtil.success('回复成功');
      }
    } else {
      addMockComment(this.postId, text, this.currentNickname);
      this.comments = getMockComments(this.postId);
      ToastUtil.success('评论成功');
    }
    this.inputText = '';
    this.replyTarget = null;
    if (this.post) {
      this.post.commentCount += 1;
    }
    Logger.info(AppConstants.SCENE_USER, JSON.stringify({
      action: 'comment_send',
      postId: this.postId,
      isReply: this.replyTarget !== null,
      length: text.length
    }));
  }

  /** 点击图片 → 大图查看 */
  private onImageClick(index: number): void {
    this.currentImageIndex = index;
    this.showImageViewer = true;
  }

  /** 格式化时间 */
  private formatTime(timestamp: number): string {
    const diff: number = Date.now() - timestamp;
    if (diff < 60000) {
      return '刚刚';
    }
    if (diff < 3600000) {
      return `${Math.floor(diff / 60000)}分钟前`;
    }
    if (diff < 86400000) {
      return `${Math.floor(diff / 3600000)}小时前`;
    }
    if (diff < 2592000000) {
      return `${Math.floor(diff / 86400000)}天前`;
    }
    return `${Math.floor(diff / 2592000000)}个月前`;
  }

  /** 格式化数字（>=10000 显示万） */
  private formatCount(count: number): string {
    if (count >= 10000) {
      return `${(count / 10000).toFixed(1)}万`;
    }
    return `${count}`;
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部导航栏（对齐设计稿 qn-topbar：圆形返回 + 圆形更多）
        this.TopBar()
        // 内容区
        Scroll() {
          Column() {
            if (this.post) {
              this.PostContent(this.post)
              this.InteractionBar(this.post)
              this.CommentSection()
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
        // 底部固定评论输入栏
        if (this.post) {
          this.BottomInputBar()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
      // 举报弹窗
      .bindSheet($$this.showReportSheet, this.ReportSheet(), {
        height: '50%',
        dragBar: true,
        backgroundColor: $r('app.color.color_bg_card')
      })
      // 图片大图查看器
      .bindContentCover(this.showImageViewer, this.ImageViewer())
    }
    .hideTitleBar(true)
  }

  /** 顶部导航栏（对齐设计稿 qn-topbar：圆形返回按钮 + 圆形更多按钮） */
  @Builder
  TopBar() {
    Row() {
      // 左：圆形返回按钮（对齐设计稿 qn-icon-btn：白底圆 + 软阴影）
      Text('←')
        .fontSize(18)
        .fontColor($r('app.color.color_ink'))
        .width(32)
        .height(32)
        .textAlign(TextAlign.Center)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor($r('app.color.color_bg_card'))
        .shadow(AppConstants.SHADOW_CARD)
        .onClick(() => {
          this.goBack();
        })

      Blank()

      // 右：圆形更多按钮（对齐设计稿 qn-icon-btn：白底圆 + 软阴影）
      Text('⋯')
        .fontSize(20)
        .fontColor($r('app.color.color_ink'))
        .width(32)
        .height(32)
        .textAlign(TextAlign.Center)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor($r('app.color.color_bg_card'))
        .shadow(AppConstants.SHADOW_CARD)
        .onClick(() => {
          this.onMore();
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 10 })
    .alignItems(VerticalAlign.Center)
  }

  /** 帖子正文区（对齐设计稿 pd-body） */
  @Builder
  PostContent(post: PostDetail) {
    Column({ space: 0 }) {
      // 作者信息行（对齐设计稿 pd-author）
      Row({ space: 10 }) {
        // 头像（36×36 圆形）
        Image(ImageUtil.get(post.authorAvatar))
          .width(36)
          .height(36)
          .borderRadius(AppConstants.RADIUS_PILL)
          .objectFit(ImageFit.Cover)
          .backgroundColor($r('app.color.color_fill'))

        // 昵称 + 认证徽标 + 时间（对齐设计稿 pd-author-meta）
        Row({ space: 5 }) {
          Text(post.authorNickname)
            .fontSize(14)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 认证徽标（对齐设计稿 pd-v：14×14 绿色圆 + 白色 ✓）
          if (post.authorType === 'farmer') {
            Text('✓')
              .fontSize(9)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
              .width(14)
              .height(14)
              .textAlign(TextAlign.Center)
              .borderRadius(AppConstants.RADIUS_PILL)
              .backgroundColor($r('app.color.color_green'))
          }

          // 发布时间
          Text(this.formatTime(post.createdAt))
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
            .margin({ left: 2 })
        }
        .layoutWeight(1)
        .alignItems(VerticalAlign.Center)

        // 关注按钮（对齐设计稿 pd-follow：黄底胶囊 + 墨黑字）
        Text(this.isFollowing ? '已关注' : '关注')
          .fontSize(12)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .height(28)
          .padding({ left: 14, right: 14 })
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor(this.isFollowing ? $r('app.color.color_fill') : $r('app.color.color_primary'))
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.onToggleFollow();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 帖子标题（对齐设计稿 pd-title：18px 800）
      Text(post.title)
        .fontSize(18)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .lineHeight(25)
        .margin({ top: 12 })
        .width('100%')

      // 正文（对齐设计稿 pd-text：14px 1.7 行高）
      Text(post.content)
        .fontSize(14)
        .fontColor($r('app.color.color_ink_2'))
        .lineHeight(24)
        .margin({ top: 10 })
        .width('100%')

      // 图片（对齐设计稿 pd-image：圆角14 + objectFit cover）
      if (post.images.length > 0) {
        this.PostImageSection(post.images)
      }

      // 话题标签行（对齐设计稿 pd-tags：灰胶囊）
      Row({ space: 8 }) {
        Text(`#${post.topicName}`)
          .fontSize(12)
          .fontColor($r('app.color.color_text_2'))
          .fontWeight(FontWeight.Medium)
          .padding({ left: 12, right: 12, top: 4, bottom: 4 })
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_fill'))
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 8 })
    .alignItems(HorizontalAlign.Start)
  }

  /** 帖子图片区（对齐设计稿：单张大图圆角14，多图九宫格） */
  @Builder
  PostImageSection(images: string[]) {
    Column({ space: 8 }) {
      if (images.length === 1) {
        // 单图：大图展示（对齐设计稿 pd-image）
        Image(ImageUtil.get(images[0]))
          .width('100%')
          .borderRadius(AppConstants.RADIUS_MD)
          .objectFit(ImageFit.Cover)
          .margin({ top: 12 })
          .onClick(() => {
            this.onImageClick(0);
          })
      } else {
        // 多图：九宫格（3列）
        Grid() {
          ForEach(images, (imgKey: string, idx: number) => {
            GridItem() {
              Image(ImageUtil.get(imgKey))
                .width('100%')
                .height('100%')
                .borderRadius(AppConstants.RADIUS_SM)
                .objectFit(ImageFit.Cover)
                .onClick(() => {
                  this.onImageClick(idx);
                })
            }
            .aspectRatio(1)
          }, (imgKey: string, idx: number) => `${imgKey}_${idx}`)
        }
        .columnsTemplate('1fr 1fr 1fr')
        .rowsGap(8)
        .columnsGap(8)
        .width('100%')
        .margin({ top: 12 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /** 互动栏（对齐设计稿 pd-actions：白卡 4 等分 + 点赞激活态红色） */
  @Builder
  InteractionBar(post: PostDetail) {
    Row() {
      // 点赞（对齐设计稿 pd-action.is-active：红色）
      Row({ space: 5 }) {
        Text(post.isLiked ? '♥' : '♡')
          .fontSize(20)
          .fontColor(post.isLiked ? $r('app.color.color_live') : $r('app.color.color_text_2'))
        Text(this.formatCount(post.likeCount))
          .fontSize(13)
          .fontColor(post.isLiked ? $r('app.color.color_live') : $r('app.color.color_text_2'))
          .fontWeight(FontWeight.Medium)
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.onToggleLike();
      })

      // 评论
      Row({ space: 5 }) {
        Text('💬')
          .fontSize(18)
        Text(this.formatCount(post.commentCount))
          .fontSize(13)
          .fontColor($r('app.color.color_text_2'))
          .fontWeight(FontWeight.Medium)
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      // 收藏
      Row({ space: 5 }) {
        Text(post.isFavorited ? '★' : '☆')
          .fontSize(20)
          .fontColor($r('app.color.color_text_2'))
        Text(this.formatCount(post.favoriteCount))
          .fontSize(13)
          .fontColor($r('app.color.color_text_2'))
          .fontWeight(FontWeight.Medium)
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.onToggleFavorite();
      })

      // 分享
      Row({ space: 5 }) {
        Text('↗')
          .fontSize(18)
          .fontColor($r('app.color.color_text_2'))
        Text('分享')
          .fontSize(13)
          .fontColor($r('app.color.color_text_2'))
          .fontWeight(FontWeight.Medium)
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.onShare();
      })
    }
    .width('100%')
    .padding({ left: 8, right: 8, top: 12, bottom: 12 })
    .margin({ top: 12 })
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(VerticalAlign.Center)
  }

  /** 评论区（对齐设计稿 pd-cmt-head + pd-cmt-list） */
  @Builder
  CommentSection() {
    Column({ space: 0 }) {
      // 分割线
      Row()
        .width('100%')
        .height(1)
        .backgroundColor($r('app.color.color_divider'))
        .margin({ top: 16, bottom: 16 })

      // 评论区标题（对齐设计稿 pd-cmt-head）
      Row({ space: 4 }) {
        Text('全部评论')
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        Text(`${this.comments.length}`)
          .fontSize(14)
          .fontColor($r('app.color.color_text_3'))
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .margin({ bottom: 2 })

      // 评论列表
      Column({ space: 0 }) {
        ForEach(this.comments, (comment: Comment) => {
          CommentItemView({
            comment: comment,
            postAuthorId: this.post ? this.post.authorId : '',
            onReply: (c: Comment) => {
              this.onStartReply(c);
            },
            onLike: (c: Comment) => {
              this.onToggleCommentLike(c);
            }
          })
        }, (comment: Comment) => comment.commentId + `_${comment.likeCount}_${comment.isLiked}`)
      }
      .width('100%')
      .padding({ bottom: 24 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .alignItems(HorizontalAlign.Start)
  }

  /** 底部固定评论输入栏（对齐设计稿 pd-input-bar） */
  @Builder
  BottomInputBar() {
    Column({ space: 0 }) {
      // 回复模式提示
      if (this.replyTarget) {
        Row({ space: 8 }) {
          Text(`回复 @${this.replyTarget.authorNickname}`)
            .fontSize(12)
            .fontColor($r('app.color.color_text_2'))
            .layoutWeight(1)
          Text('取消')
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
            .onClick(() => {
              this.onCancelReply();
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 6 })
      }
      // 输入框 + 表情 + 发送（对齐设计稿 pd-input-bar）
      Row({ space: 10 }) {
        // 输入框（对齐设计稿 pd-input：胶囊形 + 浅灰底）
        TextInput({ text: this.inputText, placeholder: this.replyTarget ? `回复 @${this.replyTarget.authorNickname}` : '写评论...' })
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .placeholderColor($r('app.color.color_text_4'))
          .backgroundColor($r('app.color.color_fill'))
          .borderRadius(AppConstants.RADIUS_PILL)
          .padding({ left: 16, right: 16 })
          .height(38)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.inputText = value;
          })

        // 表情按钮（对齐设计稿 pd-emoji）
        Text('😊')
          .fontSize(22)
          .width(32)
          .height(32)
          .textAlign(TextAlign.Center)

        // 发送按钮（对齐设计稿 pd-send：黄底胶囊 + 墨黑字）
        Text('发送')
          .fontSize(13)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .height(32)
          .padding({ left: 16, right: 16 })
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_primary'))
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.onSend();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      .backgroundColor($r('app.color.color_bg_card'))
      .shadow(AppConstants.SHADOW_NAV)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 举报弹窗（对齐设计稿：预设原因列表） */
  @Builder
  ReportSheet() {
    Column({ space: 0 }) {
      Text('举报原因')
        .fontSize(16)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .padding({ left: 16, top: 12, bottom: 12 })

      List() {
        ForEach(REPORT_REASONS, (reason: ReportReason) => {
          ListItem() {
            Text(reason.label)
              .fontSize(15)
              .fontColor($r('app.color.color_ink_2'))
              .width('100%')
              .padding({ left: 16, right: 16, top: 14, bottom: 14 })
              .onClick(() => {
                this.onSubmitReport(reason);
              })
          }
        }, (reason: ReportReason) => reason.reasonId)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
  }

  /** 图片大图查看器 */
  @Builder
  ImageViewer() {
    Stack() {
      // 黑色背景
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Black)

      // 图片滑动查看
      Swiper() {
        ForEach(this.post ? this.post.images : [], (imgKey: string, idx: number) => {
          Image(ImageUtil.get(imgKey))
            .width('100%')
            .objectFit(ImageFit.Contain)
        }, (imgKey: string, idx: number) => `${imgKey}_${idx}`)
      }
      .index(this.currentImageIndex)
      .indicator(false)
      .width('100%')
      .height('100%')

      // 关闭按钮（右上角）
      Text('✕')
        .fontSize(18)
        .fontColor(Color.White)
        .width(36)
        .height(36)
        .textAlign(TextAlign.Center)
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor('rgba(255,255,255,0.2)')
        .position({ x: '85%', y: 50 })
        .onClick(() => {
          this.showImageViewer = false;
        })
    }
    .width('100%')
    .height('100%')
  }
}

/**
 * CommentItemView - 顶级评论项（对齐设计稿 pd-cmt）
 * 头像(28) + 昵称(12/600) + 内容(13) + 底栏(时间 + 点赞) + 缩进回复(灰竖线)
 */
@ComponentV2
struct CommentItemView {
  /** 评论数据 */
  @Param comment: Comment | null = null;
  /** 帖子作者 ID（用于标记"作者"标签） */
  @Param postAuthorId: string = '';
  /** 回复回调 */
  @Event onReply: (c: Comment) => void = () => {};
  /** 点赞回调 */
  @Event onLike: (c: Comment) => void = () => {};

  /** 格式化时间 */
  private formatTime(timestamp: number): string {
    const diff: number = Date.now() - timestamp;
    if (diff < 60000) {
      return '刚刚';
    }
    if (diff < 3600000) {
      return `${Math.floor(diff / 60000)}分钟前`;
    }
    if (diff < 86400000) {
      return `${Math.floor(diff / 3600000)}小时前`;
    }
    if (diff < 2592000000) {
      return `${Math.floor(diff / 86400000)}天前`;
    }
    return `${Math.floor(diff / 2592000000)}个月前`;
  }

  /** 格式化数字（>=10000 显示万） */
  private formatCount(count: number): string {
    if (count >= 10000) {
      return `${(count / 10000).toFixed(1)}万`;
    }
    return `${count}`;
  }

  build() {
    Column({ space: 0 }) {
      if (this.comment) {
        // 评论主体（对齐设计稿 pd-cmt）
        Row({ space: 10 }) {
          // 头像（28×28 圆形）
          Image(ImageUtil.get(this.comment.authorAvatar))
            .width(28)
            .height(28)
            .borderRadius(AppConstants.RADIUS_PILL)
            .objectFit(ImageFit.Cover)
            .backgroundColor($r('app.color.color_fill'))

          // 评论内容区（对齐设计稿 pd-c-main）
          Column({ space: 0 }) {
            // 昵称（对齐设计稿 pd-c-name：12px 600）
            Text(this.comment.authorNickname)
              .fontSize(12)
              .fontColor($r('app.color.color_text_2'))
              .fontWeight(FontWeight.Medium)

            // 评论内容（对齐设计稿 pd-c-text：13px 1.6行高）
            Text(this.comment.content)
              .fontSize(13)
              .fontColor($r('app.color.color_ink_2'))
              .lineHeight(21)
              .margin({ top: 3 })
              .width('100%')

            // 底栏（对齐设计稿 pd-c-foot：时间 + 点赞）
            Row({ space: 14 }) {
              Text(this.formatTime(this.comment.createdAt))
                .fontSize(11)
                .fontColor($r('app.color.color_text_3'))

              Row({ space: 3 }) {
                Text(this.comment.isLiked ? '♥' : '♡')
                  .fontSize(12)
                  .fontColor(this.comment.isLiked ? $r('app.color.color_live') : $r('app.color.color_text_3'))
                Text(this.formatCount(this.comment.likeCount))
                  .fontSize(11)
                  .fontColor($r('app.color.color_text_3'))
              }
              .alignItems(VerticalAlign.Center)
              .onClick(() => {
                if (this.comment) {
                  this.onLike(this.comment);
                }
              })

              // 回复按钮
              Text('回复')
                .fontSize(11)
                .fontColor($r('app.color.color_text_3'))
                .onClick(() => {
                  if (this.comment) {
                    this.onReply(this.comment);
                  }
                })
            }
            .margin({ top: 6 })
            .alignItems(VerticalAlign.Center)

            // 缩进回复列表（对齐设计稿 pd-reply：灰色竖线 + 浅灰底）
            if (this.comment.replies.length > 0) {
              Column({ space: 8 }) {
                ForEach(this.comment.replies, (reply: Comment) => {
                  ReplyItemView({
                    reply: reply,
                    postAuthorId: this.postAuthorId,
                    onReply: (c: Comment) => {
                      this.onReply(c);
                    },
                    onLike: (c: Comment) => {
                      this.onLike(c);
                    }
                  })
                }, (reply: Comment) => reply.commentId + `_${reply.likeCount}_${reply.isLiked}`)
              }
              .width('100%')
              .margin({ top: 8 })
              .padding({ left: 12, top: 8, bottom: 8, right: 12 })
              .border({ width: { left: 2 }, color: { left: $r('app.color.color_line_2') } })
              .backgroundColor($r('app.color.color_fill'))
              .borderRadius({ topRight: AppConstants.RADIUS_SM, bottomRight: AppConstants.RADIUS_SM })
              .alignItems(HorizontalAlign.Start)
            }
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })
        .alignItems(VerticalAlign.Top)
        .border({ width: { bottom: 1 }, color: { bottom: $r('app.color.color_divider') } })
      }
    }
    .width('100%')
  }
}

/**
 * ReplyItemView - 缩进回复项（对齐设计稿 pd-reply）
 * 昵称 + [作者标签] + ：+ 内容，支持递归嵌套回复
 */
@ComponentV2
struct ReplyItemView {
  /** 回复数据 */
  @Param reply: Comment | null = null;
  /** 帖子作者 ID（用于标记"作者"标签） */
  @Param postAuthorId: string = '';
  /** 回复回调 */
  @Event onReply: (c: Comment) => void = () => {};
  /** 点赞回调 */
  @Event onLike: (c: Comment) => void = () => {};

  /** 格式化时间 */
  private formatTime(timestamp: number): string {
    const diff: number = Date.now() - timestamp;
    if (diff < 60000) {
      return '刚刚';
    }
    if (diff < 3600000) {
      return `${Math.floor(diff / 60000)}分钟前`;
    }
    if (diff < 86400000) {
      return `${Math.floor(diff / 3600000)}小时前`;
    }
    if (diff < 2592000000) {
      return `${Math.floor(diff / 86400000)}天前`;
    }
    return `${Math.floor(diff / 2592000000)}个月前`;
  }

  /** 格式化数字（>=10000 显示万） */
  private formatCount(count: number): string {
    if (count >= 10000) {
      return `${(count / 10000).toFixed(1)}万`;
    }
    return `${count}`;
  }

  build() {
    Column({ space: 0 }) {
      if (this.reply) {
        // 回复内容（对齐设计稿 pd-r-name + pd-r-tag + 内容）
        Row() {
          Text(this.reply.authorNickname)
            .fontSize(13)
            .fontColor($r('app.color.color_text_2'))
            .fontWeight(FontWeight.Medium)

          // 作者标签（对齐设计稿 pd-r-tag：浅绿底 + 深绿字）
          if (this.reply.authorId === this.postAuthorId) {
            Text('作者')
              .fontSize(10)
              .fontColor($r('app.color.color_green_deep'))
              .fontWeight(FontWeight.Bold)
              .backgroundColor($r('app.color.color_green_soft'))
              .padding({ left: 6, right: 6, top: 1, bottom: 1 })
              .borderRadius(AppConstants.RADIUS_PILL)
              .margin({ left: 4 })
          }

          // 回复对象（楼中楼：回复 @某人）
          if (this.reply.replyToNickname) {
            Text(` 回复 @${this.reply.replyToNickname}`)
              .fontSize(13)
              .fontColor($r('app.color.color_text_3'))
          }

          Text('：')
            .fontSize(13)
            .fontColor($r('app.color.color_ink_2'))

          Text(this.reply.content)
            .fontSize(13)
            .fontColor($r('app.color.color_ink_2'))
            .layoutWeight(1)
            .lineHeight(21)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)

        // 回复底栏（时间 + 点赞 + 回复按钮）
        Row({ space: 14 }) {
          Text(this.formatTime(this.reply.createdAt))
            .fontSize(11)
            .fontColor($r('app.color.color_text_3'))

          Row({ space: 3 }) {
            Text(this.reply.isLiked ? '♥' : '♡')
              .fontSize(12)
              .fontColor(this.reply.isLiked ? $r('app.color.color_live') : $r('app.color.color_text_3'))
            Text(this.formatCount(this.reply.likeCount))
              .fontSize(11)
              .fontColor($r('app.color.color_text_3'))
          }
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            if (this.reply) {
              this.onLike(this.reply);
            }
          })

          Text('回复')
            .fontSize(11)
            .fontColor($r('app.color.color_text_3'))
            .onClick(() => {
              if (this.reply) {
                this.onReply(this.reply);
              }
            })
        }
        .margin({ top: 4 })
        .alignItems(VerticalAlign.Center)

        // 递归渲染嵌套回复
        if (this.reply.replies.length > 0) {
          Column({ space: 8 }) {
            ForEach(this.reply.replies, (subReply: Comment) => {
              ReplyItemView({
                reply: subReply,
                postAuthorId: this.postAuthorId,
                onReply: (c: Comment) => {
                  this.onReply(c);
                },
                onLike: (c: Comment) => {
                  this.onLike(c);
                }
              })
            }, (subReply: Comment) => subReply.commentId + `_${subReply.likeCount}_${subReply.isLiked}`)
          }
          .width('100%')
          .margin({ top: 8 })
          .padding({ left: 12, top: 8, bottom: 8, right: 12 })
          .border({ width: { left: 2 }, color: { left: $r('app.color.color_line_2') } })
          .backgroundColor($r('app.color.color_fill'))
          .borderRadius({ topRight: AppConstants.RADIUS_SM, bottomRight: AppConstants.RADIUS_SM })
          .alignItems(HorizontalAlign.Start)
        }
      }
    }
    .width('100%')
  }
}
