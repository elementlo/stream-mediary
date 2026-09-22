# Mediary 开源项目曝光与流量策略

> 面向维护者的行动备忘录。原则：低成本、不引人反感、从项目实际内容出发，不做纯营销。
> 最后更新：2026-09-22

## 0. 项目特点盘点（策略的依据）

| 特点 | 对曝光的意义 |
|---|---|
| Flutter 六平台（Android/iOS/macOS/Windows/Linux/Web） | 同类 m3u8 下载器多为 Electron 或 CLI，**跨平台移动端是稀缺差异点** |
| 中英双语 README | 可同时覆盖中文与英文社区，一份内容两份渠道 |
| 完整工程化：CI 自动构建 Release、自动截图、跨平台回归测试 | 本身就是可分享的技术故事（见 §3） |
| 内置留言板（Waline 自托管） | 用户反馈闭环，社区感 |
| 有真实踩坑记录（截图自动化、Waline API、DNS 污染） | 技术文章的一手素材，全网稀缺 |

核心逻辑：**让需要它的人能找到它**（收录/标签/搜索），**让看到它的人觉得靠谱**（演示/文档/维护质量）。

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

## 3. 技术内容分享（分享工程经验，项目只是案例）

最"不引人反感"的路径：写真实踩过的坑。按素材稀缺度排序：

1. **《Flutter 桌面端截图自动化》**（已成文，见 `docs/blog-flutter-desktop-screenshots.md`）
   - `flutter screenshot` 不支持桌面、DWM 阴影黑边、PrintWindow 黑帧、CI 无头环境截屏——中英文社区均无现成文章
2. **《用 Flutter 重写 m3u8 下载器：从 Electron 到六平台一套代码》**
   - 架构对比 + 移动端 HLS 下载的坑（后台执行、存储权限、分片并发）
3. **《给 Flutter app 接留言板：Waline 文档没告诉你的三个坑》**
   - POST 字段名差异、null 字段导致 GET 崩溃、children 嵌套结构
4. **《vercel.app 在大陆的 DNS 污染与自定义域名绕行》**
   - 实测解析到 Meta IP 段的排查过程，对国内开发者极实用

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

## 6. 优先级与节奏

| 时间 | 动作 |
|---|---|
| 本周（约 1 小时） | ✅ Topics、✅ Social Preview 图、提交 HelloGitHub、登记 AlternativeTo |
| 下个迭代 | 演示 GIF、发布截图自动化踩坑文（中英文各一版） |
| 持续 | 问答社区存在感、issue/PR 维护质量、每月一篇踩坑文 |
