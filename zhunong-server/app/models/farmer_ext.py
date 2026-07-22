import uuid
import time
from app.extensions import db


class FarmerOperationLog(db.Model):
    __tablename__ = 'farmer_operation_logs'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    farmer_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    operation = db.Column(db.String(64), nullable=False)
    target_id = db.Column(db.String(36))
    detail = db.Column(db.Text)
    created_at = db.Column(db.BigInteger, default=lambda: int(time.time() * 1000))
