import 'dart:io';

import 'package:flutter/services.dart';

/// Bridges to the Android side for scoped-storage "all files access".
///
/// On Android 11+ writing into arbitrary public directories (e.g. the folder
/// chosen via the system picker) requires MANAGE_EXTERNAL_STORAGE, which can
/// only be granted from the system settings screen. On older versions the
/// legacy WRITE_EXTERNAL_STORAGE runtime permission is requested instead.
///
/// Non-Android platforms always report access as granted.
class StorageAccess {
  StorageAccess._();

  static const _channel = MethodChannel('stream_mediary/storage');

  /// Whether the app can write anywhere on external storage.
  static Future<bool> hasAccess() async {
    if (!Platform.isAndroid) return true;
    try {
      final granted =
          await _channel.invokeMethod<bool>('hasExternalStorageAccess');
      return granted ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Requests the permission. On Android 11+ this opens the system
  /// "all files access" settings screen; the user must grant manually and
  /// return to the app, so callers should re-check [hasAccess] afterwards.
  static Future<bool> requestAccess() async {
    if (!Platform.isAndroid) return true;
    try {
      final granted =
          await _channel.invokeMethod<bool>('requestExternalStorageAccess');
      return granted ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
