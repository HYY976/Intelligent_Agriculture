def register_socket_events(socketio):
    """注册全部 WebSocket 事件处理"""
    from app.sockets.chat_socket import register_chat_events
    from app.sockets.ai_socket import register_ai_events
    register_chat_events(socketio)
    register_ai_events(socketio)
