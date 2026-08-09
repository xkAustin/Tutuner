import 'package:flutter_test/flutter_test.dart';
import 'package:tutuner/core/audio/audio_output_service.dart';
import 'package:tutuner/core/metronome/beat_scheduler.dart';
import 'package:tutuner/core/metronome/time_signature.dart';
import 'package:tutuner/core/settings/app_settings.dart';
import 'package:tutuner/features/metronome/domain/metronome_controller.dart';

class _FakeAudioOutput implements AudioOutputService {
  int playCount = 0;

  @override
  Future<void> initialize() async {}

  @override
  void play(
    MetronomeSound sound, {
    required MetronomeSoundPack pack,
    double volume = 1,
  }) {
    playCount++;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  test('pause preserves position, resume continues, stop resets', () async {
    final settings = AppSettings.inMemory()..keepAwake = false;
    final output = _FakeAudioOutput();
    final controller = MetronomeController(
      settings: settings,
      audioOutput: output,
    );

    await controller.start();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(controller.isPlaying, isTrue);
    expect(controller.activeBeat, 0);

    await controller.pause();
    final pausedBeat = controller.activeBeat;
    expect(controller.isPlaying, isFalse);
    expect(controller.isPaused, isTrue);
    expect(pausedBeat, 0);

    await controller.resume();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(controller.isPlaying, isTrue);
    expect(controller.isPaused, isFalse);
    expect(controller.activeBeat, 1);

    await controller.stop();
    expect(controller.isPlaying, isFalse);
    expect(controller.isPaused, isFalse);
    expect(controller.activeBeat, -1);
    expect(output.playCount, greaterThanOrEqualTo(2));
    controller.dispose();
  });

  test('restores and updates persisted metronome configuration', () async {
    final settings = AppSettings.inMemory()
      ..metronomeTimeSignature = const TimeSignature(3, 4)
      ..metronomeSubdivision = Subdivision.triplet
      ..metronomeAccents = <BeatAccent>[
        BeatAccent.accent,
        BeatAccent.muted,
        BeatAccent.normal,
      ]
      ..metronomeSoundEnabled = false
      ..metronomeVisualEnabled = false;
    final controller = MetronomeController(
      settings: settings,
      audioOutput: _FakeAudioOutput(),
    );

    expect(controller.timeSignature, const TimeSignature(3, 4));
    expect(controller.subdivision, Subdivision.triplet);
    expect(controller.accents, <BeatAccent>[
      BeatAccent.accent,
      BeatAccent.muted,
      BeatAccent.normal,
    ]);
    expect(controller.soundEnabled, isFalse);
    expect(controller.visualEnabled, isFalse);

    await controller.setTimeSignature(const TimeSignature(5, 4));
    await controller.setSubdivision(Subdivision.sixteenth);
    await controller.setAccent(2, BeatAccent.muted);
    await controller.setSoundEnabled(true);
    await controller.setVisualEnabled(true);

    expect(settings.metronomeTimeSignature, const TimeSignature(5, 4));
    expect(settings.metronomeSubdivision, Subdivision.sixteenth);
    expect(settings.metronomeAccents[2], BeatAccent.muted);
    expect(settings.metronomeSoundEnabled, isTrue);
    expect(settings.metronomeVisualEnabled, isTrue);
    controller.dispose();
  });
}
