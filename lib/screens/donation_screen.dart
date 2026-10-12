import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_config.dart';
import '../data/station_content.dart';
import '../theme/app_theme.dart';
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
            if (AppConfig.showOnlineDonation) ...<Widget>[
              const SizedBox(height: 16),
              const _OnlineDonationCard(),
            ],
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

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '$label $value. Double tap to copy.',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: value));
          if (!context.mounted) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text('$label copied')));
        },
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
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const CardTitle('Online Donation', icon: Icons.credit_card),
          Row(
            children: <Widget>[
              Image.asset(
                'assets/images/paypal.png',
                width: 48,
                height: 48,
                semanticLabel: 'PayPal',
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Debit / Credit Card or PayPal', style: t.bodyLarge)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () =>
                  showDialog<void>(context: context, builder: (_) => const _DonationDialog()),
              icon: const Icon(Icons.volunteer_activism),
              label: const Text('Donate by credit/debit card'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonationDialog extends StatefulWidget {
  const _DonationDialog();

  @override
  State<_DonationDialog> createState() => _DonationDialogState();
}

class _DonationDialogState extends State<_DonationDialog> {
  int? _amount;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Donation Amount (PGK)'),
      content: SingleChildScrollView(
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            for (final int a in donationAmounts)
              ChoiceChip(
                label: Text('K$a'),
                selected: _amount == a,
                onSelected: (_) => setState(() => _amount = a),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        FilledButton(
          onPressed: _amount == null
              ? null
              : () {
                  final NavigatorState nav = Navigator.of(context);
                  nav.pop();
                  showDialog<void>(
                    context: nav.context,
                    builder: (BuildContext ctx) => AlertDialog(
                      title: const Text('Coming Soon'),
                      content: const Text(
                        'Online payment integration is currently under development. Please use Bank Transfer for now. Thank you!',
                      ),
                      actions: <Widget>[
                        FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
                      ],
                    ),
                  );
                },
          child: const Text('Donate Now'),
        ),
      ],
    );
  }
}
