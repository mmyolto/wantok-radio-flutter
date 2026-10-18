import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/app_config.dart';
import '../data/station_content.dart';
import '../theme/app_theme.dart';
import '../utils/launcher.dart';
import '../widgets/common.dart';
import '../widgets/subscribe_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return PageBody(
      children: <Widget>[
        const ScreenTitle('About Us'),
        SectionCard(
          child: Column(
            children: <Widget>[
              const StationLogo(height: 84),
              const SizedBox(height: 12),
              Text(
                AppConfig.network,
                textAlign: TextAlign.center,
                style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
              const SizedBox(height: 4),
              Text(
                '105.9 FM · 93.9 FM Port Moresby · 105.7 FM Goroka',
                textAlign: TextAlign.center,
                style: t.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _AboutSection(title: 'Mission', icon: Icons.flag_outlined, body: missionText),
        const SizedBox(height: 16),
        const _AboutSection(title: 'Vision', icon: Icons.visibility_outlined, body: visionText),
        const SizedBox(height: 16),
        const SubscribeCard(),
        const SizedBox(height: 24),
        Text(
          'Connect With Us',
          textAlign: TextAlign.center,
          style: t.titleLarge?.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final Widget fb = _SocialButton(
              label: 'Facebook',
              icon: Icons.facebook,
              color: AppColors.facebook,
              onTap: () => Launch.web(context, AppConfig.facebookUrl),
            );
            final Widget web = _SocialButton(
              label: 'Website',
              icon: Icons.language,
              color: AppColors.website,
              onTap: () => Launch.web(context, AppConfig.websiteUrl),
            );
            if (c.maxWidth >= 480) {
              return Row(
                children: <Widget>[
                  Expanded(child: fb),
                  const SizedBox(width: 12),
                  Expanded(child: web),
                ],
              );
            }
            return Column(children: <Widget>[fb, const SizedBox(height: 12), web]);
          },
        ),
        const SizedBox(height: 20),
        const DeveloperCard(),
        const SizedBox(height: 16),
        const _VersionText(),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.title, required this.icon, required this.body});
  final String title;
  final IconData icon;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CardTitle(title, icon: icon),
          Text(body, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _VersionText extends StatelessWidget {
  const _VersionText();

  static final Future<PackageInfo> _info = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _info,
      builder: (BuildContext context, AsyncSnapshot<PackageInfo> snap) {
        final String v = snap.hasData
            ? 'App Version ${snap.data!.version}'
            : '';
        return Text(
          v,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
        );
      },
    );
  }
}
