"""
revenue_controller - 营收 API
  - GET /summary     营收汇总
  - GET /records     营收明细列表
  - GET /chart       营收图表数据
  - GET /withdrawals 提现记录
  - POST /withdraw   申请提现
"""

import time
from flask import Blueprint, jsonify, request, g
from app.extensions import db
from app.models.revenue import RevenueRecord, Withdrawal, DailyRevenue
from app.models.user import FarmerProfile
from app.utils.response import success_response, error_response
from app.utils.decorators import jwt_required

revenue_bp = Blueprint('revenue', __name__, url_prefix='/api/revenue')


@revenue_bp.route('/summary', methods=['GET'])
@jwt_required
def revenue_summary():
    """
    营收汇总
    GET /api/revenue/summary?range=today|month|year|total
    """
    payload = g.current_user
    farmer_id = payload.get('user_id')
    range_type = request.args.get('range', 'today')

    fp = FarmerProfile.query.filter_by(user_id=farmer_id).first()

    # 计算订单数和商品数
    from app.models.product import Product
    from app.models.order import SubOrder
    product_count = Product.query.filter_by(farmer_id=farmer_id, status='approved').count()
    order_count = SubOrder.query.filter_by(farmer_id=farmer_id).count()

    # 营收金额
    if range_type == 'today':
        # 当日营收
        today = time.strftime('%Y-%m-%d')
        dr = DailyRevenue.query.filter_by(farmer_id=farmer_id, date=today).first()
        amount = float(dr.revenue or 0) if dr else 0
        count = dr.order_count if dr else 0
    elif range_type == 'month':
        # 本月营收
        month_prefix = time.strftime('%Y-%m')
        records = DailyRevenue.query.filter_by(farmer_id=farmer_id).all()
        amount = sum(float(r.revenue or 0) for r in records if r.date.startswith(month_prefix))
        count = sum(r.order_count for r in records if r.date.startswith(month_prefix))
    elif range_type == 'year':
        year_prefix = time.strftime('%Y')
        records = DailyRevenue.query.filter_by(farmer_id=farmer_id).all()
        amount = sum(float(r.revenue or 0) for r in records if r.date.startswith(year_prefix))
        count = sum(r.order_count for r in records if r.date.startswith(year_prefix))
    else:
        amount = float(fp.total_revenue or 0) if fp else 0
        count = order_count

    return success_response({
        'amount': amount,
        'orderCount': count,
        'productCount': product_count,
        'conversionRate': round(count / max(product_count, 1) * 10, 1) if product_count > 0 else 0,
        'availableBalance': float(fp.available_balance or 0) if fp else 0,
    })


@revenue_bp.route('/records', methods=['GET'])
@jwt_required
def revenue_records():
    """
    营收明细列表
    GET /api/revenue/records?page=1&size=20&status=
    """
    payload = g.current_user
    farmer_id = payload.get('user_id')
    page = int(request.args.get('page', 1))
    size = int(request.args.get('size', 20))
    status = request.args.get('status', '')

    query = RevenueRecord.query.filter_by(farmer_id=farmer_id)
    if status:
        query = query.filter_by(status=status)

    total = query.count()
    records = query.order_by(RevenueRecord.created_at.desc()).offset((page - 1) * size).limit(size).all()

    items = []
    for r in records:
        items.append({
            'recordId': r.id,
            'orderId': r.order_id or '',
            'amount': float(r.amount),
            'type': r.type,
            'status': r.status,
            'createdAt': r.created_at,
            'settledAt': r.settled_at or 0,
        })

    return success_response({
        'list': items,
        'total': total,
        'page': page,
        'size': size,
        'hasMore': (page * size) < total,
    })


@revenue_bp.route('/chart', methods=['GET'])
@jwt_required
def revenue_chart():
    """
    营收图表数据（日维度）
    GET /api/revenue/chart?days=7
    """
    payload = g.current_user
    farmer_id = payload.get('user_id')
    days = int(request.args.get('days', 7))

    import datetime
    chart_data = []
    for i in range(days - 1, -1, -1):
        date = (datetime.date.today() - datetime.timedelta(days=i)).strftime('%Y-%m-%d')
        dr = DailyRevenue.query.filter_by(farmer_id=farmer_id, date=date).first()
        chart_data.append({
            'date': date,
            'revenue': float(dr.revenue or 0) if dr else 0,
            'orderCount': dr.order_count if dr else 0,
        })

    return success_response(chart_data)


@revenue_bp.route('/withdrawals', methods=['GET'])
@jwt_required
def withdrawal_list():
    """提现记录"""
    payload = g.current_user
    farmer_id = payload.get('user_id')
    page = int(request.args.get('page', 1))
    size = int(request.args.get('size', 20))

    query = Withdrawal.query.filter_by(farmer_id=farmer_id)
    total = query.count()
    withdrawals = query.order_by(Withdrawal.created_at.desc()).offset((page - 1) * size).limit(size).all()

    items = [{
        'withdrawalId': w.id,
        'amount': float(w.amount),
        'account': w.account or '',
        'status': w.status,
        'createdAt': w.created_at,
    } for w in withdrawals]

    return success_response({
        'list': items,
        'total': total,
        'page': page,
        'size': size,
        'hasMore': (page * size) < total,
    })


@revenue_bp.route('/withdraw', methods=['POST'])
@jwt_required
def withdraw():
    """申请提现"""
    payload = g.current_user
    farmer_id = payload.get('user_id')
    body = request.get_json(silent=True) or {}
    amount = float(body.get('amount', 0))

    fp = FarmerProfile.query.filter_by(user_id=farmer_id).first()
    if not fp:
        return error_response(404, '农户不存在')

    if amount <= 0 or amount > float(fp.available_balance or 0):
        return error_response(400, '提现金额不合法')

    fp.available_balance = float(fp.available_balance or 0) - amount

    w = Withdrawal(
        farmer_id=farmer_id,
        amount=amount,
        account=body.get('account', ''),
        status='completed',
    )
    db.session.add(w)
    db.session.commit()

    return success_response({'withdrawalId': w.id, 'amount': amount, 'status': 'completed'})
