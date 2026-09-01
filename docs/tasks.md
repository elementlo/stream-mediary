# stream-mediary 任务分解（Tasks）

> SDD 第三层文档。将设计与需求分解为可独立执行、可验收的开发任务。
> 上游文档：[requirements.md](./requirements.md) ｜ [design.md](./design.md)

## 任务依赖图

```
T0 环境 ─→ T1 脚手架 ─→ T2 解析引擎 ─→ T3 下载引擎 ─→ T4 解密 ─→ T5 合并
                │              │              │                        │
                └→ 主题/导航    └→ 预览页       └→ 下载管理页             └→ 历史/播放 → 设置打磨 → 打包
```

## T0 环境与工程初始化
- [ ] 安装 Flutter 稳定版，`flutter doctor` 通过
- [ ] 启用 android/ios/windows/macos 平台支持
- [ ] `flutter create` 生成工程，配置 app 名称与组织
- [ ] 初始提交
- **验收**：`flutter run -d macos` 启动默认页

## T1 应用脚手架
- [ ] 接入依赖：riverpod、go_router、dio、pointycastle、drift、media_kit、file_selector、permission_handler、window_manager、freezed、intl
- [ ] M3 主题（seed 色、亮/暗/跟随系统）
- [ ] 自适应导航壳（≥720 NavigationRail / 否则 NavigationBar）
- [ ] go_router 路由骨架（5 条路由）
- [ ] drift 数据库（tasks/segments/settings 三表）+ repositories
- [ ] Riverpod providers 骨架
- **验收**：四平台编译通过；窄宽窗口导航切换；DB 读写单测通过
- **依赖**：T0

## T2 M3U8 解析引擎与预览
- [ ] `playlist.dart` 数据模型（MasterPlaylist/Variant/MediaPlaylist/Segment/KeyInfo）
- [ ] `attribute_parser.dart` EXT-X-* 属性解析
- [ ] `m3u8_parser.dart`：master 多级、EXT-X-KEY、相对/绝对 URL、EXTINF、DISCONTINUITY 检测
- [ ] 单测：≥5 组真实样本（多级 master、AES-128、key 轮换、相对路径、直播标签）
- [ ] 新建下载页：URL 输入 + 校验、高级选项（请求头编辑器、KEY/IV 输入）
- [ ] 解析预览卡 + 清晰度选择 + 保存目录选择
- **验收**：单测全过；真实地址出预览（AC-1.1~1.5）
- **依赖**：T1

## T3 下载引擎核心
- [ ] `task_state.dart` 状态机 + 迁移表（含单测）
- [ ] `engine_isolate.dart` 常驻 Isolate + 命令/事件协议
- [ ] `download_engine.dart` 主 isolate 门面 + 事件节流
- [ ] `segment_scheduler.dart` 两级并发（任务级 + 分片级信号量）
- [ ] `segment_downloader.dart` dio 流式下载 + 指数退避重试 + .part 原子落盘
- [ ] 断点续传：playlist_snapshot + 重启 restore 扫描
- [ ] 下载管理页：任务卡片、进度/速度、暂停/恢复/取消/重试
- **验收**：100+ 分片下载成功；杀进程续传；控制行为正确（AC-2.1~2.5）
- **依赖**：T2

## T4 AES 解密管道
- [ ] `aes_decryptor.dart` 流式 CBC 解密（128/192/256）+ 末块 PKCS7 去填充
- [ ] key 拉取与缓存（携带自定义头）；缺省 IV = media sequence 大端
- [ ] 自定义 KEY/IV 覆盖逻辑
- [ ] 单测：与 `openssl enc` 对照（128/192/256 × 默认/自定义 IV）
- **验收**：单测全过；真实加密源产物可播放（AC-5 关联）
- **依赖**：T3

## T5 分片合并
- [ ] `ts_merger.dart` 按序流式拼接 + 进度回调
- [ ] `ffmpeg_remuxer.dart` 多路径探测 + 手填路径 + `-c copy` remux + 失败回退
- [ ] 合并进度接入任务卡片
- [ ] 单测：拼接与分片按序内容逐字节一致
- **验收**：有/无 ffmpeg 均产出可播放文件（AC-3.1~3.4）
- **依赖**：T3

## T6 下载历史
- [ ] 历史页列表（完成/失败/取消）
- [ ] 操作：播放、重新下载、打开所在目录（桌面）、删除确认
- **验收**：跨重启持久化；操作正确（AC-4.1~4.4）
- **依赖**：T3

## T7 本地播放
- [ ] media_kit 初始化与播放页
- [ ] 自绘控制条：播放/暂停、进度拖动、时间、音量、全屏
- [ ] 桌面键盘快捷键
- **验收**：.ts/.mp4 可播放可拖动（AC-5.1~5.3）
- **依赖**：T5、T6

## T8 设置与打磨
- [ ] 设置页：并发数、保存目录、主题、合并偏好、ffmpeg 路径、关于
- [ ] 设置端到端生效（引擎 updateSettings 命令）
- [ ] i18n（zh/en）
- [ ] 错误提示、空态、应用图标
- **验收**：AC-6.1~6.3；analyze 0 error；核心单测覆盖 ≥70%
- **依赖**：T1~T7

## T9 打包与验收
- [ ] `flutter build apk` / `ipa` / `macos` / `windows` release 构建
- [ ] 按 requirements 全部验收准则回归
- **验收**：四平台安装包可运行；验收准则 100% 通过
- **依赖**：T8
