import 'package:flutter_soloud/flutter_soloud.dart';

enum MetronomeSound { accent, beat, subdivision }

enum MetronomeSoundPack { classic, wood, digital }

abstract interface class AudioOutputService {
  Future<void> initialize();
  void play(
    MetronomeSound sound, {
    required MetronomeSoundPack pack,
    double volume = 1,
  });
  Future<void> dispose();
}

class SoloudAudioOutputService implements AudioOutputService {
  final SoLoud _engine = SoLoud.instance;
  final Map<(MetronomeSoundPack, MetronomeSound), AudioSource> _sources =
      <(MetronomeSoundPack, MetronomeSound), AudioSource>{};

  @override
  Future<void> initialize() async {
    if (_sources.isNotEmpty) {
      return;
    }
    if (!_engine.isInitialized) {
      await _engine.init(
        sampleRate: 48000,
        bufferSize: 256,
        channels: Channels.stereo,
        lowLatency: true,
      );
    }
    for (final pack in MetronomeSoundPack.values) {
      for (final sound in MetronomeSound.values) {
        final prefix = pack == MetronomeSoundPack.classic
            ? ''
            : '${pack.name}_';
        _sources[(pack, sound)] = await _engine.loadAsset(
          'assets/audio/$prefix${sound.name}.wav',
        );
      }
    }
  }

  @override
  void play(
    MetronomeSound sound, {
    required MetronomeSoundPack pack,
    double volume = 1,
  }) {
    final source = _sources[(pack, sound)];
    if (source != null) {
      _engine.play(source, volume: volume.clamp(0, 1));
    }
  }

  @override
  Future<void> dispose() async {
    await _engine.disposeAllSources();
    _sources.clear();
    if (_engine.isInitialized) {
      _engine.deinit();
    }
  }
}
