/**
 * search_page - 搜索页（spec 3.2.1）
 *
 * 与用户端搜索页完全一致（含双榜单）
 * 卖家可查看市场热门商品/直播，作为经营参考
 *
 * 结构：
 *  - 顶部搜索框 + 取消按钮
 *  - 历史搜索 + 热门搜索（无搜索内容时）
 *  - 双榜单：商品热销榜 / 直播人气榜（spec 9.16.4）
 *  - 搜索结果（商品列表，spec 3.1.4.2）
 */

import { Logger, AppConstants, ToastUtil, NavigationHelper, RouteName, ListStateView } from 'common';
import { FarmerSearchResultDataSource, FarmerProductRankItem } from '../../viewmodel/FarmerSearchResultDataSource';
import { ImageUtil } from '../../utils/ImageUtil';
import { ReplaceableImage } from '../../components/ReplaceableImage';

/** 热门搜索词 */
interface HotKeyword {
  keyword: string;
  rank: number;
}

/** 直播榜单项 */
interface LiveRankItem {
  liveId: string;
  title: string;
  farmerName: string;
  totalViewUv: number;
  status: string;
}

/** spec 16.7：商品编辑页跳转参数（与 product_manage.ets 保持结构一致） */
interface ProductEditParam {
  productId: string;
}

@ComponentV2
export struct SearchPage {
  /** 搜索关键词 */
  @Local keyword: string = '';
  /** 历史搜索词 */
  @Local historyList: string[] = ['有机青菜', '高山绿茶', '土鸡蛋', '农家大米'];
  /** 当前榜单 Tab（0=商品热销 / 1=直播人气） */
  @Local rankTab: number = 0;
  /** 商品热销榜 */
  @Local productRankList: FarmerProductRankItem[] = [];
  /** 直播人气榜 */
  @Local liveRankList: LiveRankItem[] = [];
  /** 搜索结果数据源（spec 10.11.4 Step 3：BaseDataSource + LazyForEach） */
  private searchDataSource: FarmerSearchResultDataSource = new FarmerSearchResultDataSource();
  /** 搜索结果是否为空 */
  @Local searchResultEmpty: boolean = true;
  /** 是否显示搜索结果 */
  @Local hasSearched: boolean = false;

  /** 热门搜索词 Mock */
  private hotKeywords: HotKeyword[] = [
    { keyword: '有机青菜', rank: 1 },
    { keyword: '高山绿茶', rank: 2 },
    { keyword: '土鸡蛋', rank: 3 },
    { keyword: '农家大米', rank: 4 },
    { keyword: '散养土猪肉', rank: 5 },
    { keyword: '土蜂蜜', rank: 6 },
    { keyword: '明前嫩芽', rank: 7 },
    { keyword: '小米辣', rank: 8 }
  ];

  async aboutToAppear(): Promise<void> {
    Logger.info(AppConstants.SCENE_FARMER, { action: 'search_page_appear' });
    await this.loadRankList();
  }

  /** 加载双榜单 Mock 数据 */
  private async loadRankList(): Promise<void> {
    this.productRankList = [
      { productId: 'rk001', title: '陕西洛川苹果 5斤 脆甜多汁', price: 39.90, monthlySales: 9850, farmerName: '洛川果园', imageUrl: 'prod_apple', categoryId: 'cat_fruit', shipFrom: '陕西洛川' },
      { productId: 'rk002', title: '红心蜜柚 5斤装 福建平和', price: 29.90, monthlySales: 8620, farmerName: '平和果农', imageUrl: 'prod_pomelo', categoryId: 'cat_fruit', shipFrom: '福建平和' },
      { productId: 'rk003', title: '新疆灰枣 500g 一级骏枣', price: 25.80, monthlySales: 6580, farmerName: '丝路枣农', imageUrl: 'prod_date', categoryId: 'cat_honey', shipFrom: '新疆' },
      { productId: 'rk004', title: '云南小黄姜 2斤 现挖', price: 19.90, monthlySales: 5630, farmerName: '滇南农场', imageUrl: 'prod_ginger', categoryId: 'cat_vegetable', shipFrom: '云南' },
      { productId: 'rk005', title: '内蒙古土豆 10斤 沙土地', price: 26.80, monthlySales: 4520, farmerName: '草原牧歌', imageUrl: 'prod_potato', categoryId: 'cat_vegetable', shipFrom: '内蒙古' },
      { productId: 'rk006', title: '广西百香果 3斤 紫皮', price: 22.50, monthlySales: 4280, farmerName: '桂南果场', imageUrl: 'prod_passion', categoryId: 'cat_fruit', shipFrom: '广西' }
    ];
    this.liveRankList = [
      { liveId: 'lk001', title: '高山有机青菜采摘直播', farmerName: '青禾农庄', totalViewUv: 1286, status: 'ended' },
      { liveId: 'lk002', title: '山野好物·散养土猪直播', farmerName: '山野好物', totalViewUv: 980, status: 'living' },
      { liveId: 'lk003', title: '当季新米品鉴专场', farmerName: '青禾农庄', totalViewUv: 856, status: 'ended' },
      { liveId: 'lk004', title: '田园牧歌·果园采摘', farmerName: '田园牧歌', totalViewUv: 658, status: 'preview' },
      { liveId: 'lk005', title: '明前嫩芽绿茶制作', farmerName: '青禾农庄', totalViewUv: 568, status: 'ended' }
    ];
  }

  /** 执行搜索 */
  private async doSearch(kw: string): Promise<void> {
    const keyword: string = kw.trim();
    if (keyword.length === 0) {
      ToastUtil.warning('请输入搜索词');
      return;
    }
    this.keyword = keyword;
    this.hasSearched = true;
    // spec 10.11.4 Step 3：通过 DataSource 取数（本地榜单 Mock 过滤）
    this.searchDataSource.setKeyword(keyword);
    await this.searchDataSource.refresh();
    this.searchResultEmpty = this.searchDataSource.totalCount() === 0;
    // 加入历史（去重 + 头部）
    const idx: number = this.historyList.indexOf(keyword);
    if (idx >= 0) {
      this.historyList.splice(idx, 1);
    }
    this.historyList = [keyword].concat(this.historyList).slice(0, 10);
    Logger.info(AppConstants.SCENE_FARMER, { action: 'search', keyword, resultCount: this.searchDataSource.totalCount() });
  }

  /** 清空历史 */
  private clearHistory(): void {
    this.historyList = [];
  }

  /** 切换榜单 Tab */
  private switchRankTab(idx: number): void {
    this.rankTab = idx;
  }

  /** spec 16.10：点击搜索结果项，跳转到商品详情购买页 */
  private gotoProductEdit(item: FarmerProductRankItem): void {
    const param: ProductEditParam = { productId: item.productId };
    Logger.info(AppConstants.SCENE_FARMER, {
      action: 'search_result_click',
      productId: item.productId,
      msg: this.keyword
    });
    NavigationHelper.push(RouteName.FARMER_PRODUCT_DETAIL, param);
  }

  /** 返回 */
  private goBack(): void {
    if (this.hasSearched) {
      this.hasSearched = false;
      this.keyword = '';
    } else {
      NavigationHelper.pop();
    }
  }

  build() {
    NavDestination() {
      Column() {
        this.SearchBar()
        if (this.hasSearched) {
          this.SearchResultList()
        } else {
          Scroll() {
            Column({ space: 16 }) {
              this.HistorySection()
              this.HotKeywordSection()
              this.RankSection()
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 24 })
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

  /** 顶部搜索栏 */
  @Builder
  SearchBar() {
    Row({ space: 12 }) {
      Row({ space: 8 }) {
        Text('🔍')
          .fontSize(16)
        TextInput({ text: this.keyword, placeholder: '搜索商品 / 直播 / 卖家' })
          .backgroundColor(Color.Transparent)
          .height(40)
          .fontSize(14)
          .layoutWeight(1)
          .onSubmit(() => { this.doSearch(this.keyword); })
          .onChange((v: string) => { this.keyword = v; })
      }
      .layoutWeight(1)
      .height(40)
      .borderRadius(20)
      .backgroundColor($r('app.color.color_bg_page'))
      .padding({ left: 12, right: 12 })
      .alignItems(VerticalAlign.Center)
      Text('取消')
        .fontSize(14)
        .fontColor($r('app.color.color_text_secondary'))
        .onClick(() => this.goBack())
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)
  }

  /** 历史搜索 */
  @Builder
  HistorySection() {
    Column({ space: 12 }) {
      Row() {
        Text('历史搜索')
          .fontSize(14)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
        Text('🗑')
          .fontSize(16)
          .onClick(() => this.clearHistory())
      }
      .width('100%')
      if (this.historyList.length === 0) {
        Text('暂无搜索历史')
          .fontSize(12)
          .fontColor($r('app.color.color_text_hint'))
          .width('100%')
      } else {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.historyList, (word: string, _idx: number) => {
            Text(word)
              .fontSize(12)
              .fontColor($r('app.color.color_text_secondary'))
              .backgroundColor($r('app.color.color_bg_card'))
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .borderRadius(14)
              .margin({ right: 8, bottom: 8 })
              .onClick(() => { this.doSearch(word); })
          }, (word: string) => word)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 热门搜索 */
  @Builder
  HotKeywordSection() {
    Column({ space: 12 }) {
      Text('热门搜索')
        .fontSize(14)
        .fontColor($r('app.color.color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.hotKeywords, (item: HotKeyword, _idx: number) => {
          Row({ space: 4 }) {
            Text(`${item.rank}`)
              .fontSize(11)
              .fontColor(item.rank <= 3 ? $r('app.color.color_cta_black') : $r('app.color.color_text_hint'))
              .fontWeight(FontWeight.Bold)
            Text(item.keyword)
              .fontSize(12)
              .fontColor($r('app.color.color_text_secondary'))
          }
          .backgroundColor($r('app.color.color_bg_card'))
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(14)
          .margin({ right: 8, bottom: 8 })
          .onClick(() => { this.doSearch(item.keyword); })
        }, (item: HotKeyword) => item.keyword)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 双榜单 */
  @Builder
  RankSection() {
    Column({ space: 12 }) {
      // 榜单 Tab
      Row({ space: 12 }) {
        Text('商品热销榜')
          .fontSize(14)
          .fontColor(this.rankTab === 0 ? $r('app.color.color_cta_black') : $r('app.color.color_text_secondary'))
          .fontWeight(this.rankTab === 0 ? FontWeight.Bold : FontWeight.Normal)
          .onClick(() => { this.switchRankTab(0); })
        Text('直播人气榜')
          .fontSize(14)
          .fontColor(this.rankTab === 1 ? $r('app.color.color_cta_black') : $r('app.color.color_text_secondary'))
          .fontWeight(this.rankTab === 1 ? FontWeight.Bold : FontWeight.Normal)
          .onClick(() => { this.switchRankTab(1); })
      }
      .width('100%')

      if (this.rankTab === 0) {
        ForEach(this.productRankList, (item: FarmerProductRankItem, idx: number) => {
          this.ProductRankCard(item, idx)
        }, (item: FarmerProductRankItem) => item.productId)
      } else {
        ForEach(this.liveRankList, (item: LiveRankItem, idx: number) => {
          this.LiveRankCard(item, idx)
        }, (item: LiveRankItem) => item.liveId)
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 商品榜卡片 */
  @Builder
  ProductRankCard(item: FarmerProductRankItem, idx: number) {
    Row({ space: 12 }) {
      Text(`${idx + 1}`)
        .fontSize(16)
        .fontColor(idx < 3 ? Color.White : $r('app.color.color_text_secondary'))
        .fontWeight(FontWeight.Bold)
        .width(28)
        .height(28)
        .borderRadius(14)
        .backgroundColor(idx === 0 ? $r('app.color.color_cta_black') : (idx < 3 ? $r('app.color.color_cta_black') : $r('app.color.color_bg_page')))
        .textAlign(TextAlign.Center)
      Text('🥬')
        .fontSize(28)
        .width(48)
        .height(48)
        .borderRadius(8)
        .backgroundColor($r('app.color.color_card_yellow'))
        .textAlign(TextAlign.Center)
      Column({ space: 2 }) {
        Text(item.title)
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(item.farmerName)
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Column({ space: 2 }) {
        Text(`¥${item.price.toFixed(2)}`)
          .fontSize(13)
          .fontColor($r('app.color.color_price'))
          .fontWeight(FontWeight.Bold)
        Text(`月销 ${item.monthlySales}`)
          .fontSize(10)
          .fontColor($r('app.color.color_text_hint'))
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }

  /** 直播榜卡片 */
  @Builder
  LiveRankCard(item: LiveRankItem, idx: number) {
    Row({ space: 12 }) {
      Text(`${idx + 1}`)
        .fontSize(16)
        .fontColor(idx < 3 ? Color.White : $r('app.color.color_text_secondary'))
        .fontWeight(FontWeight.Bold)
        .width(28)
        .height(28)
        .borderRadius(14)
        .backgroundColor(idx === 0 ? $r('app.color.color_cta_black') : (idx < 3 ? $r('app.color.color_cta_black') : $r('app.color.color_bg_page')))
        .textAlign(TextAlign.Center)
      Text('📹')
        .fontSize(28)
        .width(48)
        .height(48)
        .borderRadius(8)
        .backgroundColor($r('app.color.color_bg_panel_dark'))
        .textAlign(TextAlign.Center)
      Column({ space: 2 }) {
        Text(item.title)
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(item.farmerName)
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Column({ space: 2 }) {
        Text(item.status === 'living' ? '直播中' : (item.status === 'preview' ? '预告' : '已结束'))
          .fontSize(11)
          .fontColor(item.status === 'living' ? $r('app.color.color_error') : $r('app.color.color_text_hint'))
        Text(`观看 ${item.totalViewUv}`)
          .fontSize(10)
          .fontColor($r('app.color.color_text_hint'))
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }

  /** 搜索结果列表（spec 16.9：2 列网格布局，与商城排版一致） */
  @Builder
  SearchResultList() {
    if (this.searchDataSource.getLoadFailed()) {
      ListStateView({ state: 'error', onRefresh: () => this.doSearch(this.keyword) })
    } else if (this.searchDataSource.getIsFirstLoad()) {
      ListStateView({ state: 'loading' })
    } else if (this.searchDataSource.totalCount() === 0) {
      Column({ space: 8 }) {
        Text('🔍')
          .fontSize(48)
        Text(`未找到与"${this.keyword}"相关的商品`)
          .fontSize(14)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    } else {
      // spec 16.9：改为 2 列 Grid，对齐商城推荐流排版
      Grid() {
        LazyForEach(this.searchDataSource, (item: FarmerProductRankItem, idx: number) => {
          GridItem() {
            this.ProductGridCard(item, idx)
          }
          .onClick(() => this.gotoProductEdit(item))
        }, (item: FarmerProductRankItem) => `${item.productId}_${item.monthlySales}_${item.price}`)
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(10)
      .rowsGap(10)
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .scrollBar(BarState.Off)
      .cachedCount(AppConstants.LIST_CACHED_COUNT)
      .onReachEnd(() => {
        this.searchDataSource.loadMore();
      })
    }
  }

  /** spec 16.9：搜索结果网格卡片（与商城 RecommendCard 排版一致） */
  @Builder
  ProductGridCard(item: FarmerProductRankItem, idx: number) {
    Column({ space: 8 }) {
      Stack({ alignContent: Alignment.TopStart }) {
        // spec 16.10/16.12：支持真实 file:// / http URI，其他 key 走 ImageUtil 映射（含 AI 海报结果图）
        if (item.imageUrl.startsWith('file://') || item.imageUrl.startsWith('http://') || item.imageUrl.startsWith('https://')) {
          Image(item.imageUrl)
            .width('100%')
            .height(140)
            .borderRadius(8)
            .objectFit(ImageFit.Cover)
        } else {
          ReplaceableImage({ imageKey: item.imageUrl, imgWidth: '100%', imgHeight: 140, imgRadius: 8, imgFit: ImageFit.Cover })
        }
        // 排名角标（前 3 名突出显示）
        if (idx < 3) {
          Text(`${idx + 1}`)
            .fontSize(11)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .width(20)
            .height(20)
            .borderRadius(10)
            .backgroundColor($r('app.color.color_cta_black'))
            .textAlign(TextAlign.Center)
            .position({ x: 6, y: 6 })
        }
      }
      .width('100%')
      .height(140)
      .borderRadius(8)
      .backgroundColor($r('app.color.color_card_yellow'))
      .alignContent(Alignment.Center)

      Text(item.title)
        .fontSize(13)
        .fontColor($r('app.color.color_text_primary'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Text(item.farmerName)
        .fontSize(11)
        .fontColor($r('app.color.color_text_hint'))
        .width('100%')

      Row() {
        Text(`¥${item.price.toFixed(2)}`)
          .fontSize(14)
          .fontColor($r('app.color.color_price'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text(`月销 ${item.monthlySales}`)
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(10)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
  }
}
