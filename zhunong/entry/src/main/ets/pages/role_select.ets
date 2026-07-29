/**
 * RoleSelectPage - 角色选择页（助农平台统一入口）
 *
 * 三端合并架构核心页面：
 *  - APP 桌面唯一入口，启动后展示此页面
 *  - 用户选择身份后通过 startAbility 启动对应 feature 模块
 *  - user（普通用户）/ farmer（农户卖家）/ admin（管理后台）三端独立运行
 *
 * 设计要点：
 *  - 奶油白背景 + 顶部品牌区（黄色渐变 Logo + 萌芽图标）
 *  - 三张角色卡片：彩色图标圆 + 标题 + 副标题 + 箭头
 *  - 全部使用 SVG 矢量图标，无 emoji
 */

import { common, Want } from '@kit.AbilityKit';
import { Logger, AppConstants, ToastUtil } from 'common';

/** 角色选项 */
interface RoleOption {
  /** 角色标识 */
  role: string;
  /** 角色标题 */
  title: string;
  /** 角色描述 */
  subtitle: string;
  /** 图标资源（SVG 矢量图） */
  icon: Resource;
  /** 图标圆背景色 */
  iconBgColor: string;
  /** 图标圆渐变结束色 */
  iconBgColorEnd: string;
  /** 目标模块名 */
  moduleName: string;
  /** 目标 Ability 名 */
  abilityName: string;
}

/** 应用统一 bundleName */
const APP_BUNDLE_NAME: string = 'com.zhunong.platform';

@Entry
@ComponentV2
struct RoleSelectPage {
  /** 角色选项列表（三端） */
  private roleOptions: RoleOption[] = [
    {
      role: 'user',
      title: '普通用户',
      subtitle: '商品购买 · 直播 · 社区 · 文旅',
      icon: $r('app.media.icon_role_user'),
      iconBgColor: '#7ED321',
      iconBgColorEnd: '#5BAE15',
      moduleName: 'user',
      abilityName: 'UserEntryAbility'
    },
    {
      role: 'farmer',
      title: '农户卖家',
      subtitle: '商品管理 · 直播带货 · 订单处理',
      icon: $r('app.media.icon_role_farmer'),
      iconBgColor: '#FFD93D',
      iconBgColorEnd: '#FFC107',
      moduleName: 'farmer',
      abilityName: 'FarmerEntryAbility'
    },
    {
      role: 'admin',
      title: '管理后台',
      subtitle: '用户管理 · API 管理 · 内容审核',
      icon: $r('app.media.icon_role_admin'),
      iconBgColor: '#1B5E20',
      iconBgColorEnd: '#0E3D12',
      moduleName: 'admin',
      abilityName: 'AdminEntryAbility'
    }
  ];

  /** 当前正在启动的角色（空字符串表示空闲） */
  @Local launchingRole: string = '';

  /**
   * 启动对应角色的 feature 模块
   * 通过 startAbility 显式启动目标模块的入口 Ability
   */
  private async launchRole(option: RoleOption): Promise<void> {
    // 防止重复点击
    if (this.launchingRole.length > 0) {
      return;
    }
    this.launchingRole = option.role;
    Logger.info(AppConstants.SCENE_COMMON, { action: 'launch_role_start', role: option.role });
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const want: Want = {
        bundleName: APP_BUNDLE_NAME,
        moduleName: option.moduleName,
        abilityName: option.abilityName
      };
      await context.startAbility(want);
      Logger.info(AppConstants.SCENE_COMMON, { action: 'launch_role_success', role: option.role });
    } catch (err) {
      const errorMsg = (err as Error).message;
      Logger.error(AppConstants.SCENE_COMMON, { action: 'launch_role_fail', role: option.role, error: errorMsg });
      ToastUtil.error('启动失败，请稍后重试');
    } finally {
      this.launchingRole = '';
    }
  }

  build() {
    Column() {
      // 顶部品牌区
      this.BrandSection()

      // 选择身份标题
      this.SectionHeader()

      // 角色卡片列表
      Column({ space: 14 }) {
        ForEach(this.roleOptions, (option: RoleOption) => {
          this.RoleCard(option)
        }, (option: RoleOption) => option.role)
      }
      .width('100%')
      .margin({ top: 8 })
      .layoutWeight(1)

      // 底部版本信息
      this.FooterSection()
    }
    .width('100%')
    .height('100%')
    .padding({ left: 28, right: 28, top: 72, bottom: 32 })
    .backgroundColor('#FFFEF5')
  }

  /** 顶部品牌区：黄色渐变 Logo + 标题 + 副标题 */
  @Builder
  BrandSection() {
    Column({ space: 10 }) {
      // 黄色渐变圆角方块 Logo + 萌芽图标
      Stack() {
        Image($r('app.media.icon_brand'))
          .width(44)
          .height(44)
      }
      .width(80)
      .height(80)
      .borderRadius(24)
      .linearGradient({
        angle: 135,
        colors: [['#FFD93D', 0.0], ['#FFC107', 1.0]]
      })
      .shadow({ radius: 24, color: 'rgba(255,217,61,0.42)', offsetX: 0, offsetY: 10 })
      .border({ width: 3, color: '#FFFFFF' })

      // 主标题
      Text('助农平台')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
        .letterSpacing(2)

      // 副标题
      Text('新鲜农货 · 产地直发')
        .fontSize(13)
        .fontColor('#888888')
        .letterSpacing(1)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  /** "选择身份" 区块标题 */
  @Builder
  SectionHeader() {
    Row({ space: 6 }) {
      // 深绿小圆点
      Column()
        .width(6)
        .height(6)
        .borderRadius(999)
        .backgroundColor('#1B5E20')
      Text('选择您的身份')
        .fontSize(14)
        .fontColor('#444444')
        .fontWeight(FontWeight.Medium)
        .letterSpacing(0.5)
    }
    .width('100%')
    .margin({ top: 40, bottom: 4 })
  }

  /** 单张角色卡片 */
  @Builder
  RoleCard(option: RoleOption) {
    Row({ space: 14 }) {
      // 左侧：彩色渐变图标圆
      Stack() {
        Image(option.icon)
          .width(26)
          .height(26)
      }
      .width(52)
      .height(52)
      .borderRadius(999)
      .linearGradient({
        angle: 135,
        colors: [[option.iconBgColor, 0.0], [option.iconBgColorEnd, 1.0]]
      })
      .shadow({ radius: 12, color: `${option.iconBgColor}40`, offsetX: 0, offsetY: 4 })

      // 中间：标题 + 副标题
      Column({ space: 4 }) {
        Text(option.title)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
        Text(option.subtitle)
          .fontSize(12)
          .fontColor('#999999')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 右侧：箭头 / 启动中提示
      if (this.launchingRole === option.role) {
        Text('启动中...')
          .fontSize(12)
          .fontColor('#AAAAAA')
      } else {
        Text('→')
          .fontSize(22)
          .fontColor('#CCCCCC')
          .fontWeight(FontWeight.Bold)
      }
    }
    .width('100%')
    .height(76)
    .padding({ left: 16, right: 18 })
    .borderRadius(16)
    .backgroundColor('#FFFFFF')
    .border({ width: 1, color: '#F0F0F0' })
    .shadow({ radius: 16, color: 'rgba(26,26,26,0.06)', offsetX: 0, offsetY: 4 })
    .alignItems(VerticalAlign.Center)
    .opacity(this.launchingRole === option.role ? 0.6 : 1)
    .onClick(() => {
      this.launchRole(option);
    })
  }

  /** 底部版本信息 */
  @Builder
  FooterSection() {
    Column({ space: 4 }) {
      Text('助农平台 v1.0.0')
        .fontSize(11)
        .fontColor('#BBBBBB')
      Text('三端合一 · 角色切换')
        .fontSize(10)
        .fontColor('#CCCCCC')
        .letterSpacing(0.5)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .margin({ top: 16 })
  }
}
