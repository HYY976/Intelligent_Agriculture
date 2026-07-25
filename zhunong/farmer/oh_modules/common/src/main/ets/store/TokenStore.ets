/**
 * TokenStore - JWT Token 状态管理
 * 遵循 spec 1.2.3：JWT Token，请求头 Authorization: Bearer <token>
 *                2.1.3：Token 通过 Preferences 持久化
 *                用户/卖家 7 天有效，管理员 24 小时（后端控制）
 *                10.9.3：AppStorage → AppStorageV2（API 12+ 类型安全版本）
 *                10.12：Key 类型 interface → class（AppStorageV2.connect 需要）
 */

import { AppStorageV2 } from '@kit.ArkUI';
import { PreferencesUtil } from '../utils/PreferencesUtil';
import { Logger } from '../utils/Logger';
import { AppConstants } from '../constants/AppConstants';
import { UserInfo, AdminInfo, AuthTokenKey, UserInfoKey, AdminInfoKey } from '../model/CommonModels';

class TokenStoreImpl {
  /** AppStorageV2 中各 Key 的存储名 */
  static readonly STORAGE_KEY_TOKEN: string = 'authToken';
  static readonly STORAGE_KEY_USER: string = 'authUser';
  static readonly STORAGE_KEY_ADMIN: string = 'authAdmin';

  /** 保存 Token */
  async setToken(token: string): Promise<void> {
    await PreferencesUtil.putString(AppConstants.KEY_TOKEN, token);
    const tokenRef: AuthTokenKey = AppStorageV2.connect(
      AuthTokenKey,
      TokenStoreImpl.STORAGE_KEY_TOKEN,
      () => new AuthTokenKey()
    )!;
    tokenRef.value = token;
    Logger.info(AppConstants.SCENE_COMMON, { action: 'token_saved' });
  }

  /** 读取 Token */
  async getToken(): Promise<string> {
    const tokenRef: AuthTokenKey = AppStorageV2.connect(
      AuthTokenKey,
      TokenStoreImpl.STORAGE_KEY_TOKEN,
      () => new AuthTokenKey()
    )!;
    if (tokenRef.value && tokenRef.value.length > 0) {
      return tokenRef.value;
    }
    return await PreferencesUtil.getString(AppConstants.KEY_TOKEN, '');
  }

  /** 保存用户信息（用户端/卖家端） */
  async setUserInfo(userInfo: UserInfo): Promise<void> {
    await PreferencesUtil.putString(AppConstants.KEY_USER_INFO, JSON.stringify(userInfo));
    const userRef: UserInfoKey = AppStorageV2.connect(
      UserInfoKey,
      TokenStoreImpl.STORAGE_KEY_USER,
      () => new UserInfoKey()
    )!;
    userRef.value = userInfo;
  }

  /** 读取用户信息 */
  async getUserInfo(): Promise<UserInfo | null> {
    const userRef: UserInfoKey = AppStorageV2.connect(
      UserInfoKey,
      TokenStoreImpl.STORAGE_KEY_USER,
      () => new UserInfoKey()
    )!;
    if (userRef.value !== null) {
      return userRef.value;
    }
    const json: string = await PreferencesUtil.getString(AppConstants.KEY_USER_INFO, '');
    if (json.length === 0) {
      return null;
    }
    try {
      return JSON.parse(json) as UserInfo;
    } catch (err) {
      Logger.error(AppConstants.SCENE_COMMON, { action: 'parse_user_info_fail', error: (err as Error).message });
      return null;
    }
  }

  /** 保存管理员信息 */
  async setAdminInfo(adminInfo: AdminInfo): Promise<void> {
    await PreferencesUtil.putString('admin_info', JSON.stringify(adminInfo));
    const adminRef: AdminInfoKey = AppStorageV2.connect(
      AdminInfoKey,
      TokenStoreImpl.STORAGE_KEY_ADMIN,
      () => new AdminInfoKey()
    )!;
    adminRef.value = adminInfo;
  }

  /** 读取管理员信息 */
  async getAdminInfo(): Promise<AdminInfo | null> {
    const adminRef: AdminInfoKey = AppStorageV2.connect(
      AdminInfoKey,
      TokenStoreImpl.STORAGE_KEY_ADMIN,
      () => new AdminInfoKey()
    )!;
    if (adminRef.value !== null) {
      return adminRef.value;
    }
    const json: string = await PreferencesUtil.getString('admin_info', '');
    if (json.length === 0) {
      return null;
    }
    try {
      return JSON.parse(json) as AdminInfo;
    } catch (err) {
      Logger.error(AppConstants.SCENE_COMMON, { action: 'parse_admin_info_fail', error: (err as Error).message });
      return null;
    }
  }

  /** 是否已登录 */
  async isLoggedIn(): Promise<boolean> {
    const token: string = await this.getToken();
    return token.length > 0;
  }

  /** 退出登录（清除全部鉴权信息） */
  async clearAuth(): Promise<void> {
    await PreferencesUtil.remove(AppConstants.KEY_TOKEN);
    await PreferencesUtil.remove(AppConstants.KEY_USER_INFO);
    await PreferencesUtil.remove('admin_info');
    const tokenRef: AuthTokenKey = AppStorageV2.connect(
      AuthTokenKey,
      TokenStoreImpl.STORAGE_KEY_TOKEN,
      () => new AuthTokenKey()
    )!;
    tokenRef.value = '';
    const userRef: UserInfoKey = AppStorageV2.connect(
      UserInfoKey,
      TokenStoreImpl.STORAGE_KEY_USER,
      () => new UserInfoKey()
    )!;
    userRef.value = null;
    const adminRef: AdminInfoKey = AppStorageV2.connect(
      AdminInfoKey,
      TokenStoreImpl.STORAGE_KEY_ADMIN,
      () => new AdminInfoKey()
    )!;
    adminRef.value = null;
    Logger.info(AppConstants.SCENE_COMMON, { action: 'auth_cleared' });
  }
}

/** 全局 Token 单例 */
export const TokenStore: TokenStoreImpl = new TokenStoreImpl();
