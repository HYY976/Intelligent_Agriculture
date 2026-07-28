/**
 * CommunityMock - 社区域 Mock 数据
 * 遵循 spec 4.1.5 / 3.1.3.2：话题/帖子/评论（无限嵌套）/互动
 * 5 个预设话题：全部/种植技术/销路讨论/乡村生活/互助问答
 * 现阶段前端纯 Mock，后端预留空接口（Phase 6 联调）
 * spec 16.12：每个作者分配独特 emoji 头像（不重复）
 */

import { Topic, PostListItem, PostDetail, Comment, PostListParam, PostListResult, PostSortBy } from '../model/CommunityModels';

/** 预设话题（spec 3.1.3.2：5 个预设话题，全部话题用 topicId='all' 表示） */
export const MOCK_TOPICS: Topic[] = [
  { topicId: 'all', name: '全部', sortOrder: 0, isPreset: true },
  { topicId: 't001', name: '种植技术', sortOrder: 1, isPreset: true },
  { topicId: 't002', name: '销路讨论', sortOrder: 2, isPreset: true },
  { topicId: 't003', name: '乡村生活', sortOrder: 3, isPreset: true },
  { topicId: 't004', name: '互助问答', sortOrder: 4, isPreset: true }
];

/** 作者昵称池 */
const AUTHOR_NICKNAMES: string[] = ['山间老农', '果园小妹', '稻香阿强', '茶山姑娘', '草原牧人', '城里返乡客', '农技员小王', '乡下宝妈'];

/** spec 16.12：作者头像池（与 AUTHOR_NICKNAMES 一一对应，全部独特 emoji 不重复） */
const AUTHOR_AVATARS: string[] = ['🐴', '🌸', '🌾', '🍵', '🐔', '💼', '📢', '👩'];

/** spec 16.12：根据 authorId 获取 emoji 头像（u001~u008） */
function getAvatarByAuthorId(authorId: string): string {
  const idx: number = parseInt(authorId.replace('u', ''), 10) - 1;
  if (idx >= 0 && idx < AUTHOR_AVATARS.length) {
    return AUTHOR_AVATARS[idx];
  }
  return '👤';
}

/** 帖子 Mock 数据（12 条，覆盖5话题；spec 16.12：作者头像全部独立） */
export const MOCK_POSTS: PostListItem[] = [
  {
    postId: 'p001',
    authorId: 'u001',
    authorType: 'farmer',
    authorNickname: AUTHOR_NICKNAMES[0],
    authorAvatar: getAvatarByAuthorId('u001'),
    topicId: 't001',
    topicName: '种植技术',
    title: '有机蔬菜种植心得：不用农药如何防虫害',
    contentPreview: '种了20年有机蔬菜，分享几个防虫小妙招：1. 辣椒水喷雾驱蚜虫；2. 大蒜间作防地下害虫；3. 黄色粘虫板诱杀白粉虱...',
    images: ['prod_vegetable_1', 'prod_vegetable_2', 'prod_corn_1'],
    likeCount: 328,
    commentCount: 56,
    favoriteCount: 128,
    isLiked: false,
    isFavorited: false,
    createdAt: Date.now() - 3600000
  },
  {
    postId: 'p002',
    authorId: 'u002',
    authorType: 'farmer',
    authorNickname: AUTHOR_NICKNAMES[1],
    authorAvatar: getAvatarByAuthorId('u002'),
    topicId: 't002',
    topicName: '销路讨论',
    title: '今年蜜桃大丰收，求销路！直播间带货效果怎么样？',
    contentPreview: '自家果园今年蜜桃产量翻倍，传统批发价压得太低。听说直播带货效果好，有没有姐妹分享下经验？需要什么设备？',
    images: ['prod_fruit_1', 'prod_fruit_2'],
    likeCount: 186,
    commentCount: 42,
    favoriteCount: 65,
    isLiked: true,
    isFavorited: false,
    createdAt: Date.now() - 7200000
  },
  {
    postId: 'p003',
    authorId: 'u003',
    authorType: 'user',
    authorNickname: AUTHOR_NICKNAMES[5],
    authorAvatar: getAvatarByAuthorId('u003'),
    topicId: 't003',
    topicName: '乡村生活',
    title: '辞职回乡种地的第三年，分享我的田园生活',
    contentPreview: '三年前放弃北京互联网高薪工作回到云南老家，从零开始学种地。现在有20亩有机菜园，养了50只土鸡，生活节奏慢了但很充实...',
    images: ['prod_vegetable_1', 'prod_egg_1', 'prod_rice_1', 'prod_corn_1'],
    likeCount: 865,
    commentCount: 156,
    favoriteCount: 432,
    isLiked: false,
    isFavorited: true,
    createdAt: Date.now() - 86400000
  },
  {
    postId: 'p004',
    authorId: 'u004',
    authorType: 'user',
    authorNickname: AUTHOR_NICKNAMES[6],
    authorAvatar: getAvatarByAuthorId('u004'),
    topicId: 't004',
    topicName: '互助问答',
    title: '新手求助：番茄叶子发黄卷曲是什么原因？',
    contentPreview: '第一次种番茄，最近叶子开始发黄卷曲，有经验的师傅帮忙看看是什么问题？是缺水、缺肥还是病虫害？',
    images: ['prod_vegetable_2'],
    likeCount: 56,
    commentCount: 28,
    favoriteCount: 12,
    isLiked: false,
    isFavorited: false,
    createdAt: Date.now() - 172800000
  },
  {
    postId: 'p005',
    authorId: 'u005',
    authorType: 'farmer',
    authorNickname: AUTHOR_NICKNAMES[3],
    authorAvatar: getAvatarByAuthorId('u005'),
    topicId: 't001',
    topicName: '种植技术',
    title: '武夷山岩茶制作工艺详解：从采摘到烘焙',
    contentPreview: '武夷岩茶传统制作工艺有12道工序，其中做青和烘焙是关键。分享我家三代传下来的制作心得，附带今年春茶实拍...',
    images: ['prod_tea_1', 'prod_dried_1'],
    likeCount: 432,
    commentCount: 78,
    favoriteCount: 256,
    isLiked: true,
    isFavorited: true,
    createdAt: Date.now() - 259200000
  },
  {
    postId: 'p006',
    authorId: 'u006',
    authorType: 'farmer',
    authorNickname: AUTHOR_NICKNAMES[2],
    authorAvatar: getAvatarByAuthorId('u006'),
    topicId: 't002',
    topicName: '销路讨论',
    title: '大米深加工：从卖原粮到卖品牌的转型之路',
    contentPreview: '以前一直卖原粮，利润薄。今年做了品牌包装，开发礼盒装、米饼、米糊等深加工产品，利润翻了3倍。分享转型经验...',
    images: ['prod_rice_1', 'prod_corn_1'],
    likeCount: 268,
    commentCount: 64,
    favoriteCount: 156,
    isLiked: false,
    isFavorited: false,
    createdAt: Date.now() - 345600000
  },
  {
    postId: 'p007',
    authorId: 'u007',
    authorType: 'user',
    authorNickname: AUTHOR_NICKNAMES[7],
    authorAvatar: getAvatarByAuthorId('u007'),
    topicId: 't003',
    topicName: '乡村生活',
    title: '带娃回乡下奶奶家过暑假，体验最纯粹的童年',
    contentPreview: '城市里的孩子难得接触大自然，今年暑假带娃回乡下奶奶家，捉鱼摸虾、摘菜喂鸡、看星星...孩子开心得不得了...',
    images: ['prod_vegetable_1', 'prod_egg_1', 'prod_fruit_1'],
    likeCount: 658,
    commentCount: 92,
    favoriteCount: 348,
    isLiked: false,
    isFavorited: false,
    createdAt: Date.now() - 432000000
  },
  {
    postId: 'p008',
    authorId: 'u008',
    authorType: 'farmer',
    authorNickname: AUTHOR_NICKNAMES[4],
    authorAvatar: getAvatarByAuthorId('u008'),
    topicId: 't004',
    topicName: '互助问答',
    title: '草原散养土鸡冬季如何保证产蛋率？',
    contentPreview: '内蒙古草原散养土鸡，一到冬天产蛋率就大幅下降，请教各位有什么好办法？补充光照和饲料配方有讲究吗？',
    images: ['prod_egg_1'],
    likeCount: 92,
    commentCount: 38,
    favoriteCount: 45,
    isLiked: false,
    isFavorited: false,
    createdAt: Date.now() - 518400000
  },
  {
    postId: 'p009',
    authorId: 'u001',
    authorType: 'farmer',
    authorNickname: AUTHOR_NICKNAMES[0],
    authorAvatar: getAvatarByAuthorId('u001'),
    topicId: 't001',
    topicName: '种植技术',
    title: '长白山野生菌菇识别与采摘安全指南',
    contentPreview: '长白山林区野生菌菇资源丰富，但误食毒菌后果严重。分享常见食用菌与毒菌的识别要点，野外采摘务必谨慎...',
    images: ['prod_mushroom_1', 'prod_dried_1'],
    likeCount: 386,
    commentCount: 56,
    favoriteCount: 198,
    isLiked: false,
    isFavorited: true,
    createdAt: Date.now() - 604800000
  },
  {
    postId: 'p010',
    authorId: 'u002',
    authorType: 'farmer',
    authorNickname: AUTHOR_NICKNAMES[1],
    authorAvatar: getAvatarByAuthorId('u002'),
    topicId: 't002',
    topicName: '销路讨论',
    title: '土蜂蜜销售：如何建立稳定客户群？',
    contentPreview: '自家秦岭土蜂蜜产量稳定品质好，但一直靠朋友圈零散销售。请教如何建立稳定客户群？社群运营有什么技巧？',
    images: ['prod_honey_1'],
    likeCount: 142,
    commentCount: 48,
    favoriteCount: 86,
    isLiked: false,
    isFavorited: false,
    createdAt: Date.now() - 691200000
  },
  {
    postId: 'p011',
    authorId: 'u003',
    authorType: 'user',
    authorNickname: AUTHOR_NICKNAMES[5],
    authorAvatar: getAvatarByAuthorId('u003'),
    topicId: 't003',
    topicName: '乡村生活',
    title: '秋收季：金黄稻田里的最美风景',
    contentPreview: '又到一年秋收时，金黄的稻田一望无际，沉甸甸的稻穗压弯了腰。分享一组自家稻田实拍，这是大自然最美的画卷...',
    images: ['prod_rice_1', 'prod_corn_1', 'prod_vegetable_1', 'prod_vegetable_2', 'prod_bean_1'],
    likeCount: 928,
    commentCount: 124,
    favoriteCount: 562,
    isLiked: true,
    isFavorited: true,
    createdAt: Date.now() - 777600000
  },
  {
    postId: 'p012',
    authorId: 'u004',
    authorType: 'user',
    authorNickname: AUTHOR_NICKNAMES[6],
    authorAvatar: getAvatarByAuthorId('u004'),
    topicId: 't004',
    topicName: '互助问答',
    title: '辣椒苗徒长不开花怎么办？施肥浇水都正常',
    contentPreview: '阳台种的辣椒苗长得老高就是不开花，叶子很绿很茂盛。施肥浇水都按教程来的，是不是氮肥太多？求大神指点...',
    images: ['prod_chili_1'],
    likeCount: 38,
    commentCount: 22,
    favoriteCount: 8,
    isLiked: false,
    isFavorited: false,
    createdAt: Date.now() - 864000000
  }
];

/** 帖子详情正文（按 postId 映射完整正文，避免列表冗余） */
const POST_FULL_CONTENT: Record<string, string> = {
  'p001': '种了20年有机蔬菜，分享几个防虫小妙招：\n\n1. 辣椒水喷雾驱蚜虫：将辣椒捣碎泡水24小时，过滤后稀释10倍喷洒叶面，可有效驱赶蚜虫、红蜘蛛。\n\n2. 大蒜间作防地下害虫：在菜畦四周种植大蒜，其根系分泌物可驱避地老虎、蛴螬等地下害虫。\n\n3. 黄色粘虫板诱杀白粉虱：白粉虱对黄色有趋性，悬挂黄色粘虫板每亩20-30块，可大幅降低虫口密度。\n\n4. 草木灰防虫：撒施草木灰既可补钾，又能防止根蛆、蜗牛等害虫。\n\n5. 合理轮作：避免连作同科蔬菜，打断害虫生活史。\n\n以上方法亲测有效，欢迎交流补充！',
  'p002': '自家果园今年蜜桃产量翻倍，传统批发价压得太低（地头价2元/斤），听说直播带货能卖到8-10元/斤，有没有姐妹分享下经验？\n\n需要什么设备？\n- 手机+稳定器够吗？\n- 需要补光灯吗？\n- 声卡麦克风有必要吗？\n\n直播间话术怎么练？第一次播不知道说什么。\n\n感谢指导！',
  'p003': '三年前放弃北京互联网高薪工作回到云南老家，从零开始学种地。\n\n现在有20亩有机菜园，养了50只土鸡，生活节奏慢了但很充实。\n\n每天清晨5点起床喂鸡摘菜，上午处理订单发货，下午打理菜地，晚上看书学习。虽然没有外卖和地铁，但空气清新、食物健康、时间自由。\n\n最难忘的是第一次卖出自己种的菜，那种成就感比拿到大厂offer还强烈。\n\n欢迎有同样想法的朋友交流，回乡不易但值得。'
};

/** 评论 Mock 数据（含嵌套回复，按 postId 分组；spec 16.12：评论作者头像按 authorId 取自 emoji 池） */
const COMMENT_DATA: Record<string, Comment[]> = {
  'p001': [
    {
      commentId: 'c001',
      postId: 'p001',
      parentId: null,
      authorId: 'u002',
      authorType: 'farmer',
      authorNickname: AUTHOR_NICKNAMES[1],
      authorAvatar: getAvatarByAuthorId('u002'),
      content: '辣椒水驱蚜虫这招真管用，我试过效果很好！',
      likeCount: 28,
      isLiked: false,
      createdAt: Date.now() - 3000000,
      replies: [
        {
          commentId: 'c001_r1',
          postId: 'p001',
          parentId: 'c001',
          replyToNickname: AUTHOR_NICKNAMES[1],
          authorId: 'u001',
          authorType: 'farmer',
          authorNickname: AUTHOR_NICKNAMES[0],
          authorAvatar: getAvatarByAuthorId('u001'),
          content: '是的，纯天然无残留，比农药安全多了',
          likeCount: 12,
          isLiked: false,
          createdAt: Date.now() - 2800000,
          replies: [
            {
              commentId: 'c001_r1_r1',
              postId: 'p001',
              parentId: 'c001_r1',
              replyToNickname: AUTHOR_NICKNAMES[0],
              authorId: 'u002',
              authorType: 'farmer',
              authorNickname: AUTHOR_NICKNAMES[1],
              authorAvatar: getAvatarByAuthorId('u002'),
              content: '请问辣椒和水的比例是多少？',
              likeCount: 5,
              isLiked: false,
              createdAt: Date.now() - 2600000,
              replies: []
            }
          ]
        }
      ]
    },
    {
      commentId: 'c002',
      postId: 'p001',
      parentId: null,
      authorId: 'u003',
      authorType: 'user',
      authorNickname: AUTHOR_NICKNAMES[5],
      authorAvatar: getAvatarByAuthorId('u003'),
      content: '收藏了，正好我家菜地有虫害问题',
      likeCount: 16,
      isLiked: false,
      createdAt: Date.now() - 2400000,
      replies: []
    },
    {
      commentId: 'c003',
      postId: 'p001',
      parentId: null,
      authorId: 'u004',
      authorType: 'user',
      authorNickname: AUTHOR_NICKNAMES[6],
      authorAvatar: getAvatarByAuthorId('u004'),
      content: '黄色粘虫板哪里能买到？求链接',
      likeCount: 8,
      isLiked: false,
      createdAt: Date.now() - 1800000,
      replies: [
        {
          commentId: 'c003_r1',
          postId: 'p001',
          parentId: 'c003',
          replyToNickname: AUTHOR_NICKNAMES[6],
          authorId: 'u001',
          authorType: 'farmer',
          authorNickname: AUTHOR_NICKNAMES[0],
          authorAvatar: getAvatarByAuthorId('u001'),
          content: '农资店或网上都有的，搜"黄板诱虫"',
          likeCount: 4,
          isLiked: false,
          createdAt: Date.now() - 1700000,
          replies: []
        }
      ]
    }
  ],
  'p002': [
    {
      commentId: 'c101',
      postId: 'p002',
      parentId: null,
      authorId: 'u005',
      authorType: 'farmer',
      authorNickname: AUTHOR_NICKNAMES[3],
      authorAvatar: getAvatarByAuthorId('u005'),
      content: '建议先从手机直播开始，设备要求不高。补光灯白天可以不用，晚上必备。',
      likeCount: 35,
      isLiked: false,
      createdAt: Date.now() - 6000000,
      replies: []
    }
  ]
};

/**
 * 获取帖子列表（Mock 分页）
 * 支持话题/关键字筛选 + 最新/最热排序
 */
export function getMockPostList(param: PostListParam): PostListResult {
  let filtered: PostListItem[] = MOCK_POSTS.slice();
  if (param.topicId && param.topicId !== 'all') {
    filtered = filtered.filter((p: PostListItem) => p.topicId === param.topicId);
  }
  if (param.keyword) {
    const kw: string = param.keyword;
    filtered = filtered.filter((p: PostListItem) =>
      p.title.includes(kw) || p.contentPreview.includes(kw) || p.authorNickname.includes(kw)
    );
  }
  // 排序
  if (param.sortBy === 'hottest') {
    filtered.sort((a: PostListItem, b: PostListItem) => (b.likeCount + b.commentCount * 2) - (a.likeCount + a.commentCount * 2));
  } else {
    filtered.sort((a: PostListItem, b: PostListItem) => b.createdAt - a.createdAt);
  }
  const start: number = (param.page - 1) * param.size;
  const end: number = start + param.size;
  const pageList: PostListItem[] = filtered.slice(start, end);
  return {
    list: pageList,
    hasMore: end < filtered.length
  };
}

/**
 * 获取帖子详情（含完整正文）
 */
export function getMockPostDetail(postId: string): PostDetail | null {
  const item: PostListItem | undefined = MOCK_POSTS.find((p: PostListItem) => p.postId === postId);
  if (!item) {
    return null;
  }
  const fullContent: string = POST_FULL_CONTENT[postId] ?? item.contentPreview;
  const detail: PostDetail = {
    postId: item.postId,
    authorId: item.authorId,
    authorType: item.authorType,
    authorNickname: item.authorNickname,
    authorAvatar: item.authorAvatar,
    topicId: item.topicId,
    topicName: item.topicName,
    title: item.title,
    contentPreview: item.contentPreview,
    content: fullContent,
    images: item.images,
    createdAt: item.createdAt,
    likeCount: item.likeCount,
    commentCount: item.commentCount,
    favoriteCount: item.favoriteCount,
    isLiked: item.isLiked,
    isFavorited: item.isFavorited,
    shareCount: Math.floor(item.likeCount * 0.2),
    status: 'normal'
  };
  return detail;
}

/**
 * 获取帖子评论（含嵌套回复）
 */
export function getMockComments(postId: string): Comment[] {
  return COMMENT_DATA[postId] ?? [];
}

/**
 * 切换帖子点赞（Mock 本地修改）
 */
export function toggleMockPostLike(postId: string): boolean {
  const post: PostListItem | undefined = MOCK_POSTS.find((p: PostListItem) => p.postId === postId);
  if (post) {
    post.isLiked = !post.isLiked;
    post.likeCount += post.isLiked ? 1 : -1;
    return post.isLiked;
  }
  return false;
}

/**
 * 切换帖子收藏（Mock 本地修改）
 */
export function toggleMockPostFavorite(postId: string): boolean {
  const post: PostListItem | undefined = MOCK_POSTS.find((p: PostListItem) => p.postId === postId);
  if (post) {
    post.isFavorited = !post.isFavorited;
    post.favoriteCount += post.isFavorited ? 1 : -1;
    return post.isFavorited;
  }
  return false;
}

/**
 * 切换评论点赞（Mock 本地修改）
 */
export function toggleMockCommentLike(postId: string, commentId: string): boolean {
  const comments: Comment[] = COMMENT_DATA[postId] ?? [];
  const target: Comment | null = findCommentById(comments, commentId);
  if (target) {
    target.isLiked = !target.isLiked;
    target.likeCount += target.isLiked ? 1 : -1;
    return target.isLiked;
  }
  return false;
}

/** 递归查找评论（支持嵌套） */
function findCommentById(comments: Comment[], commentId: string): Comment | null {
  for (let i: number = 0; i < comments.length; i++) {
    if (comments[i].commentId === commentId) {
      return comments[i];
    }
    const found: Comment | null = findCommentById(comments[i].replies, commentId);
    if (found) {
      return found;
    }
  }
  return null;
}

/**
 * 添加一级评论（Mock 本地追加）
 */
export function addMockComment(postId: string, content: string, authorNickname: string, authorAvatar: string): Comment {
  const newComment: Comment = {
    commentId: `c_self_${Date.now()}`,
    postId: postId,
    parentId: null,
    authorId: 'u_self',
    authorType: 'user',
    authorNickname: authorNickname,
    authorAvatar: authorAvatar,
    content: content,
    likeCount: 0,
    isLiked: false,
    createdAt: Date.now(),
    replies: []
  };
  if (!COMMENT_DATA[postId]) {
    COMMENT_DATA[postId] = [];
  }
  COMMENT_DATA[postId].unshift(newComment);
  // 更新帖子评论数
  const post: PostListItem | undefined = MOCK_POSTS.find((p: PostListItem) => p.postId === postId);
  if (post) {
    post.commentCount += 1;
  }
  return newComment;
}

/**
 * 添加回复（Mock 本地追加到指定父评论的 replies）
 */
export function addMockReply(postId: string, parentId: string, replyToNickname: string, content: string, authorNickname: string, authorAvatar: string): Comment | null {
  const comments: Comment[] = COMMENT_DATA[postId] ?? [];
  const parent: Comment | null = findCommentById(comments, parentId);
  if (!parent) {
    return null;
  }
  const newReply: Comment = {
    commentId: `r_self_${Date.now()}`,
    postId: postId,
    parentId: parentId,
    replyToNickname: replyToNickname,
    authorId: 'u_self',
    authorType: 'user',
    authorNickname: authorNickname,
    authorAvatar: authorAvatar,
    content: content,
    likeCount: 0,
    isLiked: false,
    createdAt: Date.now(),
    replies: []
  };
  parent.replies.push(newReply);
  // 更新帖子评论数
  const post: PostListItem | undefined = MOCK_POSTS.find((p: PostListItem) => p.postId === postId);
  if (post) {
    post.commentCount += 1;
  }
  return newReply;
}

/**
 * 创建新帖子（Mock 本地追加到列表头部）
 */
export function createMockPost(title: string, content: string, topicId: string, topicName: string, images: string[], authorAvatar: string): PostListItem {
  const newPost: PostListItem = {
    postId: `p_self_${Date.now()}`,
    authorId: 'u_self',
    authorType: 'user',
    authorNickname: '我',
    authorAvatar: authorAvatar,
    topicId: topicId,
    topicName: topicName,
    title: title,
    contentPreview: content.substring(0, 80),
    images: images,
    likeCount: 0,
    commentCount: 0,
    favoriteCount: 0,
    isLiked: false,
    isFavorited: false,
    createdAt: Date.now()
  };
  MOCK_POSTS.unshift(newPost);
  return newPost;
}

/**
 * 提交举报（Mock：仅记录日志，进入审核队列由管理后台处理）
 */
export function submitMockReport(_postId: string, _reason: string): boolean {
  return true;
}
