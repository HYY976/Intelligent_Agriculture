/**
 * ImageUtil - 农户端图片资源解析工具
 * 遵循 spec 2.3.2：禁止硬编码图片，统一通过 $r 引用本地资源
 * 作用：将 Mock 数据中的字符串图片 key 解析为 ArkUI Resource
 */

export class ImageUtil {
  /**
   * 根据 key 解析本地图片资源
   * @param key media 资源名（不含 app.media. 前缀）
   * @returns Resource 引用
   */
  static get(key: string): Resource {
    switch (key) {
      // 首页横滑商品图（对齐设计稿 farmer-home.html 6 张商品卡）
      case 'prod_strawberry': return $r('app.media.prod_strawberry');
      case 'prod_tomato': return $r('app.media.prod_tomato');
      case 'prod_tea': return $r('app.media.prod_tea');
      case 'prod_rice': return $r('app.media.prod_rice');
      case 'prod_eggs': return $r('app.media.prod_eggs');
      case 'prod_honey': return $r('app.media.prod_honey');
      // 卖家头像
      case 'avatar_farmer': return $r('app.media.avatar_farmer');
      // 买家/粉丝头像
      case 'avatar_customer':
      case 'avatar_user_1':
      case 'avatar_user_2':
      case 'avatar_user_3':
      case 'avatar_user_4':
      case 'avatar_user_5':
      case 'avatar_user_6':
      case 'avatar_user_7':
      case 'avatar_user_8':
        return $r('app.media.avatar_customer');
      // 吉祥物
      case 'mascot_farmer': return $r('app.media.mascot_farmer');
      // 直播封面图
      case 'live_orchard': return $r('app.media.live_orchard');
      // 默认兜底图
      default: return $r('app.media.prod_strawberry');
    }
  }

  /** 获取默认商品图（无图兜底） */
  static getDefaultProduct(): Resource {
    return $r('app.media.prod_strawberry');
  }

  /** 获取默认头像（卖家） */
  static getDefaultAvatar(): Resource {
    return $r('app.media.avatar_farmer');
  }

  /** 获取默认粉丝头像（买家） */
  static getDefaultFanAvatar(): Resource {
    return $r('app.media.avatar_customer');
  }
}
