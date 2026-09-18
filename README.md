<p align="center">
  <img src="docs/banner.png" alt="Mediary banner" width="100%" />
</p>

<p align="center">
  <img src="assets/icon.png" alt="Mediary logo" width="96" height="96" />
</p>

<h1 align="center">Mediary</h1>

<p align="center">
  基于 Flutter 打造的跨平台 <strong>M3U8 / HLS</strong> 媒体下载器。<br />
  解析、下载、解密并合并流媒体分片，输出单个可播放的视频文件。
</p>

<p align="center">
  <strong>简体中文</strong> | <a href="README.en.md">English</a>
</p>

<p align="center">
  <a href="https://github.com/elementlo/stream-mediary/releases">
    <img src="https://img.shields.io/github/v/release/elementlo/stream-mediary?label=release" alt="Release" />
  </a>
  <a href="https://github.com/elementlo/stream-mediary/actions/workflows/release.yml">
    <img src="https://img.shields.io/github/actions/workflow/status/elementlo/stream-mediary/release.yml?label=build" alt="Build" />
  </a>
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  </a>
  <a href="https://github.com/elementlo/stream-mediary/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/elementlo/stream-mediary" alt="License: MIT" />
  </a>
  <img src="https://img.shields.io/badge/平台-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20macOS-success" alt="Platforms" />
</p>

<p align="center">
  <a href="#-功能特性">功能特性</a> •
  <a href="#-产品截图">产品截图</a> •
  <a href="#-下载安装">下载安装</a> •
  <a href="#-快速开始">快速开始</a> •
  <a href="#-架构设计">架构设计</a> •
  <a href="#-参与贡献">参与贡献</a>
</p>

---

## ✨ 功能特性

- **🔗 HLS 解析** — 粘贴 `.m3u8` 地址即可预览分片数量、总时长、加密状态与估算大小；master playlist 会列出全部清晰度/带宽供选择。
- **⚡ 并发下载** — 两级调度：任务级并发（默认 3）+ 任务内分片并发（默认 8）。
- **🔐 AES 解密** — 纯 Dart 流式 AES-128/192/256-CBC 解密，支持自定义 HTTP 请求头与用户指定的 KEY / IV 覆盖。
- **🧩 智能合并** — 分片按序拼接为单个 `.ts`；检测到 `ffmpeg` 时无损 remux 为 `.mp4`（`-c copy`），失败自动回退保留 `.ts`。
- **⏯️ 断点续传** — 应用重启后自动恢复未完成任务，已完成分片不重复下载；分片级指数退避重试。
- **🎬 内置播放器** — 应用内直接播放下载的 `.ts` / `.mp4`，完整控制条 + 桌面端键盘快捷键。
- **🕘 历史记录** — 任务历史持久化，支持播放、重新下载、打开所在目录与删除。
- **🎨 Material 3** — 亮色 / 暗色 / 跟随系统主题，自适应导航（移动端底部栏，桌面端侧边栏）。
- **🌍 国际化** — 中文（默认）与英文。

## 📱 产品截图

<p align="center">
  <table>
    <tr>
      <td align="center"><sub><b>Android</b></sub><br /><img src="docs/screenshots/android-home.png" alt="Android 首页" width="200" /></td>
      <td align="center"><sub><b>iOS</b></sub><br /><img src="docs/screenshots/ios-home.png" alt="iOS 首页" width="200" /></td>
      <td align="center"><sub><b>macOS</b></sub><br /><img src="docs/screenshots/macos-home.png" alt="macOS 首页" width="300" /></td>
      <td align="center"><sub><b>Windows</b></sub><br /><img src="docs/screenshots/windows-home.png" alt="Windows 首页" width="300" /></td>
    </tr>
  </table>
</p>

## ⬇️ 下载安装

前往 **[Releases](https://github.com/elementlo/stream-mediary/releases)** 页面获取对应平台的预编译安装包。

| 平台 | 安装包 |
|---|---|
| Windows | `.exe` / `.msix` |
| macOS | `.dmg` / `.app` |
| Android | `.apk` |
| iOS | 需自行编译并侧载 |

## 🚀 快速开始

### 环境要求

- [Flutter](https://docs.flutter.dev/get-started/install) **3.47+**（Dart SDK ^3.13）
- 目标平台对应的工具链（Xcode、Android Studio、Visual Studio 等）
- *（可选）* `PATH` 中的 `ffmpeg`，用于 MP4 remux

### 从源码构建

```bash
# 1. 克隆仓库
git clone https://github.com/elementlo/stream-mediary.git
cd stream-mediary

# 2. 安装依赖
flutter pub get

# 3. 运行代码生成（drift、freezed、riverpod、l10n）
dart run build_runner build --delete-conflicting-outputs

# 4. 在已连接的设备 / 桌面上运行
flutter run
```

构建发布版本：

```bash
flutter build apk        # Android
flutter build ios        # iOS
flutter build windows    # Windows
flutter build macos      # macOS
```

## 🏗️ 架构设计

Mediary 采用分层、单向依赖的架构。下载**引擎为纯 Dart，零 Flutter 依赖**，运行在独立 isolate 中，可完整单元测试。

```
┌─────────────────────────────────────────────┐
│ features/   (UI 层)                           │
│   shell · new_download · downloads ·          │
│   history · player · settings                 │
├─────────────────────────────────────────────┤
│ providers/  (Riverpod 状态层)                  │
├─────────────────────────────────────────────┤
│ data/       (drift 数据库 + 仓储层)            │
├─────────────────────────────────────────────┤
│ engine/     (纯 Dart 下载引擎)                 │
│   m3u8 · scheduler · net · crypto · merge     │
└─────────────────────────────────────────────┘
```

**技术栈**

| 领域 | 选型 |
|---|---|
| 状态管理 | `flutter_riverpod` + `riverpod_annotation` |
| 路由 | `go_router` |
| 网络 | `dio` |
| 解密 | `pointycastle`（纯 Dart AES-CBC） |
| 数据库 | `drift` + `sqlite3_flutter_libs` |
| 播放 | `media_kit` |
| 模型 | `freezed` + `json_serializable` |

完整设计文档见 [`docs/design.md`](docs/design.md)，需求规格见 [`docs/requirements.md`](docs/requirements.md)。

## 🧪 测试

```bash
flutter test              # 单元测试（解析器、解密器、合并器、调度器）
flutter test --coverage   # 生成覆盖率报告
```

核心引擎单元测试覆盖率目标 **≥70%**。

## 🤝 参与贡献

欢迎贡献代码！请随时提交 issue 或 pull request。

1. Fork 本仓库
2. 创建特性分支（`git checkout -b feature/amazing-feature`）
3. 提交改动（`git commit -m 'Add some amazing feature'`）
4. 推送分支（`git push origin feature/amazing-feature`）
5. 发起 Pull Request

## ⚠️ 免责声明

Mediary 仅供**个人、学习与合法用途**使用。你需自行确保拥有所下载内容的合法权利。请勿使用本软件侵犯版权或违反任何服务商的服务条款。

## 📄 许可证

基于 **MIT License** 分发，详见 [`LICENSE`](LICENSE)。

---

<p align="center">
  使用 Flutter 以 💙 打造 · <a href="https://github.com/elementlo/stream-mediary">elementlo/stream-mediary</a>
</p>
