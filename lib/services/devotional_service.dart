import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';

/// The two daily devotional times (in each listener's local time).
enum DevotionalSlot {
  morning('Morning Devotional', '5:00 am'),
  evening('Evening Devotional', '9:00 pm');

  const DevotionalSlot(this.label, this.time);

  final String label;
  final String time;

  static DevotionalSlot? tryParse(String? value) {
    for (final DevotionalSlot s in values) {
      if (s.name == value) return s;
    }
    return null;
  }
}

/// A devotional written by the Radio Chaplain.
@immutable
class Devotional {
  const Devotional({
    required this.id,
    required this.date,
    required this.slot,
    required this.title,
    required this.message,
    this.scripture = '',
    this.verse = '',
    this.prayer = '',
    this.author = '',
    this.sentAt,
  });

  final String id;

  /// PNG date, `YYYY-MM-DD`.
  final String date;
  final DevotionalSlot slot;
  final String title;
  final String scripture;
  final String verse;
  final String message;
  final String prayer;
  final String author;
  final DateTime? sentAt;

  /// Parses a document from the Firestore REST API
  /// (`{name, fields: {title: {stringValue: …}}}`).
  static Devotional? fromFirestore(Map<String, dynamic> doc) {
    final Object? rawFields = doc['fields'];
    final String name = doc['name'] is String ? doc['name'] as String : '';
    if (rawFields is! Map<String, dynamic> || name.isEmpty) return null;
    String str(String key) {
      final Object? v = rawFields[key];
      return v is Map<String, dynamic> && v['stringValue'] is String
          ? (v['stringValue'] as String).trim()
          : '';
    }

    DateTime? time(String key) {
      final Object? v = rawFields[key];
      return v is Map<String, dynamic> && v['timestampValue'] is String
          ? DateTime.tryParse(v['timestampValue'] as String)
          : null;
    }

    final DevotionalSlot? slot = DevotionalSlot.tryParse(str('slot'));
    final String title = str('title');
    final String message = str('message');
    if (slot == null || title.isEmpty || message.isEmpty || str('status') != 'sent') return null;
    return Devotional(
      id: name.substring(name.lastIndexOf('/') + 1),
      date: str('date'),
      slot: slot,
      title: title,
      scripture: str('scripture'),
      verse: str('verse'),
      message: message,
      prayer: str('prayer'),
      author: str('author'),
      sentAt: time('sentAt'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'date': date,
    'slot': slot.name,
    'title': title,
    'scripture': scripture,
    'verse': verse,
    'message': message,
    'prayer': prayer,
    'author': author,
    'sentAt': sentAt?.toIso8601String(),
  };

  static Devotional? fromJson(Map<String, dynamic> j) {
    final DevotionalSlot? slot = DevotionalSlot.tryParse(j['slot'] as String?);
    if (slot == null || j['id'] is! String || j['title'] is! String || j['message'] is! String) {
      return null;
    }
    String s(String k) => j[k] is String ? j[k] as String : '';
    return Devotional(
      id: j['id'] as String,
      date: s('date'),
      slot: slot,
      title: j['title'] as String,
      scripture: s('scripture'),
      verse: s('verse'),
      message: j['message'] as String,
      prayer: s('prayer'),
      author: s('author'),
      sentAt: DateTime.tryParse(s('sentAt')),
    );
  }

  /// Plain text for sharing.
  String toShareText() {
    final StringBuffer b = StringBuffer()
      ..writeln('${slot.label}: $title')
      ..writeln();
    if (verse.isNotEmpty) b.writeln('“$verse”${scripture.isEmpty ? '' : ' — $scripture'}\n');
    if (verse.isEmpty && scripture.isNotEmpty) b.writeln('$scripture\n');
    b.writeln(message);
    if (prayer.isNotEmpty) b.writeln('\nPrayer: $prayer');
    if (author.isNotEmpty) b.writeln('\n— $author');
    b
      ..writeln()
      ..write('${AppConfig.appName} · ${AppConfig.websiteUrl}');
    return b.toString();
  }
}

/// Thrown when devotionals can't be loaded (offline, server error).
class DevotionalException implements Exception {
  const DevotionalException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Reads sent devotionals from Firestore (public, read-only REST API — no
/// sign-in needed) and keeps the latest list for offline reading.
class DevotionalService {
  DevotionalService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 15);
  static const String _base =
      'https://firestore.googleapis.com/v1/projects/${AppConfig.firebaseProjectId}'
      '/databases/(default)/documents';

  /// Latest devotionals, newest first.
  Future<List<Devotional>> fetchRecent({int limit = 21}) async {
    final Map<String, dynamic> query = <String, dynamic>{
      'structuredQuery': <String, dynamic>{
        'from': <Map<String, dynamic>>[
          <String, dynamic>{'collectionId': 'devotionals'},
        ],
        'where': <String, dynamic>{
          'fieldFilter': <String, dynamic>{
            'field': <String, String>{'fieldPath': 'status'},
            'op': 'EQUAL',
            'value': <String, String>{'stringValue': 'sent'},
          },
        },
        'orderBy': <Map<String, dynamic>>[
          <String, dynamic>{
            'field': <String, String>{'fieldPath': 'sentAt'},
            'direction': 'DESCENDING',
          },
        ],
        'limit': limit,
      },
    };
    final http.Response res = await _request(
      () => _client.post(
        Uri.parse('$_base:runQuery'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(query),
      ),
    );
    final List<Devotional> list = parseRunQuery(_decode(res));
    unawaited(_saveCache(list));
    return list;
  }

  /// One devotional (opened from a notification). Uses the offline copy when
  /// the phone can't reach the server.
  Future<Devotional> fetchById(String id) async {
    try {
      final http.Response res = await _request(
        () => _client.get(Uri.parse('$_base/devotionals/${Uri.encodeComponent(id)}')),
      );
      final Object? body = _decode(res);
      final Devotional? d = body is Map<String, dynamic> ? Devotional.fromFirestore(body) : null;
      if (d == null) throw const DevotionalException('This devotional is not available.');
      return d;
    } on DevotionalException {
      for (final Devotional d in await loadCache()) {
        if (d.id == id) return d;
      }
      rethrow;
    }
  }

  /// Parses a Firestore `runQuery` response.
  @visibleForTesting
  static List<Devotional> parseRunQuery(Object? body) {
    if (body is! List) return const <Devotional>[];
    return <Devotional>[
      for (final Object? row in body)
        if (row is Map<String, dynamic> && row['document'] is Map<String, dynamic>)
          ?Devotional.fromFirestore(row['document'] as Map<String, dynamic>),
    ];
  }

  static Object? _decode(http.Response res) {
    try {
      return jsonDecode(utf8.decode(res.bodyBytes));
    } on FormatException {
      throw const DevotionalException('Devotionals are not available right now.');
    }
  }

  Future<http.Response> _request(Future<http.Response> Function() send) async {
    final http.Response res;
    try {
      res = await send().timeout(_timeout);
    } on TimeoutException {
      throw const DevotionalException('The connection is slow. Please try again.');
    } on Exception {
      throw const DevotionalException('No internet connection. Please try again.');
    }
    if (res.statusCode == 404) {
      throw const DevotionalException('This devotional is not available.');
    }
    if (res.statusCode != 200) {
      throw DevotionalException('Devotionals are not available right now (${res.statusCode}).');
    }
    return res;
  }

  // ---------------------------------------------------------------------------
  // Offline copy
  // ---------------------------------------------------------------------------

  Future<File> _cacheFile() async {
    final Directory dir = await getApplicationSupportDirectory();
    return File('${dir.path}/devotionals.json');
  }

  Future<List<Devotional>> loadCache() async {
    try {
      final File f = await _cacheFile();
      if (!f.existsSync()) return const <Devotional>[];
      final Object? data = jsonDecode(await f.readAsString());
      if (data is! List) return const <Devotional>[];
      return <Devotional>[
        for (final Object? j in data)
          if (j is Map<String, dynamic>) ?Devotional.fromJson(j),
      ];
    } on Object {
      return const <Devotional>[];
    }
  }

  Future<void> _saveCache(List<Devotional> list) async {
    try {
      final File f = await _cacheFile();
      await f.writeAsString(
        jsonEncode(<Map<String, dynamic>>[for (final Devotional d in list) d.toJson()]),
      );
    } on Object catch (e) {
      debugPrint('Could not cache devotionals: $e');
    }
  }
}
