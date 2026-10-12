import 'dart:async';

import 'package:flutter/material.dart';

import '../data/station_content.dart';
import '../theme/app_theme.dart';
import '../utils/schedule.dart';
import '../widgets/common.dart';

class ProgramScreen extends StatefulWidget {
  const ProgramScreen({super.key});

  @override
  State<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Refresh the "on air" highlight every minute.
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime png = pngNow();
    final int onAir = currentProgramIndex(png);
    final bool weekend = isWeekend(png);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final bool twoColumns = c.maxWidth >= 900;
        final List<Widget> tiles = <Widget>[
          for (int i = 0; i < weekdayPrograms.length; i++)
            _ProgramTile(item: weekdayPrograms[i], onAir: i == onAir),
        ];

        return PageBody(
          maxWidth: twoColumns ? 1000 : 720,
          children: <Widget>[
            const ScreenTitle(scheduleTitle),
            _InfoBanner(
              icon: weekend ? Icons.weekend_outlined : Icons.schedule,
              text: weekend
                  ? 'This is our weekday schedule. Weekend programs differ — tune in to hear what is on air now.'
                  : 'All times are Papua New Guinea time (UTC+10).',
            ),
            const SizedBox(height: 16),
            if (twoColumns)
              _TwoColumnGrid(children: tiles)
            else
              ...tiles.map(
                (Widget t) => Padding(padding: const EdgeInsets.only(bottom: 10), child: t),
              ),
          ],
        );
      },
    );
  }
}

class _TwoColumnGrid extends StatelessWidget {
  const _TwoColumnGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final int half = (children.length / 2).ceil();
    Widget column(List<Widget> items) => Expanded(
      child: Column(
        children: <Widget>[
          for (final Widget w in items)
            Padding(padding: const EdgeInsets.only(bottom: 10), child: w),
        ],
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        column(children.sublist(0, half)),
        const SizedBox(width: 16),
        column(children.sublist(half)),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramTile extends StatelessWidget {
  const _ProgramTile({required this.item, required this.onAir});

  final ProgramItem item;
  final bool onAir;

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return Semantics(
      label: '${item.time}, ${item.title}${onAir ? ', on air now' : ''}',
      excludeSemantics: true,
      child: Card(
        color: onAir ? AppColors.primary : Colors.white,
        elevation: onAir ? 4 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: <Widget>[
              Container(
                constraints: const BoxConstraints(minWidth: 84),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: onAir ? AppColors.gold : AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.time,
                  textAlign: TextAlign.center,
                  style: t.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (onAir)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ON AIR NOW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    Text(
                      item.title,
                      style: t.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: onAir ? Colors.white : AppColors.onBackground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
