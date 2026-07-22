from app.controllers.user_controller import user_bp
from app.controllers.farmer_controller import farmer_bp
from app.controllers.product_controller import product_bp
from app.controllers.order_controller import order_bp
from app.controllers.live_controller import live_bp
from app.controllers.community_controller import community_bp
from app.controllers.message_controller import message_bp
from app.controllers.travel_controller import travel_bp
from app.controllers.rank_controller import rank_bp
from app.controllers.ad_controller import ad_bp
from app.controllers.admin_controller import admin_bp
from app.controllers.ai_controller import ai_bp
from app.controllers.upload_controller import upload_bp
from app.controllers.home_controller import home_bp
from app.controllers.cart_controller import cart_bp
from app.controllers.revenue_controller import revenue_bp


def register_blueprints(app):
    app.register_blueprint(user_bp)
    app.register_blueprint(farmer_bp)
    app.register_blueprint(product_bp)
    app.register_blueprint(order_bp)
    app.register_blueprint(live_bp)
    app.register_blueprint(community_bp)
    app.register_blueprint(message_bp)
    app.register_blueprint(travel_bp)
    app.register_blueprint(rank_bp)
    app.register_blueprint(ad_bp)
    app.register_blueprint(admin_bp)
    app.register_blueprint(ai_bp)
    app.register_blueprint(upload_bp)
    app.register_blueprint(home_bp)
    app.register_blueprint(cart_bp)
    app.register_blueprint(revenue_bp)
