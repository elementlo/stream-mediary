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

### 准备（一次性）

```bash
# 1. 安装 Maestro
curl -Ls "https://get.maestro.mobile.dev" | bash
export PATH="$PATH:$HOME/.maestro/bin"

# 2. 构建并安装
flutter build apk --debug && adb -s 10CFCG0PPD001YM install -r build/app/outputs/flutter-apk/app-debug.apk
flutter build ios --debug --simulator
xcrun simctl boot D1D7CA22-82C5-4906-87CE-BEC46EF72CF6
xcrun simctl install D1D7CA22-82C5-4906-87CE-BEC46EF72CF6 build/ios/iphonesimulator/Runner.app

# 3. 启动本地 HLS 测试源（保持后台运行）
./maestro/serve_test_hls.sh          # 生成 testsrc HLS 并监听 :8099
```

### Android 模拟器（分步骤）

```bash
export ANDROID_DEVICE=emulator-5554
export APP_ID=com.element.stream_mediary
export HLS_URL=http://10.0.2.2:8099/index.m3u8   # 模拟器经 10.0.2.2 访问主机

# 逐模块执行（便于定位失败）
maestro test maestro/app_launch.yaml         --device $ANDROID_DEVICE -e APP_ID=$APP_ID -e HLS_URL=$HLS_URL
maestro test maestro/navigation.yaml         --device $ANDROID_DEVICE -e APP_ID=$APP_ID -e HLS_URL=$HLS_URL
maestro test maestro/new_download_parse.yaml --device $ANDROID_DEVICE -e APP_ID=$APP_ID -e HLS_URL=$HLS_URL
maestro test maestro/download_flow.yaml      --device $ANDROID_DEVICE -e APP_ID=$APP_ID -e HLS_URL=$HLS_URL
maestro test maestro/history.yaml            --device $ANDROID_DEVICE -e APP_ID=$APP_ID -e HLS_URL=$HLS_URL
maestro test maestro/community.yaml          --device $ANDROID_DEVICE -e APP_ID=$APP_ID -e HLS_URL=$HLS_URL
maestro test maestro/settings.yaml           --device $ANDROID_DEVICE -e APP_ID=$APP_ID -e HLS_URL=$HLS_URL
maestro test maestro/merge_page.yaml         --device $ANDROID_DEVICE -e APP_ID=$APP_ID -e HLS_URL=$HLS_URL
maestro test maestro/player.yaml             --device $ANDROID_DEVICE -e APP_ID=$APP_ID -e HLS_URL=$HLS_URL

# 或一次性全量
maestro test maestro/ --device $ANDROID_DEVICE -e APP_ID=$APP_ID -e HLS_URL=$HLS_URL
```

### iOS 模拟器（分步骤）

```bash
export IOS_DEVICE=D1D7CA22-82C5-4906-87CE-BEC46EF72CF6
export APP_ID=com.element.streamMediary
export HLS_URL=http://127.0.0.1:8099/index.m3u8

maestro test maestro/app_launch.yaml --device $IOS_DEVICE -e APP_ID=$APP_ID -e HLS_URL=$HLS_URL
# ……其余同上，替换 --device 与 -e
```

### 结果判读

- 每个 flow 输出 `PASSED/FAILED`；失败时 Maestro 打印失败步骤与截图路径。
- 全量执行汇总在终端末尾（`X flows passed, Y failed`）。
- 失败分类：**用例问题**（选择器/时序）→ 修 YAML；**应用缺陷** → 记录并单独修复。

## 4. 用例编写约定

- 选择器优先级：可见英文文案 > 正则（组合多行节点/导航后缀）> `id` > 坐标（最后手段）。
- 每个 flow 自包含：`launchApp`（含 `clearState` 视需要）→ 操作 → 断言。
  依赖前置数据的 flow（history/player）直接 `runFlow: download_flow.yaml`，
  不依赖执行顺序。
- 等待用 `assertVisible` 自带超时（默认 5s），长任务（下载/合并）显式
  `extendedWaitUntil`；页面过渡用 `waitForAnimationToEnd` 消除竞态。
- 下载类用例依赖本地 HLS 源，执行前必须确认 `serve_test_hls.sh` 在跑。
- 不在用例里写死设备分辨率相关的绝对坐标，滑动用相对方向（`swipe`/`scroll`）。
- 关闭 modal sheet 用 `hideKeyboard` + 点 `Scrim`（barrier），不用系统 back。

## 5. 执行结果（2026-10-19）

| 平台 | 结果 |
|---|---|
| Android 模拟器 Pixel_9a | **10/10 flows passed**（4m41s） |
| iOS 模拟器 iPhone 17 Pro | **10/10 flows passed**（3m46s） |

## 6. 维护

- 新增页面/功能时同步补 flow，并在本计划矩阵登记。
- 文案改动（arb）需同步更新用例断言字符串。
- CI 集成（可选后续）：GitHub Actions macOS runner 可跑 iOS 模拟器 flow；
  Android 真机需 self-hosted runner，暂不纳入 CI。
