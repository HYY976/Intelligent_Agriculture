import uuid
import time
from app.extensions import db


class Coupon(db.Model):
    __tablename__ = 'coupons'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = db.Column(db.String(64), nullable=False)
    type = db.Column(db.String(16), nullable=False)  # fixed/discount
    value = db.Column(db.Numeric(10, 2), nullable=False)
    min_amount = db.Column(db.Numeric(10, 2), default=0)
    valid_from = db.Column(db.BigInteger)
    valid_to = db.Column(db.BigInteger)
    total_count = db.Column(db.Integer, default=0)
    received_count = db.Column(db.Integer, default=0)


class UserCoupon(db.Model):
    __tablename__ = 'user_coupons'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    coupon_id = db.Column(db.String(36), db.ForeignKey('coupons.id'), nullable=False)
    buyer_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    status = db.Column(db.String(16), default='unused')  # unused/used/expired
    used_order_id = db.Column(db.String(36), db.ForeignKey('orders.id'))
    received_at = db.Column(db.BigInteger, default=lambda: int(time.time() * 1000))
