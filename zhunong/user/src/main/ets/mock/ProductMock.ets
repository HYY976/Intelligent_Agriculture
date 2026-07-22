/**
 * ProductMock - 商品域 Mock 数据
 * 遵循 spec 4.1.3 商品实体定义，本地 Mock 供 Phase 2 全部页面使用
 * 商品图使用本地 SVG（key 经 ImageUtil 解析）
 */

import { Product, ProductSku, ProductSkuSpec, Category, ProductListItem } from '../model/ProductModels';
import { ProductSortBy } from '../model/ProductModels';

/** 商品列表分页结果 */
export interface ProductListResult {
  list: ProductListItem[];
  hasMore: boolean;
}

/** 商品 Mock 数据（15 个商品，覆盖各分类） */
export const MOCK_PRODUCTS: Product[] = [
  {
    productId: 'p001',
    farmerId: 'f001',
    title: '有机青菜 500g 当季新鲜 直采直发',
    categoryId: 'c111',
    mainImages: ['prod_vegetable_1', 'prod_vegetable_2', 'prod_corn_1'],
    description: '产自高山有机农场，无农药无化肥，叶色翠绿，口感清甜。每日清晨采摘，冷链配送，保证新鲜到家。建议清炒或做汤，保留原汁原味。',
    price: 9.90,
    stock: 568,
    skuList: [
      { skuId: 's0011', productId: 'p001', specs: [{ name: '规格', value: '250g' }], price: 5.90, stock: 200, skuCode: 'P001-250' },
      { skuId: 's0012', productId: 'p001', specs: [{ name: '规格', value: '500g' }], price: 9.90, stock: 188, skuCode: 'P001-500' },
      { skuId: 's0013', productId: 'p001', specs: [{ name: '规格', value: '1kg' }], price: 18.80, stock: 180, skuCode: 'P001-1K' }
    ],
    shipFrom: '云南·昆明',
    freightTemplate: '满39包邮',
    monthlySales: 5680,
    monthlyGmv: 56800,
    totalSales: 28650,
    status: 'approved',
    createdAt: 1736000000000,
    updatedAt: 1736900000000
  },
  {
    productId: 'p002',
    farmerId: 'f002',
    title: '土鸡蛋30枚 散养土鸡 营养丰富',
    categoryId: 'c131',
    mainImages: ['prod_egg_1'],
    description: '散养土鸡所产，蛋黄金黄饱满，蛋清浓稠。无激素无抗生素，孕妇婴儿辅食首选。包装采用珍珠棉防震，破损包赔。',
    price: 39.90,
    stock: 320,
    skuList: [
      { skuId: 's0021', productId: 'p002', specs: [{ name: '规格', value: '10枚' }], price: 15.90, stock: 100, skuCode: 'P002-10' },
      { skuId: 's0022', productId: 'p002', specs: [{ name: '规格', value: '30枚' }], price: 39.90, stock: 120, skuCode: 'P002-30' },
      { skuId: 's0023', productId: 'p002', specs: [{ name: '规格', value: '50枚' }], price: 65.00, stock: 100, skuCode: 'P002-50' }
    ],
    shipFrom: '湖南·长沙',
    freightTemplate: '满59包邮',
    monthlySales: 3260,
    monthlyGmv: 130200,
    totalSales: 18650,
    status: 'approved',
    createdAt: 1736100000000,
    updatedAt: 1736800000000
  },
  {
    productId: 'p003',
    farmerId: 'f001',
    title: '农家大米5kg 当季新米 软糯香甜',
    categoryId: 'c121',
    mainImages: ['prod_rice_1'],
    description: '当季新稻，颗粒饱满，煮饭软糯香甜，米香浓郁。产自东北黑土地，无抛光无打蜡，原生态好米。',
    price: 59.00,
    stock: 480,
    skuList: [
      { skuId: 's0031', productId: 'p003', specs: [{ name: '规格', value: '2.5kg' }], price: 32.00, stock: 180, skuCode: 'P003-25' },
      { skuId: 's0032', productId: 'p003', specs: [{ name: '规格', value: '5kg' }], price: 59.00, stock: 200, skuCode: 'P003-5' },
      { skuId: 's0033', productId: 'p003', specs: [{ name: '规格', value: '10kg' }], price: 115.00, stock: 100, skuCode: 'P003-10' }
    ],
    shipFrom: '黑龙江·五常',
    freightTemplate: '满99包邮',
    monthlySales: 2180,
    monthlyGmv: 128620,
    totalSales: 12350,
    status: 'approved',
    createdAt: 1736200000000,
    updatedAt: 1736700000000
  },
  {
    productId: 'p004',
    farmerId: 'f002',
    title: '新鲜番茄 1kg 沙瓤多汁 沙漠日光温室',
    categoryId: 'c112',
    mainImages: ['prod_vegetable_2'],
    description: '沙漠日光温室种植，昼夜温差大，糖分积累足。沙瓤多汁，酸甜可口，生吃做菜两相宜。',
    price: 12.80,
    stock: 680,
    skuList: [
      { skuId: 's0041', productId: 'p004', specs: [{ name: '规格', value: '500g' }], price: 7.80, stock: 280, skuCode: 'P004-05' },
      { skuId: 's0042', productId: 'p004', specs: [{ name: '规格', value: '1kg' }], price: 12.80, stock: 200, skuCode: 'P004-1' },
      { skuId: 's0043', productId: 'p004', specs: [{ name: '规格', value: '2kg' }], price: 23.80, stock: 200, skuCode: 'P004-2' }
    ],
    shipFrom: '宁夏·中卫',
    freightTemplate: '满39包邮',
    monthlySales: 4520,
    monthlyGmv: 57856,
    totalSales: 23560,
    status: 'approved',
    createdAt: 1736300000000,
    updatedAt: 1736900000000
  },
  {
    productId: 'p005',
    farmerId: 'f003',
    title: '冰糖橙 5斤 当季鲜果 甜度高',
    categoryId: 'c211',
    mainImages: ['prod_fruit_1'],
    description: '冰糖橙产自湖南麻阳，皮薄无渣，甜度高达 16°。果肉饱满多汁，秋冬润燥佳品。坏果包赔。',
    price: 29.90,
    stock: 880,
    skuList: [
      { skuId: 's0051', productId: 'p005', specs: [{ name: '规格', value: '5斤' }], price: 29.90, stock: 380, skuCode: 'P005-5' },
      { skuId: 's0052', productId: 'p005', specs: [{ name: '规格', value: '9斤' }], price: 49.90, stock: 300, skuCode: 'P005-9' },
      { skuId: 's0053', productId: 'p005', specs: [{ name: '规格', value: '整箱20斤' }], price: 99.00, stock: 200, skuCode: 'P005-20' }
    ],
    shipFrom: '湖南·怀化',
    freightTemplate: '满49包邮',
    monthlySales: 6890,
    monthlyGmv: 206011,
    totalSales: 35620,
    status: 'approved',
    createdAt: 1736400000000,
    updatedAt: 1736950000000
  },
  {
    productId: 'p006',
    farmerId: 'f003',
    title: '海南香蕉 5斤 当季自然熟 无催熟',
    categoryId: 'c212',
    mainImages: ['prod_fruit_2'],
    description: '海南直发香蕉，树上自然成熟，不使用催熟剂。口感软糯香甜，老少皆宜。收到后可常温放置 2-3 天食用。',
    price: 19.90,
    stock: 560,
    skuList: [
      { skuId: 's0061', productId: 'p006', specs: [{ name: '规格', value: '3斤' }], price: 13.90, stock: 200, skuCode: 'P006-3' },
      { skuId: 's0062', productId: 'p006', specs: [{ name: '规格', value: '5斤' }], price: 19.90, stock: 200, skuCode: 'P006-5' },
      { skuId: 's0063', productId: 'p006', specs: [{ name: '规格', value: '10斤' }], price: 36.80, stock: 160, skuCode: 'P006-10' }
    ],
    shipFrom: '海南·三亚',
    freightTemplate: '满39包邮',
    monthlySales: 3120,
    monthlyGmv: 62188,
    totalSales: 18560,
    status: 'approved',
    createdAt: 1736500000000,
    updatedAt: 1736800000000
  },
  {
    productId: 'p007',
    farmerId: 'f001',
    title: '高山绿茶 250g 明前嫩芽 清香回甘',
    categoryId: 'c311',
    mainImages: ['prod_tea_1'],
    description: '海拔 1200 米高山茶园，明前采摘嫩芽，传统工艺炒制。汤色嫩绿明亮，清香持久，回甘生津。',
    price: 68.00,
    stock: 280,
    skuList: [
      { skuId: 's0071', productId: 'p007', specs: [{ name: '规格', value: '100g' }], price: 32.00, stock: 100, skuCode: 'P007-1' },
      { skuId: 's0072', productId: 'p007', specs: [{ name: '规格', value: '250g' }], price: 68.00, stock: 100, skuCode: 'P007-2' },
      { skuId: 's0073', productId: 'p007', specs: [{ name: '规格', value: '500g礼盒' }], price: 128.00, stock: 80, skuCode: 'P007-3' }
    ],
    shipFrom: '浙江·杭州',
    freightTemplate: '满88包邮',
    monthlySales: 980,
    monthlyGmv: 66640,
    totalSales: 6520,
    status: 'approved',
    createdAt: 1736600000000,
    updatedAt: 1736900000000
  },
  {
    productId: 'p008',
    farmerId: 'f002',
    title: '山核桃 250g 临安特产 香酥脆',
    categoryId: 'c411',
    mainImages: ['prod_nut_1'],
    description: '临安天目山山核桃，果仁饱满，香酥脆口。传统炭焙工艺，少盐少油更健康。办公室零食首选。',
    price: 45.90,
    stock: 420,
    skuList: [
      { skuId: 's0081', productId: 'p008', specs: [{ name: '规格', value: '100g' }], price: 22.90, stock: 150, skuCode: 'P008-1' },
      { skuId: 's0082', productId: 'p008', specs: [{ name: '规格', value: '250g' }], price: 45.90, stock: 150, skuCode: 'P008-2' },
      { skuId: 's0083', productId: 'p008', specs: [{ name: '规格', value: '500g' }], price: 85.00, stock: 120, skuCode: 'P008-3' }
    ],
    shipFrom: '浙江·临安',
    freightTemplate: '满59包邮',
    monthlySales: 1860,
    monthlyGmv: 85374,
    totalSales: 9860,
    status: 'approved',
    createdAt: 1736700000000,
    updatedAt: 1736900000000
  },
  {
    productId: 'p009',
    farmerId: 'f003',
    title: '土蜂蜜 500g 百花蜜 农家自酿',
    categoryId: 'c321',
    mainImages: ['prod_honey_1'],
    description: '深山百花蜜，农家自酿无添加。色泽金黄，口感醇厚，富含多种活性酶。温水冲泡饮用，润肠养胃。',
    price: 89.00,
    stock: 320,
    skuList: [
      { skuId: 's0091', productId: 'p009', specs: [{ name: '规格', value: '250g' }], price: 48.00, stock: 120, skuCode: 'P009-1' },
      { skuId: 's0092', productId: 'p009', specs: [{ name: '规格', value: '500g' }], price: 89.00, stock: 120, skuCode: 'P009-2' },
      { skuId: 's0093', productId: 'p009', specs: [{ name: '规格', value: '1kg' }], price: 168.00, stock: 80, skuCode: 'P009-3' }
    ],
    shipFrom: '云南·大理',
    freightTemplate: '满99包邮',
    monthlySales: 1240,
    monthlyGmv: 110360,
    totalSales: 7820,
    status: 'approved',
    createdAt: 1736800000000,
    updatedAt: 1736900000000
  },
  {
    productId: 'p010',
    farmerId: 'f001',
    title: '土猪肉 1kg 农家散养 黑猪肉',
    categoryId: 'c131',
    mainImages: ['prod_meat_1'],
    description: '农家散养黑猪，自然生长周期 10 个月。肉质紧实，肥瘦相间，炖煮炒皆宜。冷链配送，新鲜到家。',
    price: 78.00,
    stock: 180,
    skuList: [
      { skuId: 's0101', productId: 'p010', specs: [{ name: '部位', value: '五花肉' }, { name: '规格', value: '500g' }], price: 42.00, stock: 60, skuCode: 'P010-W5' },
      { skuId: 's0102', productId: 'p010', specs: [{ name: '部位', value: '五花肉' }, { name: '规格', value: '1kg' }], price: 78.00, stock: 60, skuCode: 'P010-W1' },
      { skuId: 's0103', productId: 'p010', specs: [{ name: '部位', value: '排骨' }, { name: '规格', value: '500g' }], price: 48.00, stock: 60, skuCode: 'P010-P5' }
    ],
    shipFrom: '四川·成都',
    freightTemplate: '冷链运费15元',
    monthlySales: 890,
    monthlyGmv: 69420,
    totalSales: 5630,
    status: 'approved',
    createdAt: 1736900000000,
    updatedAt: 1736950000000
  },
  {
    productId: 'p011',
    farmerId: 'f002',
    title: '红薯干 250g 农家自晒 无添加',
    categoryId: 'c421',
    mainImages: ['prod_dried_1'],
    description: '农家自晒红薯干，选用蜜薯品种，自然晾晒 7 天。无糖无添加，软糯有嚼劲，解馋健康小零食。',
    price: 19.90,
    stock: 380,
    skuList: [
      { skuId: 's0111', productId: 'p011', specs: [{ name: '规格', value: '100g' }], price: 9.90, stock: 150, skuCode: 'P011-1' },
      { skuId: 's0112', productId: 'p011', specs: [{ name: '规格', value: '250g' }], price: 19.90, stock: 130, skuCode: 'P011-2' },
      { skuId: 's0113', productId: 'p011', specs: [{ name: '规格', value: '500g' }], price: 36.80, stock: 100, skuCode: 'P011-3' }
    ],
    shipFrom: '福建·龙岩',
    freightTemplate: '满39包邮',
    monthlySales: 2680,
    monthlyGmv: 53332,
    totalSales: 14250,
    status: 'approved',
    createdAt: 1737000000000,
    updatedAt: 1737100000000
  },
  {
    productId: 'p012',
    farmerId: 'f003',
    title: '香菇 500g 山珍鲜菇 肉厚味鲜',
    categoryId: 'c113',
    mainImages: ['prod_mushroom_1'],
    description: '深山椴木栽培香菇，朵大肉厚，香气浓郁。富含多种氨基酸，炖汤炒菜提鲜佳品。新鲜采摘，冷链配送。',
    price: 32.00,
    stock: 280,
    skuList: [
      { skuId: 's0121', productId: 'p012', specs: [{ name: '规格', value: '250g' }], price: 18.00, stock: 100, skuCode: 'P012-1' },
      { skuId: 's0122', productId: 'p012', specs: [{ name: '规格', value: '500g' }], price: 32.00, stock: 100, skuCode: 'P012-2' },
      { skuId: 's0123', productId: 'p012', specs: [{ name: '规格', value: '1kg' }], price: 58.00, stock: 80, skuCode: 'P012-3' }
    ],
    shipFrom: '湖北·神农架',
    freightTemplate: '满49包邮',
    monthlySales: 1680,
    monthlyGmv: 53760,
    totalSales: 8960,
    status: 'approved',
    createdAt: 1737100000000,
    updatedAt: 1737300000000
  },
  {
    productId: 'p013',
    farmerId: 'f001',
    title: '小米辣 250g 农家自种 辣味十足',
    categoryId: 'c114',
    mainImages: ['prod_chili_1'],
    description: '农家自种小米辣，个头小巧但辣味十足。鲜红油亮，做泡菜、炒菜、蘸料皆宜。新鲜现摘，当日发货。',
    price: 8.80,
    stock: 680,
    skuList: [
      { skuId: 's0131', productId: 'p013', specs: [{ name: '规格', value: '100g' }], price: 4.50, stock: 280, skuCode: 'P013-1' },
      { skuId: 's0132', productId: 'p013', specs: [{ name: '规格', value: '250g' }], price: 8.80, stock: 200, skuCode: 'P013-2' },
      { skuId: 's0133', productId: 'p013', specs: [{ name: '规格', value: '500g' }], price: 15.80, stock: 200, skuCode: 'P013-3' }
    ],
    shipFrom: '贵州·遵义',
    freightTemplate: '满29包邮',
    monthlySales: 5230,
    monthlyGmv: 46024,
    totalSales: 28560,
    status: 'approved',
    createdAt: 1737200000000,
    updatedAt: 1737400000000
  },
  {
    productId: 'p014',
    farmerId: 'f002',
    title: '甜糯玉米 8根 真空包装 当季新粮',
    categoryId: 'c122',
    mainImages: ['prod_corn_1'],
    description: '当季甜糯玉米，颗粒饱满，软糯香甜。真空包装锁鲜，蒸煮 15 分钟即可食用。粗粮主食好选择。',
    price: 39.90,
    stock: 520,
    skuList: [
      { skuId: 's0141', productId: 'p014', specs: [{ name: '规格', value: '4根' }], price: 22.90, stock: 200, skuCode: 'P014-1' },
      { skuId: 's0142', productId: 'p014', specs: [{ name: '规格', value: '8根' }], price: 39.90, stock: 200, skuCode: 'P014-2' },
      { skuId: 's0143', productId: 'p014', specs: [{ name: '规格', value: '16根' }], price: 75.00, stock: 120, skuCode: 'P014-3' }
    ],
    shipFrom: '吉林·松原',
    freightTemplate: '满59包邮',
    monthlySales: 3420,
    monthlyGmv: 136458,
    totalSales: 19560,
    status: 'approved',
    createdAt: 1737300000000,
    updatedAt: 1737500000000
  },
  {
    productId: 'p015',
    farmerId: 'f003',
    title: '毛豆 500g 鲜嫩翠绿 农家直采',
    categoryId: 'c115',
    mainImages: ['prod_bean_1'],
    description: '农家直采鲜毛豆，豆荚饱满，颗粒翠绿。水煮加盐即可，清香可口。富含植物蛋白，健康佐餐小菜。',
    price: 6.90,
    stock: 880,
    skuList: [
      { skuId: 's0151', productId: 'p015', specs: [{ name: '规格', value: '250g' }], price: 4.50, stock: 380, skuCode: 'P015-1' },
      { skuId: 's0152', productId: 'p015', specs: [{ name: '规格', value: '500g' }], price: 6.90, stock: 300, skuCode: 'P015-2' },
      { skuId: 's0153', productId: 'p015', specs: [{ name: '规格', value: '1kg' }], price: 12.80, stock: 200, skuCode: 'P015-3' }
    ],
    shipFrom: '江苏·盐城',
    freightTemplate: '满29包邮',
    monthlySales: 6890,
    monthlyGmv: 47541,
    totalSales: 38520,
    status: 'approved',
    createdAt: 1737400000000,
    updatedAt: 1737600000000
  }
];

/** 卖家昵称映射（farmerId → 名称） */
export const MOCK_FARMER_NAMES: Record<string, string> = {
  'f001': '青禾农庄',
  'f002': '山野好物',
  'f003': '田园牧歌'
};

/** 卖家头像映射（farmerId → 头像 key） */
export const MOCK_FARMER_AVATARS: Record<string, string> = {
  'f001': 'avatar_farmer_1',
  'f002': 'avatar_farmer_2',
  'f003': 'avatar_farmer_3'
};

/** 三级分类树 Mock（spec 3.1.4.1） */
export const MOCK_CATEGORIES: Category[] = [
  {
    categoryId: 'c1', parentId: null, name: '生鲜水果', level: 1, icon: '🍎', sortOrder: 1,
    children: [
      {
        categoryId: 'c11', parentId: 'c1', name: '蔬菜', level: 2, icon: '🥬', sortOrder: 1,
        children: [
          { categoryId: 'c111', parentId: 'c11', name: '叶菜', level: 3, icon: '🥬', sortOrder: 1 },
          { categoryId: 'c112', parentId: 'c11', name: '茄果', level: 3, icon: '🍅', sortOrder: 2 },
          { categoryId: 'c113', parentId: 'c11', name: '菌菇', level: 3, icon: '🍄', sortOrder: 3 },
          { categoryId: 'c114', parentId: 'c11', name: '辣椒', level: 3, icon: '🌶️', sortOrder: 4 },
          { categoryId: 'c115', parentId: 'c11', name: '豆类', level: 3, icon: '🫛', sortOrder: 5 }
        ]
      },
      {
        categoryId: 'c12', parentId: 'c1', name: '水果', level: 2, icon: '🍊', sortOrder: 2,
        children: [
          { categoryId: 'c121', parentId: 'c12', name: '柑橘', level: 3, icon: '🍊', sortOrder: 1 },
          { categoryId: 'c122', parentId: 'c12', name: '热带水果', level: 3, icon: '🍌', sortOrder: 2 },
          { categoryId: 'c123', parentId: 'c12', name: '时令鲜果', level: 3, icon: '🍇', sortOrder: 3 }
        ]
      },
      {
        categoryId: 'c13', parentId: 'c1', name: '肉禽蛋品', level: 2, icon: '🥩', sortOrder: 3,
        children: [
          { categoryId: 'c131', parentId: 'c13', name: '蛋品', level: 3, icon: '🥚', sortOrder: 1 },
          { categoryId: 'c132', parentId: 'c13', name: '猪肉', level: 3, icon: '🥩', sortOrder: 2 },
          { categoryId: 'c133', parentId: 'c13', name: '禽类', level: 3, icon: '🐔', sortOrder: 3 }
        ]
      }
    ]
  },
  {
    categoryId: 'c2', parentId: null, name: '粮油调味', level: 1, icon: '🌾', sortOrder: 2,
    children: [
      {
        categoryId: 'c21', parentId: 'c2', name: '米面油', level: 2, icon: '🌾', sortOrder: 1,
        children: [
          { categoryId: 'c211', parentId: 'c21', name: '大米', level: 3, icon: '🌾', sortOrder: 1 },
          { categoryId: 'c212', parentId: 'c21', name: '杂粮', level: 3, icon: '🌽', sortOrder: 2 },
          { categoryId: 'c213', parentId: 'c21', name: '食用油', level: 3, icon: '🫒', sortOrder: 3 }
        ]
      }
    ]
  },
  {
    categoryId: 'c3', parentId: null, name: '茶饮冲调', level: 1, icon: '🍵', sortOrder: 3,
    children: [
      {
        categoryId: 'c31', parentId: 'c3', name: '茶叶', level: 2, icon: '🍵', sortOrder: 1,
        children: [
          { categoryId: 'c311', parentId: 'c31', name: '绿茶', level: 3, icon: '🍵', sortOrder: 1 },
          { categoryId: 'c312', parentId: 'c31', name: '红茶', level: 3, icon: '🫖', sortOrder: 2 }
        ]
      },
      {
        categoryId: 'c32', parentId: 'c3', name: '冲饮', level: 2, icon: '🥤', sortOrder: 2,
        children: [
          { categoryId: 'c321', parentId: 'c32', name: '蜂蜜', level: 3, icon: '🍯', sortOrder: 1 },
          { categoryId: 'c322', parentId: 'c32', name: '果汁', level: 3, icon: '🧃', sortOrder: 2 }
        ]
      }
    ]
  },
  {
    categoryId: 'c4', parentId: null, name: '坚果干货', level: 1, icon: '🥜', sortOrder: 4,
    children: [
      {
        categoryId: 'c41', parentId: 'c4', name: '坚果', level: 2, icon: '🥜', sortOrder: 1,
        children: [
          { categoryId: 'c411', parentId: 'c41', name: '核桃', level: 3, icon: '🥜', sortOrder: 1 },
          { categoryId: 'c412', parentId: 'c41', name: '瓜子', level: 3, icon: '🌻', sortOrder: 2 }
        ]
      },
      {
        categoryId: 'c42', parentId: 'c4', name: '干货', level: 2, icon: '🍠', sortOrder: 2,
        children: [
          { categoryId: 'c421', parentId: 'c42', name: '果干', level: 3, icon: '🍠', sortOrder: 1 },
          { categoryId: 'c422', parentId: 'c42', name: '菌干', level: 3, icon: '🍄', sortOrder: 2 }
        ]
      }
    ]
  }
];

/**
 * 商品列表项 Mock 生成（首页推荐流/商品列表共用）
 * @param page 页码（从1开始）
 * @param size 每页条数
 * @param categoryId 末级分类ID（可选）
 * @param keyword 关键词（可选）
 * @param sortBy 排序方式
 * @returns 列表 + 是否还有更多
 */
export function getMockProductList(
  page: number,
  size: number,
  categoryId?: string,
  keyword?: string,
  sortBy: ProductSortBy = 'comprehensive'
): ProductListResult {
  // 1. 过滤
  let filtered: Product[] = MOCK_PRODUCTS.slice();
  if (categoryId) {
    filtered = filtered.filter((p: Product) => p.categoryId === categoryId);
  }
  if (keyword && keyword.length > 0) {
    const kw: string = keyword.toLowerCase();
    filtered = filtered.filter((p: Product) =>
      p.title.toLowerCase().indexOf(kw) >= 0 ||
      p.description.toLowerCase().indexOf(kw) >= 0
    );
  }
  // 2. 排序
  switch (sortBy) {
    case 'sales':
      filtered.sort((a: Product, b: Product) => b.monthlySales - a.monthlySales);
      break;
    case 'price_asc':
      filtered.sort((a: Product, b: Product) => a.price - b.price);
      break;
    case 'price_desc':
      filtered.sort((a: Product, b: Product) => b.price - a.price);
      break;
    case 'newest':
      filtered.sort((a: Product, b: Product) => b.createdAt - a.createdAt);
      break;
    case 'comprehensive':
    default:
      filtered.sort((a: Product, b: Product) => b.monthlyGmv - a.monthlyGmv);
      break;
  }
  // 3. 分页（模拟无限流：到末尾后循环返回，hasMore 在 page>=3 后置 false）
  const total: number = filtered.length;
  const maxPage: number = 3; // Mock 最多 3 页
  const hasMore: boolean = page < maxPage;
  const start: number = (page - 1) * size;
  let pageItems: Product[] = [];
  if (start < total) {
    pageItems = filtered.slice(start, start + size);
    // 不足一页时循环填充（模拟无限流）
    while (pageItems.length < size && filtered.length > 0) {
      const remain: number = size - pageItems.length;
      pageItems = pageItems.concat(filtered.slice(0, Math.min(remain, filtered.length)));
    }
  } else {
    // 超出总数：循环返回数据
    const cycled: Product[] = [];
    for (let i: number = 0; i < size; i++) {
      cycled.push(filtered[(start + i) % filtered.length]);
    }
    pageItems = cycled;
  }
  // 4. 转换为 ProductListItem
  const list: ProductListItem[] = pageItems.map((p: Product): ProductListItem => {
    return {
      productId: p.productId,
      title: p.title,
      mainImage: p.mainImages[0],
      price: p.price,
      monthlySales: p.monthlySales,
      farmerName: MOCK_FARMER_NAMES[p.farmerId] ?? '未知卖家',
      shipFrom: p.shipFrom,
      monthlyGmv: p.monthlyGmv
    };
  });
  return { list: list, hasMore: hasMore };
}

/** 根据 productId 查询商品详情 */
export function getMockProductById(productId: string): Product | null {
  const found: Product | undefined = MOCK_PRODUCTS.find((p: Product) => p.productId === productId);
  return found ?? null;
}

/** 递归查找分类节点（内部辅助函数） */
function searchCategoryById(nodes: Category[], categoryId: string): Category | null {
  for (let i: number = 0; i < nodes.length; i++) {
    if (nodes[i].categoryId === categoryId) {
      return nodes[i];
    }
    if (nodes[i].children) {
      const r: Category | null = searchCategoryById(nodes[i].children!, categoryId);
      if (r) {
        return r;
      }
    }
  }
  return null;
}

/** 根据 categoryId 递归查询分类 */
export function getMockCategoryById(categoryId: string): Category | null {
  return searchCategoryById(MOCK_CATEGORIES, categoryId);
}

/** 递归查找分类路径（内部辅助函数） */
function searchCategoryPath(nodes: Category[], path: string, categoryId: string): string {
  for (let i: number = 0; i < nodes.length; i++) {
    const cur: string = path.length > 0 ? `${path} > ${nodes[i].name}` : nodes[i].name;
    if (nodes[i].categoryId === categoryId) {
      return cur;
    }
    if (nodes[i].children) {
      const r: string = searchCategoryPath(nodes[i].children!, cur, categoryId);
      if (r.length > 0) {
        return r;
      }
    }
  }
  return '';
}

/** 获取全部分类路径（categoryId → 一级/二级/三级名） */
export function getMockCategoryPath(categoryId: string): string {
  return searchCategoryPath(MOCK_CATEGORIES, '', categoryId);
}
