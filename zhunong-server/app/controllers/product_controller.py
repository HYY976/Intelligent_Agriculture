"""
product_controller - 商品 API
  - GET /list        商品列表（分页+筛选+排序）
  - GET /<id>        商品详情（含 SKU）
  - GET /categories  三级分类树
  - GET /<id>/reviews 商品评价列表
"""

from flask import Blueprint, jsonify, request
from app.extensions import db
from app.models.product import Product, ProductSku, Category
from app.models.user import User, FarmerProfile
from app.models.order import Review
from app.utils.response import success_response, error_response

product_bp = Blueprint('product', __name__, url_prefix='/api/product')


@product_bp.route('/health', methods=['GET'])
def health():
    return jsonify({'code': 200, 'msg': 'ok', 'data': {'service': 'product'}})


@product_bp.route('/list', methods=['GET'])
def product_list():
    """
    商品列表（分页+筛选+排序）
    GET /api/product/list?page=1&size=20&categoryId=&keyword=&sortBy=comprehensive
    """
    page = int(request.args.get('page', 1))
    size = int(request.args.get('size', 20))
    category_id = request.args.get('categoryId', '')
    keyword = request.args.get('keyword', '')
    sort_by = request.args.get('sortBy', 'comprehensive')

    query = Product.query.filter_by(status='approved')

    if category_id:
        # 支持一级分类筛选：查找该分类及其子分类下所有商品
        cat = Category.query.get(category_id)
        if cat and cat.level == 1:
            sub_cats = Category.query.filter_by(parent_id=category_id).all()
            cat_ids = [category_id] + [c.id for c in sub_cats]
            # 二级分类下还有三级
            for sc in sub_cats:
                third_cats = Category.query.filter_by(parent_id=sc.id).all()
                cat_ids.extend([tc.id for tc in third_cats])
            query = query.filter(Product.category_id.in_(cat_ids))
        else:
            query = query.filter_by(category_id=category_id)

    if keyword:
        query = query.filter(Product.title.contains(keyword))

    # 排序
    if sort_by == 'sales':
        query = query.order_by(Product.monthly_sales.desc())
    elif sort_by == 'price_asc':
        query = query.order_by(Product.price.asc())
    elif sort_by == 'price_desc':
        query = query.order_by(Product.price.desc())
    elif sort_by == 'newest':
        query = query.order_by(Product.created_at.desc())
    else:
        query = query.order_by(Product.monthly_sales.desc())

    total = query.count()
    products = query.offset((page - 1) * size).limit(size).all()

    items = []
    for p in products:
        farmer = User.query.get(p.farmer_id)
        fp = FarmerProfile.query.filter_by(user_id=p.farmer_id).first() if farmer else None
        items.append({
            'productId': p.id,
            'title': p.title,
            'mainImages': p.main_images or [],
            'mainImage': (p.main_images or [''])[0] if p.main_images else '',
            'price': float(p.price),
            'stock': p.stock,
            'monthlySales': p.monthly_sales,
            'farmerId': p.farmer_id,
            'farmerName': fp.shop_name if fp else (farmer.nickname if farmer else ''),
            'shipFrom': p.ship_from or '',
            'categoryId': p.category_id or '',
        })

    return success_response({
        'list': items,
        'total': total,
        'page': page,
        'size': size,
        'hasMore': (page * size) < total,
    })


@product_bp.route('/<product_id>', methods=['GET'])
def product_detail(product_id):
    """
    商品详情（含 SKU 列表）
    GET /api/product/<product_id>
    """
    p = Product.query.get(product_id)
    if not p:
        return error_response(404, '商品不存在')

    farmer = User.query.get(p.farmer_id)
    fp = FarmerProfile.query.filter_by(user_id=p.farmer_id).first() if farmer else None
    cat = Category.query.get(p.category_id) if p.category_id else None

    # SKU 列表
    skus = ProductSku.query.filter_by(product_id=product_id).all()
    sku_list = [{
        'skuId': s.id,
        'productId': s.product_id,
        'specs': s.specs or [],
        'price': float(s.price),
        'stock': s.stock,
        'skuCode': s.sku_code or '',
    } for s in skus]

    return success_response({
        'productId': p.id,
        'farmerId': p.farmer_id,
        'title': p.title,
        'categoryId': p.category_id or '',
        'categoryName': cat.name if cat else '',
        'mainImages': p.main_images or [],
        'aiPosterUrl': p.ai_poster_url or '',
        'description': p.description or '',
        'price': float(p.price),
        'stock': p.stock,
        'skuList': sku_list,
        'shipFrom': p.ship_from or '',
        'freightTemplate': p.freight_template or '',
        'monthlySales': p.monthly_sales,
        'monthlyGmv': float(p.monthly_gmv or 0),
        'totalSales': p.total_sales,
        'status': p.status,
        'createdAt': p.created_at,
        'updatedAt': p.updated_at,
        'farmerName': fp.shop_name if fp else (farmer.nickname if farmer else ''),
        'farmerAvatar': farmer.avatar if farmer else '',
        'certificationStatus': fp.certification_status if fp else 'none',
    })


@product_bp.route('/categories', methods=['GET'])
def categories():
    """
    三级分类树
    GET /api/product/categories
    """
    all_cats = Category.query.order_by(Category.sort_order).all()

    # 构建树
    cat_map = {}
    for c in all_cats:
        cat_map[c.id] = {
            'categoryId': c.id,
            'name': c.name,
            'icon': c.icon or '',
            'level': c.level,
            'parentId': c.parent_id or '',
            'children': [],
        }

    tree = []
    for c in all_cats:
        node = cat_map[c.id]
        if c.level == 1:
            tree.append(node)
        elif c.parent_id and c.parent_id in cat_map:
            cat_map[c.parent_id]['children'].append(node)

    return success_response(tree)


@product_bp.route('/<product_id>/reviews', methods=['GET'])
def product_reviews(product_id):
    """
    商品评价列表
    GET /api/product/<product_id>/reviews?page=1&size=20
    """
    page = int(request.args.get('page', 1))
    size = int(request.args.get('size', 20))

    query = Review.query.filter_by(product_id=product_id)
    total = query.count()
    reviews = query.order_by(Review.created_at.desc()).offset((page - 1) * size).limit(size).all()

    items = []
    for r in reviews:
        buyer = User.query.get(r.buyer_id)
        items.append({
            'reviewId': r.id,
            'buyerId': r.buyer_id,
            'buyerName': buyer.nickname if buyer else '',
            'buyerAvatar': buyer.avatar if buyer else '',
            'rating': r.rating,
            'content': r.content or '',
            'images': r.images or [],
            'farmerReply': r.farmer_reply or '',
            'createdAt': r.created_at,
        })

    return success_response({
        'list': items,
        'total': total,
        'page': page,
        'size': size,
        'hasMore': (page * size) < total,
    })
