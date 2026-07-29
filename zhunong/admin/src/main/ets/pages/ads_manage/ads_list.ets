/**
 * ads_list - 广告配置列表（UI 复刻 qunong-harmony-app/pages/admin-ads.html）
 * 遵循 spec 3.3.4 / 10.8.3.4：
 *  - 顶部：圆形返回键 + 居中 "广告配置" + 黄色胶囊 "新建" 按钮
 *  - 3 列统计行（投放中/待审核/已暂停，带彩色圆点）
 *  - 横滑筛选 Tab（全部/首页Banner/开屏广告/直播贴片/社区推荐，黄色激活态）
 *  - 广告卡列表：100h 封面图 + 广告位标 + 标题 + 状态 pill + Toggle 开关 + 4 列数据 + 投放时间
 *  - 新建广告表单卡（展开态）：广告位选择 + 名称 + 素材上传 + 投放时间 + 预算 + 目标人群 + 创建按钮
 *
 * Toggle 开关：本地维护 enabled 状态，点击调用 AdRepository.toggleAdEnabled
 * 新建表单：本地维护表单状态，点击"创建广告"调用 AdRepository.createAd
 *
 * UI 设计要点（对齐 admin-ads.html）：
 *  - 顶栏：圆形返回键 + 居中标题 + 黄色胶囊"新建"
 *  - 统计卡：白底圆角 + 3 列 + 彩色圆点 + 竖线分隔
 *  - 筛选 Tab：横滑胶囊，激活态墨黑底白字
 *  - 广告卡：白底圆角 + 100h 封面 + 左上广告位标 + 状态 pill + Toggle + 4 列灰底数据 + 时间行
 *  - 表单卡：白底圆角 + 黄色图标头 + pill 选择器 + 虚线上传区 + 双列日期 + ¥ 预算 + 多选胶囊
 *
 * 越权防御（spec 10.8.8）：aboutToAppear 校验 super_admin
 */

import { Logger, AppConstants, ToastUtil, TokenStore, NavigationHelper, RouteName, ListStateView } from 'common';
import { AdminInfo } from 'common';
import {
  AdRecord,
  AdSlot,
  AdStatus,
  AdAudience,
  AdOverviewStats,
  AdCreateRequest,
  AdminRole,
  AD_SLOT_LABELS,
  AD_STATUS_LABELS,
  AD_AUDIENCE_LABELS
} from '../../model/AdminModels';
import { AdRepository } from '../../repository/AdRepository';

/** 统计项 */
interface StatItem {
  num: number;
  lab: string;
  /** 圆点颜色类型 */
  dotColor: 'green' | 'yellow' | 'gray';
}

/** 筛选项 */
interface FilterOption {
  value: 'all' | AdSlot;
  label: string;
}

/** 广告位选项（不含"全部"，用于新建表单） */
interface SlotOption {
  value: AdSlot;
  label: string;
}

/** 目标人群选项 */
interface AudienceOption {
  value: AdAudience;
  label: string;
}

/** 4 列数据项 */
interface DataCell {
  num: string;
  lab: string;
  /** 是否花费列（红色） */
  isCost: boolean;
}

@ComponentV2
export struct AdsList {
  /** 广告列表（本地维护，开关切换后更新） */
  @Local ads: AdRecord[] = [];
  /** 概览统计 */
  @Local stats: AdOverviewStats | null = null;
  /** 当前筛选的广告位 */
  @Local currentFilter: 'all' | AdSlot = 'all';
  /** 是否正在加载 */
  @Local isLoading: boolean = false;
  /** 加载失败 */
  @Local loadFailed: boolean = false;
  /** 正在切换开关的广告 ID（防止重复点击） */
  @Local togglingAdId: string = '';
  /** 正在创建广告 */
  @Local isCreating: boolean = false;

  // ===== 新建广告表单状态 =====
  /** 选中的广告位 */
  @Local formSlot: AdSlot = 'home_banner';
  /** 广告名称 */
  @Local formTitle: string = '';
  /** 投放预算 */
  @Local formBudget: string = '';
  /** 开始日期（YYYY-MM-DD） */
  @Local formStartDate: string = '';
  /** 结束日期（YYYY-MM-DD） */
  @Local formEndDate: string = '';
  /** 选中的目标人群（多选） */
  @Local formAudiences: AdAudience[] = ['all'];

  /** 滚动控制器（"新建"按钮点击后滚动到表单） */
  private scroller: Scroller = new Scroller();

  /** 统计项列表（根据加载的 stats 动态生成） */
  private getStatItems(): StatItem[] {
    let running: number = 0;
    let pending: number = 0;
    let paused: number = 0;
    if (this.stats) {
      running = this.stats.running;
      pending = this.stats.pending;
      paused = this.stats.paused;
    }
    const items: StatItem[] = [
      { num: running, lab: '投放中', dotColor: 'green' },
      { num: pending, lab: '待审核', dotColor: 'yellow' },
      { num: paused, lab: '已暂停', dotColor: 'gray' }
    ];
    return items;
  }

  /** 筛选选项列表 */
  private filterOptions: FilterOption[] = [
    { value: 'all', label: '全部' },
    { value: 'home_banner', label: '首页Banner' },
    { value: 'splash', label: '开屏广告' },
    { value: 'live_patch', label: '直播贴片' },
    { value: 'community', label: '社区推荐' }
  ];

  /** 广告位选项列表（用于新建表单，不含"全部"） */
  private slotOptions: SlotOption[] = [
    { value: 'home_banner', label: '首页Banner' },
    { value: 'splash', label: '开屏广告' },
    { value: 'live_patch', label: '直播贴片' },
    { value: 'community', label: '社区推荐' }
  ];

  /** 目标人群选项列表 */
  private audienceOptions: AudienceOption[] = [
    { value: 'all', label: '全部用户' },
    { value: 'new_user', label: '新用户' },
    { value: 'old_user', label: '老用户' },
    { value: 'high_freq', label: '高频用户' }
  ];

  async aboutToAppear(): Promise<void> {
    // 越权防御（spec 10.8.8）：仅 super_admin 可访问广告管理
    const adminInfo: AdminInfo | null = await TokenStore.getAdminInfo();
    if (!adminInfo) {
      ToastUtil.warning('请先登录');
      NavigationHelper.replace(RouteName.ADMIN_LOGIN);
      return;
    }
    const allowedRoles: AdminRole[] = ['super_admin'];
    if (allowedRoles.indexOf(adminInfo.role as AdminRole) < 0) {
      ToastUtil.warning('无权限访问该页面');
      NavigationHelper.pop();
      return;
    }
    Logger.info(AppConstants.SCENE_ADMIN, { action: 'ads_list_appear', adminId: adminInfo.adminId });
    await this.loadAll();
  }

  /** 加载列表 + 统计 */
  private async loadAll(): Promise<void> {
    this.isLoading = true;
    this.loadFailed = false;
    try {
      await Promise.all([
        this.loadAds(),
        this.loadStats()
      ]);
    } catch (err) {
      this.loadFailed = true;
      Logger.error(AppConstants.SCENE_ADMIN, { action: 'load_ads_fail', error: (err as Error).message });
    } finally {
      this.isLoading = false;
    }
  }

  /** 加载广告列表（按当前筛选） */
  private async loadAds(): Promise<void> {
    try {
      let slotFilter: AdSlot | undefined = undefined;
      if (this.currentFilter !== 'all') {
        slotFilter = this.currentFilter;
      }
      const result = await AdRepository.getAds({
        slot: slotFilter,
        page: 1,
        size: 50
      });
      this.ads = result.list;
    } catch (err) {
      Logger.error(AppConstants.SCENE_ADMIN, { action: 'load_ads_list_fail', error: (err as Error).message });
      throw new Error((err as Error).message);
    }
  }

  /** 加载概览统计 */
  private async loadStats(): Promise<void> {
    try {
      this.stats = await AdRepository.getOverviewStats();
    } catch (err) {
      Logger.error(AppConstants.SCENE_ADMIN, { action: 'load_ads_stats_fail', error: (err as Error).message });
    }
  }

  /** 切换筛选 Tab */
  private async onFilterChange(filter: 'all' | AdSlot): Promise<void> {
    if (this.currentFilter === filter) {
      return;
    }
    this.currentFilter = filter;
    await this.loadAds();
  }

  /** 切换广告开关 */
  private async onToggleAd(ad: AdRecord): Promise<void> {
    if (this.togglingAdId.length > 0) {
      return;
    }
    // 待审核状态不允许切换
    if (ad.status === 'pending') {
      ToastUtil.warning('待审核广告不可切换');
      return;
    }
    this.togglingAdId = ad.adId;
    try {
      const updated: AdRecord | null = await AdRepository.toggleAdEnabled(ad.adId);
      if (updated) {
        // 更新本地列表
        const idx: number = this.ads.findIndex((a: AdRecord): boolean => a.adId === ad.adId);
        if (idx >= 0) {
          // 替换引用以触发 @Local 刷新
          const newAds: AdRecord[] = this.ads.slice();
          newAds[idx] = updated;
          this.ads = newAds;
        }
        Logger.info(AppConstants.SCENE_ADMIN, { action: 'ad_toggle', adId: ad.adId });
      }
    } catch (err) {
      Logger.error(AppConstants.SCENE_ADMIN, { action: 'ad_toggle_fail', error: (err as Error).message });
      ToastUtil.error('操作失败');
    } finally {
      this.togglingAdId = '';
    }
  }

  // ===== 新建广告表单方法 =====

  /** 选择广告位 */
  private onSelectSlot(slot: AdSlot): void {
    this.formSlot = slot;
  }

  /** 名称输入 */
  private onTitleInput(value: string): void {
    this.formTitle = value;
  }

  /** 预算输入（仅数字） */
  private onBudgetInput(value: string): void {
    const filtered: string = value.replace(/[^0-9.]/g, '');
    this.formBudget = filtered;
  }

  /** 开始日期输入 */
  private onStartDateInput(value: string): void {
    this.formStartDate = value;
  }

  /** 结束日期输入 */
  private onEndDateInput(value: string): void {
    this.formEndDate = value;
  }

  /** 切换目标人群（多选） */
  private onToggleAudience(audience: AdAudience): void {
    const idx: number = this.formAudiences.indexOf(audience);
    if (idx >= 0) {
      // 移除（至少保留一项）
      if (this.formAudiences.length > 1) {
        const next: AdAudience[] = this.formAudiences.filter((a: AdAudience): boolean => a !== audience);
        this.formAudiences = next;
      }
    } else {
      // 添加
      const next: AdAudience[] = this.formAudiences.slice();
      next.push(audience);
      this.formAudiences = next;
    }
  }

  /** 校验表单 */
  private validateForm(): boolean {
    if (this.formTitle.trim().length === 0) {
      ToastUtil.warning('请输入广告名称');
      return false;
    }
    if (this.formBudget.length === 0 || parseFloat(this.formBudget) <= 0) {
      ToastUtil.warning('请输入有效预算金额');
      return false;
    }
    if (this.formStartDate.trim().length === 0 || this.formEndDate.trim().length === 0) {
      ToastUtil.warning('请选择投放时间');
      return false;
    }
    if (this.formAudiences.length === 0) {
      ToastUtil.warning('请选择目标人群');
      return false;
    }
    return true;
  }

  /** 提交创建广告 */
  private async doCreateAd(): Promise<void> {
    if (!this.validateForm()) {
      return;
    }
    this.isCreating = true;
    try {
      const req: AdCreateRequest = {
        slot: this.formSlot,
        title: this.formTitle.trim(),
        coverKey: 'hero_harvest',
        startAt: this.parseDate(this.formStartDate),
        endAt: this.parseDate(this.formEndDate),
        budget: parseFloat(this.formBudget),
        audiences: this.formAudiences.slice()
      };
      await AdRepository.createAd(req);
      ToastUtil.success('广告已创建，待审核');
      Logger.info(AppConstants.SCENE_ADMIN, { action: 'ad_create', adId: req.title });
      // 重置表单
      this.formTitle = '';
      this.formBudget = '';
      this.formStartDate = '';
      this.formEndDate = '';
      this.formAudiences = ['all'];
      // 刷新列表 + 统计
      await this.loadAll();
    } catch (err) {
      Logger.error(AppConstants.SCENE_ADMIN, { action: 'ad_create_fail', error: (err as Error).message });
      ToastUtil.error('创建失败');
    } finally {
      this.isCreating = false;
    }
  }

  /** 日期字符串 → 时间戳（YYYY-MM-DD） */
  private parseDate(dateStr: string): number {
    const parts: string[] = dateStr.split('-');
    if (parts.length === 3) {
      const y: number = parseInt(parts[0], 10);
      const m: number = parseInt(parts[1], 10) - 1;
      const d: number = parseInt(parts[2], 10);
      const dt: Date = new Date(y, m, d);
      return dt.getTime();
    }
    return Date.now();
  }

  /** 格式化投放时间（M/D - M/D） */
  private formatAdTime(ad: AdRecord): string {
    if (ad.isScheduled) {
      return '待排期';
    }
    const s: Date = new Date(ad.startAt);
    const e: Date = new Date(ad.endAt);
    return `${s.getMonth() + 1}/${s.getDate()} - ${e.getMonth() + 1}/${e.getDate()}`;
  }

  /** 格式化曝光数（万） */
  private formatImpressions(num: number, isEstimated: boolean): string {
    if (isEstimated) {
      return `${(num / 10000).toFixed(1)}万`;
    }
    if (num >= 10000) {
      return `${(num / 10000).toFixed(1)}万`;
    }
    return num.toLocaleString();
  }

  /** 格式化点击数 */
  private formatClicks(num: number, isPending: boolean): string {
    if (isPending) {
      return '—';
    }
    return num.toLocaleString();
  }

  /** 格式化 CTR */
  private formatCtr(ctr: number, isPending: boolean): string {
    if (isPending) {
      return '—';
    }
    return `${(ctr * 100).toFixed(1)}%`;
  }

  /** 格式化花费 */
  private formatCost(cost: number, isPending: boolean): string {
    return `¥${cost.toLocaleString()}`;
  }

  /** 获取广告 4 列数据 */
  private getAdDataCells(ad: AdRecord): DataCell[] {
    const isPending: boolean = ad.status === 'pending';
    const cells: DataCell[] = [
      { num: this.formatImpressions(ad.impressions, isPending), lab: isPending ? '预估曝光' : '曝光', isCost: false },
      { num: this.formatClicks(ad.clicks, isPending), lab: '点击', isCost: false },
      { num: this.formatCtr(ad.ctr, isPending), lab: 'CTR', isCost: false },
      { num: this.formatCost(ad.cost, isPending), lab: isPending ? '预算' : '花费', isCost: true }
    ];
    return cells;
  }

  /** 统计圆点颜色 */
  private dotResourceColor(dot: 'green' | 'yellow' | 'gray'): ResourceColor {
    if (dot === 'green') {
      return $r('app.color.color_green');
    } else if (dot === 'yellow') {
      return $r('app.color.color_yellow_deep');
    }
    return $r('app.color.color_text_4');
  }

  /** 状态 pill 背景色 */
  private statusBg(status: AdStatus): ResourceColor {
    if (status === 'running') {
      return $r('app.color.color_green_soft');
    } else if (status === 'pending') {
      return $r('app.color.color_yellow_soft');
    } else if (status === 'paused') {
      return $r('app.color.color_fill');
    }
    return $r('app.color.color_fill');
  }

  /** 状态 pill 文字色 */
  private statusColor(status: AdStatus): ResourceColor {
    if (status === 'running') {
      return $r('app.color.color_green_deep');
    } else if (status === 'pending') {
      return $r('app.color.color_yellow_text');
    } else if (status === 'paused') {
      return $r('app.color.color_text_2');
    }
    return $r('app.color.color_text_2');
  }

  /** 状态图标 */
  private statusIcon(status: AdStatus): string {
    if (status === 'running') {
      return '●';
    } else if (status === 'pending') {
      return '◐';
    } else if (status === 'paused') {
      return '■';
    }
    return '■';
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        if (this.loadFailed) {
          ListStateView({ state: 'error', onRefresh: () => this.loadAll() })
        } else if (this.isLoading && this.ads.length === 0) {
          ListStateView({ state: 'loading' })
        } else {
          this.ContentScroll()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_cream'))
    }
    .hideTitleBar(true)
  }

  /** 顶部导航：圆形返回键 + 居中标题 + 黄色胶囊"新建" */
  @Builder
  TopBar() {
    Row() {
      // 圆形返回键
      Stack() {
        Text('‹')
          .fontSize(22)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .width(32)
      .height(32)
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor($r('app.color.color_bg_card'))
      .shadow(AppConstants.SHADOW_CARD)
      .onClick(() => NavigationHelper.pop())

      // 居中标题
      Text('广告配置')
        .fontSize(17)
        .fontColor($r('app.color.color_ink'))
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 黄色胶囊"新建"按钮
      Row({ space: 4 }) {
        Text('+')
          .fontSize(16)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        Text('新建')
          .fontSize(13)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .height(32)
      .padding({ left: 14, right: 14 })
      .borderRadius(AppConstants.RADIUS_PILL)
      .backgroundColor($r('app.color.color_yellow'))
      .shadow({ radius: 10, color: 'rgba(255,217,61,0.4)', offsetX: 0, offsetY: 4 })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        // 滚动到底部表单
        this.scroller.scrollEdge(Edge.Bottom);
      })
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16, top: 4, bottom: 10 })
    .alignItems(VerticalAlign.Center)
  }

  /** 内容滚动区 */
  @Builder
  ContentScroll() {
    Scroll(this.scroller) {
      Column({ space: 12 }) {
        this.StatsCard()
        this.FilterTabs()
        this.AdListView()
        this.CreateFormCard()
      }
      .width('100%')
      .padding({ top: 4, bottom: 32 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .align(Alignment.Top)
  }

  /** 3 列统计卡（投放中 / 待审核 / 已暂停，带彩色圆点 + 竖线分隔） */
  @Builder
  StatsCard() {
    Row() {
      ForEach(this.getStatItems(), (stat: StatItem, index: number) => {
        Row() {
          Column({ space: 4 }) {
            Row({ space: 5 }) {
              // 彩色圆点
              Circle({ width: 7, height: 7 })
                .fill(this.dotResourceColor(stat.dotColor))
              Text(`${stat.num}`)
                .fontSize(22)
                .fontColor($r('app.color.color_ink'))
                .fontWeight(FontWeight.Bold)
            }
            .alignItems(VerticalAlign.Center)

            Text(stat.lab)
              .fontSize(11)
              .fontColor($r('app.color.color_text_3'))
              .fontWeight(FontWeight.Medium)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

          // 竖线分隔（除最后一项）
          if (index < 2) {
            Column()
              .width(1)
              .height(30)
              .backgroundColor($r('app.color.color_line'))
          }
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }, (stat: StatItem, index: number) => `${stat.lab}_${index}`)
    }
    .width('100%')
    .padding({ top: 16, bottom: 16 })
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .margin({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
  }

  /** 横滑筛选 Tab */
  @Builder
  FilterTabs() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.filterOptions, (opt: FilterOption) => {
          Text(opt.label)
            .height(32)
            .padding({ left: 14, right: 14 })
            .borderRadius(AppConstants.RADIUS_PILL)
            .backgroundColor(this.currentFilter === opt.value
              ? $r('app.color.color_ink')
              : $r('app.color.color_bg_card'))
            .fontColor(this.currentFilter === opt.value
              ? Color.White
              : $r('app.color.color_text_2'))
            .fontSize(12.5)
            .fontWeight(FontWeight.Bold)
            .shadow(AppConstants.SHADOW_CARD)
            .textAlign(TextAlign.Center)
            .onClick(() => this.onFilterChange(opt.value))
        }, (opt: FilterOption) => opt.value)
      }
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height(40)
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
  }

  /** 广告列表 */
  @Builder
  AdListView() {
    if (this.ads.length === 0) {
      Column({ space: 8 }) {
        Image($r('app.media.icon_megaphone'))
          .width(40)
          .height(40)
          .fillColor($r('app.color.color_text_4'))
        Text('暂无广告数据')
          .fontSize(13)
          .fontColor($r('app.color.color_text_3'))
      }
      .width('100%')
      .padding({ top: 32, bottom: 32 })
      .alignItems(HorizontalAlign.Center)
    } else {
      Column({ space: 12 }) {
        ForEach(this.ads, (ad: AdRecord) => {
          this.AdCard(ad)
        }, (ad: AdRecord) => `${ad.adId}_${ad.enabled}_${ad.status}`)
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .alignItems(HorizontalAlign.Start)
    }
  }

  /** 获取广告封面图片资源（v2.0：根据 adId 返回不同真实封面） */
  private getAdCover(adId: string): Resource {
    switch (adId) {
      case 'ad_001': return $r('app.media.ad_cover_001');
      case 'ad_002': return $r('app.media.ad_cover_002');
      case 'ad_003': return $r('app.media.ad_cover_003');
      case 'ad_004': return $r('app.media.ad_cover_004');
      default: return $r('app.media.hero_harvest');
    }
  }

  /** 单个广告卡 */
  @Builder
  AdCard(ad: AdRecord) {
    Column() {
      // 1. 封面图（100h）+ 左上广告位标
      Stack({ alignContent: Alignment.Start }) {
        Image(this.getAdCover(ad.adId))
          .width('100%')
          .height(100)
          .objectFit(ImageFit.Cover)
          .borderRadius({ topLeft: AppConstants.RADIUS_LG, topRight: AppConstants.RADIUS_LG })

        // 左上广告位标（半透明黑底）
        Stack() {
          Text(AD_SLOT_LABELS[ad.slot])
            .fontSize(10)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
        }
        .padding({ left: 8, right: 8, top: 2, bottom: 2 })
        .borderRadius(AppConstants.RADIUS_PILL)
        .backgroundColor('rgba(26,26,26,0.55)')
        .position({ x: 10, y: 10 })
      }
      .width('100%')
      .height(100)

      // 2. 卡片正文
      Column({ space: 10 }) {
        // 标题行：标题 + 状态 pill + Toggle 开关
        Row({ space: 8 }) {
          Text(ad.title)
            .fontSize(14)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 状态 pill
          Row({ space: 4 }) {
            Text(this.statusIcon(ad.status))
              .fontSize(10)
              .fontColor(this.statusColor(ad.status))
            Text(AD_STATUS_LABELS[ad.status])
              .fontSize(11)
              .fontColor(this.statusColor(ad.status))
              .fontWeight(FontWeight.Bold)
          }
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(AppConstants.RADIUS_PILL)
          .backgroundColor(this.statusBg(ad.status))
          .alignItems(VerticalAlign.Center)

          // Toggle 开关
          this.ToggleSwitch(ad)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 3. 4 列数据（灰底）
        Row() {
          ForEach(this.getAdDataCells(ad), (cell: DataCell, index: number) => {
            Column({ space: 3 }) {
              Text(cell.num)
                .fontSize(14)
                .fontColor(cell.isCost ? $r('app.color.color_live') : $r('app.color.color_ink'))
                .fontWeight(FontWeight.Bold)
              Text(cell.lab)
                .fontSize(10)
                .fontColor($r('app.color.color_text_3'))
                .fontWeight(FontWeight.Medium)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
          }, (cell: DataCell, index: number) => `${cell.lab}_${index}`)
        }
        .width('100%')
        .padding({ top: 10, bottom: 10 })
        .borderRadius(AppConstants.RADIUS_SM)
        .backgroundColor($r('app.color.color_fill'))

        // 4. 投放时间
        Row({ space: 4 }) {
          Image($r('app.media.icon_calendar'))
            .width(12)
            .height(12)
            .fillColor($r('app.color.color_text_3'))
          Text(this.formatAdTime(ad))
            .fontSize(11)
            .fontColor($r('app.color.color_text_2'))
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 12, bottom: 14 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .clip(true)
  }

  /** Toggle 开关（自定义） */
  @Builder
  ToggleSwitch(ad: AdRecord) {
    Stack({ alignContent: ad.enabled ? Alignment.End : Alignment.Start }) {
      // 圆点
      Stack() {}
        .width(18)
        .height(18)
        .borderRadius(9)
        .backgroundColor(Color.White)
        .shadow({ radius: 3, color: 'rgba(0,0,0,0.25)', offsetX: 0, offsetY: 1 })
        .margin({ left: 2, right: 2 })
    }
    .width(38)
    .height(22)
    .borderRadius(AppConstants.RADIUS_PILL)
    .backgroundColor(ad.enabled
      ? $r('app.color.color_green')
      : $r('app.color.color_text_4'))
    .onClick(() => this.onToggleAd(ad))
  }

  /** 新建广告表单卡（展开态） */
  @Builder
  CreateFormCard() {
    Column({ space: 14 }) {
      // 表单头：黄色图标 + "新建广告"标题
      Row({ space: 8 }) {
        Stack() {
          Image($r('app.media.icon_sparkles'))
            .width(16)
            .height(16)
            .fillColor($r('app.color.color_yellow_text'))
        }
        .width(30)
        .height(30)
        .borderRadius(AppConstants.RADIUS_SM)
        .backgroundColor($r('app.color.color_yellow_soft'))
        .alignContent(Alignment.Center)

        Text('新建广告')
          .fontSize(16)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 1. 广告位选择（pill 选择器）
      Column({ space: 8 }) {
        Row() {
          Text('广告位选择')
            .fontSize(12)
            .fontColor($r('app.color.color_text_2'))
            .fontWeight(FontWeight.Bold)
          Text('*')
            .fontSize(12)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')

        // 4 个 pill 单选
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.slotOptions, (opt: SlotOption) => {
            Text(opt.label)
              .height(32)
              .padding({ left: 14, right: 14 })
              .margin({ right: 8, bottom: 8 })
              .borderRadius(AppConstants.RADIUS_PILL)
              .backgroundColor(this.formSlot === opt.value
                ? $r('app.color.color_yellow_soft')
                : $r('app.color.color_fill'))
              .fontColor(this.formSlot === opt.value
                ? $r('app.color.color_yellow_text')
                : $r('app.color.color_text_2'))
              .fontSize(12.5)
              .fontWeight(FontWeight.Bold)
              .border({ width: 1, color: this.formSlot === opt.value
                ? $r('app.color.color_yellow_deep')
                : Color.Transparent })
              .textAlign(TextAlign.Center)
              .onClick(() => this.onSelectSlot(opt.value))
          }, (opt: SlotOption) => opt.value)
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 2. 广告名称
      Column({ space: 8 }) {
        Row() {
          Text('广告名称')
            .fontSize(12)
            .fontColor($r('app.color.color_text_2'))
            .fontWeight(FontWeight.Bold)
          Text('*')
            .fontSize(12)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')

        TextInput({ text: this.formTitle, placeholder: '请输入广告名称' })
          .width('100%')
          .height(46)
          .fontSize(14)
          .fontColor($r('app.color.color_ink'))
          .backgroundColor($r('app.color.color_fill'))
          .borderRadius(AppConstants.RADIUS_MD)
          .onChange((value: string) => this.onTitleInput(value))
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 3. 广告素材（虚线上传区）
      Column({ space: 8 }) {
        Row() {
          Text('广告素材')
            .fontSize(12)
            .fontColor($r('app.color.color_text_2'))
            .fontWeight(FontWeight.Bold)
          Text('*')
            .fontSize(12)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')

        // 上传区
        Column({ space: 3 }) {
          Stack() {
            Image($r('app.media.icon_upload'))
              .width(18)
              .height(18)
              .fillColor($r('app.color.color_text_2'))
          }
          .width(38)
          .height(38)
          .borderRadius(19)
          .backgroundColor($r('app.color.color_bg_card'))
          .shadow(AppConstants.SHADOW_CARD)
          .alignContent(Alignment.Center)

          Text('点击上传广告素材')
            .fontSize(13)
            .fontColor($r('app.color.color_text_2'))
            .fontWeight(FontWeight.Bold)
          Text('建议尺寸 750×300，支持 JPG / PNG')
            .fontSize(11)
            .fontColor($r('app.color.color_text_4'))
        }
        .width('100%')
        .padding({ top: 22, bottom: 22 })
        .borderRadius(AppConstants.RADIUS_MD)
        .backgroundColor($r('app.color.color_fill'))
        .border({ width: 1.5, color: $r('app.color.color_line_2'), style: BorderStyle.Dashed })
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          ToastUtil.info('素材上传功能待接入');
        })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 4. 投放时间（双列日期）
      Column({ space: 8 }) {
        Row() {
          Text('投放时间')
            .fontSize(12)
            .fontColor($r('app.color.color_text_2'))
            .fontWeight(FontWeight.Bold)
          Text('*')
            .fontSize(12)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')

        Row({ space: 8 }) {
          // 开始日期
          Row({ space: 8 }) {
            Image($r('app.media.icon_calendar'))
              .width(14)
              .height(14)
              .fillColor($r('app.color.color_text_3'))
            TextInput({ text: this.formStartDate, placeholder: '开始日期' })
              .layoutWeight(1)
              .height(46)
              .fontSize(13)
              .fontColor($r('app.color.color_ink'))
              .backgroundColor(Color.Transparent)
              .placeholderColor($r('app.color.color_text_4'))
              .onChange((value: string) => this.onStartDateInput(value))
          }
          .layoutWeight(1)
          .height(46)
          .padding({ left: 12, right: 12 })
          .borderRadius(AppConstants.RADIUS_MD)
          .backgroundColor($r('app.color.color_fill'))
          .alignItems(VerticalAlign.Center)

          // 箭头
          Text('→')
            .fontSize(14)
            .fontColor($r('app.color.color_text_4'))
            .fontWeight(FontWeight.Bold)

          // 结束日期
          Row({ space: 8 }) {
            Image($r('app.media.icon_calendar'))
              .width(14)
              .height(14)
              .fillColor($r('app.color.color_text_3'))
            TextInput({ text: this.formEndDate, placeholder: '结束日期' })
              .layoutWeight(1)
              .height(46)
              .fontSize(13)
              .fontColor($r('app.color.color_ink'))
              .backgroundColor(Color.Transparent)
              .placeholderColor($r('app.color.color_text_4'))
              .onChange((value: string) => this.onEndDateInput(value))
          }
          .layoutWeight(1)
          .height(46)
          .padding({ left: 12, right: 12 })
          .borderRadius(AppConstants.RADIUS_MD)
          .backgroundColor($r('app.color.color_fill'))
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 5. 投放预算（¥ 前缀）
      Column({ space: 8 }) {
        Row() {
          Text('投放预算')
            .fontSize(12)
            .fontColor($r('app.color.color_text_2'))
            .fontWeight(FontWeight.Bold)
          Text('*')
            .fontSize(12)
            .fontColor($r('app.color.color_live'))
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')

        Stack({ alignContent: Alignment.Start }) {
          Text('¥')
            .fontSize(15)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .margin({ left: 16 })

          TextInput({ text: this.formBudget, placeholder: '请输入预算金额' })
            .width('100%')
            .height(46)
            .fontSize(14)
            .fontColor($r('app.color.color_ink'))
            .fontWeight(FontWeight.Bold)
            .backgroundColor($r('app.color.color_fill'))
            .borderRadius(AppConstants.RADIUS_MD)
            .padding({ left: 38, right: 16 })
            .placeholderColor($r('app.color.color_text_4'))
            .type(InputType.Number)
            .onChange((value: string) => this.onBudgetInput(value))
        }
        .width('100%')
        .height(46)
        .alignContent(Alignment.Center)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 6. 目标人群（多选胶囊）
      Column({ space: 8 }) {
        Text('目标人群（可多选）')
          .fontSize(12)
          .fontColor($r('app.color.color_text_2'))
          .fontWeight(FontWeight.Bold)
          .width('100%')

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.audienceOptions, (opt: AudienceOption) => {
            Row({ space: 5 }) {
              if (this.formAudiences.indexOf(opt.value) >= 0) {
                Text('✓')
                  .fontSize(12)
                  .fontColor($r('app.color.color_yellow_text'))
                  .fontWeight(FontWeight.Bold)
              }
              Text(opt.label)
                .fontSize(12.5)
                .fontColor(this.formAudiences.indexOf(opt.value) >= 0
                  ? $r('app.color.color_yellow_text')
                  : $r('app.color.color_text_2'))
                .fontWeight(FontWeight.Bold)
            }
            .height(32)
            .padding({ left: 14, right: 14 })
            .margin({ right: 8, bottom: 8 })
            .borderRadius(AppConstants.RADIUS_PILL)
            .backgroundColor(this.formAudiences.indexOf(opt.value) >= 0
              ? $r('app.color.color_yellow_soft')
              : $r('app.color.color_fill'))
            .border({ width: 1, color: this.formAudiences.indexOf(opt.value) >= 0
              ? $r('app.color.color_yellow_deep')
              : Color.Transparent })
            .alignItems(VerticalAlign.Center)
            .onClick(() => this.onToggleAudience(opt.value))
          }, (opt: AudienceOption) => opt.value)
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 创建按钮（黄色）
      Row({ space: 6 }) {
        Text('+')
          .fontSize(16)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
        Text(this.isCreating ? '创建中...' : '创建广告')
          .fontSize(15)
          .fontColor($r('app.color.color_ink'))
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .height(46)
      .borderRadius(AppConstants.RADIUS_MD)
      .backgroundColor($r('app.color.color_yellow'))
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .margin({ top: 4 })
      .onClick(() => {
        if (!this.isCreating) {
          this.doCreateAd();
        }
      })
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppConstants.RADIUS_LG)
    .backgroundColor($r('app.color.color_bg_card'))
    .shadow(AppConstants.SHADOW_CARD)
    .margin({ left: 16, right: 16 })
    .alignItems(HorizontalAlign.Start)
  }
}
