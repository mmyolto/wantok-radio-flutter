import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

enum SubscribeResult { subscribed, alreadySubscribed }

class SubscribeException implements Exception {
  const SubscribeException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Free monthly news sign-up. Saves the email to Firestore "subscribers"
/// (document ID = the email, so nobody is added twice). The same list is used
/// by the website sign-up and is shown to admins on wantokradio.org/admin.html.
class SubscribeService {
  SubscribeService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static bool isValidEmail(String email) => _emailPattern.hasMatch(email.trim());

  Future<SubscribeResult> subscribe({required String email, String name = ''}) async {
    final String e = email.trim().toLowerCase();
    if (!isValidEmail(e)) throw const SubscribeException('Please enter a valid email address.');
    const String root = 'projects/${AppConfig.firebaseProjectId}/databases/(default)/documents';
    final String body = jsonEncode(<String, Object>{
      'writes': <Object>[
        <String, Object>{
          'update': <String, Object>{
            'name': '$root/subscribers/$e',
            'fields': <String, Object>{
              'email': <String, String>{'stringValue': e},
              'name': <String, String>{'stringValue': name.trim()},
              'source': <String, String>{'stringValue': 'app'},
            },
          },
          'currentDocument': <String, bool>{'exists': false},
          'updateTransforms': <Object>[
            <String, String>{'fieldPath': 'createdAt', 'setToServerValue': 'REQUEST_TIME'},
          ],
        },
      ],
    });
    final http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse('https://firestore.googleapis.com/v1/$root:commit'),
            headers: <String, String>{'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw const SubscribeException('The connection is too slow. Please try again.');
    } on Exception {
      throw const SubscribeException(
        'No internet connection. Please check your network and try again.',
      );
    }
    if (res.statusCode == 409) return SubscribeResult.alreadySubscribed;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw const SubscribeException('Sorry, that did not go through. Please try again.');
    }
    return SubscribeResult.subscribed;
  }
}
