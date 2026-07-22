import uuid
import time
from app.extensions import db


class Live(db.Model):
    __tablename__ = 'lives'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    farmer_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    title = db.Column(db.String(128), nullable=False)
    cover_image = db.Column(db.String(512))
    category = db.Column(db.String(64))
    intro = db.Column(db.Text)
    product_bag = db.Column(db.JSON)
    status = db.Column(db.String(16), default='preview')  # preview/living/ended
    start_time = db.Column(db.BigInteger)
    end_time = db.Column(db.BigInteger)
    total_view_uv = db.Column(db.Integer, default=0)
    total_gift_income = db.Column(db.Numeric(12, 2), default=0)
    total_order_income = db.Column(db.Numeric(12, 2), default=0)
    monthly_income = db.Column(db.Numeric(12, 2), default=0)
    created_at = db.Column(db.BigInteger, default=lambda: int(time.time() * 1000))
