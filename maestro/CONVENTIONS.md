# Maestro 用例编写规范

> 目标：新增功能时**只需按本规范补一个 flow 文件**，放进 `maestro/` 即被全量
> 执行自动收录（运行步骤见 `maestro/README.md`）。本文是实测踩坑后的固化约定，
> 写用例前必读。

## 1. 新增用例的标准步骤

1. 复制 `_template.yaml.example` 为 `maestro/<功能名>.yaml`。
2. 按模板注释填写：`appId` 头、启动、权限、操作、断言。
3. 本地单跑验证（设备/参数见 README「关键参数速查」）：
   ```bash
   maestro test maestro/<功能名>.yaml --device emulator-5554 \
     -e APP_ID=com.element.stream_mediary \
     -e HLS_URL=http://10.0.2.2:8099/index.m3u8
   ```
4. 两端全量回归（README 步骤 4）。
5. 在 `docs/maestro-test-plan.md` 的用例矩阵登记一行。

> flow 文件名即测试名；放进 `maestro/` 目录就会被全量执行自动收录，
> 无需在任何清单里注册。

## 2. Flow 结构约定

每个 flow **自包含**，可单独运行、不依赖执行顺序：

```yaml
appId: ${APP_ID}          # 由 maestro 命令行 -e 注入，勿写死
---
- launchApp               # 需要干净状态时加 clearState: true
- runFlow: dismiss_permissions.yaml   # 统一处理首启权限弹窗
- extendedWaitUntil:      # 等首屏就绪再操作
    visible: "Downloads"
    timeout: 20000
# …操作与断言…
```

- **依赖前置数据的 flow**（如历史/播放器需要一条已完成下载）：直接
  `- runFlow: download_flow.yaml`，不要假设别的 flow 先跑过。
- **会改全局状态的 flow**（如切主题）：结束前恢复原状（切回 System），
  避免污染后续 flow。
- 需要干净数据时用 `launchApp: { clearState: true }`；依赖既有数据时**不要** clearState。

## 3. 选择器规则（最重要）

Maestro 文本匹配是**全匹配**，而 Flutter 的无障碍节点常把多段文本合并。
按以下优先级选选择器：

| 场景 | 节点实际文本 | 正确写法 |
|---|---|---|
| 普通按钮/标题 | `Parse` | `tapOn: "Parse"` |
| 底部导航标签 | `Board\nTab 4 of 5`（Android 加后缀） | `tapOn: 'Board[\s\S]*'` |
| 输入框（label+hint 合并） | `M3U8 URL\nEnter or paste…` | `tapOn: 'M3U8 URL[\s\S]*'` |
| 卡片/多行信息块 | `Parse result\nNot encrypted\n…` | `visible: 'Parse result[\s\S]*'` |
| 文本在节点中部 | `Mediary\nVersion 0.4.0\nCheck…` | `visible: '[\s\S]*Version[\s\S]*'` |

**规则**：
- 单行独立文本 → 精确串。
- 可能带后缀/多行合并 → 用 `[\s\S]*` 正则（`[\s\S]` 才能跨换行，`.` 不行）。
- 同名元素多个 → 加 `index: N`（如设置页两个 "System" 分段按钮，主题用 `index: 0`）。
- 图标按钮无文本 → 依赖 `tooltip`/语义标签（见 §5），**不要**用坐标。
- 调试选择器：失败后看 `~/.maestro/tests/<时间戳>/<flow>/screen-hierarchy/*.json`
  里的真实节点文本，照它写正则。

## 4. 平台差异与陷阱（实测清单）

- **Android 导航后缀**：底部导航标签节点带 `Tab N of 5`，必须用正则。
- **iOS 关闭 modal sheet**：系统 back 手势**无效**。正确做法：
  `hideKeyboard`（键盘会吞掉点击）→ 点 barrier `tapOn: { text: "Scrim", optional: true }`。
  注意 `Dismiss` 是 sheet 的拖拽把手，点它**不会**关闭。
- **iOS 页面返回**：用 AppBar 返回按钮（语义标签 `Back`），不用 back 手势。
- **页面过渡竞态**：跳转后先 `waitForAnimationToEnd: { timeout: 10000 }` 再断言。
- **下载完成太快**：测试流是单分片 ~1MB，LAN 秒级完成，Downloads 页的
  `Downloading` 瞬态抓不到；完成态一律到 **History** 页断言任务出现。
- **系统级 UI 不深入**：文件选择器、分享面板等跨 app UI 两端差异大且不稳定，
  只验证到入口（如 `Choose folder`）出现即可。
- **权限弹窗**：统一 `runFlow: dismiss_permissions.yaml`，新增平台弹窗文案在那里加。

## 5. 应用侧配合（可测试性）

自动化依赖稳定的无障碍标签。给图标按钮加 `tooltip`（本地化）即可同时
提升可访问性与可测试性，例如播放器返回按钮：

```dart
IconButton(
  icon: const Icon(Icons.arrow_back_rounded),
  tooltip: MaterialLocalizations.of(context).backButtonTooltip, // "Back"/"返回"
  onPressed: ...,
)
```

新增纯图标交互控件时，**务必加 tooltip/语义标签**，否则用例只能靠坐标（禁止）。

## 6. 断言与等待

- 静态元素：`assertVisible` / `assertNotVisible`。
- 需等待出现：`extendedWaitUntil: { visible: ..., timeout: N }`。
- 滚动找元素：`scrollUntilVisible: { element: ..., direction: DOWN, timeout: N }`。
- 过渡后：`waitForAnimationToEnd`。
- 断言要选**稳定且语义明确**的文本（页面标题、分区头），不要断言易变的动态值
  （时间、进度数字）。

## 7. 环境变量

由 `maestro test` 命令行的 `-e` 参数注入（见 README 步骤 4），flow 里用
`${...}` 引用，**不要写死**：

- `${APP_ID}` — Android `com.element.stream_mediary` / iOS `com.element.streamMediary`
- `${HLS_URL}` — 测试流地址（Android `10.0.2.2:8099`，iOS `127.0.0.1:8099`）

## 8. 命名

- flow 文件：小写下划线，按功能命名（`download_flow.yaml`、`merge_page.yaml`）。
- 测试数据标题统一用 `MaestroTest`，便于 history/player 断言与排查。
