/**
 * product_publish - 商品上架发布页（spec 3.2.2 / 第8章 AI接口预留 / spec 16.2 去审核）
 *
 * 完整复刻淘宝发布详情页，字段：
 *  - 商品标题（5-60字，必填）
 *  - 商品类目（三级级联选择器，必填）
 *  - 商品主图（最多9张，必填）
 *  - 商品价格（元，必填）
 *  - 库存数量（必填）
 *  - SKU 多规格（可选）
 *  - 商品详情富文本（必填）
 *  - 发货地（省/市/区，必填）
 *  - 运费模板（必填）
 *  - 上架状态（立即上架/放入仓库）
 *  - AI文案生成按钮（spec 8.1：WebSocket 流式返回）
 *  - AI海报生成按钮（spec 8.2：异步任务+轮询）
 *
 * 上架流程（spec 16.2：去审核）：
 *  - 卖家填写 → 可选 AI 文案/海报 → 点击发布 → 状态 approved（直接发布）
 *  - 商品同步至 SharedProductStore，用户端立即可见
 */

import { Logger, AppConstants, ToastUtil, NavigationHelper, TokenStore, SharedProductStore, SharedProduct } from 'common';
import { ProductPublishForm, FarmerSkuInput, FreightTemplate, LiveCategory } from '../../model/FarmerModels';
import { ProductManageRepository } from '../../repository/ProductManageRepository';
import { AiPosterClient } from '../../utils/AiPosterClient';
import { BailianClient } from '../../utils/BailianClient';
import { MOCK_FARMER_ID } from '../../mock/FarmerMock';

/** 类目选项 */
interface CategoryOption {
  categoryId: string;
  name: string;
}

/** 运费模板选项（spec 10.12：ArkTS 严格模式要求具体 interface，禁用对象字面量作为类型） */
interface FreightOption {
  value: FreightTemplate;
  label: string;
}

@ComponentV2
export struct ProductPublish {
  /** 商品标题 */
  @Local title: string = '';
  /** 商品类目ID */
  @Local categoryId: string = '';
  /** 商品类目显示名 */
  @Local categoryName: string = '';
  /** 主图 key 数组 */
  @Local mainImages: string[] = [];
  /** 价格 */
  @Local priceStr: string = '';
  /** 库存 */
  @Local stockStr: string = '';
  /** 商品详情富文本 */
  @Local description: string = '';
  /** 发货地 */
  @Local shipFrom: string = '';
  /** 运费模板 */
  @Local freight: FreightTemplate = 'free';
  /** 立即上架 / 放入仓库 */
  @Local publishNow: boolean = true;
  /** AI 海报 URL */
  @Local aiPosterUrl: string = '';
  /** AI 文案生成中 */
  @Local isGeneratingCopywrite: boolean = false;
  /** AI 海报生成中 */
  @Local isGeneratingPoster: boolean = false;
  /** AI 海报生成进度文案 */
  @Local posterProgressText: string = '';
  /** 是否正在提交 */
  @Local isSubmitting: boolean = false;

  /** 类目预设选项（Mock，spec 3.1.4.1 三级分类树预置） */
  private categoryOptions: CategoryOption[] = [
    { categoryId: 'c111', name: '生鲜水果/蔬菜/叶菜' },
    { categoryId: 'c112', name: '生鲜水果/蔬菜/茄果' },
    { categoryId: 'c113', name: '生鲜水果/蔬菜/菌菇' },
    { categoryId: 'c121', name: '生鲜水果/水果/柑橘' },
    { categoryId: 'c131', name: '生鲜水果/肉禽蛋品/蛋品' },
    { categoryId: 'c211', name: '粮油调味/米面油/大米' },
    { categoryId: 'c311', name: '茶饮冲调/茶叶/绿茶' },
    { categoryId: 'c321', name: '茶饮冲调/冲饮/蜂蜜' },
    { categoryId: 'c411', name: '坚果干货/坚果/核桃' },
    { categoryId: 'c421', name: '坚果干货/干货/果干' }
  ];

  /** 运费模板选项 */
  private freightOptions: FreightOption[] = [
    { value: 'free', label: '包邮' },
    { value: 'by_piece', label: '按件计费' },
    { value: 'by_weight', label: '按重计费' }
  ];

  /** 发货地预设选项 */
  private shipFromOptions: string[] = [
    '云南·昆明', '云南·大理', '湖南·长沙', '湖南·怀化',
    '黑龙江·五常', '宁夏·中卫', '海南·三亚', '浙江·杭州',
    '浙江·临安', '四川·成都', '福建·龙岩', '湖北·神农架',
    '贵州·遵义', '江苏·盐城', '吉林·松原'
  ];

  aboutToDisappear(): void {
    // 页面销毁时取消 AI 海报任务轮询（避免内存泄漏）
    AiPosterClient.cancel();
  }

  /** 校验表单（spec 7.3.2：必填项校验） */
  private validateForm(): boolean {
    if (this.title.length < 5 || this.title.length > 60) {
      ToastUtil.warning('商品标题需 5-60 字');
      return false;
    }
    if (this.categoryId.length === 0) {
      ToastUtil.warning('请选择商品类目');
      return false;
    }
    if (this.mainImages.length === 0) {
      ToastUtil.warning('请至少上传 1 张商品主图');
      return false;
    }
    const price: number = parseFloat(this.priceStr);
    if (isNaN(price) || price <= 0) {
      ToastUtil.warning('请输入有效的商品价格');
      return false;
    }
    const stock: number = parseInt(this.stockStr, 10);
    if (isNaN(stock) || stock < 0) {
      ToastUtil.warning('请输入有效的库存数量');
      return false;
    }
    if (this.description.length === 0) {
      ToastUtil.warning('请填写商品详情');
      return false;
    }
    if (this.shipFrom.length === 0) {
      ToastUtil.warning('请选择发货地');
      return false;
    }
    return true;
  }

  /** 添加主图（Mock：使用预设 key） */
  private addImage(): void {
    if (this.mainImages.length >= 9) {
      ToastUtil.warning('最多上传 9 张图片');
      return;
    }
    const imageKeys: string[] = [
      'prod_vegetable_1', 'prod_vegetable_2', 'prod_rice_1', 'prod_fruit_1',
      'prod_egg_1', 'prod_tea_1', 'prod_honey_1', 'prod_meat_1', 'prod_corn_1'
    ];
    const idx: number = this.mainImages.length;
    const key: string = imageKeys[idx % imageKeys.length];
    this.mainImages.push(key);
  }

  /** 删除主图 */
  private removeImage(index: number): void {
    this.mainImages.splice(index, 1);
  }

  /**
   * AI 文案生成（接入阿里云百炼智能体应用）
   * 调用百炼 application/completion 接口，由智能体应用生成商品描述文案
   */
  private async generateCopywrite(): Promise<void> {
    if (this.title.length === 0) {
      ToastUtil.warning('请先填写商品标题');
      return;
    }
    if (this.isGeneratingCopywrite) {
      this.isGeneratingCopywrite = false;
      ToastUtil.info('已取消 AI 文案生成');
      return;
    }
    this.isGeneratingCopywrite = true;
    this.description = '';
    Logger.info(AppConstants.SCENE_FARMER, { action: 'ai_copywrite_start_btn' });

    // 构造百炼提示词
    const prompt: string = BailianClient.buildCopywritePrompt(this.title, this.categoryName, []);

    await BailianClient.generateText(prompt,
      (text: string) => {
        this.isGeneratingCopywrite = false;
        this.description = text;
        ToastUtil.success('AI 文案生成完成');
        Logger.info(AppConstants.SCENE_FARMER, { action: 'ai_copywrite_done', textLength: text.length });
      },
      (message: string) => {
        this.isGeneratingCopywrite = false;
        ToastUtil.error(`AI 文案生成失败：${message}`);
        Logger.error(AppConstants.SCENE_FARMER, { action: 'ai_copywrite_error', message });
      }
    );
  }

  /** AI 海报生成（spec 8.2：异步任务+轮询） */
  private async generatePoster(): Promise<void> {
    if (this.mainImages.length === 0) {
      ToastUtil.warning('请先上传商品主图');
      return;
    }
    if (this.isGeneratingPoster) {
      AiPosterClient.cancel();
      this.isGeneratingPoster = false;
      this.posterProgressText = '';
      ToastUtil.info('已取消 AI 海报生成');
      return;
    }
    this.isGeneratingPoster = true;
    this.aiPosterUrl = '';
    this.posterProgressText = '创建任务中...';
    Logger.info(AppConstants.SCENE_FARMER, { action: 'ai_poster_start_btn' });

    await AiPosterClient.createAndPoll({
      productId: '',
      images: this.mainImages,
      title: this.title.length > 0 ? this.title : '我的商品',
      style: 'fresh'
    }, {
      onProgress: (status: string) => {
        if (status === 'pending') {
          this.posterProgressText = '生成中...';
        } else if (status === 'done') {
          this.posterProgressText = '即将完成';
        }
      },
      onDone: (posterUrl: string, thumbnailUrl: string) => {
        this.isGeneratingPoster = false;
        this.aiPosterUrl = posterUrl;
        this.posterProgressText = '';
        ToastUtil.success('AI 海报生成完成');
        Logger.info(AppConstants.SCENE_FARMER, { action: 'ai_poster_done', posterUrl });
      },
      onError: (message: string) => {
        this.isGeneratingPoster = false;
        this.posterProgressText = '';
        ToastUtil.error(`AI 海报生成失败：${message}`);
        Logger.error(AppConstants.SCENE_FARMER, { action: 'ai_poster_error', message });
      }
    });
  }

  /** 提交发布（spec 16.2：去审核，立即上架 → 状态 approved；同步到共享商品池） */
  private async submitPublish(): Promise<void> {
    if (!this.validateForm()) {
      return;
    }
    this.isSubmitting = true;
    try {
      const form: ProductPublishForm = {
        title: this.title,
        categoryId: this.categoryId,
        mainImages: this.mainImages,
        price: parseFloat(this.priceStr),
        stock: parseInt(this.stockStr, 10),
        skuList: [],
        description: this.description,
        shipFrom: this.shipFrom,
        freightTemplate: this.freightOptions.find((o) => o.value === this.freight)?.label ?? '包邮',
        publishNow: this.publishNow,
        aiPosterUrl: this.aiPosterUrl.length > 0 ? this.aiPosterUrl : undefined
      };
      const productId: string = await ProductManageRepository.publishProduct(MOCK_FARMER_ID, form);

      // spec 16.2：立即上架 → 直接同步到共享商品池，用户端立即可见
      if (this.publishNow) {
        const userInfo = await TokenStore.getUserInfo();
        const now: number = Date.now();
        const sharedProduct: SharedProduct = {
          productId,
          farmerId: MOCK_FARMER_ID,
          farmerName: userInfo?.nickname ?? '青禾农庄·王大叔',
          farmerAvatar: userInfo?.avatar ?? 'avatar_farmer',
          title: this.title,
          categoryId: this.categoryId,
          mainImages: this.mainImages,
          aiPosterUrl: this.aiPosterUrl.length > 0 ? this.aiPosterUrl : undefined,
          description: this.description,
          price: parseFloat(this.priceStr),
          stock: parseInt(this.stockStr, 10),
          shipFrom: this.shipFrom,
          freightTemplate: this.freightOptions.find((o) => o.value === this.freight)?.label ?? '包邮',
          monthlySales: 0,
          monthlyGmv: 0,
          totalSales: 0,
          status: 'approved',
          createdAt: now,
          updatedAt: now
        };
        await SharedProductStore.publish(sharedProduct);
        Logger.info(AppConstants.SCENE_FARMER, {
          action: 'shared_product_synced',
          productId,
          farmerName: sharedProduct.farmerName
        });
      }

      ToastUtil.success(this.publishNow ? '商品已发布' : '商品已存入仓库');
      Logger.info(AppConstants.SCENE_FARMER, {
        action: 'product_publish_success',
        productId,
        publishNow: this.publishNow
      });
      NavigationHelper.pop();
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, {
        action: 'product_publish_fail',
        error: (err as Error).message
      });
      ToastUtil.error('提交失败，请稍后重试');
    } finally {
      this.isSubmitting = false;
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部导航栏
        this.TopBar()
        // 表单内容
        Scroll() {
          Column({ space: 16 }) {
            // AI 海报预览区（生成后显示）
            if (this.aiPosterUrl.length > 0) {
              this.AiPosterPreview()
            }
            // 基础信息
            this.BasicInfoSection()
            // 主图上传
            this.ImagesSection()
            // 价格库存
            this.PriceStockSection()
            // 详情富文本
            this.DescriptionSection()
            // AI 智能助手（移至商品详情下方）
            this.AiActionsSection()
            // 物流信息
            this.LogisticsSection()
            // 上架状态
            this.PublishStatusSection()
            // 提交按钮
            Button(this.isSubmitting ? '提交中...' : '发布商品')
              .width('100%')
              .height(48)
              .borderRadius(24)
              .backgroundColor(this.isSubmitting ? $r('app.color.color_button_disabled') : $r('app.color.color_cta_black'))
              .fontColor(Color.White)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .enabled(!this.isSubmitting)
              .margin({ top: 8, bottom: 24 })
              .onClick(() => {
                this.submitPublish();
              })
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

  /** 顶部导航栏 */
  @Builder
  TopBar() {
    Row({ space: 12 }) {
      Text('‹')
        .fontSize(28)
        .fontColor($r('app.color.color_text_primary'))
        .onClick(() => NavigationHelper.pop())
      Text('发布商品')
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

  /** AI 海报预览区 */
  @Builder
  AiPosterPreview() {
    Column({ space: 8 }) {
      Text('AI 海报预览')
        .fontSize(14)
        .fontColor($r('app.color.color_text_secondary'))
        .alignSelf(ItemAlign.Start)
      Stack() {
        Text('🎨')
          .fontSize(48)
        Text('AI 海报')
          .fontSize(12)
          .fontColor(Color.White)
          .backgroundColor('rgba(0,0,0,0.5)')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(8)
          .position({ x: 8, y: 8 })
      }
      .width('100%')
      .height(160)
      .borderRadius(12)
      .backgroundColor($r('app.color.color_card_yellow'))
      .alignContent(Alignment.Bottom)
    }
    .width('100%')
  }

  /** AI 操作区 */
  @Builder
  AiActionsSection() {
    Column({ space: 12 }) {
      Text('AI 智能助手')
        .fontSize(14)
        .fontColor($r('app.color.color_text_secondary'))
        .alignSelf(ItemAlign.Start)
      Row({ space: 12 }) {
        Button(this.isGeneratingCopywrite ? '取消生成' : '✨ AI 文案')
          .layoutWeight(1)
          .height(40)
          .borderRadius(20)
          .backgroundColor(this.isGeneratingCopywrite ? $r('app.color.color_bg_page') : $r('app.color.color_cta_black'))
          .fontColor(this.isGeneratingCopywrite ? $r('app.color.color_text_primary') : Color.White)
          .fontSize(13)
          .onClick(() => {
            this.generateCopywrite();
          })
        Button(this.isGeneratingPoster ? '取消生成' : '🎨 AI 海报')
          .layoutWeight(1)
          .height(40)
          .borderRadius(20)
          .backgroundColor(this.isGeneratingPoster ? $r('app.color.color_bg_page') : $r('app.color.color_cta_black'))
          .fontColor(this.isGeneratingPoster ? $r('app.color.color_text_primary') : Color.White)
          .fontSize(13)
          .onClick(() => {
            this.generatePoster();
          })
      }
      .width('100%')
      if (this.posterProgressText.length > 0) {
        Text(this.posterProgressText)
          .fontSize(12)
          .fontColor($r('app.color.color_text_hint'))
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

      // 商品标题
      Column({ space: 6 }) {
        Row() {
          Text('* 标题')
            .fontSize(13)
            .fontColor($r('app.color.color_text_primary'))
          Blank()
          Text(`${this.title.length}/60`)
            .fontSize(11)
            .fontColor($r('app.color.color_text_hint'))
        }
        .width('100%')
        TextInput({ text: this.title, placeholder: '5-60字，如：有机青菜 500g 当季新鲜' })
          .height(44)
          .borderRadius(8)
          .backgroundColor($r('app.color.color_bg_page'))
          .padding({ left: 12, right: 12 })
          .maxLength(60)
          .fontSize(14)
          .onChange((v: string) => { this.title = v; })
      }
      .width('100%')

      // 商品类目
      Column({ space: 6 }) {
        Text('* 商品类目')
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
          .alignSelf(ItemAlign.Start)
        Select(this.categoryOptions.map((c: CategoryOption): SelectOption => {
          return { value: c.name };
        }))
          .selected(this.categoryOptions.findIndex((c: CategoryOption) => c.categoryId === this.categoryId))
          .value(this.categoryName.length > 0 ? this.categoryName : '请选择商品类目')
          .height(44)
          .borderRadius(8)
          .backgroundColor($r('app.color.color_bg_page'))
          .onSelect((idx: number) => {
            const opt: CategoryOption = this.categoryOptions[idx];
            this.categoryId = opt.categoryId;
            this.categoryName = opt.name;
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 主图上传 */
  @Builder
  ImagesSection() {
    Column({ space: 12 }) {
      Row() {
        Text('* 商品主图')
          .fontSize(14)
          .fontColor($r('app.color.color_text_secondary'))
        Blank()
        Text(`${this.mainImages.length}/9`)
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')
      // 图片网格（3列）
      Grid() {
        ForEach(this.mainImages, (imgKey: string, idx: number) => {
          GridItem() {
            Stack() {
              Text('🌾')
                .fontSize(28)
              Text('×')
                .fontSize(14)
                .fontColor(Color.White)
                .backgroundColor('rgba(0,0,0,0.6)')
                .width(20)
                .height(20)
                .borderRadius(10)
                .textAlign(TextAlign.Center)
                .position({ x: '70%', y: 4 })
                .onClick(() => {
                  this.removeImage(idx);
                })
            }
            .width('100%')
            .height(96)
            .borderRadius(8)
            .backgroundColor($r('app.color.color_card_yellow'))
            .alignContent(Alignment.Center)
          }
        }, (imgKey: string, idx: number) => `${imgKey}_${idx}`)
        // 添加按钮
        if (this.mainImages.length < 9) {
          GridItem() {
            Stack() {
              Text('+')
                .fontSize(36)
                .fontColor($r('app.color.color_text_hint'))
            }
            .width('100%')
            .height(96)
            .borderRadius(8)
            .backgroundColor($r('app.color.color_bg_page'))
            .alignContent(Alignment.Center)
            .onClick(() => {
              this.addImage();
            })
          }
        }
      }
      .columnsTemplate('1fr 1fr 1fr')
      .columnsGap(8)
      .rowsGap(8)
      .width('100%')
      .height(96)
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 价格库存 */
  @Builder
  PriceStockSection() {
    Column({ space: 12 }) {
      Text('价格与库存')
        .fontSize(14)
        .fontColor($r('app.color.color_text_secondary'))
        .alignSelf(ItemAlign.Start)
      Row({ space: 12 }) {
        Column({ space: 6 }) {
          Text('* 价格（元）')
            .fontSize(11)
            .fontColor($r('app.color.color_text_secondary'))
            .alignSelf(ItemAlign.Start)
          TextInput({ text: this.priceStr, placeholder: '0.00' })
            .type(InputType.Number)
            .height(40)
            .borderRadius(8)
            .backgroundColor($r('app.color.color_bg_page'))
            .padding({ left: 10, right: 10 })
            .fontSize(14)
            .onChange((v: string) => { this.priceStr = v; })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Column({ space: 6 }) {
          Text('* 库存')
            .fontSize(11)
            .fontColor($r('app.color.color_text_secondary'))
            .alignSelf(ItemAlign.Start)
          TextInput({ text: this.stockStr, placeholder: '0' })
            .type(InputType.Number)
            .height(40)
            .borderRadius(8)
            .backgroundColor($r('app.color.color_bg_page'))
            .padding({ left: 10, right: 10 })
            .fontSize(14)
            .onChange((v: string) => { this.stockStr = v; })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 商品详情富文本 */
  @Builder
  DescriptionSection() {
    Column({ space: 12 }) {
      Text('* 商品详情')
        .fontSize(14)
        .fontColor($r('app.color.color_text_secondary'))
        .alignSelf(ItemAlign.Start)
      TextArea({ text: this.description, placeholder: '请填写商品详情（可使用 AI 文案生成）' })
        .height(120)
        .borderRadius(8)
        .backgroundColor($r('app.color.color_bg_page'))
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .fontSize(14)
        .maxLength(2000)
        .onChange((v: string) => { this.description = v; })
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 物流信息 */
  @Builder
  LogisticsSection() {
    Column({ space: 12 }) {
      Text('物流信息')
        .fontSize(14)
        .fontColor($r('app.color.color_text_secondary'))
        .alignSelf(ItemAlign.Start)
      // 发货地
      Column({ space: 6 }) {
        Text('* 发货地')
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
          .alignSelf(ItemAlign.Start)
        Select(this.shipFromOptions.map((s: string): SelectOption => {
          return { value: s };
        }))
          .selected(this.shipFromOptions.indexOf(this.shipFrom))
          .value(this.shipFrom.length > 0 ? this.shipFrom : '请选择发货地')
          .height(44)
          .borderRadius(8)
          .backgroundColor($r('app.color.color_bg_page'))
          .onSelect((idx: number) => {
            this.shipFrom = this.shipFromOptions[idx];
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      // 运费模板
      Column({ space: 6 }) {
        Text('* 运费模板')
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
          .alignSelf(ItemAlign.Start)
        Row() {
          ForEach(this.freightOptions, (opt: FreightOption) => {
            Text(opt.label)
              .fontSize(13)
              .fontColor(this.freight === opt.value ? Color.White : $r('app.color.color_text_primary'))
              .backgroundColor(this.freight === opt.value ? $r('app.color.color_cta_black') : $r('app.color.color_bg_page'))
              .padding({ left: 16, right: 16, top: 8, bottom: 8 })
              .borderRadius(16)
              .margin({ right: 8 })
              .onClick(() => {
                this.freight = opt.value;
              })
          }, (opt: FreightOption) => opt.value)
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 上架状态 */
  @Builder
  PublishStatusSection() {
    Column({ space: 12 }) {
      Text('上架状态')
        .fontSize(14)
        .fontColor($r('app.color.color_text_secondary'))
        .alignSelf(ItemAlign.Start)
      Row() {
        Text(this.publishNow ? '立即上架' : '放入仓库')
          .fontSize(14)
          .fontColor($r('app.color.color_text_primary'))
          .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.publishNow })
          .selectedColor($r('app.color.color_primary'))
          .onChange((on: boolean) => {
            this.publishNow = on;
          })
      }
      .width('100%')
      Text(this.publishNow ? '提交后进入审核队列，审核通过即可上架' : '存入仓库后可随时上架')
        .fontSize(11)
        .fontColor($r('app.color.color_text_hint'))
        .alignSelf(ItemAlign.Start)
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }
}
