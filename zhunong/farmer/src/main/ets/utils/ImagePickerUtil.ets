/**
 * ImagePickerUtil - 图片选择工具
 *
 * 基于 HarmonyOS NEXT @kit.MediaLibraryKit 的 PhotoViewPicker 实现，
 * 支持从设备相册选择图片（真机/模拟器）。
 *
 * 使用场景：
 *  - 直播封面上传
 *  - 商品图片上传
 *  - 社区帖子配图
 *  - 头像上传
 */

import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { Logger, AppConstants } from 'common';

/** 单图选择回调（成功） */
export type OnPickSuccess = (uri: string) => void;
/** 单图选择回调（失败/取消） */
export type OnPickError = (msg: string) => void;

class ImagePickerUtilImpl {
  /**
   * 调起系统图库选择单张图片
   * @param onSuccess 成功回调，返回图片 URI（file:// 协议，可直接用于 Image 组件 src）
   * @param onError 失败/取消回调，返回错误信息
   */
  async pickSingleImage(onSuccess: OnPickSuccess, onError: OnPickError): Promise<void> {
    try {
      Logger.info(AppConstants.SCENE_FARMER, {
        action: 'image_picker_start'
      });

      const options: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 1;

      const photoPicker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
      const result: photoAccessHelper.PhotoSelectResult = await photoPicker.select(options);

      const uris: string[] = result.photoUris;
      if (uris.length === 0) {
        Logger.warn(AppConstants.SCENE_FARMER, {
          action: 'image_picker_empty'
        });
        onError('未选择图片');
        return;
      }

      Logger.info(AppConstants.SCENE_FARMER, {
        action: 'image_picker_done',
        count: uris.length
      });
      onSuccess(uris[0]);
    } catch (err) {
      const errMsg: string = (err as Error).message ?? '图片选择失败';
      Logger.error(AppConstants.SCENE_FARMER, {
        action: 'image_picker_exception',
        error: errMsg
      });
      onError(errMsg);
    }
  }

  /**
   * 调起系统图库选择多张图片
   * @param maxNumber 最大数量
   * @param onSuccess 成功回调，返回图片 URI 列表
   * @param onError 失败/取消回调
   */
  async pickMultipleImages(
    maxNumber: number,
    onSuccess: (uris: string[]) => void,
    onError: OnPickError
  ): Promise<void> {
    try {
      Logger.info(AppConstants.SCENE_FARMER, {
        action: 'image_picker_multi_start',
        count: maxNumber
      });

      const options: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = maxNumber;

      const photoPicker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
      const result: photoAccessHelper.PhotoSelectResult = await photoPicker.select(options);

      const uris: string[] = result.photoUris;
      if (uris.length === 0) {
        Logger.warn(AppConstants.SCENE_FARMER, {
          action: 'image_picker_multi_empty'
        });
        onError('未选择图片');
        return;
      }

      Logger.info(AppConstants.SCENE_FARMER, {
        action: 'image_picker_multi_done',
        count: uris.length
      });
      onSuccess(uris);
    } catch (err) {
      const errMsg: string = (err as Error).message ?? '图片选择失败';
      Logger.error(AppConstants.SCENE_FARMER, {
        action: 'image_picker_multi_exception',
        error: errMsg
      });
      onError(errMsg);
    }
  }
}

/** 图片选择工具单例 */
export const ImagePickerUtil: ImagePickerUtilImpl = new ImagePickerUtilImpl();
