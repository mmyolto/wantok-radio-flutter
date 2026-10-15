import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../app_services.dart';
import '../audio/radio_audio_handler.dart';
import '../config/app_config.dart';
import '../services/now_playing_service.dart';
import '../theme/app_theme.dart';
import '../utils/launcher.dart';
import '../widgets/common.dart';

class LivestreamScreen extends StatefulWidget {
  const LivestreamScreen({super.key});

  @override
  State<LivestreamScreen> createState() => _LivestreamScreenState();
}

class _LivestreamScreenState extends State<LivestreamScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  @override
  void initState() {
    super.initState();
    radio.status.addListener(_syncSpin);
    radio.status.addListener(_watchConnection);
    radio.errorMessage.addListener(_showError);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSpin());
  }

  @override
  void dispose() {
    radio.status.removeListener(_syncSpin);
    radio.status.removeListener(_watchConnection);
    radio.errorMessage.removeListener(_showError);
    _noAudioTimer?.cancel();
    _spin.dispose();
    super.dispose();
  }

  /// True while the disc is gliding back to its starting position.
  bool _returning = false;

  void _syncSpin() {
    if (!mounted) return;
    final bool reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (radio.status.value == RadioStatus.playing && !reduceMotion) {
      if (!_spin.isAnimating || _returning) {
        _returning = false;
        _spin.repeat();
      }
    } else {
      _returnToStart();
    }
  }

  /// When the radio stops, the disc finishes its turn and settles back
  /// upright (its original position) instead of freezing at an angle.
  void _returnToStart() {
    if (_returning) return;
    _spin.stop();
    final double v = _spin.value;
    if (v == 0) return;
    _returning = true;
    _spin
        .animateTo(
          1,
          duration: Duration(milliseconds: (350 + 900 * (1 - v)).round()),
          curve: Curves.easeOutCubic,
        )
        .whenCompleteOrCancel(() {
          if (!mounted || !_returning) return;
          _returning = false;
          _spin.value = 0; // same angle as 1 full turn
        });
  }

  // ---------------------------------------------------------------------------
  // "No audio" pop-up
  // ---------------------------------------------------------------------------

  /// How long Play may stay silent (buffering, reconnecting or offline)
  /// before the listener is told what is happening.
  static const Duration _noAudioAfter = Duration(seconds: 15);
  Timer? _noAudioTimer;
  BuildContext? _dialogContext;

  /// Starts a watch whenever the radio is trying to play but no audio is
  /// coming through; cancels it as soon as the stream is playing.
  void _watchConnection() {
    if (!mounted) return;
    switch (radio.status.value) {
      case RadioStatus.playing:
        _noAudioTimer?.cancel();
        _noAudioTimer = null;
        _closeDialog(); // audio is back: the pop-up is no longer needed
      case RadioStatus.connecting:
      case RadioStatus.reconnecting:
      case RadioStatus.offline:
        _noAudioTimer ??= Timer(_noAudioAfter, _onNoAudio);
      case RadioStatus.stopped:
      case RadioStatus.paused:
      case RadioStatus.error:
        _noAudioTimer?.cancel();
        _noAudioTimer = null;
    }
  }

  void _onNoAudio() {
    _noAudioTimer = null;
    final RadioStatus s = radio.status.value;
    if (!mounted || s == RadioStatus.playing || s == RadioStatus.stopped) return;
    final bool offline = s == RadioStatus.offline;
    _showStreamDialog(
      icon: offline ? Icons.wifi_off_rounded : Icons.volume_off_rounded,
      title: offline ? 'Connection lost' : 'No audio from the live stream',
      message: offline
          ? 'Your phone has lost its internet connection, so the radio cannot play. '
                'Check your mobile data or Wi-Fi. The app will reconnect by itself when the '
                'connection returns.'
          : 'The app is not receiving any audio from the station right now. Your connection '
                'may be weak, or the live stream may be temporarily off air. '
                'We will keep trying for you.',
      keepTrying: true,
    );
  }

  /// The stream could not be reached at all (all retries used up).
  void _showError() {
    final String? msg = radio.errorMessage.value;
    if (msg == null || !mounted) return;
    _noAudioTimer?.cancel();
    _noAudioTimer = null;
    _showStreamDialog(
      icon: Icons.error_outline_rounded,
      title: 'Live stream unavailable',
      message: msg,
      keepTrying: false,
    );
  }

  Future<void> _showStreamDialog({
    required IconData icon,
    required String title,
    required String message,
    required bool keepTrying,
  }) async {
    if (_dialogContext != null) return; // one pop-up at a time
    final String? choice = await showDialog<String>(
      context: context,
      barrierColor: _StreamAlert.scrim,
      builder: (BuildContext ctx) {
        _dialogContext = ctx;
        return _StreamAlert(
          icon: icon,
          title: title,
          message: message,
          primaryLabel: keepTrying ? 'Keep trying' : 'Try again',
          secondaryLabel: keepTrying ? 'Stop' : 'Close',
          onPrimary: () => Navigator.pop(ctx, keepTrying ? 'wait' : 'retry'),
          onSecondary: () => Navigator.pop(ctx, 'stop'),
        );
      },
    );
    _dialogContext = null;
    if (!mounted) return;
    switch (choice) {
      case 'stop':
        if (keepTrying) await radio.stop();
      case 'retry':
        await _onPlayPressed();
      case 'wait':
        // Ask again later if there is still no audio.
        if (radio.status.value != RadioStatus.playing) {
          _noAudioTimer?.cancel();
          _noAudioTimer = Timer(_noAudioAfter * 2, _onNoAudio);
        }
    }
  }

  void _closeDialog() {
    final BuildContext? ctx = _dialogContext;
    if (ctx != null && ctx.mounted) Navigator.pop(ctx);
  }

  Future<void> _onPlayPressed() async {
    final RadioStatus s = radio.status.value;
    final bool idle = s == RadioStatus.stopped || s == RadioStatus.paused || s == RadioStatus.error;
    if (!idle) {
      await radio.stop();
      return;
    }
    List<ConnectivityResult> net;
    try {
      net = await Connectivity().checkConnectivity();
    } catch (_) {
      net = <ConnectivityResult>[ConnectivityResult.other];
    }
    final bool offline =
        net.isEmpty || net.every((ConnectivityResult c) => c == ConnectivityResult.none);
    if (!mounted) return;
    if (offline) {
      await showDialog<void>(
        context: context,
        barrierColor: _StreamAlert.scrim,
        builder: (BuildContext ctx) => _StreamAlert(
          icon: Icons.wifi_off_rounded,
          title: 'No internet connection',
          message: 'Please check your mobile data or Wi-Fi and try again to start the livestream.',
          primaryLabel: 'OK',
          onPrimary: () => Navigator.pop(ctx),
        ),
      );
      return;
    }
    await radio.play();
  }

  Future<void> _openSleepTimer() async {
    final Duration? picked = await showModalBottomSheet<Duration>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (BuildContext ctx) => _SleepTimerSheet(active: radio.sleepAt.value != null),
    );
    if (picked == null) return;
    radio.setSleepTimer(picked == Duration.zero ? null : picked);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            picked == Duration.zero
                ? 'Sleep timer turned off'
                : 'Radio will stop in ${picked.inMinutes} minutes',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          final bool landscape = c.maxWidth > c.maxHeight && c.maxWidth >= 560;
          final double pad = pagePadding(c.maxWidth);

          if (landscape) {
            final double art = (c.maxHeight * 0.62).clamp(140.0, 360.0);
            return Row(
              children: <Widget>[
                // Green panel with the disc on the left.
                Expanded(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: AppColors.headerGradient,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(36),
                        bottomRight: Radius.circular(36),
                      ),
                    ),
                    child: Center(child: _Artwork(size: art, spin: _spin)),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(pad),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: c.maxHeight - pad * 2),
                      child: Center(child: _controls()),
                    ),
                  ),
                ),
              ],
            );
          }

          // Portrait: green top, disc floating over the light bottom.
          final double art = (c.maxHeight * 0.36).clamp(150.0, 300.0).clamp(0.0, c.maxWidth * 0.72);
          const double topGap = 20;
          final double band = topGap + art * 0.62;
          return SingleChildScrollView(
            padding: EdgeInsets.only(bottom: pad),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight - pad),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: topGap + art,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: band,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(gradient: AppColors.headerGradient),
                          ),
                        ),
                        Positioned(
                          top: band - 36,
                          left: 0,
                          right: 0,
                          height: 37,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                            ),
                          ),
                        ),
                        Positioned(
                          top: topGap,
                          left: 0,
                          right: 0,
                          child: Center(child: _Artwork(size: art, spin: _spin)),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(pad, 20, pad, 0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: _controls(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _controls() {
    return ValueListenableBuilder<RadioStatus>(
      valueListenable: radio.status,
      builder: (BuildContext context, RadioStatus status, _) {
        final bool busy =
            status == RadioStatus.connecting ||
            status == RadioStatus.reconnecting ||
            status == RadioStatus.offline;
        final bool idle =
            status == RadioStatus.stopped ||
            status == RadioStatus.paused ||
            status == RadioStatus.error;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _StatusLine(status: status),
            const SizedBox(height: 14),
            const _NowPlayingCard(),
            const SizedBox(height: 22),
            _PlayPill(idle: idle, busy: busy, onPressed: _onPlayPressed),
            const SizedBox(height: 8),
            ValueListenableBuilder<DateTime?>(
              valueListenable: radio.sleepAt,
              builder: (BuildContext context, DateTime? at, _) => TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: AppColors.onSurfaceVariant),
                onPressed: _openSleepTimer,
                icon: Icon(at == null ? Icons.bedtime_outlined : Icons.bedtime),
                label: Text(at == null ? 'Sleep timer' : 'Sleep timer · stops ${_clock(at)}'),
              ),
            ),
            const SizedBox(height: 22),
            _OnDemandCard(onTap: () => Launch.web(context, AppConfig.onDemandUrl)),
          ],
        );
      },
    );
  }

  String _clock(DateTime at) {
    final TimeOfDay tod = TimeOfDay.fromDateTime(at);
    return MaterialLocalizations.of(context).formatTimeOfDay(tod);
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.size, required this.spin});

  final double size;
  final Animation<double> spin;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RadioStatus>(
      valueListenable: radio.status,
      builder: (BuildContext context, RadioStatus status, Widget? child) {
        final bool playing = status == RadioStatus.playing;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.03),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: (playing ? AppColors.gold : Colors.black).withValues(
                  alpha: playing ? 0.45 : 0.18,
                ),
                blurRadius: playing ? 36 : 18,
                spreadRadius: playing ? 4 : 0,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          RotationTransition(
            turns: spin,
            child: ClipOval(
              child: Image.asset(
                'assets/images/station_artwork.png',
                fit: BoxFit.cover,
                semanticLabel: 'Station artwork',
              ),
            ),
          ),
          const Positioned(right: 0, left: 0, bottom: 6, child: Center(child: _LiveBadge())),
        ],
      ),
    );
  }
}

/// Wide green Play / Stop button.
class _PlayPill extends StatelessWidget {
  const _PlayPill({required this.idle, required this.busy, required this.onPressed});

  final bool idle;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      height: 60,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (busy)
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.gold),
                )
              else
                Icon(
                  idle ? Icons.play_arrow_rounded : Icons.stop_rounded,
                  size: 34,
                  color: AppColors.gold,
                ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  idle ? 'Play' : (busy ? 'Cancel' : 'Stop'),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.status});
  final RadioStatus status;

  @override
  Widget build(BuildContext context) {
    final String text;
    Color dot = AppColors.goldDeep;
    Color color = AppColors.primary;
    switch (status) {
      case RadioStatus.stopped:
        text = AppConfig.tagline;
      case RadioStatus.connecting:
        text = 'Buffering…';
      case RadioStatus.reconnecting:
        text = 'Reconnecting…';
      case RadioStatus.offline:
        text = 'Waiting for internet connection…';
        dot = AppColors.error;
        color = AppColors.error;
      case RadioStatus.playing:
        text = 'On Air · Live Now';
        dot = const Color(0xFF22C55E);
      case RadioStatus.paused:
        text = 'Paused — tap Play to rejoin live';
      case RadioStatus.error:
        text = 'Stream unavailable — please try again';
        dot = AppColors.error;
        color = AppColors.error;
    }
    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dot,
              boxShadow: <BoxShadow>[BoxShadow(color: dot.withValues(alpha: 0.6), blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _NowPlayingCard extends StatelessWidget {
  const _NowPlayingCard();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NowPlaying?>(
      valueListenable: nowPlayingService.current,
      builder: (BuildContext context, NowPlaying? np, _) {
        if (np == null || (!np.hasSong && !np.isLive)) return const SizedBox.shrink();
        final String label = np.isLive && (np.streamerName ?? '').isNotEmpty
            ? 'LIVE WITH ${np.streamerName!.toUpperCase()}'
            : 'NOW PLAYING';
        return SectionCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
                child: const Icon(Icons.music_note_rounded, color: AppColors.gold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      np.hasSong ? np.display : AppConfig.appName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.onBackground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OnDemandCard extends StatelessWidget {
  const _OnDemandCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.headphones_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Listen or Download On-Demand',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(Icons.open_in_new_rounded, color: AppColors.primary, size: 20),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RadioStatus>(
      valueListenable: radio.status,
      builder: (BuildContext context, RadioStatus status, _) {
        if (status != RadioStatus.playing) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.red,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: <BoxShadow>[
              BoxShadow(color: AppColors.red.withValues(alpha: 0.6), blurRadius: 12),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.circle, size: 8, color: Colors.white),
              SizedBox(width: 5),
              Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SleepTimerSheet extends StatelessWidget {
  const _SleepTimerSheet({required this.active});
  final bool active;

  static const List<int> _minutes = <int>[15, 30, 45, 60, 90, 120];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Sleep timer',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Stop the radio automatically after…',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              for (final int m in _minutes)
                ActionChip(
                  label: Text(
                    m < 60
                        ? '$m min'
                        : '${m ~/ 60} hr${m >= 120 ? 's' : ''}${m % 60 != 0 ? ' ${m % 60} min' : ''}',
                  ),
                  onPressed: () => Navigator.pop(context, Duration(minutes: m)),
                ),
            ],
          ),
          if (active) ...<Widget>[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context, Duration.zero),
              icon: const Icon(Icons.timer_off_outlined),
              label: const Text('Turn off sleep timer'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pop-up in the same style as the website's pop-ups: white card, gold top
/// edge, gold "LIVE STREAM" pill, serif heading, gold and dark buttons.
class _StreamAlert extends StatelessWidget {
  const _StreamAlert({
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  /// Dark green see-through background, as on the website.
  static const Color scrim = Color(0xC7021412);

  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(height: 5, color: AppColors.gold),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 12, 0),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(icon, size: 14, color: const Color(0xFF5E4700)),
                        const SizedBox(width: 6),
                        const Text(
                          'LIVE STREAM',
                          style: TextStyle(
                            fontFamily: AppTheme.bodyFont,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.3,
                            color: Color(0xFF5E4700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: onSecondary ?? onPrimary,
                    icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
              child: Text(
                title,
                style: t.headlineSmall?.copyWith(color: AppColors.night, height: 1.2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
              child: Text(
                message,
                style: t.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant, height: 1.5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.end,
                children: <Widget>[
                  if (secondaryLabel != null)
                    OutlinedButton(
                      onPressed: onSecondary,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: AppColors.night,
                        side: const BorderSide(color: AppColors.night),
                        minimumSize: const Size(110, 48),
                      ),
                      child: Text(secondaryLabel!),
                    ),
                  FilledButton(
                    onPressed: onPrimary,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.night,
                      minimumSize: const Size(130, 48),
                    ),
                    child: Text(primaryLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
