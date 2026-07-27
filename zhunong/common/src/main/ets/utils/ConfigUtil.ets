/**
 * ConfigUtil - 全局配置工具
 * 遵循 spec 1.2.3：通过 common 模块统一管理 baseUrl（dev/prod 环境切换）
 * 当前 dev: http://192.168.1.100:5000/api，prod: 留空待部署后填写
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

/** 阿里云百炼（Bailian）应用调用配置 */
interface BailianConfig {
  /** 百炼统一 BaseURL（应用调用） */
  baseUrl: string;
  /** 百炼应用 ID（app_id） */
  appId: string;
  /** 百炼 API Key（sk-ws-...） */
  apiKey: string;
}

/** 阿里云百炼 AI 助手智能体配置（用于 AI 助手对话页） */
interface BailianAgentConfig {
  /** 百炼应用调用 BaseURL（含 /api/v1/apps 前缀） */
  baseUrl: string;
  /** 百炼智能体应用 ID */
  appId: string;
  /** 百炼 API Key */
  apiKey: string;
}

/** 阿里云百炼直播开播介绍优化智能体配置（spec 16.7：用于开播介绍 AI 优化） */
interface BailianLiveIntroConfig {
  /** 百炼应用调用 BaseURL（含 /api/v1/apps 前缀） */
  baseUrl: string;
  /** 百炼直播智能体应用 ID */
  appId: string;
  /** 百炼 API Key */
  apiKey: string;
}

class ConfigUtilImpl {
  /** 开发环境配置（本机调试） */
  private readonly devConfig: ServerConfig = {
    baseUrl: 'http://192.168.1.100:5000/api',
    wsUrl: 'ws://192.168.1.100:5000/api/ws',
    staticUrl: 'http://192.168.1.100:5000/static',
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

  /** 阿里云百炼配置（用户提供的应用 ID + API Key） */
  private readonly bailianConfig: BailianConfig = {
    // 阿里云百炼应用调用统一入口（注意是 /apps/ 不是 /applications/）
    // 官方文档：https://help.aliyun.com/zh/model-studio/developer-reference/call-application-through-api
    baseUrl: 'https://dashscope.aliyuncs.com/api/v1/apps',
    appId: '1106454de98d442d8581e6ed187f9a75',
    apiKey: 'sk-ws-H.EIDXEHY.0yN1.MEUCIQCGLsoRoygKGO0EwHgKnjHfgqFfnNpql8OjjHxdnzWGMgIgCPKEVyj1huJEFKkR4jcsYamh6L1ViV3aGK1eWjG8Hf8'
  };

  /** 阿里云百炼 AI 助手智能体配置（用于顶部导航栏 AI 助手对话页） */
  private readonly bailianAgentConfig: BailianAgentConfig = {
    // 使用华北2-北京业务空间专属域名（API Host），性能更好、稳定性更高
    // 专属域名格式：https://{WorkspaceId}.cn-beijing.maas.aliyuncs.com/api/v1/apps
    baseUrl: 'https://llm-rybx4hw7nil2ekgl.cn-beijing.maas.aliyuncs.com/api/v1/apps',
    appId: '73e8df32b0d44ad090927ff7d33b9e19',
    apiKey: 'sk-ws-H.EIDXEHY.0yN1.MEUCIQCGLsoRoygKGO0EwHgKnjHfgqFfnNpql8OjjHxdnzWGMgIgCPKEVyj1huJEFKkR4jcsYamh6L1ViV3aGK1eWjG8Hf8'
  };

  /** spec 16.7：阿里云百炼直播开播介绍优化智能体配置（农户端创建直播页 AI 优化按钮） */
  private readonly bailianLiveIntroConfig: BailianLiveIntroConfig = {
    // 使用华北2-北京业务空间专属域名（API Host），性能更好、稳定性更高
    // 专属域名格式：https://{WorkspaceId}.cn-beijing.maas.aliyuncs.com/api/v1/apps
    // 实际请求 URL：{baseUrl}/{appId}/completion
    baseUrl: 'https://llm-rybx4hw7nil2ekgl.cn-beijing.maas.aliyuncs.com/api/v1/apps',
    appId: '38c6f2e6d0a74cc38081b07872ecac5f',
    apiKey: 'sk-ws-H.EIDXEHY.0yN1.MEUCIQCGLsoRoygKGO0EwHgKnjHfgqFfnNpql8OjjHxdnzWGMgIgCPKEVyj1huJEFKkR4jcsYamh6L1ViV3aGK1eWjG8Hf8'
  };

  /** 获取当前配置 */
  getConfig(): ServerConfig {
    return this.activeConfig;
  }

  /** 获取阿里云百炼配置 */
  getBailianConfig(): BailianConfig {
    return this.bailianConfig;
  }

  /** 获取阿里云百炼 AI 助手智能体配置 */
  getBailianAgentConfig(): BailianAgentConfig {
    return this.bailianAgentConfig;
  }

  /** spec 16.7：获取阿里云百炼直播开播介绍优化智能体配置 */
  getBailianLiveIntroConfig(): BailianLiveIntroConfig {
    return this.bailianLiveIntroConfig;
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
