# Flutter 桌面端截图自动化：官方工具集体缺席，我们是怎么在 CI 里把图截出来的

> 本文记录了给一个 Flutter 六平台项目（Mediary）自动生成 README 产品截图的全过程。剧透：官方提供的两条路在桌面端全部走不通，最后靠的是操作系统级截屏 + GitHub Actions 的隐藏技能。全文约 15 分钟，坑都替你踩完了。

## 一、需求很简单，对吧？

事情是这样的：开源项目的 README 需要产品截图。手动截图的问题人人都懂——UI 一改，图就过期；想覆盖 Android / iOS / macOS / Windows 四个平台，你得凑齐四台设备，还得记得每台设备上截图的正确姿势。

所以目标定得很朴素：

1. **截图必须来自真实运行的 app**（不是设计稿，不是渲染图）
2. **一条命令产出**，最好能进 CI
3. **全平台覆盖**

听起来就是个"写个脚本"的活儿。然后我们花了整整两天。

## 二、移动端：官方方案能用，但有两个暗坑

Flutter 官方给截图准备的方案是 `integration_test` 的 `takeScreenshot()`：测试代码里截，driver 端收，写文件。思路清晰，文档齐全。

### 坑 1：`convertFlutterSurfaceToImage()` 的调用时机

在 Android/iOS 上截图前必须调用它把渲染表面转成可捕获的图像。文档里轻描淡写一句话，但**调用位置错了就是 2 分钟超时死给你看**：

```dart
// ❌ 错误：在 testWidgets 外面调，不 await
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.convertFlutterSurfaceToImage();  // 死锁，测试超时
  testWidgets('...', (tester) async { ... });
}

// ✅ 正确：在测试内部、首帧 pump 之后，await 它
testWidgets('...', (tester) async {
  await tester.pumpWidget(const MyApp());
  await binding.convertFlutterSurfaceToImage();
  await tester.pumpAndSettle();
  final bytes = await binding.takeScreenshot('home');
});
```

这个坑的阴险之处在于：报错是 `TimeoutException`，你第一反应是"页面有动画没 settle"，会去翻自己的 widget 树找 `AnimationController`——方向完全错了。真相藏在 SDK 的示例代码里（`packages/integration_test/example/integration_test/_extended_test_io.dart`），官方示例是对的，文档没强调。

### 坑 2：真机 GPU 不买账

修完时机问题，模拟器上跑通了。兴冲冲插上 Android 真机（联发科芯片），日志里蹦出一串：

```
E/mali_gralloc: ERROR: Unrecognized and/or unsupported format 0x3b and usage 0xb00
```

翻译一下：这块 Mali GPU 的图形分配器不认识 `convertFlutterSurfaceToImage()` 要的缓冲区格式。**这是硬件兼容性问题，代码层面无解**。同一份测试代码，模拟器好好的，真机就是截不出来。

### 移动端的最终答案：别跟框架较劲，用系统工具

既然 app 能正常跑起来，那直接让操作系统截屏不就完了？

```bash
# Android：启动 app，等首帧，screencap
flutter run -d <device> --debug &
adb -s <device> shell screencap -p /sdcard/s.png
adb -s <device> pull /sdcard/s.png docs/screenshots/android-home.png

# iOS 模拟器：simctl 自带截屏
xcrun simctl io <simulator-id> screenshot docs/screenshots/ios-home.png
```

土吗？土。可靠吗？非常可靠。截出来的是**像素级真实的屏幕内容**，连状态栏时间都是真的（后处理裁掉即可）。

一个实用细节：怎么知道 app 启动完成了？轮询 `flutter run` 的输出，等 `Flutter run key commands` 这行出现，再 sleep 几秒让首帧渲染完。比固定 sleep 30 秒优雅，也比截图截到启动屏强。

## 三、桌面端：官方工具直接摆烂

移动端好歹是"有方案但有坑"，桌面端是**压根没有方案**。

### `integration_test`？不支持桌面

`takeScreenshot()` 的实现依赖移动端的 surface 转换机制，桌面端没有对应实现。

### `flutter screenshot`？想得美

Flutter CLI 有个 `flutter screenshot` 命令，看起来就是干这个的。在 macOS 上运行：

```
Screenshot not supported for macOS.
```

一句话，没有解释，没有 workaround，没有 issue 链接。它支持移动端和 Web，桌面端就是不支持。你品，你细品：**官方 CLI 里那个叫 screenshot 的命令，不支持你的桌面应用截图**。

### 那就只能 OS 级截屏了——但每个系统都有自己的脾气

#### macOS：窗口在哪，你得先问

macOS 有 `screencapture -R x,y,w,h` 可以截指定区域。问题是：app 窗口的位置是系统随机放的，你得先把它挪到已知坐标：

```bash
# 启动 app 后，用 AppleScript 把窗口摆好
osascript -e 'tell application "System Events" to tell process "Mediary"
  set frontmost to true
  set position of window 1 to {100, 100}
  set size of window 1 to {1120, 720}
end tell'
sleep 3
screencapture -x -R100,100,1120,720 docs/screenshots/macos-home.png
```

这里有个我们踩过的坑：**先读窗口 bounds 再截**看似更通用，但窗口移动后 Flutter 需要时间重新渲染，立刻截会得到一块黑。所以正确姿势是"先摆窗口 → 等几秒 → 按摆好的坐标截"，确定性拉满。

#### Windows：三个坑连环套

Windows 没有 `screencapture` 这种一行命令，得用 PowerShell + Win32 API。我们写了个脚本，然后被现实教育了三轮。

**坑 1：任务栏入镜。** 把窗口设成 1280×800，截图里底部多了条任务栏——因为 800 超出了屏幕**工作区**（work area，即去掉任务栏的可用区域），窗口被任务栏压住了。修复：用 `Screen.PrimaryScreen.WorkingArea` 限制窗口尺寸。

**坑 2：PrintWindow 的黑边。** 有人会说：截什么屏幕，用 `PrintWindow` API 直接抓窗口位图啊，不受遮挡影响。试了，窗口四周多了一圈黑边。原因是 `GetWindowRect` 返回的矩形**包含 DWM 的不可见阴影边框**（约 8px），这部分区域在窗口位图里没有内容，渲染成黑色。

正确做法是问 DWM 要**可见边框**：

```csharp
// DWMWA_EXTENDED_FRAME_BOUNDS = 9
[DllImport("dwmapi.dll")]
public static extern int DwmGetWindowAttribute(
    IntPtr hWnd, int attr, out RECT rect, int size);
```

**坑 3：黑帧检测的阈值。** 为了兜底，我们写了"如果截图中心像素接近纯黑就换另一种截法"的逻辑，阈值设了 RGB < 25。然后 app 的暗色主题背景是 `(19, 21, 24)`——被误判成黑帧。教训：**给暗色主题 app 写黑屏检测，阈值得贴着 0 设**（< 5），或者干脆检测多个采样点的方差。

最终 Windows 方案：`MoveWindow` 摆到 (0,0)、尺寸取工作区、`DwmGetWindowAttribute` 拿可见边框、`CopyFromScreen` 截该区域、`PrintWindow` 做锁屏兜底。

## 四、终极形态：让 GitHub Actions 替你开 Windows

到这里还剩最后一个问题：脚本写好了，但 **macOS 脚本只能在 Mac 上跑，Windows 脚本只能在 Windows 上跑**。作为一个在 Mac 上开发的人，每次更新 Windows 截图都要找一台 Windows 电脑，等于没自动化。

Docker 行不行？不行，两条路都堵死：

- Mac 上的 Docker 跑的是 Linux 容器，没有 MSVC 工具链，编译不了 Windows 目标
- Windows 容器（Server Core）**没有图形桌面会话**，GUI app 无法渲染，更别提截屏

但你其实有一台随叫随到的 Windows 机器：**GitHub Actions 的 `windows-latest` runner**。公开仓库免费，而且它带真实桌面会话（能跑 GUI！）。于是有了这个 workflow：

```yaml
jobs:
  capture-windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter build windows --release
      - name: Launch app and capture window screenshot
        shell: pwsh
        run: |
          Start-Process "build\windows\x64\runner\Release\Mediary.exe"
          # 轮询等窗口出现 → 摆位置 → DWM 边框 → CopyFromScreen
          ...
      - name: Commit screenshot back to repo
        run: |
          git config user.name "github-actions[bot]"
          git add docs/screenshots/windows-home.png
          git commit -m "docs: update Windows home screenshot [skip ci]"
          git push
```

注意最后一步：**截图直接 commit 回仓库**。在 Actions 页面点一下（或 `gh workflow run windows-screenshot.yml`），几分钟后 Windows 截图就自己更新了，全程不需要碰任何 Windows 设备。`[skip ci]` 防止提交触发其他 workflow 死循环。

一个小提醒：runner 的桌面会话偶尔会有窗口置前失败的情况，脚本里 `SetForegroundWindow` 之后多等几秒再截，稳定性会好很多。

## 五、另一条路：不运行 app 的"截图"

调研中还发现一类方案：`golden_screenshot` 这类基于 golden test 的包，在 `flutter test` 里离屏渲染 widget，不需要设备、不需要启动 app，一条命令批量产出各尺寸截图，还自带手机/桌面设备外框。

它适合做 UI 回归测试和商店素材批量生成，但**不适合当 README 的产品截图**：golden test 渲染的是宿主机上的软件光栅化结果 + 手绘设备框，不是各平台原生渲染。四张"平台截图"其实是同一份渲染换了个框，macOS 的原生标题栏、Android 的真实状态栏都不存在。对开源项目来说，真实运行截图的说服力完全不同。

我们的结论：**README 用真实截图（本文方案），UI 回归用 golden test**，两者互补。

## 六、踩坑清单（太长不看版）

| # | 坑 | 解法 |
|---|---|---|
| 1 | `convertFlutterSurfaceToImage()` 在测试外调用 → 超时死锁 | 测试内、首帧后、await |
| 2 | 部分真机 GPU（Mali）不支持 surface 转换 | 放弃框架截图，用 `adb screencap` / `simctl io screenshot` |
| 3 | `flutter screenshot` 不支持桌面端 | OS 级截屏 |
| 4 | macOS 窗口位置随机 | AppleScript 先摆窗口，等渲染，再按固定坐标截 |
| 5 | Windows 任务栏入镜 | 窗口尺寸限制在 WorkingArea 内 |
| 6 | `GetWindowRect` 含 DWM 阴影 → 黑边 | `DwmGetWindowAttribute(DWMWA_EXTENDED_FRAME_BOUNDS)` |
| 7 | 黑帧检测误伤暗色主题 | 阈值贴 0（RGB < 5），别用 25 |
| 8 | 没有 Windows 电脑跑脚本 | GitHub Actions `windows-latest` 有真实桌面会话，截完自动 commit 回仓库 |
| 9 | Docker 替代 Windows？ | 不行：Linux 容器编不了 Windows，Windows 容器没有 GUI 会话 |

## 七、写在最后

这件事最大的感触是：Flutter 的桌面端生态还在"能跑"和"好用"之间。一个 `flutter screenshot` 命令，名字起得信心满满，桌面端直接一句 not supported 打发。但换个角度，操作系统几十年来早就把截屏这件事做得明明白白——**框架不给的，找系统要；本地没有的，找 CI 借**。

所有脚本都在仓库里，欢迎抄作业：

- 桌面截图脚本：`tool/screenshot_desktop.sh`
- Windows CI 截图 workflow：`.github/workflows/windows-screenshot.yml`
- 移动端截图测试：`integration_test/screenshot_test.dart`

项目地址：[elementlo/stream-mediary](https://github.com/elementlo/stream-mediary) —— 一个用 Flutter 写的六平台 m3u8/HLS 下载器。如果这篇文章帮你省了两小时，去点个 star 呗。
