/**
 * ProductModels - 用户端商品域数据模型
 * 遵循 spec 4.1.3 商品实体定义
 * 含商品/SKU/分类/评价/店铺信息
 */

/** 商品 SKU 规格项 */
export interface ProductSkuSpec {
  /** 规格名（如：颜色/尺码/重量） */
  name: string;
  /** 规格值（如：红色/L/5kg） */
  value: string;
}

/** 商品 SKU（spec 4.1.3） */
export interface ProductSku {
  skuId: string;
  productId: string;
  /** 规格组合 */
  specs: ProductSkuSpec[];
  /** SKU 价格（元） */
  price: number;
  /** SKU 库存 */
  stock: number;
  /** SKU 编码 */
  skuCode: string;
}

/** 商品实体（spec 4.1.3） */
export interface Product {
  productId: string;
  farmerId: string;
  /** 商品标题 */
  title: string;
  /** 末级分类 ID */
  categoryId: string;
  /** 主图 URL 数组（最多9张） */
  mainImages: string[];
  /** AI 海报 URL */
  aiPosterUrl?: string;
  /** 富文本描述（前端用纯文本/分段展示） */
  description: string;
  /** 价格（元） */
  price: number;
  /** 总库存 */
  stock: number;
  /** SKU 列表 */
  skuList: ProductSku[];
  /** 发货地 */
  shipFrom: string;
  /** 运费模板 */
  freightTemplate: string;
  /** 月销量 */
  monthlySales: number;
  /** 月销售额 */
  monthlyGmv: number;
  /** 总销量 */
  totalSales: number;
  /** 商品状态 */
  status: 'draft' | 'pending_review' | 'approved' | 'rejected' | 'off_shelf';
  /** 驳回原因 */
  rejectReason?: string;
  createdAt: number;
  updatedAt: number;
}

/** 商品分类（spec 4.1.3） */
export interface Category {
  categoryId: string;
  /** 父分类 ID（null 为一级） */
  parentId: string | null;
  name: string;
  /** 层级 1/2/3 */
  level: 1 | 2 | 3;
  /** 图标 emoji */
  icon?: string;
  /** 排序值 */
  sortOrder: number;
  /** 子分类 */
  children?: Category[];
}

/** 商品评价（spec 4.1.6 Review） */
export interface Review {
  reviewId: string;
  orderId: string;
  productId: string;
  buyerId: string;
  /** 评价人昵称 */
  buyerNickname: string;
  /** 评价人头像 */
  buyerAvatar: string;
  /** 1-5 星 */
  rating: number;
  /** 评价文字 */
  content: string;
  /** 评价图片 URL 数组（最多5张） */
  images: string[];
  /** 卖家回复 */
  farmerReply?: string;
  createdAt: number;
}

/** 商品列表项（首页/商城列表使用，精简字段） */
export interface ProductListItem {
  productId: string;
  title: string;
  /** 主图 URL（取 mainImages[0]） */
  mainImage: string;
  price: number;
  monthlySales: number;
  /** 卖家昵称 */
  farmerName: string;
  /** 发货地 */
  shipFrom: string;
  /** 月销售额（榜单使用） */
  monthlyGmv?: number;
}

/** 店铺信息（spec 4.1.2 SellerInfo 精简） */
export interface ShopInfo {
  farmerId: string;
  shopName: string;
  shopLogo: string;
  shopIntro: string;
  /** 认证状态 */
  certificationStatus: 'pending' | 'approved' | 'rejected';
  totalRevenue: number;
  availableBalance: number;
  followCount: number;
  fansCount: number;
  /** 店铺在售商品 */
  productCount: number;
}

/** 商品列表排序方式 */
export type ProductSortBy = 'comprehensive' | 'sales' | 'price_asc' | 'price_desc' | 'newest';

/** 商品列表查询参数 */
export interface ProductListParam {
  categoryId?: string;
  keyword?: string;
  sortBy: ProductSortBy;
  page: number;
  size: number;
}
