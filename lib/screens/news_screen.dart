import 'dart:async';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../config/app_config.dart';
import '../services/newsletter_service.dart';
import '../theme/app_theme.dart';
import '../utils/launcher.dart';
import '../widgets/common.dart';
import '../widgets/subscribe_card.dart';

const List<String> _months = <String>[
  'January', 'February', 'March', 'April', 'May', 'June', //
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// "October 2026" from "2026-10".
String newsletterMonthLabel(String month) {
  final List<String> p = month.split('-');
  final int m = p.length == 2 ? int.tryParse(p[1]) ?? 0 : 0;
  return m >= 1 && m <= 12 ? '${_months[m - 1]} ${p[0]}' : month;
}

/// Monthly News: the News Letters published in the app, plus email sign-up.
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<Newsletter>> _future = newsletterService.fetch();

  Future<void> _refresh() async {
    final Future<List<Newsletter>> f = newsletterService.fetch(refresh: true);
    setState(() => _future = f);
    try {
      await f;
    } on Object {
      // shown by the FutureBuilder
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: PageBody(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          const ScreenTitle('Monthly News', subtitle: 'Our News Letter, every end of the month'),
          FutureBuilder<List<Newsletter>>(
            future: _future,
            builder: (BuildContext context, AsyncSnapshot<List<Newsletter>> snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final List<Newsletter> list = snap.data ?? const <Newsletter>[];
              if (snap.hasError || list.isEmpty) {
                return SectionCard(
                  child: Column(
                    children: <Widget>[
                      const Icon(
                        Icons.mark_email_unread_outlined,
                        size: 40,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        snap.hasError
                            ? 'Could not load the News Letter. Check your internet connection.'
                            : 'Our first News Letter will appear here at the end of the month.',
                        textAlign: TextAlign.center,
                        style: t.bodyLarge,
                      ),
                      if (snap.hasError)
                        TextButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try again'),
                        ),
                    ],
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (int i = 0; i < list.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _IssueCard(newsletter: list[i], latest: i == 0),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const SubscribeCard(),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () => Launch.web(context, '${AppConfig.websiteUrl}#/news'),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Read the latest news on our website'),
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.newsletter, required this.latest});

  final Newsletter newsletter;
  final bool latest;

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return SectionCard(
      color: latest ? AppColors.secondaryContainer : null,
      onTap: () => Navigator.of(context).push(NewsletterPage.route(newsletter: newsletter)),
      child: Row(
        children: <Widget>[
          Icon(
            latest ? Icons.mark_email_unread : Icons.drafts_outlined,
            color: latest ? AppColors.secondary : AppColors.primary,
            size: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  newsletterMonthLabel(newsletter.month),
                  style: t.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (newsletter.preview.isNotEmpty)
                  Text(
                    newsletter.preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium,
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

/// One News Letter. Opened from the list, the pop-up, or a notification (by [month]).
class NewsletterPage extends StatefulWidget {
  const NewsletterPage({super.key, this.newsletter, this.month});

  final Newsletter? newsletter;

  /// `YYYY-MM`; empty or null opens the newest.
  final String? month;

  static Route<void> route({Newsletter? newsletter, String? month}) => MaterialPageRoute<void>(
    builder: (_) => NewsletterPage(newsletter: newsletter, month: month),
  );

  @override
  State<NewsletterPage> createState() => _NewsletterPageState();
}

class _NewsletterPageState extends State<NewsletterPage> {
  Newsletter? _n;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final Newsletter? given = widget.newsletter;
    _n = given;
    if (given == null) {
      unawaited(_load());
    } else {
      unawaited(newsletterService.markSeen(given.month));
    }
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final List<Newsletter> list = await newsletterService.fetch(refresh: true);
      final String want = widget.month ?? '';
      Newsletter? found;
      for (final Newsletter n in list) {
        if (want.isEmpty || n.month == want) {
          found = n;
          break;
        }
      }
      found ??= list.isEmpty ? null : list.first;
      if (found != null) await newsletterService.markSeen(found.month);
      if (!mounted) return;
      setState(() {
        _n = found;
        _failed = found == null;
      });
    } on Object {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Newsletter? n = _n;
    return Scaffold(
      appBar: const GradientAppBar(title: 'NEWS LETTER'),
      body: SafeArea(
        top: false,
        child: n != null
            ? NewsletterBody(newsletter: n)
            : _failed
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text('Could not load the News Letter.'),
                    TextButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

/// The readable News Letter.
class NewsletterBody extends StatelessWidget {
  const NewsletterBody({super.key, required this.newsletter});

  final Newsletter newsletter;

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return PageBody(
      children: <Widget>[
        ScreenTitle('News Letter', subtitle: newsletterMonthLabel(newsletter.month)),
        for (final NewsletterPart p in newsletter.parts)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CardTitle(p.title),
                  if (p.stats.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        p.stats,
                        style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (p.text.isNotEmpty)
                    SelectableText(p.text, style: t.bodyLarge?.copyWith(height: 1.5)),
                  for (final NewsletterFile f in p.files)
                    if (f.isImage)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            f.url,
                            fit: BoxFit.cover,
                            errorBuilder: (BuildContext c, Object e, StackTrace? s) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      )
                    else
                      TextButton.icon(
                        onPressed: () => Launch.web(context, f.url),
                        icon: const Icon(Icons.attach_file),
                        label: Text(f.name, overflow: TextOverflow.ellipsis),
                      ),
                ],
              ),
            ),
          ),
        Text(
          'God bless you — Wantok Radio Light',
          textAlign: TextAlign.center,
          style: t.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}
