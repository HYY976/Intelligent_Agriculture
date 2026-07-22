import uuid
import time
from app.extensions import db


class User(db.Model):
    __tablename__ = 'users'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    phone = db.Column(db.String(20), unique=True, nullable=False)
    nickname = db.Column(db.String(64))
    avatar = db.Column(db.String(512))
    password_hash = db.Column(db.String(255), nullable=False)
    user_type = db.Column(db.String(16), nullable=False, default='user')  # user/farmer
    status = db.Column(db.String(16), nullable=False, default='active')  # active/banned
    ban_reason = db.Column(db.String(255))
    ban_until = db.Column(db.BigInteger)
    created_at = db.Column(db.BigInteger, default=lambda: int(time.time() * 1000))
    last_login_at = db.Column(db.BigInteger)
    last_login_ip = db.Column(db.String(64))


class FarmerProfile(db.Model):
    __tablename__ = 'farmer_profiles'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    shop_name = db.Column(db.String(128))
    shop_logo = db.Column(db.String(512))
    shop_intro = db.Column(db.Text)
    certification_status = db.Column(db.String(32), default='none')  # none/pending/approved/rejected
    real_name = db.Column(db.String(64))
    id_card_no = db.Column(db.String(32))
    id_card_front_img = db.Column(db.String(512))
    id_card_back_img = db.Column(db.String(512))
    farmer_cert_img = db.Column(db.String(512))
    total_revenue = db.Column(db.Numeric(12, 2), default=0)
    available_balance = db.Column(db.Numeric(12, 2), default=0)
    frozen_balance = db.Column(db.Numeric(12, 2), default=0)
    follow_count = db.Column(db.Integer, default=0)
    fans_count = db.Column(db.Integer, default=0)


class CertificationInfo(db.Model):
    __tablename__ = 'certification_infos'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    farmer_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    real_name = db.Column(db.String(64))
    id_card_no = db.Column(db.String(32))
    id_card_front_img = db.Column(db.String(512))
    id_card_back_img = db.Column(db.String(512))
    farmer_cert_img = db.Column(db.String(512))
    status = db.Column(db.String(32), default='pending')  # pending/approved/rejected
    reject_reason = db.Column(db.String(255))
    submitted_at = db.Column(db.BigInteger, default=lambda: int(time.time() * 1000))
    reviewed_at = db.Column(db.BigInteger)


class Admin(db.Model):
    __tablename__ = 'admins'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    username = db.Column(db.String(64), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    role = db.Column(db.String(32), nullable=False)  # super_admin/user_admin/content_reviewer/api_admin
    nickname = db.Column(db.String(64))
    last_login_at = db.Column(db.BigInteger)
    created_at = db.Column(db.BigInteger, default=lambda: int(time.time() * 1000))
