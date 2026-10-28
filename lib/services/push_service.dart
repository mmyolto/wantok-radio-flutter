import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';
import '../firebase_options.dart';
import 'devotional_service.dart';

/// What to open after a devotional notification is tapped.
@immutable
class DevotionalOpenRequest {
  const DevotionalOpenRequest({this.id, this.slot, this.title, this.body});

  /// Firestore document ID; `null` for a Bible-verse notification.
  final String? id;
  final DevotionalSlot? slot;
  final String? title;
  final String? body;

  static DevotionalOpenRequest? fromMessage(RemoteMessage m) {
    if (m.data['type'] != 'devotional') return null;
    final Object? id = m.data['id'];
    return DevotionalOpenRequest(
      id: id is String && id.isNotEmpty ? id : null,
      slot: DevotionalSlot.tryParse(m.data['slot'] as String?),
      title: m.notification?.title,
      body: m.notification?.body,
    );
  }
}

/// Reminder settings shown on the Devotional screen.
@immutable
class ReminderState {
  const ReminderState({
    this.available = false,
    this.morning = false,
    this.evening = false,
    this.blocked = false,
    this.busy = false,
  });

  /// Firebase is set up on this build and the device supports push.
  final bool available;
  final bool morning;
  final bool evening;

  /// The person turned notifications off in the phone's settings.
  final bool blocked;
  final bool busy;

  bool isOn(DevotionalSlot s) => s == DevotionalSlot.morning ? morning : evening;

  ReminderState copyWith({
    bool? available,
    bool? morning,
    bool? evening,
    bool? blocked,
    bool? busy,
  }) {
    return ReminderState(
      available: available ?? this.available,
      morning: morning ?? this.morning,
      evening: evening ?? this.evening,
      blocked: blocked ?? this.blocked,
      busy: busy ?? this.busy,
    );
  }
}

/// Daily devotional push notifications at 5:00 am and 9:00 pm in the
/// listener's OWN local time.
///
/// The phone reports its time zone (e.g. "Australia/Brisbane") to the
/// `pushZones` list and joins one topic per slot for that zone, e.g.
/// `devotional-morning.Australia.Brisbane`. The Cloud Function sends to each
/// zone when it reaches 5:00 am / 9:00 pm there. If the listener travels, the
/// next time the app opens it moves to the new zone's topics.
///
/// Notification taps become [openRequests] for the UI.
class PushService {
  final ValueNotifier<ReminderState> state = ValueNotifier<ReminderState>(const ReminderState());

  /// Set when a devotional notification is tapped (consumed by the home shell).
  final ValueNotifier<DevotionalOpenRequest?> openRequests = ValueNotifier<DevotionalOpenRequest?>(
    null,
  );

  /// Month (`YYYY-MM`) of a News Letter notification that was tapped, or that
  /// arrived while the app is open.
  final ValueNotifier<String?> newsletterRequests = ValueNotifier<String?>(null);

  /// Devotionals that arrive while the app is open (shown as an in-app banner).
  final StreamController<DevotionalOpenRequest> _foreground =
      StreamController<DevotionalOpenRequest>.broadcast();
  Stream<DevotionalOpenRequest> get foregroundMessages => _foreground.stream;

  FirebaseMessaging? _messaging;
  _Prefs _prefs = const _Prefs();
  Future<void>? _syncing;
  bool _resyncNeeded = false;

  bool get available => state.value.available;

  /// Show the one-time "turn on daily devotionals?" prompt.
  bool get shouldOfferPrompt => available && !_prefs.asked;

  /// Topic suffix for a time zone — must match `zoneKey()` in the Cloud
  /// Functions and the `pushZones` rule ("/" → ".", "+" → "~").
  @visibleForTesting
  static String zoneKey(String zone) => zone.replaceAll('/', '.').replaceAll('+', '~');

  static String topicFor(DevotionalSlot s, String zone) =>
      '${s == DevotionalSlot.morning ? AppConfig.morningDevotionalTopic : AppConfig.eveningDevotionalTopic}'
      '.${zoneKey(zone)}';

  static final RegExp _validZone = RegExp(r'^[A-Za-z0-9_+/-]{1,64}$');

  /// IANA zone from a fixed UTC offset ("Etc/GMT-10" means UTC+10).
  @visibleForTesting
  static String zoneFromOffset(Duration offset) {
    if (offset.inMinutes % 60 != 0) return AppConfig.homeTimeZone;
    final int h = offset.inHours;
    if (h == 0) return 'Etc/UTC';
    return h > 0 ? 'Etc/GMT-$h' : 'Etc/GMT+${-h}';
  }

  /// The phone's time zone, e.g. "Pacific/Port_Moresby".
  static Future<String> _deviceZone() async {
    try {
      final String id = (await FlutterTimezone.getLocalTimezone()).identifier;
      if (_validZone.hasMatch(id)) return id;
    } on Object catch (e) {
      debugPrint('Time zone lookup failed: $e');
    }
    return zoneFromOffset(DateTime.now().timeZoneOffset);
  }

  /// Adds the zone to the server's list so the function knows to send there.
  Future<bool> _registerZone(String zone) async {
    final Uri uri = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/${AppConfig.firebaseProjectId}'
      '/databases/(default)/documents/pushZones/${Uri.encodeComponent(zoneKey(zone))}',
    );
    try {
      final http.Response res = await http
          .patch(
            uri,
            headers: <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(<String, Object>{
              'fields': <String, Object>{
                'zone': <String, String>{'stringValue': zone},
              },
            }),
          )
          .timeout(const Duration(seconds: 20));
      return res.statusCode == 200;
    } on Object catch (e) {
      debugPrint('Could not register time zone: $e');
      return false;
    }
  }

  /// Re-checks the time zone (e.g. after travelling) — call when the app returns
  /// to the foreground. Does nothing when nothing changed.
  Future<void> resync() => _sync();

  /// Starts Firebase. Safe to call when Firebase isn't configured — the
  /// feature just stays hidden.
  Future<void> init() async {
    final FirebaseOptions? options = DefaultFirebaseOptions.currentPlatform;
    if (options == null) return;
    try {
      await Firebase.initializeApp(options: options).timeout(const Duration(seconds: 15));
      final FirebaseMessaging m = FirebaseMessaging.instance;
      if (!await m.isSupported()) return;
      _messaging = m;
      _prefs = await _Prefs.load();

      // We show our own banner while the app is open.
      await m.setForegroundNotificationPresentationOptions();

      FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
        if (msg.data['type'] == 'newsletter') {
          newsletterRequests.value = msg.data['month'] as String? ?? '';
          return;
        }
        final DevotionalOpenRequest? r = DevotionalOpenRequest.fromMessage(msg);
        if (r != null) _foreground.add(r);
      });
      FirebaseMessaging.onMessageOpenedApp.listen(_opened);
      final RemoteMessage? initial = await m.getInitialMessage();
      if (initial != null) _opened(initial);
      // A new registration (e.g. after restoring the phone) loses topics — rejoin.
      m.onTokenRefresh.listen((_) => _sync(force: true));

      final NotificationSettings ns = await m.getNotificationSettings();
      state.value = ReminderState(
        available: true,
        morning: _prefs.morning,
        evening: _prefs.evening,
        blocked: _prefs.asked && ns.authorizationStatus == AuthorizationStatus.denied,
      );
      unawaited(_sync());
    } on Object catch (e) {
      debugPrint('Push notifications unavailable: $e');
    }
  }

  void _opened(RemoteMessage msg) {
    if (msg.data['type'] == 'newsletter') {
      newsletterRequests.value = msg.data['month'] as String? ?? '';
      return;
    }
    final DevotionalOpenRequest? r = DevotionalOpenRequest.fromMessage(msg);
    if (r != null) openRequests.value = r;
  }

  /// Called after the listener answers the first-run prompt.
  Future<void> answerPrompt({required bool accept}) async {
    _prefs = _prefs.copyWith(asked: true);
    await _prefs.save();
    if (accept) {
      await setBoth(true);
    }
  }

  /// Turns one reminder on or off. Returns false if the phone blocks notifications.
  Future<bool> setSlot(DevotionalSlot slot, bool on) async {
    if (!available) return false;
    if (on && !await _ensurePermission()) return false;
    _prefs = _prefs.copyWith(
      asked: true,
      morning: slot == DevotionalSlot.morning ? on : null,
      evening: slot == DevotionalSlot.evening ? on : null,
    );
    await _prefs.save();
    state.value = state.value.copyWith(morning: _prefs.morning, evening: _prefs.evening);
    unawaited(_sync());
    return true;
  }

  Future<bool> setBoth(bool on) async {
    if (!available) return false;
    if (on && !await _ensurePermission()) return false;
    _prefs = _prefs.copyWith(asked: true, morning: on, evening: on);
    await _prefs.save();
    state.value = state.value.copyWith(morning: on, evening: on);
    unawaited(_sync());
    return true;
  }

  Future<bool> _ensurePermission() async {
    final FirebaseMessaging? m = _messaging;
    if (m == null) return false;
    state.value = state.value.copyWith(busy: true);
    try {
      final NotificationSettings s = await m.requestPermission();
      final bool ok =
          s.authorizationStatus == AuthorizationStatus.authorized ||
          s.authorizationStatus == AuthorizationStatus.provisional;
      state.value = state.value.copyWith(blocked: !ok, busy: false);
      return ok;
    } on Object catch (e) {
      debugPrint('Notification permission request failed: $e');
      state.value = state.value.copyWith(busy: false);
      return false;
    }
  }

  /// Brings the topic subscriptions in line with the switches. Runs one at a
  /// time; anything that fails (offline) is retried on the next launch.
  Future<void> _sync({bool force = false}) async {
    if (_syncing != null) {
      _resyncNeeded = true;
      return _syncing;
    }
    _syncing = _doSync(force: force);
    try {
      await _syncing;
    } finally {
      _syncing = null;
    }
    if (_resyncNeeded) {
      _resyncNeeded = false;
      await _sync();
    }
  }

  Future<void> _doSync({required bool force}) async {
    final FirebaseMessaging? m = _messaging;
    if (m == null) return;

    final String zone = await _deviceZone();
    final bool devotionals = _prefs.asked && (_prefs.morning || _prefs.evening);
    final Set<String> wanted = <String>{
      // Everyone gets the monthly News Letter — no phone number or email needed.
      AppConfig.newsletterTopic,
      if (_prefs.asked && _prefs.morning) topicFor(DevotionalSlot.morning, zone),
      if (_prefs.asked && _prefs.evening) topicFor(DevotionalSlot.evening, zone),
    };
    if (devotionals && _prefs.registeredZone != zone && await _registerZone(zone)) {
      _prefs = _prefs.copyWith(registeredZone: zone);
      await _prefs.save();
    }

    final Set<String> toJoin = force ? wanted : wanted.difference(_prefs.subscribed);
    final Set<String> toLeave = _prefs.subscribed.difference(wanted);
    if (toJoin.isEmpty && toLeave.isEmpty) return;
    if (!kIsWeb && Platform.isIOS && !await _waitForApnsToken(m)) return;

    for (final String topic in toLeave) {
      try {
        await m.unsubscribeFromTopic(topic).timeout(const Duration(seconds: 20));
        _prefs = _prefs.withSubscribed(topic, false);
        await _prefs.save();
      } on Object catch (e) {
        debugPrint('Could not leave $topic: $e');
      }
    }
    for (final String topic in toJoin) {
      try {
        await m.subscribeToTopic(topic).timeout(const Duration(seconds: 20));
        _prefs = _prefs.withSubscribed(topic, true);
        await _prefs.save();
      } on Object catch (e) {
        debugPrint('Could not join $topic: $e');
      }
    }
  }

  /// iOS can only join topics once Apple has issued a push token.
  Future<bool> _waitForApnsToken(FirebaseMessaging m) async {
    for (int i = 0; i < 10; i++) {
      try {
        if (await m.getAPNSToken() != null) return true;
      } on Object {
        // not ready yet
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    return false;
  }
}

/// Saved reminder choices (a small JSON file; no extra plugin needed).
@immutable
class _Prefs {
  const _Prefs({
    this.asked = false,
    this.morning = false,
    this.evening = false,
    this.subscribed = const <String>{},
    this.registeredZone,
  });

  final bool asked;
  final bool morning;
  final bool evening;

  /// Topics this phone has successfully joined.
  final Set<String> subscribed;

  /// Time zone last added to the server's list.
  final String? registeredZone;

  _Prefs copyWith({bool? asked, bool? morning, bool? evening, String? registeredZone}) => _Prefs(
    asked: asked ?? this.asked,
    morning: morning ?? this.morning,
    evening: evening ?? this.evening,
    subscribed: subscribed,
    registeredZone: registeredZone ?? this.registeredZone,
  );

  _Prefs withSubscribed(String topic, bool on) => _Prefs(
    asked: asked,
    morning: morning,
    evening: evening,
    subscribed: on ? <String>{...subscribed, topic} : (<String>{...subscribed}..remove(topic)),
    registeredZone: registeredZone,
  );

  static Future<File> _file() async {
    final Directory dir = await getApplicationSupportDirectory();
    return File('${dir.path}/devotional_reminders.json');
  }

  static Future<_Prefs> load() async {
    try {
      final File f = await _file();
      if (!f.existsSync()) return const _Prefs();
      final Object? j = jsonDecode(await f.readAsString());
      if (j is! Map<String, dynamic>) return const _Prefs();
      return _Prefs(
        asked: j['asked'] == true,
        morning: j['morning'] == true,
        evening: j['evening'] == true,
        subscribed: <String>{
          if (j['subscribed'] is List)
            for (final Object? s in j['subscribed'] as List<dynamic>)
              if (s is String) s,
        },
        registeredZone: j['registeredZone'] is String ? j['registeredZone'] as String : null,
      );
    } on Object {
      return const _Prefs();
    }
  }

  Future<void> save() async {
    try {
      final File f = await _file();
      await f.writeAsString(
        jsonEncode(<String, Object>{
          'asked': asked,
          'morning': morning,
          'evening': evening,
          'subscribed': subscribed.toList(),
          'registeredZone': ?registeredZone,
        }),
      );
    } on Object catch (e) {
      debugPrint('Could not save reminder settings: $e');
    }
  }
}
