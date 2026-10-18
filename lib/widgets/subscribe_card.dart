import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/subscribe_service.dart';
import '../theme/app_theme.dart';

/// "Get our monthly news" — free email sign-up (About Us page and Monthly News page).
class SubscribeCard extends StatefulWidget {
  const SubscribeCard({super.key, this.service});

  /// For tests; a real service is created when null.
  final SubscribeService? service;

  @override
  State<SubscribeCard> createState() => _SubscribeCardState();
}

class _SubscribeCardState extends State<SubscribeCard> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  late final SubscribeService _service = widget.service ?? SubscribeService();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String email = _email.text.trim().toLowerCase();
    try {
      final SubscribeResult r = await _service.subscribe(email: email, name: _name.text);
      _form.currentState?.reset();
      _name.clear();
      _email.clear();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            r == SubscribeResult.subscribed
                ? 'You\'re subscribed — thank you! Our monthly news will come to $email.'
                : '$email is already on our monthly news list.',
          ),
        ),
      );
    } on SubscribeException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    const OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide.none,
    );
    InputDecoration deco(String label, IconData icon, {String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: border,
      enabledBorder: border,
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.secondary, width: 2),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.primary, Color(0xFF0B4A42)],
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'FREE · ONCE A MONTH',
                    style: t.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Get our monthly news',
                style: t.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Station news, new programs, testimonies and ways to pray with us — '
                'straight to your email. Free, and you can unsubscribe at any time.',
                style: t.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                inputFormatters: <TextInputFormatter>[LengthLimitingTextInputFormatter(80)],
                decoration: deco('Your name (optional)', Icons.person_outline),
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const ValueKey<String>('subscribeEmail'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                inputFormatters: <TextInputFormatter>[LengthLimitingTextInputFormatter(120)],
                validator: (String? v) => SubscribeService.isValidEmail(v ?? '')
                    ? null
                    : 'Please enter a valid email address',
                decoration: deco('Email address', Icons.email_outlined, hint: 'you@example.com'),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(50),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : const Icon(Icons.mark_email_read_outlined),
                label: Text(_busy ? 'Subscribing…' : 'Subscribe — free'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
