# Maestro 自动化测试

移动端（Android / iOS）UI 自动化测试，基于 [Maestro](https://maestro.mobile.dev)。
测试范围、用例矩阵与执行步骤见 [`docs/maestro-test-plan.md`](../docs/maestro-test-plan.md)。

## 目录

```
maestro/
├── serve_test_hls.sh        本地 HLS 测试源（ffmpeg 生成 + http.server 提供）
├── dismiss_permissions.yaml 权限弹窗统一处理（被各 flow 引用）
├── app_launch.yaml          冷启动与首屏
├── navigation.yaml          底部导航 5 tab 切换
├── new_download_parse.yaml  新建下载：解析预览 + 无效地址
├── download_flow.yaml       完整下载生命周期（依赖本地 HLS 源）
├── history.yaml             历史记录页
├── community.yaml           留言板 + emoji 面板
├── settings.yaml            设置：分区/主题/版本
├── merge_page.yaml          合并页
├── player.yaml              内置播放器（依赖已完成下载）
└── test_hls/                serve_test_hls.sh 生成的测试流（git 忽略）
```

## 快速开始

```bash
# 0. 安装 Maestro（一次性）
curl -Ls "https://get.maestro.mobile.dev" | bash
export PATH="$PATH:$HOME/.maestro/bin"

# 1. 启动本地 HLS 测试源（保持后台运行）
./maestro/serve_test_hls.sh

# 2. 执行（Android 模拟器示例）
maestro test maestro/app_launch.yaml \
  --device emulator-5554 \
  -e APP_ID=com.element.stream_mediary \
  -e HLS_URL=http://10.0.2.2:8099/index.m3u8
```

环境变量：
- `APP_ID` — Android `com.element.stream_mediary` / iOS `com.element.streamMediary`
- `HLS_URL` — Android 模拟器用 `10.0.2.2`（主机回环），iOS 模拟器用 `127.0.0.1`

设备：两端均用模拟器（Android `Pixel_9a` / iOS `iPhone 17 Pro`），系统语言设为
**英文**，用例断言统一英文文案。详见 `docs/maestro-test-plan.md`。

## 执行顺序

各 flow 自包含：`history.yaml` 与 `player.yaml` 内部会先 `runFlow: download_flow.yaml`
创建标题为 **MaestroTest** 的已完成下载，因此任意顺序、单独或全量执行均可。
建议全量：

```bash
maestro test maestro/ --device <设备ID> -e APP_ID=<应用ID> -e HLS_URL=<测试流地址>
```

## 约定

- 选择器优先用可见中文文案，其次 `id`，避免绝对坐标。
- 每个 flow 自包含（`launchApp` 开头），可单独运行。
- 系统级 UI（文件选择器、分享面板）不深入断言，跨平台不稳定。
- 文案（arb）改动需同步更新用例断言字符串。
