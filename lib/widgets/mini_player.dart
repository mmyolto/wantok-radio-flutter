import 'package:flutter/material.dart';

import '../app_services.dart';
import '../audio/radio_audio_handler.dart';
import '../services/now_playing_service.dart';
import '../theme/app_theme.dart';

/// Compact "now playing" bar shown under the other screens while the radio is on.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RadioStatus>(
      valueListenable: radio.status,
      builder: (BuildContext context, RadioStatus status, _) {
        final bool visible = status != RadioStatus.stopped;
        return AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          // When hidden, still reserve the system gesture-bar area.
          child: visible
              ? _Bar(status: status, onOpen: onOpen)
              : const SafeArea(top: false, child: SizedBox(width: double.infinity)),
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.status, required this.onOpen});

  final RadioStatus status;
  final VoidCallback onOpen;

  String _subtitle(NowPlaying? np) {
    switch (status) {
      case RadioStatus.connecting:
        return 'Connecting…';
      case RadioStatus.reconnecting:
        return 'Reconnecting…';
      case RadioStatus.offline:
        return 'Waiting for internet…';
      case RadioStatus.paused:
        return 'Paused';
      case RadioStatus.error:
        return 'Stream unavailable — tap to retry';
      case RadioStatus.playing:
      case RadioStatus.stopped:
        return (np?.hasSong ?? false) ? np!.display : 'On Air · Live Now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool busy =
        status == RadioStatus.connecting ||
        status == RadioStatus.reconnecting ||
        status == RadioStatus.offline;
    final bool showPlay = status == RadioStatus.paused || status == RadioStatus.error;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[AppColors.primary, AppColors.night],
        ),
        border: Border(top: BorderSide(color: Color(0x99FFD60A), width: 1.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: InkWell(
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.goldGradient,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/station_artwork.png',
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ValueListenableBuilder<NowPlaying?>(
                      valueListenable: nowPlayingService.current,
                      builder: (BuildContext context, NowPlaying? np, _) => Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              if (status == RadioStatus.playing) ...<Widget>[
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.red,
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(color: AppColors.red, blurRadius: 6),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              const Flexible(
                                child: Text(
                                  'Wantok Radio Light',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _subtitle(np),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.gold, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (busy)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.gold),
                      ),
                    ),
                  Semantics(
                    button: true,
                    label: showPlay ? 'Play' : 'Stop',
                    onTap: showPlay ? radio.play : radio.stop,
                    excludeSemantics: true,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: showPlay ? radio.play : radio.stop,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.goldGradient,
                        ),
                        child: Icon(
                          showPlay ? Icons.play_arrow_rounded : Icons.stop_rounded,
                          color: AppColors.night,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
