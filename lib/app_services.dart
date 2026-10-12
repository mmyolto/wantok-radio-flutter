import 'audio/radio_audio_handler.dart';
import 'services/devotional_service.dart';
import 'services/now_playing_service.dart';
import 'services/push_service.dart';
import 'services/request_service.dart';

/// App-wide singletons, created once in `main()`.
final NowPlayingService nowPlayingService = NowPlayingService();
final RequestService requestService = RequestService();
final DevotionalService devotionalService = DevotionalService();
final PushService pushService = PushService();

late final RadioAudioHandler radio;
