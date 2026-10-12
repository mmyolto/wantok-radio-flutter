import 'package:flutter/material.dart';

import '../data/station_content.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: <Widget>[
        const ScreenTitle('Frequently Asked Questions'),
        for (int i = 0; i < faqs.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FaqTile(faq: faqs[i], initiallyExpanded: i == 0),
          ),
      ],
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.faq, this.initiallyExpanded = false});
  final Faq faq;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: const Icon(Icons.help_outline, color: AppColors.secondary),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.primary,
          title: Text(
            faq.question,
            style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
          children: <Widget>[Text(faq.answer, style: t.bodyLarge)],
        ),
      ),
    );
  }
}
