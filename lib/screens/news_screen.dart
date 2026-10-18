import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/app_theme.dart';
import '../utils/launcher.dart';
import '../widgets/common.dart';
import '../widgets/subscribe_card.dart';

/// Monthly News: free email newsletter sign-up.
class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return PageBody(
      children: <Widget>[
        const ScreenTitle('Monthly News', subtitle: 'Stay connected with the ministry'),
        const SubscribeCard(),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const CardTitle('What you will receive', icon: Icons.inbox_outlined),
              for (final String line in const <String>[
                'Station news and announcements',
                'New programs and special broadcasts',
                'Testimonies from listeners across PNG',
                'Prayer points and ways to support the ministry',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.check_circle, size: 18, color: AppColors.secondary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(line, style: t.bodyLarge)),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                'One email a month, free. To stop, just reply to any of our emails and ask to '
                'be removed.',
                style: t.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: () => Launch.web(context, '${AppConfig.websiteUrl}#/news'),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Read the latest news on our website'),
          ),
        ),
      ],
    );
  }
}
