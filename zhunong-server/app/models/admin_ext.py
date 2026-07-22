import uuid
import time
from app.extensions import db


class ApiInfo(db.Model):
    __tablename__ = 'api_infos'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    path = db.Column(db.String(255), nullable=False)
    method = db.Column(db.String(16), nullable=False)  # GET/POST/PUT/DELETE
    description = db.Column(db.String(255))
    today_request_count = db.Column(db.Integer, default=0)
    error_rate = db.Column(db.Float, default=0.0)
    avg_response_time = db.Column(db.Float, default=0.0)


class ApiKey(db.Model):
    __tablename__ = 'api_keys'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    app_key = db.Column(db.String(64), nullable=False)
    app_secret = db.Column(db.String(128), nullable=False)
    status = db.Column(db.String(16), default='active')  # active/revoked
    created_at = db.Column(db.BigInteger, default=lambda: int(time.time() * 1000))


class RateLimitConfig(db.Model):
    __tablename__ = 'rate_limit_configs'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    api_id = db.Column(db.String(36), db.ForeignKey('api_infos.id'), nullable=False)
    qps_limit = db.Column(db.Integer, default=100)
