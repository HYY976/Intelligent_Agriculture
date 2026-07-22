def register_chat_events(socketio):
    """聊天 WebSocket 事件占位"""

    @socketio.on('connect')
    def _on_connect():
        return True

    @socketio.on('chat_message')
    def _on_chat_message(data):
        socketio.emit('chat_message', data)
