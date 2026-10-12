import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';
import '../services/now_playing_service.dart';

/// High-level state the UI cares about.
enum RadioStatus { stopped, connecting, playing, paused, reconnecting, offline, error }

/// Live-radio audio handler.
///
/// * Plays in the background with lock-screen / notification / headset /
///   Bluetooth controls (via audio_service).
/// * Always rejoins the *live* broadcast when resumed.
/// * Falls back to backup streams, retries with back-off, and reconnects by
///   itself when the internet comes back.
/// * Pauses for phone calls and other apps, ducks for navigation prompts,
///   and stops when headphones are unplugged.
class RadioAudioHandler extends BaseAudioHandler {
  RadioAudioHandler({required this.nowPlaying}) {
    _init();
  }

  final NowPlayingService nowPlaying;

  final AudioPlayer _player = AudioPlayer(
    handleInterruptions: false, // handled below so a live stream rejoins live
    userAgent: 'WantokRadioLight/1.0 (Flutter)',
  );

  /// Status for the UI (more detailed than [playbackState]).
  final ValueNotifier<RadioStatus> status = ValueNotifier<RadioStatus>(RadioStatus.stopped);

  /// Last error shown to the user, if any.
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);

  /// When the sleep timer will stop playback (null = off).
  final ValueNotifier<DateTime?> sleepAt = ValueNotifier<DateTime?>(null);

  static const List<Duration> _retryDelays = <Duration>[
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 15),
    Duration(seconds: 30),
  ];

  bool _active = false; // user wants audio
  bool _paused = false; // paused from notification / interruption
  bool _resumeAfterInterruption = false;
  bool _online = true;
  int _streamIndex = 0;
  int _retry = 0;
  int _loadToken = 0;
  int _failedToken = -1; // stops one failure being handled twice
  Timer? _retryTimer;
  Timer? _sleepTimer;
  Uri? _stationArtUri;
  String? _icyTitle;
  List<String> _streams = <String>[AppConfig.primaryStreamUrl, ...AppConfig.fallbackStreamUrls];
  final List<StreamSubscription<dynamic>> _subs = <StreamSubscription<dynamic>>[];

  MediaItem get _baseItem => MediaItem(
    id: 'wantok-radio-light-live',
    title: AppConfig.appName,
    artist: AppConfig.tagline,
    album: AppConfig.network,
    artUri: _stationArtUri,
    isLive: true,
    playable: true,
  );

  // ---------------------------------------------------------------------------
  // Setup
  // ---------------------------------------------------------------------------

  Future<void> _init() async {
    mediaItem.add(_baseItem);
    _broadcast();

    try {
      final AudioSession session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      _subs.add(session.interruptionEventStream.listen(_onInterruption));
      _subs.add(session.becomingNoisyEventStream.listen((_) => pause()));
    } catch (e) {
      debugPrint('Audio session setup failed: $e');
    }

    _subs.add(_player.playerStateStream.listen((_) => _onPlayerChanged()));
    _subs.add(
      _player.playbackEventStream.listen(
        (_) {},
        onError: (Object e, StackTrace st) => _onStreamFailure(e),
      ),
    );
    _subs.add(
      _player.icyMetadataStream.listen((IcyMetadata? icy) {
        final String? t = icy?.info?.title?.trim();
        _icyTitle = (t == null || t.isEmpty) ? null : t;
        _updateMetadata();
      }),
    );

    nowPlaying.current.addListener(_onNowPlaying);

    final Connectivity connectivity = Connectivity();
    try {
      _online = _hasNetwork(await connectivity.checkConnectivity());
    } catch (_) {
      _online = true;
    }
    _subs.add(connectivity.onConnectivityChanged.listen(_onConnectivity));

    unawaited(_prepareStationArt());
  }

  /// Copies the station artwork out of the app bundle so the notification and
  /// lock screen can show it.
  Future<void> _prepareStationArt() async {
    try {
      final Directory dir = await getApplicationSupportDirectory();
      final File file = File('${dir.path}/station_artwork.png');
      final ByteData data = await rootBundle.load('assets/images/station_artwork.png');
      // Rewrite when missing or when an app update changed the artwork.
      if (!await file.exists() || await file.length() != data.lengthInBytes) {
        await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      }
      _stationArtUri = Uri.file(file.path);
      _updateMetadata();
    } catch (e) {
      debugPrint('Could not prepare station artwork: $e');
    }
  }

  static bool _hasNetwork(List<ConnectivityResult> r) =>
      r.isNotEmpty && !r.every((ConnectivityResult c) => c == ConnectivityResult.none);

  // ---------------------------------------------------------------------------
  // Public controls (also called from notification, lock screen, headset…)
  // ---------------------------------------------------------------------------

  bool get isActive => _active && !_paused;

  @override
  Future<void> play() async {
    errorMessage.value = null;
    _active = true;
    _paused = false;
    _resumeAfterInterruption = false;
    _retry = 0;
    _streamIndex = 0;
    nowPlaying.acquireForPlayback();
    if (!_online) {
      // Re-check: connectivity streams can lag behind reality.
      try {
        _online = _hasNetwork(await Connectivity().checkConnectivity());
      } catch (_) {}
    }
    if (!_online) {
      _setStatus(RadioStatus.offline);
      return;
    }
    await _connect();
  }

  /// Pausing a live stream disconnects (saves data); resuming rejoins live.
  @override
  Future<void> pause() async {
    if (!_active) return;
    _paused = true;
    _cancelRetry();
    _loadToken++;
    await _player.stop();
    _setStatus(RadioStatus.paused);
  }

  @override
  Future<void> stop() async {
    _active = false;
    _paused = false;
    _resumeAfterInterruption = false;
    _cancelRetry();
    _loadToken++;
    // Stopping by hand also cancels a pending sleep timer.
    _sleepTimer?.cancel();
    _sleepTimer = null;
    sleepAt.value = null;
    nowPlaying.releaseForPlayback();
    await _player.stop();
    _setStatus(RadioStatus.stopped);
    await super.stop();
  }

  @override
  Future<void> click([MediaButton button = MediaButton.media]) async {
    // Single headset / Bluetooth button press toggles play.
    if (isActive) {
      await pause();
    } else {
      await play();
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    // App swiped away from recents on Android: stop if not playing.
    if (!isActive) await stop();
  }

  @override
  Future<void> onNotificationDeleted() => stop();

  /// Stops playback after [after]; pass null to cancel.
  void setSleepTimer(Duration? after) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    if (after == null) {
      sleepAt.value = null;
      return;
    }
    sleepAt.value = DateTime.now().add(after);
    _sleepTimer = Timer(after, () {
      sleepAt.value = null;
      stop();
    });
  }

  // ---------------------------------------------------------------------------
  // Connection handling
  // ---------------------------------------------------------------------------

  Future<void> _connect() async {
    _cancelRetry();
    final int token = ++_loadToken;
    _setStatus(
      _retry == 0 && _streamIndex == 0 ? RadioStatus.connecting : RadioStatus.reconnecting,
    );
    final String url = _streams[_streamIndex % _streams.length];
    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(url)), preload: true);
      if (token != _loadToken || !_active || _paused) return;
      unawaited(_player.play().catchError(_onStreamFailure));
    } on PlayerInterruptedException {
      // A newer request replaced this one — nothing to do.
    } catch (e) {
      if (token == _loadToken) _onStreamFailure(e);
    }
  }

  void _onStreamFailure(Object error) {
    if (!_active || _paused) return;
    // A failed load is reported both by the awaited call and the event stream.
    if (_failedToken == _loadToken) return;
    _failedToken = _loadToken;
    debugPrint('Stream failure: $error');
    _cancelRetry();
    _loadToken++;

    if (!_online) {
      _setStatus(RadioStatus.offline);
      return; // _onConnectivity resumes when the network returns
    }

    // Try the next backup stream straight away.
    if (_streamIndex < _streams.length - 1) {
      _streamIndex++;
      unawaited(_connect());
      return;
    }

    if (_retry < _retryDelays.length) {
      final Duration wait = _retryDelays[_retry];
      _retry++;
      _streamIndex = 0;
      _setStatus(RadioStatus.reconnecting);
      _retryTimer = Timer(wait, () {
        if (_active && !_paused) _connect();
      });
      return;
    }

    _active = false;
    nowPlaying.releaseForPlayback();
    unawaited(_player.stop());
    errorMessage.value =
        'We could not reach the live stream. Please check your connection and try again.';
    _setStatus(RadioStatus.error);
  }

  void _onPlayerChanged() {
    if (!_active || _paused) return;
    final PlayerState s = _player.playerState;
    switch (s.processingState) {
      case ProcessingState.loading:
      case ProcessingState.buffering:
        if (status.value != RadioStatus.reconnecting) {
          _setStatus(
            status.value == RadioStatus.playing ? RadioStatus.reconnecting : RadioStatus.connecting,
          );
        }
      case ProcessingState.ready:
        if (s.playing) {
          _retry = 0;
          errorMessage.value = null;
          _setStatus(RadioStatus.playing);
        }
      case ProcessingState.completed:
        // A live stream should never "finish" — the connection dropped.
        _onStreamFailure(StateError('Stream ended'));
      case ProcessingState.idle:
        break;
    }
  }

  void _onConnectivity(List<ConnectivityResult> result) {
    final bool wasOnline = _online;
    _online = _hasNetwork(result);
    if (!_online && _active && !_paused) {
      _setStatus(RadioStatus.offline);
    }
    if (_online && !wasOnline && _active && !_paused) {
      _retry = 0;
      _streamIndex = 0;
      // Give the new connection a moment to settle.
      _cancelRetry();
      _retryTimer = Timer(const Duration(milliseconds: 800), _connect);
    }
  }

  void _onInterruption(AudioInterruptionEvent event) {
    if (event.begin) {
      switch (event.type) {
        case AudioInterruptionType.duck:
          if (_player.playing) _player.setVolume(0.3);
        case AudioInterruptionType.pause:
        case AudioInterruptionType.unknown:
          if (isActive) {
            _resumeAfterInterruption = event.type == AudioInterruptionType.pause;
            pause();
          }
      }
    } else {
      switch (event.type) {
        case AudioInterruptionType.duck:
          _player.setVolume(1.0);
        case AudioInterruptionType.pause:
          if (_resumeAfterInterruption && _active && _paused) play();
          _resumeAfterInterruption = false;
        case AudioInterruptionType.unknown:
          _resumeAfterInterruption = false;
      }
    }
  }

  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  // ---------------------------------------------------------------------------
  // Metadata
  // ---------------------------------------------------------------------------

  void _onNowPlaying() {
    final NowPlaying? np = nowPlaying.current.value;
    if (np != null && np.streamUrls.isNotEmpty) {
      final List<String> merged = <String>{
        AppConfig.primaryStreamUrl,
        ...np.streamUrls,
        ...AppConfig.fallbackStreamUrls,
      }.toList();
      if (!listEquals(merged, _streams)) _streams = merged;
    }
    _updateMetadata();
  }

  void _updateMetadata() {
    final NowPlaying? np = nowPlaying.current.value;
    final String? icy = _icyTitle;
    MediaItem item = _baseItem;
    if (np != null && np.hasSong) {
      item = item.copyWith(
        title: np.title!,
        artist: (np.artist ?? '').isNotEmpty ? np.artist : AppConfig.appName,
        album: AppConfig.appName,
        artUri: np.artUrl != null ? Uri.parse(np.artUrl!) : _stationArtUri,
      );
    } else if (icy != null) {
      item = item.copyWith(title: icy, artist: AppConfig.appName);
    }
    // MediaItem equality only compares ids, so compare what is shown.
    final MediaItem? old = mediaItem.value;
    if (old == null ||
        old.title != item.title ||
        old.artist != item.artist ||
        old.album != item.album ||
        old.artUri != item.artUri) {
      mediaItem.add(item);
    }
  }

  // ---------------------------------------------------------------------------
  // State broadcasting
  // ---------------------------------------------------------------------------

  void _setStatus(RadioStatus s) {
    status.value = s;
    _broadcast();
  }

  void _broadcast() {
    final RadioStatus s = status.value;
    final bool playing =
        s == RadioStatus.playing ||
        s == RadioStatus.connecting ||
        s == RadioStatus.reconnecting ||
        s == RadioStatus.offline;

    final AudioProcessingState processing;
    switch (s) {
      case RadioStatus.stopped:
        processing = AudioProcessingState.idle;
      case RadioStatus.connecting:
        processing = AudioProcessingState.loading;
      case RadioStatus.reconnecting:
      case RadioStatus.offline:
        processing = AudioProcessingState.buffering;
      case RadioStatus.playing:
      case RadioStatus.paused:
        processing = AudioProcessingState.ready;
      case RadioStatus.error:
        processing = AudioProcessingState.error;
    }

    playbackState.add(
      PlaybackState(
        controls: <MediaControl>[
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
        ],
        androidCompactActionIndices: const <int>[0, 1],
        systemActions: const <MediaAction>{},
        processingState: processing,
        playing: playing,
        errorMessage: s == RadioStatus.error ? errorMessage.value : null,
      ),
    );
  }

  Future<void> disposeHandler() async {
    for (final StreamSubscription<dynamic> s in _subs) {
      await s.cancel();
    }
    nowPlaying.current.removeListener(_onNowPlaying);
    _sleepTimer?.cancel();
    _cancelRetry();
    await _player.dispose();
  }
}
