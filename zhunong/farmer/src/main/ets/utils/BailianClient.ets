/**
 * BailianClient - 阿里云百炼应用调用客户端
 *
 * 接入阿里云百炼智能体应用（应用调用 API）
 * 文档：https://help.aliyun.com/zh/model-studio/developer-reference/use-api-key
 *
 * 接口规范：
 *  - URL: https://dashscope.aliyuncs.com/api/v1/applications/{app_id}/completion
 *  - Method: POST
 *  - Headers:
 *      Authorization: Bearer {API_KEY}
 *      Content-Type: application/json
 *  - Body: { input: { prompt }, parameters: { has_thoughts: false } }
 *  - Response: { output: { session_id, text }, request_id }
 *
 * 用于农户端"AI 文案"按钮：将商品标题/类目/卖点作为 prompt 输入，
 * 由百炼智能体应用生成完整的商品描述文案。
 */

import { http } from '@kit.NetworkKit';
import { Logger, AppConstants, ConfigUtil } from 'common';

/** 百炼应用调用请求头 */
interface BailianHeaders {
  'Authorization': string;
  'Content-Type': string;
}

/** 百炼应用调用请求体（input 部分） */
interface BailianInput {
  /** 用户输入提示词 */
  prompt: string;
}

/** 百炼应用调用请求体（parameters 部分） */
interface BailianParameters {
  /** 是否返回思考过程（默认 false） */
  has_thoughts: boolean;
}

/** 百炼应用调用请求体 */
interface BailianRequest {
  /** 输入内容 */
  input: BailianInput;
  /** 调用参数 */
  parameters: BailianParameters;
}

/** 百炼应用调用响应 output 部分 */
interface BailianOutput {
  /** 会话 ID（百炼返回，可用于多轮对话） */
  session_id?: string;
  /** 智能体生成的文本 */
  text?: string;
}

/** 百炼应用调用响应 */
interface BailianResponse {
  /** 输出内容 */
  output?: BailianOutput;
  /** 请求 ID（百炼追踪用） */
  request_id?: string;
  /** 错误码（调用失败时，字符串类型，区别于 WebSocket close code） */
  code?: string;
  /** 错误信息（调用失败时） */
  message?: string;
}

/** http.request 选项参数 */
interface HttpRequestOptions {
  method: http.RequestMethod;
  header: BailianHeaders;
  extraData: string;
  connectTimeout: number;
  readTimeout: number;
  expectDataType: http.HttpDataType;
}

/** 文案生成回调（成功） */
export type OnBailianSuccess = (text: string) => void;
/** 文案生成回调（失败） */
export type OnBailianError = (message: string) => void;

class BailianClientImpl {
  /**
   * 调用百炼智能体应用生成文案
   * @param prompt 用户输入提示词（拼接好的商品标题/类目/卖点等上下文）
   * @param onSuccess 成功回调，返回生成的文案
   * @param onError 失败回调，返回错误信息
   */
  async generateText(prompt: string, onSuccess: OnBailianSuccess, onError: OnBailianError): Promise<void> {
    const cfg = ConfigUtil.getBailianConfig();
    const url: string = `${cfg.baseUrl}/${cfg.appId}/completion`;

    Logger.info(AppConstants.SCENE_FARMER, {
      action: 'bailian_invoke_start',
      url,
      promptLength: prompt.length
    });

    const inputObj: BailianInput = { prompt };
    const parametersObj: BailianParameters = { has_thoughts: false };
    const requestBody: BailianRequest = {
      input: inputObj,
      parameters: parametersObj
    };
    const headersObj: BailianHeaders = {
      'Authorization': `Bearer ${cfg.apiKey}`,
      'Content-Type': 'application/json'
    };
    const requestOptions: HttpRequestOptions = {
      method: http.RequestMethod.POST,
      header: headersObj,
      extraData: JSON.stringify(requestBody),
      connectTimeout: AppConstants.HTTP_TIMEOUT_AI,
      readTimeout: AppConstants.HTTP_TIMEOUT_AI,
      expectDataType: http.HttpDataType.STRING
    };

    const httpRequest: http.HttpRequest = http.createHttp();
    try {
      const response: http.HttpResponse = await httpRequest.request(url, requestOptions);

      const responseStr: string = typeof response.result === 'string' ? response.result : '';
      const responseCode: number = response.responseCode;

      Logger.info(AppConstants.SCENE_FARMER, {
        action: 'bailian_invoke_response',
        status: responseCode,
        bodyLength: responseStr.length
      });

      if (responseCode < 200 || responseCode >= 300) {
        Logger.error(AppConstants.SCENE_FARMER, {
          action: 'bailian_http_error',
          status: responseCode,
          body: responseStr
        });
        onError(`百炼调用失败(${responseCode})`);
        return;
      }

      const parsed: BailianResponse = JSON.parse(responseStr) as BailianResponse;

      // 百炼业务错误（如 API Key 无效、应用未发布等）
      if (parsed.code && parsed.code.length > 0) {
        Logger.error(AppConstants.SCENE_FARMER, {
          action: 'bailian_business_error',
          bizCode: parsed.code,
          message: parsed.message
        });
        onError(parsed.message ?? `百炼调用错误：${parsed.code}`);
        return;
      }

      const text: string = parsed.output?.text ?? '';
      if (text.length === 0) {
        Logger.warn(AppConstants.SCENE_FARMER, {
          action: 'bailian_empty_text',
          requestId: parsed.request_id
        });
        onError('百炼未返回有效文案，请稍后重试');
        return;
      }

      Logger.info(AppConstants.SCENE_FARMER, {
        action: 'bailian_invoke_done',
        requestId: parsed.request_id,
        textLength: text.length
      });
      onSuccess(text);
    } catch (err) {
      const errMsg: string = (err as Error).message ?? '百炼调用异常';
      Logger.error(AppConstants.SCENE_FARMER, {
        action: 'bailian_invoke_exception',
        error: errMsg
      });
      onError(errMsg);
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 构造商品文案生成的提示词
   * @param title 商品标题
   * @param category 商品类目
   * @param keyPoints 关键卖点
   * @returns 拼接好的 prompt 字符串
   */
  buildCopywritePrompt(title: string, category: string, keyPoints: string[]): string {
    const parts: string[] = [];
    parts.push('请为以下商品生成一段详细描述文案，用于电商商品详情页展示。');
    parts.push(`商品标题：${title}`);
    if (category.length > 0) {
      parts.push(`商品类目：${category}`);
    }
    if (keyPoints.length > 0) {
      parts.push(`关键卖点：${keyPoints.join('、')}`);
    }
    parts.push('要求：');
    parts.push('1. 突出产地直采、新鲜健康的卖点；');
    parts.push('2. 描述口感、品质、营养价值；');
    parts.push('3. 说明采摘与配送方式，强调新鲜到家；');
    parts.push('4. 文案风格亲切自然，300字以内；');
    parts.push('5. 输出纯文本，不要使用 markdown 标记。');
    return parts.join('\n');
  }
}

/** 阿里云百炼应用调用客户端单例 */
export const BailianClient: BailianClientImpl = new BailianClientImpl();
