import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wantok_radio_light/services/subscribe_service.dart';

void main() {
  group('Monthly news subscribe', () {
    test('email check', () {
      expect(SubscribeService.isValidEmail('mary@example.com'), isTrue);
      expect(SubscribeService.isValidEmail('  Mary@Example.org '), isTrue);
      expect(SubscribeService.isValidEmail('mary@example'), isFalse);
      expect(SubscribeService.isValidEmail('not an email'), isFalse);
    });

    test('new email is saved with ID = lower-case email and source "app"', () async {
      late Map<String, Object?> sent;
      final SubscribeService s = SubscribeService(
        client: MockClient((http.Request r) async {
          sent = jsonDecode(r.body) as Map<String, Object?>;
          return http.Response('{}', 200);
        }),
      );
      expect(
        await s.subscribe(email: ' Mary@Example.com ', name: 'Mary'),
        SubscribeResult.subscribed,
      );
      final String body = jsonEncode(sent);
      expect(body, contains('/subscribers/mary@example.com'));
      expect(body, contains('"source":{"stringValue":"app"}'));
      expect(body, contains('"exists":false'));
    });

    test('an email already on the list is reported, not an error', () async {
      final SubscribeService s = SubscribeService(
        client: MockClient((_) async => http.Response('{"error":{"code":409}}', 409)),
      );
      expect(await s.subscribe(email: 'mary@example.com'), SubscribeResult.alreadySubscribed);
    });

    test('server error gives a friendly message', () async {
      final SubscribeService s = SubscribeService(
        client: MockClient((_) async => http.Response('', 500)),
      );
      expect(s.subscribe(email: 'mary@example.com'), throwsA(isA<SubscribeException>()));
    });
  });
}
