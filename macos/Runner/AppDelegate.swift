import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var pendingLink: String?
  private var deepLinkChannel: FlutterMethodChannel?
  private var flutterReady = false

  func configureDeepLinkChannel(messenger: FlutterBinaryMessenger) {
    guard deepLinkChannel == nil else { return }
    let channel = FlutterMethodChannel(
      name: "stream_mediary/deep_link",
      binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "getInitialLink" {
        result(self?.pendingLink)
        self?.pendingLink = nil
        self?.flutterReady = true
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    deepLinkChannel = channel
  }

  override func application(_ application: NSApplication, open urls: [URL]) {
    for url in urls where url.scheme == "stream-mediary" {
      if flutterReady, let channel = deepLinkChannel {
        channel.invokeMethod("onOpenLink", arguments: url.absoluteString)
      } else {
        pendingLink = url.absoluteString
      }
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
