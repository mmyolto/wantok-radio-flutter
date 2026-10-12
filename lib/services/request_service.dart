import 'dart:async';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class RequestException implements Exception {
  const RequestException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Sends prayer and song requests to the studio's Google Sheet
/// (same Apps Script endpoint and fields as the original app).
class RequestService {
  RequestService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<void> submitPrayer({
    required String name,
    required String phone,
    required String location,
    required String request,
  }) {
    return _send(<String, String>{
      'type': 'prayer',
      'name': name,
      'phone': phone,
      'location': location,
      'request': request,
    });
  }

  Future<void> submitSong({
    required String name,
    required String phone,
    required String location,
    required String message,
    required String artist,
    required String songTitle,
  }) {
    return _send(<String, String>{
      'type': 'song',
      'name': name,
      'phone': phone,
      'location': location,
      'message': message,
      'artist': artist,
      'songTitle': songTitle,
    });
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
}
