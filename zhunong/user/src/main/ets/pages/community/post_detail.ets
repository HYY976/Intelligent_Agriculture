/**
 * post_detail - 帖子详情页（spec 3.1.3.2）
 *  - 帖子完整内容 + 图片九宫格大图查看
 *  - 互动栏：点赞/收藏/分享/举报
 *  - 评论列表：无限嵌套回复（递归 CommentItem 组件渲染，楼中楼）
 *  - 评论仅支持文字+表情（不支持图片）
 *  - 底部固定评论输入框（普通评论 / 回复指定评论切换）
 *  - 举报弹窗（bindSheet，预设原因 + 自定义描述）
 */

import { Logger, AppConstants, ToastUtil, RouteName, NavigationHelper } from 'common';
import { PostDetail, Comment, ReportReason, REPORT_REASONS } from '../../model/CommunityModels';
import {
  getMockPostDetail, getMockComments, toggleMockPostLike, toggleMockPostFavorite,
  toggleMockCommentLike, addMockComment, addMockReply, submitMockReport
} from '../../mock/CommunityMock';
import { ImageUtil } from '../../utils/ImageUtil';

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

  aboutToAppear(): void {
    const params: Record<string, string> | undefined = NavigationHelper.getParam<Record<string, string>>();
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
    if (liked) {
      ToastUtil.success('点赞成功');
    }
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
    ToastUtil.info('分享功能开发中（会话分享/长图/拷贝链接）');
    Logger.info(AppConstants.SCENE_USER, { action: 'post_share', postId: this.postId });
  }

  /** 举报 */
  private onReport(): void {
    this.showReportSheet = true;
  }

  /** 提交举报 */
  private onSubmitReport(reason: ReportReason): void {
    submitMockReport(this.postId, reason.label, '');
    this.showReportSheet = false;
    ToastUtil.success('举报已提交，将进入审核队列');
    Logger.info(AppConstants.SCENE_USER, { action: 'post_report', postId: this.postId, reason: reason.label });
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
      // 回复指定评论
      const replyToNickname: string = this.replyTarget.authorNickname;
      const newReply: Comment | null = addMockReply(
        this.postId,
        this.replyTarget.commentId,
        replyToNickname,
        text,
        this.currentNickname
      );
      if (newReply) {
        // 触发评论列表刷新（重新读取 Mock 数据）
        this.comments = getMockComments(this.postId);
        ToastUtil.success('回复成功');
      }
    } else {
      // 一级评论
      addMockComment(this.postId, text, this.currentNickname);
      this.comments = getMockComments(this.postId);
      ToastUtil.success('评论成功');
    }
    this.inputText = '';
    this.replyTarget = null;
    // 更新帖子评论数
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

  build() {
    NavDestination() {
      Column() {
        // 顶部导航栏
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
        // 底部评论输入栏
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

  /** 顶部导航栏 */
  @Builder
  TopBar() {
    Row({ space: 12 }) {
      Text('←')
        .fontSize(24)
        .fontColor($r('app.color.color_text_primary'))
        .onClick(() => {
          this.goBack();
        })
      Text('帖子详情')
        .fontSize(16)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
      Text('⋯')
        .fontSize(22)
        .fontColor($r('app.color.color_text_primary'))
        .onClick(() => {
          this.onReport();
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** 帖子正文区 */
  @Builder
  PostContent(post: PostDetail) {
    Column({ space: 12 }) {
      // 作者信息
      Row({ space: 10 }) {
        Image(ImageUtil.get(post.authorAvatar))
          .width(44)
          .height(44)
          .borderRadius(22)
        Column({ space: 2 }) {
          Row({ space: 4 }) {
            Text(post.authorNickname)
              .fontSize(14)
              .fontColor($r('app.color.color_text_primary'))
              .fontWeight(FontWeight.Medium)
            if (post.authorType === 'farmer') {
              Text('卖家')
                .fontSize(9)
                .fontColor(Color.White)
                .backgroundColor($r('app.color.color_secondary'))
                .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                .borderRadius(3)
            }
          }
          .alignItems(VerticalAlign.Center)
          Text(this.formatTime(post.createdAt))
            .fontSize(11)
            .fontColor($r('app.color.color_text_hint'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        // 话题标签
        Text(`#${post.topicName}`)
          .fontSize(11)
          .fontColor($r('app.color.color_primary'))
          .backgroundColor('rgba(76,175,80,0.1)')
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(10)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 标题
      Text(post.title)
        .fontSize(18)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Bold)

      // 正文
      Text(post.content)
        .fontSize(14)
        .fontColor($r('app.color.color_text_primary'))
        .lineHeight(24)

      // 图片九宫格（完整9图）
      if (post.images.length > 0) {
        this.PostImageGrid(post.images)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(HorizontalAlign.Start)
  }

  /** 帖子图片九宫格（3列，最多9图） */
  @Builder
  PostImageGrid(images: string[]) {
    Grid() {
      ForEach(images, (imgKey: string, idx: number) => {
        GridItem() {
          Image(ImageUtil.get(imgKey))
            .width('100%')
            .aspectRatio(1)
            .borderRadius(8)
            .objectFit(ImageFit.Cover)
            .onClick(() => {
              this.onImageClick(idx);
            })
        }
      }, (imgKey: string, idx: number) => imgKey + idx)
    }
    .columnsTemplate('1fr 1fr 1fr')
    .rowsGap(6)
    .columnsGap(6)
    .width('100%')
  }

  /** 互动栏 */
  @Builder
  InteractionBar(post: PostDetail) {
    Row({ space: 24 }) {
      // 点赞
      Row({ space: 4 }) {
        Text(post.isLiked ? '❤️' : '🤍')
          .fontSize(18)
        Text(this.formatCount(post.likeCount))
          .fontSize(13)
          .fontColor(post.isLiked ? $r('app.color.color_primary') : $r('app.color.color_text_secondary'))
      }
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.onToggleLike();
      })

      // 评论
      Row({ space: 4 }) {
        Text('💬')
          .fontSize(18)
        Text(this.formatCount(post.commentCount))
          .fontSize(13)
          .fontColor($r('app.color.color_text_secondary'))
      }
      .alignItems(VerticalAlign.Center)

      // 收藏
      Row({ space: 4 }) {
        Text(post.isFavorited ? '⭐' : '☆')
          .fontSize(18)
        Text(this.formatCount(post.favoriteCount))
          .fontSize(13)
          .fontColor(post.isFavorited ? $r('app.color.color_secondary') : $r('app.color.color_text_secondary'))
      }
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.onToggleFavorite();
      })

      Blank()

      // 分享
      Row({ space: 4 }) {
        Text('🔗')
          .fontSize(16)
        Text('分享')
          .fontSize(13)
          .fontColor($r('app.color.color_text_secondary'))
      }
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.onShare();
      })

      // 举报
      Text('举报')
        .fontSize(13)
        .fontColor($r('app.color.color_text_hint'))
        .onClick(() => {
          this.onReport();
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor($r('app.color.color_bg_card'))
    .margin({ top: 1 })
    .alignItems(VerticalAlign.Center)
  }

  /** 评论区域 */
  @Builder
  CommentSection() {
    Column({ space: 0 }) {
      Text(`全部评论 (${this.comments.length})`)
        .fontSize(15)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .padding({ left: 16, top: 16, bottom: 8 })

      // 评论列表（递归渲染嵌套回复）
      Column({ space: 16 }) {
        ForEach(this.comments, (comment: Comment) => {
          CommentItem({
            comment: comment,
            depth: 0,
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
      .padding({ left: 16, right: 16, bottom: 24 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .margin({ top: 8 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(HorizontalAlign.Start)
  }

  /** 底部评论输入栏 */
  @Builder
  BottomInputBar() {
    Column({ space: 8 }) {
      // 回复模式提示
      if (this.replyTarget) {
        Row({ space: 8 }) {
          Text(`回复 @${this.replyTarget.authorNickname}`)
            .fontSize(12)
            .fontColor($r('app.color.color_text_secondary'))
            .layoutWeight(1)
          Text('取消')
            .fontSize(12)
            .fontColor($r('app.color.color_text_hint'))
            .onClick(() => {
              this.onCancelReply();
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
      }
      // 输入框 + 发送按钮
      Row({ space: 8 }) {
        TextInput({ text: this.inputText, placeholder: this.replyTarget ? `回复 @${this.replyTarget.authorNickname}` : '说点什么…' })
          .fontSize(14)
          .fontColor($r('app.color.color_text_primary'))
          .placeholderColor($r('app.color.color_text_hint'))
          .backgroundColor($r('app.color.color_bg_page'))
          .borderRadius(20)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .layoutWeight(1)
          .onChange((value: string) => {
            this.inputText = value;
          })
        Text('发送')
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.color_primary'))
          .padding({ left: 18, right: 18, top: 8, bottom: 8 })
          .borderRadius(18)
          .onClick(() => {
            this.onSend();
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12, bottom: 24, top: 8 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 举报弹窗内容 */
  @Builder
  ReportSheet() {
    Column({ space: 0 }) {
      Text('选择举报原因')
        .fontSize(16)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .padding({ left: 16, top: 12, bottom: 12 })

      List() {
        ForEach(REPORT_REASONS, (reason: ReportReason) => {
          ListItem() {
            Text(reason.label)
              .fontSize(14)
              .fontColor($r('app.color.color_text_primary'))
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
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.95)')
      Swiper() {
        ForEach(this.post ? this.post.images : [], (imgKey: string, idx: number) => {
          Image(ImageUtil.get(imgKey))
            .width('100%')
            .objectFit(ImageFit.Contain)
        }, (imgKey: string, idx: number) => imgKey + idx)
      }
      .index(this.currentImageIndex)
      .indicator(false)
      .width('100%')
      .height('100%')

      // 关闭按钮
      Text('✕')
        .fontSize(22)
        .fontColor(Color.White)
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor('rgba(255,255,255,0.2)')
        .textAlign(TextAlign.Center)
        .position({ right: 16, top: 48 })
        .onClick(() => {
          this.showImageViewer = false;
        })
    }
    .width('100%')
    .height('100%')
  }

  /** 格式化数字（>=10000 显示万） */
  private formatCount(count: number): string {
    if (count >= 10000) {
      return `${(count / 10000).toFixed(1)}万`;
    }
    return `${count}`;
  }

  /** 格式化时间 */
  private formatTime(timestamp: number): string {
    const diff: number = Date.now() - timestamp;
    const minutes: number = Math.floor(diff / 60000);
    if (minutes < 1) {
      return '刚刚';
    }
    if (minutes < 60) {
      return `${minutes}分钟前`;
    }
    const hours: number = Math.floor(minutes / 60);
    if (hours < 24) {
      return `${hours}小时前`;
    }
    const days: number = Math.floor(hours / 24);
    if (days < 30) {
      return `${days}天前`;
    }
    const date: Date = new Date(timestamp);
    return `${date.getMonth() + 1}月${date.getDate()}日`;
  }
}

/**
 * CommentItem - 评论项组件（递归，支持无限嵌套回复 楼中楼）
 * spec 3.1.3.2：评论仅支持文字+表情，不支持图片
 */
@ComponentV2
struct CommentItem {
  /** 当前评论数据 */
  @Param comment: Comment | null = null;
  /** 嵌套深度（用于缩进） */
  @Param depth: number = 0;
  /** 回复回调 */
  @Event onReply: (comment: Comment) => void = () => {};
  /** 点赞回调 */
  @Event onLike: (comment: Comment) => void = () => {};

  build() {
    Column({ space: 8 }) {
      if (this.comment) {
        this.CommentHeader(this.comment)
        this.CommentBody(this.comment)
        // 递归渲染回复（楼中楼）
        if (this.comment.replies.length > 0) {
          Column({ space: 12 }) {
            ForEach(this.comment.replies, (reply: Comment) => {
              CommentItem({
                comment: reply,
                depth: this.depth + 1,
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
          .padding({ left: 12 })
          .backgroundColor($r('app.color.color_bg_page'))
          .borderRadius(8)
          .alignItems(HorizontalAlign.Start)
        }
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /** 评论头部（头像 + 昵称 + 时间 + 点赞） */
  @Builder
  CommentHeader(comment: Comment) {
    Row({ space: 8 }) {
      Image(ImageUtil.get(comment.authorAvatar))
        .width(28)
        .height(28)
        .borderRadius(14)
      Column({ space: 1 }) {
        Row({ space: 4 }) {
          Text(comment.authorNickname)
            .fontSize(12)
            .fontColor($r('app.color.color_text_primary'))
            .fontWeight(FontWeight.Medium)
          if (comment.authorType === 'farmer') {
            Text('卖')
              .fontSize(8)
              .fontColor(Color.White)
              .backgroundColor($r('app.color.color_secondary'))
              .padding({ left: 2, right: 2, top: 0, bottom: 0 })
              .borderRadius(2)
          }
        }
        .alignItems(VerticalAlign.Center)
        Text(this.formatTime(comment.createdAt))
          .fontSize(10)
          .fontColor($r('app.color.color_text_hint'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      // 点赞
      Column({ space: 1 }) {
        Text(comment.isLiked ? '❤️' : '🤍')
          .fontSize(13)
        Text(this.formatCount(comment.likeCount))
          .fontSize(10)
          .fontColor(comment.isLiked ? $r('app.color.color_primary') : $r('app.color.color_text_hint'))
      }
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        this.onLike(comment);
      })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  /** 评论正文 + 回复按钮 */
  @Builder
  CommentBody(comment: Comment) {
    Column({ space: 4 }) {
      // 评论内容（回复某人时显示 "@被回复人"）
      if (comment.replyToNickname) {
        Row() {
          Text('回复 @')
            .fontSize(13)
            .fontColor($r('app.color.color_text_secondary'))
          Text(comment.replyToNickname)
            .fontSize(13)
            .fontColor($r('app.color.color_primary'))
          Text('：')
            .fontSize(13)
            .fontColor($r('app.color.color_text_secondary'))
          Text(comment.content)
            .fontSize(13)
            .fontColor($r('app.color.color_text_primary'))
            .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
      } else {
        Text(comment.content)
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
      }
      // 回复按钮
      Text('回复')
        .fontSize(11)
        .fontColor($r('app.color.color_text_hint'))
        .onClick(() => {
          this.onReply(comment);
        })
    }
    .width('100%')
    .padding({ left: 36 })
    .alignItems(HorizontalAlign.Start)
  }

  /** 格式化数字 */
  private formatCount(count: number): string {
    if (count >= 10000) {
      return `${(count / 10000).toFixed(1)}万`;
    }
    return `${count}`;
  }

  /** 格式化时间 */
  private formatTime(timestamp: number): string {
    const diff: number = Date.now() - timestamp;
    const minutes: number = Math.floor(diff / 60000);
    if (minutes < 1) {
      return '刚刚';
    }
    if (minutes < 60) {
      return `${minutes}分钟前`;
    }
    const hours: number = Math.floor(minutes / 60);
    if (hours < 24) {
      return `${hours}小时前`;
    }
    const days: number = Math.floor(hours / 24);
    if (days < 30) {
      return `${days}天前`;
    }
    const date: Date = new Date(timestamp);
    return `${date.getMonth() + 1}月${date.getDate()}日`;
  }
}
