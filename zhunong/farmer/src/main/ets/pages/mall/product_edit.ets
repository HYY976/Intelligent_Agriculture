/**
 * product_edit - 商品编辑页（spec 3.2.3.1 / 3.2.4.5）
 *
 * 复刻 product_publish 表单，进入时根据 productId 预填字段
 * 提交时调用 ProductManageRepository.updateProduct
 * 支持状态切换（已上架→下架 / 已驳回→重新提交）
 */

import { Logger, AppConstants, ToastUtil, ProductStatus, NavigationHelper, PageResult } from 'common';
import { FarmerProductItem, ProductPublishForm, FreightTemplate } from '../../model/FarmerModels';
import { ProductManageRepository } from '../../repository/ProductManageRepository';
import { MOCK_FARMER_ID, MOCK_FARMER_PRODUCTS } from '../../mock/FarmerMock';

/** 运费模板选项（spec 10.12：ArkTS 严格模式要求具体 interface，禁用对象字面量作为类型） */
interface FreightOption {
  value: FreightTemplate;
  label: string;
}

/** 类目选项 */
interface CategoryOption {
  categoryId: string;
  name: string;
}

@ComponentV2
export struct ProductEdit {
  /** 商品 ID */
  @Local productId: string = '';
  /** 商品标题 */
  @Local title: string = '';
  /** 商品类目ID */
  @Local categoryId: string = '';
  /** 商品类目显示名 */
  @Local categoryName: string = '';
  /** 主图 key 数组 */
  @Local mainImages: string[] = [];
  /** 价格（字符串形式） */
  @Local priceStr: string = '';
  /** 库存（字符串形式） */
  @Local stockStr: string = '';
  /** 商品详情富文本 */
  @Local description: string = '';
  /** 发货地 */
  @Local shipFrom: string = '';
  /** 运费模板 */
  @Local freight: FreightTemplate = 'free';
  /** 立即上架 / 放入仓库 */
  @Local publishNow: boolean = true;
  /** 当前商品状态 */
  @Local currentStatus: ProductStatus = 'approved';
  /** 驳回原因 */
  @Local rejectReason: string = '';
  /** 是否正在提交 */
  @Local isSubmitting: boolean = false;
  /** 是否正在加载 */
  @Local isLoading: boolean = true;

  /** 类目预设选项（Mock） */
  private categoryOptions: CategoryOption[] = [
    { categoryId: 'c111', name: '生鲜水果/蔬菜/叶菜' },
    { categoryId: 'c112', name: '生鲜水果/蔬菜/茄果' },
    { categoryId: 'c121', name: '生鲜水果/水果/柑橘' },
    { categoryId: 'c131', name: '生鲜水果/肉禽蛋品/蛋品' },
    { categoryId: 'c211', name: '粮油调味/米面油/大米' },
    { categoryId: 'c311', name: '茶饮冲调/茶叶/绿茶' },
    { categoryId: 'c321', name: '茶饮冲调/冲饮/蜂蜜' },
    { categoryId: 'c411', name: '坚果干货/坚果/核桃' }
  ];

  /** 运费模板选项 */
  private freightOptions: FreightOption[] = [
    { value: 'free', label: '包邮' },
    { value: 'by_piece', label: '按件计费' },
    { value: 'by_weight', label: '按重计费' }
  ];

  /** 发货地预设选项 */
  private shipFromOptions: string[] = [
    '云南·昆明', '云南·大理', '湖南·长沙', '黑龙江·五常',
    '宁夏·中卫', '海南·三亚', '浙江·杭州', '四川·成都',
    '福建·龙岩', '贵州·遵义'
  ];

  async aboutToAppear(): Promise<void> {
    const params: Record<string, string> | undefined = NavigationHelper.getParam<Record<string, string>>();
    this.productId = params?.productId ?? '';
    Logger.info(AppConstants.SCENE_FARMER, { action: 'product_edit_appear', productId: this.productId });
    await this.loadProduct();
  }

  /** 加载商品数据（Mock：从本地 Mock 列表查询；Phase 6 联调时切换为 Repository 查询接口） */
  private async loadProduct(): Promise<void> {
    this.isLoading = true;
    try {
      // Mock 阶段直接从本地查询
      const found: FarmerProductItem | undefined = MOCK_FARMER_PRODUCTS.find(
        (p: FarmerProductItem): boolean => p.productId === this.productId
      );
      if (found) {
        this.title = found.title;
        this.priceStr = found.price.toFixed(2);
        this.stockStr = `${found.stock}`;
        this.currentStatus = found.status;
        this.rejectReason = found.rejectReason ?? '';
        this.mainImages = [found.mainImage];
        // 预填默认值（Mock 无详细数据，使用默认值）
        this.categoryId = 'c111';
        this.categoryName = '生鲜水果/蔬菜/叶菜';
        this.description = '（编辑模式：请补充商品详情）';
        this.shipFrom = '云南·昆明';
      }
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'load_product_fail', error: (err as Error).message });
      ToastUtil.error('加载商品失败');
    } finally {
      this.isLoading = false;
    }
  }

  /** 校验表单 */
  private validateForm(): boolean {
    if (this.title.length < 5 || this.title.length > 60) {
      ToastUtil.warning('商品标题需 5-60 字');
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
    return true;
  }

  /** 添加主图（Mock：使用预设 key） */
  private addImage(): void {
    if (this.mainImages.length >= 9) {
      ToastUtil.warning('最多上传 9 张图片');
      return;
    }
    const imageKeys: string[] = ['prod_vegetable_1', 'prod_rice_1', 'prod_fruit_1', 'prod_egg_1'];
    const idx: number = this.mainImages.length;
    this.mainImages.push(imageKeys[idx % imageKeys.length]);
  }

  /** 删除主图 */
  private removeImage(index: number): void {
    this.mainImages.splice(index, 1);
  }

  /** 提交编辑 */
  private async submitEdit(): Promise<void> {
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
        aiPosterUrl: undefined
      };
      await ProductManageRepository.updateProduct(this.productId, form);
      ToastUtil.success('商品已更新');
      Logger.info(AppConstants.SCENE_FARMER, { action: 'product_edit_success', productId: this.productId });
      NavigationHelper.pop();
    } catch (err) {
      Logger.error(AppConstants.SCENE_FARMER, { action: 'product_edit_fail', error: (err as Error).message });
      ToastUtil.error('更新失败，请稍后重试');
    } finally {
      this.isSubmitting = false;
    }
  }

  /** 上下架切换 */
  private async toggleShelf(): Promise<void> {
    const target: ProductStatus = this.currentStatus === 'approved'
      ? 'off_shelf'
      : 'approved';
    try {
      await ProductManageRepository.setProductStatus(this.productId, target);
      this.currentStatus = target;
      ToastUtil.success(target === 'approved' ? '已上架' : '已下架');
      Logger.info(AppConstants.SCENE_FARMER, { action: 'product_status_change', productId: this.productId, productStatus: target });
    } catch (err) {
      ToastUtil.error('操作失败');
      Logger.error(AppConstants.SCENE_FARMER, { action: 'product_status_change_fail', error: (err as Error).message });
    }
  }

  /** 删除商品 */
  private async deleteProduct(): Promise<void> {
    try {
      await ProductManageRepository.deleteProduct(this.productId);
      ToastUtil.success('商品已删除');
      Logger.info(AppConstants.SCENE_FARMER, { action: 'product_delete_success', productId: this.productId });
      NavigationHelper.pop();
    } catch (err) {
      ToastUtil.error('删除失败');
      Logger.error(AppConstants.SCENE_FARMER, { action: 'product_delete_fail', error: (err as Error).message });
    }
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        if (this.isLoading) {
          Column() {
            Text('加载中...')
              .fontSize(14)
              .fontColor($r('app.color.color_text_secondary'))
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else {
          Scroll() {
            Column({ space: 16 }) {
              // 状态横幅（驳回时显示驳回原因）
              if (this.currentStatus === 'rejected') {
                this.RejectBanner()
              }
              this.BasicInfoSection()
              this.ImagesSection()
              this.PriceStockSection()
              this.DescriptionSection()
              this.LogisticsSection()
              this.ActionButtons()
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 24 })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
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
      Text('编辑商品')
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

  /** 驳回原因横幅 */
  @Builder
  RejectBanner() {
    Column({ space: 6 }) {
      Row({ space: 8 }) {
        Text('⚠️')
          .fontSize(16)
        Text('商品已被驳回')
          .fontSize(14)
          .fontColor($r('app.color.color_error'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
      }
      .width('100%')
      Text(`驳回原因：${this.rejectReason}`)
        .fontSize(12)
        .fontColor($r('app.color.color_text_secondary'))
        .width('100%')
    }
    .width('100%')
    .padding(12)
    .borderRadius(8)
    .backgroundColor('rgba(244,67,54,0.08)')
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
        TextInput({ text: this.title, placeholder: '5-60字' })
          .height(44)
          .borderRadius(8)
          .backgroundColor($r('app.color.color_bg_page'))
          .padding({ left: 12, right: 12 })
          .maxLength(60)
          .fontSize(14)
          .onChange((v: string) => { this.title = v; })
      }
      .width('100%')
      Column({ space: 6 }) {
        Text('* 商品类目')
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
          .alignSelf(ItemAlign.Start)
        Select(this.categoryOptions.map((c: CategoryOption): SelectOption => { return { value: c.name }; }))
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

  /** 主图 */
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
                .onClick(() => { this.removeImage(idx); })
            }
            .width('100%')
            .height(96)
            .borderRadius(8)
            .backgroundColor($r('app.color.color_card_yellow'))
            .alignContent(Alignment.Center)
          }
        }, (imgKey: string, idx: number) => `${imgKey}_${idx}`)
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
            .onClick(() => { this.addImage(); })
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

  /** 商品详情 */
  @Builder
  DescriptionSection() {
    Column({ space: 12 }) {
      Text('* 商品详情')
        .fontSize(14)
        .fontColor($r('app.color.color_text_secondary'))
        .alignSelf(ItemAlign.Start)
      TextArea({ text: this.description, placeholder: '请填写商品详情' })
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
      Column({ space: 6 }) {
        Text('* 发货地')
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
          .alignSelf(ItemAlign.Start)
        Select(this.shipFromOptions.map((s: string): SelectOption => { return { value: s }; }))
          .selected(this.shipFromOptions.indexOf(this.shipFrom))
          .value(this.shipFrom.length > 0 ? this.shipFrom : '请选择发货地')
          .height(44)
          .borderRadius(8)
          .backgroundColor($r('app.color.color_bg_page'))
          .onSelect((idx: number) => { this.shipFrom = this.shipFromOptions[idx]; })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
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
              .onClick(() => { this.freight = opt.value; })
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

  /** 操作按钮区 */
  @Builder
  ActionButtons() {
    Column({ space: 10 }) {
      // 上下架 / 删除（仅在已上架/已下架时显示）
      if (this.currentStatus === 'approved' || this.currentStatus === 'off_shelf') {
        Row({ space: 10 }) {
          Button(this.currentStatus === 'approved' ? '下架' : '上架')
            .layoutWeight(1)
            .height(44)
            .borderRadius(8)
            .backgroundColor($r('app.color.color_bg_page'))
            .fontColor($r('app.color.color_text_primary'))
            .fontSize(14)
            .onClick(() => { this.toggleShelf(); })
          Button('删除商品')
            .layoutWeight(1)
            .height(44)
            .borderRadius(8)
            .backgroundColor($r('app.color.color_bg_page'))
            .fontColor($r('app.color.color_error'))
            .fontSize(14)
            .onClick(() => { this.deleteProduct(); })
        }
        .width('100%')
      }
      // 保存按钮
      Button(this.isSubmitting ? '提交中...' : '保存修改')
        .width('100%')
        .height(48)
        .borderRadius(24)
        .backgroundColor(this.isSubmitting ? $r('app.color.color_button_disabled') : $r('app.color.color_cta_black'))
        .fontColor(Color.White)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .enabled(!this.isSubmitting)
        .onClick(() => { this.submitEdit(); })
    }
    .width('100%')
  }
}
