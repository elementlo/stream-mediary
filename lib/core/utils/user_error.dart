import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../../engine/m3u8/m3u8_parser.dart';
import '../l10n/app_localizations.dart';

final Logger _errorLog = Logger('UserOperation');

void logUserError(String operation, Object error, StackTrace stackTrace) {
  _errorLog.severe(operation, error, stackTrace);
}

/// Turns technical failures into short, actionable messages for the UI.
/// The original exception and stack trace belong in logs only.
String userErrorMessage(Object error, AppLocalizations l10n) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status == 401 || status == 403) return l10n.errorAccessDenied;
    if (status == 404 || status == 410) return l10n.errorMediaMissing;
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return l10n.errorNetwork;
    }
    return l10n.errorServer;
  }
  if (error is SocketException) return l10n.errorNetwork;
  if (error is FileSystemException) return l10n.errorStorage;
  if (error is M3u8ParseException) {
    final message = error.message.toLowerCase();
    if (message.contains('live recording')) return l10n.errorLiveMedia;
    if (message.contains('drm') || message.contains('encryption')) {
      return l10n.errorProtectedMedia;
    }
    if (message.contains('not supported') || message.contains('unsupported')) {
      return l10n.errorUnsupportedMedia;
    }
    return l10n.errorInvalidMedia;
  }
  if (error is FormatException) return l10n.errorInvalidMedia;
  return l10n.errorTryAgain;
}
