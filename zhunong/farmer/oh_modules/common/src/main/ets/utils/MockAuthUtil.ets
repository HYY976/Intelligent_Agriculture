/**
 * MockAuthUtil - 本地 Mock 鉴权工具（无后端时使用）
 *
 * 用途：在没有可用后端服务时，提供本地账号密码登录/注册能力，保证 App 可独立演示。
 * - 注册：用户名 + 密码 + userType，写入本地 Preferences 持久化
 * - 登录：校验用户名 + 密码 + userType，匹配后返回模拟 token + userInfo/adminInfo
 * - 预置测试账号：user/123456、farmer/123456、admin/123456
 *
 * 数据格式与 HttpUtil.post 返回的 ApiResponse<T> 对齐，便于后续切回真实后端。
 */

import { PreferencesUtil } from './PreferencesUtil';
import { Logger } from './Logger';
import { AppConstants } from '../constants/AppConstants';
import { ApiResponse, UserInfo, AdminInfo } from '../model/CommonModels';

/** Mock 用户记录（user/farmer 共用） */
interface MockUserRecord {
  userId: string;
  username: string;
  password: string;
  userType: 'user' | 'farmer';
  nickname: string;
  avatar: string;
  status: 'active' | 'banned';
  createdAt: number;
  lastLoginAt: number;
}

/** Mock 管理员记录 */
/** 管理员角色联合类型（避免索引类型访问，符合 ArkTS 规范） */
type AdminRoleType = 'super_admin' | 'user_admin' | 'content_reviewer' | 'api_admin';

interface MockAdminRecord {
  adminId: string;
  username: string;
  password: string;
  role: AdminRoleType;
  nickname: string;
  lastLoginAt: number;
}

/** 登录/注册响应（user/farmer） */
interface AuthResponseData {
  token: string;
  userInfo: UserInfo;
}

/** 管理员登录响应 */
interface AdminAuthResponseData {
  token: string;
  adminInfo: AdminInfo;
}

class MockAuthUtilImpl {
  /** Preferences 中存储用户列表的 key */
  private static readonly KEY_USERS: string = 'mock_users';
  /** Preferences 中存储管理员列表的 key */
  private static readonly KEY_ADMINS: string = 'mock_admins';

  /** 内存缓存用户列表（首次访问时从 Preferences 加载） */
  private usersCache: MockUserRecord[] | null = null;
  /** 内存缓存管理员列表 */
  private adminsCache: MockAdminRecord[] | null = null;

  /** 默认预置用户（首次启动时写入） */
  private readonly presetUsers: MockUserRecord[] = [
    {
      userId: 'u_demo_001', username: 'user', password: '123456', userType: 'user',
      nickname: 'demo_user', avatar: 'avatar_default', status: 'active',
      createdAt: 1736000000000, lastLoginAt: 1736000000000
    },
    {
      userId: 'f_demo_001', username: 'farmer', password: '123456', userType: 'farmer',
      nickname: 'demo_farmer', avatar: 'avatar_farmer_1', status: 'active',
      createdAt: 1736000000000, lastLoginAt: 1736000000000
    },
    {
      userId: 'f_demo_002', username: '青禾农庄', password: '123456', userType: 'farmer',
      nickname: '青禾农庄', avatar: 'avatar_farmer_1', status: 'active',
      createdAt: 1736000000000, lastLoginAt: 1736000000000
    },
    {
      userId: 'f_demo_003', username: '山野好物', password: '123456', userType: 'farmer',
      nickname: '山野好物', avatar: 'avatar_farmer_2', status: 'active',
      createdAt: 1736000000000, lastLoginAt: 1736000000000
    },
    {
      userId: 'f_demo_004', username: '田园牧歌', password: '123456', userType: 'farmer',
      nickname: '田园牧歌', avatar: 'avatar_farmer_3', status: 'active',
      createdAt: 1736000000000, lastLoginAt: 1736000000000
    }
  ];

  /** 默认预置管理员 */
  private readonly presetAdmins: MockAdminRecord[] = [
    {
      adminId: 'a_demo_001', username: 'admin', password: '123456', role: 'super_admin',
      nickname: '超级管理员', lastLoginAt: 1736000000000
    }
  ];

  /** 加载用户列表（首次访问时从 Preferences 读取，若无则初始化预置账号） */
  private async loadUsers(): Promise<MockUserRecord[]> {
    if (this.usersCache !== null) {
      return this.usersCache;
    }
    const json: string = await PreferencesUtil.getString(MockAuthUtilImpl.KEY_USERS, '');
    if (json.length > 0) {
      try {
        this.usersCache = JSON.parse(json) as MockUserRecord[];
        return this.usersCache;
      } catch (err) {
        Logger.error(AppConstants.SCENE_COMMON, { action: 'mock_users_parse_fail', error: (err as Error).message });
      }
    }
    // 首次启动：写入预置用户
    this.usersCache = this.presetUsers.slice();
    await this.saveUsers();
    return this.usersCache;
  }

  /** 持久化用户列表 */
  private async saveUsers(): Promise<void> {
    if (this.usersCache === null) {
      return;
    }
    await PreferencesUtil.putString(MockAuthUtilImpl.KEY_USERS, JSON.stringify(this.usersCache));
  }

  /** 加载管理员列表 */
  private async loadAdmins(): Promise<MockAdminRecord[]> {
    if (this.adminsCache !== null) {
      return this.adminsCache;
    }
    const json: string = await PreferencesUtil.getString(MockAuthUtilImpl.KEY_ADMINS, '');
    if (json.length > 0) {
      try {
        this.adminsCache = JSON.parse(json) as MockAdminRecord[];
        return this.adminsCache;
      } catch (err) {
        Logger.error(AppConstants.SCENE_COMMON, { action: 'mock_admins_parse_fail', error: (err as Error).message });
      }
    }
    this.adminsCache = this.presetAdmins.slice();
    await this.saveAdmins();
    return this.adminsCache;
  }

  /** 持久化管理员列表 */
  private async saveAdmins(): Promise<void> {
    if (this.adminsCache === null) {
      return;
    }
    await PreferencesUtil.putString(MockAuthUtilImpl.KEY_ADMINS, JSON.stringify(this.adminsCache));
  }

  /** 生成模拟 JWT token（无真实签名，仅用于本地标识） */
  private generateToken(userId: string, userType: string): string {
    const now: number = Date.now();
    const exp: number = now + 7 * 24 * 60 * 60 * 1000; // 7 天后过期
    // 简单 base64 编码 payload，避免依赖外部库
    const payload: string = `${userId}|${userType}|${now}|${exp}`;
    return `mock.${this.b64encode(payload)}.${now}`;
  }

  /** 简单 base64 编码（UTF-8 安全） */
  private b64encode(input: string): string {
    // 使用基础 ASCII 转换；中文等字符按 UTF-8 字节处理
    const bytes: number[] = [];
    for (let i = 0; i < input.length; i++) {
      const code: number = input.charCodeAt(i);
      if (code < 0x80) {
        bytes.push(code);
      } else if (code < 0x800) {
        bytes.push(0xC0 | (code >> 6));
        bytes.push(0x80 | (code & 0x3F));
      } else {
        bytes.push(0xE0 | (code >> 12));
        bytes.push(0x80 | ((code >> 6) & 0x3F));
        bytes.push(0x80 | (code & 0x3F));
      }
    }
    const chars: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    let result: string = '';
    for (let i = 0; i < bytes.length; i += 3) {
      const b1: number = bytes[i];
      const b2: number = i + 1 < bytes.length ? bytes[i + 1] : 0;
      const b3: number = i + 2 < bytes.length ? bytes[i + 2] : 0;
      result += chars[(b1 >> 2) & 0x3F];
      result += chars[((b1 << 4) | (b2 >> 4)) & 0x3F];
      result += i + 1 < bytes.length ? chars[((b2 << 2) | (b3 >> 6)) & 0x3F] : '=';
      result += i + 2 < bytes.length ? chars[b3 & 0x3F] : '=';
    }
    return result;
  }

  /** 将 MockUserRecord 转换为 UserInfo */
  private toUserInfo(record: MockUserRecord): UserInfo {
    return {
      userId: record.userId,
      phone: record.username,
      nickname: record.nickname,
      avatar: record.avatar,
      userType: record.userType,
      status: record.status,
      createdAt: record.createdAt,
      lastLoginAt: record.lastLoginAt
    } as UserInfo;
  }

  /** 将 MockAdminRecord 转换为 AdminInfo */
  private toAdminInfo(record: MockAdminRecord): AdminInfo {
    return {
      adminId: record.adminId,
      username: record.username,
      nickname: record.nickname,
      role: record.role,
      lastLoginAt: record.lastLoginAt
    } as AdminInfo;
  }

  /**
   * 注册（用户端 / 卖家端共用）
   * @param username 账号
   * @param password 密码
   * @param userType 'user' | 'farmer'
   */
  async register(username: string, password: string, userType: 'user' | 'farmer'): Promise<ApiResponse<AuthResponseData>> {
    // 模拟网络延迟
    await this.delay();

    const trimmedName: string = username.trim();
    if (trimmedName.length === 0) {
      return { code: 400, msg: '账号不能为空', data: null } as ApiResponse<AuthResponseData>;
    }
    if (password.length < 6) {
      return { code: 400, msg: '密码至少6位', data: null } as ApiResponse<AuthResponseData>;
    }

    const users: MockUserRecord[] = await this.loadUsers();
    // 检查用户名是否已被占用（同 userType 内唯一）
    const exists: boolean = users.some((u: MockUserRecord) =>
      u.username === trimmedName && u.userType === userType);
    if (exists) {
      return { code: 409, msg: '该账号已被注册', data: null } as ApiResponse<AuthResponseData>;
    }

    const now: number = Date.now();
    const newRecord: MockUserRecord = {
      userId: `${userType === 'farmer' ? 'f' : 'u'}_${now}`,
      username: trimmedName,
      password,
      userType,
      nickname: trimmedName,
      avatar: userType === 'farmer' ? 'avatar_farmer_1' : 'avatar_default',
      status: 'active',
      createdAt: now,
      lastLoginAt: now
    };
    users.push(newRecord);
    this.usersCache = users;
    await this.saveUsers();

    const token: string = this.generateToken(newRecord.userId, userType);
    const userInfo: UserInfo = this.toUserInfo(newRecord);
    Logger.info(AppConstants.SCENE_COMMON, { action: 'mock_register_success', userId: newRecord.userId, userType });
    return {
      code: AppConstants.CODE_SUCCESS,
      msg: '注册成功',
      data: { token, userInfo }
    } as ApiResponse<AuthResponseData>;
  }

  /**
   * 登录（用户端 / 卖家端共用）
   * @param username 账号
   * @param password 密码
   * @param userType 'user' | 'farmer'
   */
  async login(username: string, password: string, userType: 'user' | 'farmer'): Promise<ApiResponse<AuthResponseData>> {
    await this.delay();

    const trimmedName: string = username.trim();
    const users: MockUserRecord[] = await this.loadUsers();
    const matched: MockUserRecord | undefined = users.find((u: MockUserRecord) =>
      u.username === trimmedName && u.userType === userType);

    if (!matched) {
      return { code: 404, msg: '账号不存在，请先注册', data: null } as ApiResponse<AuthResponseData>;
    }
    if (matched.password !== password) {
      return { code: 401, msg: '密码错误', data: null } as ApiResponse<AuthResponseData>;
    }
    if (matched.status === 'banned') {
      return { code: 403, msg: '账号已被禁用', data: null } as ApiResponse<AuthResponseData>;
    }

    matched.lastLoginAt = Date.now();
    this.usersCache = users;
    await this.saveUsers();

    const token: string = this.generateToken(matched.userId, userType);
    const userInfo: UserInfo = this.toUserInfo(matched);
    Logger.info(AppConstants.SCENE_COMMON, { action: 'mock_login_success', userId: matched.userId, userType });
    return {
      code: AppConstants.CODE_SUCCESS,
      msg: '登录成功',
      data: { token, userInfo }
    } as ApiResponse<AuthResponseData>;
  }

  /**
   * 管理员登录
   * @param username 用户名
   * @param password 密码
   * @param role 选中的角色（仅用于校验，实际权限由账号本身决定）
   */
  async loginAdmin(username: string, password: string, _role: string): Promise<ApiResponse<AdminAuthResponseData>> {
    await this.delay();

    const trimmedName: string = username.trim();
    const admins: MockAdminRecord[] = await this.loadAdmins();
    const matched: MockAdminRecord | undefined = admins.find((a: MockAdminRecord) =>
      a.username === trimmedName);

    if (!matched) {
      return { code: 404, msg: '管理员账号不存在', data: null } as ApiResponse<AdminAuthResponseData>;
    }
    if (matched.password !== password) {
      return { code: 401, msg: '密码错误', data: null } as ApiResponse<AdminAuthResponseData>;
    }

    matched.lastLoginAt = Date.now();
    this.adminsCache = admins;
    await this.saveAdmins();

    const token: string = this.generateToken(matched.adminId, 'admin');
    const adminInfo: AdminInfo = this.toAdminInfo(matched);
    Logger.info(AppConstants.SCENE_COMMON, { action: 'mock_admin_login_success', adminId: matched.adminId });
    return {
      code: AppConstants.CODE_SUCCESS,
      msg: '登录成功',
      data: { token, adminInfo }
    } as ApiResponse<AdminAuthResponseData>;
  }

  /**
   * 管理员注册
   * @param username 用户名
   * @param password 密码
   * @param role 选中的角色
   */
  async registerAdmin(username: string, password: string, role: string): Promise<ApiResponse<AdminAuthResponseData>> {
    await this.delay();

    const trimmedName: string = username.trim();
    if (trimmedName.length < 4) {
      return { code: 400, msg: '用户名至少 4 个字符', data: null } as ApiResponse<AdminAuthResponseData>;
    }
    if (password.length < 6) {
      return { code: 400, msg: '密码至少 6 个字符', data: null } as ApiResponse<AdminAuthResponseData>;
    }

    const admins: MockAdminRecord[] = await this.loadAdmins();
    const exists: boolean = admins.some((a: MockAdminRecord) => a.username === trimmedName);
    if (exists) {
      return { code: 409, msg: '该用户名已被注册', data: null } as ApiResponse<AdminAuthResponseData>;
    }

    const now: number = Date.now();
    const newRecord: MockAdminRecord = {
      adminId: `admin_${now}`,
      username: trimmedName,
      password,
      role: role as AdminRoleType,
      nickname: trimmedName,
      lastLoginAt: now
    };
    admins.push(newRecord);
    this.adminsCache = admins;
    await this.saveAdmins();

    const token: string = this.generateToken(newRecord.adminId, 'admin');
    const adminInfo: AdminInfo = this.toAdminInfo(newRecord);
    Logger.info(AppConstants.SCENE_COMMON, { action: 'mock_admin_register_success', adminId: newRecord.adminId });
    return {
      code: AppConstants.CODE_SUCCESS,
      msg: '注册成功',
      data: { token, adminInfo }
    } as ApiResponse<AdminAuthResponseData>;
  }

  /** 模拟网络延迟（300-600ms） */
  private async delay(): Promise<void> {
    return new Promise<void>((resolve: () => void) => {
      const ms: number = 300 + Math.floor(Math.random() * 300);
      setTimeout(resolve, ms);
    });
  }
}

/** 全局 Mock 鉴权单例 */
export const MockAuthUtil: MockAuthUtilImpl = new MockAuthUtilImpl();
