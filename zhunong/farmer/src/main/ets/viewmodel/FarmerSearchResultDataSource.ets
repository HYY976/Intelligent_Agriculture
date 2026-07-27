/**
 * FarmerSearchResultDataSource - 卖家端搜索结果（商品）数据源
 * 遵循 spec 3.2.1：与用户端搜索页一致（含双榜单），仅商品结果使用 LazyForEach
 * spec 10.11.3：继承 BaseDataSource<T>，仅保留过滤字段 + fetchPage 单一职责
 *
 * 特殊设计：farmer 端搜索结果来自本地榜单数据 + 商城商品（无 Repository 分页接口），
 * DataSource 内部合并商品榜 Mock 数据和商城商品，fetchPage 按 keyword 过滤返回。
 * spec 16.8：同步商城商品，支持关键词搜索
 */

import { AppConstants, BaseDataSource, FetchPageResult, Logger, SharedProductStore, SharedProduct } from 'common';
import { MOCK_FARMER_PRODUCTS } from '../mock/FarmerMock';

/** 商品榜单项（spec 10.12：ArkTS 严格模式要求显式 interface） */
export interface FarmerProductRankItem {
  productId: string;
  title: string;
  price: number;
  monthlySales: number;
  farmerName: string;
  /** spec 16.10：封面图 URI（file:// / http:// / mock key），用于搜索结果展示 */
  imageUrl: string;
  /** spec 16.10：类目 ID，用于按类目关键词精准匹配 */
  categoryId: string;
  /** spec 16.10：发货地（用于详情页展示） */
  shipFrom: string;
}

/** 商品榜 Mock 数据（spec 3.2.1：与页面 loadRankList 一致） */
const MOCK_PRODUCT_RANK: FarmerProductRankItem[] = [
  { productId: 'rk001', title: '陕西洛川苹果 5斤 脆甜多汁', price: 39.90, monthlySales: 9850, farmerName: '洛川果园', imageUrl: 'prod_apple', categoryId: 'cat_fruit', shipFrom: '陕西洛川' },
  { productId: 'rk002', title: '红心蜜柚 5斤装 福建平和', price: 29.90, monthlySales: 8620, farmerName: '平和果农', imageUrl: 'prod_pomelo', categoryId: 'cat_fruit', shipFrom: '福建平和' },
  { productId: 'rk003', title: '新疆灰枣 500g 一级骏枣', price: 25.80, monthlySales: 6580, farmerName: '丝路枣农', imageUrl: 'prod_date', categoryId: 'cat_honey', shipFrom: '新疆' },
  { productId: 'rk004', title: '云南小黄姜 2斤 现挖', price: 19.90, monthlySales: 5630, farmerName: '滇南农场', imageUrl: 'prod_ginger', categoryId: 'cat_vegetable', shipFrom: '云南' },
  { productId: 'rk005', title: '内蒙古土豆 10斤 沙土地', price: 26.80, monthlySales: 4520, farmerName: '草原牧歌', imageUrl: 'prod_potato', categoryId: 'cat_vegetable', shipFrom: '内蒙古' },
  { productId: 'rk006', title: '广西百香果 3斤 紫皮', price: 22.50, monthlySales: 4280, farmerName: '桂南果场', imageUrl: 'prod_passion', categoryId: 'cat_fruit', shipFrom: '广西' },
  { productId: 'rk007', title: '有机青菜 3斤 当季现摘', price: 12.80, monthlySales: 3210, farmerName: '青耕农场', imageUrl: 'prod_vegetable_1', categoryId: 'cat_vegetable', shipFrom: '本地农场' },
  { productId: 'rk008', title: '五常大米 10斤 东北新米', price: 49.90, monthlySales: 5680, farmerName: '黑土地合作社', imageUrl: 'prod_rice', categoryId: 'cat_rice', shipFrom: '黑龙江五常' }
];

/**
 * spec 16.8：从商城商品转换为搜索结果格式
 * 合并商品榜和商城商品，丰富搜索数据源
 * spec 16.10：补充 imageUrl / categoryId / shipFrom 字段
 */
function getMallProductsForSearch(): FarmerProductRankItem[] {
  return MOCK_FARMER_PRODUCTS
    .filter((p) => p.status === 'approved') // 只搜索已上架商品
    .map((p): FarmerProductRankItem => {
      const item: FarmerProductRankItem = {
        productId: p.productId,
        title: p.title,
        price: p.price,
        monthlySales: p.monthlySales,
        farmerName: '我的店铺', // 商城商品统一显示为"我的店铺"
        imageUrl: p.mainImage && p.mainImage.length > 0 ? p.mainImage : 'prod_default',
        categoryId: p.categoryId ?? '',
        shipFrom: '本地农场'
      };
      return item;
    });
}

/** 合并后的完整搜索数据源（商品榜 + 商城已上架商品） */
const ALL_SEARCHABLE_PRODUCTS: FarmerProductRankItem[] = [
  ...MOCK_PRODUCT_RANK,
  ...getMallProductsForSearch()
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
   * spec 16.8：复用合并后的全部数据（商品榜 + 商城商品），按 keyword 模糊匹配过滤
   * spec 16.9：合并 SharedProductStore 中已发布的商品，保证新发布商品可被搜索到
   * 支持搜索：商品标题、卖家名、品类关键词（如"青菜"、"大米"、"茶叶"、"猪肉"、"辣椒"等）
   * @param _page 页码（从 1 开始，仅返回第一页）
   * @param _size 每页条数（忽略，返回全部过滤结果）
   */
  protected async fetchPage(_page: number, _size: number): Promise<FetchPageResult<FarmerProductRankItem>> {
    this.loadFailed = false;
    try {
      // spec 16.9：合并 SharedProductStore 中已发布商品（实时同步）
      const shared: SharedProduct[] = await SharedProductStore.getAll();
      const sharedItems: FarmerProductRankItem[] = shared
        .filter((p: SharedProduct): boolean => p.status === 'approved')
        .map((p: SharedProduct): FarmerProductRankItem => {
          const item: FarmerProductRankItem = {
            productId: p.productId,
            title: p.title,
            price: p.price,
            monthlySales: p.monthlySales,
            farmerName: p.farmerName,
            imageUrl: p.mainImages.length > 0 ? p.mainImages[0] : 'prod_default',
            categoryId: p.categoryId,
            shipFrom: p.shipFrom
          };
          return item;
        });
      // 去重：以 productId 为准，已发布商品优先于 Mock 商品
      const mockIds: Set<string> = new Set<string>(ALL_SEARCHABLE_PRODUCTS.map(
        (p: FarmerProductRankItem): string => p.productId
      ));
      const merged: FarmerProductRankItem[] = ALL_SEARCHABLE_PRODUCTS.slice();
      sharedItems.forEach((it: FarmerProductRankItem) => {
        if (!mockIds.has(it.productId)) {
          merged.unshift(it);
        }
      });

      const kw: string = this.keyword.trim().toLowerCase(); // 统一小写，支持不区分大小写的模糊搜索
      let list: FarmerProductRankItem[];
      if (kw.length === 0) {
        // 无关键词时返回热门商品（销量排序）
        list = merged
          .slice()
          .sort((a: FarmerProductRankItem, b: FarmerProductRankItem): number => b.monthlySales - a.monthlySales)
          .slice(0, 20); // 限制返回数量避免过长
      } else {
        // spec 16.10：精准匹配 - 标题、卖家名、类目名（不再使用全局 categoryMatch 误匹配）
        // 类目 ID → 中文名映射（与发布页保持一致）
        const categoryMap: Record<string, string> = {
          'cat_vegetable': '新鲜果蔬蔬菜青菜',
          'cat_fruit': '时令水果苹果蜜柚百香果',
          'cat_rice': '粮油调味大米粮食五常',
          'cat_tea': '茶饮冲调茶叶绿茶',
          'cat_meat': '肉蛋禽类猪肉鸡肉',
          'cat_honey': '特产滋补蜂蜜红枣'
        };
        list = merged.filter((p: FarmerProductRankItem): boolean => {
          const titleMatch: boolean = p.title.toLowerCase().includes(kw);
          const farmerMatch: boolean = p.farmerName.toLowerCase().includes(kw);
          // 仅匹配该商品所属类目的关键词，避免"青菜"误匹配到苹果/柚子
          const catKeywords: string = categoryMap[p.categoryId] ?? '';
          const categoryMatch: boolean = catKeywords.toLowerCase().includes(kw);
          return titleMatch || farmerMatch || categoryMatch;
        });
      }
      Logger.info(this.scene, {
        action: `${this.actionPrefix}_search`,
        keyword: kw,
        resultCount: list.length
      });
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
