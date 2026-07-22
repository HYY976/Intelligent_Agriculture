/**
 * search_page - 搜索页 + 双榜单（spec 3.1.1 / 3.1.2.1）
 * 功能：
 *  - 顶部搜索输入框（防抖联想 + 回车触发搜索 + 保存历史）
 *  - 未搜索态：搜索历史（Preferences 持久化）+ 热门搜索词 Top10 + 双榜单切换（商品榜/直播榜）
 *  - 搜索态：4 Tab 结果（商品 / 直播 / 帖子 / 农户）
 *  - 榜单项点击跳转商品详情/直播间（Phase 2 仅商品详情可用，直播跳转占位）
 */

import { Logger, AppConstants, PreferencesUtil, UserRoutes, RouteName, NavigationHelper, ListStateView } from 'common';
import { SearchHistoryItem, HotWord, RankItem, RankType, SearchResultTab,
  SearchLiveItem, SearchPostItem, SearchFarmerItem } from '../../model/SearchModels';
import { ProductListItem } from '../../model/ProductModels';
import { MOCK_HOT_WORDS, MOCK_PRODUCT_RANK, MOCK_LIVE_RANK,
  getMockSearchSuggestions, getMockSearchLiveResults,
  getMockSearchPostResults, getMockSearchFarmerResults } from '../../mock/SearchMock';
import { SearchResultDataSource } from '../../viewmodel/SearchResultDataSource';
import { ImageUtil } from '../../utils/ImageUtil';
import { ProductCard } from '../../components/ProductCard';

/** 跳转商品详情的路由参数（spec 10.12：ArkTS 严格模式要求具体 interface） */
interface ProductDetailParam {
  productId: string;
}

/** 历史记录最大保存条数 */
const MAX_HISTORY_SIZE: number = 15;
/** 防抖延迟（毫秒） */
const SUGGEST_DEBOUNCE_MS: number = 250;

@ComponentV2
export struct SearchPage {
  /** 搜索输入框文本 */
  @Local keyword: string = '';
  /** 联想词列表 */
  @Local suggestions: string[] = [];
  /** 搜索历史列表 */
  @Local historyList: string[] = [];
  /** 当前是否进入搜索结果态 */
  @Local hasSearched: boolean = false;
  /** 当前结果 Tab */
  @Local resultTab: SearchResultTab = 'product';
  /** 当前榜单类型 */
  @Local rankType: RankType = 'product';
  /** 商品结果数据源（spec 10.11：LazyForEach 迁移） */
  private productDataSource: SearchResultDataSource = new SearchResultDataSource();
  /** 商品结果是否为空 */
  @Local productResultEmpty: boolean = true;
  /** 直播结果 */
  @Local liveResults: SearchLiveItem[] = [];
  /** 帖子结果 */
  @Local postResults: SearchPostItem[] = [];
  /** 农户结果 */
  @Local farmerResults: SearchFarmerItem[] = [];
  /** 防抖定时器 */
  private debounceTimerId: number | undefined = undefined;

  async aboutToAppear(): Promise<void> {
    Logger.info(AppConstants.SCENE_USER, { action: 'search_page_appear' });
    await this.loadHistory();
  }

  /** 从 Preferences 加载搜索历史 */
  private async loadHistory(): Promise<void> {
    const raw: string = await PreferencesUtil.getString(AppConstants.KEY_SEARCH_HISTORY, '');
    if (raw.length > 0) {
      try {
        const arr: SearchHistoryItem[] = JSON.parse(raw) as SearchHistoryItem[];
        const list: string[] = [];
        arr.forEach((it: SearchHistoryItem) => {
          if (it.keyword && it.keyword.length > 0) {
            list.push(it.keyword);
          }
        });
        this.historyList = list;
      } catch (err) {
        Logger.warn(AppConstants.SCENE_USER, { action: 'history_parse_fail', error: (err as Error).message });
        this.historyList = [];
      }
    }
  }

  /** 保存搜索词到历史（去重 + 置顶 + 截断） */
  private async saveHistory(word: string): Promise<void> {
    const trimmed: string = word.trim();
    if (trimmed.length === 0) {
      return;
    }
    const list: string[] = this.historyList.filter((w: string) => w !== trimmed);
    list.unshift(trimmed);
    if (list.length > MAX_HISTORY_SIZE) {
      list.splice(MAX_HISTORY_SIZE, list.length - MAX_HISTORY_SIZE);
    }
    this.historyList = list;
    const records: SearchHistoryItem[] = list.map((w: string): SearchHistoryItem => ({
      keyword: w,
      searchedAt: Date.now()
    }));
    await PreferencesUtil.putString(AppConstants.KEY_SEARCH_HISTORY, JSON.stringify(records));
  }

  /** 清空搜索历史 */
  private async clearHistory(): Promise<void> {
    this.historyList = [];
    await PreferencesUtil.remove(AppConstants.KEY_SEARCH_HISTORY);
    Logger.info(AppConstants.SCENE_USER, { action: 'search_history_cleared' });
  }

  /** 输入框内容变化（防抖联想） */
  private onInputChange(value: string): void {
    this.keyword = value;
    if (this.debounceTimerId !== undefined) {
      clearTimeout(this.debounceTimerId);
    }
    this.debounceTimerId = setTimeout(() => {
      this.suggestions = getMockSearchSuggestions(this.keyword);
    }, SUGGEST_DEBOUNCE_MS);
  }

  /** 触发搜索 */
  private async doSearch(word: string): Promise<void> {
    const trimmed: string = word.trim();
    if (trimmed.length === 0) {
      return;
    }
    this.keyword = trimmed;
    this.suggestions = [];
    this.hasSearched = true;
    this.resultTab = 'product';
    await this.saveHistory(trimmed);
    await this.loadAllResults(trimmed);
    Logger.info(AppConstants.SCENE_USER, JSON.stringify({ action: 'search_execute', keyword: trimmed }));
  }

  /** 加载全部 Tab 结果 */
  private async loadAllResults(word: string): Promise<void> {
    // 商品结果（spec 10.11：迁移至 SearchResultDataSource + LazyForEach 分页）
    this.productDataSource.setKeyword(word);
    await this.productDataSource.refresh();
    this.productResultEmpty = this.productDataSource.totalCount() === 0;
    // 直播/帖子/农户结果（数据量小，保留 ForEach）
    this.liveResults = getMockSearchLiveResults(word);
    this.postResults = getMockSearchPostResults(word);
    this.farmerResults = getMockSearchFarmerResults(word);
  }

  /** 返回上一页 */
  private goBack(): void {
    NavigationHelper.pop();
  }

  /** 跳转商品详情 */
  private gotoProductDetail(productId: string): void {
    const param: ProductDetailParam = { productId: productId };
    NavigationHelper.push(RouteName.USER_PRODUCT_DETAIL, param);
  }

  /** 点击历史/热词直接搜索 */
  private async quickSearch(word: string): Promise<void> {
    await this.doSearch(word);
  }

  /** 清空输入 */
  private clearInput(): void {
    this.keyword = '';
    this.suggestions = [];
    this.hasSearched = false;
    this.productResultEmpty = true;
  }

  /** 切换榜单类型 */
  private switchRank(type: RankType): void {
    this.rankType = type;
  }

  /** 当前榜单数据 */
  private currentRankList(): RankItem[] {
    return this.rankType === 'product' ? MOCK_PRODUCT_RANK : MOCK_LIVE_RANK;
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部搜索栏
        this.SearchHeader()

        // 内容区
        if (this.hasSearched) {
          // 搜索结果态
          this.SearchResultSection()
        } else {
          // 未搜索态：历史 + 热词 + 双榜单
          Scroll() {
            Column() {
              this.HistorySection()
              this.HotWordsSection()
              this.RankSection()
            }
            .width('100%')
            .padding({ bottom: 24 })
          }
          .layoutWeight(1)
          .width('100%')
          .scrollBar(BarState.Off)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_page'))
    }
    .hideTitleBar(true)
  }

  /** 顶部搜索栏（返回 + 输入框 + 搜索按钮） */
  @Builder
  SearchHeader() {
    Row({ space: 8 }) {
      Text('←')
        .fontSize(22)
        .fontColor($r('app.color.color_text_primary'))
        .width(40)
        .height(40)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.goBack();
        })

      Stack({ alignContent: Alignment.End }) {
        TextInput({ text: this.keyword, placeholder: '搜索农产品/直播/帖子/农户' })
          .fontSize(14)
          .height(40)
          .borderRadius(20)
          .backgroundColor($r('app.color.color_bg_page'))
          .padding({ left: 16, right: 40 })
          .onChange((value: string) => {
            this.onInputChange(value);
          })
          .onSubmit(() => {
            this.doSearch(this.keyword);
          })

        if (this.keyword.length > 0) {
          Text('✕')
            .fontSize(14)
            .fontColor($r('app.color.color_text_hint'))
            .width(28)
            .height(28)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.clearInput();
            })
        }
      }
      .layoutWeight(1)

      Text('搜索')
        .fontSize(14)
        .fontColor($r('app.color.color_primary'))
        .fontWeight(FontWeight.Medium)
        .height(40)
        .padding({ left: 4, right: 4 })
        .onClick(() => {
          this.doSearch(this.keyword);
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 12, right: 12 })
    .backgroundColor($r('app.color.color_bg_card'))
    .alignItems(VerticalAlign.Center)

    // 联想词下拉
    if (this.suggestions.length > 0 && !this.hasSearched) {
      Column() {
        ForEach(this.suggestions, (s: string, index: number) => {
          Row() {
            Text('🔍')
              .fontSize(14)
              .fontColor($r('app.color.color_text_hint'))
              .margin({ right: 8 })
            Text(s)
              .fontSize(14)
              .fontColor($r('app.color.color_text_primary'))
              .layoutWeight(1)
            Text(this.historyList.includes(s) ? '历史' : '联想')
              .fontSize(11)
              .fontColor($r('app.color.color_text_hint'))
          }
          .width('100%')
          .height(44)
          .padding({ left: 16, right: 16 })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.quickSearch(s);
          })
          .borderWidth({ bottom: 0.5 })
          .borderColor($r('app.color.color_divider'))
        }, (s: string, index: number) => `suggest_${index}_${s}`)
      }
      .width('100%')
      .backgroundColor($r('app.color.color_bg_card'))
    }
  }

  /** 搜索历史区块 */
  @Builder
  HistorySection() {
    if (this.historyList.length > 0) {
      Column() {
        Row() {
          Text('搜索历史')
            .fontSize(14)
            .fontColor($r('app.color.color_text_primary'))
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
          Text('🗑 清空')
            .fontSize(12)
            .fontColor($r('app.color.color_text_hint'))
            .onClick(() => {
              this.clearHistory();
            })
        }
        .width('100%')

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.historyList, (w: string, index: number) => {
            Text(w)
              .fontSize(13)
              .fontColor($r('app.color.color_text_secondary'))
              .height(32)
              .padding({ left: 14, right: 14 })
              .margin({ right: 8, bottom: 8, top: 8 })
              .borderRadius(16)
              .backgroundColor($r('app.color.color_bg_card'))
              .onClick(() => {
                this.quickSearch(w);
              })
          }, (w: string, index: number) => `hist_${index}_${w}`)
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    }
  }

  /** 热门搜索词区块（spec 3.1.1.2：Top10） */
  @Builder
  HotWordsSection() {
    Column({ space: 8 }) {
      Row() {
        Text('🔥 热门搜索')
          .fontSize(14)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
      }
      .width('100%')

      ForEach(MOCK_HOT_WORDS, (h: HotWord, index: number) => {
        Row() {
          // 排名（前3 高亮）
          Text(`${index + 1}`)
            .fontSize(13)
            .fontColor(index < 3 ? $r('app.color.color_secondary') : $r('app.color.color_text_hint'))
            .fontWeight(FontWeight.Bold)
            .width(24)
          Text(h.word)
            .fontSize(14)
            .fontColor($r('app.color.color_text_primary'))
            .layoutWeight(1)
            .margin({ left: 8 })
          if (h.isNew) {
            Text('NEW')
              .fontSize(10)
              .fontColor(Color.White)
              .backgroundColor($r('app.color.color_secondary'))
              .borderRadius(3)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
          }
          Text(`${h.hotScore}`)
            .fontSize(11)
            .fontColor($r('app.color.color_text_hint'))
            .margin({ left: 8 })
        }
        .width('100%')
        .height(40)
        .padding({ left: 12, right: 12 })
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.quickSearch(h.word);
        })
      }, (h: HotWord, index: number) => `hot_${index}_${h.word}`)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .margin({ top: 8 })
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 双榜单区块（spec 3.1.2.1：月热销商品榜/直播榜 Top10） */
  @Builder
  RankSection() {
    Column() {
      // 标题 + Tab 切换
      Row() {
        Text('🏆 月度榜单')
          .fontSize(16)
          .fontColor($r('app.color.color_text_primary'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 8 })

      // 榜单类型切换
      Row({ space: 0 }) {
        this.RankTabButton('商品榜', 'product')
        this.RankTabButton('直播榜', 'live')
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      // 榜单列表
      ForEach(this.currentRankList(), (item: RankItem, index: number) => {
        this.RankItemView(item, index)
      }, (item: RankItem, index: number) => `rank_${this.rankType}_${index}_${item.targetId}`)
    }
    .width('100%')
    .padding({ bottom: 16 })
    .margin({ top: 8 })
    .backgroundColor($r('app.color.color_bg_card'))
  }

  /** 榜单 Tab 按钮 */
  @Builder
  RankTabButton(label: string, type: RankType) {
    Text(label)
      .fontSize(14)
      .fontColor(this.rankType === type ? Color.White : $r('app.color.color_text_secondary'))
      .fontWeight(this.rankType === type ? FontWeight.Bold : FontWeight.Normal)
      .height(36)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.rankType === type ? $r('app.color.color_primary') : $r('app.color.color_bg_page'))
      .borderRadius(18)
      .margin({ left: 4, right: 4 })
      .onClick(() => {
        this.switchRank(type);
      })
  }

  /** 榜单项视图 */
  @Builder
  RankItemView(item: RankItem, index: number) {
    Row({ space: 12 }) {
      // 排名徽章
      Column() {
        if (item.rank <= 3) {
          Text(item.rank === 1 ? '🥇' : (item.rank === 2 ? '🥈' : '🥉'))
            .fontSize(24)
        } else {
          Text(`${item.rank}`)
            .fontSize(16)
            .fontColor($r('app.color.color_text_hint'))
            .fontWeight(FontWeight.Bold)
        }
      }
      .width(32)
      .alignItems(HorizontalAlign.Center)

      // 封面
      Image(ImageUtil.get(item.coverImage))
        .width(64)
        .height(64)
        .borderRadius(8)
        .objectFit(ImageFit.Cover)

      // 标题 + 卖家 + 数据
      Column({ space: 4 }) {
        Text(item.title)
          .fontSize(14)
          .fontColor($r('app.color.color_text_primary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text(item.sellerName)
          .fontSize(12)
          .fontColor($r('app.color.color_text_secondary'))
        Row({ space: 12 }) {
          Text(this.rankType === 'product' ? `月销 ${this.formatCount(item.monthlyCount)}` : `观看 ${this.formatCount(item.monthlyCount)}`)
            .fontSize(11)
            .fontColor($r('app.color.color_text_hint'))
          Text(`¥${this.formatAmount(item.monthlyAmount)}`)
            .fontSize(11)
            .fontColor($r('app.color.color_price'))
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 关注/进入按钮
      Text(this.rankType === 'product' ? '查看' : '进入')
        .fontSize(12)
        .fontColor($r('app.color.color_primary'))
        .height(28)
        .padding({ left: 12, right: 12 })
        .borderRadius(14)
        .borderWidth(1)
        .borderColor($r('app.color.color_primary'))
        .textAlign(TextAlign.Center)
        .onClick(() => {
          if (item.type === 'product') {
            this.gotoProductDetail(item.targetId);
          } else {
            // 直播间跳转 Phase 3 实现
            Logger.info(AppConstants.SCENE_USER, JSON.stringify({ action: 'goto_live_placeholder', liveId: item.targetId }));
          }
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Center)
  }

  /** 搜索结果区（4 Tab） */
  @Builder
  SearchResultSection() {
    Column() {
      // Tab 栏
      Row() {
        this.ResultTabButton('商品', 'product', this.productDataSource.totalCount())
        this.ResultTabButton('直播', 'live', this.liveResults.length)
        this.ResultTabButton('帖子', 'post', this.postResults.length)
        this.ResultTabButton('农户', 'farmer', this.farmerResults.length)
      }
      .width('100%')
      .height(44)
      .backgroundColor($r('app.color.color_bg_card'))
      .borderWidth({ bottom: 0.5 })
      .borderColor($r('app.color.color_divider'))

      // 结果内容
      Stack() {
        if (this.resultTab === 'product') {
          this.ProductResultList()
        } else if (this.resultTab === 'live') {
          this.LiveResultList()
        } else if (this.resultTab === 'post') {
          this.PostResultList()
        } else {
          this.FarmerResultList()
        }
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .layoutWeight(1)
  }

  /** 结果 Tab 按钮 */
  @Builder
  ResultTabButton(label: string, tab: SearchResultTab, count: number) {
    Column({ space: 2 }) {
      Text(count > 0 ? `${label} ${count}` : label)
        .fontSize(13)
        .fontColor(this.resultTab === tab ? $r('app.color.color_primary') : $r('app.color.color_text_secondary'))
        .fontWeight(this.resultTab === tab ? FontWeight.Bold : FontWeight.Normal)
      // 下划线
      Divider()
        .strokeWidth(this.resultTab === tab ? 2 : 0)
        .color($r('app.color.color_primary'))
        .width(24)
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.resultTab = tab;
    })
  }

  /** 商品结果列表（双列瀑布流，spec 10.11：LazyForEach 迁移） */
  @Builder
  ProductResultList() {
    // spec 10.11.4 Step 4：4 态状态机（error / loading / empty / list）
    if (this.productDataSource.getLoadFailed()) {
      ListStateView({ state: 'error', onRefresh: () => this.doSearch(this.keyword) })
    } else if (this.productDataSource.getIsFirstLoad()) {
      ListStateView({ state: 'loading' })
    } else if (this.productDataSource.totalCount() === 0) {
      ListStateView({
        state: 'empty',
        emptyText: '暂无相关商品',
        emptyDesc: `没有找到与"${this.keyword}"相关的商品`,
        emptyActionText: '换个关键词',
        onEmptyAction: () => {
          this.clearInput();
        }
      })
    } else {
      WaterFlow() {
        LazyForEach(this.productDataSource, (item: ProductListItem, index: number) => {
          FlowItem() {
            ProductCard({
              item: item,
              onCardClick: (pid: string) => {
                this.gotoProductDetail(pid);
              }
            })
          }
          .margin({ bottom: 8 })
        }, (item: ProductListItem) => item.productId + `_${item.monthlySales}_${item.price}`)
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(8)
      .rowsGap(8)
      .padding({ left: 12, right: 12, top: 8, bottom: 12 })
      .cachedCount(AppConstants.LIST_CACHED_COUNT)
      .onReachEnd(() => {
        this.productDataSource.loadMore();
      })
    }
  }

  /** 直播结果列表 */
  @Builder
  LiveResultList() {
    if (this.liveResults.length === 0) {
      ListStateView({
        state: 'empty',
        emptyText: '暂无相关直播',
        emptyDesc: `没有找到与"${this.keyword}"相关的直播`,
        emptyActionText: '换个关键词',
        onEmptyAction: () => {
          this.clearInput();
        }
      })
    } else {
      Scroll() {
        Column({ space: 12 }) {
          ForEach(this.liveResults, (item: SearchLiveItem, index: number) => {
            Row({ space: 12 }) {
              Stack() {
                Image(ImageUtil.get(item.coverImage))
                  .width(120)
                  .height(80)
                  .borderRadius(8)
                  .objectFit(ImageFit.Cover)
                Text('回放')
                  .fontSize(10)
                  .fontColor(Color.White)
                  .backgroundColor('rgba(0,0,0,0.6)')
                  .borderRadius(3)
                  .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                  .position({ x: 6, y: 6 })
              }
              .width(120)
              .height(80)

              Column({ space: 4 }) {
                Text(item.title)
                  .fontSize(14)
                  .fontColor($r('app.color.color_text_primary'))
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')
                Text(item.farmerName)
                  .fontSize(12)
                  .fontColor($r('app.color.color_text_secondary'))
                Text(`累计观看 ${this.formatCount(item.totalViewUv)} 人次`)
                  .fontSize(11)
                  .fontColor($r('app.color.color_text_hint'))
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .backgroundColor($r('app.color.color_bg_card'))
            .borderRadius(12)
            .onClick(() => {
              Logger.info(AppConstants.SCENE_USER, JSON.stringify({ action: 'goto_live_placeholder', liveId: item.liveId }));
            })
          }, (item: SearchLiveItem, index: number) => `result_live_${item.liveId}_${index}`)
        }
        .padding({ top: 12, bottom: 12 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
  }

  /** 帖子结果列表 */
  @Builder
  PostResultList() {
    if (this.postResults.length === 0) {
      ListStateView({
        state: 'empty',
        emptyText: '暂无相关帖子',
        emptyDesc: `没有找到与"${this.keyword}"相关的帖子`,
        emptyActionText: '换个关键词',
        onEmptyAction: () => {
          this.clearInput();
        }
      })
    } else {
      Scroll() {
        Column({ space: 12 }) {
          ForEach(this.postResults, (item: SearchPostItem, index: number) => {
            Row({ space: 12 }) {
              if (item.coverImage && item.coverImage.length > 0) {
                Image(ImageUtil.get(item.coverImage))
                  .width(96)
                  .height(72)
                  .borderRadius(8)
                  .objectFit(ImageFit.Cover)
              } else {
                Column()
                  .width(96)
                  .height(72)
                  .borderRadius(8)
                  .backgroundColor($r('app.color.color_bg_page'))
              }

              Column({ space: 4 }) {
                Text(item.title)
                  .fontSize(14)
                  .fontColor($r('app.color.color_text_primary'))
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')
                Row({ space: 12 }) {
                  Text(item.authorName)
                    .fontSize(12)
                    .fontColor($r('app.color.color_text_secondary'))
                  Text(`👍 ${item.likeCount}`)
                    .fontSize(11)
                    .fontColor($r('app.color.color_text_hint'))
                  Text(`💬 ${item.commentCount}`)
                    .fontSize(11)
                    .fontColor($r('app.color.color_text_hint'))
                }
                .width('100%')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 10, bottom: 10 })
            .backgroundColor($r('app.color.color_bg_card'))
            .borderRadius(12)
          }, (item: SearchPostItem, index: number) => `result_post_${item.postId}_${index}`)
        }
        .padding({ top: 12, bottom: 12 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
  }

  /** 农户结果列表 */
  @Builder
  FarmerResultList() {
    if (this.farmerResults.length === 0) {
      ListStateView({
        state: 'empty',
        emptyText: '暂无相关农户',
        emptyDesc: `没有找到与"${this.keyword}"相关的农户`,
        emptyActionText: '换个关键词',
        onEmptyAction: () => {
          this.clearInput();
        }
      })
    } else {
      Scroll() {
        Column({ space: 12 }) {
          ForEach(this.farmerResults, (item: SearchFarmerItem, index: number) => {
            Row({ space: 12 }) {
              Image(ImageUtil.get(item.avatar))
                .width(56)
                .height(56)
                .borderRadius(28)
                .objectFit(ImageFit.Cover)

              Column({ space: 4 }) {
                Row({ space: 6 }) {
                  Text(item.farmerName)
                    .fontSize(14)
                    .fontColor($r('app.color.color_text_primary'))
                    .fontWeight(FontWeight.Medium)
                  if (item.certified) {
                    Text('✓ 认证')
                      .fontSize(10)
                      .fontColor(Color.White)
                      .backgroundColor($r('app.color.color_primary'))
                      .borderRadius(3)
                      .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                  }
                }
                Text(item.shopIntro)
                  .fontSize(12)
                  .fontColor($r('app.color.color_text_secondary'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')
                Row({ space: 12 }) {
                  Text(`粉丝 ${this.formatCount(item.fansCount)}`)
                    .fontSize(11)
                    .fontColor($r('app.color.color_text_hint'))
                  Text(`商品 ${item.productCount}`)
                    .fontSize(11)
                    .fontColor($r('app.color.color_text_hint'))
                }
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Text(item.followed ? '已关注' : '+ 关注')
                .fontSize(12)
                .fontColor(item.followed ? $r('app.color.color_text_hint') : Color.White)
                .backgroundColor(item.followed ? $r('app.color.color_bg_page') : $r('app.color.color_primary'))
                .height(28)
                .padding({ left: 12, right: 12 })
                .borderRadius(14)
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .backgroundColor($r('app.color.color_bg_card'))
            .borderRadius(12)
            .alignItems(VerticalAlign.Center)
          }, (item: SearchFarmerItem, index: number) => `result_farmer_${item.farmerId}_${index}`)
        }
        .padding({ top: 12, bottom: 12 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
  }

  /** 格式化数量（万） */
  private formatCount(n: number): string {
    if (n >= 10000) {
      return `${(n / 10000).toFixed(1)}万`;
    }
    return `${n}`;
  }

  /** 格式化金额（万） */
  private formatAmount(n: number): string {
    if (n >= 10000) {
      return `${(n / 10000).toFixed(1)}万`;
    }
    return `${n}`;
  }

}
