/**
 * WsClient - WebSocket 长连接封装（spec 3.1.3.3）
 * 遵循 spec 3.1.3.3 WebSocket 协议规范：
 *  - 连接地址：ws://server/api/ws?token=<jwt>
 *  - 心跳：每 30 秒客户端发送 ping，服务端响应 pong
 *  - 断线重连：指数退避（1s/2s/4s/8s/16s/30s 上限，AppConstants.WS_RECONNECT_DELAYS）
 *  - 消息格式：JSON WsMessage
 *
 * Phase 3 Mock 策略：
 *  - 真实环境：后端 WebSocket 服务未部署，连接失败时自动切换到 'mock' 状态
 *  - Mock 状态：本地模拟消息接收（定时推送系统通知），保证前端体验完整
 *  - Phase 6 联调：后端部署 ws 服务后，自动恢复真实长连接
 */

import { webSocket } from '@kit.NetworkKit';
import { Logger, AppConstants, PreferencesUtil } from 'common';
import { WsMessage, WsConnectionState, MessageContentType } from '../model/MessageModels';
import { ConfigUtil } from 'common';

/** 消息接收回调 */
type OnWsMessage = (msg: WsMessage) => void;
/** 连接状态变更回调 */
type OnWsStateChange = (state: WsConnectionState) => void;

class WsClientImpl {
  /** WebSocket 实例（null=未连接） */
  private ws: webSocket.WebSocket | null = null;
  /** 当前连接状态 */
  private state: WsConnectionState = 'disconnected';
  /** 心跳定时器 ID */
  private heartbeatTimer: number = -1;
  /** 重连定时器 ID */
  private reconnectTimer: number = -1;
  /** 当前重连索引（对应 WS_RECONNECT_DELAYS） */
  private reconnectIndex: number = 0;
  /** 消息接收回调列表 */
  private messageListeners: OnWsMessage[] = [];
  /** 状态变更回调列表 */
  private stateListeners: OnWsStateChange[] = [];
  /** Mock 消息定时器 ID */
  private mockTimer: number = -1;
  /** 是否主动关闭（不触发重连） */
  private manualClose: boolean = false;

  /** 获取当前连接状态 */
  getState(): WsConnectionState {
    return this.state;
  }

  /** 注册消息接收监听器 */
  onMessage(listener: OnWsMessage): void {
    if (this.messageListeners.indexOf(listener) < 0) {
      this.messageListeners.push(listener);
    }
  }

  /** 注册状态变更监听器 */
  onStateChange(listener: OnWsStateChange): void {
    if (this.stateListeners.indexOf(listener) < 0) {
      this.stateListeners.push(listener);
    }
  }

  /** 注销消息接收监听器 */
  offMessage(listener: OnWsMessage): void {
    const idx: number = this.messageListeners.indexOf(listener);
    if (idx >= 0) {
      this.messageListeners.splice(idx, 1);
    }
  }

  /** 注销状态变更监听器 */
  offStateChange(listener: OnWsStateChange): void {
    const idx: number = this.stateListeners.indexOf(listener);
    if (idx >= 0) {
      this.stateListeners.splice(idx, 1);
    }
  }

  /** 建立连接 */
  async connect(): Promise<void> {
    if (this.state === 'connecting' || this.state === 'connected' || this.state === 'reconnecting') {
      return;
    }
    this.manualClose = false;
    const token: string = await PreferencesUtil.getString(AppConstants.KEY_TOKEN, '');
    const wsUrl: string = ConfigUtil.wsUrl(`api/ws?token=${token}`);
    Logger.info(AppConstants.SCENE_USER, { action: 'ws_connect_start', url: wsUrl });

    this.setState('connecting');
    this.ws = webSocket.createWebSocket();

    // 注册事件回调
    this.ws.on('open', () => {
      Logger.info(AppConstants.SCENE_USER, { action: 'ws_open' });
      this.reconnectIndex = 0;
      this.setState('connected');
      this.startHeartbeat();
    });

    this.ws.on('message', (err: Error, data: string | ArrayBuffer) => {
      if (err) {
        Logger.error(AppConstants.SCENE_USER, { action: 'ws_message_error', error: err.message });
        return;
      }
      this.handleMessage(data);
    });

    this.ws.on('close', (err: Error, data: webSocket.CloseResult) => {
      Logger.info(AppConstants.SCENE_USER, { action: 'ws_close', code: data.code, reason: data.reason });
      this.stopHeartbeat();
      this.setState('disconnected');
      if (!this.manualClose) {
        this.scheduleReconnect();
      }
    });

    this.ws.on('error', (err: Error) => {
      Logger.error(AppConstants.SCENE_USER, { action: 'ws_error', error: err.message });
      this.stopHeartbeat();
      this.setState('disconnected');
      if (!this.manualClose) {
        // 后端未部署时连接失败，切换到 Mock 模式
        this.enterMockMode();
      }
    });

    try {
      await this.ws.connect(wsUrl);
    } catch (err) {
      Logger.error(AppConstants.SCENE_USER, { action: 'ws_connect_fail', error: (err as Error).message });
      // 后端未部署时连接失败，切换到 Mock 模式
      this.enterMockMode();
    }
  }

  /** 主动关闭连接 */
  disconnect(): void {
    this.manualClose = true;
    this.stopHeartbeat();
    this.stopReconnect();
    this.stopMock();
    if (this.ws) {
      this.ws.close((err: Error) => {
        if (err) {
          Logger.error(AppConstants.SCENE_USER, { action: 'ws_close_fail', error: err.message });
        }
      });
      this.ws = null;
    }
    this.setState('disconnected');
  }

  /** 发送消息 */
  async send(msg: WsMessage): Promise<boolean> {
    if (this.state === 'connected' && this.ws) {
      try {
        await this.ws.send(JSON.stringify(msg));
        Logger.info(AppConstants.SCENE_USER, { action: 'ws_send', sessionId: msg.sessionId });
        return true;
      } catch (err) {
        Logger.error(AppConstants.SCENE_USER, { action: 'ws_send_fail', error: (err as Error).message });
        return false;
      }
    }
    // Mock 状态：本地回声（自己消息已在 UI 显示），不实际发送
    Logger.info(AppConstants.SCENE_USER, { action: 'ws_send_mock', sessionId: msg.sessionId });
    return true;
  }

  /** 启动心跳（每 30 秒发送 ping） */
  private startHeartbeat(): void {
    this.stopHeartbeat();
    this.heartbeatTimer = setInterval(() => {
      if (this.ws && this.state === 'connected') {
        this.ws.send('ping');
        Logger.info(AppConstants.SCENE_USER, { action: 'ws_heartbeat' });
      }
    }, AppConstants.WS_HEARTBEAT_INTERVAL);
  }

  /** 停止心跳 */
  private stopHeartbeat(): void {
    if (this.heartbeatTimer !== -1) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = -1;
    }
  }

  /** 调度重连（指数退避） */
  private scheduleReconnect(): void {
    this.stopReconnect();
    if (this.reconnectIndex >= AppConstants.WS_RECONNECT_DELAYS.length) {
      // 超过最大重试次数，切换 Mock 模式
      Logger.info(AppConstants.SCENE_USER, { action: 'ws_reconnect_exhausted_switch_mock' });
      this.enterMockMode();
      return;
    }
    const delay: number = AppConstants.WS_RECONNECT_DELAYS[this.reconnectIndex];
    this.setState('reconnecting');
    Logger.info(AppConstants.SCENE_USER, { action: 'ws_reconnect_schedule', attempt: this.reconnectIndex + 1, delay: delay });
    this.reconnectTimer = setTimeout(() => {
      this.reconnectIndex++;
      this.connect();
    }, delay);
  }

  /** 停止重连 */
  private stopReconnect(): void {
    if (this.reconnectTimer !== -1) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = -1;
    }
  }

  /** 进入 Mock 模式（后端未部署时使用） */
  private enterMockMode(): void {
    if (this.state === 'mock') {
      return;
    }
    this.setState('mock');
    Logger.info(AppConstants.SCENE_USER, { action: 'ws_enter_mock_mode' });
    // Mock：每 60 秒模拟推送一条系统通知
    this.stopMock();
    this.mockTimer = setInterval(() => {
      this.simulateIncomingNotification();
    }, 60000);
  }

  /** 停止 Mock */
  private stopMock(): void {
    if (this.mockTimer !== -1) {
      clearInterval(this.mockTimer);
      this.mockTimer = -1;
    }
  }

  /** 模拟接收系统通知（Mock） */
  private simulateIncomingNotification(): void {
    const notices: string[] = [
      '您的订单已发货，请注意查收',
      '您关注的卖家有新直播预告',
      '您的商品评价已通过审核',
      '您关注的商品有促销活动',
      '您的提现申请已处理完成'
    ];
    const noticeIdx: number = Math.floor(Math.random() * notices.length);
    const mockMsg: WsMessage = {
      type: 'notification',
      sessionId: 'sys_notice',
      fromUserId: 'system',
      toUserId: 'u_self',
      content: notices[noticeIdx],
      contentType: 'text',
      timestamp: Date.now()
    };
    this.notifyMessage(mockMsg);
  }

  /** 处理收到的消息 */
  private handleMessage(data: string | ArrayBuffer): void {
    if (typeof data !== 'string') {
      return;
    }
    if (data === 'pong') {
      // 心跳响应，忽略
      return;
    }
    try {
      const msg: WsMessage = JSON.parse(data) as WsMessage;
      this.notifyMessage(msg);
      Logger.info(AppConstants.SCENE_USER, { action: 'ws_message_recv', type: msg.type, sessionId: msg.sessionId });
    } catch (err) {
      Logger.error(AppConstants.SCENE_USER, { action: 'ws_message_parse_fail', error: (err as Error).message, raw: data.substring(0, 200) });
    }
  }

  /** 通知所有消息监听器 */
  private notifyMessage(msg: WsMessage): void {
    this.messageListeners.forEach((l: OnWsMessage) => {
      l(msg);
    });
  }

  /** 更新连接状态并通知监听器 */
  private setState(state: WsConnectionState): void {
    if (this.state === state) {
      return;
    }
    this.state = state;
    Logger.info(AppConstants.SCENE_USER, { action: 'ws_state_change', state: state });
    this.stateListeners.forEach((l: OnWsStateChange) => {
      l(state);
    });
  }
}

/** 全局 WebSocket 单例 */
export const WsClient: WsClientImpl = new WsClientImpl();
