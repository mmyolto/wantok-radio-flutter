import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../app_services.dart';
import '../audio/radio_audio_handler.dart';
import '../config/app_config.dart';
import '../services/push_service.dart';
import '../theme/app_theme.dart';
import '../utils/launcher.dart';
import '../widgets/common.dart';
import '../widgets/mini_player.dart';
import '../widgets/stream_alert.dart';
import 'about_screen.dart';
import 'contact_screen.dart';
import 'devotional_screen.dart';
import 'donation_screen.dart';
import 'faq_screen.dart';
import 'livestream_screen.dart';
import 'program_screen.dart';
import 'requests_screen.dart';

class _Section {
  const _Section(this.label, this.icon, this.selectedIcon, this.builder);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget Function() builder;
}

final List<_Section> _sections = <_Section>[
  _Section(
    'Livestream',
    Icons.play_circle_outline,
    Icons.play_circle,
    () => const LivestreamScreen(),
  ),
  _Section(
    'Devotional',
    Icons.auto_stories_outlined,
    Icons.auto_stories,
    () => const DevotionalScreen(),
  ),
  _Section('Program', Icons.list_alt_outlined, Icons.list_alt, () => const ProgramScreen()),
  _Section('Requests', Icons.favorite_border, Icons.favorite, () => const RequestsScreen()),
  _Section('About Us', Icons.info_outline, Icons.info, () => const AboutScreen()),
  _Section('Contact', Icons.call_outlined, Icons.call, () => const ContactScreen()),
  _Section(
    'Donation',
    Icons.volunteer_activism_outlined,
    Icons.volunteer_activism,
    () => const DonationScreen(),
  ),
  _Section('FAQ', Icons.question_answer_outlined, Icons.question_answer, () => const FaqScreen()),
];

final int _devotionalIndex = _sections.indexWhere((_Section s) => s.label == 'Devotional');

bool get _isAndroid => !kIsWeb && Platform.isAndroid;

/// Main frame: drawer on phones, navigation rail on tablets.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 0;
  bool _foregroundInterest = false;
  StreamSubscription<DevotionalOpenRequest>? _foregroundSub;
  bool _promptScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setForegroundInterest(true);
    pushService.openRequests.addListener(_handleOpenRequest);
    pushService.state.addListener(_maybeOfferReminders);
    _foregroundSub = pushService.foregroundMessages.listen(_showDevotionalBanner);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleOpenRequest();
      _maybeOfferReminders();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setForegroundInterest(false);
    pushService.openRequests.removeListener(_handleOpenRequest);
    pushService.state.removeListener(_maybeOfferReminders);
    _foregroundSub?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Daily devotional notifications
  // ---------------------------------------------------------------------------

  /// A devotional notification was tapped: show the Devotional section and
  /// open that devotional.
  void _handleOpenRequest() {
    final DevotionalOpenRequest? r = pushService.openRequests.value;
    if (r == null || !mounted) return;
    pushService.openRequests.value = null;
    _openDevotional(r);
  }

  void _openDevotional(DevotionalOpenRequest r) {
    _scaffoldKey.currentState?.closeDrawer();
    _select(_devotionalIndex);
    final String? id = r.id;
    if (id != null) Navigator.of(context).push(DevotionalPage.route(id: id));
  }

  /// Devotional arrived while the app is open.
  void _showDevotionalBanner(DevotionalOpenRequest r) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(
        MaterialBanner(
          backgroundColor: AppColors.secondaryContainer,
          leading: Icon(
            r.slot == null ? Icons.auto_stories : slotIcon(r.slot!),
            color: AppColors.secondary,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                r.title ?? 'Daily Devotional',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (r.body != null) Text(r.body!, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
          actions: <Widget>[
            TextButton(onPressed: messenger.hideCurrentMaterialBanner, child: const Text('Later')),
            TextButton(
              onPressed: () {
                messenger.hideCurrentMaterialBanner();
                _openDevotional(r);
              },
              child: const Text('Read'),
            ),
          ],
        ),
      );
  }

  /// Once, after the first start: offer the 5 am / 9 pm reminders.
  void _maybeOfferReminders() {
    if (_promptScheduled || !mounted || !pushService.shouldOfferPrompt) return;
    _promptScheduled = true;
    Future<void>.delayed(const Duration(milliseconds: 1500), () async {
      if (!mounted) return;
      final bool? accept = await showDialog<bool>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          icon: const Icon(Icons.auto_stories, color: AppColors.secondary, size: 36),
          title: const Text('Daily Devotionals'),
          content: const Text(
            'Start and end each day with God’s Word. Our Radio Chaplain sends a '
            'short devotional at 5:00 am and 9:00 pm, your local time.\n\n'
            'You can change this any time on the Devotional page.',
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not Now')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Turn On')),
          ],
        ),
      );
      await pushService.answerPrompt(accept: accept ?? false);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only poll "now playing" while the app is visible (or radio is on).
    _setForegroundInterest(state == AppLifecycleState.resumed);
    // Travelled to another time zone? Move the devotional reminders with you.
    if (state == AppLifecycleState.resumed) unawaited(pushService.resync());
  }

  void _setForegroundInterest(bool value) {
    if (value == _foregroundInterest) return;
    _foregroundInterest = value;
    if (value) {
      nowPlayingService.acquire();
    } else {
      nowPlayingService.release();
    }
  }

  void _select(int i) {
    if (i == _index) return;
    setState(() => _index = i);
  }

  Future<void> _shareApp() async {
    final StringBuffer b = StringBuffer()
      ..writeln('Listen to ${AppConfig.appName} — ${AppConfig.tagline}.')
      ..writeln()
      ..writeln('Android: ${AppConfig.playStoreUrl}');
    if (AppConfig.appStoreUrl.isNotEmpty) b.writeln('iPhone & iPad: ${AppConfig.appStoreUrl}');
    b.writeln('Web: ${AppConfig.websiteUrl}');
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: b.toString(),
        subject: AppConfig.appName,
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Future<void> _confirmExit() async {
    final bool listening =
        radio.status.value != RadioStatus.stopped && radio.status.value != RadioStatus.error;
    final String? choice = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        icon: const Icon(Icons.exit_to_app, color: AppColors.primary),
        title: const Text('Exit Application'),
        content: Text(
          listening
              ? 'Would you like to keep listening in the background, or stop the radio and exit?'
              : 'Are you sure you want to exit?',
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          if (listening)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'background'),
              child: const Text('Keep Listening'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'exit'),
            child: Text(listening ? 'Stop & Exit' : 'Exit'),
          ),
        ],
      ),
    );
    if (choice == 'exit') {
      await radio.stop();
      await SystemNavigator.pop();
    } else if (choice == 'background') {
      await SystemNavigator.pop();
    }
  }

  void _onBack() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState?.closeDrawer();
      return;
    }
    if (_index != 0) {
      _select(0);
      return;
    }
    if (_isAndroid) _confirmExit();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool useRail = width >= Breakpoints.medium;
    final bool extendedRail = width >= Breakpoints.expanded;

    final Widget body = AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      child: KeyedSubtree(key: ValueKey<int>(_index), child: _sections[_index].builder()),
    );

    final Widget content = Scaffold(
      key: _scaffoldKey,
      appBar: GradientAppBar(
        title: 'WANTOK RADIO LIGHT',
        leading: useRail
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Menu',
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share App',
            onPressed: _shareApp,
          ),
        ],
      ),
      drawer: useRail
          ? null
          : _AppDrawer(
              selected: _index,
              onSelect: (int i) {
                Navigator.pop(context);
                _select(i);
              },
              onShare: () {
                Navigator.pop(context);
                _shareApp();
              },
              onExit: _isAndroid
                  ? () {
                      Navigator.pop(context);
                      _confirmExit();
                    }
                  : null,
            ),
      body: SafeArea(top: false, child: body),
      bottomNavigationBar: _index == 0 ? null : MiniPlayer(onOpen: () => _select(0)),
    );

    return StreamProblemWatcher(
      child: PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) _onBack();
      },
      child: useRail
          ? Scaffold(
              body: Row(
                children: <Widget>[
                  _Rail(selected: _index, extended: extendedRail, onSelect: _select),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(child: content),
                ],
              ),
            )
          : content,
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.selected,
    required this.onSelect,
    required this.onShare,
    required this.onExit,
  });

  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onShare;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      selectedIndex: selected,
      onDestinationSelected: onSelect,
      backgroundColor: Colors.white,
      children: <Widget>[
        const _DrawerHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: GoldButton(
            label: 'Give Online',
            icon: Icons.favorite_rounded,
            height: 48,
            onPressed: () => Launch.web(context, AppConfig.donateUrl),
          ),
        ),
        const SizedBox(height: 4),
        for (final _Section s in _sections)
          NavigationDrawerDestination(
            icon: Icon(s.icon),
            selectedIcon: Icon(s.selectedIcon, color: AppColors.primary),
            label: Text(s.label),
          ),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 28, vertical: 8), child: Divider()),
        _DrawerAction(icon: Icons.share_outlined, label: 'Share App', onTap: onShare),
        if (onExit != null) _DrawerAction(icon: Icons.exit_to_app, label: 'Exit', onTap: onExit!),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: DeveloperCredit(size: 11.5),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: <BoxShadow>[
                BoxShadow(color: AppColors.gold.withValues(alpha: 0.35), blurRadius: 24),
              ],
            ),
            child: const StationLogo(height: 60),
          ),
          const SizedBox(height: 14),
          const Text(
            'WANTOK RADIO LIGHT',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.displayFont,
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'YOUR INSPIRATION STATION',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.bodyFont,
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
              color: AppColors.gold,
              letterSpacing: 2.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerAction extends StatelessWidget {
  const _DrawerAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.onSurfaceVariant),
        title: Text(label, style: Theme.of(context).textTheme.labelLarge),
        shape: const StadiumBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        onTap: onTap,
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.selected, required this.extended, required this.onSelect});

  final int selected;
  final bool extended;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: IntrinsicHeight(
            child: NavigationRail(
              selectedIndex: selected,
              onDestinationSelected: onSelect,
              extended: extended,
              minExtendedWidth: 240,
              labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: extended
                    ? const StationLogo(height: 56)
                    : ClipOval(
                        child: Image.asset(
                          'assets/images/station_artwork.png',
                          width: 48,
                          height: 48,
                          semanticLabel: 'Wantok Radio Light',
                        ),
                      ),
              ),
              destinations: <NavigationRailDestination>[
                for (final _Section s in _sections)
                  NavigationRailDestination(
                    icon: Icon(s.icon),
                    selectedIcon: Icon(s.selectedIcon),
                    label: Text(s.label),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
