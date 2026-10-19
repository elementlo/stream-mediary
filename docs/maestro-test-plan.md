# Mediary Maestro 自动化测试计划

> 框架：[Maestro](https://maestro.mobile.dev) 2.11.0 · 平台：Android 真机 + iOS 模拟器
> 用例目录：`maestro/` · 本文档为测试范围、用例矩阵与执行步骤。

## 1. 测试环境

| 项 | Android | iOS |
|---|---|---|
| 设备 | 模拟器 Pixel_9a（Android 16 / API 36） | iPhone 17 Pro 模拟器（iOS 26.5） |
| 设备 ID | `emulator-5554` | `D1D7CA22-82C5-4906-87CE-BEC46EF72CF6` |
| 应用 ID | `com.element.stream_mediary` | `com.element.streamMediary` |
| 构建 | `flutter build apk --debug` | `flutter build ios --debug --simulator` |
| 网络 | 模拟器经 `10.0.2.2` 访问主机 | 共享主机网络栈，访问 `127.0.0.1` |

> 两端均用模拟器而非真机：真机（尤其国产 ROM）对后台 instrumentation
> 管控严格，Maestro 驱动易超时；模拟器环境可控、可复现。

**测试流媒体源**：本地 HLS 服务器（`maestro/serve_test_hls.sh`），用 ffmpeg 生成
10 秒 testsrc 视频 → 单分片 HLS，经 `python3 -m http.server` 提供。
- Android 访问 `http://10.0.2.2:8099/index.m3u8`
- iOS 模拟器访问 `http://127.0.0.1:8099/index.m3u8`

**语言**：两台模拟器均设为**英文**（iOS 用 `simctl spawn defaults write
"Apple Global Domain" AppleLanguages -array en`；Android 模拟器默认英文），
用例断言统一用英文文案，跨平台一致、不依赖设备语言。

## 2. 测试范围与用例矩阵

覆盖全部 5 个主导航页 + 新建下载/批量导入/播放器子页。共 9 个 flow：

| # | Flow 文件 | 覆盖功能 | 关键断言 |
|---|---|---|---|
| 1 | `app_launch.yaml` | 冷启动、首屏渲染 | 出现「下载中」页与空态/任务列表 |
| 2 | `navigation.yaml` | 底部导航 5 tab 切换 | 每页标题正确（下载中/历史记录/合并/留言板/设置） |
| 3 | `new_download_parse.yaml` | 新建下载：输入 m3u8 → 解析预览 | 出现「解析结果」与分片信息；无效地址报错 |
| 4 | `download_flow.yaml` | 完整下载：解析 → 开始下载 → 完成 | 状态从「下载中」到「已完成」，进度条推进 |
| 5 | `history.yaml` | 历史记录：完成的任务入历史、播放入口 | 历史页出现该任务；删除确认弹窗可取消 |
| 6 | `community.yaml` | 留言板：加载列表、打开发布面板、emoji 面板 | 出现留言列表或空态；发布面板含昵称/内容框；emoji 面板可开合 |
| 7 | `settings.yaml` | 设置：主题切换、语言、并发滑块、代理输入、关于 | 主题即时生效；各分区标题存在；版本号显示 |
| 8 | `merge_page.yaml` | 合并页：入口与文件夹选择器 | 出现「选择文件夹」；无 ts 文件时提示 |
| 9 | `player.yaml` | 内置播放器：从历史打开播放 | 播放器页面出现、控制条可见、可返回 |

### 平台差异处理（实测结论）

- **权限弹窗**：Android 存储/通知权限、iOS 通知与本地网络权限——各 flow 开头用
  `runFlow: dismiss_permissions.yaml` 统一尝试点掉（Allow/OK 等），不存在则跳过。
- **导航形态**：手机宽度下两端均为底部导航栏（`NavigationBar`），用例一致。
- **Android 无障碍后缀**：底部导航标签的节点文本带 `Tab N of 5` 后缀
  （如 `Board\nTab 4 of 5`），Maestro 文本为全匹配，故导航 tap 一律用跨换行正则
  `'Board[\s\S]*'`；页面标题/分区标题是独立精确节点，用精确串。
- **组合多行节点**：Flutter 把 label+hint、卡片多行文本合并为单个节点
  （如 `M3U8 URL\nEnter or paste…`、`Parse result\nNot encrypted…`、
  `Task concurrency\n3\n1\n16`、历史条目 `MaestroTest\n<日期>\n<size>`），
  这些一律用前缀/包含式正则匹配。
- **iOS 返回**：系统 back 手势对 modal bottom sheet 与 push 页不可靠；
  关闭 sheet 用 `hideKeyboard` + 点 barrier（语义标签 `Scrim`，注意 `Dismiss`
  是 sheet 拖拽把手、点击不关闭）；播放页返回用 AppBar 返回按钮
  （已加本地化 tooltip「Back」作为稳定无障碍标签）。
- **下载完成太快**：测试流为单分片 ~1MB，LAN 下秒级完成，Downloads 页的
  「Downloading」瞬态抓不到；完成态改由 History 出现该任务断言。
- **文件选择器**：合并页/保存目录的系统选择器 UI 两端不同，用例只验证到
  「Choose folder」入口出现，不深入系统选择器内部（跨 app UI 不稳定）。
- **深链/托盘/窗口**：桌面专属功能不在移动端测试范围。

### 不覆盖项（说明）

- DRM、真实签名 CDN 流（会过期，不可重复）
- 系统文件选择器内部操作、系统分享
- iOS 侧载安装流程（无签名包需开发者证书）

## 3. 执行步骤

完整运行手册见 [`maestro/README.md`](../maestro/README.md)（agent 按序执行命令即可）。
概要：

```bash
# 0. 安装 Maestro（一次性）
curl -Ls "https://get.maestro.mobile.dev" | bash
export PATH="$PATH:$HOME/.maestro/bin"

# 1. 启动两台模拟器（系统语言英文；iOS 改语言后需重启模拟器）
~/Library/Android/sdk/emulator/emulator -avd Pixel_9a -no-snapshot-save -no-boot-anim &
xcrun simctl boot D1D7CA22-82C5-4906-87CE-BEC46EF72CF6

# 2. 构建并安装
flutter build apk --debug
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
flutter build ios --debug --simulator
xcrun simctl install D1D7CA22-82C5-4906-87CE-BEC46EF72CF6 build/ios/iphonesimulator/Runner.app

# 3. 启动本地 HLS 测试源（后台）
./maestro/serve_test_hls.sh &

# 4. 执行（全量；单 flow 把 maestro/ 换成 maestro/<flow>.yaml）
maestro test maestro/ --device emulator-5554 \
  -e APP_ID=com.element.stream_mediary -e HLS_URL=http://10.0.2.2:8099/index.m3u8
maestro test maestro/ --device D1D7CA22-82C5-4906-87CE-BEC46EF72CF6 \
  -e APP_ID=com.element.streamMediary -e HLS_URL=http://127.0.0.1:8099/index.m3u8

# 5. 清理：杀掉 serve_test_hls.sh
```

### 结果判读

- 末尾汇总 `N/10 Flows Passed`。
- 失败时调试产物（截图 + UI 层级 JSON）在 `~/.maestro/tests/<时间戳>/<flow>/`；
  选择器失败照 `screen-hierarchy/*.json` 里的真实节点文本修正。
- 失败分类：**用例问题**（选择器/时序）→ 修 YAML；**应用缺陷** → 记录并单独修复。

## 4. 用例编写约定

完整规范见 [`maestro/CONVENTIONS.md`](../maestro/CONVENTIONS.md)（选择器规则、
平台陷阱清单、flow 结构、新增用例步骤）。要点：

- 选择器优先级：可见英文文案 > 正则（组合多行节点/导航后缀）> `id` > 坐标（禁用）。
- 每个 flow 自包含；依赖前置数据的直接 `runFlow: download_flow.yaml`。
- 长任务用 `extendedWaitUntil`，页面过渡用 `waitForAnimationToEnd`。
- 关闭 modal sheet 用 `hideKeyboard` + 点 `Scrim`，不用系统 back。
- 新增用例：复制 `maestro/_template.yaml.example` → 填写 → 单跑 → 全量回归 → 登记矩阵。

## 5. 执行结果（2026-10-19）

| 平台 | 结果 |
|---|---|
| Android 模拟器 Pixel_9a | **10/10 flows passed**（4m41s） |
| iOS 模拟器 iPhone 17 Pro | **10/10 flows passed**（3m46s） |

## 6. 维护

- **新增功能 → 只补一个 flow**：复制 `maestro/_template.yaml.example`，按
  `maestro/CONVENTIONS.md` 编写，放进 `maestro/` 即被全量执行自动收录，
  再在本计划矩阵登记一行。运行手册无需改动。
- 文案改动（arb）需同步更新用例断言字符串。
- 新增平台弹窗文案 → 改 `dismiss_permissions.yaml` 一处即可。
- CI 集成（可选后续）：GitHub Actions macOS runner 可跑 iOS 模拟器 flow；
  Android 模拟器也可在 macOS runner 上跑（按 README 运行手册执行）。
