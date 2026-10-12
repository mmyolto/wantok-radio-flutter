import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../data/countries.dart';
import '../data/station_content.dart';
import '../services/request_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  Future<void> _open(BuildContext context, RequestKind kind) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool? sent = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute<bool>(builder: (_) => RequestFormPage(kind: kind)));
    if (sent ?? false) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            kind == RequestKind.prayer
                ? 'Prayer request submitted successfully!'
                : 'Song request submitted successfully!',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final bool side = c.maxWidth >= 700;
        final Widget prayer = _ChoiceCard(
          icon: Icons.volunteer_activism,
          color: AppColors.primary,
          title: 'Prayer Request',
          subtitle: 'Share your prayer request with us and we will lift you up in prayer',
          onTap: () => _open(context, RequestKind.prayer),
        );
        final Widget song = _ChoiceCard(
          icon: Icons.music_note_rounded,
          color: AppColors.secondary,
          title: 'Song Request',
          subtitle: 'Request your favorite Christian song and dedicate it to someone special',
          onTap: () => _open(context, RequestKind.song),
        );
        return PageBody(
          maxWidth: side ? 900 : 640,
          children: <Widget>[
            const ScreenTitle('Requests', subtitle: 'How can we serve you today?'),
            if (side)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(child: prayer),
                    const SizedBox(width: 16),
                    Expanded(child: song),
                  ],
                ),
              )
            else ...<Widget>[prayer, const SizedBox(height: 16), song],
            const SizedBox(height: 24),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.privacy_tip_outlined),
                label: const Text('Privacy Policy'),
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: (_) => const PrivacyPolicyPage())),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      child: SectionCard(
        onTap: onTap,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: t.titleLarge?.copyWith(color: color),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: t.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

enum RequestKind { prayer, song }

/// Prayer or song request form (full page so it works well with the keyboard).
class RequestFormPage extends StatefulWidget {
  const RequestFormPage({super.key, required this.kind});
  final RequestKind kind;

  @override
  State<RequestFormPage> createState() => _RequestFormPageState();
}

class _RequestFormPageState extends State<RequestFormPage> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _location = TextEditingController();
  final TextEditingController _message = TextEditingController();
  final TextEditingController _songTitle = TextEditingController();
  final TextEditingController _artist = TextEditingController();

  Country _country = countries.firstWhere((Country c) => c.name == defaultCountryName);
  bool _sending = false;
  bool _showErrors = false;

  bool get _isPrayer => widget.kind == RequestKind.prayer;

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _name,
      _phone,
      _location,
      _message,
      _songTitle,
      _artist,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _missing => <String>[
    if (_name.text.trim().isEmpty) 'Name',
    if (_phoneDigits.length < 5) 'Phone Number',
    if (_message.text.trim().isEmpty) _isPrayer ? 'Prayer Request' : 'Message / Dedication',
  ];

  /// Digits of the local number, without a leading trunk "0" (the country
  /// code is added in front, e.g. 0412 345 678 → +61 412 345 678).
  String get _phoneDigits =>
      _phone.text.replaceAll(RegExp(r'[^0-9]'), '').replaceFirst(RegExp(r'^0+'), '');

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final List<String> missing = _missing;
    if (missing.isNotEmpty) {
      setState(() => _showErrors = true);
      await showDialog<void>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          icon: const Icon(Icons.error_outline, color: AppColors.error),
          title: const Text('Missing Information'),
          content: Text(
            'Please fill in the following mandatory fields:\n\n${missing.map((String m) => '• $m').join('\n')}',
          ),
          actions: <Widget>[
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    final String fullPhone = '${_country.dialCode}$_phoneDigits';
    final String loc = _location.text.trim();
    final String fullLocation = loc.isEmpty ? _country.name : '${_country.name}, $loc';

    setState(() => _sending = true);
    try {
      if (_isPrayer) {
        await requestService.submitPrayer(
          name: _name.text.trim(),
          phone: fullPhone,
          location: fullLocation,
          request: _message.text.trim(),
        );
      } else {
        await requestService.submitSong(
          name: _name.text.trim(),
          phone: fullPhone,
          location: fullLocation,
          message: _message.text.trim(),
          artist: _artist.text.trim(),
          songTitle: _songTitle.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on RequestException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Submission failed. Please try again.')));
    }
  }

  Future<void> _pickCountry() async {
    final Country? picked = await showDialog<Country>(
      context: context,
      builder: (_) => CountryPickerDialog(selected: _country),
    );
    if (picked != null) setState(() => _country = picked);
  }

  void _revalidate(String _) {
    if (_showErrors) setState(() {});
  }

  String? _err(TextEditingController c) {
    if (!_showErrors) return null;
    if (identical(c, _phone)) return _phoneDigits.length < 5 ? 'Enter a valid phone number' : null;
    return c.text.trim().isEmpty ? 'Required' : null;
  }

  Widget _countryButton(TextTheme t) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: _pickCountry,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: AppColors.outline),
          backgroundColor: Colors.white,
        ),
        child: Semantics(
          label: 'Country code ${_country.name} ${_country.dialCode}',
          excludeSemantics: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '${_country.flag} ${_country.dialCode}',
                style: t.bodyLarge?.copyWith(color: AppColors.onBackground),
              ),
              const Icon(Icons.arrow_drop_down, color: AppColors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _phoneField() {
    return TextField(
      controller: _phone,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      autofillHints: const <String>[AutofillHints.telephoneNumberNational],
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9 \-]')),
        LengthLimitingTextInputFormatter(18),
      ],
      onChanged: _revalidate,
      decoration: InputDecoration(
        labelText: 'Phone Number *',
        hintText: 'Phone number',
        errorText: _err(_phone),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    final Color accent = _isPrayer ? AppColors.primary : AppColors.secondary;

    return Scaffold(
      appBar: GradientAppBar(title: _isPrayer ? 'Prayer Request' : 'Song Request'),
      body: SafeArea(
        top: false,
        child: AbsorbPointer(
          absorbing: _sending,
          child: PageBody(
            maxWidth: 640,
            children: <Widget>[
              Text(
                _isPrayer
                    ? 'Share your prayer request with us and we will lift you up in prayer'
                    : 'Request your favorite Christian song and dedicate it to someone special',
                textAlign: TextAlign.center,
                style: t.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              SectionCard(
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      TextField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const <String>[AutofillHints.name],
                        onChanged: _revalidate,
                        decoration: InputDecoration(
                          labelText: _isPrayer ? 'Name *' : 'Your Name *',
                          hintText: 'Enter your name',
                          prefixIcon: const Icon(Icons.person_outline),
                          errorText: _err(_name),
                        ),
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints c) {
                          final double scale = MediaQuery.textScalerOf(context).scale(16) / 16;
                          final Widget country = _countryButton(t);
                          final Widget phone = _phoneField();
                          if (c.maxWidth < 280 * scale) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[country, const SizedBox(height: 14), phone],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              country,
                              const SizedBox(width: 10),
                              Expanded(child: phone),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _location,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Location (${_country.name})',
                          hintText: "where you're listening from",
                          prefixIcon: const Icon(Icons.location_on_outlined),
                        ),
                      ),
                      if (!_isPrayer) ...<Widget>[
                        const SizedBox(height: 14),
                        TextField(
                          controller: _songTitle,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Song Title',
                            hintText: 'Enter song title',
                            prefixIcon: Icon(Icons.music_note_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _artist,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Artist',
                            hintText: 'Enter artist name',
                            prefixIcon: Icon(Icons.mic_none_outlined),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      TextField(
                        controller: _message,
                        minLines: 4,
                        maxLines: 8,
                        maxLength: 1000,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        onChanged: _revalidate,
                        decoration: InputDecoration(
                          labelText: _isPrayer ? 'Prayer Request *' : 'Message / Dedication *',
                          hintText: _isPrayer
                              ? 'Share your prayer request...'
                              : 'Who is this song for? / Your message',
                          alignLabelWithHint: true,
                          errorText: _err(_message),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: accent),
                        onPressed: _sending ? null : _submit,
                        icon: _sending
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          _sending
                              ? 'Sending…'
                              : (_isPrayer ? 'Submit Prayer Request' : 'Submit Song Request'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _sending ? null : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back to Selection'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Fields marked * are required. We do not collect, sell, or trade your personal information.',
                textAlign: TextAlign.center,
                style: t.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Searchable list of countries with dialling codes.
class CountryPickerDialog extends StatefulWidget {
  const CountryPickerDialog({super.key, required this.selected});
  final Country selected;

  @override
  State<CountryPickerDialog> createState() => _CountryPickerDialogState();
}

class _CountryPickerDialogState extends State<CountryPickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final String q = _query.trim().toLowerCase();
    final List<Country> list = q.isEmpty
        ? countries
        : countries
              .where((Country c) => c.name.toLowerCase().contains(q) || c.dialCode.contains(q))
              .toList();
    final Size size = MediaQuery.sizeOf(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 480, maxHeight: size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('Select Country', style: Theme.of(context).textTheme.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                autofocus: false,
                onChanged: (String v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Search country...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Flexible(
              child: list.isEmpty
                  ? const Padding(padding: EdgeInsets.all(24), child: Text('No matching country'))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: list.length,
                      itemBuilder: (BuildContext context, int i) {
                        final Country c = list[i];
                        final bool sel = c.name == widget.selected.name;
                        return ListTile(
                          leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                          title: Text(c.name),
                          trailing: Text(
                            c.dialCode,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          selected: sel,
                          selectedTileColor: AppColors.primaryContainer.withValues(alpha: 0.35),
                          onTap: () => Navigator.pop(context, c),
                        );
                      },
                    ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CLOSE'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: const GradientAppBar(title: 'Privacy Policy'),
      body: SafeArea(
        top: false,
        child: PageBody(
          children: <Widget>[
            const ScreenTitle('Privacy Policy'),
            for (final PolicySection s in privacyPolicy) ...<Widget>[
              Text(s.title, style: t.titleLarge?.copyWith(color: AppColors.primary)),
              const SizedBox(height: 6),
              Text(s.body, style: t.bodyLarge),
              const SizedBox(height: 18),
            ],
            Text(
              privacyLastUpdated,
              textAlign: TextAlign.center,
              style: t.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
