/**
 * ConfigUtil - 全局配置工具
 * 遵循 spec 1.2.3：通过 common 模块统一管理 baseUrl（dev/prod 环境切换）
 * 当前 dev: http://10.0.2.2:5000/api，prod: 留空待部署后填写
 */

import { AppConstants } from '../constants/AppConstants';

interface ServerConfig {
  /** HTTP REST 基础地址（含 /api 前缀） */
  baseUrl: string;
  /** WebSocket 基础地址（含 /api 前缀） */
  wsUrl: string;
  /** 静态资源基础地址 */
  staticUrl: string;
  /** 百度地图 AK（占位符，待用户提供真实 AK） */
  baiduMapAk: string;
  /** 是否为开发环境 */
  isDev: boolean;
}

class ConfigUtilImpl {
  /** 开发环境配置（本机调试） */
  private readonly devConfig: ServerConfig = {
    baseUrl: 'http://10.0.2.2:5000/api',
    wsUrl: 'ws://10.0.2.2:5000/api/ws',
    staticUrl: 'http://10.0.2.2:5000/static',
    baiduMapAk: 'PLACEHOLDER_BAIDU_MAP_AK',
    isDev: true
  };

  /** 生产环境配置（部署后填写） */
  private readonly prodConfig: ServerConfig = {
    baseUrl: 'https://api.zhunong.example.com/api',
    wsUrl: 'wss://api.zhunong.example.com/api/ws',
    staticUrl: 'https://api.zhunong.example.com/static',
    baiduMapAk: 'PLACEHOLDER_BAIDU_MAP_AK',
    isDev: false
  };

  /** 当前激活配置（默认 dev） */
  private activeConfig: ServerConfig = this.devConfig;

  /** 获取当前配置 */
  getConfig(): ServerConfig {
    return this.activeConfig;
  }

  /** 切换到开发环境 */
  useDev(): void {
    this.activeConfig = this.devConfig;
  }

  /** 切换到生产环境 */
  useProd(): void {
    this.activeConfig = this.prodConfig;
  }

  /** 拼接完整 REST URL */
  apiUrl(path: string): string {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    const prefix: string = this.activeConfig.baseUrl.endsWith('/')
      ? this.activeConfig.baseUrl.slice(0, -1)
      : this.activeConfig.baseUrl;
    const suffix: string = path.startsWith('/') ? path : `/${path}`;
    return `${prefix}${suffix}`;
  }

  /** 拼接 WebSocket URL（含 token 参数） */
  wsUrl(path: string, token?: string): string {
    const prefix: string = this.activeConfig.wsUrl.endsWith('/')
      ? this.activeConfig.wsUrl.slice(0, -1)
      : this.activeConfig.wsUrl;
    const suffix: string = path.startsWith('/') ? path : `/${path}`;
    const base: string = `${prefix}${suffix}`;
    if (token && token.length > 0) {
      const separator: string = base.includes('?') ? '&' : '?';
      return `${base}${separator}token=${token}`;
    }
    return base;
  }

  /** 拼接静态资源完整 URL（uploads/xxx.png → 完整 URL） */
  staticUrl(path: string): string {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    const prefix: string = this.activeConfig.staticUrl.endsWith('/')
      ? this.activeConfig.staticUrl.slice(0, -1)
      : this.activeConfig.staticUrl;
    const suffix: string = path.startsWith('/') ? path : `/${path}`;
    return `${prefix}${suffix}`;
  }

  /** 获取百度地图 AK */
  getBaiduMapAk(): string {
    return this.activeConfig.baiduMapAk;
  }

  /**
   * 是否启用真实百度地图 SDK（spec 10.4）。
   * 默认 false：文旅地图页使用自绘 Mock 地图 + 本地 Mock POI，保证编译通过。
   * 启用条件：用户提供真实 AK + ohpm 安装 @bdmap/* 包 + 调用 setUseRealBaiduMap(true)。
   */
  private realBaiduMapEnabled: boolean = false;

  /** 是否启用真实百度地图 SDK */
  useRealBaiduMap(): boolean {
    return this.realBaiduMapEnabled;
  }

  /** 设置是否启用真实百度地图 SDK（联调阶段手动开启） */
  setUseRealBaiduMap(enabled: boolean): void {
    this.realBaiduMapEnabled = enabled;
  }

  /** 是否开发环境 */
  isDev(): boolean {
    return this.activeConfig.isDev;
  }
}

/** 全局配置单例 */
export const ConfigUtil: ConfigUtilImpl = new ConfigUtilImpl();
