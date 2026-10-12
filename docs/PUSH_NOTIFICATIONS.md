# Daily devotional notifications

Listeners get a short devotional from the **Radio Chaplain** every day, at their **own local
time** wherever they live (daylight saving included):

| Notification | Local time | Topic |
|---|---|---|
| Morning Devotional | 5:00 am | `devotional-morning.<time zone>` e.g. `devotional-morning.Pacific.Port_Moresby` |
| Evening Devotional | 9:00 pm | `devotional-evening.<time zone>` |

```
Radio Chaplain ──writes──▶ chaplain.html ──▶ Firestore "devotionals"
                                                   │
app ──time zone──▶ Firestore "pushZones"           │
                         │                         │
        Cloud Function every 15 minutes ───────────┘
        (each zone at its own 5:00 am / 9:00 pm)
                         │ Firebase Cloud Messaging (topics per zone)
                         ▼
              Wantok Radio Light app on every phone
```

The backend (Cloud Functions, Firestore rules and the chaplain page) is in the
**4-daily-devotionals** folder of the complete package — follow its README first. This page
covers the app.

## What the app does

- **Devotional** page (second item in the menu): today's devotionals, the last three weeks, an
  offline copy, and sharing. It reads only devotionals that have been sent.
- One-time prompt after the first start: *"Turn on daily devotionals?"*. Each reminder can be
  switched on or off on the Devotional page.
- The app reads the phone's time zone (package `flutter_timezone`), adds it to `pushZones` and
  joins that zone's topics. When the app opens in a new time zone (travel), it moves the
  reminders to the new zone automatically.
- Tapping a notification opens that devotional. If the app is open, a banner appears instead.
- Android: notification channel **"Daily devotionals"** (created in `MainActivity.kt`), small icon
  `ic_stat_radio`, Android 13+ permission prompt.
- iOS: push entitlement (`Runner.entitlements`) and the *remote-notification* background mode.

Until the app IDs below are filled in, the app works normally and the reminder switches stay
hidden; the Devotional page still shows the devotionals.

## One-time setup (about 20 minutes, no Mac needed)

### 1. Register the apps in Firebase
Firebase Console → project **wantok-radio-light-81519** → ⚙ Project settings → *Your apps*:

1. **Add app → Android**, package name `org.wantokradiolight.www`, nickname "WRL Android".
   Skip the download and SDK steps. Copy the **App ID** (`1:953977170930:android:…`).
2. **Add app → iOS**, bundle ID `org.wantokradiolight.www`, nickname "WRL iOS". Skip the
   download and SDK steps. Copy the **App ID** (`1:953977170930:ios:…`).
3. Paste both into `lib/firebase_options.dart`:
   ```dart
   static const String androidAppId = '1:953977170930:android:…';
   static const String iosAppId = '1:953977170930:ios:…';
   ```
   Commit the change on GitHub (pencil icon → *Commit changes*). These IDs are not secret.

> If Firebase shows an *API key* error on the phone, the Web API key is restricted. Copy
> `current_key` from the Android `google-services.json` (and `API_KEY` from the iOS plist) into
> `androidApiKey` / `iosApiKey` in the same file.

### 2. Apple push key (iPhone and iPad only)
1. developer.apple.com → Certificates, IDs & Profiles → **Identifiers** →
   `org.wantokradiolight.www` → tick **Push Notifications** → Save.
2. **Keys** → **+** → name "WRL Push", tick **Apple Push Notifications service (APNs)** →
   Continue → Register → **Download** the `.p8` file (only once!). Note the **Key ID** and your
   **Team ID** (top-right of the page).
3. Firebase Console → Project settings → **Cloud Messaging** → *Apple app configuration* →
   **APNs Authentication Key → Upload** the `.p8`, Key ID and Team ID.
4. Codemagic picks up the push capability on the next iOS build. If that build says the
   profile is missing the *aps-environment* entitlement, delete the old App Store profile for
   `org.wantokradiolight.www` under **Profiles** in the Apple portal and run the build again —
   Codemagic then creates a new profile that includes push.

### 3. Build and test
1. Push to `main` — GitHub Actions builds the new APK (version 1.1.0).
2. Install it, open it, and tap **Turn On** in the *Daily Devotionals* prompt.
3. In `chaplain.html`, write today's devotional and press **Send now** (after 5:00 am your
   time) — the notification arrives within seconds. Each slot reaches a phone only once a day,
   so test on the evening slot if the morning one has already gone out.

## Notes
- Times follow each phone's own clock and time zone. If a phone's time zone can't be read, the
  app uses its UTC offset, and Port Moresby as a last resort.
- Notifications are sent to topics, so the station never stores phone numbers or tokens.
- On Android the person can change sound / pop-up for "Daily devotionals" in the phone's
  notification settings; on iPhone under Settings → Notifications → Wantok Radio Light.
