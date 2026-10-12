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
    radio.errorMessage.addListener(_showError);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSpin());
  }

  @override
  void dispose() {
    radio.status.removeListener(_syncSpin);
    radio.errorMessage.removeListener(_showError);
    _spin.dispose();
    super.dispose();
  }

  void _syncSpin() {
    if (!mounted) return;
    final bool reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (radio.status.value == RadioStatus.playing && !reduceMotion) {
      if (!_spin.isAnimating) _spin.repeat();
    } else {
      _spin.stop();
    }
  }

  void _showError() {
    final String? msg = radio.errorMessage.value;
    if (msg == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          action: SnackBarAction(label: 'Retry', onPressed: radio.play),
        ),
      );
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
        builder: (BuildContext ctx) => AlertDialog(
          icon: const Icon(Icons.wifi_off, color: AppColors.error),
          title: const Text('No Internet Connection'),
          content: const Text(
            'Please check your internet connection and try again to start the livestream.',
          ),
          actions: <Widget>[
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
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
      color: Theme.of(context).colorScheme.surface,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          final bool landscape = c.maxWidth > c.maxHeight && c.maxWidth >= 560;
          final double pad = pagePadding(c.maxWidth);

          if (landscape) {
            final double art = (c.maxHeight * 0.62).clamp(140.0, 360.0);
            return SingleChildScrollView(
              padding: EdgeInsets.all(pad),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight - pad * 2),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Center(
                            child: _Artwork(size: art, spin: _spin),
                          ),
                        ),
                        SizedBox(width: pad),
                        Expanded(child: _controls(c.maxWidth / 2)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          final double art = (c.maxHeight * 0.4).clamp(150.0, 320.0).clamp(0.0, c.maxWidth * 0.78);
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(pad, pad + 8, pad, pad),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight - pad * 2 - 8),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _Artwork(size: art, spin: _spin),
                      const SizedBox(height: 28),
                      _controls(c.maxWidth),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _controls(double availableWidth) {
    final TextTheme t = Theme.of(context).textTheme;
    final double buttonWidth = (availableWidth * 0.6).clamp(200.0, 300.0);

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
            Semantics(
              header: true,
              child: Text(
                AppConfig.appName,
                textAlign: TextAlign.center,
                style: t.headlineMedium?.copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 6),
            _StatusLine(status: status),
            const SizedBox(height: 12),
            const _NowPlayingCard(),
            const SizedBox(height: 20),
            SizedBox(
              width: buttonWidth,
              height: 64,
              child: FilledButton(
                onPressed: _onPlayPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: idle ? AppColors.primary : AppColors.red,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 3,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (busy)
                      const SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                      )
                    else
                      Icon(idle ? Icons.play_arrow_rounded : Icons.stop_rounded, size: 40),
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
            const SizedBox(height: 12),
            ValueListenableBuilder<DateTime?>(
              valueListenable: radio.sleepAt,
              builder: (BuildContext context, DateTime? at, _) => TextButton.icon(
                onPressed: _openSleepTimer,
                icon: Icon(at == null ? Icons.bedtime_outlined : Icons.bedtime),
                label: Text(at == null ? 'Sleep timer' : 'Sleep timer · stops ${_clock(at)}'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'REACHING YOU RIGHT WHERE YOU ARE',
              textAlign: TextAlign.center,
              style: t.labelLarge?.copyWith(
                color: AppColors.secondary,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
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

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.status});
  final RadioStatus status;

  @override
  Widget build(BuildContext context) {
    String text;
    Color color = AppColors.secondary;
    switch (status) {
      case RadioStatus.stopped:
        text = AppConfig.tagline;
      case RadioStatus.connecting:
        text = 'Buffering…';
      case RadioStatus.reconnecting:
        text = 'Reconnecting…';
      case RadioStatus.offline:
        text = 'Waiting for internet connection…';
        color = AppColors.error;
      case RadioStatus.playing:
        text = 'On Air · Live Now';
        color = AppColors.primaryLight;
      case RadioStatus.paused:
        text = 'Paused — tap Play to rejoin live';
      case RadioStatus.error:
        text = 'Stream unavailable — please try again';
        color = AppColors.error;
    }
    return Semantics(
      liveRegion: true,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: color, fontWeight: FontWeight.w600),
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
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.secondaryContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: <Widget>[
              const Icon(Icons.music_note_rounded, color: AppColors.secondary),
              const SizedBox(width: 10),
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
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      np.hasSong ? np.display : AppConfig.appName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSecondaryContainer,
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
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
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
        ),
      ),
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
