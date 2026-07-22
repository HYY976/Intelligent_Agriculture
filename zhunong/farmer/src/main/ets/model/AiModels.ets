/**
 * AiModels - AI 接口数据模型（spec 第8章）
 * 遵循 spec 8.1 AI文案 / 8.2 AI海报 / 8.3 AI智能体接口规范
 * 现阶段后端 Mock，前端调用层完整实现，后续仅需替换后端 Service
 */

/** AI 文案请求（spec 8.1.2 AiCopywriteRequest） */
export interface AiCopywriteRequest {
  /** 商品ID（编辑时传） */
  productId?: string;
  /** 商品标题 */
  title: string;
  /** 商品类目 */
  category: string;
  /** 商品图片 URL 数组 */
  images: string[];
  /** 关键卖点 */
  keyPoints?: string[];
}

/** AI 文案流式消息类型 */
export type AiCopywriteMessageType = 'chunk' | 'done' | 'error';

/** AI 文案流式消息（spec 8.1.3） */
export interface AiCopywriteMessage {
  /** 消息类型：chunk 文案片段 / done 完成 / error 错误 */
  type: AiCopywriteMessageType;
  /** 文案片段（chunk 时） */
  content?: string;
  /** 完整描述（done 时） */
  description?: string;
  /** 亮点数组（done 时） */
  highlights?: string[];
  /** 错误信息（error 时） */
  message?: string;
}

/** AI 文案流式回调 */
export type OnAiCopywriteChunk = (chunk: string) => void;
/** AI 文案完成回调 */
export type OnAiCopywriteDone = (description: string, highlights: string[]) => void;
/** AI 文案错误回调 */
export type OnAiCopywriteError = (message: string) => void;

/** AI 文案监听器集合 */
export interface AiCopywriteListeners {
  onChunk: OnAiCopywriteChunk;
  onDone: OnAiCopywriteDone;
  onError: OnAiCopywriteError;
}

/** AI 海报任务请求（spec 8.2.1 AiPosterTaskRequest） */
export interface AiPosterTaskRequest {
  /** 商品ID（编辑时传） */
  productId?: string;
  /** 商品图片 URL 数组 */
  images: string[];
  /** 商品标题 */
  title: string;
  /** 风格（清新/复古/国风） */
  style?: string;
}

/** AI 海报任务状态（spec 8.2.2） */
export type AiPosterTaskStatus = 'pending' | 'done' | 'failed';

/** AI 海报任务创建响应（spec 8.2.1 AiPosterTaskResponse） */
export interface AiPosterTaskResponse {
  taskId: string;
  status: 'pending';
  createdAt: number;
}

/** AI 海报任务结果（spec 8.2.2 AiPosterTaskResult） */
export interface AiPosterTaskResult {
  taskId: string;
  status: AiPosterTaskStatus;
  /** 海报 URL（done 时） */
  posterUrl?: string;
  /** 缩略图 URL（done 时） */
  thumbnailUrl?: string;
  /** 错误信息（failed 时） */
  errorMessage?: string;
  createdAt: number;
  /** 完成时间戳 */
  completedAt?: number;
}

/** AI 海报轮询回调 */
export type OnAiPosterProgress = (status: AiPosterTaskStatus) => void;
/** AI 海报完成回调 */
export type OnAiPosterDone = (posterUrl: string, thumbnailUrl: string) => void;
/** AI 海报失败回调 */
export type OnAiPosterError = (message: string) => void;

/** AI 海报监听器集合 */
export interface AiPosterListeners {
  onProgress: OnAiPosterProgress;
  onDone: OnAiPosterDone;
  onError: OnAiPosterError;
}

/** AI 智能体 TTS 请求（spec 8.3.1 AiTtsRequest） */
export interface AiTtsRequest {
  productId: string;
  /** 待合成文本 */
  text: string;
  /** 音色（男声/女声/方言） */
  voiceType?: string;
}

/** AI 智能体 TTS 响应（spec 8.3.1 AiTtsResponse） */
export interface AiTtsResponse {
  /** 音频 URL */
  audioUrl: string;
  /** 时长（秒） */
  duration: number;
}

/** AI 智能体推荐项（spec 8.3.2） */
export interface AiRecommendItem {
  productId: string;
  /** 推荐理由 */
  reason: string;
  /** 优先级 */
  priority: number;
}

/** AI 智能体推荐请求（spec 8.3.2 AiRecommendRequest） */
export interface AiRecommendRequest {
  farmerId: string;
  /** 直播ID（直播间场景） */
  liveId?: string;
  /** 上下文（开场/促销） */
  context?: string;
}

/** AI 智能体推荐响应（spec 8.3.2 AiRecommendResponse） */
export interface AiRecommendResponse {
  recommendations: AiRecommendItem[];
}

/** 音色枚举文案 */
export const AI_VOICE_LABELS: Record<string, string> = {
  'male': '男声',
  'female': '女声',
  'dialect': '方言'
};

/** AI 海报风格枚举文案 */
export const AI_POSTER_STYLE_LABELS: Record<string, string> = {
  'fresh': '清新',
  'retro': '复古',
  'chinese': '国风'
};
