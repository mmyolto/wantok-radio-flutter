import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// What is on air right now, from the station's AzuraCast server.
@immutable
class NowPlaying {
  const NowPlaying({
    this.title,
    this.artist,
    this.artUrl,
    this.isLive = false,
    this.streamerName,
    this.listeners,
    this.streamUrls = const <String>[],
  });

  final String? title;
  final String? artist;
  final String? artUrl;
  final bool isLive;
  final String? streamerName;
  final int? listeners;

  /// Listen URLs reported by the server (https), best first.
  final List<String> streamUrls;

  bool get hasSong => (title ?? '').trim().isNotEmpty;

  /// "Title — Artist", or whichever part exists.
  String get display {
    final String t = (title ?? '').trim();
    final String a = (artist ?? '').trim();
    if (t.isNotEmpty && a.isNotEmpty) return '$t — $a';
    return t.isNotEmpty ? t : a;
  }

  static NowPlaying? fromAzuraCast(Map<String, dynamic> json) {
    final Map<String, dynamic> station = _map(json['station']);
    final Map<String, dynamic> np = _map(json['now_playing']);
    final Map<String, dynamic> song = _map(np['song']);
    final Map<String, dynamic> live = _map(json['live']);
    final Map<String, dynamic> listeners = _map(json['listeners']);

    String? title = _str(song['title']);
    final String? artist = _str(song['artist']);
    if ((title == null || title.isEmpty) && _str(song['text']) != null) {
      title = _str(song['text']);
    }

    String? art = _str(song['art']);
    // AzuraCast returns a generic placeholder when a track has no artwork.
    if (art != null && (art.contains('/default') || !art.startsWith('http'))) {
      art = null;
    }
    if (art != null && art.startsWith('http:')) {
      art = art.replaceFirst('http:', 'https:');
    }

    final List<String> urls = <String>[];
    final String? listenUrl = _str(station['listen_url']);
    if (listenUrl != null) urls.add(listenUrl);
    final Object? mounts = station['mounts'];
    if (mounts is List) {
      for (final Object? m in mounts) {
        final String? u = _str(_map(m)['url']);
        if (u != null) urls.add(u);
      }
    }

    return NowPlaying(
      title: title,
      artist: artist,
      artUrl: art,
      isLive: live['is_live'] == true,
      streamerName: _str(live['streamer_name']),
      listeners: listeners['current'] is num ? (listeners['current'] as num).toInt() : null,
      streamUrls: urls
          .where((String u) => u.startsWith('http'))
          .map((String u) => u.replaceFirst(RegExp(r'^http:'), 'https:'))
          .toSet()
          .toList(),
    );
  }

  static Map<String, dynamic> _map(Object? v) =>
      v is Map<String, dynamic> ? v : const <String, dynamic>{};

  static String? _str(Object? v) {
    if (v is! String) return null;
    final String s = v.trim();
    return s.isEmpty ? null : s;
  }

  @override
  bool operator ==(Object other) =>
      other is NowPlaying &&
      other.title == title &&
      other.artist == artist &&
      other.artUrl == artUrl &&
      other.isLive == isLive &&
      other.streamerName == streamerName;

  @override
  int get hashCode => Object.hash(title, artist, artUrl, isLive, streamerName);
}

/// Polls the "now playing" API while someone is interested (app open or
/// radio playing). Failures are silent — the app simply shows the station name.
class NowPlayingService {
  NowPlayingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final ValueNotifier<NowPlaying?> current = ValueNotifier<NowPlaying?>(null);

  Timer? _timer;
  int _interest = 0;
  bool _fetching = false;

  /// Call when something starts needing the data; pair with [release].
  void acquire() {
    _interest++;
    if (_interest == 1) {
      unawaited(refresh());
      _timer = Timer.periodic(AppConfig.nowPlayingRefresh, (_) => refresh());
    }
  }

  bool _forPlayback = false;

  /// Keeps polling while the radio is playing (idempotent).
  void acquireForPlayback() {
    if (_forPlayback) return;
    _forPlayback = true;
    acquire();
  }

  void releaseForPlayback() {
    if (!_forPlayback) return;
    _forPlayback = false;
    release();
  }

  void release() {
    if (_interest == 0) return;
    _interest--;
    if (_interest == 0) {
      _timer?.cancel();
      _timer = null;
    }
  }

  Future<void> refresh() async {
    if (_fetching) return;
    _fetching = true;
    try {
      final http.Response res = await _client
          .get(
            Uri.parse(AppConfig.nowPlayingApiUrl),
            headers: const <String, String>{'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final Object? decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          final NowPlaying? np = NowPlaying.fromAzuraCast(decoded);
          if (np != null && np != current.value) current.value = np;
        }
      }
    } catch (_) {
      // Network or parse problem — keep whatever we had.
    } finally {
      _fetching = false;
    }
  }

  void dispose() {
    _timer?.cancel();
    current.dispose();
    _client.close();
  }
}
