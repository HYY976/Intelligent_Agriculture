import uuid
import time
from app.extensions import db


class Gift(db.Model):
    __tablename__ = 'gifts'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = db.Column(db.String(64), nullable=False)
    icon = db.Column(db.String(512))
    price = db.Column(db.Numeric(10, 2), nullable=False)
    animation = db.Column(db.String(512))


class GiftRecord(db.Model):
    __tablename__ = 'gift_records'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    live_id = db.Column(db.String(36), db.ForeignKey('lives.id'), nullable=False)
    sender_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    receiver_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    gift_id = db.Column(db.String(36), db.ForeignKey('gifts.id'), nullable=False)
    count = db.Column(db.Integer, nullable=False, default=1)
    total_amount = db.Column(db.Numeric(12, 2), nullable=False)
    created_at = db.Column(db.BigInteger, default=lambda: int(time.time() * 1000))
