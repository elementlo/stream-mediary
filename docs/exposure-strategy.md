# Mediary 开源项目曝光与流量策略

> 面向维护者的行动备忘录。原则：低成本、不引人反感、从项目实际内容出发，不做纯营销。
> 最后更新：2026-09-29

## 0. 项目特点盘点（策略的依据）

| 特点 | 对曝光的意义 |
|---|---|
| Flutter 六平台（Android/iOS/macOS/Windows/Linux/Web） | 同类 m3u8 下载器多为 Electron 或 CLI，**跨平台移动端是稀缺差异点** |
| **PNG 包装 HLS（roUd）支持** | yt-dlp / N_m3u8DL-RE 默认都不处理，**全网稀缺能力** |
| 下载代理、AIMD 自适应并发、isolate 卸载解密 | 工程深度，技术文章素材（见 §3） |
| 中英双语 README | 可同时覆盖中文与英文社区，一份内容两份渠道 |
| 完整工程化：CI 自动构建 Release、自动截图、跨平台回归测试 | 本身就是可分享的技术故事（见 §3） |
| 内置留言板（Waline 自托管） | 用户反馈闭环，社区感 |
| 有真实踩坑记录（截图自动化、Waline API、DNS 污染） | 技术文章的一手素材，全网稀缺 |

核心逻辑：**让需要它的人能找到它**（收录/标签/搜索），**让看到它的人觉得靠谱**（演示/文档/维护质量）。

### 0.1 差异化定位（一句话回答"为什么选你"）

赛道拥挤：yt-dlp（全能 CLI 巨头）、N_m3u8DL-RE（中文圈最流行）、各种 GUI 套壳。对外定位建议：

> **支持 PNG 包装流的跨平台图形化 HLS 下载器**

而不是泛泛的"m3u8 下载器"。两个差异点按稀缺度排序：roUd PNG 包装支持 > 移动端 GUI。

## 1. GitHub 站内优化（零成本，最直接）

- [x] **Topics 标签**：已设置 `flutter` `dart` `m3u8` `hls` `video-downloader` `cross-platform` `android` `ios` `macos` `windows` `ffmpeg` `stream-downloader`
- [x] **Social Preview 图**：已生成 `docs/social-preview.png`（1280×640），需在仓库 Settings → General → Social preview 手动上传（GitHub 无 API）
- [ ] **README 顶部加 15-30 秒演示 GIF**：录"粘贴 m3u8 → 解析 → 下载 → 合并 → 播放"完整流程。下载器类项目"看一眼就懂"胜过千字说明
- [ ] **About 栏一句话简介**：确保填了 "Cross-platform HLS/m3u8 downloader built with Flutter" 之类的英文简介 + 官网/下载链接（指向 Releases）

## 2. 一次性提交收录（低成本，长尾流量）

| 渠道 | 动作 | 预期 |
|---|---|---|
| **HelloGitHub**（hellogithub.com） | 提交项目收录 | 中文开源月刊，收录即获一期推荐位 + 长期索引，中文曝光性价比最高 |
| **awesome-flutter** | 提 PR 加入工具类列表 | Flutter 开发者找项目的常用入口 |
| **FlutterAwesome** | 提交收录 | 同上，英文向 |
| **AlternativeTo** | 登记为 N_m3u8DL-RE / M3U8-Downloader 的替代 | 截获 "m3u8 downloader alternative" 精准搜索流量 |
| **F-Droid** | 提交收录（纯开源 + CI 产 APK，符合条件） | 开源 Android 应用的正式分发渠道，带来持续安装量 |

### 2.1 社区首发渠道（按受众精准度排序）

**中文圈（主战场）：**

| 渠道 | 说明 |
|---|---|
| **吾爱破解（52pojie）** | 对下载/逆向类工具最友好，受众精准，首发贴容易火 |
| **少数派（sspai）** | 偏好设计精良的工具，Material 3 + 跨平台是卖点，可投稿 |
| **酷安（coolapk）** | Android 应用分发，适合发 APK |
| **Bilibili** | 录 2 分钟演示视频（粘贴 m3u8 → 解析 → 选清晰度 → 下载 → 内置播放），视频转化高于文字 |
| **知乎 / 掘金** | 走技术文路线（见 §3），掘金尤其吃 Flutter 工程向内容 |
| **V2EX** | `/go/create` 或 `/go/share`，受众挑剔，做好被质疑的心理准备 |

**国际圈：**

| 渠道 | 说明 |
|---|---|
| **Reddit r/DataHoarder** | 最对口的受众（内容归档爱好者），强烈建议发 |
| **Reddit r/FlutterDev** | 打"Flutter 跨平台工程"角度而非"下载器"角度，接受度更高 |
| **awesome 列表** | `awesome-flutter`、`awesome-hls`、self-hosted 类清单，长尾流量稳定 |
| **Product Hunt** | 可试，但下载器类排名一般（见 §5） |

**被低估的角度**：抛开"它下载什么"，单看"一个高质量的 Flutter 跨平台桌面+移动应用"，对 Flutter 开发者就有展示价值。投 "Made with Flutter" 类合集、Flutter 中文社区。

## 3. 技术内容分享（分享工程经验，项目只是案例）

最"不引人反感"的路径：写真实踩过的坑。按素材稀缺度排序：

1. **《Flutter 桌面端截图自动化》**（已成文，见 `docs/blog-flutter-desktop-screenshots.md`）
   - `flutter screenshot` 不支持桌面、DWM 阴影黑边、PrintWindow 黑帧、CI 无头环境截屏——中英文社区均无现成文章
2. **《用 worker isolate 修复 Dart 事件循环阻塞：下载并发名存实亡的排查》**
   - AES 解密 / zlib 解压在主 isolate 上把 8 路并发串行化——Flutter 性能优化好案例，全网少见
3. **《借鉴 TCP 拥塞控制：下载器的 AIMD 自适应并发》**
   - 成功加性增、拥塞（超时/429/5xx）乘性减，比固定并发更稳
4. **《用 Flutter 重写 m3u8 下载器：从 Electron 到六平台一套代码》**
   - 架构对比 + 移动端 HLS 下载的坑（后台执行、存储权限、分片并发）
5. **《给 Flutter app 接留言板：Waline 文档没告诉你的三个坑》**
   - POST 字段名差异、null 字段导致 GET 崩溃、children 嵌套结构
6. **《vercel.app 在大陆的 DNS 污染与自定义域名绕行》**
   - 实测解析到 Meta IP 段的排查过程，对国内开发者极实用

标题策略：走"Flutter 实战 / 性能优化"而非"下载器"，既涨 star 又涨技术声誉，还规避部分平台对下载工具的敏感。

发布渠道：
- 中文：掘金、知乎、V2EX（分享创造节点）
- 英文：dev.to、Reddit r/FlutterDev（Show & Tell，注意各版块自推规则，通常要求 9:1 分享/自推比例）

## 4. 社区存在感（长期复利）

- **问答场景自然出现**：Stack Overflow / 知乎 / V2EX 回答 "Flutter 下载 HLS"、"m3u8 解析" 类问题时认真答题，文末附项目链接。被需要时出现 ≠ 推销
- **认真维护 issue / PR**：快速响应、清晰的 CONTRIBUTING。小项目口碑 = "维护者靠谱"，决定流量能否转化为 star 与留存
- **开启 GitHub Discussions**：承接开发者向讨论（feature request / Q&A），与 app 内留言板（用户向）互补；Discussions 活跃度影响 GitHub 站内权重

## 5. 不建议做的

- ❌ 群发 QQ/微信群、论坛刷屏——转化率极低且败坏名声
- ❌ 买 star / 互 star 群——GitHub 会清理，污染真实用户画像
- ❌ Product Hunt 首发——需集中运营一天，工具类小项目 ROI 一般，可后置

## 5.1 必须正视的现实风险

1. **主流平台会限流/拒绝下载器**：Hacker News 的 Show HN、Product Hunt、部分 subreddit 对"下载工具"常判为盗版相邻而 flag 或沉帖。别把希望押在这些上。
2. **特定站点的关联是双刃剑**：与特定站点的绑定会让推广被归类为"扒某站"，既缩小可投放渠道，也增加被 DMCA / 下架风险。**对外宣传强调通用 HLS 能力和合法用途，淡化特定站点**。
3. **GitHub DMCA**：通用 HLS 工具一般能存活，但被特定版权方盯上可能收到 takedown。保持"通用工具"定位、不内置任何站点破解逻辑，是长期安全线。
4. **别买量、别刷 star**：这个体量不值得，且会反噬口碑。

## 6. 优先级与节奏

如果只做三件事：
1. **吾爱破解 + r/DataHoarder 各发一帖**（受众最精准）
2. **录一个 Bilibili/YouTube 演示视频**（转化最高）
3. **写一篇 isolate 性能优化的掘金/知乎技术文**（拉开发者 + 涨技术声誉）

| 时间 | 动作 |
|---|---|
| 本周（约 1 小时） | ✅ Topics、✅ Social Preview 图、提交 HelloGitHub、登记 AlternativeTo |
| 下个迭代 | 演示 GIF/视频、吾爱破解与 r/DataHoarder 首发帖、isolate 性能优化文 |
| 持续 | 问答社区存在感、issue/PR 维护质量、每月一篇踩坑文 |
