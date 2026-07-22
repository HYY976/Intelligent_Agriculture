import uuid
import time
from app.extensions import db


class CartItem(db.Model):
    __tablename__ = 'cart_items'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    buyer_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    farmer_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    product_id = db.Column(db.String(36), db.ForeignKey('products.id'), nullable=False)
    sku_id = db.Column(db.String(36), db.ForeignKey('product_skus.id'))
    title = db.Column(db.String(128), nullable=False)
    image = db.Column(db.String(512))
    price = db.Column(db.Numeric(10, 2), nullable=False)
    specs = db.Column(db.JSON)
    quantity = db.Column(db.Integer, nullable=False, default=1)
    is_selected = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.BigInteger, default=lambda: int(time.time() * 1000))
