# 智农 — 智慧农业综合服务智能体

> **HarmonyOS NEXT 原生应用** · 三端架构（用户端 / 农户端 / 管理后台端）+ 共享库
>
> **bundleName**: `com.zhunong.platform` · **版本**: 1.0.0 · **HarmonyOS SDK**: 6.1.1(24)

---

## 一、项目简介

**智农**（全称：智慧农业综合服务智能体）是一款基于 HarmonyOS NEXT 的农业综合服务平台，采用 **三端 Entry + common 共享 HAR 库** 的工程架构，覆盖农产品上行、助农直播、社区互动、文旅地图、智能体助手等核心场景。

| 端 | bundleName | 定位 |
|----|-----------|------|
| 用户端 (user) | `com.zhunong.user` | C 端消费者：商品购买 / 助农直播 / 社区 / 文旅地图 |
| 农户端 (farmer) | `com.zhunong.farmer` | 卖家农户：商品上架 / 直播开播 / 营收管理 / 智农 AI 助手 |
| 管理后台 (admin) | `com.zhunong.admin` | 运营管理：用户管理 / API 管理 / 内容审核 / 4 角色 RBAC |
| 共享库 (common) | — | HAR 库：公共组件 / 工具 / 模型 / 路由 / 跨端同步存储 |

---

## 二、技术栈

### 前端（鸿蒙原生）

- **HarmonyOS NEXT** (API 24, SDK 6.1.1)
- **ArkTS** + **ArkUI** 声明式 UI（`@ComponentV2` / `@ObservedV2` / `@Local` / `@Param`）
- **状态管理**：`AppStorageV2` + `@ObservedV2` 单例（`SharedProductStore` / `SharedLiveStore` / `SharedPostStore`）
- **列表渲染**：`LazyForEach` + `BaseDataSource<T>` 4 态状态机（loading / error / empty / data）
- **路由导航**：`NavPathStack` 声明式路由（`NavigationHelper` + `RouteName` 常量表）

### 后端

- **Flask**（Python Web 框架，REST API）
- **MySQL**（业务数据存储）
- **ChromaDB**（向量检索，用于 AI 智能体语义匹配）
- **Nginx**（反向代理 + 静态资源）
- **JWT** 认证（7 天有效期，存储于 Preferences）

### AI 能力

- **阿里云百炼（Bailian）** 智能体应用调用
  - 智农 AI 助手对话（农户端）
  - 直播开播介绍 AI 优化（农户端）
  - AI 海报生成（农户端商品发布）

### 地图

- **腾讯地图 JS API**（WebView 嵌入，文旅地图页）
- **百度地图 HarmonyOS SDK**（可选，通过 `ConfigUtil.setUseRealBaiduMap(true)` 开启）

---

## 三、工程结构

```
zhunong/
├── AppScope/                     # 应用级配置
│   ├── app.json5                 # bundleName / 版本 / 图标
│   └── resources/base/element/string.json   # app_name = "智农"
│
├── common/                       # 【HAR 共享库】三端公共能力
│   ├── Index.ets                 # 统一导出入口
│   └── src/main/ets/
│       ├── components/           # 15 个通用组件（QnTopBar/QnCard/QnButton...）
│       ├── constants/            # AppConstants 全局常量
│       ├── model/                # CommonModels 数据模型
│       ├── repository/           # BaseRepository + 3 个跨端共享存储
│       ├── router/               # AppRouter 路由表 + RouteName
│       ├── store/                # ModeStore/ThemeStore/TokenStore
│       ├── utils/                # Logger/HttpUtil/ConfigUtil/ToastUtil...
│       └── viewmodel/            # BaseDataSource<T> 列表数据源基类
│
├── user/                         # 【Entry】用户端
│   └── src/main/ets/pages/
│       ├── home/                 # 首页（莫兰迪色快捷入口 + 为你推荐瀑布流）
│       ├── mall/                 # 商城（分类/列表/详情/下单/评价/订单）
│       ├── live/                 # 直播（列表 + 直播间）
│       ├── community/            # 社区（帖子列表/详情/发布）
│       ├── travel/               # 文旅（腾讯地图 + POI + 路线 + 预订）
│       ├── search/               # 搜索（历史/热词/4 Tab 榜单/结果）
│       ├── cart/                 # 购物车
│       ├── message/              # 消息（会话列表 + 聊天详情）
│       ├── profile/              # 个人中心（设置/地址/收藏/关注/钱包/优惠券）
│       ├── login/                # 登录 / 注册
│       ├── splash/               # 开屏广告
│       └── root/                 # 根页面（底部 Tab 导航）
│
├── farmer/                       # 【Entry】农户端
│   └── src/main/ets/pages/
│       ├── home/                 # 首页 + 营收详情
│       ├── mall/                 # 商城管理（发布/编辑/详情/卖家店铺）
│       ├── live/                 # 直播（浏览/创建/直播间+视频播放）
│       ├── community/            # 社区（帖子管理）
│       ├── market/               # 行情报价
│       ├── agent/                # 智农 AI 助手对话页
│       ├── message/              # 消息
│       ├── profile/              # 卖家中心（认证/粉丝/直播管理/商品管理/营收统计/提现）
│       ├── search/               # 搜索
│       ├── login/                # 登录 / 注册
│       ├── splash/               # 开屏广告
│       └── root/                 # 根页面（底部 Tab 导航）
│
├── admin/                        # 【Entry】管理后台
│   └── src/main/ets/pages/
│       ├── home/                 # 管理首页（4 角色 RBAC 仪表盘）
│       ├── user_manage/          # 用户管理（列表/详情）
│       ├── api_manage/           # API 管理（列表/详情/Key/限流）
│       ├── content_review/       # 内容审核（列表/详情）
│       ├── ads_manage/           # 广告管理
│       ├── login/                # 登录 / 注册
│       └── root/                 # 根页面
│
├── build-profile.json5           # 工程构建配置（4 模块 + 签名 + 产物）
├── oh-package.json5              # 工程级依赖
├── hvigorfile.ts                 # 构建脚本
└── spec.md                       # 迭代规格说明书（开发唯一依据）
```

---

## 四、核心特性

### 4.1 三端跨端数据同步

通过 `common` 模块的 **Preferences 持久化共享存储**，实现农户端发布内容实时同步到用户端：

| 共享存储 | 持久化 Key | 同步方向 | 说明 |
|---------|-----------|---------|------|
| `SharedProductStore` | `shared_products` | farmer → user | 商品发布 / 上下架状态同步 |
| `SharedLiveStore` | `shared_lives` | farmer → user | 直播开播 / 结束状态同步 |
| `SharedPostStore` | `shared_posts` | farmer → user | 社区帖子发布同步 |

### 4.2 列表 4 态状态机

所有列表页统一采用 `BaseDataSource<T>` + 4 态 UI：

```
loading → [error | empty | data]
```

- **LoadingView**：`LoadingProgress` 48px
- **ErrorView**：⚠️ 64px + 刷新按钮
- **EmptyView**：空状态图 + 引导文案 + 行动按钮
- **DataView**：`LazyForEach` + `keyGenerator` + `.cachedCount(5)`

### 4.3 智农 AI 助手

农户端内置 **阿里云百炼智能体** 驱动的 AI 助手：

- 自然语言对话交互（流式响应）
- 农业知识问答 / 种养殖建议
- 直播开播介绍文案 AI 优化
- AI 海报生成（商品发布时）

### 4.4 文旅地图

用户端文旅页采用 **WebView 嵌入腾讯地图 JS API**：

- `javaScriptProxy` 实现 ArkTS ↔ JS 双向通信
- POI Marker 动态注入与点击回调
- 推荐路线 / 热门景点瀑布流 / 预订入口
- 底部面板支持拖拽调节高度（`PanGesture`）

### 4.5 莫兰迪色系

首页快捷入口采用经典莫兰迪灰调配色：

| 入口 | 色值 |
|------|------|
| 分类（灰绿） | `#A8B5A0` |
| 直播（灰粉） | `#D4A5A5` |
| 商城（灰黄） | `#D4C5A0` |
| 旅游（灰蓝） | `#A0B5C5` |

### 4.6 开屏广告自定义

用户端支持在「我的 → 设置」中从相册选择图片作为开屏广告，通过 `ImageReplaceStore` 持久化到 Preferences，下次启动应用生效。

---

## 五、开发环境

### 5.1 必备工具

| 工具 | 版本要求 | 说明 |
|------|---------|------|
| DevEco Studio | 6.1+ | HarmonyOS 官方 IDE |
| HarmonyOS SDK | 6.1.1(24) | API 24 |
| hvigorw | 内置 | 构建工具 |
| Java JDK | 17+ | HAP 打包需要（`PackageHap` 阶段） |

### 5.2 后端服务（Docker）

项目配套后端通过 Docker Compose 部署：

| 容器 | 端口 | 说明 |
|------|------|------|
| zhunong-backend | 5000 | Flask API 服务 |
| zhunong-db | 3306 | MySQL 数据库 |
| zhunong-chromadb | 8000 | ChromaDB 向量检索 |
| zhunong-nginx | 80 | Nginx 反向代理 |

```bash
# 启动后端
docker compose up -d
```

### 5.3 配置说明

后端地址在 [ConfigUtil.ets](common/src/main/ets/utils/ConfigUtil.ets) 中配置：

```typescript
// 开发环境（默认）
devConfig.baseUrl = 'http://192.168.1.100:5000/api'
// 生产环境
prodConfig.baseUrl = 'https://api.zhunong.example.com/api'
```

> **注意**：HarmonyOS 模拟器无法识别 `10.0.2.2`，请使用主机 WLAN IP。开发环境下 `BaseRepository.fetchWithFallback` 会在后端不可达时直接返回 Mock 数据，避免 15 秒超时等待。

---

## 六、构建与运行

### 6.1 命令行构建

```bash
# 设置 SDK 环境
export DEVECO_SDK_HOME="/path/to/DevEco Studio/sdk"

# 编译所有模块
hvigorw assembleHap --mode module -p product=default -p buildMode=debug --no-daemon

# 仅编译指定模块（如 user）
hvigorw assembleHap --mode module -p product=default -p module=user -p buildMode=debug
```

### 6.2 DevEco Studio

1. 打开 DevEco Studio → File → Open → 选择 `zhunong` 目录
2. 等待 Sync 完成
3. 选择运行模块（user / farmer / admin）和设备/模拟器
4. 点击 Run ▶

### 6.3 部署到设备

```bash
# 先卸载旧版本（避免签名冲突）
hdc uninstall com.zhunong.user

# 安装新 HAP
hdc install entry-default-signed.hap
```

> **签名要求**：HAP 必须使用已配置的签名 Profile 签名后才能安装到设备/模拟器，未签名 HAP 安装会失败。

---

## 七、开发规范

### 7.1 ArkTS 严格模式

- ✅ 所有模块导入使用正确相对路径（`../../model/FarmerModels`）
- ✅ 禁止对象字面量作为类型声明，必须使用显式 `interface`
- ✅ `@ComponentV2` 中 `ForEach` itemGenerator 禁止 `if/else`，使用 `.visibility()` 三元表达式
- ✅ `LogInfo` 对象只能包含接口定义的字段
- ✅ 自定义弹窗统一使用方案 C（`@ComponentV2` + `Stack` + `@Local show` + `@Builder`）
- ❌ 禁止 `@CustomDialog` + `@Component` V1 模式（v2.8 起 V1 例外清单已清零）

### 7.2 模块规范

- HAR 模块 `module.json5` 中 `type` 必须为 `har`，`hvigorfile.ts` 使用 `harTasks`
- HAR 模块 `module.json5` 不得包含 `deliveryWithInstall` 或 `pages` 字段
- HAP 模块 `type` 为 `entry`/`feature`，使用 `hapTasks`
- `entry` 模块已废弃，项目模块为 `user` / `farmer` / `admin` / `common`

### 7.3 列表性能

- 列表组件统一使用 `LazyForEach` + `keyGenerator` + `.cachedCount(AppConstants.LIST_CACHED_COUNT)`
- `DataSource` 修改数据后调用 `dataSource.refresh()` 而非直接修改本地状态
- `ForEach` 的 `key` 必须包含会变化的字段（如购物车勾选状态需包含 `selectedCount`）

### 7.4 资源命名

- AppScope 资源文件名全局唯一，不同扩展名不可同名（`background.png` 与 `background.svg` 冲突）
- 颜色资源统一定义在各模块 `resources/base/element/color.json`

---

## 八、关键文件索引

| 文件 | 说明 |
|------|------|
| [spec.md](spec.md) | 迭代规格说明书（开发唯一依据） |
| [AppScope/app.json5](AppScope/app.json5) | 应用级配置 |
| [build-profile.json5](build-profile.json5) | 工程构建配置 |
| [common/Index.ets](common/Index.ets) | HAR 库统一导出 |
| [common/.../AppConstants.ets](common/src/main/ets/constants/AppConstants.ets) | 全局常量 |
| [common/.../ConfigUtil.ets](common/src/main/ets/utils/ConfigUtil.ets) | 环境配置 + 百炼 AI 配置 |
| [common/.../NavigationHelper.ets](common/src/main/ets/utils/NavigationHelper.ets) | 声明式路由工具 |
| [common/.../BaseDataSource.ets](common/src/main/ets/viewmodel/BaseDataSource.ets) | 列表数据源基类 |
| [common/.../SharedProductStore.ets](common/src/main/ets/repository/SharedProductStore.ets) | 跨端商品共享存储 |
| [common/.../SharedLiveStore.ets](common/src/main/ets/repository/SharedLiveStore.ets) | 跨端直播共享存储 |
| [common/.../SharedPostStore.ets](common/src/main/ets/repository/SharedPostStore.ets) | 跨端帖子共享存储 |

---

## 九、版本历史

| 版本 | 日期 | 主要内容 |
|------|------|---------|
| 1.0.0 | 2026-07 | 三端架构搭建 + 核心功能开发 + 智农 AI 助手 + 文旅地图 + 莫兰迪色系 |

---

## 十、License

Apache-2.0

---

> **开发依据**：本项目以 [spec.md](spec.md) 为唯一开发依据，禁止擅自增删改需求。所有迭代需先更新 spec.md 再进行开发。
