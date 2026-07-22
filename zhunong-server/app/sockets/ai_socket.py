def register_ai_events(socketio):
    """AI 文案流式生成 WebSocket 事件占位"""

    @socketio.on('connect')
    def _on_connect():
        return True

    @socketio.on('ai_generate')
    def _on_ai_generate(data):
        socketio.emit('ai_chunk', {'content': ''})
