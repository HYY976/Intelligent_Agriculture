/**
 * post_detail - 帖子详情（spec 3.2.4.2 / 9.9.2）
 *
 * - 帖子详情展示（作者信息+标题+正文+图片+互动）
 * - 评论列表（无限嵌套）
 * - 评论输入框（卖家评论带 V 标）
 */

import { Logger, AppConstants, ToastUtil, NavigationHelper, RouteName } from 'common';
import { Post, Comment } from '../../model/FarmerCommunityModels';
import { CommunityRepository } from '../../repository/CommunityRepository';
import { MOCK_FARMER_ID } from '../../mock/FarmerMock';

/** 扁平化评论项（递归渲染用） */
interface FlatCommentItem {
  commentId: string;
  authorId: string;
  authorType: string;
  content: string;
  likeCount: number;
  createdAt: number;
  authorNickname: string;
  authorAvatar: string;
  isSeller: boolean;
  /** 缩进层级 */
  level: number;
  /** 父评论ID */
  parentId: string | null;
}

@ComponentV2
export struct PostDetail {
  /** 帖子 ID */
  @Local postId: string = '';
  /** 帖子详情 */
  @Local post: Post | null = null;
  /** 评论列表（扁平化） */
  @Local comments: FlatCommentItem[] = [];
  /** 评论输入 */
  @Local inputComment: string = '';
  /** 是否正在加载 */
  @Local isLoading: boolean = false;
  /** 是否已点赞 */
  @Local hasLiked: boolean = false;
  /** 是否已收藏 */
  @Local hasFavorited: boolean = false;

  async aboutToAppear(): Promise<void> {
    const params: Record<string, string> = NavigationHelper.getParam<Record<string, string>>() ?? {};
    this.postId = params?.postId ?? '';
    Logger.info(AppConstants.SCENE_FARMER, { action: 'post_detail_appear', postId: this.postId });
    await this.loadData();
  }

  /** 加载帖子和评论 */
  private async loadData(): Promise<void> {
    this.isLoading = true;
    try {
      const post: Post | null = await CommunityRepository.getPostDetail(this.postId);
      if (post) {
        this.post = post;
      } else {
        ToastUtil.warning('帖子不存在');
        NavigationHelper.pop();
        return;
      }
      const comments: Comment[] = await CommunityRepository.getComments(this.postId);
      this.comments = this.flattenComments(comments, 0, null);
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'load_post_fail', error: (err as Error).message });
      ToastUtil.error('加载失败');
    } finally {
      this.isLoading = false;
    }
  }

  /** 扁平化嵌套评论 */
  private flattenComments(comments: Comment[], level: number, parentId: string | null): FlatCommentItem[] {
    const result: FlatCommentItem[] = [];
    comments.forEach((c: Comment) => {
      const item: FlatCommentItem = {
        commentId: c.commentId,
        authorId: c.authorId,
        authorType: c.authorType,
        content: c.content,
        likeCount: c.likeCount,
        createdAt: c.createdAt,
        authorNickname: c.authorNickname ?? '匿名',
        authorAvatar: c.authorAvatar ?? '',
        isSeller: c.isSeller ?? false,
        level: level,
        parentId: parentId
      };
      result.push(item);
      if (c.replies && c.replies.length > 0) {
        result.push(...this.flattenComments(c.replies, level + 1, c.commentId));
      }
    });
    return result;
  }

  /** 提交评论 */
  private async submitComment(): Promise<void> {
    if (this.inputComment.length === 0) {
      ToastUtil.warning('请输入评论内容');
      return;
    }
    try {
      await CommunityRepository.createComment(this.postId, null, MOCK_FARMER_ID, this.inputComment);
      ToastUtil.success('评论成功');
      this.inputComment = '';
      // 重新加载评论
      const comments: Comment[] = await CommunityRepository.getComments(this.postId);
      this.comments = this.flattenComments(comments, 0, null);
      Logger.info(AppConstants.SCENE_FARMER, { action: 'comment_success', postId: this.postId });
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'comment_fail', error: (err as Error).message });
      ToastUtil.error('评论失败');
    }
  }

  /** 点赞 */
  private onLike(): void {
    this.hasLiked = !this.hasLiked;
    if (this.post) {
      this.post.likeCount = this.hasLiked ? this.post.likeCount + 1 : this.post.likeCount - 1;
    }
    Logger.info(AppConstants.SCENE_FARMER, { action: 'like_post', postId: this.postId, liked: this.hasLiked });
  }

  /** 收藏 */
  private onFavorite(): void {
    this.hasFavorited = !this.hasFavorited;
    if (this.post) {
      this.post.favoriteCount = this.hasFavorited ? this.post.favoriteCount + 1 : this.post.favoriteCount - 1;
    }
    Logger.info(AppConstants.SCENE_FARMER, { action: 'favorite_post', postId: this.postId, favorited: this.hasFavorited });
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
        if (this.isLoading) {
          Column() {
            Text('加载中...')
              .fontSize(14)
              .fontColor($r('app.color.color_text_secondary'))
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else if (this.post) {
          Scroll() {
            Column({ space: 12 }) {
              this.PostDetailCard()
              this.CommentSection()
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 12, bottom: 80 })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          this.CommentInputBar()
        }
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
      Text('帖子详情')
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

  /** 帖子详情卡片 */
  @Builder
  PostDetailCard() {
    Column({ space: 12 }) {
      // 作者信息
      Row({ space: 8 }) {
        Text('👤')
          .fontSize(24)
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor($r('app.color.color_primary_light'))
          .textAlign(TextAlign.Center)
        Column({ space: 2 }) {
          Row({ space: 4 }) {
            Text(this.post?.authorNickname ?? '匿名')
              .fontSize(14)
              .fontColor($r('app.color.color_text_primary'))
              .fontWeight(FontWeight.Medium)
            if (this.post?.isSeller === true) {
              Text('V 卖家')
                .fontSize(9)
                .fontColor(Color.White)
                .backgroundColor($r('app.color.color_secondary'))
                .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                .borderRadius(4)
            }
          }
          Text(this.formatTime(this.post?.createdAt ?? 0))
            .fontSize(11)
            .fontColor($r('app.color.color_text_hint'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      // 标题
      Text(this.post?.title ?? '')
        .fontSize(18)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Bold)
        .width('100%')

      // 正文
      Text(this.post?.content ?? '')
        .fontSize(14)
        .fontColor($r('app.color.color_text_primary'))
        .width('100%')

      // 图片网格
      if (this.post && this.post.images.length > 0) {
        Grid() {
          ForEach(this.post.images, (img: string, idx: number) => {
            GridItem() {
              Stack() {
                Text('🖼')
                  .fontSize(28)
              }
              .width('100%')
              .height(100)
              .borderRadius(6)
              .backgroundColor($r('app.color.color_bg_page'))
              .alignContent(Alignment.Center)
            }
          }, (img: string, idx: number) => `${img}_${idx}`)
        }
        .columnsTemplate('1fr 1fr 1fr')
        .columnsGap(6)
        .rowsGap(6)
        .width('100%')
        .height(Math.ceil(this.post.images.length / 3) * 100 + (Math.ceil(this.post.images.length / 3) - 1) * 6)
      }

      // 互动栏
      Row({ space: 24 }) {
        Row({ space: 4 }) {
          Text(this.hasLiked ? '❤️' : '👍')
            .fontSize(14)
          Text(`${this.post?.likeCount ?? 0}`)
            .fontSize(12)
            .fontColor(this.hasLiked ? $r('app.color.color_error') : $r('app.color.color_text_hint'))
        }
        .onClick(() => this.onLike())
        Row({ space: 4 }) {
          Text('💬')
            .fontSize(14)
          Text(`${this.post?.commentCount ?? 0}`)
            .fontSize(12)
            .fontColor($r('app.color.color_text_hint'))
        }
        Row({ space: 4 }) {
          Text(this.hasFavorited ? '⭐' : '☆')
            .fontSize(14)
          Text(`${this.post?.favoriteCount ?? 0}`)
            .fontSize(12)
            .fontColor(this.hasFavorited ? $r('app.color.color_secondary') : $r('app.color.color_text_hint'))
        }
        .onClick(() => this.onFavorite())
        Blank()
        Text('🔗')
          .fontSize(14)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 评论区域 */
  @Builder
  CommentSection() {
    Column({ space: 12 }) {
      Text(`评论 ${this.comments.length}`)
        .fontSize(14)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)

      if (this.comments.length === 0) {
        Text('暂无评论，快来抢沙发！')
          .fontSize(12)
          .fontColor($r('app.color.color_text_hint'))
          .width('100%')
      } else {
        ForEach(this.comments, (item: FlatCommentItem, _idx: number) => {
          this.CommentCard(item)
        }, (item: FlatCommentItem) => item.commentId)
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 评论卡片 */
  @Builder
  CommentCard(item: FlatCommentItem) {
    Row({ space: 8 }) {
      Text('👤')
        .fontSize(16)
        .width(28)
        .height(28)
        .borderRadius(14)
        .backgroundColor($r('app.color.color_bg_page'))
        .textAlign(TextAlign.Center)
      Column({ space: 4 }) {
        Row({ space: 4 }) {
          Text(item.authorNickname)
            .fontSize(12)
            .fontColor($r('app.color.color_text_primary'))
            .fontWeight(FontWeight.Medium)
          if (item.isSeller) {
            Text('V')
              .fontSize(8)
              .fontColor(Color.White)
              .backgroundColor($r('app.color.color_secondary'))
              .width(12)
              .height(12)
              .borderRadius(6)
              .textAlign(TextAlign.Center)
          }
          Text(this.formatTime(item.createdAt))
            .fontSize(10)
            .fontColor($r('app.color.color_text_hint'))
        }
        .width('100%')
        Text(item.content)
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
          .width('100%')
        Row({ space: 12 }) {
          Text(`👍 ${item.likeCount}`)
            .fontSize(11)
            .fontColor($r('app.color.color_text_hint'))
          Text('回复')
            .fontSize(11)
            .fontColor($r('app.color.color_secondary'))
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: item.level * 16, top: 8, bottom: 8 })
  }

  /** 底部评论输入栏 */
  @Builder
  CommentInputBar() {
    Row({ space: 8 }) {
      TextInput({ text: this.inputComment, placeholder: '写评论...' })
        .height(36)
        .borderRadius(18)
        .backgroundColor($r('app.color.color_bg_page'))
        .padding({ left: 16, right: 16 })
        .fontSize(13)
        .layoutWeight(1)
        .onChange((v: string) => { this.inputComment = v; })
      Button('发送')
        .height(36)
        .borderRadius(18)
        .backgroundColor($r('app.color.color_secondary'))
        .fontColor(Color.White)
        .fontSize(12)
        .padding({ left: 16, right: 16 })
        .onClick(() => { this.submitComment(); })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor($r('app.color.color_bg_card'))
  }
}
