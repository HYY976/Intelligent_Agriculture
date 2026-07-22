import uuid
import time
from app.extensions import db


class ContentReview(db.Model):
    __tablename__ = 'content_reviews'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    content_type = db.Column(db.String(16), nullable=False)  # product/live/post/report
    content_id = db.Column(db.String(36), nullable=False)
    submitter_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    status = db.Column(db.String(16), default='pending')  # pending/approved/rejected
    reviewer_id = db.Column(db.String(36), db.ForeignKey('admins.id'))
    reject_reason = db.Column(db.String(255))
    reviewed_at = db.Column(db.BigInteger)
    created_at = db.Column(db.BigInteger, default=lambda: int(time.time() * 1000))


class Report(db.Model):
    __tablename__ = 'reports'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    reporter_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    target_type = db.Column(db.String(16), nullable=False)  # post/comment/product/live
    target_id = db.Column(db.String(36), nullable=False)
    reason = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text)
    status = db.Column(db.String(16), default='pending')  # pending/reviewed
    created_at = db.Column(db.BigInteger, default=lambda: int(time.time() * 1000))
