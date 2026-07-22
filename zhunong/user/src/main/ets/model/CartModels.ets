/**
 * CartModels - 用户端购物车域数据模型
 * 遵循 spec 3.1.3.4 购物车 Tab 规范
 * 含购物车商品项/按卖家分组
 */

/** 购物车商品项 */
export interface CartItem {
  /** 购物车项 ID */
  cartItemId: string;
  /** 商品 ID */
  productId: string;
  /** SKU ID（无规格商品为空） */
  skuId?: string;
  /** 商品标题 */
  title: string;
  /** 商品主图 */
  image: string;
  /** 单价（元） */
  price: number;
  /** 购买数量 */
  quantity: number;
  /** 库存上限（用于数量选择器 max） */
  stock: number;
  /** 规格描述（如：红色 / 5kg） */
  specText: string;
  /** 是否选中（结算用） */
  selected: boolean;
}

/** 购物车按卖家分组 */
export interface CartGroup {
  /** 卖家 ID */
  farmerId: string;
  /** 卖家昵称（店铺名） */
  farmerName: string;
  /** 该卖家下购物车项 */
  items: CartItem[];
  /** 该分组是否全选 */
  allSelected: boolean;
}

/** 购物车结算汇总 */
export interface CartSummary {
  /** 选中商品总数 */
  totalCount: number;
  /** 选中商品总金额（不含运费） */
  totalAmount: number;
  /** 是否全选 */
  allSelected: boolean;
  /** 选中分组数（卖家数） */
  selectedGroupCount: number;
}
