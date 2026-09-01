# stream-mediary 设计文档（Design）

> SDD 第二层文档。定义系统架构、模块接口、数据模型与平台适配策略。
> 上游文档：[requirements.md](./requirements.md)

## 1. 技术选型

| 领域 | 选型 | 版本策略 | 理由 |
|---|---|---|---|
| 状态管理 | flutter_riverpod + riverpod_annotation | ^3.x | 类型安全、依赖注入、对 Stream/Isolate 友好 |
| 路由 | go_router | ^16.x | 声明式、桌面/移动自适应 |
| HTTP | dio | ^5.x | 流式响应、拦截器注入自定义头、CancelToken |
| AES 解密 | pointycastle | ^4.x | 纯 Dart 四平台，CBC 分块流式解密 |
| 数据库 | drift + sqlite3_flutter_libs | ^2.x | 类型安全、四平台、后台 isolate |
| 播放 | media_kit + media_kit_video + media_kit_libs_video | ^1.x | 六平台、直接播放 .ts |
| 目录选择 | file_selector | ^1.x | 官方、桌面 + Android |
| 权限 | permission_handler | ^12.x | Android |
| 窗口 | window_manager | ^0.5.x | 桌面窗口尺寸/标题 |
| 模型 | freezed + json_serializable | ^3.x / ^6.x | 不可变模型 + JSON |
| 国际化 | flutter_localizations + intl | — | zh/en |

## 2. 分层架构

```
┌─────────────────────────────────────────────┐
│ features/ (UI 层)                            │
│   shell · new_download · downloads ·        │
│   history · player · settings               │
├─────────────────────────────────────────────┤
│ providers/ (Riverpod 状态层)                  │
│   engineProviders · taskListProvider ·      │
│   settingsProvider · historyProvider        │
├─────────────────────────────────────────────┤
│ data/ (数据层)                                │
│   db/ (drift: AppDatabase + DAO)            │
│   repositories/ (TaskRepo · SettingsRepo)   │
├─────────────────────────────────────────────┤
│ engine/ (纯 Dart 下载引擎，零 Flutter 依赖)    │
│   m3u8/ · task/ · scheduler/ · net/ ·       │
│   crypto/ · merge/ · isolate 门面            │
└─────────────────────────────────────────────┘
```

依赖方向单向向下；engine 不依赖 Flutter，可独立单测。

### 目录结构

```
lib/
├── main.dart                    # 初始化 DB/Engine/ProviderScope
├── app.dart                     # MaterialApp.router + M3 主题
├── core/
│   ├── theme/app_theme.dart
│   ├── router/app_router.dart
│   ├── l10n/                    # arb 文件与生成
│   └── utils/                   # hex/url/formatters
├── engine/
│   ├── m3u8/
│   │   ├── playlist.dart        # MasterPlaylist/Variant/MediaPlaylist/Segment/KeyInfo
│   │   ├── attribute_parser.dart
│   │   └── m3u8_parser.dart
│   ├── task/task_state.dart     # 状态机 enum + canTransition
│   ├── scheduler/segment_scheduler.dart
│   ├── net/segment_downloader.dart
│   ├── crypto/aes_decryptor.dart
│   ├── merge/ts_merger.dart
│   ├── merge/ffmpeg_remuxer.dart
│   ├── engine_isolate.dart      # 常驻 Isolate 入口 + 命令/事件协议
│   └── download_engine.dart     # 主 isolate 门面
├── data/
│   ├── db/app_database.dart     # drift 定义
│   └── repositories/
├── providers/
└── features/
    ├── shell/adaptive_shell.dart
    ├── new_download/
    ├── downloads/
    ├── history/
    ├── player/
    └── settings/
```

## 3. 下载引擎设计

### 3.1 任务状态机

```
created → parsing → preview_ready → queued → downloading ⇄ paused
                                                ↓
failed ←(可重试错误)──────────────────────  merging → completed
failed / canceled →(用户重试)→ queued
```

- `TaskState` enum + `canTransition(from, to)` 迁移表集中校验，非法迁移记日志并忽略
- 状态变更产生 `TaskStateChangedEvent` 推送 UI 与持久化

### 3.2 Isolate 组织

- 单个常驻引擎 Isolate（`engine_isolate.dart`）承载：状态机、调度器、dio 实例、解密、合并
- 主 isolate `DownloadEngine` 门面：
  - 命令（SendPort）：`parse / start / pause / resume / cancel / retry / restore / updateSettings`
  - 事件（Stream<EngineEvent>）：`taskStateChanged / progress(taskId, doneSegs, totalSegs, bytes, speed) / mergeProgress / taskCompleted / errorOccurred`
- 事件 500ms 节流，避免 UI 高频 rebuild

### 3.3 两级并发调度

- 任务级：信号量控制同时下载的任务数（设置项，默认 3）
- 分片级：每任务内信号量池（默认 8），分片按序号升序入队（小序号优先，利于尽早合并）
- 暂停 = 停止派发新分片 + 取消进行中请求；恢复 = 重新入队未完成分片

### 3.4 分片持久化与断点续传

- 分片落盘：`{taskDir}/segments/{seq:06d}.ts`，先写 `.part` 再原子 rename
- 分片状态写 drift（pending/downloading/done/failed + byteSize + retryCount），批量事务（每 20 条或 2s）
- 任务记录保存 `playlist_snapshot`（解析结果 JSON）
- 重启 restore：扫描分片目录，文件存在且大小一致 → done；`.part` 删除重下

### 3.5 解密管道

- `EXT-X-KEY:METHOD=AES-128/192/256`，key 从 `URI` 拉取（携带自定义头），按 URI 缓存
- IV 缺省 = 分片 media sequence number 的 16 字节大端表示
- 用户自定义 KEY/IV（hex）全局覆盖
- 流式解密：`Stream<bytes> → CBC 按 16B 块解密 → 输出流`；仅缓存末块，EOF 时 PKCS7 去填充；每分片独立
- 多段 EXT-X-KEY（key 轮换）按分片区间绑定

### 3.6 合并器

1. `ts_merger`：按序流式拷贝（1MB buffer）→ `{title}.ts`，进度 = 已写/总字节
2. `ffmpeg_remuxer`：探测（PATH + `/opt/homebrew/bin` + `/usr/local/bin` + 用户手填路径）→ `ffmpeg -y -i out.ts -c copy -movflags +faststart out.mp4`；失败回退保留 .ts
3. 产物路径写回任务记录

## 4. 数据模型（drift）

```
tasks:
  id TEXT PK(uuid)          url TEXT
  title TEXT                status INTEGER        # TaskState index
  headers TEXT              # JSON map<string,string>
  custom_key TEXT?          custom_iv TEXT?
  variant_json TEXT?        # 选中清晰度信息
  playlist_snapshot TEXT    # 解析结果 JSON（续传依据）
  save_dir TEXT             output_path TEXT?
  total_segments INTEGER    done_segments INTEGER
  total_bytes INTEGER       downloaded_bytes INTEGER
  error_msg TEXT?           created_at INTEGER    updated_at INTEGER

segments:
  task_id TEXT (FK)         seq INTEGER
  url TEXT                  status INTEGER
  byte_size INTEGER         retry_count INTEGER
  PK(task_id, seq)

settings:
  key TEXT PK               value TEXT
  # concurrency / default_save_dir / theme_mode / merge_preference / ffmpeg_path
```

UI 运行时模型用 freezed（`DownloadTaskUi`：进度百分比、速度格式化），与持久化解耦。

## 5. UI 设计

### 5.1 导航

- `adaptive_shell`：宽度 ≥720 用 `NavigationRail`（≥1000 extended），否则底部 `NavigationBar`
- 目的地：下载中 / 历史记录 / 设置；新建下载为 FAB（移动）/ 工具栏按钮（桌面）
- 路由：`/downloads` `/history` `/settings` `/new` `/player/:taskId`

### 5.2 页面

| 页面 | 关键组件 |
|---|---|
| 新建下载 | URL TextField + 校验；可折叠高级选项（请求头 KV 编辑器、KEY/IV hex 输入）；解析按钮 |
| 解析预览 | preview_card（分片数/时长/加密徽章/估算大小）；variant_picker（清晰度单选）；保存目录选择；确认按钮 |
| 下载管理 | task_card 列表：状态 Chip、LinearProgressIndicator、分片进度、速度、剩余时间；暂停/恢复/取消/重试按钮 |
| 历史记录 | history_tile：状态图标、时间、大小；菜单：播放/重新下载/打开目录/删除 |
| 播放 | media_kit Video + 自绘控制条（播放/暂停、拖动、音量、全屏）；桌面键盘快捷键 |
| 设置 | 并发数 Slider、保存目录、主题 SegmentedButton、合并偏好、ffmpeg 路径与探测状态、关于 |

### 5.3 Material 3

- `ColorScheme.fromSeed`、`useMaterial3: true`
- 组件：Card.filled、Chip、SegmentedButton、NavigationBar/Rail、FAB、Snackbar
- 亮/暗/跟随系统三态主题

## 6. 平台适配

| 平台 | 策略 |
|---|---|
| Android | minSdk 24；保存到 `getExternalStorageDirectory()`（免运行时权限）；`INTERNET` 权限 |
| iOS | 沙盒 `getApplicationDocumentsDirectory()`；Info.plist 开 `UIFileSharingEnabled` + `LSSupportsOpeningDocumentsInPlace`；退后台自动落盘，回前台 restore；UI 提示保持前台 |
| macOS | 沙盒 entitlement：`network.client` + `files.user-selected.read-write`；ffmpeg 多路径探测 |
| Windows | 无沙盒；默认保存至"视频"文件夹；窗口最小 960×600；规避长路径 |
| 通用 | "打开所在目录"：macOS `open -R` / Windows `explorer /select,`；移动端隐藏该项 |

## 7. 错误处理

- 网络错误：分片级 3 次指数退避（1s/3s/9s）；任务级失败保留已完成分片
- 解析错误：明确提示（404/403/非 m3u8 内容）
- 解密错误：KEY 拉取失败/长度不合法时任务失败并提示
- 合并错误：remux 失败回退 .ts；拼接失败任务置 failed
- 全部错误经 `errorOccurred` 事件 → SnackBar/任务卡片展示

## 8. 测试策略

- 单测（纯 Dart）：m3u8_parser（≥5 组样本）、aes_decryptor（与 openssl 对照）、ts_merger（逐字节比对）、状态机迁移表、调度器
- 集成：引擎端到端（本地 HTTP server 提供模拟 m3u8 + 分片）
- 手动回归：四平台按 requirements 验收准则逐条执行
