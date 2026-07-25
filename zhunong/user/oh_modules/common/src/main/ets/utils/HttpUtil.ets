/**
 * HttpUtil - HTTP 请求工具
 * 封装 @ohos.net.http，统一处理：
 *  - JWT Token 注入（Header: Authorization: Bearer <token>，spec 1.2.3）
 *  - 超时控制（默认15s，AI接口30-60s，spec 2.2.4）
 *  - 错误分类处理（网络错误/业务错误/系统错误，spec 2.2.4）
 *  - Promise.catch 兜底（spec 2.2.4）
 *  - 统一响应解析为 ApiResponse<T>
 */

import { http } from '@kit.NetworkKit';
import { AppStorageV2 } from '@kit.ArkUI';
import { Logger } from './Logger';
import { ConfigUtil } from './ConfigUtil';
import { PreferencesUtil } from './PreferencesUtil';
import { ToastUtil } from './ToastUtil';
import { AppConstants } from '../constants/AppConstants';
import { ApiResponse, AuthExpiredKey } from '../model/CommonModels';

type HttpMethod = 'GET' | 'POST' | 'PUT' | 'DELETE';

interface RequestOptions {
  /** 是否携带 JWT Token（默认 true） */
  withAuth?: boolean;
  /** 自定义请求头 */
  headers?: Record<string, string>;
  /** 超时时间（毫秒） */
  timeout?: number;
  /** 是否展示错误 Toast（默认 true） */
  showErrorToast?: boolean;
  /** 是否在 401 时跳转登录页（默认 true） */
  redirectOnAuth?: boolean;
}

class HttpUtilImpl {
  /** GET 请求（params 为具体属性 interface 实例，避免索引签名触发 arkts-no-untyped-obj-literals） */
  async get<T>(path: string, params?: object, options?: RequestOptions): Promise<ApiResponse<T>> {
    const url: string = this.buildUrl(path, params);
    return this.request<T>('GET', url, undefined, options);
  }

  /** POST 请求 */
  async post<T>(path: string, body?: object, options?: RequestOptions): Promise<ApiResponse<T>> {
    const url: string = ConfigUtil.apiUrl(path);
    return this.request<T>('POST', url, body, options);
  }

  /** PUT 请求 */
  async put<T>(path: string, body?: object, options?: RequestOptions): Promise<ApiResponse<T>> {
    const url: string = ConfigUtil.apiUrl(path);
    return this.request<T>('PUT', url, body, options);
  }

  /** DELETE 请求 */
  async delete<T>(path: string, options?: RequestOptions): Promise<ApiResponse<T>> {
    const url: string = ConfigUtil.apiUrl(path);
    return this.request<T>('DELETE', url, undefined, options);
  }

  /** 底层请求实现 */
  private async request<T>(method: HttpMethod, url: string, body?: object, options?: RequestOptions): Promise<ApiResponse<T>> {
    const opts: RequestOptions = options ?? {};
    const withAuth: boolean = opts.withAuth ?? true;
    const timeout: number = opts.timeout ?? AppConstants.HTTP_TIMEOUT_DEFAULT;
    const showErrorToast: boolean = opts.showErrorToast ?? true;
    const redirectOnAuth: boolean = opts.redirectOnAuth ?? true;

    const httpRequest: http.HttpRequest = http.createHttp();
    const headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };
    // 显式合并自定义请求头（ArkTS 禁用 spread 操作符）
    if (opts.headers) {
      const headerKeys: string[] = Object.keys(opts.headers);
      headerKeys.forEach((k: string) => {
        headers[k] = opts.headers![k];
      });
    }

    if (withAuth) {
      const token: string = await PreferencesUtil.getString(AppConstants.KEY_TOKEN, '');
      if (token.length > 0) {
        headers['Authorization'] = `Bearer ${token}`;
      }
    }

    try {
      Logger.info(AppConstants.SCENE_COMMON, { action: 'http_request', method, url });

      const response: http.HttpResponse = await httpRequest.request(url, {
        method: this.mapHttpMethod(method),
        header: headers,
        extraData: body ? JSON.stringify(body) : undefined,
        connectTimeout: timeout,
        readTimeout: timeout,
        expectDataType: http.HttpDataType.STRING
      });

      const responseStr: string = typeof response.result === 'string' ? response.result : '';
      const responseCode: number = response.responseCode;

      Logger.info(AppConstants.SCENE_COMMON, { action: 'http_response', method, url, status: responseCode });

      if (responseCode === 401 && redirectOnAuth) {
        await this.handleUnauthorized();
        return { code: 401, msg: '请先登录', data: null } as ApiResponse<T>;
      }

      if (responseCode >= 200 && responseCode < 300) {
        const parsed: ApiResponse<T> = JSON.parse(responseStr) as ApiResponse<T>;
        return parsed;
      }

      // HTTP 状态码非 2xx
      if (showErrorToast) {
        ToastUtil.error(`请求失败(${responseCode})`);
      }
      return { code: responseCode, msg: `请求失败(${responseCode})`, data: null } as ApiResponse<T>;
    } catch (err) {
      const errMsg: string = (err as Error).message ?? '网络请求异常';
      Logger.error(AppConstants.SCENE_COMMON, { action: 'http_error', method, url, error: errMsg });
      if (showErrorToast) {
        ToastUtil.error('网络连接失败，请检查网络后重试');
      }
      return { code: -1, msg: errMsg, data: null } as ApiResponse<T>;
    } finally {
      httpRequest.destroy();
    }
  }

  /** 构造带 query 参数的 URL（通过 Object.entries 遍历 params 对象，避开索引签名访问） */
  private buildUrl(path: string, params?: object): string {
    const base: string = ConfigUtil.apiUrl(path);
    if (!params) {
      return base;
    }
    const entries: Array<[string, Object]> = Object.entries(params);
    if (entries.length === 0) {
      return base;
    }
    const queryParts: string[] = [];
    entries.forEach((entry: [string, Object]) => {
      const k: string = entry[0];
      const v: Object = entry[1];
      queryParts.push(`${encodeURIComponent(k)}=${encodeURIComponent(String(v))}`);
    });
    const separator: string = base.includes('?') ? '&' : '?';
    return `${base}${separator}${queryParts.join('&')}`;
  }

  /** 映射 HttpMethod 枚举 */
  private mapHttpMethod(method: HttpMethod): http.RequestMethod {
    switch (method) {
      case 'GET':
        return http.RequestMethod.GET;
      case 'POST':
        return http.RequestMethod.POST;
      case 'PUT':
        return http.RequestMethod.PUT;
      case 'DELETE':
        return http.RequestMethod.DELETE;
      default:
        return http.RequestMethod.GET;
    }
  }

  /** 401 处理：清除 Token 并跳转登录页 */
  private async handleUnauthorized(): Promise<void> {
    await PreferencesUtil.remove(AppConstants.KEY_TOKEN);
    await PreferencesUtil.remove(AppConstants.KEY_USER_INFO);
    ToastUtil.warning('登录已过期，请重新登录');
    // spec 10.9.3：AppStorage.setOrCreate → AppStorageV2.connect + .value 赋值
    // 实际跳转由各端 EntryAbility 处理（通过 AppStorageV2 监听 auth_expired 变化）
    // 10.12：Key 类型 interface → class，回调改为 new AuthExpiredKey()
    const expiredRef: AuthExpiredKey = AppStorageV2.connect(
      AuthExpiredKey,
      'auth_expired',
      () => new AuthExpiredKey()
    )!;
    expiredRef.value = Date.now();
  }
}

/** 全局 HTTP 单例 */
export const HttpUtil: HttpUtilImpl = new HttpUtilImpl();
