/// Central place for every station detail used by the app.
/// Change values here — no other file needs editing.
class AppConfig {
  AppConfig._();

  static const String appName = 'Wantok Radio Light';
  static const String tagline = 'Your Inspiration Station';
  static const String network = 'PNG Christian Broadcasting Network';

  // ---------------------------------------------------------------------------
  // Streaming
  // ---------------------------------------------------------------------------

  /// Main live stream (AzuraCast on radio.kinect.com.pg).
  static const String primaryStreamUrl = 'https://radio.kinect.com.pg/listen/wrl/radio.mp3';

  /// Backup streams tried in order if the main one fails.
  static const List<String> fallbackStreamUrls = <String>['https://ca7ssl.rcast.net/radio/61643/'];

  /// AzuraCast "now playing" API — used for song title / artist / artwork.
  static const String nowPlayingApiUrl = 'https://radio.kinect.com.pg/api/nowplaying/wrl';

  static const Duration nowPlayingRefresh = Duration(seconds: 30);

  // ---------------------------------------------------------------------------
  // Requests (Google Apps Script → Google Sheets)
  // ---------------------------------------------------------------------------
  static const String requestsEndpoint =
      'https://script.google.com/macros/s/AKfycbzslIEaNUYNiOSp2e0v3E8d8mypfZ5jFevO4C4XeYE_jszEpPNXiTczITeeG_210fbn/exec';

  // ---------------------------------------------------------------------------
  // Daily devotionals (written by the Radio Chaplain, pushed at 5 am and 9 pm)
  // ---------------------------------------------------------------------------

  /// Firebase project that stores the devotionals and sends the notifications.
  static const String firebaseProjectId = 'wantok-radio-light-81519';

  /// Push topic prefixes — must match `SLOTS` in the Cloud Functions. The
  /// phone's time zone is appended, e.g. "devotional-morning.Pacific.Port_Moresby",
  /// so each listener gets the devotional at 5:00 am and 9:00 pm local time.
  static const String morningDevotionalTopic = 'devotional-morning';
  static const String eveningDevotionalTopic = 'devotional-evening';

  /// Used only if the phone's time zone can't be read.
  static const String homeTimeZone = 'Pacific/Port_Moresby';

  // ---------------------------------------------------------------------------
  // Contact
  // ---------------------------------------------------------------------------
  static const String studioMobile = '+67573560343'; // SMS + WhatsApp
  static const String officePhone = '+67575666596';
  static const String officePhoneDisplay = '+675 7566 6596';
  static const String officeHours = '8:00am - 4:30pm PNG Time';
  static const String email = 'wrlstudio@wantokradio.org';
  static const String emailSubject = 'Feedback from App';
  static const String addressLine1 = 'Gerehu Stage 2, Sivari RD, Sec: 378, Lot 6';
  static const String addressLine2 = 'Port Moresby, Papua New Guinea';

  // ---------------------------------------------------------------------------
  // Web
  // ---------------------------------------------------------------------------
  static const String websiteUrl = 'https://wantokradio.org/';
  static const String onDemandUrl = 'https://wantokradio.org/#/ondemand';
  static const String facebookUrl = 'https://www.facebook.com/ChristianNet';

  /// Upload store_assets/privacy.html to the website so this link works —
  /// Google Play and the App Store both require a public privacy policy URL.
  static const String privacyPolicyUrl = 'https://wantokradio.org/privacy.html';

  static const String androidPackageId = 'org.wantokradiolight.www';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=$androidPackageId';

  /// Fill in once the app is live on the App Store, e.g.
  /// 'https://apps.apple.com/app/id1234567890'. Leave empty until then.
  static const String appStoreUrl = '';

  /// Developer credit shown on the splash screen, in the menu and on About Us.
  static const String developerCredit = 'Built & Design: Meltronics Info-Tech';

  // ---------------------------------------------------------------------------
  // Feature switches
  // ---------------------------------------------------------------------------

  /// Card / PayPal donations are not live yet. When `false` the
  /// "Online Donation" card is hidden so store reviewers don't see an
  /// unfinished feature (Apple rejects "coming soon" placeholders).
  /// Set to `true` to show it with the "Coming Soon" message, as in the
  /// original Android app.
  static const bool showOnlineDonation = false;

  /// Papua New Guinea is UTC+10 all year (no daylight saving).
  static const Duration pngUtcOffset = Duration(hours: 10);
}
