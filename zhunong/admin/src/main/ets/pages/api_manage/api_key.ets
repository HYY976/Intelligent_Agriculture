/**
 * api_key - API 密钥管理（spec 3.3.2 / 10.8.3.2，对齐 api-key.html 设计稿）
 *
 * - 顶栏：圆形返回键 + 居中标题"API密钥" + 右侧黄色"生成密钥"按钮
 * - 提示栏：浅黄底警告"Secret密钥仅在创建时展示一次，请妥善保存"
 * - 密钥卡：AppKey(mono) + 状态pill(启用/已吊销) + 创建时间/最后使用 + 复制AppKey/吊销按钮
 * - 生成确认弹窗 + 新密钥一次性展示弹窗（AppKey/AppSecret + 复制按钮）
 * - 吊销确认弹窗
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
            lastUsedAt: k.lastUsedAt,
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
    ToastUtil.success('已复制');
    Logger.info(AppConstants.SCENE_ADMIN, { action: 'api_key_copy', length: text.length });
  }

  /** 格式化日期（YYYY-MM-DD） */
  private formatDate(ts: number): string {
    if (ts === 0) {
      return '—';
    }
    const d: Date = new Date(ts);
    const y: number = d.getFullYear();
    const m: string = (d.getMonth() + 1).toString().padStart(2, '0');
    const day: string = d.getDate().toString().padStart(2, '0');
    return `${y}-${m}-${day}`;
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
        .backgroundColor($r('app.color.color_cream'))

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

  /** 顶部导航：圆形返回键 + 居中标题 + 右侧黄色生成按钮 */
  @Builder
  TopBar() {
    Row() {
      // 圆形返回键
      Stack() {
        Text('‹')
          .fontSize(22)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .width(32)
      .height(32)
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor($r('app.color.color_bg_card'))
      .shadow(AppConstants.SHADOW_CARD)
      .onClick(() => NavigationHelper.pop())

      // 居中标题
      Text('API密钥')
        .fontSize(17)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 右侧黄色生成按钮
      Row({ space: 4 }) {
        Text('+')
          .fontSize(16)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        Text(this.isCreating ? '生成中' : '生成密钥')
          .fontSize(12)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .height(32)
      .padding({ left: 12, right: 12 })
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor($r('app.color.color_primary'))
      .opacity(this.isCreating ? 0.6 : 1)
      .onClick(() => { if (!this.isCreating) this.onClickCreate(); })
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16, top: 4, bottom: 10 })
    .alignItems(VerticalAlign.Center)
  }

  /** 提示栏（浅黄底警告） */
  @Builder
  NoticeBar() {
    Row({ space: 8 }) {
      Text('⚠')
        .fontSize(14)
        .fontColor('#B8860B')
      Text('Secret密钥仅在创建时展示一次，请妥善保存')
        .fontSize(12)
        .fontColor($r('app.color.color_text_2'))
        .layoutWeight(1)
        .lineHeight(18)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .margin({ left: 16, right: 16, top: 4 })
    .borderRadius(AppConstants.RADIUS_MD)
    .backgroundColor($r('app.color.color_yellow_tint'))
    .alignItems(VerticalAlign.Top)
  }

  /** 密钥列表 */
  @Builder
  KeyListView() {
    Scroll() {
      Column({ space: 10 }) {
        ForEach(this.keys, (key: ApiKey) => {
          this.KeyItemCard(key)
        }, (key: ApiKey) => key.keyId)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 24 })
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  /** 密钥卡片（对齐 api-key.html 设计稿） */
  @Builder
  KeyItemCard(key: ApiKey) {
    Column({ space: 8 }) {
      // 顶行：AppKey + 状态 pill
      Row() {
        Text(key.appKey)
          .fontSize(13)
          .fontColor(key.status === 'revoked' ? $r('app.color.color_text_3') : $r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 状态 pill
        this.StatusPill(key.status)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // meta 行：创建时间 + 最后使用
      Column({ space: 2 }) {
        Row() {
          Text('创建时间')
            .fontSize(12)
            .fontColor($r('app.color.color_text_4'))
            .margin({ right: 4 })
          Text(this.formatDate(key.createdAt))
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
        }
        .width('100%')

        Row() {
          Text('最后使用')
            .fontSize(12)
            .fontColor($r('app.color.color_text_4'))
            .margin({ right: 4 })
          Text(this.formatDate(key.lastUsedAt))
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
        }
        .width('100%')
      }
      .width('100%')
      .margin({ top: 8 })

      // 操作行：复制 AppKey + 吊销
      Row({ space: 8 }) {
        // 复制 AppKey（灰线框按钮）
        Row({ space: 4 }) {
          Text('⧉')
            .fontSize(13)
            .fontColor($r('app.color.color_text_2'))
          Text('复制AppKey')
            .fontSize(12)
            .fontColor($r('app.color.color_text_2'))
            .fontWeight(FontWeight.Medium)
        }
        .height(30)
        .padding({ left: 12, right: 12 })
        .borderRadius(AppConstants.RADIUS_SM)
        .backgroundColor($r('app.color.color_bg_card'))
        .border({ width: 1, color: $r('app.color.color_line_2') })
        .alignItems(VerticalAlign.Center)
        .onClick(() => this.copyToClipboard(key.appKey))

        // 吊销按钮（红色字，已吊销时 disabled）
        Row({ space: 4 }) {
          Text('✕')
            .fontSize(13)
            .fontColor(key.status === 'revoked' ? $r('app.color.color_text_4') : $r('app.color.color_live'))
          Text('吊销')
            .fontSize(12)
            .fontColor(key.status === 'revoked' ? $r('app.color.color_text_4') : $r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
        }
        .height(30)
        .padding({ left: 12, right: 12 })
        .borderRadius(AppConstants.RADIUS_SM)
        .opacity(key.status === 'revoked' ? 0.4 : 1)
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          if (key.status === 'active' && !this.isRevoking) {
            this.onClickRevoke(key.keyId);
          }
        })
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(14)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }

  /** 状态 pill */
  @Builder
  StatusPill(status: ApiKeyStatus) {
    Row({ space: 4 }) {
      if (status === 'active') {
        Text('✓')
          .fontSize(10)
          .fontColor($r('app.color.color_green_deep'))
          .fontWeight(FontWeight.Bold)
      } else {
        Text('⊘')
          .fontSize(10)
          .fontColor($r('app.color.color_text_2'))
      }
      Text(API_KEY_STATUS_LABELS[status])
        .fontSize(11)
        .fontColor(status === 'active' ? $r('app.color.color_green_deep') : $r('app.color.color_text_2'))
        .fontWeight(FontWeight.Medium)
    }
    .padding({ left: 10, right: 10, top: 3, bottom: 3 })
    .borderRadius(AppConstants.RADIUS_PILL)
    .backgroundColor(status === 'active' ? $r('app.color.color_green_soft') : $r('app.color.color_fill'))
    .alignItems(VerticalAlign.Center)
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

  /** 生成密钥确认对话框（居中，对齐设计稿） */
  @Builder
  CreateConfirmDialog() {
    Stack({ alignContent: Alignment.Center }) {
      // 遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(26,26,26,0.45)')
        .onClick(() => { this.showCreateDialog = false; })

      // 对话框内容
      Column({ space: 8 }) {
        Text('生成新密钥')
          .fontSize(17)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .textAlign(TextAlign.Center)

        Text('将创建一对新的AppKey/AppSecret')
          .fontSize(13)
          .fontColor($r('app.color.color_text_2'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .lineHeight(20)

        Row({ space: 10 }) {
          Button('取消')
            .layoutWeight(1)
            .height(42)
            .borderRadius(AppConstants.RADIUS_MD)
            .backgroundColor($r('app.color.color_fill'))
            .fontColor($r('app.color.color_text_2'))
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .onClick(() => { this.showCreateDialog = false; })
          Button('确定')
            .layoutWeight(1)
            .height(42)
            .borderRadius(AppConstants.RADIUS_MD)
            .backgroundColor($r('app.color.color_ink'))
            .fontColor(Color.White)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .onClick(() => { this.doCreate(); })
        }
        .width('100%')
        .margin({ top: 18 })
      }
      .width('80%')
      .padding({ left: 18, right: 18, top: 20, bottom: 18 })
      .borderRadius(AppConstants.RADIUS_LG)
      .backgroundColor($r('app.color.color_bg_card'))
      .shadow(AppConstants.SHADOW_FLOAT)
    }
    .width('100%')
    .height('100%')
  }

  /** 新密钥一次性展示对话框（对齐设计稿） */
  @Builder
  SecretDialog() {
    Stack({ alignContent: Alignment.Center }) {
      // 遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(26,26,26,0.45)')

      // 对话框内容
      Column({ space: 10 }) {
        Text('密钥创建成功')
          .fontSize(17)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .textAlign(TextAlign.Center)

        // 黄底警告条
        Row({ space: 6 }) {
          Text('⚠')
            .fontSize(14)
            .fontColor('#B8860B')
          Text('AppSecret 仅展示一次，关闭后无法再次查看')
            .fontSize(12)
            .fontColor('#B8860B')
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 10, right: 10, top: 8, bottom: 8 })
        .margin({ top: 10 })
        .borderRadius(AppConstants.RADIUS_SM)
        .backgroundColor($r('app.color.color_yellow_tint'))
        .alignItems(VerticalAlign.Center)

        // AppKey 行（灰底）
        Row() {
          Column() {
            Text('AppKey')
              .fontSize(11)
              .fontColor($r('app.color.color_text_3'))
              .fontWeight(FontWeight.Medium)
            Text(this.newKeyResponse!.appKey)
              .fontSize(12)
              .fontColor($r('app.color.color_ink'))
              .fontWeight(FontWeight.Bold)
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // 复制按钮
          Stack() {
            Text('⧉')
              .fontSize(15)
              .fontColor($r('app.color.color_text_2'))
          }
          .width(30)
          .height(30)
          .borderRadius(AppConstants.RADIUS_XS)
          .backgroundColor($r('app.color.color_bg_card'))
          .shadow(AppConstants.SHADOW_CARD)
          .onClick(() => this.copyToClipboard(this.newKeyResponse!.appKey))
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .margin({ top: 12 })
        .borderRadius(AppConstants.RADIUS_SM)
        .backgroundColor($r('app.color.color_fill'))
        .alignItems(VerticalAlign.Center)

        // AppSecret 行（黄底）
        Row() {
          Column() {
            Text('AppSecret')
              .fontSize(11)
              .fontColor($r('app.color.color_text_3'))
              .fontWeight(FontWeight.Medium)
            Text(this.newKeyResponse!.appSecret)
              .fontSize(12)
              .fontColor($r('app.color.color_ink'))
              .fontWeight(FontWeight.Bold)
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // 复制按钮
          Stack() {
            Text('⧉')
              .fontSize(15)
              .fontColor($r('app.color.color_text_2'))
          }
          .width(30)
          .height(30)
          .borderRadius(AppConstants.RADIUS_XS)
          .backgroundColor($r('app.color.color_bg_card'))
          .shadow(AppConstants.SHADOW_CARD)
          .onClick(() => this.copyToClipboard(this.newKeyResponse!.appSecret))
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .borderRadius(AppConstants.RADIUS_SM)
        .backgroundColor($r('app.color.color_yellow_tint'))
        .alignItems(VerticalAlign.Center)

        // 我已保存按钮
        Button('我已保存')
          .width('100%')
          .height(42)
          .borderRadius(AppConstants.RADIUS_MD)
          .backgroundColor($r('app.color.color_ink'))
          .fontColor(Color.White)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 18 })
          .onClick(() => this.closeSecretDialog())
      }
      .width('85%')
      .padding({ left: 18, right: 18, top: 20, bottom: 18 })
      .borderRadius(AppConstants.RADIUS_LG)
      .backgroundColor($r('app.color.color_bg_card'))
      .shadow(AppConstants.SHADOW_FLOAT)
    }
    .width('100%')
    .height('100%')
  }

  /** 吊销确认对话框（对齐设计稿） */
  @Builder
  RevokeConfirmDialog() {
    Stack({ alignContent: Alignment.Center }) {
      // 遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(26,26,26,0.45)')
        .onClick(() => { this.showRevokeDialog = false; })

      // 对话框内容
      Column({ space: 8 }) {
        Text('确认吊销该密钥？')
          .fontSize(17)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .textAlign(TextAlign.Center)

        Text('吊销后该 AppKey 将立即失效，使用该密钥的所有第三方应用将无法访问接口。此操作不可逆。')
          .fontSize(13)
          .fontColor($r('app.color.color_text_2'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .lineHeight(20)

        Row({ space: 10 }) {
          Button('取消')
            .layoutWeight(1)
            .height(42)
            .borderRadius(AppConstants.RADIUS_MD)
            .backgroundColor($r('app.color.color_fill'))
            .fontColor($r('app.color.color_text_2'))
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .onClick(() => { this.showRevokeDialog = false; })
          Button('确认吊销')
            .layoutWeight(1)
            .height(42)
            .borderRadius(AppConstants.RADIUS_MD)
            .backgroundColor($r('app.color.color_live'))
            .fontColor(Color.White)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .onClick(() => { this.doRevoke(); })
        }
        .width('100%')
        .margin({ top: 18 })
      }
      .width('80%')
      .padding({ left: 18, right: 18, top: 20, bottom: 18 })
      .borderRadius(AppConstants.RADIUS_LG)
      .backgroundColor($r('app.color.color_bg_card'))
      .shadow(AppConstants.SHADOW_FLOAT)
    }
    .width('100%')
    .height('100%')
  }
}
