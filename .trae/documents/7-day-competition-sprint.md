# 助农平台 7 天比赛冲刺开发计划

## Context

项目需在 7 天内完成比赛演示。前端（HarmonyOS NEXT）已完成 90%（65 页面全部落地，编译通过），后端（Flask）仅完成 15%（14 个 Controller 大部分为 health-check 占位，Services 层为空）。

**关键洞察**：前端 Repository 使用 `BaseRepository.fetchWithFallback` 模式——后端返回 `code===200 && data!==null` 时自动用真实数据，否则回退 Mock。因此**后端只需返回正确 JSON 格式，前端零改动自动切真实数据**。

---

## 架构决策

1. **切换 SQLite**：DevConfig 改为 `sqlite:///zhunong.db`，零配置启动，演示够用
2. **跳过 Service 层**：Controller 直接 `db.session.query` 查询，赛后再提取
3. **种子数据 ID 对齐前端 Mock**：p001-p015, f001-f003, o001-o008 等保持一致
4. **前端唯一改动**：购物车需新建 `CartRepository.ets`（~50行），其余全部零改动

---

## Day 1：基础设施 + 三端登录 (P0)

### 配置改动
- `config.py`：新增 `SQLiteConfig`（`sqlite:///zhunong.db`）
- 验证 `python run.py init-db` 建表成功

### user_controller.py（/api/user）
- `POST /login` — 手机号+验证码登录（任意6位码通过），返回 `{token, userInfo}`
- `POST /sms_code` — 发送验证码 Mock
- `POST /register` — 手机号注册
- `GET /profile` — 获取当前用户信息（需 JWT）
- `PUT /profile` — 更新用户昵称/头像

### admin_controller.py（/api/admin）
- `POST /login` — 用户名+密码登录，返回 `{token, adminInfo}`

### farmer_controller.py（/api/farmer）
- `POST /login` — 卖家手机号+验证码登录
- `POST /sms_code` — 发送验证码 Mock

### 种子数据
- 3 个 Farmer（f001=青禾农庄, f002=山野好物, f003=田园牧歌）
- 5 个 Buyer

---

## Day 2：商品 + 首页 + 分类 (P0)

### home_controller.py（/api/home）
- `GET /recommend` — 首页推荐流（分页，返回 `PageResult<ProductListItem>`）
- `GET /banner` — Banner 列表

### product_controller.py（/api/product）
- `GET /list` — 商品列表（分页+筛选+排序）
- `GET /<id>` — 商品详情（含 SKU）
- `GET /categories` — 三级分类树
- `GET /<id>/reviews` — 商品评价列表

### 种子数据
- 15+ 商品（p001-p015），对齐前端 ProductMock
- 4 一级分类 + 二级 + 三级
- ProductSku 记录

---

## Day 3：购物车 + 订单核心流程 (P0)

### 新增 cart_controller.py（/api/cart）
- `GET /list` — 购物车列表（按卖家分组）
- `POST /add` — 加入购物车
- `PUT /update` — 更新数量/选中状态
- `DELETE /<id>` — 删除购物车项

### order_controller.py（/api/order）
- `POST /create` — 创建订单（按卖家拆子订单）
- `GET /list` — 订单列表（按状态筛选）
- `GET /<id>` — 订单详情
- `POST /<id>/pay` — Mock 支付（状态流转）
- `POST /<id>/confirm` — 确认收货
- `POST /<id>/cancel` — 取消订单
- `POST /<id>/review` — 提交评价
- `GET /count` — 各状态订单数量统计

### 前端改动
- 新建 `user/src/main/ets/repository/CartRepository.ets`（~50行）

### 种子数据
- 8 个订单覆盖 8 种状态
- 3 个收货地址

---

## Day 4：农户端完整流程 (P0)

### farmer_controller.py（/api/farmer）补充
- `GET /profile` — 卖家信息
- `PUT /profile` — 更新店铺信息
- `POST /certification` — 提交资质认证
- `GET /products` — 卖家商品列表
- `PUT /product/status` — 上下架
- `DELETE /product/delete` — 删除商品
- `POST /product/publish` — 发布新商品
- `PUT /product/update` — 编辑商品
- `GET /fans` — 粉丝列表
- `GET /lives` — 直播管理历史
- `POST /live/create` — 开播创建
- `POST /live/end` — 结束直播

### 新增 revenue_controller.py（/api/revenue）
- `GET /summary` — 营收汇总
- `GET /records` — 营收明细列表
- `GET /chart` — 营收图表数据
- `GET /withdrawals` — 提现记录

### 种子数据
- RevenueRecord + DailyRevenue + Withdrawal + Follow 记录

---

## Day 5：管理后台完整流程 (P0)

### admin_controller.py（/api/admin）补充
- `GET /dashboard/stats` — 控制台统计
- `GET /users` — 用户列表（多条件搜索分页）
- `GET /users/<id>` — 用户详情聚合
- `PUT /users/<id>/ban` — 封禁
- `PUT /users/<id>/unban` — 解封
- `PUT /users/<id>/reset-password` — 重置密码
- `GET /reviews` — 审核列表
- `GET /reviews/<id>` — 审核详情
- `PUT /reviews/<id>/approve` — 审核通过
- `PUT /reviews/<id>/reject` — 审核驳回
- `GET /reviews/pending-count` — 待审核数量
- `GET /apis` — API 列表
- `GET /apis/<id>` — API 详情
- `GET /api-keys` / `POST /api-keys` / `PUT /api-keys/<id>/revoke` — 密钥管理

### 种子数据
- ContentReview 记录 15 条（含 pending/approved/rejected）
- ApiInfo + ApiKey + RateLimitConfig

---

## Day 6：社区/直播/消息真实化 + 端到端联调 (P1)

### 升级已有 Controller（从空列表改为 DB 查询）
- community_controller：topics / posts / posts/<id> / POST posts
- live_controller：list / <id> / gifts
- message_controller：sessions / messages / POST messages

### 端到端联调
- 启动后端 `python run.py`
- DevEco Studio 运行前端
- 验证：用户注册→浏览→加购→下单→支付
- 验证：农户登录→发布商品→查看营收
- 验证：管理员登录→审核→用户管理

### 种子数据
- 20+ 帖子 + 50+ 评论
- 5 场直播
- 10 个聊天会话 + 50 条消息
- 5 种礼物配置

---

## Day 7：丰富数据 + 排行榜/广告/AI/上传 + Demo 彩排 (P0+P1)

### rank_controller.py（/api/rank）
- `GET /product` — 商品月度排行
- `GET /live` — 直播月度排行

### ad_controller.py（/api/ad）
- `GET /splash` — 开屏广告

### ai_controller.py（/api/ai）
- `POST /copywrite` — AI 文案生成（Mock 固定模板）
- `POST /poster` — AI 海报生成（Mock 返回商品首图）

### upload_controller.py（/api/upload）
- `POST /image` — 图片上传

### 丰富种子数据
- 商品扩充到 30+，订单 30+，帖子 50+，用户 30+

### Demo 彩排
- 完整走三个角色流程
- 准备演示脚本

---

## 验证方式

1. 每个 Controller 完成后用 `curl` 验证返回格式
2. Day 6 端到端联调：前端连接后端，逐页验证数据展示
3. Day 7 彩排：完整演示三个角色流程，确保零故障

## 关键文件清单

| 文件 | 改动类型 |
|------|----------|
| `zhunong-server/app/config.py` | 新增 SQLiteConfig |
| `zhunong-server/app/controllers/user_controller.py` | 重写（5个端点） |
| `zhunong-server/app/controllers/product_controller.py` | 重写（4个端点） |
| `zhunong-server/app/controllers/order_controller.py` | 重写（8个端点） |
| `zhunong-server/app/controllers/admin_controller.py` | 重写（16个端点） |
| `zhunong-server/app/controllers/farmer_controller.py` | 重写（12个端点） |
| `zhunong-server/app/controllers/home_controller.py` | 重写（2个端点） |
| `zhunong-server/app/controllers/rank_controller.py` | 重写（2个端点） |
| `zhunong-server/app/controllers/ad_controller.py` | 重写（1个端点） |
| `zhunong-server/app/controllers/ai_controller.py` | 重写（2个端点） |
| `zhunong-server/app/controllers/upload_controller.py` | 重写（1个端点） |
| `zhunong-server/app/controllers/cart_controller.py` | 新建（4个端点） |
| `zhunong-server/app/controllers/revenue_controller.py` | 新建（4个端点） |
| `zhunong-server/seed/seed_data.py` | 大幅扩充 |
| `zhunong/user/src/main/ets/repository/CartRepository.ets` | 新建 |
| `zhunong-server/app/controllers/__init__.py` | 注册新 Blueprint |
