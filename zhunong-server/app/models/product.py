import uuid
import time
from app.extensions import db


class Category(db.Model):
    __tablename__ = 'categories'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    parent_id = db.Column(db.String(36), db.ForeignKey('categories.id'))
    name = db.Column(db.String(64), nullable=False)
    level = db.Column(db.Integer, default=1)  # 1/2/3
    icon = db.Column(db.String(512))
    sort_order = db.Column(db.Integer, default=0)


class Product(db.Model):
    __tablename__ = 'products'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    farmer_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    title = db.Column(db.String(128), nullable=False)
    category_id = db.Column(db.String(36), db.ForeignKey('categories.id'))
    main_images = db.Column(db.JSON)
    ai_poster_url = db.Column(db.String(512))
    description = db.Column(db.Text)
    price = db.Column(db.Numeric(10, 2), nullable=False)
    stock = db.Column(db.Integer, default=0)
    ship_from = db.Column(db.String(128))
    freight_template = db.Column(db.String(64))
    monthly_sales = db.Column(db.Integer, default=0)
    monthly_gmv = db.Column(db.Numeric(12, 2), default=0)
    total_sales = db.Column(db.Integer, default=0)
    status = db.Column(db.String(32), default='draft')  # draft/pending_review/approved/rejected/off_shelf
    reject_reason = db.Column(db.String(255))
    created_at = db.Column(db.BigInteger, default=lambda: int(time.time() * 1000))
    updated_at = db.Column(db.BigInteger, default=lambda: int(time.time() * 1000))


class ProductSku(db.Model):
    __tablename__ = 'product_skus'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    product_id = db.Column(db.String(36), db.ForeignKey('products.id'), nullable=False)
    specs = db.Column(db.JSON)
    price = db.Column(db.Numeric(10, 2), nullable=False)
    stock = db.Column(db.Integer, default=0)
    sku_code = db.Column(db.String(64))
