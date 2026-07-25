/**
 * QnAvatar - 头像组件
 * 对齐设计稿 .qn-avatar（圆形头像）/ .qn-avatar-ring（带黄色描边环）
 * spec 15.4.1：13 个公共组件之一
 */

import { AppConstants } from '../constants/AppConstants';

@ComponentV2
export struct QnAvatar {
  /** 头像图片资源 */
  @Param src: Resource = $r('app.media.avatar_customer');
  /** 尺寸（默认 48vp） */
  @Param avatarSize: number = 48;
  /** 是否带黄色描边环（对齐 .qn-avatar-ring） */
  @Param ring: boolean = false;

  build() {
    Image(this.src)
      .width(this.avatarSize)
      .height(this.avatarSize)
      .borderRadius(AppConstants.RADIUS_PILL)
      .objectFit(ImageFit.Cover)
      .border(this.ring ? { width: 3, color: $r('app.color.color_bg_card') } : { width: 0 })
      .shadow(this.ring ? {
        radius: 5,
        color: $r('app.color.color_yellow'),
        offsetX: 0,
        offsetY: 0
      } : { radius: 0, color: Color.Transparent, offsetX: 0, offsetY: 0 })
  }
}
