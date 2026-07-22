import uuid
import time
from app.extensions import db


class UserBrowsingHistory(db.Model):
    __tablename__ = 'user_browsing_histories'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    buyer_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    product_id = db.Column(db.String(36), db.ForeignKey('products.id'), nullable=False)
    browsed_at = db.Column(db.BigInteger, default=lambda: int(time.time() * 1000))


class UserFavorite(db.Model):
    __tablename__ = 'user_favorites'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    buyer_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    product_id = db.Column(db.String(36), db.ForeignKey('products.id'), nullable=False)
    created_at = db.Column(db.BigInteger, default=lambda: int(time.time() * 1000))


class UserAddress(db.Model):
    __tablename__ = 'user_addresses'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    buyer_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    receiver_name = db.Column(db.String(64), nullable=False)
    phone = db.Column(db.String(20), nullable=False)
    province = db.Column(db.String(64))
    city = db.Column(db.String(64))
    district = db.Column(db.String(64))
    detail = db.Column(db.String(255))
    is_default = db.Column(db.Boolean, default=False)
