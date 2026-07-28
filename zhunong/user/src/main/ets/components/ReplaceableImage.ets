/**
 * ReplaceableImage - 可替换图片组件（演示用）
 * 点击右下角 📷 按钮 → 打开相册 → 选择照片 → 替换原图
 * 替换结果缓存在 ImageReplaceStore（@ObservedV2）中，同 key 全局即时生效
 *
 * 使用方式（替代 Image(ImageUtil.get(key))）：
 *   ReplaceableImage({ imageKey: key, imgWidth: '100%', imgHeight: 120, imgRadius: 8 })
 */

import { photoAccessHelper } from '@kit.MediaLibraryKit';
import fs from '@ohos.file.fs';
import { Logger, AppConstants, ToastUtil } from 'common';
import { ImageUtil } from '../utils/ImageUtil';
import { ImageReplaceStore } from '../utils/ImageReplaceStore';

@ComponentV2
export struct ReplaceableImage {
  /** 图片资源 key（对应 ImageUtil 中的 key） */
  @Param imageKey: string = '';
  /** 宽度（支持 '100%' / 数字） */
  @Param imgWidth: Length = '100%';
  /** 高度（支持 '100%' / 数字） */
  @Param imgHeight: Length = '100%';
  /** 圆角（统一） */
  @Param imgRadius: number = 0;
  /** 填充模式 */
  @Param imgFit: ImageFit = ImageFit.Cover;
  /** 响应式存储单例（读取 version 建立 V2 依赖，version 变化时自动刷新） */
  @Local store: ImageReplaceStore = ImageReplaceStore.getInstance();

  /**
   * 解析当前应显示的图片源
   * @param _version 占位参数：传入 store.version 以建立 @Trace 响应式依赖
   */
  private resolveSrc(_version: number): string | Resource {
    const replaced: string | undefined = ImageReplaceStore.getUri(this.imageKey);
    if (replaced !== undefined) {
      return replaced;
    }
    return ImageUtil.getOriginal(this.imageKey);
  }

  build() {
    Stack() {
      // 图片本体（读取 store.version 建立响应式依赖）
      Image(this.resolveSrc(this.store.version))
        .width('100%')
        .height('100%')
        .borderRadius(this.imgRadius)
        .objectFit(this.imgFit)
        .backgroundColor($r('app.color.color_fill'))

      // 右下角替换按钮（半透明 📷，点击触发相册选择）
      Text('📷')
        .fontSize(10)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .width(20)
        .height(20)
        .borderRadius(10)
        .backgroundColor('rgba(0,0,0,0.55)')
        .position({ right: 2, bottom: 2 })
        .onClick(() => { this.pickPhoto(); })
    }
    .width(this.imgWidth)
    .height(this.imgHeight)
    .clip(true)
    .borderRadius(this.imgRadius)
  }

  /** 点击 📷 → 打开相册选择图片 → 复制到内部存储 → 替换 */
  private async pickPhoto(): Promise<void> {
    try {
      ToastUtil.info('请选择图片替换');
      const options: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 1;
      const photoPicker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
      const result: photoAccessHelper.PhotoSelectResult = await photoPicker.select(options);
      if (result.photoUris && result.photoUris.length > 0) {
        const sourceUri: string = result.photoUris[0];
        const filesDir: string = getContext(this).filesDir;
        const destFileName: string = `img_${this.imageKey}_${Date.now()}.jpg`;
        const destPath: string = `${filesDir}/${destFileName}`;
        const srcFile = fs.openSync(sourceUri, fs.OpenMode.READ_ONLY);
        const destFile = fs.openSync(destPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
        fs.copyFileSync(srcFile.fd, destFile.fd);
        fs.closeSync(srcFile);
        fs.closeSync(destFile);
        const fileUri: string = `file://${destPath}`;
        ImageReplaceStore.set(this.imageKey, fileUri);
        ToastUtil.success('图片已替换，同 key 全局生效');
        Logger.info(AppConstants.SCENE_USER, { action: 'demo_image_replaced', msg: this.imageKey });
      }
    } catch (err) {
      Logger.error(AppConstants.SCENE_USER, { action: 'demo_image_replace_fail', msg: (err as Error).message });
      ToastUtil.error('替换失败，请重试');
    }
  }
}
