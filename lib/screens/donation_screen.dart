import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_config.dart';
import '../data/station_content.dart';
import '../theme/app_theme.dart';
import '../utils/launcher.dart';
import '../widgets/common.dart';

class DonationScreen extends StatelessWidget {
  const DonationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final bool wide = c.maxWidth >= 760;
        final List<Widget> banks = <Widget>[
          for (final BankAccount b in bankAccounts) _BankCard(account: b),
        ];
        return PageBody(
          maxWidth: wide ? 960 : 640,
          children: <Widget>[
            const ScreenTitle('Support Our Ministry'),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.headerGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: <Widget>[
                  const Icon(Icons.format_quote_rounded, color: AppColors.gold, size: 32),
                  Text(
                    donationVerse,
                    textAlign: TextAlign.center,
                    style: t.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    donationVerseRef,
                    style: t.labelLarge?.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
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
                  const CardTitle('Why Give?', icon: Icons.favorite_outline),
                  Text(whyGive1, style: t.bodyLarge),
                  const SizedBox(height: 10),
                  Text(whyGive2, style: t.bodyLarge),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const _OnlineDonationCard(),
            const SizedBox(height: 24),
            Text(
              'Bank Transfer',
              textAlign: TextAlign.center,
              style: t.titleLarge?.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap a number to copy it',
              textAlign: TextAlign.center,
              style: t.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            if (wide)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (int i = 0; i < banks.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(width: 16),
                      Expanded(child: banks[i]),
                    ],
                  ],
                ),
              )
            else
              for (final Widget b in banks)
                Padding(padding: const EdgeInsets.only(bottom: 16), child: b),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.lock_outline, size: 16, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'We do not collect, sell, or trade your personal information.',
                    textAlign: TextAlign.center,
                    style: t.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _BankCard extends StatelessWidget {
  const _BankCard({required this.account});
  final BankAccount account;

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  account.logoAsset,
                  width: 52,
                  height: 52,
                  fit: BoxFit.contain,
                  semanticLabel: '${account.bank} logo',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(account.bank, style: t.titleLarge?.copyWith(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CopyRow(label: 'Account Name', value: account.accountName),
          _CopyRow(label: 'Account Number', value: account.accountNumber),
          _CopyRow(label: 'SWIFT Code', value: account.swift),
          _CopyRow(label: 'BSB Number', value: account.bsb),
        ],
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.label, required this.value});
  final String label;
  final String value;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label copied')));
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '$label $value. Double tap to copy.',
      onTap: () => _copy(context),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _copy(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: '$label: ',
                        style: t.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      TextSpan(
                        text: value,
                        style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const Icon(Icons.copy_rounded, size: 18, color: AppColors.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnlineDonationCard extends StatelessWidget {
  const _OnlineDonationCard();

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.volunteer_activism_rounded, color: AppColors.night),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Give Online', style: t.titleLarge?.copyWith(color: Colors.white)),
                    Text(
                      'One-time or monthly gift in Kina',
                      style: t.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Tap below to open our secure donation page on wantokradio.org. '
            'Choose your amount and follow the steps there.',
            style: t.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85), height: 1.5),
          ),
          const SizedBox(height: 18),
          GoldButton(
            label: 'Donate Now',
            icon: Icons.favorite_rounded,
            onPressed: () => Launch.web(context, AppConfig.donateUrl),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.lock_rounded, size: 14, color: AppColors.gold),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Secure page · opens in your browser',
                  style: t.bodySmall?.copyWith(color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            children: <Widget>[
              _PolicyLink(label: 'Terms & Conditions', url: AppConfig.donationTermsUrl),
              _PolicyLink(label: 'Privacy Policy', url: AppConfig.donationPrivacyUrl),
              _PolicyLink(label: 'Refund Policy', url: AppConfig.donationRefundUrl),
            ],
          ),
        ],
      ),
    );
  }
}

class _PolicyLink extends StatelessWidget {
  const _PolicyLink({required this.label, required this.url});
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.gold,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 36),
        textStyle: const TextStyle(
          fontFamily: AppTheme.bodyFont,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.gold,
        ),
      ),
      onPressed: () => Launch.web(context, url),
      child: Text(label),
    );
  }
}
