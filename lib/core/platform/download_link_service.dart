import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DownloadLink {
  const DownloadLink({required this.url, this.referer, this.userAgent});

  final String url;
  final String? referer;
  final String? userAgent;

  Map<String, String> get headers => {
    if (referer != null && referer!.isNotEmpty) 'Referer': referer!,
    if (userAgent != null && userAgent!.isNotEmpty) 'User-Agent': userAgent!,
  };

  static DownloadLink? parse(String raw) {
    if (raw.length > 16384) return null;
    final link = Uri.tryParse(raw);
    if (link == null ||
        link.scheme != 'stream-mediary' ||
        link.host != 'download') {
      return null;
    }
    final rawUrl = link.queryParameters['url'];
    if (rawUrl == null) return null;
    final url = Uri.tryParse(rawUrl);
    if (url == null ||
        !url.hasAuthority ||
        !(url.isScheme('https') || url.isScheme('http'))) {
      return null;
    }
    final referer = link.queryParameters['referer'];
    final refererUri = referer == null ? null : Uri.tryParse(referer);
    return DownloadLink(
      url: rawUrl,
      referer:
          refererUri != null &&
              (refererUri.isScheme('http') || refererUri.isScheme('https'))
          ? referer
          : null,
      userAgent: link.queryParameters['userAgent'],
    );
  }
}

/// Receives OS custom-protocol launches. Windows starts a new process with
/// the URL as an argument; macOS sends the URL to the running app.
class DownloadLinkService extends ValueNotifier<DownloadLink?> {
  DownloadLinkService._() : super(null);

  static final instance = DownloadLinkService._();
  static const _channel = MethodChannel('stream_mediary/deep_link');

  Future<void> initialize({List<String> arguments = const []}) async {
    if (Platform.isWindows) {
      for (final argument in arguments) {
        final parsed = DownloadLink.parse(argument);
        if (parsed != null) value = parsed;
      }
    }
    if (Platform.isMacOS) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onOpenLink' && call.arguments is String) {
          final parsed = DownloadLink.parse(call.arguments as String);
          if (parsed != null) value = parsed;
        }
      });
      String? initial;
      try {
        initial = await _channel.invokeMethod<String>('getInitialLink');
      } on MissingPluginException {
        // A missing native bridge must not prevent the app from rendering.
      }
      if (initial != null) {
        final parsed = DownloadLink.parse(initial);
        if (parsed != null) value = parsed;
      }
    }
  }
}
