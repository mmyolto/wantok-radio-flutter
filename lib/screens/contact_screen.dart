import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/app_theme.dart';
import '../utils/launcher.dart';
import '../widgets/brand_icons.dart';
import '../widgets/common.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;

    final List<Widget> channels = <Widget>[
      _ContactTile(
        color: AppColors.sms,
        icon: const Icon(Icons.sms_outlined, color: Colors.white),
        title: 'SMS',
        subtitle: 'Send a text',
        onTap: () => Launch.sms(context, AppConfig.studioMobile),
      ),
      _ContactTile(
        color: AppColors.whatsApp,
        icon: const WhatsAppIcon(color: Colors.white),
        title: 'WhatsApp',
        subtitle: 'Message us',
        onTap: () => Launch.whatsApp(context, AppConfig.studioMobile),
      ),
      _ContactTile(
        color: AppColors.email,
        icon: const Icon(Icons.email_outlined, color: Colors.white),
        title: 'Email',
        subtitle: 'Send an email',
        onTap: () => Launch.email(context, AppConfig.email, subject: AppConfig.emailSubject),
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final bool wide = c.maxWidth >= 760;
        return PageBody(
          maxWidth: wide ? 960 : 640,
          children: <Widget>[
            const ScreenTitle(
              'Contact Us',
              subtitle:
                  "We'd love to hear from you! Reach out to us through any of these channels:",
            ),
            if (wide)
              Row(
                children: <Widget>[
                  for (int i = 0; i < channels.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: channels[i]),
                  ],
                ],
              )
            else
              for (final Widget w in channels)
                Padding(padding: const EdgeInsets.only(bottom: 12), child: w),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const CardTitle('Office Enquiries', icon: Icons.business_outlined),
                  Text(
                    '${AppConfig.officePhoneDisplay}\n(Open ${AppConfig.officeHours})',
                    style: t.bodyLarge,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Launch.call(context, AppConfig.officePhone),
                      icon: const Icon(Icons.call),
                      label: const Text('Call Office'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const CardTitle('Visit Us', icon: Icons.location_on_outlined),
                  Text(
                    AppConfig.appName,
                    style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(AppConfig.addressLine1, style: t.bodyLarge),
                  Text(AppConfig.addressLine2, style: t.bodyLarge),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => Launch.map(context),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Open in Maps'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color color;
  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      onTap: onTap,
      excludeSemantics: true,
      child: SectionCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
              child: Center(child: icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  Text(subtitle, style: t.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}
