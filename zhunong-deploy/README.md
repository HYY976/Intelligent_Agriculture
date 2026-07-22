# 助农三端鸿蒙原生综合平台 - Docker 部署

本目录包含 Flask 后端 + MySQL + ChromaDB + Nginx 的容器化部署配置。
三端鸿蒙原生 APP（user / farmer / admin）独立打包，Flask 后端独立服务，提供 RESTful API + WebSocket，前后端分离。

## 目录结构

```
zhunong-deploy/
├── docker-compose.yml      # 编排：backend + db + chromadb + nginx
├── .env.example            # 环境变量示例
├── README.md               # 本文档
├── backend/
│   └── Dockerfile          # 多阶段构建：python:3.11-slim → gunicorn + eventlet
├── nginx/
│   └── nginx.conf          # 反向代理（/api/ /api/ws /static/）
└── mysql/
    └── init.sql            # 数据库初始化：zhunong 库 + utf8mb4 + 时区
```

## 环境要求

- Docker 20+
- Docker Compose 2+

## 快速启动

```bash
cp .env.example .env
docker-compose up -d --build
```

## 停止服务

```bash
docker-compose down
```

## 查看日志

```bash
docker-compose logs -f backend
```

## 初始化数据库表

首次启动后，创建全部 SQLAlchemy 业务表：

```bash
docker-compose exec backend python run.py init-db
```

## 填充种子数据

写入默认管理员、预置分类树、预设话题及 Mock 商品/直播/榜单数据：

```bash
docker-compose exec backend python run.py seed
```

## 端口说明

| 端口 | 服务      | 说明                         |
|------|-----------|------------------------------|
| 80   | nginx     | 对外入口，反向代理 /api/ /static/ /api/ws |
| 5000 | flask     | 后端 RESTful API + WebSocket |
| 3306 | mysql     | 业务数据库（MySQL 8.0）      |
| 8000 | chromadb  | 向量检索 / 语义推荐          |

## 默认管理员账号

| 用户名              | 密码      | 角色                |
|---------------------|-----------|---------------------|
| super_admin         | admin123  | super_admin         |
| user_admin          | admin123  | user_admin          |
| content_reviewer    | admin123  | content_reviewer    |
| api_admin           | admin123  | api_admin           |
