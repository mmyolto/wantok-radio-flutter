# Changelog

All notable changes to the Wantok Radio Light app.
The version number matches `version:` in `pubspec.yaml`.

## 1.2.0 (build 16) — October 2026
- **Monthly News Letter in the app**: at the end of every month the station's News Letter appears for
  everyone who has the app — no phone number or email needed. A notification announces it, and the
  app shows it once on the next start (also when notifications are turned off)
- Monthly News page lists every News Letter; tap one to read it (photos and attachments included)
- Daily Devotional shows only today's two devotionals (morning and evening); yesterday's are no longer carried over
- Always portrait (upright) on every phone and tablet
- Targets Android 16 (API 36) for Google Play; build tooling updated

## 1.0.2 (build 15) — October 2026
- Monthly News sign-up: brighter gold Subscribe button for better contrast

## 1.0.1 (build 14) — October 2026
- **Monthly News**: free email sign-up for the station's monthly news, in the menu and on the About Us page
  (same subscriber list as the website, managed on wantokradio.org/admin.html)

## 1.1.0 (build 2) — October 2026
- **Daily Devotional** page: devotionals written by the Radio Chaplain, with an offline copy and sharing
- Optional devotional notifications at 5:00 am and 9:00 pm in each listener's own local time,
  wherever they live (Firebase Cloud Messaging, one topic per time zone); a one-time prompt offers
  them, each can be switched on or off on the Devotional page, and they follow the phone when
  the listener travels
- Tapping a notification opens that devotional; one that arrives while the app is open shows a banner
- Privacy policy and store answers updated for notifications

## 1.0.0 (build 1) — October 2026
First Flutter release for Android and iOS, replacing the earlier Android-only app.

- Live stream with background playback, lock-screen, notification, headset and Bluetooth controls
- Automatic reconnect, backup stream, pauses for phone calls, stops when headphones are unplugged
- "Now playing" song from the station server, sleep timer, On-Demand link
- Program schedule with the program on air now (PNG time)
- Prayer and song requests to the studio, with country-code picker
- About, Contact, Donation (bank transfer) and FAQ screens, privacy policy
- Phone and tablet layouts, portrait and landscape, large-text support
- "Built & Design: Meltronics Info-Tech" credit on the splash screen, menu and About Us
