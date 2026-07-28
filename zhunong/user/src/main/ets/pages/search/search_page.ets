/**
 * search_page - 搜索页 + 4 Tab 榜单（对齐设计稿 search.html）
 * 功能：
 *  - 顶部搜索栏：返回 + 输入框（圆角胶囊） + 黄色搜索按钮
 *  - 未搜索态：搜索历史（灰标签）+ 热门搜索（黄标签）+ 4 Tab 排行榜（商品榜/直播榜/农户榜/攻略榜）
 *  - 搜索态：4 Tab 结果（商品 / 直播 / 帖子 / 农户）
 *  - 榜单项点击跳转商品详情/直播间（直播/农户/攻略 Phase 3 跳转占位）
 */

import { Logger, AppConstants, PreferencesUtil, RouteName, NavigationHelper, ListStateView } from 'common';
import { SearchHistoryItem, HotWord, RankItem, RankType, SearchResultTab,
  SearchLiveItem, SearchPostItem, SearchFarmerItem, FarmerRankItem, GuideRankItem } from '../../model/SearchModels';
import { ProductListItem } from '../../model/ProductModels';
import { MOCK_HOT_WORDS, MOCK_PRODUCT_RANK, MOCK_LIVE_RANK, MOCK_FARMER_RANK, MOCK_GUIDE_RANK,
  getMockSearchSuggestions, getMockSearchLiveResults,
  getMockSearchPostResults, getMockSearchFarmerResults } from '../../mock/SearchMock';
import { SearchResultDataSource } from '../../viewmodel/SearchResultDataSource';
import { ImageUtil } from '../../utils/ImageUtil';
import { ProductCard } from '../../components/ProductCard';
import { ReplaceableImage } from '../../components/ReplaceableImage';

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
  /** 当前榜单类型（对齐设计稿：商品榜/直播榜/农户榜/攻略榜） */
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
    Logger.info(AppConstants.SCENE_USER, { action: 'search_execute', keyword: trimmed });
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
          // 未搜索态：历史 + 热词 + 4 Tab 榜单（对齐设计稿 qn-search-body 卡片堆叠）
          Scroll() {
            Column({ space: 12 }) {
              this.HistoryCard()
              this.HotWordsCard()
              this.RankCard()
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 0, bottom: 24 })
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

  /** 顶部搜索栏（对齐设计稿 qn-search-top：返回 + 胶囊输入框 + 黄色搜索按钮） */
  @Builder
  SearchHeader() {
    Column() {
      Row({ space: 10 }) {
        // 返回按钮
        Text('←')
          .fontSize(24)
          .fontColor($r('app.color.color_ink'))
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.goBack();
          })

        // 搜索输入框（胶囊形 + 浅灰底）
        Stack({ alignContent: Alignment.End }) {
          Row({ space: 8 }) {
            Text('🔍')
              .fontSize(14)
              .fontColor($r('app.color.color_text_3'))
            TextInput({ text: this.keyword, placeholder: '搜索助农好物/直播间' })
              .fontSize(14)
              .fontColor($r('app.color.color_ink'))
              .placeholderFont({ size: 14 })
              .placeholderColor($r('app.color.color_text_4'))
              .backgroundColor(Color.Transparent)
              .padding(0)
              .layoutWeight(1)
              .onChange((value: string) => {
                this.onInputChange(value);
              })
              .onSubmit(() => {
                this.doSearch(this.keyword);
              })
          }
          .width('100%')
          .height(40)
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_fill'))
          .padding({ left: 14, right: 40, top: 0, bottom: 0 })
          .alignItems(VerticalAlign.Center)

          // 清空输入按钮
          if (this.keyword.length > 0) {
            Text('✕')
              .fontSize(12)
              .fontColor($r('app.color.color_text_3'))
              .width(28)
              .height(28)
              .textAlign(TextAlign.Center)
              .onClick(() => {
                this.clearInput();
              })
          }
        }
        .layoutWeight(1)

        // 搜索按钮（对齐设计稿 qn-search-btn：黄底 + 墨黑字 + 胶囊圆角）
        Text('搜索')
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .height(40)
          .padding({ left: 18, right: 18 })
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor($r('app.color.color_primary'))
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.doSearch(this.keyword);
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 4, bottom: 12 })
      .alignItems(VerticalAlign.Center)

      // 联想词下拉
      if (this.suggestions.length > 0 && !this.hasSearched) {
        Column() {
          ForEach(this.suggestions, (s: string, index: number) => {
            Row() {
              Text('🔍')
                .fontSize(14)
                .fontColor($r('app.color.color_text_3'))
                .margin({ right: 8 })
              Text(s)
                .fontSize(14)
                .fontColor($r('app.color.color_ink'))
                .layoutWeight(1)
              Text(this.historyList.includes(s) ? '历史' : '联想')
                .fontSize(11)
                .fontColor($r('app.color.color_text_3'))
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
    .width('100%')
  }

  /** 搜索历史卡片（对齐设计稿 qn-card：标题 + 清空 + 灰标签流） */
  @Builder
  HistoryCard() {
    if (this.historyList.length > 0) {
      Column() {
        // 标题 + 清空按钮
        Row() {
          Text('搜索历史')
            .fontSize(16)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
          Row({ space: 3 }) {
            Text('🗑')
              .fontSize(13)
            Text('清空')
              .fontSize(12)
              .fontColor($r('app.color.color_text_3'))
          }
          .onClick(() => {
            this.clearHistory();
          })
        }
        .width('100%')
        .padding({ bottom: 12 })

        // 标签流（对齐设计稿 qn-tag-flow + qn-tag-gray）
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.historyList, (w: string, index: number) => {
            Text(w)
              .fontSize(13)
              .fontColor($r('app.color.color_text_2'))
              .height(32)
              .padding({ left: 14, right: 14 })
              .margin({ right: 10, bottom: 10 })
              .borderRadius(AppConstants.RADIUS_PILL)
              .backgroundColor($r('app.color.color_fill'))
              .onClick(() => {
                this.quickSearch(w);
              })
          }, (w: string, index: number) => `hist_${index}_${w}`)
        }
        .width('100%')
      }
      .width('100%')
      .padding(16)
      .backgroundColor($r('app.color.color_bg_card'))
      .borderRadius(AppConstants.RADIUS_LG)
      .shadow(AppConstants.SHADOW_CARD)
    }
  }

  /** 热门搜索卡片（对齐设计稿：🔥 标题 + 黄标签流） */
  @Builder
  HotWordsCard() {
    Column() {
      // 标题行（对齐设计稿 🔥 图标 + "热门搜索"）
      Row({ space: 5 }) {
        Text('🔥')
          .fontSize(16)
        Text('热门搜索')
          .fontSize(16)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ bottom: 12 })

      // 黄色标签流（对齐设计稿 qn-tag-yellow：浅黄底 + 暗黄字）
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(MOCK_HOT_WORDS.slice(0, 8), (h: HotWord, index: number) => {
          Text(h.word)
            .fontSize(13)
            .fontColor('#B8860B')
            .fontWeight(FontWeight.Medium)
            .height(32)
            .padding({ left: 14, right: 14 })
            .margin({ right: 10, bottom: 10 })
            .borderRadius(AppConstants.RADIUS_PILL)
            .backgroundColor($r('app.color.color_yellow_soft'))
            .onClick(() => {
              this.quickSearch(h.word);
            })
        }, (h: HotWord, index: number) => `hot_${index}_${h.word}`)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 排行榜卡片（对齐设计稿 qn-card + 4 Tab：商品榜/直播榜/农户榜/攻略榜） */
  @Builder
  RankCard() {
    Column() {
      // 标题行（对齐设计稿 qn-section-head：排行榜 + 完整榜单 more）
      Row() {
        Text('排行榜')
          .fontSize(16)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Row({ space: 2 }) {
          Text('完整榜单')
            .fontSize(12)
            .fontColor($r('app.color.color_text_3'))
          Text('›')
            .fontSize(14)
            .fontColor($r('app.color.color_text_3'))
        }
      }
      .width('100%')
      .padding({ bottom: 12 })

      // 4 Tab 栏（对齐设计稿 qn-rank-tabs：底部下划线）
      Row() {
        this.RankTabButton('商品榜', 'product')
        this.RankTabButton('直播榜', 'live')
        this.RankTabButton('农户榜', 'farmer')
        this.RankTabButton('攻略榜', 'guide')
      }
      .width('100%')
      .borderWidth({ bottom: 1 })
      .borderColor($r('app.color.color_divider'))
      .margin({ left: -16, right: -16, bottom: 4 })
      .padding({ left: 16, right: 16 })

      // 当前榜单列表
      if (this.rankType === 'product') {
        ForEach(MOCK_PRODUCT_RANK.slice(0, 5), (item: RankItem, index: number) => {
          this.ProductRankItemView(item)
        }, (item: RankItem, index: number) => `rank_p_${item.targetId}_${index}`)
      } else if (this.rankType === 'live') {
        ForEach(MOCK_LIVE_RANK.slice(0, 4), (item: RankItem, index: number) => {
          this.LiveRankItemView(item)
        }, (item: RankItem, index: number) => `rank_l_${item.targetId}_${index}`)
      } else if (this.rankType === 'farmer') {
        ForEach(MOCK_FARMER_RANK.slice(0, 4), (item: FarmerRankItem, index: number) => {
          this.FarmerRankItemView(item)
        }, (item: FarmerRankItem, index: number) => `rank_f_${item.farmerId}_${index}`)
      } else {
        ForEach(MOCK_GUIDE_RANK.slice(0, 4), (item: GuideRankItem, index: number) => {
          this.GuideRankItemView(item)
        }, (item: GuideRankItem, index: number) => `rank_g_${item.guideId}_${index}`)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(AppConstants.RADIUS_LG)
    .shadow(AppConstants.SHADOW_CARD)
  }

  /** 榜单 Tab 按钮（对齐设计稿 qn-rank-tab + is-active 下划线） */
  @Builder
  RankTabButton(label: string, type: RankType) {
    Column({ space: 0 }) {
      Text(label)
        .fontSize(14)
        .fontColor(this.rankType === type ? $r('app.color.color_ink') : $r('app.color.color_text_3'))
        .fontWeight(this.rankType === type ? FontWeight.Bold : FontWeight.Medium)
        .height(40)
        .textAlign(TextAlign.Center)
      // 下划线（对齐设计稿 ::after 22px×3px 黄色）
      Divider()
        .strokeWidth(this.rankType === type ? 3 : 0)
        .color($r('app.color.color_yellow_deep'))
        .width(22)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.switchRank(type);
    })
  }

  /** 商品榜单项（对齐设计稿 qn-rank-item：排名 + 封面 + 信息 + 价格） */
  @Builder
  ProductRankItemView(item: RankItem) {
    Row({ space: 12 }) {
      // 排名（对齐设计稿：Top1-3 金色，其余灰）
      Text(`${item.rank}`)
        .fontSize(18)
        .fontColor(item.rank <= 3 ? $r('app.color.color_gold') : $r('app.color.color_text_4'))
        .fontWeight(FontWeight.Bold)
        .width(22)
        .textAlign(TextAlign.Center)

      // 封面
      ReplaceableImage({ imageKey: item.coverImage, imgWidth: 52, imgHeight: 52, imgRadius: AppConstants.RADIUS_SM, imgFit: ImageFit.Cover })

      // 标题 + 销量
      Column({ space: 5 }) {
        Text(item.title)
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text(`热销 ${this.formatCount(item.monthlyCount)} 件`)
          .fontSize(11)
          .fontColor($r('app.color.color_text_3'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 价格（对齐设计稿 qn-rank-price：¥ 小 + 数字大）
      Row({ space: 1 }) {
        Text('¥')
          .fontSize(11)
          .fontColor($r('app.color.color_live'))
          .fontWeight(FontWeight.Bold)
        Text(this.formatAmount(item.monthlyAmount))
          .fontSize(16)
          .fontColor($r('app.color.color_live'))
          .fontWeight(FontWeight.Bold)
      }
      .alignItems(VerticalAlign.Bottom)
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .borderWidth({ bottom: 1 })
    .borderColor($r('app.color.color_divider'))
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.gotoProductDetail(item.targetId);
    })
  }

  /** 直播榜单项（对齐设计稿：排名 + 封面 + 标题 + 在看数 + LIVE 标签） */
  @Builder
  LiveRankItemView(item: RankItem) {
    Row({ space: 12 }) {
      Text(`${item.rank}`)
        .fontSize(18)
        .fontColor(item.rank <= 3 ? $r('app.color.color_gold') : $r('app.color.color_text_4'))
        .fontWeight(FontWeight.Bold)
        .width(22)
        .textAlign(TextAlign.Center)

      ReplaceableImage({ imageKey: item.coverImage, imgWidth: 52, imgHeight: 52, imgRadius: AppConstants.RADIUS_SM, imgFit: ImageFit.Cover })

      Column({ space: 5 }) {
        Text(item.title)
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text(`${this.formatCount(item.monthlyCount)}人在看`)
          .fontSize(11)
          .fontColor($r('app.color.color_text_3'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // LIVE 标签（对齐设计稿 qn-pill-live：红底白字 + 圆点）
      Row({ space: 3 }) {
        Text('●')
          .fontSize(8)
          .fontColor(Color.White)
        Text('LIVE')
          .fontSize(10)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
      }
      .backgroundColor($r('app.color.color_live'))
      .borderRadius(AppConstants.RADIUS_PILL)
      .padding({ left: 7, right: 7, top: 2, bottom: 2 })
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .borderWidth({ bottom: 1 })
    .borderColor($r('app.color.color_divider'))
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      Logger.info(AppConstants.SCENE_USER, { action: 'goto_live_placeholder', liveId: item.targetId });
    })
  }

  /** 农户榜单项（对齐设计稿：排名 + 头像 + 信息 + 关注按钮） */
  @Builder
  FarmerRankItemView(item: FarmerRankItem) {
    Row({ space: 12 }) {
      Text(`${item.rank}`)
        .fontSize(18)
        .fontColor(item.rank <= 3 ? $r('app.color.color_gold') : $r('app.color.color_text_4'))
        .fontWeight(FontWeight.Bold)
        .width(22)
        .textAlign(TextAlign.Center)

      Image(ImageUtil.get(item.avatar))
        .width(52)
        .height(52)
        .borderRadius(AppConstants.RADIUS_PILL)
        .objectFit(ImageFit.Cover)

      Column({ space: 5 }) {
        Text(item.farmerName)
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text(`粉丝 ${this.formatCount(item.fansCount)} · 好评率 ${item.goodRate}%`)
          .fontSize(11)
          .fontColor($r('app.color.color_text_3'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 关注按钮（对齐设计稿 qn-pill-green：浅绿底 + 深绿字）
      Text(item.followed ? '已关注' : '关注')
        .fontSize(11)
        .fontColor(item.followed ? $r('app.color.color_text_2') : $r('app.color.color_green_deep'))
        .fontWeight(FontWeight.Bold)
        .height(26)
        .padding({ left: 10, right: 10 })
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor(item.followed ? $r('app.color.color_fill') : $r('app.color.color_green_soft'))
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .borderWidth({ bottom: 1 })
    .borderColor($r('app.color.color_divider'))
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      Logger.info(AppConstants.SCENE_USER, { action: 'goto_farmer_placeholder', farmerId: item.farmerId });
    })
  }

  /** 攻略榜单项（对齐设计稿：排名 + 攻略图标 + 标题 + 阅读收藏数） */
  @Builder
  GuideRankItemView(item: GuideRankItem) {
    Row({ space: 12 }) {
      Text(`${item.rank}`)
        .fontSize(18)
        .fontColor(item.rank <= 3 ? $r('app.color.color_gold') : $r('app.color.color_text_4'))
        .fontWeight(FontWeight.Bold)
        .width(22)
        .textAlign(TextAlign.Center)

      // 攻略图标（对齐设计稿 qn-rank-ico：浅黄底 + 书本 emoji）
      Column() {
        Text('📖')
          .fontSize(22)
          .fontColor('#B8860B')
      }
      .width(52)
      .height(52)
      .borderRadius(AppConstants.RADIUS_SM)
      .backgroundColor($r('app.color.color_yellow_tint'))
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column({ space: 5 }) {
        Text(item.title)
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text(`${this.formatCount(item.readCount)}阅读 · ${item.favoriteCount}收藏`)
          .fontSize(11)
          .fontColor($r('app.color.color_text_3'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('›')
        .fontSize(16)
        .fontColor($r('app.color.color_text_4'))
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .borderWidth({ bottom: 1 })
    .borderColor($r('app.color.color_divider'))
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      Logger.info(AppConstants.SCENE_USER, { action: 'goto_guide_placeholder', guideId: item.guideId });
    })
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
        .fontColor(this.resultTab === tab ? $r('app.color.color_ink') : $r('app.color.color_text_2'))
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
                ReplaceableImage({ imageKey: item.coverImage, imgWidth: 120, imgHeight: 80, imgRadius: AppConstants.RADIUS_MD, imgFit: ImageFit.Cover })
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
                  .fontColor($r('app.color.color_ink'))
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')
                Text(item.farmerName)
                  .fontSize(12)
                  .fontColor($r('app.color.color_text_2'))
                Text(`累计观看 ${this.formatCount(item.totalViewUv)} 人次`)
                  .fontSize(11)
                  .fontColor($r('app.color.color_text_3'))
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .backgroundColor($r('app.color.color_bg_card'))
            .borderRadius(AppConstants.RADIUS_LG)
            .onClick(() => {
              Logger.info(AppConstants.SCENE_USER, { action: 'goto_live_placeholder', liveId: item.liveId });
            })
          }, (item: SearchLiveItem, index: number) => `result_live_${item.liveId}_${index}`)
        }
        .padding({ top: 4, bottom: 12 })
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
                ReplaceableImage({ imageKey: item.coverImage, imgWidth: 96, imgHeight: 72, imgRadius: AppConstants.RADIUS_SM, imgFit: ImageFit.Cover })
              } else {
                Column()
                  .width(96)
                  .height(72)
                  .borderRadius(AppConstants.RADIUS_SM)
                  .backgroundColor($r('app.color.color_fill'))
              }

              Column({ space: 4 }) {
                Text(item.title)
                  .fontSize(14)
                  .fontColor($r('app.color.color_ink'))
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')
                Row({ space: 12 }) {
                  Text(item.authorName)
                    .fontSize(12)
                    .fontColor($r('app.color.color_text_2'))
                  Text(`👍 ${item.likeCount}`)
                    .fontSize(11)
                    .fontColor($r('app.color.color_text_3'))
                  Text(`💬 ${item.commentCount}`)
                    .fontSize(11)
                    .fontColor($r('app.color.color_text_3'))
                }
                .width('100%')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 10, bottom: 10 })
            .backgroundColor($r('app.color.color_bg_card'))
            .borderRadius(AppConstants.RADIUS_LG)
          }, (item: SearchPostItem, index: number) => `result_post_${item.postId}_${index}`)
        }
        .padding({ top: 4, bottom: 12 })
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
                    .fontColor($r('app.color.color_ink'))
                    .fontWeight(FontWeight.Medium)
                  if (item.certified) {
                    Text('✓ 认证')
                      .fontSize(10)
                      .fontColor(Color.White)
                      .backgroundColor($r('app.color.color_ink'))
                      .borderRadius(3)
                      .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                  }
                }
                Text(item.shopIntro)
                  .fontSize(12)
                  .fontColor($r('app.color.color_text_2'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')
                Row({ space: 12 }) {
                  Text(`粉丝 ${this.formatCount(item.fansCount)}`)
                    .fontSize(11)
                    .fontColor($r('app.color.color_text_3'))
                  Text(`商品 ${item.productCount}`)
                    .fontSize(11)
                    .fontColor($r('app.color.color_text_3'))
                }
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Text(item.followed ? '已关注' : '+ 关注')
                .fontSize(12)
                .fontColor(item.followed ? $r('app.color.color_text_3') : Color.White)
                .backgroundColor(item.followed ? $r('app.color.color_fill') : $r('app.color.color_ink'))
                .height(28)
                .padding({ left: 12, right: 12 })
                .borderRadius(14)
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .backgroundColor($r('app.color.color_bg_card'))
            .borderRadius(AppConstants.RADIUS_LG)
            .alignItems(VerticalAlign.Center)
          }, (item: SearchFarmerItem, index: number) => `result_farmer_${item.farmerId}_${index}`)
        }
        .padding({ top: 4, bottom: 12 })
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
