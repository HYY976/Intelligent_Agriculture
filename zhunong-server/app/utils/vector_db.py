import os
import chromadb


_client = None


def get_chroma_client():
    """获取 ChromaDB 客户端单例（语义推荐 / 用户画像向量检索）"""
    global _client
    if _client is None:
        persist_dir = os.getenv('CHROMA_PERSIST_DIR', './chroma_data')
        _client = chromadb.PersistentClient(path=persist_dir)
    return _client


def get_or_create_collection(name='zhunong_default'):
    """获取或创建一个向量集合"""
    client = get_chroma_client()
    return client.get_or_create_collection(name=name)
