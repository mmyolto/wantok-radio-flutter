import 'package:flutter/material.dart';

import '../app_services.dart';
import '../audio/radio_audio_handler.dart';
import '../theme/app_theme.dart';

/// Pop-up in the same style as the website's pop-ups: white card, gold top
/// edge, gold "LIVE STREAM" pill, serif heading, gold and dark buttons.
class StreamAlert extends StatelessWidget {
  const StreamAlert({
    super.key,
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

/// Watches the radio for [StreamProblem]s and shows the matching pop-up on
/// whatever screen the listener is on. The pop-up closes by itself when the
/// sound comes back.
class StreamProblemWatcher extends StatefulWidget {
  const StreamProblemWatcher({super.key, required this.child});

  final Widget child;

  @override
  State<StreamProblemWatcher> createState() => _StreamProblemWatcherState();
}

class _StreamProblemWatcherState extends State<StreamProblemWatcher> {
  BuildContext? _dialogContext;
  StreamProblem? _showing;

  @override
  void initState() {
    super.initState();
    radio.problem.addListener(_onProblem);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onProblem());
  }

  @override
  void dispose() {
    radio.problem.removeListener(_onProblem);
    super.dispose();
  }

  void _onProblem() {
    if (!mounted) return;
    final StreamProblem? p = radio.problem.value;
    if (p == _showing) return;
    _close();
    if (p != null) _show(p);
  }

  void _close() {
    final BuildContext? ctx = _dialogContext;
    _dialogContext = null;
    _showing = null;
    if (ctx != null && ctx.mounted) Navigator.of(ctx).pop();
  }

  Future<void> _show(StreamProblem p) async {
    _showing = p;
    final bool unavailable = p == StreamProblem.unavailable;
    final String? choice = await showDialog<String>(
      context: context,
      barrierColor: StreamAlert.scrim,
      builder: (BuildContext ctx) {
        _dialogContext = ctx;
        return switch (p) {
          StreamProblem.noAudio => StreamAlert(
              icon: Icons.volume_off_rounded,
              title: 'No audio from the live stream',
              message:
                  'The app is not receiving any audio from the station right now. Your '
                  'connection may be weak, or the live stream may be temporarily off air. '
                  'We will keep trying for you.',
              primaryLabel: 'Keep trying',
              secondaryLabel: 'Stop',
              onPrimary: () => Navigator.pop(ctx, 'wait'),
              onSecondary: () => Navigator.pop(ctx, 'stop'),
            ),
          StreamProblem.offline => StreamAlert(
              icon: Icons.wifi_off_rounded,
              title: 'Connection lost',
              message:
                  'Your phone has lost its internet connection, so the radio cannot play. '
                  'Check your mobile data or Wi-Fi. The radio will reconnect by itself when '
                  'the connection returns.',
              primaryLabel: 'Keep trying',
              secondaryLabel: 'Stop',
              onPrimary: () => Navigator.pop(ctx, 'wait'),
              onSecondary: () => Navigator.pop(ctx, 'stop'),
            ),
          StreamProblem.unavailable => StreamAlert(
              icon: Icons.error_outline_rounded,
              title: 'Live stream unavailable',
              message:
                  radio.errorMessage.value ??
                  'We could not reach the live stream. Please check your connection and try again.',
              primaryLabel: 'Try again',
              secondaryLabel: 'Close',
              onPrimary: () => Navigator.pop(ctx, 'retry'),
              onSecondary: () => Navigator.pop(ctx, 'close'),
            ),
        };
      },
    );
    // Closed by us (sound came back / new problem): nothing more to do.
    if (_showing != p) return;
    _dialogContext = null;
    _showing = null;
    switch (choice) {
      case 'stop':
        await radio.stop();
      case 'retry':
        await radio.play();
      case 'close':
        radio.problem.value = null;
      default: // 'wait', or tapped outside
        if (unavailable) {
          radio.problem.value = null;
        } else {
          radio.acknowledgeProblem();
        }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
