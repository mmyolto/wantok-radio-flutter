import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';

/// One part of the monthly News Letter (e.g. "From the Radio Chaplain").
@immutable
class NewsletterPart {
  const NewsletterPart({
    required this.title,
    this.stats = '',
    this.text = '',
    this.files = const <NewsletterFile>[],
  });

  final String title;
  final String stats;
  final String text;
  final List<NewsletterFile> files;
}

/// A photo or document attached to a part.
@immutable
class NewsletterFile {
  const NewsletterFile({required this.name, required this.url});

  final String name;
  final String url;

  bool get isImage => RegExp(r'\.(png|jpe?g|gif|webp)(\?|$)', caseSensitive: false).hasMatch(url) ||
      url.contains('/image/upload/');
}

/// A monthly News Letter published by the General Manager.
@immutable
class Newsletter {
  const Newsletter({
    required this.month,
    required this.title,
    required this.parts,
    this.publishedAt,
  });

  /// `YYYY-MM`.
  final String month;
  final String title;
  final List<NewsletterPart> parts;
  final DateTime? publishedAt;

  /// The General Manager's overview, used as a short preview.
  String get preview {
    for (final NewsletterPart p in parts) {
      if (p.text.isNotEmpty) return p.text;
    }
    return '';
  }

  /// Parses a `publicNewsletters` document from the Firestore REST API.
  static Newsletter? fromFirestore(Map<String, dynamic> doc) {
    final Object? rawFields = doc['fields'];
    if (rawFields is! Map<String, dynamic>) return null;
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

    final String month = str('month');
    if (!RegExp(r'^\d{4}-\d{2}$').hasMatch(month)) return null;

    final List<NewsletterPart> parts = <NewsletterPart>[];
    try {
      final Object? list = jsonDecode(str('json'));
      if (list is List<dynamic>) {
        for (final Object? p in list) {
          if (p is! Map<String, dynamic>) continue;
          String s(String k) => p[k] is String ? (p[k] as String).trim() : '';
          final List<NewsletterFile> files = <NewsletterFile>[
            if (p['files'] is List<dynamic>)
              for (final Object? f in p['files'] as List<dynamic>)
                if (f is Map<String, dynamic> &&
                    f['url'] is String &&
                    (f['url'] as String).startsWith('https://'))
                  NewsletterFile(
                    name: f['name'] is String ? f['name'] as String : 'File',
                    url: f['url'] as String,
                  ),
          ];
          parts.add(NewsletterPart(title: s('title'), stats: s('stats'), text: s('text'), files: files));
        }
      }
    } on FormatException {
      return null;
    }
    if (parts.isEmpty) return null;
    return Newsletter(
      month: month,
      title: str('title').isEmpty ? 'News Letter $month' : str('title'),
      parts: parts,
      publishedAt: time('publishedAt'),
    );
  }
}

/// Reads the monthly News Letters that appear in the app at the end of each
/// month (no phone number or email needed), and remembers which one the
/// listener has already seen.
class NewsletterService {
  static const String _base =
      'https://firestore.googleapis.com/v1/projects/${AppConfig.firebaseProjectId}'
      '/databases/(default)/documents';

  List<Newsletter>? _cache;

  /// Newest first.
  Future<List<Newsletter>> fetch({bool refresh = false}) async {
    final List<Newsletter>? cached = _cache;
    if (cached != null && !refresh) return cached;
    final http.Response res = await http
        .get(Uri.parse('$_base/publicNewsletters?pageSize=36'))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw HttpException('News Letters unavailable (${res.statusCode})');
    }
    final Object? body = jsonDecode(res.body);
    final List<Newsletter> list = <Newsletter>[
      if (body is Map<String, dynamic> && body['documents'] is List<dynamic>)
        for (final Object? d in body['documents'] as List<dynamic>)
          if (d is Map<String, dynamic>) ?Newsletter.fromFirestore(d),
    ]..sort((Newsletter a, Newsletter b) => b.month.compareTo(a.month));
    _cache = list;
    return list;
  }

  Future<Newsletter?> latest() async {
    final List<Newsletter> list = await fetch(refresh: true);
    return list.isEmpty ? null : list.first;
  }

  /// The newest News Letter if the listener hasn't opened it yet.
  Future<Newsletter?> unseen() async {
    try {
      final Newsletter? n = await latest();
      if (n == null) return null;
      final String? seen = await _readSeen();
      if (seen != null && seen.compareTo(n.month) >= 0) return null;
      return n;
    } on Object catch (e) {
      debugPrint('News Letter check failed: $e');
      return null;
    }
  }

  Future<void> markSeen(String month) async {
    try {
      final String? seen = await _readSeen();
      if (seen != null && seen.compareTo(month) >= 0) return;
      final File f = await _file();
      await f.writeAsString(jsonEncode(<String, String>{'seen': month}));
    } on Object catch (e) {
      debugPrint('Could not save News Letter state: $e');
    }
  }

  static Future<File> _file() async {
    final Directory dir = await getApplicationSupportDirectory();
    return File('${dir.path}/newsletter_seen.json');
  }

  Future<String?> _readSeen() async {
    try {
      final File f = await _file();
      if (!f.existsSync()) return null;
      final Object? j = jsonDecode(await f.readAsString());
      return j is Map<String, dynamic> && j['seen'] is String ? j['seen'] as String : null;
    } on Object {
      return null;
    }
  }
}
