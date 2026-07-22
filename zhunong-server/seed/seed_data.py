import time
import random
from werkzeug.security import generate_password_hash
from app.extensions import db
from app.models.user import User, FarmerProfile, Admin
from app.models.product import Product, ProductSku, Category
from app.models.community import Topic, Post, Comment
from app.models.live import Live
from app.models.ranking import ProductRank
from app.models.order import Order, SubOrder, OrderItem, Review
from app.models.cart import CartItem
from app.models.revenue import RevenueRecord, Withdrawal, DailyRevenue
from app.models.message import ChatSession, ChatMessage
from app.models.follow import Follow
from app.models.gift import Gift
from app.models.review import ContentReview
from app.models.user_ext import UserAddress
from app.models.admin_ext import ApiInfo, ApiKey, RateLimitConfig


def run_seed():
    """初始化全部演示数据"""
    now_ms = int(time.time() * 1000)

    # ===================== 1. 管理员 =====================
    admins_data = [
        ('super_admin', 'admin123', 'super_admin', '超级管理员'),
        ('user_admin', 'admin123', 'user_admin', '用户管理员'),
        ('content_reviewer', 'admin123', 'content_reviewer', '内容审核员'),
        ('api_admin', 'admin123', 'api_admin', 'API管理员'),
    ]
    for username, password, role, nickname in admins_data:
        if not Admin.query.filter_by(username=username).first():
            db.session.add(Admin(
                username=username,
                password_hash=generate_password_hash(password),
                role=role,
                nickname=nickname,
            ))
    db.session.commit()

    # ===================== 2. 分类树 =====================
    # 一级分类
    cat1_data = [
        ('生鲜水果', '🍎'), ('粮油调味', '🌾'), ('肉禽蛋品', '🥩'),
        ('农副加工', '🫒'), ('茶饮冲调', '🍵'), ('坚果干货', '🥜'),
    ]
    cat1_map = {}
    for idx, (name, icon) in enumerate(cat1_data):
        c = Category.query.filter_by(name=name, level=1).first()
        if not c:
            c = Category(name=name, level=1, icon=icon, sort_order=idx)
            db.session.add(c)
            db.session.flush()
        cat1_map[name] = c.id

    # 二级分类（生鲜水果下）
    cat2_data = {
        '生鲜水果': ['时令鲜果', '热带水果', '进口水果'],
        '粮油调味': ['大米杂粮', '食用油', '调味品'],
        '肉禽蛋品': ['猪肉', '牛羊肉', '蛋品'],
        '农副加工': ['干货菌菇', '腌腊制品', '蜂蜜'],
        '茶饮冲调': ['茶叶', '咖啡', '冲饮'],
        '坚果干货': ['坚果', '果干', '零食'],
    }
    cat2_map = {}
    for c1_name, subs in cat2_data.items():
        parent_id = cat1_map.get(c1_name)
        if not parent_id:
            continue
        for idx, name in enumerate(subs):
            c = Category.query.filter_by(name=name, level=2, parent_id=parent_id).first()
            if not c:
                c = Category(name=name, level=2, parent_id=parent_id, sort_order=idx)
                db.session.add(c)
                db.session.flush()
            cat2_map[f'{c1_name}/{name}'] = c.id
    db.session.commit()

    # ===================== 3. 农户用户 =====================
    farmers_data = [
        ('13800000001', '青禾农庄', '有机蔬菜·新鲜直达', '云南·昆明', 'approved'),
        ('13800000002', '山野好物', '山间散养·自然好味', '湖南·长沙', 'approved'),
        ('13800000003', '田园牧歌', '五常大米·产地直供', '黑龙江·五常', 'approved'),
        ('13800000004', '阳光果园', '热带鲜果·树上熟', '海南·三亚', 'approved'),
        ('13800000005', '云上茶舍', '高山云雾茶·手工炒制', '福建·武夷山', 'pending'),
    ]
    farmer_ids = []
    for phone, shop_name, shop_intro, location, cert_status in farmers_data:
        user = User.query.filter_by(phone=phone).first()
        if not user:
            user = User(
                phone=phone,
                nickname=shop_name,
                password_hash=generate_password_hash('123456'),
                user_type='farmer',
            )
            db.session.add(user)
            db.session.flush()
            fp = FarmerProfile(
                user_id=user.id,
                shop_name=shop_name,
                shop_intro=shop_intro,
                certification_status=cert_status,
                total_revenue=random.uniform(10000, 80000),
                available_balance=random.uniform(5000, 20000),
                fans_count=random.randint(50, 500),
            )
            db.session.add(fp)
        farmer_ids.append(user.id)
    db.session.commit()

    # ===================== 4. 买家用户 =====================
    buyers_data = [
        ('13900000001', '小美'), ('13900000002', '大壮'), ('13900000003', '花花'),
        ('13900000004', '老王'), ('13900000005', '阿杰'), ('13900000006', '小红'),
        ('13900000007', '小李'), ('13900000008', '阿芳'),
    ]
    buyer_ids = []
    for phone, nickname in buyers_data:
        user = User.query.filter_by(phone=phone).first()
        if not user:
            user = User(
                phone=phone,
                nickname=nickname,
                password_hash=generate_password_hash('123456'),
                user_type='user',
            )
            db.session.add(user)
            db.session.flush()
        buyer_ids.append(user.id)
    db.session.commit()

    # ===================== 5. 商品 =====================
    products_data = [
        ('有机青菜 500g', '生鲜水果/时令鲜果', 9.90, 568, 5680, 'prod_vegetable_1'),
        ('土鸡蛋30枚', '肉禽蛋品/蛋品', 39.90, 320, 3260, 'prod_egg_1'),
        ('农家大米5kg', '粮油调味/大米杂粮', 59.00, 480, 2180, 'prod_rice_1'),
        ('新鲜番茄 1kg', '生鲜水果/时令鲜果', 12.80, 680, 4560, 'prod_vegetable_2'),
        ('武夷岩茶 250g', '茶饮冲调/茶叶', 128.00, 120, 560, 'prod_tea_1'),
        ('东北黑木耳 200g', '农副加工/干货菌菇', 25.80, 450, 1890, 'prod_mushroom_1'),
        ('海南芒果 5斤', '生鲜水果/热带水果', 35.00, 380, 2680, 'prod_fruit_1'),
        ('云南核桃 500g', '坚果干货/坚果', 29.90, 520, 3200, 'prod_nut_1'),
        ('农家腊肉 500g', '农副加工/腌腊制品', 45.00, 280, 1560, 'prod_meat_1'),
        ('五常稻花香 10kg', '粮油调味/大米杂粮', 115.00, 200, 890, 'prod_rice_2'),
        ('散养土鸡 1只', '肉禽蛋品/猪肉', 68.00, 150, 720, 'prod_chicken_1'),
        ('龙井茶叶 100g', '茶饮冲调/茶叶', 88.00, 160, 480, 'prod_tea_2'),
        ('新疆红枣 1kg', '坚果干货/果干', 19.90, 600, 4200, 'prod_date_1'),
        ('土蜂蜜 500g', '农副加工/蜂蜜', 55.00, 180, 630, 'prod_honey_1'),
        ('东北松子 250g', '坚果干货/坚果', 49.90, 140, 510, 'prod_pine_1'),
    ]
    product_ids = []
    for idx, (title, cat_path, price, stock, monthly_sales, image_key) in enumerate(products_data):
        # 分配给不同农户
        fid = farmer_ids[idx % len(farmer_ids)]
        cat_id = cat2_map.get(cat_path, '')

        p = Product(
            farmer_id=fid,
            title=title,
            category_id=cat_id,
            main_images=[image_key],
            description=f'{title} - 新鲜直达，品质保证，产地直供',
            price=price,
            stock=stock,
            ship_from='产地直发',
            freight_template='满39包邮',
            monthly_sales=monthly_sales,
            monthly_gmv=price * monthly_sales,
            total_sales=monthly_sales * 3,
            status='approved',
        )
        db.session.add(p)
        db.session.flush()
        product_ids.append(p.id)

        # 创建默认 SKU
        sku = ProductSku(
            product_id=p.id,
            specs=[{'name': '规格', 'value': '默认'}],
            price=price,
            stock=stock,
            sku_code=f'P{idx+1:03d}',
        )
        db.session.add(sku)

        # 创建审核记录（已通过）
        cr = ContentReview(
            content_type='product',
            content_id=p.id,
            submitter_id=fid,
            status='approved',
            reviewed_at=now_ms,
        )
        db.session.add(cr)

    db.session.commit()

    # ===================== 6. 收货地址 =====================
    for bid in buyer_ids[:3]:
        addr = UserAddress(
            buyer_id=bid,
            receiver_name='张三',
            phone='13800000000',
            province='湖北省',
            city='武汉市',
            district='武昌区',
            detail='光谷大道100号',
            is_default=True,
        )
        db.session.add(addr)
    db.session.commit()

    # ===================== 7. 订单（覆盖8种状态） =====================
    if buyer_ids and product_ids:
        order_statuses = [
            'pending_payment', 'pending_shipment', 'pending_receipt',
            'pending_review', 'completed', 'completed', 'cancelled', 'refunded',
        ]
        for idx, status in enumerate(order_statuses):
            bid = buyer_ids[idx % len(buyer_ids)]
            pid = product_ids[idx % len(product_ids)]
            p = Product.query.get(pid)

            order = Order(
                buyer_id=bid,
                total_amount=float(p.price) if p else 10.0,
                status=status,
            )
            db.session.add(order)
            db.session.flush()

            fid = p.farmer_id if p else farmer_ids[0]
            sub = SubOrder(
                order_id=order.id,
                farmer_id=fid,
                subtotal=float(p.price) if p else 10.0,
                freight=0,
                status=status,
            )
            db.session.add(sub)
            db.session.flush()

            oi = OrderItem(
                sub_order_id=sub.id,
                product_id=pid,
                title=p.title if p else '商品',
                image=(p.main_images or [''])[0] if p else '',
                price=p.price if p else 10.0,
                quantity=1,
            )
            db.session.add(oi)

    db.session.commit()

    # ===================== 8. 话题 =====================
    topic_names = ['全部', '种植技术', '销路讨论', '乡村生活', '互助问答']
    for idx, name in enumerate(topic_names):
        if not Topic.query.filter_by(name=name).first():
            db.session.add(Topic(name=name, sort_order=idx, is_preset=True))
    db.session.commit()

    # ===================== 9. 帖子 =====================
    topics = Topic.query.all()
    for i in range(20):
        author = User.query.get(random.choice(buyer_ids + farmer_ids))
        topic = random.choice(topics) if topics else None
        post = Post(
            author_id=author.id,
            author_type=author.user_type,
            topic_id=topic.id if topic else None,
            title=f'分享：助农好物推荐第{i+1}期',
            content=f'大家好，今天给大家推荐几款优质的农产品，都是产地直供，新鲜美味！第{i+1}期分享来啦~',
            images=[],
            like_count=random.randint(10, 200),
            comment_count=random.randint(2, 30),
            favorite_count=random.randint(5, 50),
            status='normal',
        )
        db.session.add(post)
    db.session.commit()

    # ===================== 10. 直播 =====================
    for idx, fid in enumerate(farmer_ids[:3]):
        live = Live(
            farmer_id=fid,
            title=f'助农直播第{idx+1}场',
            cover_image='',
            category='生鲜水果',
            intro='产地直供，新鲜直达',
            product_bag=product_ids[:3],
            status='ended' if idx > 0 else 'living',
            start_time=now_ms - 3600000,
            end_time=now_ms if idx > 0 else None,
            total_view_uv=random.randint(500, 5000),
            total_gift_income=random.uniform(100, 1000),
        )
        db.session.add(live)
    db.session.commit()

    # ===================== 11. 聊天会话 + 消息 =====================
    for i in range(5):
        bid = buyer_ids[i % len(buyer_ids)]
        fid = farmer_ids[i % len(farmer_ids)]
        session = ChatSession(
            type='private',
            user_a_id=bid,
            user_b_id=fid,
            last_message='好的，谢谢！',
            last_message_at=now_ms - i * 60000,
        )
        db.session.add(session)
        db.session.flush()

        # 每个会话 5 条消息
        for j in range(5):
            sender_id = bid if j % 2 == 0 else fid
            receiver_id = fid if j % 2 == 0 else bid
            msg = ChatMessage(
                session_id=session.id,
                sender_id=sender_id,
                receiver_id=receiver_id,
                content=['你好，这个还有货吗？', '有的，新鲜得很！', '价格能优惠吗？', '已经是产地价了哦', '好的，谢谢！'][j],
                created_at=now_ms - (5 - j) * 60000,
            )
            db.session.add(msg)
    db.session.commit()

    # ===================== 12. 粉丝关系 =====================
    for fid in farmer_ids[:3]:
        for bid in buyer_ids[:5]:
            if not Follow.query.filter_by(follower_id=bid, following_id=fid).first():
                f = Follow(follower_id=bid, following_id=fid)
                db.session.add(f)
    db.session.commit()

    # ===================== 13. 营收数据 =====================
    import datetime
    for fid in farmer_ids[:3]:
        for days_ago in range(7):
            date = (datetime.date.today() - datetime.timedelta(days=days_ago)).strftime('%Y-%m-%d')
            if not DailyRevenue.query.filter_by(farmer_id=fid, date=date).first():
                dr = DailyRevenue(
                    date=date,
                    farmer_id=fid,
                    order_count=random.randint(5, 30),
                    revenue=random.uniform(500, 3000),
                )
                db.session.add(dr)
    db.session.commit()

    # ===================== 14. 礼物配置 =====================
    gift_names = [('小红花', 1), ('爱心', 5), ('火箭', 50), ('皇冠', 100), ('嘉年华', 500)]
    for name, price in gift_names:
        if not Gift.query.filter_by(name=name).first():
            db.session.add(Gift(name=name, price=price))
    db.session.commit()

    # ===================== 15. 商品月度榜单 =====================
    month = time.strftime('%Y-%m')
    for idx, pid in enumerate(product_ids[:10], start=1):
        p = Product.query.get(pid)
        if p and not ProductRank.query.filter_by(month=month, product_id=pid).first():
            db.session.add(ProductRank(
                month=month,
                product_id=pid,
                farmer_id=p.farmer_id,
                monthly_gmv=float(p.monthly_gmv or 0),
                rank=idx,
            ))
    db.session.commit()

    # ===================== 16. API 管理 Mock 数据 =====================
    api_paths = [
        ('/api/home/recommend', 'GET', '首页推荐流'),
        ('/api/product/list', 'GET', '商品列表'),
        ('/api/user/login', 'POST', '用户登录'),
        ('/api/order/create', 'POST', '创建订单'),
        ('/api/cart/list', 'GET', '购物车列表'),
        ('/api/admin/reviews', 'GET', '审核列表'),
    ]
    for path, method, desc in api_paths:
        if not ApiInfo.query.filter_by(path=path, method=method).first():
            api = ApiInfo(
                path=path, method=method, description=desc,
                today_request_count=random.randint(100, 5000),
                error_rate=round(random.uniform(0, 0.5), 2),
                avg_response_time=round(random.uniform(10, 200), 1),
            )
            db.session.add(api)
            db.session.flush()

            rl = RateLimitConfig(api_id=api.id, qps_limit=100)
            db.session.add(rl)

    # 默认密钥
    if not ApiKey.query.first():
        import secrets
        db.session.add(ApiKey(app_key=secrets.token_hex(16), app_secret=secrets.token_hex(32)))

    db.session.commit()

    # ===================== 17. 审核队列（5条待审核） =====================
    # 创建几个 pending 状态的商品和审核记录
    for i in range(5):
        fid = farmer_ids[i % len(farmer_ids)]
        p = Product(
            farmer_id=fid,
            title=f'待审核商品{i+1}',
            main_images=['prod_vegetable_1'],
            description='新上架商品待审核',
            price=random.uniform(10, 100),
            stock=random.randint(50, 200),
            status='pending_review',
        )
        db.session.add(p)
        db.session.flush()

        cr = ContentReview(
            content_type='product',
            content_id=p.id,
            submitter_id=fid,
            status='pending',
        )
        db.session.add(cr)
    db.session.commit()

    print('✅ 种子数据初始化完成：')
    print(f'   管理员: 4 | 农户: {len(farmer_ids)} | 买家: {len(buyer_ids)}')
    print(f'   商品: {len(product_ids)} | 订单: {len(order_statuses)} | 帖子: 20')
    print(f'   待审核: 5')
