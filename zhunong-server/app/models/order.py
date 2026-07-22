import uuid
import time
from app.extensions import db


class Order(db.Model):
    __tablename__ = 'orders'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    buyer_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    total_amount = db.Column(db.Numeric(12, 2), nullable=False)
    status = db.Column(db.String(32), default='pending_payment')  # 8 状态枚举
    coupon_id = db.Column(db.String(36), db.ForeignKey('coupons.id'))
    created_at = db.Column(db.BigInteger, default=lambda: int(time.time() * 1000))
    paid_at = db.Column(db.BigInteger)


class SubOrder(db.Model):
    __tablename__ = 'sub_orders'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    order_id = db.Column(db.String(36), db.ForeignKey('orders.id'), nullable=False)
    farmer_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    subtotal = db.Column(db.Numeric(12, 2), nullable=False)
    freight = db.Column(db.Numeric(10, 2), default=0)
    status = db.Column(db.String(32), default='pending_payment')
    address_id = db.Column(db.String(36), db.ForeignKey('user_addresses.id'))
    settled_at = db.Column(db.BigInteger)


class OrderItem(db.Model):
    __tablename__ = 'order_items'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    sub_order_id = db.Column(db.String(36), db.ForeignKey('sub_orders.id'), nullable=False)
    product_id = db.Column(db.String(36), db.ForeignKey('products.id'), nullable=False)
    sku_id = db.Column(db.String(36), db.ForeignKey('product_skus.id'))
    title = db.Column(db.String(128), nullable=False)
    image = db.Column(db.String(512))
    specs = db.Column(db.JSON)
    price = db.Column(db.Numeric(10, 2), nullable=False)
    quantity = db.Column(db.Integer, nullable=False, default=1)


class Review(db.Model):
    __tablename__ = 'reviews'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    order_id = db.Column(db.String(36), db.ForeignKey('orders.id'), nullable=False)
    product_id = db.Column(db.String(36), db.ForeignKey('products.id'), nullable=False)
    buyer_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    rating = db.Column(db.Integer, nullable=False)  # 1-5
    content = db.Column(db.Text)
    images = db.Column(db.JSON)
    farmer_reply = db.Column(db.Text)
    created_at = db.Column(db.BigInteger, default=lambda: int(time.time() * 1000))
