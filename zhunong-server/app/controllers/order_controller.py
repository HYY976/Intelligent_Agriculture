"""
order_controller - 订单 API
  - POST /create     创建订单（按卖家拆子订单）
  - GET  /list       订单列表（按状态筛选）
  - GET  /<id>       订单详情
  - POST /<id>/pay   模拟支付
  - POST /<id>/confirm 确认收货
  - POST /<id>/cancel 取消订单
  - POST /<id>/review 提交评价
  - GET  /count      各状态订单数量统计
"""

import time
from flask import Blueprint, jsonify, request, g
from app.extensions import db
from app.models.order import Order, SubOrder, OrderItem, Review
from app.models.product import Product
from app.models.cart import CartItem
from app.models.user import User, FarmerProfile
from app.models.user_ext import UserAddress
from app.utils.response import success_response, error_response
from app.utils.decorators import jwt_required

order_bp = Blueprint('order', __name__, url_prefix='/api/order')


@order_bp.route('/health', methods=['GET'])
def health():
    return jsonify({'code': 200, 'msg': 'ok', 'data': {'service': 'order'}})


@order_bp.route('/create', methods=['POST'])
@jwt_required
def create_order():
    """
    创建订单（从购物车选中项创建，按卖家拆子订单）
    POST /api/order/create
    body: { addressId, couponId?, cartItemIds? }
    如果 cartItemIds 为空，则使用所有选中的购物车项
    """
    payload = g.current_user
    buyer_id = payload.get('user_id')
    body = request.get_json(silent=True) or {}
    address_id = body.get('addressId', '')
    cart_item_ids = body.get('cartItemIds', [])

    # 获取购物车项
    if cart_item_ids:
        cart_items = CartItem.query.filter(CartItem.id.in_(cart_item_ids)).all()
    else:
        cart_items = CartItem.query.filter_by(buyer_id=buyer_id, is_selected=True).all()

    if not cart_items:
        return error_response(400, '购物车为空')

    # 按卖家分组
    farmer_groups = {}
    for ci in cart_items:
        fid = ci.farmer_id
        if fid not in farmer_groups:
            farmer_groups[fid] = []
        farmer_groups[fid].append(ci)

    # 计算总金额
    total_amount = sum(float(ci.price) * ci.quantity for ci in cart_items)

    # 创建主订单
    order = Order(
        buyer_id=buyer_id,
        total_amount=total_amount,
        status='pending_payment',
        coupon_id=body.get('couponId'),
    )
    db.session.add(order)
    db.session.flush()

    # 创建子订单（按卖家拆单）
    for farmer_id, items in farmer_groups.items():
        subtotal = sum(float(ci.price) * ci.quantity for ci in items)
        sub_order = SubOrder(
            order_id=order.id,
            farmer_id=farmer_id,
            subtotal=subtotal,
            freight=0,
            status='pending_payment',
            address_id=address_id,
        )
        db.session.add(sub_order)
        db.session.flush()

        # 创建订单项
        for ci in items:
            order_item = OrderItem(
                sub_order_id=sub_order.id,
                product_id=ci.product_id,
                title=ci.title,
                image=ci.image or '',
                specs=ci.specs,
                price=ci.price,
                quantity=ci.quantity,
            )
            db.session.add(order_item)

            # 扣减库存
            product = Product.query.get(ci.product_id)
            if product:
                product.stock = max(0, product.stock - ci.quantity)

    # 清空已下单的购物车项
    for ci in cart_items:
        db.session.delete(ci)

    db.session.commit()

    return success_response({
        'orderId': order.id,
        'totalAmount': total_amount,
        'status': 'pending_payment',
    })


@order_bp.route('/list', methods=['GET'])
@jwt_required
def order_list():
    """
    订单列表
    GET /api/order/list?page=1&size=20&status=
    """
    payload = g.current_user
    buyer_id = payload.get('user_id')
    page = int(request.args.get('page', 1))
    size = int(request.args.get('size', 20))
    status = request.args.get('status', '')

    query = Order.query.filter_by(buyer_id=buyer_id)
    if status:
        query = query.filter_by(status=status)

    total = query.count()
    orders = query.order_by(Order.created_at.desc()).offset((page - 1) * size).limit(size).all()

    items = []
    for o in orders:
        # 获取第一个商品图作为主图
        sub_orders = SubOrder.query.filter_by(order_id=o.id).all()
        main_image = ''
        item_count = 0
        seller_names = []
        for so in sub_orders:
            oi_list = OrderItem.query.filter_by(sub_order_id=so.id).all()
            item_count += len(oi_list)
            for oi in oi_list:
                if not main_image and oi.image:
                    main_image = oi.image
            farmer = User.query.get(so.farmer_id)
            fp = FarmerProfile.query.filter_by(user_id=so.farmer_id).first()
            seller_names.append(fp.shop_name if fp else (farmer.nickname if farmer else ''))

        items.append({
            'orderId': o.id,
            'status': o.status,
            'mainImage': main_image,
            'itemCount': item_count,
            'totalAmount': float(o.total_amount),
            'sellerDisplay': '、'.join(seller_names),
            'createdAt': o.created_at,
        })

    return success_response({
        'list': items,
        'total': total,
        'page': page,
        'size': size,
        'hasMore': (page * size) < total,
    })


@order_bp.route('/<order_id>', methods=['GET'])
@jwt_required
def order_detail(order_id):
    """订单详情"""
    order = Order.query.get(order_id)
    if not order:
        return error_response(404, '订单不存在')

    sub_orders = SubOrder.query.filter_by(order_id=order_id).all()
    sub_items = []
    for so in sub_orders:
        farmer = User.query.get(so.farmer_id)
        fp = FarmerProfile.query.filter_by(user_id=so.farmer_id).first()
        oi_list = OrderItem.query.filter_by(sub_order_id=so.id).all()

        order_items = [{
            'orderItemId': oi.id,
            'productId': oi.product_id,
            'title': oi.title,
            'image': oi.image or '',
            'specs': oi.specs or [],
            'price': float(oi.price),
            'quantity': oi.quantity,
        } for oi in oi_list]

        sub_items.append({
            'subOrderId': so.id,
            'farmerId': so.farmer_id,
            'farmerName': fp.shop_name if fp else (farmer.nickname if farmer else ''),
            'subtotal': float(so.subtotal),
            'freight': float(so.freight or 0),
            'status': so.status,
            'items': order_items,
        })

    # 收货地址
    address_info = None
    if sub_orders and sub_orders[0].address_id:
        addr = UserAddress.query.get(sub_orders[0].address_id)
        if addr:
            address_info = {
                'receiverName': addr.receiver_name,
                'phone': addr.phone,
                'province': addr.province or '',
                'city': addr.city or '',
                'district': addr.district or '',
                'detail': addr.detail or '',
            }

    return success_response({
        'orderId': order.id,
        'buyerId': order.buyer_id,
        'totalAmount': float(order.total_amount),
        'status': order.status,
        'createdAt': order.created_at,
        'paidAt': order.paid_at or 0,
        'address': address_info,
        'subOrders': sub_items,
    })


@order_bp.route('/<order_id>/pay', methods=['POST'])
@jwt_required
def pay_order(order_id):
    """模拟支付：pending_payment → pending_shipment"""
    order = Order.query.get(order_id)
    if not order:
        return error_response(404, '订单不存在')
    if order.status != 'pending_payment':
        return error_response(400, '订单状态不允许支付')

    now_ms = int(time.time() * 1000)
    order.status = 'pending_shipment'
    order.paid_at = now_ms

    for so in SubOrder.query.filter_by(order_id=order_id).all():
        so.status = 'pending_shipment'

    # 写入营收记录
    for so in SubOrder.query.filter_by(order_id=order_id).all():
        from app.models.revenue import RevenueRecord
        rr = RevenueRecord(
            farmer_id=so.farmer_id,
            order_id=order.id,
            sub_order_id=so.id,
            amount=so.subtotal,
            type='order',
            status='pending',
        )
        db.session.add(rr)

        # 更新卖家营收
        fp = FarmerProfile.query.filter_by(user_id=so.farmer_id).first()
        if fp:
            fp.total_revenue = float(fp.total_revenue or 0) + float(so.subtotal)
            fp.available_balance = float(fp.available_balance or 0) + float(so.subtotal)

    db.session.commit()
    return success_response({'orderId': order_id, 'status': 'pending_shipment'})


@order_bp.route('/<order_id>/confirm', methods=['POST'])
@jwt_required
def confirm_order(order_id):
    """确认收货：pending_receipt → pending_review"""
    order = Order.query.get(order_id)
    if not order:
        return error_response(404, '订单不存在')

    order.status = 'pending_review'
    for so in SubOrder.query.filter_by(order_id=order_id).all():
        so.status = 'pending_review'

    # 营收结算
    for so in SubOrder.query.filter_by(order_id=order_id).all():
        from app.models.revenue import RevenueRecord
        RevenueRecord.query.filter_by(sub_order_id=so.id).update({'status': 'settled', 'settled_at': int(time.time() * 1000)})

    db.session.commit()
    return success_response({'orderId': order_id, 'status': 'pending_review'})


@order_bp.route('/<order_id>/cancel', methods=['POST'])
@jwt_required
def cancel_order(order_id):
    """取消订单"""
    order = Order.query.get(order_id)
    if not order:
        return error_response(404, '订单不存在')

    order.status = 'cancelled'
    for so in SubOrder.query.filter_by(order_id=order_id).all():
        so.status = 'cancelled'

    db.session.commit()
    return success_response({'orderId': order_id, 'status': 'cancelled'})


@order_bp.route('/<order_id>/review', methods=['POST'])
@jwt_required
def review_order(order_id):
    """
    提交评价：pending_review → completed
    body: { items: [{ productId, rating, content, images? }] }
    """
    order = Order.query.get(order_id)
    if not order:
        return error_response(404, '订单不存在')

    body = request.get_json(silent=True) or {}
    payload = g.current_user
    review_items = body.get('items', [])

    for ri in review_items:
        review = Review(
            order_id=order_id,
            product_id=ri.get('productId', ''),
            buyer_id=payload.get('user_id'),
            rating=ri.get('rating', 5),
            content=ri.get('content', ''),
            images=ri.get('images', []),
        )
        db.session.add(review)

    order.status = 'completed'
    for so in SubOrder.query.filter_by(order_id=order_id).all():
        so.status = 'completed'

    db.session.commit()
    return success_response({'orderId': order_id, 'status': 'completed'})


@order_bp.route('/count', methods=['GET'])
@jwt_required
def order_count():
    """各状态订单数量统计"""
    payload = g.current_user
    buyer_id = payload.get('user_id')

    statuses = ['pending_payment', 'pending_shipment', 'pending_receipt', 'pending_review', 'completed', 'cancelled']
    counts = {}
    for s in statuses:
        counts[s] = Order.query.filter_by(buyer_id=buyer_id, status=s).count()

    counts['all'] = Order.query.filter_by(buyer_id=buyer_id).count()

    return success_response(counts)
