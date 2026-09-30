/// Shared helper for routing a Dio instance through an HTTP proxy.
///
/// Pure Dart (no Flutter dependency) so both the download engine and the
/// in-app update service can reuse the exact same proxy semantics.
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Normalizes a proxy host/port pair into a `host:port` string, or null when
/// no proxy is configured. Mirrors `EngineConfig.hasProxy`: a blank host means
/// "direct connection"; the port defaults to 8080 when omitted.
String? normalizeProxy(String? host, int? port) {
  final trimmed = host?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  return '$trimmed:${port ?? 8080}';
}

/// Replaces [dio]'s HTTP adapter so all of its traffic goes through [proxy]
/// (`host:port`), or restores a direct connection when [proxy] is null.
///
/// The old adapter is closed (non-force) so in-flight requests finish on their
/// existing connections. Callers that want to skip redundant rebuilds should
/// compare [proxy] against their own last-applied value before calling.
void applyDioProxy(Dio dio, String? proxy) {
  final previous = dio.httpClientAdapter;
  dio.httpClientAdapter = proxy == null
      ? IOHttpClientAdapter()
      : IOHttpClientAdapter(
          createHttpClient: () => HttpClient()..findProxy = (_) => 'PROXY $proxy',
        );
  previous.close();
}
