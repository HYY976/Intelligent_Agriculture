/**
 * ImageUtil - 用户端图片资源解析工具
 * 遵循 spec 2.3.2：禁止硬编码色值/图片，统一通过 $r 引用本地资源
 * 作用：将 Mock 数据中的字符串图片 key 解析为 ArkUI Resource
 * 后续对接后端时，可在此扩展网络 URL 分支
 *
 * 演示模式：get() 优先检查 ImageReplaceStore，若已替换则返回 file:// URI
 */

import { ImageReplaceStore } from './ImageReplaceStore';

export class ImageUtil {
  /**
   * 根据 key 解析本地图片资源（优先返回演示替换图）
   * @param key media 资源名（不含 app.media. 前缀）
   * @returns Resource 引用 或 file:// URI 字符串
   */
  static get(key: string): string | Resource {
    // 演示模式：优先检查全局替换存储
    const replaced: string | undefined = ImageReplaceStore.getUri(key);
    if (replaced !== undefined) {
      return replaced;
    }
    return ImageUtil.getOriginal(key);
  }

  /**
   * 根据 key 解析原始本地图片资源（不检查替换存储）
   * @returns Resource 引用
   */
  static getOriginal(key: string): Resource {
    switch (key) {
      // 商品图（spec 4.1.3 mainImages）
      case 'prod_vegetable_1': return $r('app.media.prod_vegetable_1');
      case 'prod_vegetable_2': return $r('app.media.prod_vegetable_2');
      case 'prod_fruit_1': return $r('app.media.prod_fruit_1');
      case 'prod_fruit_2': return $r('app.media.prod_fruit_2');
      case 'prod_rice_1': return $r('app.media.prod_rice_1');
      case 'prod_egg_1': return $r('app.media.prod_egg_1');
      case 'prod_tea_1': return $r('app.media.prod_tea_1');
      case 'prod_nut_1': return $r('app.media.prod_nut_1');
      case 'prod_honey_1': return $r('app.media.prod_honey_1');
      case 'prod_meat_1': return $r('app.media.prod_meat_1');
      case 'prod_dried_1': return $r('app.media.prod_dried_1');
      case 'prod_mushroom_1': return $r('app.media.prod_mushroom_1');
      case 'prod_chili_1': return $r('app.media.prod_chili_1');
      case 'prod_corn_1': return $r('app.media.prod_corn_1');
      case 'prod_bean_1': return $r('app.media.prod_bean_1');
      // 头像
      case 'avatar_default': return $r('app.media.avatar_default');
      case 'avatar_farmer_1': return $r('app.media.avatar_farmer_1');
      case 'avatar_farmer_2': return $r('app.media.avatar_farmer_2');
      case 'avatar_farmer_3': return $r('app.media.avatar_farmer_3');
      // 吉祥物
      case 'mascot_farmer': return $r('app.media.mascot_farmer');
      case 'hero_harvest': return $r('app.media.hero_harvest');
      // spec 16.12：AI 海报生成结果图（与 farmer 端共享）
      case 'ai_poster_result': return $r('app.media.5ca5fecf7f0a30564c6060604cfdae53');
      // 文旅
      case 'farm_picking': return $r('app.media.farm_picking');
      case 'live_orchard': return $r('app.media.live_orchard');
      // 店铺 Logo
      case 'shop_logo_default': return $r('app.media.shop_logo_default');
      // 开屏广告
      case 'splash_ad_1': return $r('app.media.splash_ad_1');
      case 'splash_ad_2': return $r('app.media.splash_ad_2');
      // 默认兜底图
      default: return $r('app.media.prod_vegetable_1');
    }
  }

  /** 获取默认商品图（无图兜底） */
  static getDefaultProduct(): Resource {
    return $r('app.media.prod_vegetable_1');
  }

  /** 获取默认头像 */
  static getDefaultAvatar(): Resource {
    return $r('app.media.avatar_default');
  }

  /** 获取默认店铺 Logo */
  static getDefaultShopLogo(): Resource {
    return $r('app.media.shop_logo_default');
  }
}
