# Mediary UI 设计规范（Redesign Spec）

> 本文档是 Mediary 界面重构的唯一设计依据。所有数值均为可直接落地的实现规格。
> 对应代码：`lib/core/theme/`、`lib/core/platform/`、`lib/core/widgets/`

---

## 1. 设计目标与用户

**用户是谁**：想把自己有权保存的 HLS 流（课程、直播回放、自建媒体）落到本地的人。
他打开 App 时脑子里的模型只有一件事：**一堆碎片，最后变成一个能播的文件**。

**设计要解决的三个问题**

| 现状问题 | 设计对策 |
|---|---|
| 用的是 `ColorScheme.fromSeed` 生成的默认配色，换个 App 长得一模一样 | 手写完整色板 + 品牌靛蓝，不依赖种子色算法 |
| 进度条是原生 `LinearProgressIndicator`，看不出"分片"这个核心概念 | 签名组件 **分片进度条**：把引擎真实的 segment 粒度画出来 |
| 四个平台只差一个导航栏宽窄，桌面端内容拉伸满屏 | 平台档位（Profile）驱动密度/转场/滚动/交互差异 + 桌面内容限宽居中 |

**设计原则**

1. **简洁**：默认零阴影，靠 1px 发丝线 + 表面色阶分层。一屏只有一个主色焦点。
2. **一致**：同一语义在所有平台用同一颜色/图标/文案。状态色板全局唯一。
3. **平台像本地人**：不是把移动端放大到桌面，而是按平台惯例给转场、密度、指针交互。
4. **本项目独有**：视觉隐喻来自产品自身机制——**分片 → 汇聚 → 成品**。

---

## 2. 设计语言：Stream（流）

设计语言围绕"离散分片汇聚为连续成品"建立。三条视觉母题：

- **分片（Segment）** — 离散的、可数的、有状态的块。用于进度、列表、状态指示。
- **汇聚（Merge）** — 分片向中心收拢的动作。用于合并态、加载态。
- **连续（Continuous）** — 成品后的平滑实体。用于完成态、播放态。

具体体现：进度条画成分片刻度；合并中刻度向中心收拢；完成后刻度淡出为一条连续圆角实体。
这套语言只在 Mediary 成立，因为它复刻的是产品自己的运行机制。

---

## 3. 色彩系统

手写色板，**不使用 `ColorScheme.fromSeed`**。品牌主色沿用启动图标底色 `#4F46E5`，保证图标与界面同源。

### 3.1 品牌与语义色

| 语义 | 亮色 | 暗色 | 用途 |
|---|---|---|---|
| `primary` 品牌靛蓝 | `#4F46E5` | `#7C8CFF` | 主按钮、选中态、完成分片 |
| `onPrimary` | `#FFFFFF` | `#0B1020` | 主色上的文字 |
| `primaryContainer` | `#E8E9FE` | `#2A3170` | 主色浅底（选中背景） |
| `tertiary` 流青（accent） | `#0891B2` | `#22D3EE` | **进行中**状态、数据流动 |
| `success` 完成 | `#059669` | `#34D399` | 下载完成、ffmpeg 可用 |
| `warning` 提醒 | `#D97706` | `#FBBF24` | 降级输出、需注意 |
| `danger` 错误 | `#E11D48` | `#FB7185` | 失败、删除、错误 |

> 语义色**不进入** `ColorScheme` 的标准槽位（M3 只有 error），而是通过 `MediaryColors` 主题扩展
> 注入，保证 4 个状态在全局永远同一个颜色。

### 3.2 中性色阶

| 槽位 | 亮色 | 暗色 | 用途 |
|---|---|---|---|
| `surface` | `#F7F8FA` | `#0F1116` | 页面底色 |
| `surfaceContainerLow` | `#FFFFFF` | `#15181F` | **卡片** |
| `surfaceContainer` | `#F1F3F7` | `#1A1E27` | 次级容器、输入框 |
| `surfaceContainerHigh` | `#E9ECF2` | `#222732` | 悬浮/hover 态 |
| `onSurface` | `#14171F` | `#E8EAF0` | 主文字（对比度 ≥ 13:1） |
| `onSurfaceVariant` | `#5C6577` | `#9BA3B4` | 次要文字（对比度 ≥ 4.6:1） |
| `outline` | `#DDE1E9` | `#333A47` | 发丝线、卡片描边 |
| `outlineVariant` | `#E9ECF2` | `#252B36` | 分隔线 |

暗色底刻意带一点蓝调（非纯中性灰），避免大面积死黑。

### 3.3 状态色映射（全局唯一）

| 任务状态 | 色 | 图标 |
|---|---|---|
| created / parsing / previewReady | `onSurfaceVariant` | `schedule` |
| queued | `onSurfaceVariant` | `hourglass_empty` |
| **downloading** | `tertiary` 流青 | `arrow_downward` |
| paused | `warning` | `pause` |
| **merging** | `primary` 靛蓝 | `call_merge` |
| completed | `success` | `check_circle` |
| failed | `danger` | `error` |
| canceled | `onSurfaceVariant` | `cancel` |

下载中用**流青**而非品牌靛蓝是刻意的：靛蓝代表"确定性/成品"，流青代表"正在流动的数据"。
一眼就能从颜色区分"在传"和"在合"。

---

## 4. 字体与排版

字体沿用各平台系统字体（不引入字体资源，保证包体与平台原生观感）。差异靠**字重、字号、行高、字距**建立。

### 4.1 字号阶梯

| Token | 字号/行高 | 字重 | 字距 | 用途 |
|---|---|---|---|---|
| `displaySmall` | 32 / 40 | 700 | -0.5 | 桌面端空状态大标题 |
| `headlineSmall` | 22 / 30 | 700 | -0.3 | 桌面端页面标题 |
| `titleLarge` | 18 / 25 | 650 | -0.2 | 卡片主标题（文件名） |
| `titleMedium` | 15 / 22 | 600 | 0 | 区块标题 |
| `titleSmall` | 12.5 / 18 | 600 | +0.4 | 小节标签 |
| `bodyLarge` | 15 / 23 | 400 | 0 | 正文（移动端） |
| `bodyMedium` | 13.5 / 21 | 400 | 0 | 正文默认 |
| `bodySmall` | 12 / 18 | 400 | +0.1 | 辅助信息 |
| `labelLarge` | 14 / 20 | 600 | +0.1 | 按钮文字 |
| `labelMedium` | 11.5 / 16 | 600 | +0.3 | 状态徽章 |
| `labelSmall` | 11 / 15 | 500 | +0.5 | 时间戳、极次要信息 |

中文行高统一比英文版高约 8%（上表已含），保证中文字面不挤。

### 4.2 数字必须等宽

所有会跳动的数字（速度、大小、百分比、ETA、分片计数）统一加：

```dart
fontFeatures: [FontFeature.tabularFigures()]
```

这是硬性要求——否则下载中的速度数字每 500ms 变一次宽度，整行左右抖动。

---

## 5. 间距、圆角、层级

### 5.1 间距（4pt 基准）

| Token | 值 | 典型用途 |
|---|---|---|
| `xs` | 4 | 图标与文字间隙 |
| `sm` | 8 | 行内元素间距 |
| `md` | 12 | 卡片内元素间距 |
| `lg` | 16 | 卡片内边距（移动） |
| `xl` | 20 | 卡片内边距（桌面）、区块间距 |
| `xxl` | 32 | 页面级留白 |

### 5.2 圆角

| Token | 值 | 用途 |
|---|---|---|
| `sm` | 8 | 徽章、小按钮、输入框内元素 |
| `md` | 12 | 按钮、输入框 |
| `lg` | 16 | **卡片** |
| `xl` | 22 | 弹窗、大容器 |
| `full` | 999 | 药丸按钮、状态徽章 |

刻意避开"所有东西都 16"的默认观感：按钮 12、卡片 16、弹窗 22，形成三级层次。

### 5.3 层级（Elevation）

**默认零阴影。** 分层靠表面色阶 + 1px 发丝描边。

| 层级 | 处理 |
|---|---|
| 页面底 | `surface` |
| 卡片 | `surfaceContainerLow` + `outline` 1px 描边 |
| 悬浮态 | 提亮到 `surfaceContainerHigh`（桌面 hover） |
| FAB / 弹窗 / 菜单 | 唯一使用阴影的三种元素 |

零阴影是"简洁"的主要落点：默认 M3 卡片加阴影会让密集列表显得脏。

---

## 6. 动效

| Token | 时长 | 曲线 | 用途 |
|---|---|---|---|
| `fast` | 120ms | `easeOut` | 悬停、按下反馈 |
| `standard` | 200ms | `easeOutCubic` | 常规状态切换 |
| `emphasized` | 320ms | `easeOutQuint` | 展开/收起、页面进出 |
| `progress` | 450ms | `linear` | 进度条推进 |

**分片进度条的推进**用 `450ms` 而不是常规 200ms：进度本身是连续数据，缓动会让它显得迟疑；
同时引擎事件 500ms 节流，450ms 刚好接上，视觉上是平滑爬升而非跳跃。

**合并态动效**：分片刻度向中心收拢并渐变为一条连续圆角实体（`emphasized`），
对应"汇聚"母题——这是唯一一处装饰性动效，因为它承载了产品的核心叙事。

---

## 7. 签名组件

### 7.1 分片进度条 `SegmentProgressBar`

**为什么需要它**：`LinearProgressIndicator` 只能表达"百分比"，而 Mediary 的真实进度单位是**分片**。
把它画出来，用户能直接看到"还剩几个块"，也能看到卡在哪个分片上。

规格：

- 每个分片一个刻度块，间隔 2px
- **刻度上限 60 块**：`totalSegments > 60` 时按区间分桶（每桶含 `ceil(total/60)` 个分片），保证块宽不小于 2px
- 高度：移动端 8px，桌面端 6px（桌面更密更克制）
- 圆角：块宽 ≥ 6px 时用 `sm`，否则直角（避免细块被圆角吃掉）
- 分片状态着色：

| 分片状态 | 颜色 | 说明 |
|---|---|---|
| 已完成 | `primary` | 靛蓝 = 已固化 |
| 进行中 | `tertiary` + 呼吸动画 | 流青 = 正在流动，仅高亮当前 1 块 |
| 待下载 | `outlineVariant` | 极淡，不抢视觉 |
| 失败 | `danger` | 失败分片直接标红，便于定位 |

- 合并阶段切换到 **汇聚态**：刻度收拢为连续条，用 `primary → tertiary` 渐变 + 轻微流光
- 无障碍：整体包 `Semantics(label: '进度 42%，已下载 21/50 个分片')`
- `totalSegments == 0`（未解析）时退化为不确定态连续条

### 7.2 状态徽章 `StatusBadge`

替代默认 `Chip`（默认 Chip 有最小高度和多余内边距，密集列表里显笨重）。

- 药丸形，高 22px，内边距 水平 8px
- 左侧 6px 圆点 + 右侧文字（`labelMedium`）
- 背景 = 状态色 12% alpha；文字与圆点用**状态色本身**（不用 alpha 降透明度，保证 11px 文字仍达 4.5:1 对比度）
- 进行中状态圆点带脉冲动画

### 7.3 卡片 `MediaryCard`

- `surfaceContainerLow` 底 + `outline` 1px 描边，`lg` 圆角，零阴影
- 桌面端内边距 `xl`(20)，移动端 `lg`(16)
- 可选 `accent`：左侧 3px 状态色竖条，仅用于"进行中"的任务卡，让活跃任务在列表中可扫读
- 桌面端 hover 时背景提到 `surfaceContainerHigh`（`fast` 过渡）

### 7.4 其他

| 组件 | 规格 |
|---|---|
| `SectionHeader` | `titleSmall` + `onSurfaceVariant`，上方间距 `xxl`、下方 `md`。替代原先 settings/merge 两处重复的 `_SectionTitle` |
| `EmptyState` | 图标装在 64px 圆角方块（`primaryContainer` 12% 底）里，而非裸图标；标题 + 提示 + 主行动按钮 |
| `StatTile` | 标签在上（`bodySmall`/`onSurfaceVariant`），值在下（`titleMedium` + 等宽数字）。用于解析预览、扫描结果 |
| `MediaryScaffold` | 统一页面骨架：桌面端大标题 + 内容限宽居中；移动端标准 AppBar |
| `MediaryButton` | 主按钮满宽（流程页）、次按钮描边。桌面端流程页按钮右对齐 |

---

## 8. 平台适配档位

适配由 `PlatformProfile` 统一定义，**不是**散落各处的 `Platform.isXxx` 判断。

| 维度 | Android | iOS | macOS | Windows |
|---|---|---|---|---|
| 导航形态 | 底部栏 + FAB | 底部栏 + FAB | 侧边 Rail（宽屏展开） | 侧边 Rail（宽屏展开） |
| 页面转场 | M3 fade-through | Cupertino 横向滑入 + 边缘返回手势 | 淡入 + 8px 上移 | 淡入 + 8px 上移 |
| 密度 | comfortable | comfortable | **compact** | **compact** |
| 卡片内边距 | 16 | 16 | 20 | 20 |
| 列表项高度 | 56 | 56 | 48 | 48 |
| 最小点击区 | 48 | 48 | 32（鼠标） | 32（鼠标） |
| 滚动 | overscroll glow | bounce | clamp + 常显滚动条 | clamp + 常显滚动条 |
| 指针交互 | — | — | hover 态、右键菜单、快捷键 | hover 态、右键菜单、快捷键 |
| 弹窗 | M3 居中弹窗 | Cupertino 风格 | 紧凑居中弹窗 | 紧凑居中弹窗 |
| 提示条 | 底部 | 底部 | 右下浮动 | 右下浮动 |
| 文字选择 | 标准 | Cupertino | 标准 | 标准 |
| 安全区 | 顶部/底部 | 顶部/底部（含 Home 指示条） | 无 | 无 |

**导航断点**

| 窗口宽度 | 形态 |
|---|---|
| < 640 | 底部 `NavigationBar` |
| 640 – 1023 | `NavigationRail`（仅图标 + 标签） |
| ≥ 1024 | `NavigationRail` 展开（图标 + 标签，256px） |

**桌面内容限宽**（解决当前拉伸满屏的问题）

| 页面类型 | 最大宽度 |
|---|---|
| 表单页（新建下载 / 设置 / 合并） | 760 |
| 列表页（下载中 / 历史） | 960 |

超宽时水平居中，两侧留白。

---

## 9. 无障碍

- 所有交互元素最小点击区：移动 48×48，桌面 32×32
- 文字对比度：主文字 ≥ 12:1，次要文字 ≥ 4.5:1，徽章文字 ≥ 4.5:1
- 状态**不只靠颜色**传达：徽章 = 色 + 圆点 + 文字；分片进度条 = 色 + 明度差 + 无障碍标签
- 进度条、任务卡、播放器控件均提供 `Semantics` 标签
- 支持系统字号放大：所有文本用 `TextTheme`，不写死 `fontSize`（签名组件内的固定字号已按最小可读值 11px 设定）

---

## 10. 落地清单

| 文件 | 职责 |
|---|---|
| `lib/core/theme/design_tokens.dart` | 间距/圆角/动效/字号/等宽数字 |
| `lib/core/theme/mediary_colors.dart` | 语义色 + `MediaryColors` 主题扩展 |
| `lib/core/theme/app_theme.dart` | 手写 `ColorScheme` + 全组件主题 |
| `lib/core/platform/platform_profile.dart` | 平台档位、断点、限宽 |
| `lib/core/widgets/segment_progress_bar.dart` | 签名组件 |
| `lib/core/widgets/status_badge.dart` | 状态徽章 + 状态映射 |
| `lib/core/widgets/mediary_card.dart` | 卡片 |
| `lib/core/widgets/mediary_scaffold.dart` | 页面骨架（限宽 + 大标题） |
| `lib/core/widgets/section_header.dart` | 区块标题 |
| `lib/core/widgets/empty_state.dart` | 空状态 |
| `lib/core/widgets/stat_tile.dart` | 数据格 |
| `lib/features/**` | 六个页面按本规范重构 |