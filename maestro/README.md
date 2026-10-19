# Maestro 自动化测试

移动端（Android / iOS）UI 自动化测试，基于 [Maestro](https://maestro.mobile.dev)。

- **运行手册**：见下方「运行步骤」，agent 按序执行命令即可跑通全流程
- **用例规范**：[`CONVENTIONS.md`](CONVENTIONS.md)（新增用例前必读）
- **测试计划**：[`../docs/maestro-test-plan.md`](../docs/maestro-test-plan.md)（范围、矩阵、实测结论）

## 目录

```
maestro/
├── serve_test_hls.sh        本地 HLS 测试源（ffmpeg 生成 + http.server 提供）
├── CONVENTIONS.md           用例编写规范与平台陷阱清单
├── _template.yaml.example   新用例模板（复制为 <功能>.yaml）
├── dismiss_permissions.yaml 权限弹窗统一处理（被各 flow 引用）
├── app_launch.yaml          冷启动与首屏
├── navigation.yaml          底部导航 5 tab 切换
├── new_download_parse.yaml  新建下载：解析预览 + 无效地址
├── download_flow.yaml       完整下载生命周期（依赖本地 HLS 源）
├── history.yaml             历史记录页（内嵌 download_flow，自包含）
├── community.yaml           留言板 + emoji 面板
├── settings.yaml            设置：分区/主题/版本
├── merge_page.yaml          合并页
├── player.yaml              内置播放器（内嵌 download_flow，自包含）
└── test_hls/                serve_test_hls.sh 生成的测试流（git 忽略）
```

## 运行步骤（agent 按序执行）

### 0. 前置（一次性）

```bash
# 安装 Maestro
curl -Ls "https://get.maestro.mobile.dev" | bash
export PATH="$PATH:$HOME/.maestro/bin"   # 每条 maestro 命令前都要保证在 PATH
```

### 1. 启动设备（两端均为模拟器，系统语言英文）

```bash
# Android：启动模拟器并等待就绪
~/Library/Android/sdk/emulator/emulator -avd Pixel_9a -no-snapshot-save -no-boot-anim &
adb -s emulator-5554 wait-for-device
# 轮询直到 sys.boot_completed=1

# iOS：启动模拟器并设英文（若已是英文可跳过 defaults 两步）
xcrun simctl boot D1D7CA22-82C5-4906-87CE-BEC46EF72CF6
xcrun simctl spawn D1D7CA22-82C5-4906-87CE-BEC46EF72CF6 \
  defaults write "Apple Global Domain" AppleLanguages -array en
# 改过语言需 shutdown + boot 一次才生效
```

### 2. 构建并安装 app

```bash
# Android
flutter build apk --debug
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk

# iOS
flutter build ios --debug --simulator
xcrun simctl install D1D7CA22-82C5-4906-87CE-BEC46EF72CF6 build/ios/iphonesimulator/Runner.app
```

### 3. 启动本地 HLS 测试源（后台，跑完杀掉）

```bash
./maestro/serve_test_hls.sh &        # 生成 testsrc HLS 并监听 :8099
curl -s -o /dev/null http://127.0.0.1:8099/index.m3u8   # 确认 200
```

### 4. 执行测试

```bash
# Android 全量
maestro test maestro/ --device emulator-5554 \
  -e APP_ID=com.element.stream_mediary \
  -e HLS_URL=http://10.0.2.2:8099/index.m3u8

# iOS 全量
maestro test maestro/ --device D1D7CA22-82C5-4906-87CE-BEC46EF72CF6 \
  -e APP_ID=com.element.streamMediary \
  -e HLS_URL=http://127.0.0.1:8099/index.m3u8

# 单跑某个 flow（调试）：把 maestro/ 换成 maestro/<flow>.yaml
```

### 5. 判读与清理

- 末尾汇总 `N/10 Flows Passed`；失败看 `~/.maestro/tests/<时间戳>/<flow>/`
  的截图与 `screen-hierarchy/*.json`（真实节点文本，照它修选择器）。
- 清理：杀掉 `serve_test_hls.sh` 进程；模拟器可关可留。

## 新增用例（最常见操作）

1. `cp maestro/_template.yaml.example maestro/<功能名>.yaml`
2. 按 [`CONVENTIONS.md`](CONVENTIONS.md) 填写操作与断言
3. 单跑验证（步骤 4 的单 flow 形式，加 `--skip-build` 不需要，直接跑即可）
4. 两端全量回归（步骤 4）
5. 在 `docs/maestro-test-plan.md` 用例矩阵登记一行

放进 `maestro/` 的 `*.yaml` 会被全量执行自动收录，无需注册。

## 关键参数速查

| 参数 | Android | iOS |
|---|---|---|
| 设备 ID | `emulator-5554` | `D1D7CA22-82C5-4906-87CE-BEC46EF72CF6` |
| APP_ID | `com.element.stream_mediary` | `com.element.streamMediary` |
| HLS_URL | `http://10.0.2.2:8099/index.m3u8` | `http://127.0.0.1:8099/index.m3u8` |
