import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_radio_light/data/countries.dart';
import 'package:wantok_radio_light/data/station_content.dart';
import 'package:wantok_radio_light/screens/about_screen.dart';
import 'package:wantok_radio_light/screens/contact_screen.dart';
import 'package:wantok_radio_light/screens/devotional_screen.dart';
import 'package:wantok_radio_light/screens/donation_screen.dart';
import 'package:wantok_radio_light/screens/faq_screen.dart';
import 'package:wantok_radio_light/screens/news_screen.dart';
import 'package:wantok_radio_light/screens/program_screen.dart';
import 'package:wantok_radio_light/screens/requests_screen.dart';
import 'package:wantok_radio_light/services/devotional_service.dart';
import 'package:wantok_radio_light/services/now_playing_service.dart';
import 'package:wantok_radio_light/services/push_service.dart';
import 'package:wantok_radio_light/theme/app_theme.dart';
import 'package:wantok_radio_light/utils/schedule.dart';

/// Screen sizes from a small phone up to a large tablet, both orientations.
const List<Size> sizes = <Size>[
  Size(320, 568), // iPhone SE (1st gen)
  Size(360, 640), // small Android
  Size(390, 844), // iPhone 14/15
  Size(430, 932), // large phone
  Size(844, 390), // phone landscape
  Size(768, 1024), // iPad portrait
  Size(1024, 768), // iPad landscape
  Size(1366, 1024), // iPad Pro landscape
];

const Devotional sampleDevotional = Devotional(
  id: '2026-10-13_morning',
  date: '2026-10-13',
  slot: DevotionalSlot.morning,
  title: 'New Every Morning',
  scripture: 'Lamentations 3:22-23',
  verse:
      'It is of the LORD’s mercies that we are not consumed, because his compassions fail '
      'not. They are new every morning: great is thy faithfulness.',
  message:
      'Whatever yesterday held, today begins with God’s mercy. Before the noise of the day, '
      'pause and thank Him for one new mercy you can see this morning.',
  prayer: 'Lord, thank you that your mercies are new today. Walk with me. Amen.',
  author: 'Radio Chaplain',
);

Widget wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: child),
);

void main() {
  group('Schedule', () {
    test('morning devotion on a weekday', () {
      // Monday 13 Oct 2025, 05:45 PNG time.
      final int i = currentProgramIndex(DateTime(2025, 10, 13, 5, 45));
      expect(weekdayPrograms[i].title, 'Morning Light Devotion');
    });

    test('overnight automation before 05:30', () {
      final int i = currentProgramIndex(DateTime(2025, 10, 14, 2, 10));
      expect(weekdayPrograms[i].title, startsWith('Automation'));
    });

    test('late evening', () {
      final int i = currentProgramIndex(DateTime(2025, 10, 15, 23, 59));
      expect(weekdayPrograms[i].title, 'Late Night Dedication');
    });

    test('weekend has no highlight', () {
      expect(currentProgramIndex(DateTime(2025, 10, 18, 9)), -1);
    });
  });

  group('Now playing parser', () {
    test('reads AzuraCast song, art and listen urls', () {
      final NowPlaying? np = NowPlaying.fromAzuraCast(<String, dynamic>{
        'station': <String, dynamic>{
          'listen_url': 'http://radio.kinect.com.pg/listen/wrl/radio.mp3',
          'mounts': <dynamic>[
            <String, dynamic>{'url': 'https://radio.kinect.com.pg/listen/wrl/radio.mp3'},
          ],
        },
        'now_playing': <String, dynamic>{
          'song': <String, dynamic>{
            'title': 'Amazing Grace',
            'artist': 'Choir',
            'art': 'https://radio.kinect.com.pg/api/station/wrl/art/abc.jpg',
          },
        },
        'live': <String, dynamic>{'is_live': false},
        'listeners': <String, dynamic>{'current': 12},
      });
      expect(np, isNotNull);
      expect(np!.display, 'Amazing Grace — Choir');
      expect(np.listeners, 12);
      expect(np.streamUrls, <String>['https://radio.kinect.com.pg/listen/wrl/radio.mp3']);
      expect(np.artUrl, isNotNull);
    });

    test('ignores placeholder art and tolerates missing fields', () {
      final NowPlaying? np = NowPlaying.fromAzuraCast(<String, dynamic>{
        'now_playing': <String, dynamic>{
          'song': <String, dynamic>{
            'text': 'Station ID',
            'art': 'https://x/static/img/generic_song.jpg/default',
          },
        },
      });
      expect(np!.display, 'Station ID');
      expect(np.artUrl, isNull);
      expect(NowPlaying.fromAzuraCast(<String, dynamic>{})!.hasSong, isFalse);
    });
  });

  group('Devotionals', () {
    test('reads sent devotionals from a Firestore runQuery response', () {
      final List<Devotional> list = DevotionalService.parseRunQuery(<dynamic>[
        <String, dynamic>{
          'document': <String, dynamic>{
            'name': 'projects/p/databases/(default)/documents/devotionals/2026-10-13_evening',
            'fields': <String, dynamic>{
              'title': <String, String>{'stringValue': 'Rest for the Weary'},
              'message': <String, String>{'stringValue': 'Come to Him tonight.'},
              'scripture': <String, String>{'stringValue': 'Matthew 11:28'},
              'slot': <String, String>{'stringValue': 'evening'},
              'date': <String, String>{'stringValue': '2026-10-13'},
              'status': <String, String>{'stringValue': 'sent'},
              'sentAt': <String, String>{'timestampValue': '2026-10-13T11:00:02.123Z'},
            },
          },
        },
        <String, dynamic>{'readTime': '2026-10-13T11:00:05Z'}, // empty result row
      ]);
      expect(list, hasLength(1));
      expect(list.single.id, '2026-10-13_evening');
      expect(list.single.slot, DevotionalSlot.evening);
      expect(list.single.sentAt, DateTime.utc(2026, 10, 13, 11, 0, 2, 123));
      expect(DevotionalService.parseRunQuery(<String, dynamic>{'error': 1}), isEmpty);
    });

    test('ignores drafts and incomplete documents', () {
      expect(
        Devotional.fromFirestore(<String, dynamic>{
          'name': 'x/devotionals/a',
          'fields': <String, dynamic>{
            'title': <String, String>{'stringValue': 'Draft'},
            'message': <String, String>{'stringValue': 'Not yet'},
            'slot': <String, String>{'stringValue': 'morning'},
            'status': <String, String>{'stringValue': 'draft'},
          },
        }),
        isNull,
      );
    });

    test('offline copy round-trips', () {
      final Devotional? d = Devotional.fromJson(sampleDevotional.toJson());
      expect(d?.title, sampleDevotional.title);
      expect(d?.slot, DevotionalSlot.morning);
      expect(sampleDevotional.toShareText(), contains('Lamentations 3:22-23'));
    });

    test('time zone topics match the Cloud Functions', () {
      expect(
        PushService.topicFor(DevotionalSlot.morning, 'Pacific/Port_Moresby'),
        'devotional-morning.Pacific.Port_Moresby',
      );
      expect(PushService.zoneKey('Etc/GMT+10'), 'Etc.GMT~10');
      expect(PushService.zoneFromOffset(const Duration(hours: 10)), 'Etc/GMT-10');
      expect(PushService.zoneFromOffset(const Duration(hours: -5)), 'Etc/GMT+5');
      expect(PushService.zoneFromOffset(Duration.zero), 'Etc/UTC');
    });

    test('day labels', () {
      final DateTime today = DateTime(2026, 10, 13, 5);
      expect(devotionalDayLabel('2026-10-13', today: today), 'Today');
      expect(devotionalDayLabel('2026-10-12', today: today), 'Yesterday');
      expect(devotionalDayLabel('2026-10-09', today: today), 'Fri 9 Oct');
    });
  });

  test('Papua New Guinea is in the country list', () {
    expect(countries.where((Country c) => c.name == defaultCountryName), hasLength(1));
  });

  group('Screens render without overflow on every screen size', () {
    final Map<String, Widget Function()> screens = <String, Widget Function()>{
      'Devotional': () => const DevotionalScreen(),
      'Devotional page': () => const DevotionalBody(devotional: sampleDevotional, onShare: _noop),
      'Devotional card': () => ListView(
        children: const <Widget>[
          DevotionalCard(devotional: sampleDevotional, featured: true),
          DevotionalCard(devotional: sampleDevotional),
        ],
      ),
      'Program': () => const ProgramScreen(),
      'Requests': () => const RequestsScreen(),
      'About': () => const AboutScreen(),
      'Contact': () => const ContactScreen(),
      'Donation': () => const DonationScreen(),
      'FAQ': () => const FaqScreen(),
      'Monthly News': () => const NewsScreen(),
      'Prayer form': () => const RequestFormPage(kind: RequestKind.prayer),
      'Song form': () => const RequestFormPage(kind: RequestKind.song),
      'Privacy': () => const PrivacyPolicyPage(),
    };

    for (final MapEntry<String, Widget Function()> s in screens.entries) {
      for (final Size size in sizes) {
        for (final double scale in <double>[1.0, 1.6]) {
          testWidgets('${s.key} @ ${size.width.toInt()}x${size.height.toInt()} text x$scale', (
            WidgetTester tester,
          ) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1.0;
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(tester.view.reset);
            addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

            await tester.pumpWidget(wrap(s.value()));
            await tester.pump(const Duration(milliseconds: 300));
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  });
}

void _noop() {}
