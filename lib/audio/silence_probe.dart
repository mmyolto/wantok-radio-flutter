import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Checks whether a live MP3 stream is carrying real sound.
///
/// When the studio feed is off, the streaming host keeps the stream "online"
/// but fills it with digital silence. The player then receives data and its
/// clock keeps moving, so it cannot tell that nothing is audible.
///
/// An MP3 encoder turns silence into the same frame over and over, while
/// speech and music give a different frame every time. This probe downloads a
/// few seconds of the stream and counts how many frames are identical.
class SilenceProbe {
  SilenceProbe._();

  /// How much of the stream to listen to.
  static const Duration sample = Duration(seconds: 4);

  /// Stop early once this many bytes arrived (about 6 s at 128 kbps).
  static const int maxBytes = 96 * 1024;

  /// Returns true when the stream is silent, false when it carries sound and
  /// null when it could not be checked (no connection, not an MP3 stream…).
  static Future<bool?> isSilent(String url) async {
    final http.Client client = http.Client();
    try {
      final http.StreamedResponse res = await client
          .send(http.Request('GET', Uri.parse(url)))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;

      final BytesBuilder bytes = BytesBuilder(copy: false);
      final Completer<void> done = Completer<void>();
      void finish() {
        if (!done.isCompleted) done.complete();
      }

      final StreamSubscription<List<int>> sub = res.stream.listen(
        (List<int> chunk) {
          bytes.add(chunk);
          if (bytes.length >= maxBytes) finish();
        },
        onDone: finish,
        onError: (Object _) => finish(),
        cancelOnError: true,
      );
      await done.future.timeout(sample, onTimeout: () {});
      await sub.cancel();
      return looksSilent(bytes.takeBytes());
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  static const List<int> _mpeg1Kbps = <int>[0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320];
  static const List<int> _mpeg2Kbps = <int>[0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160];
  static const List<int> _mpeg1Rates = <int>[44100, 48000, 32000];

  /// True when most MP3 frames in [b] are identical (digital silence).
  static bool? looksSilent(Uint8List b) {
    final Map<String, int> counts = <String, int>{};
    int frames = 0;
    int i = 0;
    while (i + 4 < b.length) {
      if (b[i] == 0xFF && (b[i + 1] & 0xE0) == 0xE0) {
        final int version = (b[i + 1] >> 3) & 3; // 3 = MPEG-1, 2 = MPEG-2, 0 = MPEG-2.5
        final int layer = (b[i + 1] >> 1) & 3; // 1 = Layer III
        final int brIndex = (b[i + 2] >> 4) & 15;
        final int srIndex = (b[i + 2] >> 2) & 3;
        if (version != 1 && layer == 1 && brIndex > 0 && brIndex < 15 && srIndex < 3) {
          final bool mpeg1 = version == 3;
          final int kbps = (mpeg1 ? _mpeg1Kbps : _mpeg2Kbps)[brIndex];
          final int rate = _mpeg1Rates[srIndex] ~/ (mpeg1 ? 1 : (version == 2 ? 2 : 4));
          final int pad = (b[i + 2] >> 1) & 1;
          final int len = (mpeg1 ? 144000 : 72000) * kbps ~/ rate + pad;
          if (len > 36 && i + len <= b.length) {
            // Skip header + side information; compare the audio data itself.
            final String key = String.fromCharCodes(b.sublist(i + 36, i + len));
            counts[key] = (counts[key] ?? 0) + 1;
            frames++;
            i += len;
            continue;
          }
        }
      }
      i++;
    }
    if (frames < 40) return null; // not enough to judge
    final int top = counts.values.fold<int>(0, (int a, int c) => c > a ? c : a);
    return top / frames >= 0.6;
  }
}
