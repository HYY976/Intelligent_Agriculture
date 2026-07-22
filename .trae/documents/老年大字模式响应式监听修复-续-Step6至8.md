# 老年大字模式响应式监听修复 — 续（Step 6 收尾 + Step 7 spec 回写 + Step 8 验证）

## 背景

本计划是 [老年大字模式响应式监听修复.md](file:///C:/Users/21132/Project/.trae/documents/老年大字模式响应式监听修复.md)（已获用户批准）的**收尾续作**。原计划 8 步中：
- **Step 1-5 已完成** ✅：common 模块 3 文件（CommonModels.ets 加 @ObservedV2/@Trace + ModeStore.ets/ThemeStore.ets 新增 connectXxxRef()）+ farmer 2 页面（home_page.ets + setting.ets）改造完成
- **Step 6 进行中** 🔄：user/profile/setting.ets 仅完成 import 行（line 7），剩余 6 处编辑未做
- **Step 7-8 待执行** ⏳：spec.md 回写 + 版本升级 + 编译验证

本次会话因上下文重置进入 Plan Mode，需重新建立计划后继续。

## 当前状态核查（Phase 1 实测）

### user/profile/setting.ets（Step 6 待完成）
经 Read 实测，该文件目前状态：
- ✅ line 7：`import type { CurrentModeKey, CurrentThemeKey } from 'common';` 已添加
- ❌ line 18-19：仍为 `@Local currentMode: string = AppConstants.MODE_STANDARD;` + `@Local currentTheme: string = AppConstants.THEME_SYSTEM;`
- ❌ line 21-23：aboutToAppear 仍调用 `await ModeStore.getMode()` + `await ThemeStore.getTheme()`
- ❌ line 27-31：toggleMode 仍用 `this.currentMode`
- ❌ line 65：`this.currentMode === AppConstants.MODE_ELDER`
- ❌ line 70：`this.currentTheme === ...`（两处）
- ❌ line 85-95：字号快捷切换段 6 处 `this.currentMode`

### spec.md（Step 7 待完成）
经 grep 实测，spec.md 当前 v2.9，**无 10.18 节**，以下条款为误报需更正：
- line 274（2.1.3）：`各页面通过 @StorageLink('currentMode') 响应式刷新` — 失实
- line 1999-2000（6.6.1）：`AppStorage.set('currentMode', newMode)` + `@StorageLink('currentMode')` — 失实
- line 3356-3357（10.9.3.3 表）：`@StorageLink... 改 @Consumer` — 误报
- line 3360-3372（10.9.3.3 正文）：`@Consumer('currentMode')` 方案 — 误报（@Consumer 属 V1，与 V2 路线冲突）
- line 3694（10.10.7 任务5）：`可立即启动验证` — 误报（响应式从未落地，需先修复）

## 待执行步骤

### Step 6（收尾）：user/profile/setting.ets 响应式改造

文件：[user/profile/setting.ets](file:///C:/Users/21132/Project/zhunong/user/src/main/ets/pages/profile/setting.ets)

6 处编辑（与 farmer/profile/setting.ets 同构，参照已完成的 farmer 版本）：

**编辑 1**（line 18-19，@Local 声明）：
- old：`@Local currentMode: string = AppConstants.MODE_STANDARD;` + `@Local currentTheme: string = AppConstants.THEME_SYSTEM;`
- new：`@Local modeRef: CurrentModeKey = ModeStore.connectModeRef();` + `@Local themeRef: CurrentThemeKey = ThemeStore.connectThemeRef();`

**编辑 2**（line 21-24，aboutToAppear）：
- 删除 `this.currentMode = await ModeStore.getMode();` + `this.currentTheme = await ThemeStore.getTheme();`
- 保留空 aboutToAppear（或加注释说明 modeRef 通过 connectModeRef 持有共享实例）

**编辑 3**（line 27-31，toggleMode）：
- `const prev: string = this.currentMode;` → `const prev: string = this.modeRef.value;`
- 删除 `this.currentMode = await ModeStore.toggleMode();`，仅保留 `await ModeStore.toggleMode();`（setMode 已通过共享 ref 同步）
- Logger/Toast 引用 `this.currentMode` → `this.modeRef.value`

**编辑 4**（line 65，字号模式行项）：
- `this.currentMode === AppConstants.MODE_ELDER` → `this.modeRef.value === AppConstants.MODE_ELDER`

**编辑 5**（line 70，深色模式行项，两处）：
- 两处 `this.currentTheme` → `this.themeRef.value`

**编辑 6**（line 85-95，字号快捷切换段，6 处）：
- 6 处 `this.currentMode` → `this.modeRef.value`

验证：grep 确认 `currentMode` / `currentTheme` 在该文件 0 残留（仅 type import 名含 CurrentModeKey/CurrentThemeKey）。

### Step 7：spec.md 回写 + 版本升级

文件：[spec.md](file:///C:/Users/21132/Project/spec.md)

**7.1 版本号升级**
- line 3：`> 文档版本：v2.9` → `> 文档版本：v3.0`
- 版本日志新增 v3.0 条目（2026-07-22）：老年大字模式响应式监听修复——根因 CurrentModeKey/CurrentThemeKey 缺 @ObservedV2/@Trace + 页面一次性读取；修复方案 AppStorageV2.connect + @ObservedV2/@Trace；新增 connectModeRef/connectThemeRef；3 页面改造；spec 10.9.3.3/10.10.7/2.1.3/6.6.1 误报更正；新增 10.18 节

**7.2 误报更正（4 处）**
- line 274（2.1.3）：`@StorageLink('currentMode') 响应式刷新` → `@Local modeRef = ModeStore.connectModeRef() 响应式刷新（AppStorageV2 + @ObservedV2/@Trace，spec 10.18）`
- line 1999-2000（6.6.1）：`AppStorage.set('currentMode', newMode)` + `@StorageLink('currentMode')` → `ModeStore.setMode(newMode) 内部 AppStorageV2.connect 共享 ref 写入 value` + `各页面通过 @Local modeRef = ModeStore.connectModeRef() 响应式刷新`
- line 3356-3357（10.9.3.3 表注）：`@StorageLink... 改 @Consumer` → `@StorageLink... 改 @Local modeRef = ModeStore.connectModeRef()（spec 10.18 更正）`
- line 3360-3372（10.9.3.3 正文）：整段 @Consumer 方案更正为 AppStorageV2.connect + @ObservedV2/@Trace 方案；标注 user home_page/profile_page 代码缺失为独立子任务
- line 3694（10.10.7 任务5）：`可立即启动验证` → 标注为误报，响应式修复已在 v3.0 落地（spec 10.18），现可启动验证

**7.3 新增 spec 10.18 节**（在 10.17 节之后）
结构（7 小节，与 10.16/10.17 体例一致）：
- 10.18.1 问题背景：spec 10.10.7 标注"任务5 可立即启动验证"，代码核查发现响应式从未落地
- 10.18.2 根因定位：CurrentModeKey/CurrentThemeKey 缺 @ObservedV2/@Trace + 页面 @Local 一次性读取 + spec 10.9.3.3 @Consumer 方案误报（V1 语义，与 V2 路线冲突）
- 10.18.3 修复方案：AppStorageV2.connect + @ObservedV2/@Trace 机制说明（经华为官方文档验证）；isElderMode() 调用点 0 改动的封装优势
- 10.18.4 涉及文件清单（6 文件表格）：CommonModels.ets / ModeStore.ets / ThemeStore.ets / farmer home_page.ets / farmer setting.ets / user setting.ets
- 10.18.5 实施记录：Step 1-6 逐步落地记录（common 3 文件 + farmer 2 页面 + user 1 页面）
- 10.18.6 静态/编译验证：⏳ 待用户执行 hvigorw assembleHap 回填
- 10.18.7 遗留问题：user home_page/profile_page 老年大字 UI 适配缺失 / farmer setting onThemeChange 漏调 setTheme / AuthExpiredKey 401 监听未实现 — 均为独立子任务，本次不处理

### Step 8：编译验证

提示用户在 `C:\Users\21132\Project\zhunong` 执行 `hvigorw assembleHap --no-daemon`，预期三端 BUILD SUCCESSFUL 0 ERROR。
收到日志后回填 spec 10.18.6 验证记录。

## 假设与决策

1. **不扩展范围**：user home_page/profile_page 老年大字 UI 适配缺失属新增需求，受"禁止擅自增删改需求"约束，本次仅做响应式监听修复，不新增 UI 适配代码
2. **farmer setting.ets onThemeChange 漏调 setTheme**：本次不修（独立 bug），仅在 spec 10.18.7 记录
3. **isElderMode() 封装保持**：30+ 处调用点 0 改动，仅改 isElderMode() 内部实现读取 modeRef.value
4. **参照 farmer 版本**：user setting.ets 改造与 farmer/profile/setting.ets 同构（已完成），确保两端一致

## 验证步骤

1. Step 6 完成后：grep `currentMode`/`currentTheme` 在 user/profile/setting.ets 0 残留
2. Step 7 完成后：spec.md 版本号 v3.0，10.18 节存在，4 处误报更正
3. Step 8：用户执行 hvigorw，回填 10.18.6
