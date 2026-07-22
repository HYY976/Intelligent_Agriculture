/**
 * FarmerSearchResultDataSource - 卖家端搜索结果（商品）数据源
 * 遵循 spec 3.2.1：与用户端搜索页一致（含双榜单），仅商品结果使用 LazyForEach
 * spec 10.11.3：继承 BaseDataSource<T>，仅保留过滤字段 + fetchPage 单一职责
 *
 * 特殊设计：farmer 端搜索结果来自本地榜单数据（无 Repository 分页接口），
 * DataSource 内部硬编码商品榜 Mock 数据，fetchPage 按 keyword 过滤返回。
 */

import { AppConstants, BaseDataSource, FetchPageResult, Logger } from 'common';

/** 商品榜单项（spec 10.12：ArkTS 严格模式要求显式 interface） */
export interface FarmerProductRankItem {
  productId: string;
  title: string;
  price: number;
  monthlySales: number;
  farmerName: string;
}

/** 商品榜 Mock 数据（spec 3.2.1：与页面 loadRankList 一致） */
const MOCK_PRODUCT_RANK: FarmerProductRankItem[] = [
  { productId: 'rk001', title: '陕西洛川苹果 5斤 脆甜多汁', price: 39.90, monthlySales: 9850, farmerName: '洛川果园' },
  { productId: 'rk002', title: '红心蜜柚 5斤装 福建平和', price: 29.90, monthlySales: 8620, farmerName: '平和果农' },
  { productId: 'rk003', title: '新疆灰枣 500g 一级骏枣', price: 25.80, monthlySales: 6580, farmerName: '丝路枣农' },
  { productId: 'rk004', title: '云南小黄姜 2斤 现挖', price: 19.90, monthlySales: 5630, farmerName: '滇南农场' },
  { productId: 'rk005', title: '内蒙古土豆 10斤 沙土地', price: 26.80, monthlySales: 4520, farmerName: '草原牧歌' },
  { productId: 'rk006', title: '广西百香果 3斤 紫皮', price: 22.50, monthlySales: 4280, farmerName: '桂南果场' }
];

export class FarmerSearchResultDataSource extends BaseDataSource<FarmerProductRankItem> {
  /** 日志场景名（spec 10.11.3：注入基类） */
  protected readonly scene: string = AppConstants.SCENE_FARMER;
  /** 日志动作前缀（spec 10.11.3：注入基类） */
  protected readonly actionPrefix: string = 'farmer_search_result';

  /** 当前搜索关键词 */
  private keyword: string = '';
  /** 加载失败标志（4 态状态机：fetchPage 内部捕获异常后设置） */
  private loadFailed: boolean = false;

  /** 设置搜索关键词，refresh 后生效 */
  setKeyword(keyword: string): void {
    this.keyword = keyword;
  }

  /** 4 态状态机：是否加载失败（spec 10.13：fetchPage try-catch 暴露错误态） */
  getLoadFailed(): boolean {
    return this.loadFailed;
  }

  /**
   * 单页取数（spec 10.11.3：基类 refresh / loadMore 调用）
   * 复用本地榜单数据，按 keyword 过滤商品标题/卖家名（与原页面逻辑一致）
   * @param _page 页码（从 1 开始，仅返回第一页）
   * @param _size 每页条数（忽略，返回全部过滤结果）
   */
  protected async fetchPage(_page: number, _size: number): Promise<FetchPageResult<FarmerProductRankItem>> {
    this.loadFailed = false;
    try {
      const kw: string = this.keyword.trim();
      let list: FarmerProductRankItem[];
      if (kw.length === 0) {
        list = MOCK_PRODUCT_RANK.slice();
      } else {
        list = MOCK_PRODUCT_RANK.filter((p: FarmerProductRankItem): boolean =>
          p.title.includes(kw) || p.farmerName.includes(kw)
        );
      }
      return { list: list, hasMore: false };
    } catch (err) {
      this.loadFailed = true;
      Logger.error(this.scene, {
        action: `${this.actionPrefix}_fetch_fail`,
        page: _page,
        error: (err as Error).message
      });
      return { list: [], hasMore: false };
    }
  }
}
