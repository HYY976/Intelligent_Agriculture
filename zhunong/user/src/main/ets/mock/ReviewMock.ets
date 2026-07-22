/**
 * ReviewMock - 商品评价 Mock 数据
 * 遵循 spec 4.1.6 Review 实体定义
 */

import { Review } from '../model/ProductModels';

/** 评价统计结果 */
export interface ReviewStats {
  avgRating: number;
  totalCount: number;
  goodRate: number;
}

/** 评价 Mock 数据（按 productId 索引） */
export const MOCK_REVIEWS: Review[] = [
  {
    reviewId: 'r001', orderId: 'o001', productId: 'p001', buyerId: 'u001',
    buyerNickname: '田园小厨', buyerAvatar: 'avatar_default',
    rating: 5,
    content: '青菜非常新鲜，叶片翠绿没有虫眼，清炒味道清甜。物流也很快，第二天就到了，会回购！',
    images: ['prod_vegetable_1', 'prod_vegetable_2'],
    farmerReply: '感谢您的支持！我们坚持有机种植，欢迎再次选购～',
    createdAt: 1736800000000
  },
  {
    reviewId: 'r002', orderId: 'o002', productId: 'p001', buyerId: 'u002',
    buyerNickname: '健康饮食家', buyerAvatar: 'avatar_default',
    rating: 5,
    content: '已经第三次购买了，品质一直很稳定。家里老人孩子都爱吃，比菜场的新鲜多了。',
    images: [],
    createdAt: 1736850000000
  },
  {
    reviewId: 'r003', orderId: 'o003', productId: 'p001', buyerId: 'u003',
    buyerNickname: '美食探店达人', buyerAvatar: 'avatar_default',
    rating: 4,
    content: '青菜不错，就是包装可以再改进一下，部分叶子压到了。整体满意。',
    images: ['prod_vegetable_1'],
    farmerReply: '感谢反馈，我们会优化包装工艺，期待您下次再来！',
    createdAt: 1736900000000
  },
  {
    reviewId: 'r004', orderId: 'o004', productId: 'p002', buyerId: 'u004',
    buyerNickname: '宝妈小课堂', buyerAvatar: 'avatar_default',
    rating: 5,
    content: '土鸡蛋蛋黄金黄，给宝宝做辅食很放心。煮出来的蛋清香没有腥味，强推！',
    images: ['prod_egg_1', 'prod_egg_1'],
    farmerReply: '谢谢宝妈认可，散养土鸡蛋品质有保证，欢迎回购～',
    createdAt: 1736860000000
  },
  {
    reviewId: 'r005', orderId: 'o005', productId: 'p003', buyerId: 'u005',
    buyerNickname: '米饭爱好者', buyerAvatar: 'avatar_default',
    rating: 5,
    content: '五常大米果然名不虚传，煮饭满屋飘香，米粒晶莹饱满，软糯香甜。会一直买这家。',
    images: ['prod_rice_1'],
    createdAt: 1736870000000
  },
  {
    reviewId: 'r006', orderId: 'o006', productId: 'p005', buyerId: 'u006',
    buyerNickname: '水果控', buyerAvatar: 'avatar_default',
    rating: 5,
    content: '冰糖橙真的甜！皮薄好剥，水分足，孩子一次能吃三个。坏果包赔服务很贴心。',
    images: ['prod_fruit_1'],
    farmerReply: '感谢喜爱，麻阳冰糖橙甜度高，欢迎推荐给朋友～',
    createdAt: 1736880000000
  },
  {
    reviewId: 'r007', orderId: 'o007', productId: 'p007', buyerId: 'u007',
    buyerNickname: '茶友会', buyerAvatar: 'avatar_default',
    rating: 5,
    content: '明前绿茶品质上乘，汤色嫩绿明亮，入口回甘。包装精致，自饮送礼两相宜。',
    images: ['prod_tea_1'],
    createdAt: 1736890000000
  }
];

/** 根据 productId 查询评价列表 */
export function getMockReviewsByProductId(productId: string): Review[] {
  return MOCK_REVIEWS.filter((r: Review) => r.productId === productId);
}

/** 计算商品评价统计（平均分 + 总数 + 好评率） */
export function getMockReviewStats(productId: string): ReviewStats {
  const list: Review[] = getMockReviewsByProductId(productId);
  if (list.length === 0) {
    const empty: ReviewStats = { avgRating: 5.0, totalCount: 0, goodRate: 100 };
    return empty;
  }
  let sum: number = 0;
  let goodCount: number = 0;
  for (let i: number = 0; i < list.length; i++) {
    sum += list[i].rating;
    if (list[i].rating >= 4) {
      goodCount++;
    }
  }
  const stats: ReviewStats = {
    avgRating: Math.round((sum / list.length) * 10) / 10,
    totalCount: list.length,
    goodRate: Math.round((goodCount / list.length) * 100)
  };
  return stats;
}
