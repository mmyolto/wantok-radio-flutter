import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class RequestException implements Exception {
  const RequestException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Sends prayer and song requests to:
///  1. the studio's Google Sheet (same Apps Script endpoint and fields as the original app), and
///  2. the website database (Firestore "requests", source "app"), so they appear live on the
///     studio screen (Website & App column) and on the website for the Admin and Chaplain.
/// The request counts as sent if either one succeeds.
class RequestService {
  RequestService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<void> submitPrayer({
    required String name,
    required String phone,
    required String location,
    required String request,
  }) {
    return _submit(
      <String, String>{
        'type': 'prayer',
        'name': name,
        'phone': phone,
        'location': location,
        'request': request,
      },
      <String, String>{
        'type': 'prayer',
        'name': name,
        'phone': phone,
        'location': location,
        'message': request,
      },
    );
  }

  Future<void> submitSong({
    required String name,
    required String phone,
    required String location,
    required String message,
    required String artist,
    required String songTitle,
  }) {
    return _submit(
      <String, String>{
        'type': 'song',
        'name': name,
        'phone': phone,
        'location': location,
        'message': message,
        'artist': artist,
        'songTitle': songTitle,
      },
      <String, String>{
        'type': 'song',
        'name': name,
        'phone': phone,
        'location': location,
        'message': message.trim().isEmpty ? 'Song request: $songTitle' : message,
        'artist': artist,
        'songTitle': songTitle,
      },
    );
  }

  Future<void> _submit(Map<String, String> sheet, Map<String, String> website) async {
    final List<Object?> errors = await Future.wait<Object?>(<Future<Object?>>[
      _send(sheet).then<Object?>((_) => null, onError: (Object e) => e),
      _store(website).then<Object?>((_) => null, onError: (Object e) => e),
    ]);
    final Object? sheetError = errors[0];
    if (sheetError != null && errors[1] != null) {
      throw sheetError is RequestException
          ? sheetError
          : const RequestException('Submission failed. Please try again.');
    }
  }

  Future<void> _send(Map<String, String> params) async {
    final Uri uri = Uri.parse(AppConfig.requestsEndpoint).replace(queryParameters: params);
    final http.Response res;
    try {
      res = await _client.get(uri).timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw const RequestException('The connection is too slow. Please try again.');
    } on Exception {
      throw const RequestException(
        'No internet connection. Please check your network and try again.',
      );
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw const RequestException('Submission failed. Please try again.');
    }
  }

  /// Creates a document in Firestore "requests" (public "create only" in the database rules).
  Future<void> _store(Map<String, String> data) async {
    const String project = AppConfig.firebaseProjectId;
    const String root = 'projects/$project/databases/(default)/documents';
    final Map<String, Object> fields = <String, Object>{
      for (final MapEntry<String, String> e in <String, String>{
        ...data,
        'source': 'app',
        'status': 'new',
      }.entries)
        e.key: <String, String>{'stringValue': e.value.trim()},
    };
    final String body = jsonEncode(<String, Object>{
      'writes': <Object>[
        <String, Object>{
          'update': <String, Object>{'name': '$root/requests/${_newId()}', 'fields': fields},
          'currentDocument': <String, bool>{'exists': false},
          'updateTransforms': <Object>[
            <String, String>{'fieldPath': 'createdAt', 'setToServerValue': 'REQUEST_TIME'},
          ],
        },
      ],
    });
    final http.Response res = await _client
        .post(
          Uri.parse('https://firestore.googleapis.com/v1/$root:commit'),
          headers: <String, String>{'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 25));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw RequestException('Website save failed (${res.statusCode}).');
    }
  }

  static String _newId() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final Random r = Random.secure();
    return List<String>.generate(20, (_) => chars[r.nextInt(chars.length)]).join();
  }
}
