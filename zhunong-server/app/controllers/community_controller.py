"""
community_controller - 社区模块 API
  - GET  /topics          话题列表
  - GET  /posts           帖子列表（分页+筛选+排序）
  - GET  /posts/<id>      帖子详情
  - POST /posts           发帖
  - POST /posts/<id>/like 点赞
  - POST /posts/<id>/favorite 收藏
  - GET  /posts/<id>/comments 评论列表
  - POST /posts/<id>/comments 发表评论
  - POST /report          举报
"""

import time
from flask import Blueprint, jsonify, request, g
from app.extensions import db
from app.models.community import Topic, Post, Comment
from app.models.user import User
from app.utils.response import success_response, error_response
from app.utils.decorators import jwt_required

community_bp = Blueprint('community', __name__, url_prefix='/api/community')


@community_bp.route('/health', methods=['GET'])
def health():
    return jsonify({'code': 200, 'msg': 'ok', 'data': {'service': 'community'}})


@community_bp.route('/topics', methods=['GET'])
def topics():
    """GET /api/community/topics"""
    all_topics = Topic.query.order_by(Topic.sort_order).all()
    items = [{
        'topicId': t.id,
        'name': t.name,
        'isPreset': t.is_preset,
    } for t in all_topics]
    return success_response({'list': items})


@community_bp.route('/posts', methods=['GET'])
def post_list():
    """
    GET /api/community/posts?page=1&size=20&topicId=all&keyword=&sortBy=latest
    """
    page = int(request.args.get('page', 1))
    size = int(request.args.get('size', 20))
    topic_id = request.args.get('topicId', 'all')
    keyword = request.args.get('keyword', '')
    sort_by = request.args.get('sortBy', 'latest')

    query = Post.query.filter_by(status='normal')

    if topic_id and topic_id != 'all':
        query = query.filter_by(topic_id=topic_id)
    if keyword:
        query = query.filter(Post.title.contains(keyword) | Post.content.contains(keyword))

    if sort_by == 'hottest':
        query = query.order_by(Post.like_count.desc())
    else:
        query = query.order_by(Post.created_at.desc())

    total = query.count()
    posts = query.offset((page - 1) * size).limit(size).all()

    items = []
    for p in posts:
        author = User.query.get(p.author_id)
        topic = Topic.query.get(p.topic_id) if p.topic_id else None
        items.append({
            'postId': p.id,
            'authorId': p.author_id,
            'authorName': author.nickname if author else '',
            'authorAvatar': author.avatar if author else '',
            'authorType': p.author_type,
            'topicId': p.topic_id or '',
            'topicName': topic.name if topic else '',
            'title': p.title or '',
            'content': (p.content or '')[:200],
            'images': p.images or [],
            'likeCount': p.like_count,
            'commentCount': p.comment_count,
            'favoriteCount': p.favorite_count,
            'createdAt': p.created_at,
        })

    return success_response({
        'list': items,
        'total': total,
        'page': page,
        'size': size,
        'hasMore': (page * size) < total,
    })


@community_bp.route('/posts/<post_id>', methods=['GET'])
def post_detail(post_id):
    """GET /api/community/posts/<post_id>"""
    p = Post.query.get(post_id)
    if not p:
        return error_response(404, '帖子不存在')

    author = User.query.get(p.author_id)
    topic = Topic.query.get(p.topic_id) if p.topic_id else None

    return success_response({
        'postId': p.id,
        'authorId': p.author_id,
        'authorName': author.nickname if author else '',
        'authorAvatar': author.avatar if author else '',
        'authorType': p.author_type,
        'topicId': p.topic_id or '',
        'topicName': topic.name if topic else '',
        'title': p.title or '',
        'content': p.content or '',
        'images': p.images or [],
        'likeCount': p.like_count,
        'commentCount': p.comment_count,
        'favoriteCount': p.favorite_count,
        'status': p.status,
        'createdAt': p.created_at,
    })


@community_bp.route('/posts', methods=['POST'])
@jwt_required
def create_post():
    """
    POST /api/community/posts
    body: { title, content, images[], topicId }
    """
    payload = g.current_user
    body = request.get_json(silent=True) or {}
    title = body.get('title', '')
    content = body.get('content', '')

    if not title or not content:
        return error_response(400, '标题和内容不能为空')

    post = Post(
        author_id=payload.get('user_id'),
        author_type=payload.get('user_type', 'user'),
        topic_id=body.get('topicId', ''),
        title=title,
        content=content,
        images=body.get('images', []),
        status='normal',
    )
    db.session.add(post)
    db.session.commit()

    return success_response({'postId': post.id, 'status': 'normal'})


@community_bp.route('/posts/<post_id>/like', methods=['POST'])
def post_like(post_id):
    """POST /api/community/posts/<post_id>/like"""
    body = request.get_json(silent=True) or {}
    liked = bool(body.get('liked', False))
    post = Post.query.get(post_id)
    if post:
        post.like_count = max(0, post.like_count + (1 if liked else -1))
        db.session.commit()
    return success_response({'liked': liked})


@community_bp.route('/posts/<post_id>/favorite', methods=['POST'])
def post_favorite(post_id):
    """POST /api/community/posts/<post_id>/favorite"""
    body = request.get_json(silent=True) or {}
    favorited = bool(body.get('favorited', False))
    post = Post.query.get(post_id)
    if post:
        post.favorite_count = max(0, post.favorite_count + (1 if favorited else -1))
        db.session.commit()
    return success_response({'favorited': favorited})


@community_bp.route('/posts/<post_id>/comments', methods=['GET'])
def post_comments(post_id):
    """GET /api/community/posts/<post_id>/comments"""
    page = int(request.args.get('page', 1))
    size = int(request.args.get('size', 50))

    query = Comment.query.filter_by(post_id=post_id)
    total = query.count()
    comments = query.order_by(Comment.created_at.asc()).offset((page - 1) * size).limit(size).all()

    items = []
    for c in comments:
        author = User.query.get(c.author_id)
        items.append({
            'commentId': c.id,
            'parentId': c.parent_id or '',
            'authorId': c.author_id,
            'authorName': author.nickname if author else '',
            'authorAvatar': author.avatar if author else '',
            'content': c.content,
            'likeCount': c.like_count,
            'createdAt': c.created_at,
        })

    return success_response({'list': items, 'total': total})


@community_bp.route('/posts/<post_id>/comments', methods=['POST'])
@jwt_required
def create_comment(post_id):
    """POST /api/community/posts/<post_id>/comments"""
    payload = g.current_user
    body = request.get_json(silent=True) or {}
    content = body.get('content', '')
    if not content:
        return error_response(400, '评论内容不能为空')

    comment = Comment(
        post_id=post_id,
        parent_id=body.get('parentId', '') or None,
        author_id=payload.get('user_id'),
        author_type=payload.get('user_type', 'user'),
        content=content,
    )
    db.session.add(comment)

    post = Post.query.get(post_id)
    if post:
        post.comment_count += 1

    db.session.commit()
    return success_response({'commentId': comment.id, 'content': content})


@community_bp.route('/comments/<comment_id>/like', methods=['POST'])
def comment_like(comment_id):
    """POST /api/community/comments/<comment_id>/like"""
    body = request.get_json(silent=True) or {}
    liked = bool(body.get('liked', False))
    comment = Comment.query.get(comment_id)
    if comment:
        comment.like_count = max(0, comment.like_count + (1 if liked else -1))
        db.session.commit()
    return success_response({'liked': liked})


@community_bp.route('/report', methods=['POST'])
@jwt_required
def report():
    """POST /api/community/report"""
    body = request.get_json(silent=True) or {}
    from app.models.review import Report
    report_obj = Report(
        reporter_id=g.current_user.get('user_id', ''),
        target_type=body.get('targetType', ''),
        target_id=body.get('targetId', ''),
        reason=body.get('reason', ''),
        description=body.get('description', ''),
    )
    db.session.add(report_obj)
    db.session.commit()
    return success_response({'reportId': report_obj.id, 'status': 'pending'})


@community_bp.route('/my/posts', methods=['GET'])
@jwt_required
def my_posts():
    """GET /api/community/my/posts"""
    payload = g.current_user
    page = int(request.args.get('page', 1))
    size = int(request.args.get('size', 20))

    query = Post.query.filter_by(author_id=payload.get('user_id'))
    total = query.count()
    posts = query.order_by(Post.created_at.desc()).offset((page - 1) * size).limit(size).all()

    items = [{
        'postId': p.id,
        'title': p.title or '',
        'likeCount': p.like_count,
        'commentCount': p.comment_count,
        'status': p.status,
        'createdAt': p.created_at,
    } for p in posts]

    return success_response({
        'list': items,
        'total': total,
        'page': page,
        'size': size,
        'hasMore': (page * size) < total,
    })


@community_bp.route('/my/favorites', methods=['GET'])
@jwt_required
def my_favorites():
    """GET /api/community/my/favorites"""
    page = int(request.args.get('page', 1))
    size = int(request.args.get('size', 20))
    return success_response({
        'list': [],
        'hasMore': False,
        'page': page,
        'size': size,
        'total': 0,
    })
