# 多阶段构建：python:3.11-slim → 安装 requirements → gunicorn + eventlet 启动
FROM python:3.11-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# 系统依赖：gcc / default-libmysqlclient-dev / pkg-config 用于 PyMySQL 编译
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    default-libmysqlclient-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 复制整个 zhunong-server 源码（构建上下文为 zhunong-server）
COPY . .

EXPOSE 5000

CMD ["gunicorn", "-w", "4", "-k", "eventlet", "-b", "0.0.0.0:5000", "run:app"]
