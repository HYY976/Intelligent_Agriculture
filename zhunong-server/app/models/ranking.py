import uuid
import time
from app.extensions import db


class ProductRank(db.Model):
    __tablename__ = 'product_ranks'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    month = db.Column(db.String(7), nullable=False)  # YYYY-MM
    product_id = db.Column(db.String(36), db.ForeignKey('products.id'), nullable=False)
    farmer_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    monthly_gmv = db.Column(db.Numeric(12, 2), default=0)
    rank = db.Column(db.Integer, nullable=False)  # 1-10
    updated_at = db.Column(db.BigInteger, default=lambda: int(time.time() * 1000))


class LiveRank(db.Model):
    __tablename__ = 'live_ranks'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    month = db.Column(db.String(7), nullable=False)
    live_id = db.Column(db.String(36), db.ForeignKey('lives.id'), nullable=False)
    farmer_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    monthly_income = db.Column(db.Numeric(12, 2), default=0)
    rank = db.Column(db.Integer, nullable=False)
    updated_at = db.Column(db.BigInteger, default=lambda: int(time.time() * 1000))


class SplashAd(db.Model):
    __tablename__ = 'splash_ads'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    month = db.Column(db.String(7), nullable=False)
    rank_type = db.Column(db.String(16), nullable=False)  # product/live
    farmer_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    product_id = db.Column(db.String(36), db.ForeignKey('products.id'))
    live_id = db.Column(db.String(36), db.ForeignKey('lives.id'))
    poster_url = db.Column(db.String(512))
    target_url = db.Column(db.String(512))
    rank = db.Column(db.Integer, default=1)
    start_date = db.Column(db.String(10))
    end_date = db.Column(db.String(10))
