import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'app_services.dart';
import 'audio/radio_audio_handler.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Always upright (portrait), on every phone and tablet.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[DeviceOrientation.portraitUp]);
  // Draw behind the status / navigation bars (required look on Android 15+).
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  SystemChrome.setSystemUIOverlayStyle(AppTheme.overlay);

  try {
    radio = await AudioService.init<RadioAudioHandler>(
      builder: () => RadioAudioHandler(nowPlaying: nowPlayingService),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'org.wantokradiolight.www.playback',
        androidNotificationChannelName: 'Radio playback',
        androidNotificationChannelDescription: 'Live stream playback controls',
        androidNotificationIcon: 'drawable/ic_stat_radio',
        notificationColor: AppColors.primary,
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        preloadArtwork: true,
      ),
    );
  } catch (e) {
    // Background service unavailable (should not happen) — still let people
    // listen while the app is open.
    debugPrint('AudioService.init failed: $e');
    radio = RadioAudioHandler(nowPlaying: nowPlayingService);
  }

  runApp(const WantokRadioApp());

  // Daily devotional notifications (no-op until Firebase is set up).
  unawaited(pushService.init());
}
