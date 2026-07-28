# 趣农助农平台 - 用户端迭代规格说明书 v3.0

> **版本**: v3.0 | **日期**: 2026-07-28 | **范围**: 用户端模块排版同步 + 莫兰迪色系 + 首页推荐重构 + 旅游页面完善
> **开发依据**: 本文档为唯一开发依据，禁止擅自增删改需求

---

## 一、需求总览

### 1.1 本次迭代目标

| 编号 | 需求 | 模块 | 优先级 |
|------|------|------|--------|
| R1 | 商品/直播/社区模块排版同步农户端 | user: community / live / home | P0 |
| R2 | 商品/直播/社区内容实时同步 | common + farmer + user | P0 |
| R3 | 首页快捷入口按钮换莫兰迪色系 | user: home | P0 |
| R4 | 首页"为你推荐"排版对齐农户端 + 商品内容同步 | user: home | P0 |
| R5 | 旅游页面做全：接入腾讯地图 + 演示内容 | user: travel | P0 |

### 1.2 约束

- 莫兰迪色系：经典灰粉系（分类=灰绿 `#A8B5A0`，直播=灰粉 `#D4A5A5`，助农=灰黄 `#D4C5A0`，旅游=灰蓝 `#A0B5C5`）
- 腾讯地图接入方式：WebView 嵌入腾讯地图 JS API（无需原生 SDK）
- 旅游演示内容：地图+POI标注、推荐路线列表、热门景点瀑布流、预订/预约入口
- 实时同步范围：农户发布的商品、农户创建的直播、社区帖子内容、商品上下架状态
- 数据同步技术方案：通过 common 模块 Preferences 持久化共享存储（同 SharedProductStore 模式）

---

## 二、R1 + R2：模块排版同步 + 内容实时同步

### 2.1 社区模块（community）

#### 2.1.1 排版同步（user 对齐 farmer）

**现状对比**：
- farmer 端 `community_list.ets`：List 列表视图，帖子卡片含作者信息行（头像+昵称+V标+时间）+ 标题 + 正文 + 3图网格 + 互动栏（点赞/评论/收藏/删除）
- user 端 `community_list.ets`：WaterFlow 双列瀑布流，NoteCard 含封面图 + 标题 + 作者头像 + 点赞数

**目标排版**（对齐 farmer 端）：
- 顶部栏：标题"社区" + 搜索图标按钮（保持不变）
- 话题 Tab 栏：横向滚动胶囊（推荐/关注/附近/助农日记），选中黑底白字
- 排序栏：最新/最热 + 帖子总数
- 帖子列表：**List 单列**（替代 WaterFlow 双列），卡片结构对齐 farmer 端：
  - 作者信息行：头像(32px) + 昵称(13px) + 卖家V标(14px 黑底白字) + 时间(11px)
  - 帖子标题：15px Medium，最多2行
  - 帖子内容：13px，最多3行
  - 图片网格：Grid 3列，每张80px高，最多展示3张（超3张显示+N）
  - 互动栏：👍点赞数 + 💬评论数 + ⭐收藏数 + 🔗分享
- 空状态：ListStateView emoji 模式

**文件变更**：
- `user/src/main/ets/pages/community/community_list.ets` — 重构 CommunityContent 和 NoteCard

#### 2.1.2 内容实时同步

**SharedPostStore（新建）**：
- 位置：`common/src/main/ets/repository/SharedPostStore.ets`
- 持久化 key：`shared_posts`
- 接口设计（同 SharedProductStore 模式）：
  ```
  interface SharedPost {
    postId: string;
    authorId: string;
    authorType: 'user' | 'farmer';
    authorNickname: string;
    authorAvatar: string;
    topicId: string;
    title: string;
    content: string;
    images: string[];
    likeCount: number;
    commentCount: number;
    favoriteCount: number;
    isSeller: boolean;
    createdAt: number;
  }
  ```
- 方法：`publish(post)`, `getAll()`, `getById(id)`, `remove(id)`, `clear()`

**farmer 端发布同步**：
- `farmer/src/main/ets/repository/CommunityRepository.ets` — `createPost()` 成功后调用 `SharedPostStore.publish()`

**user 端读取合并**：
- `user/src/main/ets/repository/CommunityRepository.ets` — `getPostList()` 中合并 `SharedPostStore.getAll()` 到列表头部
- `user/src/main/ets/mock/CommunityMock.ets` — `getMockPostList()` 合并共享帖子

### 2.2 直播模块（live）

#### 2.2.1 排版同步（user 对齐 farmer）

**现状对比**：
- farmer 端 `live_browse.ets`：List 列表视图，直播卡片含封面图(160px) + 状态标签 + 观看人数 + 标题 + 主播信息 + 进入按钮
- user 端 `live_list.ets`：Swiper 竖向全屏沉浸式，LiveRoomCard 含全屏背景图 + 渐变遮罩 + 顶部主播栏 + 底部内容 + 右侧悬浮操作

**目标排版**（对齐 farmer 端）：
- 顶部导航栏：返回 + 标题"助农直播" + 排序选项（热门/最新）
- 分类筛选条：横向滚动胶囊（全部/生鲜/粮油/肉禽/茶饮/其他），选中黑底白字
- 直播列表：**List 单列**（替代 Swiper），卡片结构对齐 farmer 端：
  - 封面区：160px 高，含状态标签（左上：直播中/预告/已结束）+ 观看人数（左下）
  - 信息区：标题(15px) + 主播信息行(头像emoji+昵称+累计观看) + 进入按钮(全宽胶囊)
- 空状态：引导文案 + 刷新按钮

**文件变更**：
- `user/src/main/ets/pages/live/live_list.ets` — 重构为列表视图

#### 2.2.2 内容实时同步

**SharedLiveStore（新建）**：
- 位置：`common/src/main/ets/repository/SharedLiveStore.ets`
- 持久化 key：`shared_lives`
- 接口设计：
  ```
  interface SharedLive {
    liveId: string;
    title: string;
    coverImage: string;
    farmerName: string;
    farmerAvatar: string;
    status: 'preview' | 'living' | 'ended';
    onlineCount: number;
    totalViewUv: number;
    category: string;
    createdAt: number;
  }
  ```
- 方法：`publish(live)`, `getAll()`, `getById(id)`, `markEnded(id)`, `clear()`

**farmer 端发布同步**：
- `farmer/src/main/ets/repository/LiveManageRepository.ets` — `createLive()` 后调用 `SharedLiveStore.publish()`；`endLive()` 后调用 `SharedLiveStore.markEnded()`

**user 端读取合并**：
- `user/src/main/ets/repository/LiveRepository.ets` — `getLiveList()` 中合并 `SharedLiveStore.getAll()` 到列表头部
- `user/src/main/ets/mock/LiveMock.ets` — 合并共享直播数据

### 2.3 商品模块（home 推荐）

#### 2.3.1 排版同步（user 对齐 farmer）

**详见 R4 章节（首页"为你推荐"重构）**

#### 2.3.2 内容实时同步（含上下架状态）

**现有机制**：`SharedProductStore`（common 模块，Preferences 持久化 key=`shared_products`）

**farmer 端发布同步**（已实现）：
- farmer 端 `product_publish.ets` 发布商品时调用 `SharedProductStore.publish()`
- 商品状态变化（上下架/删除）时调用 `SharedProductStore.publish()` 更新状态或 `SharedProductStore.remove()` 删除

**user 端读取合并**（需实现）：
- `user/src/main/ets/repository/HomeRepository.ets` — `getRecommendList()` 中合并 `SharedProductStore.getAll()` 中 `status === 'approved'` 的商品到列表头部
- 过滤掉 `status !== 'approved'` 的商品（实现上下架状态同步）

---

## 三、R3：首页快捷入口莫兰迪色系

### 3.1 色值定义

| 入口 | 色键 | 莫兰迪色值 | 说明 |
|------|------|-----------|------|
| 分类 | green | `#A8B5A0` | 灰绿 |
| 直播 | red | `#D4A5A5` | 灰粉 |
| 助农 | yellow | `#D4C5A0` | 灰黄 |
| 旅游 | blue | `#A0B5C5` | 灰蓝 |

### 3.2 文件变更

- `user/src/main/resources/base/element/color.json` — 新增 4 个莫兰迪色值
  ```json
  { "name": "color_morandi_green", "value": "#A8B5A0" },
  { "name": "color_morandi_pink", "value": "#D4A5A5" },
  { "name": "color_morandi_yellow", "value": "#D4C5A0" },
  { "name": "color_morandi_blue", "value": "#A0B5C5" }
  ```
- `user/src/main/ets/pages/home/home_page.ets` — `getQuickEntryBgColor()` 方法映射改为莫兰迪色

---

## 四、R4：首页"为你推荐"排版对齐 + 商品同步

### 4.1 排版对齐 farmer 端

**farmer 端"我的商品"排版**（参照对象）：
- 段头：标题"我的商品"(16px Bold) + "查看全部 ›"(12px gray)
- 横向滚动商品卡片：120px 宽卡片（120×120图 + 名称 + 价格 + 月销）

**user 端"为你推荐"目标排版**：
- 段头：标题"为你推荐"(16px Bold) + "查看全部 ›"(12px gray)（替换原"更多好物 ›"）
- **保留双列瀑布流布局**（user 端主内容区，不适合改为横向滚动条）
- 商品卡片样式对齐 farmer 端风格：
  - 主图：1:1 正方形（保持）
  - 商品标题：13px Medium，最多2行（保持）
  - 价格行：¥ 符号(12px) + 整数(20px Bold) 红色（保持）
  - 月销量：10px gray（保持）
  - 卖家信息行：头像(20px) + 昵称(11px)（保持）
  - 产地标签：左上角绿色圆角小标（保持）

**文件变更**：
- `user/src/main/ets/pages/home/home_page.ets` — `ProductSectionHead` 文案改为"查看全部 ›"
- 商品卡片样式基本保持（已与 farmer 端风格一致），重点在内容同步

### 4.2 商品内容同步

**文件变更**：
- `user/src/main/ets/repository/HomeRepository.ets` — `getRecommendList()` 合并 `SharedProductStore` 中 `status === 'approved'` 的商品到列表头部
- `user/src/main/ets/pages/home/home_page.ets` — `onPageShow` / `.onShown()` 中刷新推荐流（确保从商品详情返回后同步）

---

## 五、R5：旅游页面完善

### 5.1 腾讯地图接入（WebView 方式）

**技术方案**：
- 使用 ArkUI `Web` 组件加载腾讯地图 JS API 页面
- 地图 HTML 页面内嵌在 `user/src/main/resources/rawfile/travel_map.html`
- 通过 `Web({ src: $rawfile('travel_map.html'), controller: this.controller })` 加载
- 腾讯地图 JS API Key 使用占位符 `TX_MAP_KEY`（演示用，无实际 Key 时使用开源地图底图或 mock 底图 fallback）
- POI 标注通过 `runJavaScript()` 注入 JS 代码动态添加 Marker

**地图 HTML 页面功能**：
- 加载腾讯地图 JS SDK
- 初始化地图（中心点：杭州，缩放级别 12）
- 暴露 `addMarker(lat, lng, name)` JS 函数供 ArkTS 调用
- 暴露 `clearMarkers()` JS 函数
- Marker 点击事件通过 `WebController.runJavaScript` 回调 ArkTS

**Fallback 策略**：
- 若腾讯地图 JS API 加载失败（无网络/无 Key），显示浅绿渐变底 + 文案"地图加载中..."
- POI 列表仍可正常展示在底部面板

### 5.2 页面结构（旅游页面做全）

**整体布局**（Stack 分层）：
1. **底层**：腾讯地图 WebView（全屏）
2. **顶部浮层**：渐隐遮罩 + 返回按钮 + 搜索栏
3. **分类筛选条**：横向滚动胶囊（全部/农庄/民宿/景点/采摘园/市集）
4. **右侧悬浮按钮**：定位 + 图层切换
5. **底部内容面板**（Scroll 可滚动，白色圆角顶部）：
   - 拖动条
   - 标题栏："附近农庄" + N个结果
   - **推荐路线列表**（新增）：2-3 条主题路线卡片（路线图 + 标题 + 景点数 + 时长 + 价格 + "查看路线"按钮）
   - **横滑 POI 卡片列表**（保持）：240px 宽卡片
   - **热门景点瀑布流**（新增）：双列 WaterFlow，景点图文卡片
   - **预订入口卡片**（新增）：精选体验预订横幅（封面 + 标题 + 价格 + "立即预订"按钮）

### 5.3 演示内容

#### 5.3.1 推荐路线（新增 Mock 数据）

```
路线1：余杭生态采摘一日游
  - 图：farm_picking
  - 景点：山田农庄 → 桃源采摘园 → 阳光生态农庄
  - 时长：1天 | 价格：¥168/人
  - 标签：采摘、亲子、生态

路线2：龙坞茶文化体验游
  - 图：prod_tea_1
  - 景点：金穗民宿 → 茶山人家
  - 时长：2天1夜 | 价格：¥388/人
  - 标签：茶文化、民宿、深度体验

路线3：临安古村落文化游
  - 图：hero_harvest
  - 景点：古城农耕文化村
  - 时长：1天 | 价格：¥128/人
  - 标签：古村、文化、助农
```

#### 5.3.2 热门景点瀑布流（新增 Mock 数据）

复用现有 `MOCK_POIS` 6 个 POI 数据，渲染为双列瀑布流卡片：
- 封面图（可变高度）
- 名称(15px Bold)
- 分类标签(11px 黄色 pill)
- 评分 + 距离 + 价格行

#### 5.3.3 预订入口

复用 `getMockBookingByPoiId('poi001')` 数据，渲染精选体验预订横幅：
- 封面图 + 标题 + 距离 + 标签 + 评分 + 价格 + "立即预订"按钮
- 点击跳转 `RouteName.USER_BOOKING`

### 5.4 文件变更

| 文件 | 变更类型 | 说明 |
|------|---------|------|
| `user/src/main/resources/rawfile/travel_map.html` | 新建 | 腾讯地图 JS API HTML 页面 |
| `user/src/main/ets/pages/travel/travel_map.ets` | 重构 | 替换 Mock 地图为 WebView + 新增路线/瀑布流/预订模块 |
| `user/src/main/ets/mock/TravelMock.ets` | 修改 | 新增 `MOCK_ROUTES` 推荐路线数据 |
| `user/src/main/ets/model/TravelModels.ets` | 修改 | 新增 `TravelRoute` 路线模型 |

### 5.5 TravelRoute 数据模型

```
interface TravelRoute {
  routeId: string;
  title: string;
  coverImage: string;
  poiIds: string[];       // 包含的 POI ID 列表
  poiNames: string[];     // POI 名称列表（冗余，展示用）
  duration: string;       // 时长文案（如"1天"、"2天1夜"）
  price: number;          // 价格（元/人）
  tags: string[];         // 标签（如 采摘/亲子/生态）
  description: string;    // 路线描述
}
```

---

## 六、common 模块共享存储导出

### 6.1 新增文件

| 文件 | 说明 |
|------|------|
| `common/src/main/ets/repository/SharedLiveStore.ets` | 共享直播池（Preferences 持久化） |
| `common/src/main/ets/repository/SharedPostStore.ets` | 共享帖子池（Preferences 持久化） |

### 6.2 Index.ets 导出更新

```typescript
// 共享直播池
export { SharedLiveStore } from './src/main/ets/repository/SharedLiveStore';
export type { SharedLive } from './src/main/ets/repository/SharedLiveStore';
// 共享帖子池
export { SharedPostStore } from './src/main/ets/repository/SharedPostStore';
export type { SharedPost } from './src/main/ets/repository/SharedPostStore';
```

---

## 七、文件变更清单

### 7.1 新建文件（5 个）

| # | 文件路径 | 说明 |
|---|---------|------|
| 1 | `common/src/main/ets/repository/SharedLiveStore.ets` | 共享直播池 |
| 2 | `common/src/main/ets/repository/SharedPostStore.ets` | 共享帖子池 |
| 3 | `user/src/main/resources/rawfile/travel_map.html` | 腾讯地图 HTML |
| 4 | （目录）`user/src/main/resources/rawfile/` | rawfile 资源目录 |

### 7.2 修改文件（12 个）

| # | 文件路径 | 变更内容 |
|---|---------|---------|
| 1 | `common/Index.ets` | 导出 SharedLiveStore + SharedPostStore |
| 2 | `farmer/src/main/ets/repository/LiveManageRepository.ets` | createLive/endLive 同步到 SharedLiveStore |
| 3 | `farmer/src/main/ets/repository/CommunityRepository.ets` | createPost 同步到 SharedPostStore |
| 4 | `user/src/main/ets/repository/LiveRepository.ets` | getLiveList 合并 SharedLiveStore |
| 5 | `user/src/main/ets/repository/CommunityRepository.ets` | getPostList 合并 SharedPostStore |
| 6 | `user/src/main/ets/repository/HomeRepository.ets` | getRecommendList 合并 SharedProductStore |
| 7 | `user/src/main/ets/pages/home/home_page.ets` | 莫兰迪色系 + 推荐段头文案 + onShown 刷新 |
| 8 | `user/src/main/ets/pages/community/community_list.ets` | 瀑布流改列表视图对齐 farmer |
| 9 | `user/src/main/ets/pages/live/live_list.ets` | Swiper 改列表视图对齐 farmer |
| 10 | `user/src/main/ets/pages/travel/travel_map.ets` | 接入腾讯地图 + 路线/瀑布流/预订模块 |
| 11 | `user/src/main/ets/mock/TravelMock.ets` | 新增 MOCK_ROUTES 路线数据 |
| 12 | `user/src/main/ets/model/TravelModels.ets` | 新增 TravelRoute 模型 |
| 13 | `user/src/main/resources/base/element/color.json` | 新增 4 个莫兰迪色值 |

---

## 八、技术规范遵从

- 所有 .ets 文件模块导入使用正确相对路径
- 对象字面量禁止用作类型声明，使用显式 interface
- @ComponentV2 中 ForEach itemGenerator 回调禁止包含 if/else 条件渲染，使用 .visibility() 三元表达式
- List 组件使用 LazyForEach + keyGenerator + .cachedCount(AppConstants.LIST_CACHED_COUNT)
- DataSource 操作修改数据后调用 dataSource.refresh()
- HAR 模块 module.json5 不含 deliveryWithInstall / pages 字段
- 跨 HAP 数据同步通过 PreferencesUtil 持久化（同 SharedProductStore 模式）
