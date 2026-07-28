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
      // 买家/粉丝头像（spec 16.8：扩展至 avatar_user_15，支持更多粉丝 Mock 数据）
      case 'avatar_customer':
      case 'avatar_user_1':
      case 'avatar_user_2':
      case 'avatar_user_3':
      case 'avatar_user_4':
      case 'avatar_user_5':
      case 'avatar_user_6':
      case 'avatar_user_7':
      case 'avatar_user_8':
      case 'avatar_user_9':
      case 'avatar_user_10':
      case 'avatar_user_11':
      case 'avatar_user_12':
      case 'avatar_user_13':
      case 'avatar_user_14':
      case 'avatar_user_15':
      case 'avatar_user_16':
      case 'avatar_user_17':
      case 'avatar_user_18':
      case 'avatar_user_19':
      case 'avatar_user_20':
        return $r('app.media.avatar_customer');
      // 吉祥物
      case 'mascot_farmer': return $r('app.media.mascot_farmer');
      // spec 16.12：AI 海报生成结果图
      case 'ai_poster_result': return $r('app.media.5ca5fecf7f0a30564c6060604cfdae53');
      // 直播封面图（spec 16.8：live_orchard + live_cover_1~16 映射到可用农产品图）
      case 'live_orchard': return $r('app.media.live_orchard');
      case 'live_cover_1': return $r('app.media.prod_strawberry');
      case 'live_cover_2': return $r('app.media.prod_rice');
      case 'live_cover_3': return $r('app.media.prod_tea');
      case 'live_cover_4': return $r('app.media.prod_eggs');
      case 'live_cover_5': return $r('app.media.prod_honey');
      case 'live_cover_6': return $r('app.media.prod_tomato');
      case 'live_cover_7': return $r('app.media.prod_strawberry');
      case 'live_cover_8': return $r('app.media.prod_honey');
      case 'live_cover_9': return $r('app.media.prod_rice');
      case 'live_cover_10': return $r('app.media.prod_eggs');
      case 'live_cover_11': return $r('app.media.prod_tea');
      case 'live_cover_12': return $r('app.media.prod_strawberry');
      case 'live_cover_13': return $r('app.media.prod_tomato');
      case 'live_cover_14': return $r('app.media.prod_strawberry');
      case 'live_cover_15': return $r('app.media.prod_honey');
      case 'live_cover_16': return $r('app.media.prod_rice');
      // 默认兜底图
      default: return $r('app.media.prod_strawberry');
    }
  }

  /** 获取默认商品图（无图兜底） */
  static getDefaultProduct(): Resource {
    return $r('app.media.prod_strawberry');
  }

  /** 获取原始图片资源（ReplaceableImage 未替换时的兜底图，等同于 get） */
  static getOriginal(key: string): Resource {
    return ImageUtil.get(key);
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
