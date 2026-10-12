import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';

/// Opens links, dialers, SMS, e-mail and WhatsApp, with a friendly message
/// when the device has no app that can handle the action.
class Launch {
  Launch._();

  static Future<void> web(BuildContext context, String url) =>
      _open(context, Uri.parse(url), 'Could not open the link.');

  static Future<void> call(BuildContext context, String number) =>
      _open(context, Uri(scheme: 'tel', path: number), 'Calling is not available on this device.');

  static Future<void> sms(BuildContext context, String number) =>
      _open(context, Uri(scheme: 'sms', path: number), 'No messaging app found.');

  static Future<void> whatsApp(BuildContext context, String number) {
    final String digits = number.replaceAll(RegExp(r'[^0-9]'), '');
    return _open(context, Uri.parse('https://wa.me/$digits'), 'Could not open WhatsApp.');
  }

  static Future<void> email(BuildContext context, String address, {String? subject}) {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: address,
      query: subject == null ? null : 'subject=${Uri.encodeComponent(subject)}',
    );
    return _open(context, uri, 'No e-mail app found. Write to us at $address');
  }

  static Future<void> map(BuildContext context) {
    final String q = Uri.encodeComponent(
      '${AppConfig.appName}, ${AppConfig.addressLine1}, ${AppConfig.addressLine2}',
    );
    return _open(
      context,
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$q'),
      'Could not open maps.',
    );
  }

  static Future<void> _open(BuildContext context, Uri uri, String failMessage) async {
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
    bool ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok) {
      messenger?.showSnackBar(SnackBar(content: Text(failMessage)));
    }
  }
}
