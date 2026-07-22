/**
 * api_key - API 密钥管理（spec 3.3.2 / 10.8.3.2）
 *
 * - 顶部"生成密钥"按钮 → 弹确认对话框 → 调 `ApiRepository.createApiKey()`
 *   → 返回 AppKey/AppSecret（仅展示一次，Secret 后续不可见）
 * - 密钥列表：AppKey + 状态（active/revoked）+ 创建时间 + 操作（吊销按钮）
 * - 吊销确认弹窗 + 调 `ApiRepository.revokeApiKey()`
 *
 * 越权防御（spec 10.8.8）：aboutToAppear 校验 super_admin / api_admin
 */

import { Logger, AppConstants, ToastUtil, TokenStore, AdminRoutes, NavigationHelper, RouteName, RouterParam, ListStateView } from 'common';
import { AdminInfo } from 'common';
import {
  ApiKey,
  CreateApiKeyResponse,
  ApiKeyStatus,
  AdminRole,
  API_KEY_STATUS_LABELS
} from '../../model/AdminModels';
import { ApiRepository } from '../../repository/ApiRepository';

@ComponentV2
export struct ApiKeyPage {
  /** 密钥列表 */
  @Local keys: ApiKey[] = [];
  /** 是否正在加载 */
  @Local isLoading: boolean = false;
  /** 是否正在生成 */
  @Local isCreating: boolean = false;
  /** 加载失败 */
  @Local loadFailed: boolean = false;
  /** 是否展示"生成密钥确认对话框" */
  @Local showCreateDialog: boolean = false;
  /** 是否展示"新密钥一次性展示对话框" */
  @Local showSecretDialog: boolean = false;
  /** 新创建的密钥响应（仅展示一次 Secret） */
  @Local newKeyResponse: CreateApiKeyResponse | null = null;
  /** 是否展示"吊销确认对话框" */
  @Local showRevokeDialog: boolean = false;
  /** 待吊销的密钥 ID */
  @Local pendingRevokeKeyId: string = '';
  /** 是否正在吊销 */
  @Local isRevoking: boolean = false;

  async aboutToAppear(): Promise<void> {
    // 越权防御（spec 10.8.8）
    const adminInfo: AdminInfo | null = await TokenStore.getAdminInfo();
    if (!adminInfo) {
      ToastUtil.warning('请先登录');
      NavigationHelper.replace(RouteName.ADMIN_LOGIN);
      return;
    }
    const allowedRoles: AdminRole[] = ['super_admin', 'api_admin'];
    if (allowedRoles.indexOf(adminInfo.role as AdminRole) < 0) {
      ToastUtil.warning('无权限访问该页面');
      NavigationHelper.pop();
      return;
    }
    Logger.info(AppConstants.SCENE_ADMIN, { action: 'api_key_appear', adminId: adminInfo.adminId, role: adminInfo.role });
    await this.loadKeys();
  }

  /** 加载密钥列表 */
  private async loadKeys(): Promise<void> {
    this.isLoading = true;
    this.loadFailed = false;
    try {
      this.keys = await ApiRepository.listApiKeys();
    } catch (err) {
      this.loadFailed = true;
      Logger.error(AppConstants.SCENE_ADMIN, { action: 'load_api_keys_fail', error: (err as Error).message });
    } finally {
      this.isLoading = false;
    }
  }

  /** 确认生成密钥（弹确认对话框） */
  private onClickCreate(): void {
    this.showCreateDialog = true;
  }

  /** 执行生成密钥 */
  private async doCreate(): Promise<void> {
    this.showCreateDialog = false;
    this.isCreating = true;
    try {
      const response: CreateApiKeyResponse = await ApiRepository.createApiKey();
      this.newKeyResponse = response;
      this.showSecretDialog = true;
      // 刷新列表
      await this.loadKeys();
      Logger.info(AppConstants.SCENE_ADMIN, { action: 'api_key_create', keyId: response.keyId });
    } catch (err) {
      Logger.error(AppConstants.SCENE_ADMIN, { action: 'api_key_create_fail', error: (err as Error).message });
      ToastUtil.error('生成失败');
    } finally {
      this.isCreating = false;
    }
  }

  /** 关闭新密钥对话框 */
  private closeSecretDialog(): void {
    this.showSecretDialog = false;
    this.newKeyResponse = null;
  }

  /** 点击吊销 */
  private onClickRevoke(keyId: string): void {
    this.pendingRevokeKeyId = keyId;
    this.showRevokeDialog = true;
  }

  /** 执行吊销 */
  private async doRevoke(): Promise<void> {
    this.showRevokeDialog = false;
    if (this.pendingRevokeKeyId.length === 0) {
      return;
    }
    this.isRevoking = true;
    try {
      await ApiRepository.revokeApiKey(this.pendingRevokeKeyId);
      ToastUtil.success('已吊销');
      Logger.info(AppConstants.SCENE_ADMIN, { action: 'api_key_revoke', keyId: this.pendingRevokeKeyId });
      // 本地状态更新（避免重新拉取）
      const keyId: string = this.pendingRevokeKeyId;
      this.keys = this.keys.map((k: ApiKey): ApiKey => {
        if (k.keyId === keyId) {
          const updated: ApiKey = {
            keyId: k.keyId,
            appKey: k.appKey,
            status: 'revoked',
            createdAt: k.createdAt,
            revokedAt: Date.now()
          };
          return updated;
        }
        return k;
      });
    } catch (err) {
      Logger.error(AppConstants.SCENE_ADMIN, { action: 'api_key_revoke_fail', error: (err as Error).message });
      ToastUtil.error('吊销失败');
    } finally {
      this.isRevoking = false;
      this.pendingRevokeKeyId = '';
    }
  }

  /** 复制到剪贴板（Mock 提示） */
  private copyToClipboard(text: string): void {
    // HarmonyOS 可使用 pasteboard 服务，此处仅 Mock 提示
    ToastUtil.success('已复制（Mock）');
    Logger.info(AppConstants.SCENE_ADMIN, { action: 'api_key_copy', length: text.length });
  }

  /** 格式化时间 */
  private formatTime(ts: number): string {
    const d: Date = new Date(ts);
    const y: number = d.getFullYear();
    const m: string = (d.getMonth() + 1).toString().padStart(2, '0');
    const day: string = d.getDate().toString().padStart(2, '0');
    const hh: string = d.getHours().toString().padStart(2, '0');
    const mi: string = d.getMinutes().toString().padStart(2, '0');
    return `${y}-${m}-${day} ${hh}:${mi}`;
  }

  /** 状态文字色 */
  private statusColor(status: ApiKeyStatus): Resource {
    if (status === 'active') {
      return $r('app.color.color_primary');
    }
    return $r('app.color.color_text_hint');
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          this.TopBar()
          this.NoticeBar()
          if (this.loadFailed) {
            ListStateView({ state: 'error', onRefresh: () => this.loadKeys() })
          } else if (this.keys.length === 0 && !this.isLoading) {
            this.EmptyView()
          } else {
            this.KeyListView()
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.color_bg_page'))

        // 生成密钥确认对话框
        if (this.showCreateDialog) {
          this.CreateConfirmDialog()
        }
        // 新密钥一次性展示对话框
        if (this.showSecretDialog && this.newKeyResponse) {
          this.SecretDialog()
        }
        // 吊销确认对话框
        if (this.showRevokeDialog) {
          this.RevokeConfirmDialog()
        }
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
  }

  /** 顶部导航 */
  @Builder
  TopBar() {
    Row({ space: 12 }) {
      Text('‹')
        .fontSize(28)
        .fontColor($r('app.color.color_text_primary'))
        .onClick(() => NavigationHelper.pop())
      Text('API 密钥')
        .fontSize(18)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
      Button(this.isCreating ? '生成中...' : '生成密钥')
        .height(36)
        .borderRadius(18)
        .backgroundColor(this.isCreating ? $r('app.color.color_button_disabled') : $r('app.color.color_primary'))
        .fontColor(Color.White)
        .fontSize(12)
        .enabled(!this.isCreating)
        .onClick(() => this.onClickCreate())
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** 提示栏 */
  @Builder
  NoticeBar() {
    Row({ space: 6 }) {
      Text('⚠️')
        .fontSize(12)
      Text('AppSecret 仅在创建时展示一次，请妥善保存；后续将无法再次查看')
        .fontSize(11)
        .fontColor($r('app.color.color_secondary'))
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor('rgba(255,213,79,0.15)')
  }

  /** 密钥列表 */
  @Builder
  KeyListView() {
    List({ space: 8 }) {
      ForEach(this.keys, (key: ApiKey) => {
        ListItem() {
          this.KeyItemCard(key)
        }
      }, (key: ApiKey) => key.keyId)
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 12, right: 12, top: 8, bottom: 12 })
    .scrollBar(BarState.Off)
  }

  /** 密钥卡片 */
  @Builder
  KeyItemCard(key: ApiKey) {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text('AppKey')
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
        Text(key.appKey)
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        // 复制按钮
        Text('📋')
          .fontSize(16)
          .onClick(() => this.copyToClipboard(key.appKey))
      }
      .width('100%')

      Row({ space: 12 }) {
        Text(`状态：${API_KEY_STATUS_LABELS[key.status]}`)
          .fontSize(11)
          .fontColor(this.statusColor(key.status))
        Text(`创建：${this.formatTime(key.createdAt)}`)
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
          .layoutWeight(1)
      }
      .width('100%')

      if (key.status === 'revoked' && key.revokedAt) {
        Text(`吊销时间：${this.formatTime(key.revokedAt)}`)
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
          .width('100%')
      }

      if (key.status === 'active') {
        Button('吊销')
          .width('100%')
          .height(32)
          .borderRadius(16)
          .backgroundColor($r('app.color.color_bg_page'))
          .fontColor($r('app.color.color_error'))
          .fontSize(12)
          .enabled(!this.isRevoking)
          .onClick(() => this.onClickRevoke(key.keyId))
      } else {
        Text('已吊销，无法恢复')
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
          .width('100%')
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 空状态 */
  @Builder
  EmptyView() {
    Column({ space: 12 }) {
      Text('🔑')
        .fontSize(64)
      Text('暂无 API 密钥')
        .fontSize(14)
        .fontColor($r('app.color.color_text_secondary'))
      Text('点击右上角"生成密钥"按钮创建第一个密钥')
        .fontSize(11)
        .fontColor($r('app.color.color_text_hint'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  /** 生成密钥确认对话框 */
  @Builder
  CreateConfirmDialog() {
    Stack({ alignContent: Alignment.Center }) {
      // 遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => { this.showCreateDialog = false; })

      // 对话框内容
      Column({ space: 12 }) {
        Text('确认生成新密钥？')
          .fontSize(16)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Medium)
        Text('生成后 AppSecret 仅展示一次，请确保已准备好保存。建议在私密环境下操作。')
          .fontSize(12)
          .fontColor($r('app.color.color_text_secondary'))
          .width('100%')
        Row({ space: 8 }) {
          Button('取消')
            .layoutWeight(1)
            .height(40)
            .borderRadius(20)
            .backgroundColor($r('app.color.color_bg_page'))
            .fontColor($r('app.color.color_text_primary'))
            .fontSize(14)
            .onClick(() => { this.showCreateDialog = false; })
          Button('确认生成')
            .layoutWeight(1)
            .height(40)
            .borderRadius(20)
            .backgroundColor($r('app.color.color_primary'))
            .fontColor(Color.White)
            .fontSize(14)
            .onClick(() => { this.doCreate(); })
        }
        .width('100%')
      }
      .width('80%')
      .padding(20)
      .borderRadius(12)
      .backgroundColor($r('app.color.color_bg_card'))
    }
    .width('100%')
    .height('100%')
  }

  /** 新密钥一次性展示对话框 */
  @Builder
  SecretDialog() {
    Stack({ alignContent: Alignment.Center }) {
      // 遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.7)')

      // 对话框内容
      Column({ space: 12 }) {
        Row({ space: 6 }) {
          Text('🎉')
            .fontSize(16)
          Text('密钥生成成功')
            .fontSize(16)
            .fontColor($r('app.color.color_primary'))
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
        }
        .width('100%')

        Text('⚠️ 请立即保存以下信息，AppSecret 后续将无法再次查看！')
          .fontSize(11)
          .fontColor($r('app.color.color_error'))
          .width('100%')

        // AppKey
        Column({ space: 4 }) {
          Text('AppKey')
            .fontSize(11)
            .fontColor($r('app.color.color_text_hint'))
          Row({ space: 8 }) {
            Text(this.newKeyResponse!.appKey)
              .fontSize(13)
              .fontColor($r('app.color.color_text_primary'))
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
            Text('📋')
              .fontSize(16)
              .onClick(() => this.copyToClipboard(this.newKeyResponse!.appKey))
          }
          .width('100%')
          .padding(8)
          .borderRadius(8)
          .backgroundColor($r('app.color.color_bg_page'))
        }
        .width('100%')

        // AppSecret
        Column({ space: 4 }) {
          Text('AppSecret（仅此一次）')
            .fontSize(11)
            .fontColor($r('app.color.color_error'))
          Row({ space: 8 }) {
            Text(this.newKeyResponse!.appSecret)
              .fontSize(13)
              .fontColor($r('app.color.color_error'))
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)
            Text('📋')
              .fontSize(16)
              .onClick(() => this.copyToClipboard(this.newKeyResponse!.appSecret))
          }
          .width('100%')
          .padding(8)
          .borderRadius(8)
          .backgroundColor('rgba(244,67,54,0.08)')
        }
        .width('100%')

        Button('我已保存')
          .width('100%')
          .height(40)
          .borderRadius(20)
          .backgroundColor($r('app.color.color_primary'))
          .fontColor(Color.White)
          .fontSize(14)
          .onClick(() => this.closeSecretDialog())
      }
      .width('85%')
      .padding(20)
      .borderRadius(12)
      .backgroundColor($r('app.color.color_bg_card'))
    }
    .width('100%')
    .height('100%')
  }

  /** 吊销确认对话框 */
  @Builder
  RevokeConfirmDialog() {
    Stack({ alignContent: Alignment.Center }) {
      // 遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => { this.showRevokeDialog = false; })

      // 对话框内容
      Column({ space: 12 }) {
        Text('确认吊销该密钥？')
          .fontSize(16)
          .fontColor($r('app.color.color_error'))
          .fontWeight(FontWeight.Medium)
        Text('吊销后该 AppKey 将立即失效，使用该密钥的所有第三方应用将无法访问接口。此操作不可逆。')
          .fontSize(12)
          .fontColor($r('app.color.color_text_secondary'))
          .width('100%')
        Row({ space: 8 }) {
          Button('取消')
            .layoutWeight(1)
            .height(40)
            .borderRadius(20)
            .backgroundColor($r('app.color.color_bg_page'))
            .fontColor($r('app.color.color_text_primary'))
            .fontSize(14)
            .onClick(() => { this.showRevokeDialog = false; })
          Button('确认吊销')
            .layoutWeight(1)
            .height(40)
            .borderRadius(20)
            .backgroundColor($r('app.color.color_error'))
            .fontColor(Color.White)
            .fontSize(14)
            .onClick(() => { this.doRevoke(); })
        }
        .width('100%')
      }
      .width('80%')
      .padding(20)
      .borderRadius(12)
      .backgroundColor($r('app.color.color_bg_card'))
    }
    .width('100%')
    .height('100%')
  }
}
