"""
cart_controller - 购物车 API
  - GET  /list   购物车列表（按卖家分组）
  - POST /add    加入购物车
  - PUT  /update 更新数量/选中状态
  - DELETE /<id> 删除购物车项
"""

from flask import Blueprint, jsonify, request, g
from app.extensions import db
from app.models.cart import CartItem
from app.models.product import Product, ProductSku
from app.models.user import User, FarmerProfile
from app.utils.response import success_response, error_response
from app.utils.decorators import jwt_required

cart_bp = Blueprint('cart', __name__, url_prefix='/api/cart')


@cart_bp.route('/list', methods=['GET'])
@jwt_required
def cart_list():
    """
    购物车列表（按卖家分组）
    GET /api/cart/list
    """
    payload = g.current_user
    buyer_id = payload.get('user_id')

    items = CartItem.query.filter_by(buyer_id=buyer_id).order_by(CartItem.created_at.desc()).all()

    # 按卖家分组
    farmer_groups = {}
    for ci in items:
        fid = ci.farmer_id
        if fid not in farmer_groups:
            farmer_groups[fid] = []
        farmer_groups[fid].append(ci)

    groups = []
    for farmer_id, cart_items in farmer_groups.items():
        farmer = User.query.get(farmer_id)
        fp = FarmerProfile.query.filter_by(user_id=farmer_id).first()

        item_list = []
        for ci in cart_items:
            item_list.append({
                'cartItemId': ci.id,
                'productId': ci.product_id,
                'title': ci.title,
                'image': ci.image or '',
                'price': float(ci.price),
                'specs': ci.specs or [],
                'quantity': ci.quantity,
                'isSelected': ci.is_selected,
            })

        groups.append({
            'farmerId': farmer_id,
            'farmerName': fp.shop_name if fp else (farmer.nickname if farmer else ''),
            'items': item_list,
        })

    # 计算汇总
    selected_items = [ci for ci in items if ci.is_selected]
    total_amount = sum(float(ci.price) * ci.quantity for ci in selected_items)
    total_count = len(selected_items)

    return success_response({
        'groups': groups,
        'totalAmount': total_amount,
        'totalCount': total_count,
        'allCount': len(items),
    })


@cart_bp.route('/add', methods=['POST'])
@jwt_required
def add_to_cart():
    """
    加入购物车
    POST /api/cart/add
    body: { productId, skuId?, quantity? }
    """
    payload = g.current_user
    buyer_id = payload.get('user_id')
    body = request.get_json(silent=True) or {}
    product_id = body.get('productId', '')
    sku_id = body.get('skuId', '')
    quantity = int(body.get('quantity', 1))

    product = Product.query.get(product_id)
    if not product:
        return error_response(404, '商品不存在')

    # 获取 SKU 信息
    sku = ProductSku.query.get(sku_id) if sku_id else None
    price = float(sku.price) if sku else float(product.price)
    specs = sku.specs if sku else []
    title = product.title

    # 检查是否已在购物车
    existing = CartItem.query.filter_by(
        buyer_id=buyer_id,
        product_id=product_id,
        sku_id=sku_id if sku_id else None,
    ).first()

    if existing:
        existing.quantity += quantity
    else:
        ci = CartItem(
            buyer_id=buyer_id,
            farmer_id=product.farmer_id,
            product_id=product_id,
            sku_id=sku_id if sku_id else None,
            title=title,
            image=(product.main_images or [''])[0] if product.main_images else '',
            price=price,
            specs=specs,
            quantity=quantity,
        )
        db.session.add(ci)

    db.session.commit()
    return success_response(True)


@cart_bp.route('/update', methods=['PUT'])
@jwt_required
def update_cart_item():
    """
    更新数量/选中状态
    PUT /api/cart/update
    body: { cartItemId, quantity?, isSelected? }
    """
    body = request.get_json(silent=True) or {}
    cart_item_id = body.get('cartItemId', '')

    ci = CartItem.query.get(cart_item_id)
    if not ci:
        return error_response(404, '购物车项不存在')

    if 'quantity' in body:
        ci.quantity = int(body['quantity'])
        if ci.quantity <= 0:
            db.session.delete(ci)
    if 'isSelected' in body:
        ci.is_selected = bool(body['isSelected'])

    db.session.commit()
    return success_response(True)


@cart_bp.route('/<cart_item_id>', methods=['DELETE'])
@jwt_required
def delete_cart_item(cart_item_id):
    """删除购物车项"""
    ci = CartItem.query.get(cart_item_id)
    if ci:
        db.session.delete(ci)
        db.session.commit()
    return success_response(True)
