/// Text content shown in the app (taken from the original Android app).
library;

class ProgramItem {
  const ProgramItem(this.time, this.title, this.startMinute);

  /// Display time, e.g. "05:30 AM".
  final String time;
  final String title;

  /// Minutes after midnight (PNG time) the program starts.
  final int startMinute;
}

const String scheduleTitle = 'Weekdays Program Schedule';

const List<ProgramItem> weekdayPrograms = <ProgramItem>[
  ProgramItem('05:30 AM', 'Morning Light Devotion', 5 * 60 + 30),
  ProgramItem('07:00 AM', 'NBC News', 7 * 60),
  ProgramItem('07:30 AM', 'Praying for the Nation', 7 * 60 + 30),
  ProgramItem('11:30 AM', 'Belo Taim Devotion', 11 * 60 + 30),
  ProgramItem('12:00 PM', 'NBC News', 12 * 60),
  ProgramItem('12:15 PM', 'Lunch Hour Dedication', 12 * 60 + 15),
  ProgramItem('02:30 PM', 'Drive to Destiny', 14 * 60 + 30),
  ProgramItem('06:00 PM', 'NBC News', 18 * 60),
  ProgramItem('06:15 PM', 'Night Light Show', 18 * 60 + 15),
  ProgramItem('08:00 PM', 'Toksave', 20 * 60),
  ProgramItem('08:10 PM', 'Chapel in the Air', 20 * 60 + 10),
  ProgramItem('09:00 PM', 'Night Light Devotion', 21 * 60),
  ProgramItem('09:30 PM', 'Pray for the World', 21 * 60 + 30),
  ProgramItem('10:00 PM', 'Late Night Dedication', 22 * 60),
  ProgramItem('12:00 AM', 'Station Close', 0),
  ProgramItem('12:00 AM', 'Automation (12:00 AM - 05:00 AM)', 0),
];

class Faq {
  const Faq(this.question, this.answer);
  final String question;
  final String answer;
}

const List<Faq> faqs = <Faq>[
  Faq(
    'How can I listen to Wantok Radio Light?',
    'You can listen through this app, our website at www.wantokradio.org, or on FM '
        'frequencies across PNG 105.9 FM including 93.9 FM in Port Moresby and 105.7 FM in Goroka.',
  ),
  Faq(
    'How can I support the ministry?',
    'You can support us by bank transfer to the accounts shown on the Donation screen. Your '
        "support helps us keep the 'Inspiration Station' on air.",
  ),
  Faq(
    'Can I request a song or prayer?',
    "Yes! Use the 'Requests' screen in this app to send us your prayer requests or song dedications.",
  ),
  Faq(
    'How do I get the daily devotional?',
    'Open the Devotional page in the menu. Our Radio Chaplain posts a devotional every morning '
        'and evening. Switch on the reminders there to get a notification at 5:00 am and '
        '9:00 pm in your own local time, wherever you are.',
  ),
  Faq(
    'Where is Wantok Radio Light located?',
    'Our main studios are located in Port Moresby, Papua New Guinea, but we have FM transmitters '
        'serving many provinces.',
  ),
  Faq(
    'Is there a cost to use this app?',
    'No, the Wantok Radio Light app is completely free to download and use. We are a '
        'listener-supported ministry.',
  ),
  Faq(
    'How can I share the app with others?',
    "You can share the app by telling your friends to search for 'Wantok Radio Light' on the "
        'Google Play Store or Apple App Store, by using "Share App" in the menu, or by sharing our '
        'website link with them.',
  ),
];

const String missionText =
    'To preach JESUS CHRIST to as many Papua New Guineans as possible; people of all walks of '
    'life in both the urban and remote communities of Papua New Guinea. And also, to saturate '
    'the airwaves of PNG with Christian programming to counter the work of the devil and '
    'demonic forces in the airspace of PNG.';

const String visionText =
    'To use electronic communications media to spread the gospel message of JESUS CHRIST to '
    'the nation of Papua New Guinea and internationally while at the same time addressing '
    'social issues affecting the nation in partnership with Christian Churches, mission '
    'organizations, NGOs and Government agencies.';

const String donationVerse =
    '"Each of you should give what you have decided in your heart to give, not reluctantly or '
    'under compulsion, for God loves a cheerful giver."';
const String donationVerseRef = '2 Corinthians 9:7';

const String whyGive1 =
    'Your generous donations help us continue spreading the Gospel through radio broadcasts, '
    'maintaining our equipment, and reaching more communities across Papua New Guinea with the '
    "message of God's love.";
const String whyGive2 =
    'Every contribution, no matter the size, makes a significant impact in our ministry and '
    'helps us fulfill our mission of being a light to the nation.';

class BankAccount {
  const BankAccount({
    required this.bank,
    required this.logoAsset,
    required this.accountName,
    required this.accountNumber,
    required this.swift,
    required this.bsb,
  });
  final String bank;
  final String logoAsset;
  final String accountName;
  final String accountNumber;
  final String swift;
  final String bsb;
}

const List<BankAccount> bankAccounts = <BankAccount>[
  BankAccount(
    bank: 'Bank of South Pacific',
    logoAsset: 'assets/images/bsp.png',
    accountName: 'Wantok Radio Light',
    accountNumber: '1000908049',
    swift: 'BOSPPGPM',
    bsb: '088-340',
  ),
  BankAccount(
    bank: 'Kina Bank',
    logoAsset: 'assets/images/kina.png',
    accountName: 'Wantok Radio Light',
    accountNumber: '11757718',
    swift: 'KINIPGPG',
    bsb: '028-038',
  ),
];

const List<int> donationAmounts = <int>[20, 50, 100, 150, 250, 300, 500];

class PolicySection {
  const PolicySection(this.title, this.body);
  final String title;
  final String body;
}

const String privacyLastUpdated = 'Last updated: October 2026';

const List<PolicySection> privacyPolicy = <PolicySection>[
  PolicySection(
    'Introduction',
    'Wantok Radio Light ("we", "our", or "us") is committed to protecting your privacy. This '
        'Privacy Policy explains how we collect, use, and disclose your information when you use '
        'our mobile application.',
  ),
  PolicySection(
    'Information We Collect',
    'Our app does not require you to create an account. We only receive the details you choose '
        'to type into a Prayer Request or Song Request form (your name, phone number, country, '
        'location and message). These are sent to our studio team so we can respond on air or '
        'in prayer, and are not used for any other purpose.',
  ),
  PolicySection(
    'Permissions',
    'The app requires certain permissions to function:\n'
        '• Internet: To stream radio content and send your requests.\n'
        '• Background audio / Foreground Service: To keep the radio playing while you use other '
        'apps or when the screen is off.\n'
        '• Notifications: To provide playback controls in the notification area and lock screen, '
        'and — only if you turn them on — to deliver the daily devotionals at 5:00 am and '
        '9:00 pm.',
  ),
  PolicySection(
    'Daily Devotional Notifications',
    'If you turn on devotional reminders, the app uses Google Firebase Cloud Messaging to '
        'deliver them. Firebase gives your phone a random notification ID so the reminders can '
        'reach it, and the app shares your phone’s time zone (for example '
        '"Pacific/Port_Moresby") so they arrive at 5:00 am and 9:00 pm your local time. '
        'Neither is linked to your name or phone number, and neither is used for advertising. '
        'You can turn the reminders off at any time on the Devotional page or in your phone’s '
        'Settings.',
  ),
  PolicySection(
    'Third-Party Services',
    'We use Google Sheets (via Google Apps Script) to receive requests, Google Firebase to '
        'store the devotionals and send reminders, and our streaming provider to deliver the '
        'live broadcast and "now playing" information. These services '
        'may process information as governed by their own privacy policies.',
  ),
  PolicySection(
    "Children's Privacy",
    'Our app does not knowingly collect personal information from children under 13.',
  ),
  PolicySection('Data Sharing', 'We do not collect, sell, or trade your personal information.'),
  PolicySection(
    'Contact Us',
    'If you have any questions about this Privacy Policy, please contact us at '
        'wrlstudio@wantokradio.org',
  ),
];
