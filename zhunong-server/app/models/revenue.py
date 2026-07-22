import uuid
import time
from app.extensions import db


class RevenueRecord(db.Model):
    __tablename__ = 'revenue_records'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    farmer_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    order_id = db.Column(db.String(36), db.ForeignKey('orders.id'))
    sub_order_id = db.Column(db.String(36), db.ForeignKey('sub_orders.id'))
    amount = db.Column(db.Numeric(12, 2), nullable=False)
    type = db.Column(db.String(16), nullable=False)  # order/gift
    status = db.Column(db.String(16), default='pending')  # pending/settled/withdrawn
    created_at = db.Column(db.BigInteger, default=lambda: int(time.time() * 1000))
    settled_at = db.Column(db.BigInteger)


class Withdrawal(db.Model):
    __tablename__ = 'withdrawals'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    farmer_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    amount = db.Column(db.Numeric(12, 2), nullable=False)
    account = db.Column(db.String(128))
    status = db.Column(db.String(16), default='completed')  # completed
    created_at = db.Column(db.BigInteger, default=lambda: int(time.time() * 1000))


class DailyRevenue(db.Model):
    __tablename__ = 'daily_revenues'
    date = db.Column(db.String(10), primary_key=True)  # YYYY-MM-DD
    farmer_id = db.Column(db.String(36), db.ForeignKey('users.id'), primary_key=True)
    order_count = db.Column(db.Integer, default=0)
    revenue = db.Column(db.Numeric(12, 2), default=0)
    refund_amount = db.Column(db.Numeric(12, 2), default=0)
