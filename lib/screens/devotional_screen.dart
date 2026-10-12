import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../app_services.dart';
import '../services/devotional_service.dart';
import '../services/push_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

const List<String> _weekdays = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const List<String> _months = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
];

/// "Today", "Yesterday" or "Tue 13 Oct" for a `YYYY-MM-DD` date (the
/// listener's local calendar day).
String devotionalDayLabel(String date, {DateTime? today}) {
  final DateTime? d = DateTime.tryParse(date);
  if (d == null) return date;
  final DateTime now = today ?? DateTime.now();
  // UTC on both sides so a daylight-saving change on the phone can't skew the count.
  final DateTime day0 = DateTime.utc(now.year, now.month, now.day);
  final int diff = day0.difference(DateTime.utc(d.year, d.month, d.day)).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';
}

IconData slotIcon(DevotionalSlot s) =>
    s == DevotionalSlot.morning ? Icons.wb_twilight_rounded : Icons.nights_stay_rounded;

/// Daily devotionals from the Radio Chaplain, plus the reminder switches.
class DevotionalScreen extends StatefulWidget {
  const DevotionalScreen({super.key});

  @override
  State<DevotionalScreen> createState() => _DevotionalScreenState();
}

class _DevotionalScreenState extends State<DevotionalScreen> {
  List<Devotional>? _items;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load(showCacheFirst: true);
  }

  Future<void> _load({bool showCacheFirst = false}) async {
    if (showCacheFirst) {
      final List<Devotional> cached = await devotionalService.loadCache();
      if (!mounted) return;
      if (cached.isNotEmpty && _items == null) setState(() => _items = cached);
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<Devotional> list = await devotionalService.fetchRecent();
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } on DevotionalException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String today = _isoDate(DateTime.now());
    // A devotional is dated by the listener's local day; hide ones that
    // listeners further east already received for "tomorrow".
    final List<Devotional> items = (_items ?? const <Devotional>[])
        .where((Devotional d) => d.date.compareTo(today) <= 0)
        .toList();
    final List<Devotional> todays = items.where((Devotional d) => d.date == today).toList();
    final List<Devotional> earlier = items.where((Devotional d) => d.date != today).toList();
    final TextTheme t = Theme.of(context).textTheme;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: PageBody(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          const ScreenTitle(
            'Daily Devotional',
            subtitle: 'A word from our Radio Chaplain every morning and evening.',
          ),
          ValueListenableBuilder<ReminderState>(
            valueListenable: pushService.state,
            builder: (BuildContext context, ReminderState s, _) =>
                s.available ? _ReminderCard(state: s) : const SizedBox.shrink(),
          ),
          if (_loading && _items == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (items.isEmpty)
            _EmptyState(error: _error, onRetry: _load)
          else ...<Widget>[
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '$_error Showing saved devotionals.',
                  textAlign: TextAlign.center,
                  style: t.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ),
            if (todays.isNotEmpty) ...<Widget>[
              const _SectionLabel('Today'),
              for (final Devotional d in todays)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DevotionalCard(devotional: d, featured: true),
                ),
            ],
            if (earlier.isNotEmpty) ...<Widget>[
              _SectionLabel(todays.isEmpty ? 'Latest' : 'Earlier'),
              for (final Devotional d in earlier)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DevotionalCard(devotional: d),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Semantics(
        header: true,
        child: Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.state});
  final ReminderState state;

  Future<void> _toggle(BuildContext context, DevotionalSlot slot, bool on) async {
    final bool ok = await pushService.setSlot(slot, on);
    if (!ok && on && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notifications are turned off for Wantok Radio Light. '
            'Turn them on in your phone’s Settings, then try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SectionCard(
        padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const CardTitle('Reminders', icon: Icons.notifications_active_outlined),
            for (final DevotionalSlot s in DevotionalSlot.values)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(slotIcon(s), color: AppColors.secondary),
                title: Text(s.label, style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text('Every day at ${s.time}, your local time'),
                value: state.isOn(s),
                onChanged: state.busy ? null : (bool v) => _toggle(context, s, v),
              ),
            if (state.blocked && (state.morning || state.evening))
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 8, 12),
                child: Text(
                  'Notifications are blocked in your phone’s Settings, so reminders can’t appear.',
                  style: t.bodyMedium?.copyWith(color: AppColors.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.error, required this.onRetry});
  final String? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return SectionCard(
      child: Column(
        children: <Widget>[
          Icon(
            error == null ? Icons.auto_stories_outlined : Icons.wifi_off_rounded,
            size: 48,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 12),
          Text(
            error ?? 'The next devotional appears here at 5:00 am or 9:00 pm, your local time.',
            textAlign: TextAlign.center,
            style: t.bodyLarge,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

/// Summary card that opens the full devotional.
class DevotionalCard extends StatelessWidget {
  const DevotionalCard({super.key, required this.devotional, this.featured = false});

  final Devotional devotional;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    final Devotional d = devotional;
    final Color fg = featured ? Colors.white : AppColors.onBackground;
    final Color muted = featured
        ? Colors.white.withValues(alpha: 0.85)
        : AppColors.onSurfaceVariant;
    final String preview = d.verse.isNotEmpty ? '“${d.verse}”' : d.message;

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              slotIcon(d.slot),
              size: 20,
              color: featured ? AppColors.gold : AppColors.secondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${d.slot.label} · ${devotionalDayLabel(d.date)}',
                style: t.labelLarge?.copyWith(color: muted, fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.chevron_right, color: muted),
          ],
        ),
        const SizedBox(height: 10),
        Text(d.title, style: t.titleLarge?.copyWith(color: fg)),
        if (d.scripture.isNotEmpty) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            d.scripture,
            style: t.bodyMedium?.copyWith(
              color: featured ? AppColors.gold : AppColors.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          preview,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: t.bodyMedium?.copyWith(
            color: muted,
            fontStyle: d.verse.isNotEmpty ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      label: '${d.slot.label}, ${devotionalDayLabel(d.date)}: ${d.title}',
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: featured ? const BoxDecoration(gradient: AppColors.headerGradient) : null,
          child: InkWell(
            onTap: () => Navigator.of(context).push(DevotionalPage.route(devotional: d)),
            child: Padding(padding: const EdgeInsets.all(20), child: content),
          ),
        ),
      ),
    );
  }
}

/// Full devotional. Opened from the list, or from a notification (by [id]).
class DevotionalPage extends StatefulWidget {
  const DevotionalPage({super.key, this.devotional, this.id})
    : assert(devotional != null || id != null);

  final Devotional? devotional;
  final String? id;

  static Route<void> route({Devotional? devotional, String? id}) => MaterialPageRoute<void>(
    builder: (_) => DevotionalPage(devotional: devotional, id: id),
  );

  @override
  State<DevotionalPage> createState() => _DevotionalPageState();
}

class _DevotionalPageState extends State<DevotionalPage> {
  Devotional? _d;
  String? _error;

  @override
  void initState() {
    super.initState();
    _d = widget.devotional;
    if (_d == null) _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final Devotional d = await devotionalService.fetchById(widget.id!);
      if (mounted) setState(() => _d = d);
    } on DevotionalException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _share() async {
    final Devotional? d = _d;
    if (d == null) return;
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: d.toShareText(),
        subject: d.title,
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Devotional? d = _d;
    return Scaffold(
      appBar: GradientAppBar(
        title: 'DEVOTIONAL',
        actions: <Widget>[
          if (d != null)
            IconButton(icon: const Icon(Icons.share_outlined), tooltip: 'Share', onPressed: _share),
        ],
      ),
      body: SafeArea(
        top: false,
        child: d != null
            ? DevotionalBody(devotional: d, onShare: _share)
            : _error != null
            ? PageBody(
                children: <Widget>[_EmptyState(error: _error, onRetry: _load)],
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

/// The readable devotional (public so it can be tested on every screen size).
class DevotionalBody extends StatelessWidget {
  const DevotionalBody({super.key, required this.devotional, this.onShare});

  final Devotional devotional;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    final Devotional d = devotional;
    return PageBody(
      maxWidth: 680,
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: <Widget>[
            Chip(
              avatar: Icon(slotIcon(d.slot), size: 18, color: AppColors.secondary),
              label: Text(d.slot.label),
              backgroundColor: AppColors.secondaryContainer,
              side: BorderSide.none,
              labelStyle: t.labelLarge?.copyWith(color: AppColors.onSecondaryContainer),
            ),
            Text(
              '${devotionalDayLabel(d.date)} · ${d.slot.time}',
              style: t.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(
            d.title,
            textAlign: TextAlign.center,
            style: t.headlineMedium?.copyWith(color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 20),
        if (d.verse.isNotEmpty || d.scripture.isNotEmpty) ...<Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              border: const Border(left: BorderSide(color: AppColors.secondary, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (d.verse.isNotEmpty)
                  Text(
                    '“${d.verse}”',
                    style: t.bodyLarge?.copyWith(fontStyle: FontStyle.italic, height: 1.6),
                  ),
                if (d.scripture.isNotEmpty) ...<Widget>[
                  if (d.verse.isNotEmpty) const SizedBox(height: 10),
                  Text(
                    d.scripture,
                    style: t.bodyLarge?.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
        ],
        Text(d.message, style: t.bodyLarge?.copyWith(height: 1.65)),
        if (d.prayer.isNotEmpty) ...<Widget>[
          const SizedBox(height: 22),
          SectionCard(
            color: AppColors.secondaryContainer.withValues(alpha: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const CardTitle('Prayer', icon: Icons.volunteer_activism_outlined),
                Text(d.prayer, style: t.bodyLarge?.copyWith(height: 1.6)),
              ],
            ),
          ),
        ],
        if (d.author.isNotEmpty) ...<Widget>[
          const SizedBox(height: 20),
          Text(
            '— ${d.author}',
            textAlign: TextAlign.right,
            style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
        ],
        if (onShare != null) ...<Widget>[
          const SizedBox(height: 28),
          Center(
            child: OutlinedButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share this devotional'),
            ),
          ),
        ],
      ],
    );
  }
}
