import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';

class AudioSessionService {
  StreamSubscription<AudioInterruptionEvent>? _interruptionSubscription;
  StreamSubscription<void>? _noisySubscription;

  Future<void> initialize({
    required void Function() onInterrupted,
    required void Function() onDeviceDisconnected,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) {
      return;
    }
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    _interruptionSubscription = session.interruptionEventStream.listen((event) {
      if (event.begin && event.type != AudioInterruptionType.duck) {
        onInterrupted();
      }
    });
    _noisySubscription = session.becomingNoisyEventStream.listen(
      (_) => onDeviceDisconnected(),
    );
  }

  Future<void> dispose() async {
    await _interruptionSubscription?.cancel();
    await _noisySubscription?.cancel();
  }
}
