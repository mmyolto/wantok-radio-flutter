import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'config/app_config.dart';

/// Firebase settings for the station's project (`wantok-radio-light-81519`).
///
/// Push notifications start working once the Android and iOS apps are
/// registered in Firebase and their App IDs are filled in below — see
/// docs/PUSH_NOTIFICATIONS.md. Until then the app runs normally and the
/// reminder switches are simply hidden.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static const String _messagingSenderId = '953977170930';

  /// Browser key created by Firebase (Project settings → General → Web API Key).
  static const String _apiKey = 'AIzaSyBuNp4RqyJlhmcH5jpGhWRDLJEEgErCl6Y';

  // ---------------------------------------------------------------------------
  // Fill these in from Firebase Console → Project settings → Your apps.
  // ---------------------------------------------------------------------------

  /// Android app `org.wantokradiolight.www`: "App ID", e.g.
  /// '1:953977170930:android:0123456789abcdef'.
  static const String androidAppId = '1:953977170930:android:e143ec5787eac062b9996b';

  /// Optional: the Android "current_key" from google-services.json. Leave empty
  /// to use the Web API Key above.
  static const String androidApiKey = '';

  /// iOS app `org.wantokradiolight.www`: "App ID", e.g.
  /// '1:953977170930:ios:0123456789abcdef'.
  static const String iosAppId = '';

  /// Optional: API_KEY from GoogleService-Info.plist.
  static const String iosApiKey = '';

  /// Options for the current platform, or `null` when it isn't set up yet.
  static FirebaseOptions? get currentPlatform {
    if (kIsWeb) return null;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        if (androidAppId.isEmpty) return null;
        return const FirebaseOptions(
          apiKey: androidApiKey == '' ? _apiKey : androidApiKey,
          appId: androidAppId,
          messagingSenderId: _messagingSenderId,
          projectId: AppConfig.firebaseProjectId,
        );
      case TargetPlatform.iOS:
        if (iosAppId.isEmpty) return null;
        return const FirebaseOptions(
          apiKey: iosApiKey == '' ? _apiKey : iosApiKey,
          appId: iosAppId,
          messagingSenderId: _messagingSenderId,
          projectId: AppConfig.firebaseProjectId,
          iosBundleId: AppConfig.androidPackageId,
        );
      default:
        return null;
    }
  }
}
