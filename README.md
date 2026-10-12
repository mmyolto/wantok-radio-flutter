# Wantok Radio Light

[![Build & Release](https://github.com/mmyolto/wantok-radio-flutter/actions/workflows/build.yml/badge.svg)](https://github.com/mmyolto/wantok-radio-flutter/actions/workflows/build.yml)

Official live-radio app of **Wantok Radio Light — PNG Christian Broadcasting Network**,
built with Flutter for **Android** and **iOS** (phones and tablets).

- **Website:** https://wantokradio.org
- **Download (Android):** https://wantokradio.org/app.html
- **Package / bundle ID:** `org.wantokradiolight.www`

## Features

| Screen | What it does |
|---|---|
| Livestream | One-tap live stream, now-playing song, sleep timer, On-Demand link |
| Devotional | Daily devotionals from the Radio Chaplain; reminders at 5:00 am and 9:00 pm in the listener's own local time (push) |
| Program | Weekday schedule with the program on air now (PNG time, UTC+10) |
| Requests | Prayer and song requests sent to the studio's Google Sheet |
| About Us | Mission, vision, Facebook and website |
| Contact | SMS, WhatsApp, e-mail, call the office, map |
| Donation | Bible verse, why give, BSP and Kina Bank details (tap to copy) |
| FAQ | Common questions |

Built in:

- Daily devotional push notifications (Firebase Cloud Messaging topics) — setup:
  [docs/PUSH_NOTIFICATIONS.md](docs/PUSH_NOTIFICATIONS.md)
- Background playback with lock-screen, notification, headset and Bluetooth controls
- Pauses for phone calls, ducks for navigation prompts, stops when headphones are unplugged
- Always rejoins the live broadcast; backup stream and automatic reconnect
- Drawer on phones, navigation rail on tablets; portrait and landscape; large-text support
- Android adaptive and themed icons, Android 12+ splash, iOS icons and launch screen

## Project structure

```
lib/
  main.dart                     start-up, background audio service, push notifications
  firebase_options.dart         Firebase app IDs (fill in to switch on devotional push)
  app.dart                      app shell, theme, splash
  config/app_config.dart        station settings: stream, phone numbers, links, switches
  data/                         schedule, FAQ, mission, banks, countries, privacy text
  audio/radio_audio_handler.dart  live-stream engine
  services/                     now-playing API, requests, devotionals, push notifications
  screens/                      one file per screen
  widgets/                      shared UI
  theme/                        colours and fonts
test/                           unit and layout tests (8 screen sizes, large text)
assets/                         images and fonts
android/ ios/                   platform projects
store_assets/                   store icons, feature graphic, privacy page
docs/                           setup and store guides
.github/workflows/build.yml     CI: analyze, test, build, publish release
codemagic.yaml                  signed iOS / Android builds without a Mac
```

Station details are changed in **`lib/config/app_config.dart`**; screen text in
**`lib/data/station_content.dart`**.

## Development

Requirements: Flutter stable **3.38 or newer** (latest stable recommended), JDK 17, Android
Studio for Android, Xcode 16+ on a Mac for iOS.

```bash
flutter pub get
flutter run        # phone or emulator
flutter analyze
flutter test
```

If the tools report a problem with the `android/` or `ios/` folder, run `flutter create .`
once — it only adds missing files.

## Releasing

| Where | How |
|---|---|
| GitHub + website download | Push to `main`. GitHub Actions builds, signs and publishes a Release with `WantokRadioLight.apk`. One-time setup: [docs/GITHUB_SETUP.md](docs/GITHUB_SETUP.md) |
| Google Play | Upload the `*-googleplay.aab` from the Release to Play Console |
| App Store | Codemagic (`codemagic.yaml`, no Mac needed) or `flutter build ipa` on a Mac |

Store text, privacy answers and review notes: [docs/STORE_LISTING.md](docs/STORE_LISTING.md).

For every new version, raise `version:` in `pubspec.yaml` (the number after `+` must always
go up) and add a line to [CHANGELOG.md](CHANGELOG.md).

### Signing

Android releases are signed with the station's upload key, kept **outside** this repository
and supplied to CI as GitHub secrets (`ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`,
`ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS`). For local release builds, create
`android/key.properties` (git-ignored):

```properties
storePassword=…
keyPassword=…
keyAlias=upload
storeFile=upload-keystore.jks   # placed in android/app/
```

Every update must be signed with the same key.

## Before the first store submission

- [ ] `privacy.html` uploaded to https://wantokradio.org/privacy.html
- [ ] Screenshots taken on a phone and a tablet
- [ ] Data safety (Play) and App Privacy (Apple) forms filled from `docs/STORE_LISTING.md`
- [ ] After App Store approval, set `AppConfig.appStoreUrl`
- [ ] Devotional push set up: app IDs in `lib/firebase_options.dart`, APNs key in Firebase,
      Push Notifications capability on the App ID ([docs/PUSH_NOTIFICATIONS.md](docs/PUSH_NOTIFICATIONS.md))
- [ ] Card/PayPal donations stay hidden (`AppConfig.showOnlineDonation = false`) until online giving is live

## Credits

Built & Design: **Meltronics Info-Tech**, Port Moresby.

## Licence

© 2026 Wantok Radio Light. All rights reserved — see [LICENSE](LICENSE).
