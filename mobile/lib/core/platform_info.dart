import 'package:flutter/foundation.dart';

/// Nom d'appareil affiché (web + mobile, sans dart:io).
String deviceDisplayName() {
  if (kIsWeb) {
    return 'Web';
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'Android';
    case TargetPlatform.iOS:
      return 'iOS';
    case TargetPlatform.windows:
      return 'Windows';
    case TargetPlatform.macOS:
      return 'macOS';
    case TargetPlatform.linux:
      return 'Linux';
    case TargetPlatform.fuchsia:
      return 'Fuchsia';
  }
}
