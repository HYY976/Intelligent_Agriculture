/**
 * live_create - 开播表单（spec 3.2.4.3 / spec 16.4 注册身份同步）
 *
 * 开播表单字段：
 *  - 直播标题（必填）
 *  - 直播封面图（必填，单图上传）
 *  - 商品袋选择（多选已上架商品，可选）
 *  - 直播分类（必填，生鲜/粮油/肉禽/茶饮/其他）
 *  - 开播介绍（可选，200字内）
 *
 * 点击"开始直播" → 进入直播间页 pages/live/live_room?liveId=xxx&role=broadcaster
 * spec 16.4：主播昵称、头像使用 TokenStore 中的注册身份信息
 */

import { Logger, AppConstants, ToastUtil, FarmerRoutes, NavigationHelper, RouteName, PageResult, TokenStore } from 'common';
import { LiveCategory, LiveCreateForm, FarmerProductItem, LIVE_CATEGORY_LABELS } from '../../model/FarmerModels';
import { LiveManageRepository } from '../../repository/LiveManageRepository';
import { ProductManageRepository } from '../../repository/ProductManageRepository';
import { MOCK_FARMER_ID, MOCK_FARMER_PROFILE } from '../../mock/FarmerMock';
import { BailianClient } from '../../utils/BailianClient';
import { ImagePickerUtil } from '../../utils/ImagePickerUtil';

/** 分类选项 */
interface CategoryOption {
  value: LiveCategory;
  label: string;
}

/** 跳转直播间页的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface LiveRoomParam {
  liveId: string;
  role: string;
}

@ComponentV2
export struct LiveCreate {
  /** 直播标题 */
  @Local title: string = '';
  /** 直播封面图 key */
  @Local coverImage: string = '';
  /** 商品袋商品ID数组 */
  @Local productBag: string[] = [];
  /** 直播分类 */
  @Local category: LiveCategory = 'fresh';
  /** 开播介绍 */
  @Local intro: string = '';
  /** 是否正在提交 */
  @Local isSubmitting: boolean = false;
  /** 可选商品列表（已上架） */
  @Local availableProducts: FarmerProductItem[] = [];
  /** 商品袋选择面板是否展开 */
  @Local bagPanelOpen: boolean = false;
  /** 主播昵称（spec 16.4：从 TokenStore 加载，回退 MOCK_FARMER_PROFILE.shopName） */
  @Local anchorName: string = MOCK_FARMER_PROFILE.shopName;
  /** 主播头像（spec 16.4：从 TokenStore 加载，回退 MOCK_FARMER_PROFILE.shopLogo） */
  @Local anchorAvatar: string = MOCK_FARMER_PROFILE.shopLogo;
  /** spec 16.7：AI 优化中 */
  @Local isAiOptimizing: boolean = false;

  /** 分类选项 */
  private categoryOptions: CategoryOption[] = [
    { value: 'fresh', label: LIVE_CATEGORY_LABELS['fresh'] },
    { value: 'grain', label: LIVE_CATEGORY_LABELS['grain'] },
    { value: 'meat', label: LIVE_CATEGORY_LABELS['meat'] },
    { value: 'tea', label: LIVE_CATEGORY_LABELS['tea'] },
    { value: 'other', label: LIVE_CATEGORY_LABELS['other'] }
  ];

  async aboutToAppear(): Promise<void> {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'live_create_appear' });
    // spec 16.4：加载注册身份信息
    try {
      const userInfo = await TokenStore.getUserInfo();
      if (userInfo !== null) {
        if (userInfo.nickname.length > 0) {
          this.anchorName = userInfo.nickname;
        }
        if (userInfo.avatar.length > 0) {
          this.anchorAvatar = userInfo.avatar;
        }
        Logger.info(AppConstants.SCENE_FARMER, {
          action: 'live_create_load_user_info',
          nickname: this.anchorName
        });
      }
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, {
        action: 'load_user_info_fail',
        error: (err as Error).message
      });
    }
    await this.loadAvailableProducts();
  }

  /** 加载可加入商品袋的已上架商品 */
  private async loadAvailableProducts(): Promise<void> {
    try {
      const result: PageResult<FarmerProductItem> = await ProductManageRepository.getMyProducts(MOCK_FARMER_ID, 1, 50, 'approved');
      this.availableProducts = result.list.filter((p: FarmerProductItem): boolean => p.status === 'approved');
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'load_products_fail', error: (err as Error).message });
    }
  }

  /** spec 16.7：上传封面图（调起系统图库选择本地图片） */
  private uploadCover(): void {
    ImagePickerUtil.pickSingleImage(
      (uri: string) => {
        this.coverImage = uri;
        ToastUtil.success('封面已选择');
        Logger.info(AppConstants.SCENE_FARMER, {
          action: 'live_cover_picked',
          url: uri
        });
      },
      (msg: string) => {
        Logger.warn(AppConstants.SCENE_FARMER, {
          action: 'live_cover_pick_fail',
          error: msg
        });
        // 图库不可用时回退到 Mock 封面，保证流程可用
        const covers: string[] = ['live_cover_1', 'live_cover_2', 'live_cover_3', 'live_cover_4', 'live_cover_5'];
        const idx: number = Math.floor(Math.random() * covers.length);
        this.coverImage = covers[idx];
        ToastUtil.warning(msg || '图库不可用，已使用默认封面');
      }
    );
  }

  /** 切换商品袋商品选中状态 */
  private toggleProduct(productId: string): void {
    const idx: number = this.productBag.indexOf(productId);
    if (idx >= 0) {
      this.productBag.splice(idx, 1);
    } else {
      if (this.productBag.length >= 20) {
        ToastUtil.warning('商品袋最多 20 件');
        return;
      }
      this.productBag.push(productId);
    }
  }

  /** 校验 */
  private validateForm(): boolean {
    if (this.title.length === 0) {
      ToastUtil.warning('请填写直播标题');
      return false;
    }
    if (this.coverImage.length === 0) {
      ToastUtil.warning('请上传直播封面图');
      return false;
    }
    return true;
  }

  /** spec 16.7：AI 优化开播介绍（调用阿里云百炼直播智能体） */
  private async optimizeIntroWithAi(): Promise<void> {
    if (this.isAiOptimizing) {
      return;
    }
    if (this.intro.trim().length === 0) {
      ToastUtil.warning('请先输入开播介绍');
      return;
    }
    this.isAiOptimizing = true;
    Logger.info(AppConstants.SCENE_FARMER, {
      action: 'live_intro_ai_optimize_start',
      count: this.intro.length
    });
    BailianClient.optimizeLiveIntro(
      this.intro,
      (text: string) => {
        this.isAiOptimizing = false;
        // 优化结果若超过 200 字限制则截断
        const truncated: string = text.length > 200 ? text.substring(0, 200) : text;
        this.intro = truncated;
        ToastUtil.success('AI 优化完成');
        Logger.info(AppConstants.SCENE_FARMER, {
          action: 'live_intro_ai_optimize_done',
          count: truncated.length
        });
      },
      (msg: string) => {
        this.isAiOptimizing = false;
        ToastUtil.error(msg ?? 'AI 优化失败，请稍后重试');
        Logger.error(AppConstants.SCENE_FARMER, {
          action: 'live_intro_ai_optimize_fail',
          error: msg
        });
      }
    );
  }

  /** 开始直播（spec 16.4：携带注册身份信息） */
  private async startLive(): Promise<void> {
    if (!this.validateForm()) {
      return;
    }
    this.isSubmitting = true;
    try {
      const form: LiveCreateForm = {
        title: this.title,
        coverImage: this.coverImage,
        productBag: this.productBag,
        category: this.category,
        intro: this.intro
      };
      const liveId: string = await LiveManageRepository.createLive(
        MOCK_FARMER_ID,
        form,
        this.anchorName,
        this.anchorAvatar
      );
      ToastUtil.success('直播已开启');
      Logger.info(AppConstants.SCENE_FARMER, {
        action: 'live_create_success',
        liveId,
        anchorName: this.anchorName
      });
      // 替换当前页跳转直播间（避免返回回到表单）
      const param: LiveRoomParam = { liveId: liveId, role: 'broadcaster' };
      NavigationHelper.replace(RouteName.FARMER_LIVE_ROOM, param);
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'live_create_fail', error: (err as Error).message });
      ToastUtil.error('开播失败，请稍后重试');
    } finally {
      this.isSubmitting = false;
    }
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        Scroll() {
          Column({ space: 16 }) {
            this.CoverSection()
            this.BasicInfoSection()
            this.CategorySection()
            this.IntroSection()
            this.ProductBagSection()
            // 开始直播按钮
            Button(this.isSubmitting ? '正在开播...' : '🔴 开始直播')
              .width('100%')
              .height(48)
              .borderRadius(24)
              .backgroundColor(this.isSubmitting ? $r('app.color.color_button_disabled') : $r('app.color.color_cta_black'))
              .fontColor(Color.White)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .enabled(!this.isSubmitting)
              .margin({ top: 8, bottom: 24 })
              .onClick(() => { this.startLive(); })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
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
      Text('创建直播')
        .fontSize(18)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** 封面上传（spec 16.7：支持显示本地选取的图片） */
  @Builder
  CoverSection() {
    Column({ space: 12 }) {
      Text('* 直播封面')
        .fontSize(14)
        .fontColor($r('app.color.color_text_secondary'))
        .alignSelf(ItemAlign.Start)
      if (this.coverImage.length === 0) {
        Stack() {
          Column({ space: 8 }) {
            Text('📷')
              .fontSize(40)
            Text('点击上传封面')
              .fontSize(12)
              .fontColor($r('app.color.color_text_hint'))
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .height(180)
        .borderRadius(12)
        .backgroundColor($r('app.color.color_bg_page'))
        .alignContent(Alignment.Center)
        .onClick(() => this.uploadCover())
      } else {
        Stack() {
          // spec 16.7：若为 file:// 或 http(s) URI 则直接渲染真实图片，否则显示 emoji 占位
          if (this.coverImage.startsWith('file://') || this.coverImage.startsWith('http://') || this.coverImage.startsWith('https://')) {
            Image(this.coverImage)
              .width('100%')
              .height(180)
              .objectFit(ImageFit.Cover)
              .borderRadius(12)
          } else {
            Text('📹')
              .fontSize(60)
          }
          Text('重新上传')
            .fontSize(12)
            .fontColor(Color.White)
            .backgroundColor('rgba(0,0,0,0.6)')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(8)
            .position({ x: 8, y: 8 })
        }
        .width('100%')
        .height(180)
        .borderRadius(12)
        .backgroundColor($r('app.color.color_bg_panel_dark'))
        .alignContent(Alignment.Center)
        .onClick(() => this.uploadCover())
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 基础信息 */
  @Builder
  BasicInfoSection() {
    Column({ space: 12 }) {
      Text('基础信息')
        .fontSize(14)
        .fontColor($r('app.color.color_text_secondary'))
        .alignSelf(ItemAlign.Start)
      Column({ space: 6 }) {
        Text('* 直播标题')
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
          .alignSelf(ItemAlign.Start)
        TextInput({ text: this.title, placeholder: '如：高山有机青菜采摘直播' })
          .height(44)
          .borderRadius(8)
          .backgroundColor($r('app.color.color_bg_page'))
          .padding({ left: 12, right: 12 })
          .fontSize(14)
          .maxLength(50)
          .onChange((v: string) => { this.title = v; })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 分类 */
  @Builder
  CategorySection() {
    Column({ space: 12 }) {
      Text('* 直播分类')
        .fontSize(14)
        .fontColor($r('app.color.color_text_secondary'))
        .alignSelf(ItemAlign.Start)
      Row() {
        ForEach(this.categoryOptions, (opt: CategoryOption) => {
          Text(opt.label)
            .fontSize(13)
            .fontColor(this.category === opt.value ? Color.White : $r('app.color.color_text_primary'))
            .backgroundColor(this.category === opt.value ? $r('app.color.color_cta_black') : $r('app.color.color_bg_page'))
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .borderRadius(16)
            .margin({ right: 8 })
            .onClick(() => { this.category = opt.value; })
        }, (opt: CategoryOption) => opt.value)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 开播介绍（spec 16.7：含 AI 优化按钮，调用百炼直播智能体） */
  @Builder
  IntroSection() {
    Column({ space: 12 }) {
      Row() {
        Text('开播介绍（可选）')
          .fontSize(14)
          .fontColor($r('app.color.color_text_secondary'))
          .layoutWeight(1)
        // spec 16.7：AI 优化按钮
        Text(this.isAiOptimizing ? 'AI 优化中...' : '✨ AI 优化')
          .fontSize(12)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(this.isAiOptimizing ? $r('app.color.color_button_disabled') : $r('app.color.color_info'))
          .borderRadius(12)
          .onClick(() => { this.optimizeIntroWithAi(); })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      TextArea({ text: this.intro, placeholder: '200字以内，可点击右上角 AI 优化自动润色' })
        .height(80)
        .borderRadius(8)
        .backgroundColor($r('app.color.color_bg_page'))
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .fontSize(14)
        .maxLength(200)
        .onChange((v: string) => { this.intro = v; })
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 商品袋选择 */
  @Builder
  ProductBagSection() {
    Column({ space: 12 }) {
      Row() {
        Text('商品袋')
          .fontSize(14)
          .fontColor($r('app.color.color_text_secondary'))
          .layoutWeight(1)
        Text(`已选 ${this.productBag.length}`)
          .fontSize(12)
          .fontColor($r('app.color.color_secondary'))
        Text(this.bagPanelOpen ? '收起 ▴' : '展开 ▾')
          .fontSize(12)
          .fontColor($r('app.color.color_text_secondary'))
          .margin({ left: 12 })
          .onClick(() => { this.bagPanelOpen = !this.bagPanelOpen; })
      }
      .width('100%')
      if (this.bagPanelOpen) {
        if (this.availableProducts.length === 0) {
          Text('暂无可加入商品袋的已上架商品')
            .fontSize(12)
            .fontColor($r('app.color.color_text_hint'))
            .width('100%')
        } else {
          ForEach(this.availableProducts, (p: FarmerProductItem, _idx: number) => {
            Row({ space: 8 }) {
              Checkbox()
                .select(this.productBag.indexOf(p.productId) >= 0)
                .selectedColor($r('app.color.color_primary'))
                .width(20)
                .height(20)
                .onChange((checked: boolean) => {
                  if (checked) {
                    if (this.productBag.indexOf(p.productId) < 0) {
                      this.productBag.push(p.productId);
                    }
                  } else {
                    const idx: number = this.productBag.indexOf(p.productId);
                    if (idx >= 0) {
                      this.productBag.splice(idx, 1);
                    }
                  }
                })
              Text('🌾')
                .fontSize(20)
              Column({ space: 2 }) {
                Text(p.title)
                  .fontSize(13)
                  .fontColor($r('app.color.color_text_primary'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`¥${p.price.toFixed(2)}`)
                  .fontSize(11)
                  .fontColor($r('app.color.color_price'))
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')
            .padding({ top: 8, bottom: 8 })
            .onClick(() => { this.toggleProduct(p.productId); })
          }, (p: FarmerProductItem) => p.productId)
        }
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }
}
