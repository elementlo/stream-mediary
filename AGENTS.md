# AGENTS.md

本文件为 AI 编码助手提供项目上下文。Mediary 是一个基于 Flutter 的跨平台 M3U8 / HLS 媒体下载器：解析、下载、解密并合并流媒体分片，输出单个可播放的视频文件。

## 项目概要

- **名称**：Mediary（包名 `stream_mediary`）
- **定位**：跨平台 HLS 下载器，支持 Android / iOS / Windows / macOS
- **许可证**：MIT
- **仓库**：https://github.com/elementlo/stream-mediary
- **核心特性**：HLS 解析预览、PNG 包装（`roUd`）HLS 支持、两级并发下载、纯 Dart AES-CBC 解密、分片合并 + ffmpeg remux、断点续传、内置播放器、历史记录、下载代理、Material 3、中英文国际化

## 关联插件（浏览器扩展）

- **名称**：Video Stream Link Detector（Chrome Manifest V3 扩展）
- **仓库**：https://github.com/elementlo/IDM-shell-extension
- **作用**：在视频页检测 HLS / PNG 包装流入口，通过桌面自定义协议 `stream-mediary://download` 唤起 Mediary，并携带：
  - `url` — 流媒体入口地址
  - `referer` — 来源网页地址（Mediary 持久化为 `refererUrl`，用于"复制来源网页"）
  - `userAgent` — 浏览器 UA
- **检测策略**：完全通用、站点中立——HLS 按后缀/MIME/查询参数识别；PNG 包装流按结构探测（任何 302 到 `.png` 的请求都是候选，解包验证 `roUd` 块后才保留）。扩展代码不含任何站点硬编码。
- **可选规则（JSON 导入）**：popup ⚙ 面板仅支持导入/导出/清空 JSON 规则（无编辑表单）。规则是通用检测之上的**额外筛选**：页面域名命中规则时只保留 `urlFilter` 匹配的候选；`pagePath`+`entryPath` 可为无法观察到请求的页面构造 fallback 入口。规则字段：`hostname`（必填）、`urlFilter`、`pagePath`、`entryPath`（`$1..$n` 引用分组）、`kind`（`wrapped-hls`/`hls`）。存 `chrome.storage.local`，导入时校验。详见插件仓库的 AGENTS.md 与 README。
- **协议注册**：macOS 由 `.app` bundle 注册；Windows 在应用首次启动时写入当前用户注册表
- **说明**：扩展为独立实现，不含任何第三方专有代码；签名 CDN 地址可能过期

## 环境准备与常用命令

```bash
# 安装依赖
flutter pub get

# 代码生成（drift / freezed / riverpod / json）——改动表或模型后必须运行
dart run build_runner build --delete-conflicting-outputs

# 国际化生成（改动 .arb 后运行；模板为 app_zh.arb）
flutter gen-l10n

# 静态分析（提交前须无 issue）
flutter analyze

# 运行全部测试
flutter test

# 生成覆盖率
flutter test --coverage

# 运行单个测试文件 / 单个用例
flutter test test/engine/scheduler_aimd_test.dart
flutter test --plain-name "用例名关键字"

# 在已连接设备/桌面运行
flutter run

# 构建发布产物
flutter build apk        # Android
flutter build ios        # iOS
flutter build macos      # macOS
flutter build windows    # Windows
```

环境要求：Flutter 3.47+（Dart SDK ^3.13）、目标平台工具链（Xcode / Android Studio / Visual Studio）；可选 `ffmpeg`（在 `PATH` 中，用于 MP4 remux）。

## 技术栈

| 领域 | 选型 |
|---|---|
| 框架 | Flutter 3.47+（Dart SDK ^3.13） |
| 状态管理 | `flutter_riverpod` + `riverpod_annotation` |
| 路由 | `go_router` |
| 网络 | `dio`（HTTP 代理通过 `IOHttpClientAdapter` + `HttpClient.findProxy` 实现） |
| 解密 | `pointycastle`（纯 Dart AES-128/192/256-CBC） |
| 数据库 | `drift` + `sqlite3_flutter_libs`（schema 版本化迁移） |
| 播放 | `media_kit` / `media_kit_video` |
| 模型/序列化 | `freezed` + `json_serializable` |
| 平台能力 | `window_manager`、`tray_manager`、`permission_handler`、`file_selector`、`connectivity_plus`、`battery_plus`、`flutter_local_notifications` 等 |
| 代码生成 | `build_runner`（drift / freezed / riverpod / l10n） |

## 架构

分层、单向依赖。**下载引擎为纯 Dart、零 Flutter 依赖**，可完整单元测试。

```
features/   UI 层（Flutter 页面与组件）
providers/  Riverpod 状态层（引擎、任务列表、设置等 provider）
data/       drift 数据库 + 仓储层
engine/     纯 Dart 下载引擎（解析 → 调度 → 下载 → 解密 → 合并）
core/       跨层基础设施（l10n、主题、路由、平台、工具、通用组件）
```

## 目录结构

```
lib/
├── main.dart / app.dart        应用入口与根组件
├── core/
│   ├── l10n/                   国际化（app_zh.arb / app_en.arb + 生成文件）
│   ├── platform/               平台能力（深链 DownloadLinkService、桌面窗口等）
│   ├── router/                 go_router 路由表
│   ├── theme/                  设计令牌与配色
│   ├── utils/                  格式化、日志、错误处理等工具
│   └── widgets/                通用 UI 组件（卡片、脚手架、进度条等）
├── data/
│   ├── db/                     drift 表定义、数据库、生成代码（*.g.dart）
│   ├── remote/                 远程数据源（社区评论 Waline 客户端）
│   └── repositories/           仓储（设置、任务存储、来源模板等）
├── engine/                     纯 Dart 下载引擎
│   ├── download_engine.dart    引擎编排：解析→调度→下载→解密→合并
│   ├── engine_config.dart      EngineConfig + DownloadRequest（含代理、命名逻辑）
│   ├── engine_store.dart       持久化抽象（EngineTaskRecord / EngineTaskStore）
│   ├── engine_events.dart      引擎事件（进度、状态、合并、完成、错误）
│   ├── m3u8/                   M3U8 解析器与播放列表模型
│   ├── scheduler/              分片调度器（AIMD 自适应并发）
│   ├── net/                    分片下载器、roUd PNG 解码器
│   ├── crypto/                 AES-CBC 流式解密
│   ├── merge/                  TS 合并、ffmpeg remux、文件夹合并
│   └── task/                   任务运行时状态与状态机
├── features/
│   ├── shell/                  自适应导航外壳
│   ├── new_download/           新建下载 / 批量导入
│   ├── downloads/              下载列表（任务卡片、右键/长按菜单）
│   ├── history/                历史记录
│   ├── player/                 内置播放器
│   ├── merge/                  本地文件夹合并
│   ├── settings/               设置（并发、代理、保存目录、主题等）
│   ├── community/              社区留言板
│   └── update/                 应用内更新
└── providers/                  Riverpod providers 与任务视图模型

test/                           单元/集成测试（core / data / engine / features）
docs/                           设计文档、需求规格、产品改进等
release-notes/                  各版本 GitHub Release 文案
.github/workflows/              CI（release.yml 按 tag 构建四平台并发布）
```

## 关键模块说明

- **DownloadEngine**（`engine/download_engine.dart`）：引擎核心。管理任务生命周期、并发信号量、分片调度、解密与合并；通过 `EngineEvent` 流上报进度，经 `EngineTaskStore` 持久化。
- **SegmentScheduler**（`engine/scheduler/`）：分片级并发调度，按 seq 升序派发；AIMD 自适应窗口（成功加性增、拥塞乘性减，下限 2、上限为用户配置值）。
- **SegmentDownloader**（`engine/net/`）：基于 dio 流式下载，写 `.part` 临时文件后原子重命名；分片级指数退避重试（0.3s/1s/3s），永久错误（400/401/403/404/410）快速失败；PNG `roUd` 解包与 AES 解密在 worker isolate 执行，避免阻塞事件循环。
- **并发模型**：任务并发（`taskConcurrency`，默认 3）× 分片并发（`segmentConcurrency`，默认 16）。"逐个下载"开启时任务并发强制为 1。
- **下载代理**：`EngineConfig.proxyHost/proxyPort` → 替换 dio 的 `IOHttpClientAdapter`，所有引擎流量（playlist/分片/密钥）走代理；留空恢复直连；保存即生效、重启后从设置恢复。
- **设置持久化**：键值对存于 drift `Settings` 表，经 `SettingsRepository` 类型化访问。
- **数据库迁移**：`AppDatabase.schemaVersion` 递增，`MigrationStrategy.onUpgrade` 按版本增量 `addColumn` / `createTable`。

## 开发约定

- **回复语言**：中文。
- **代码生成**：修改 drift 表、freezed、riverpod 或 `.arb` 后需运行
  `dart run build_runner build --delete-conflicting-outputs`（l10n 用 `flutter gen-l10n`）。生成文件（`*.g.dart`、`*.freezed.dart`、`app_localizations*.dart`）须随源码一并提交，不要手改。
- **提交前校验**：`flutter analyze`（须无 issue）+ `flutter test`（须全绿）。
- **引擎纯净性**：`engine/` 不得引入 Flutter 依赖，保持可单测。
- **国际化**：新增用户可见文案须同时加入 `app_zh.arb` 与 `app_en.arb`（模板为 zh），不要在代码里硬编码用户可见字符串。
- **命名逻辑**：默认标题在 `DownloadRequest.effectiveTitle`，需处理通用名（index/master 等）与图片伪装扩展名（png/jpg/jpeg/webp/gif），避免同名冲突。
- **数据库改动**：新增/修改列时同步递增 `AppDatabase.schemaVersion` 并在 `MigrationStrategy.onUpgrade` 补迁移，保证老用户升级不丢数据。

## 代码风格

- 遵循 `package:flutter_lints` 默认规则（见 `analysis_options.yaml`），`build/`、各平台目录已排除。
- Dart 官方风格：2 空格缩进；优先 `const` 构造；用 `final` 而非 `var`（类型明显时）。
- 公共 API 写文档注释（`///`）；注释解释"为什么"而非复述代码。
- 优先早返回、避免深层嵌套；不可达分支用 `// Ignore.` 等简短注释说明。
- 文件顶部 `library;` 声明 + 模块用途注释（引擎层惯例）。

## 测试说明

- 测试位于 `test/`，按 `core / data / engine / features` 分层；引擎测试用内存假件（`InMemoryTaskStore`、`FakeHlsServer`）避免真实网络/磁盘依赖。
- 核心引擎单元测试覆盖率目标 **≥70%**。
- 网络相关测试通过本地回环服务器（`HttpServer.bind(loopbackIPv4, 0)`）模拟源站/代理，断言请求计数与内容。
- 改动引擎逻辑（解析、调度、下载、解密、合并、命名）须补充或更新对应测试；修复 bug 优先加回归用例。
- 集成测试在 `integration_test/`，CI 计划见 `.github/workflows/`。

## 安全注意事项

- **不要在仓库中提交任何私密信息**：本地绝对路径、个人姓名/邮箱、设备标识、内网地址、密钥、keystore、token 等一律不得写入代码、文档或日志。
- 诊断信息（`FailureDiagnosis.report`）刻意脱敏：不含请求头、查询串与密钥，仅保留 host 与错误码。
- 下载代理仅作用于引擎流量；代理地址等用户配置存于本地数据库，不外传。
- 深链 `stream-mediary://download` 解析须校验 scheme/host 与 URL 合法性（见 `DownloadLink.parse`），限制长度，拒绝非 http(s)。
- 处理外部输入（m3u8、PNG `roUd`、HTTP 响应）时注意边界：截断、越界 byte range、异常 padding 均须抛错而非崩溃。
- 本项目仅供合法用途，不支持 DRM；改动不得引入绕过版权保护的能力。

## 提交与 PR 规范

- 提交信息遵循 **Conventional Commits**：`feat:` / `fix:` / `perf:` / `refactor:` / `test:` / `docs:` / `chore:` / `style:`，可带 scope（如 `fix(theme):`）。
- 首行用祈使句、简洁概括；必要时空行后列要点说明动机与影响。
- 版本发布单独用 `chore: bump version to x.y.z+n` 提交（见下方发布流程）。
- PR 前确保 `flutter analyze` 与 `flutter test` 通过；改动功能须附测试。

## 发布流程

1. 升级 `pubspec.yaml` 的 `version`（`x.y.z+n`）。
2. 更新 `CHANGELOG.md`，新增 `release-notes/vX.Y.Z.md`。
3. 两个提交：功能提交 + `chore: bump version to ...`。
4. 在版本提交上打 tag `vX.Y.Z`，推送 `main` 与 tag。
5. tag 推送触发 `release.yml`：构建 Android/macOS/iOS/Windows 产物，生成 `SHA256SUMS.txt`，自动发布 GitHub Release（正文取 `release-notes/<tag>.md`）。

## 免责声明

本项目仅供个人、学习与合法用途。使用者需自行确保拥有所下载内容的合法权利，不得用于侵犯版权或违反服务条款。DRM 保护的流不受支持。
