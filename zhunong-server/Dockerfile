FROM python:3.11-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# 创建 SQLite 数据库目录和 uploads 目录
RUN mkdir -p /app/app/static/uploads

# 初始化数据库并灌入种子数据
RUN python -c "from app import create_app; app = create_app(); print('DB tables created')"

EXPOSE 5000

CMD ["python", "run.py"]
