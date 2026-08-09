import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tutuner/core/metronome/beat_scheduler.dart';
import 'package:tutuner/core/metronome/time_signature.dart';
import 'package:tutuner/core/settings/app_settings.dart';

void main() {
  final originalPlatform = SharedPreferencesAsyncPlatform.instance;

  tearDownAll(() {
    SharedPreferencesAsyncPlatform.instance = originalPlatform;
  });

  test('metronome configuration survives a settings reload', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final settings = AppSettings(preferences: SharedPreferencesAsync());
    await settings.load();

    await settings.setMetronomeTimeSignature(const TimeSignature(3, 4));
    await settings.setMetronomeSubdivision(Subdivision.triplet);
    await settings.setMetronomeAccents(<BeatAccent>[
      BeatAccent.accent,
      BeatAccent.muted,
      BeatAccent.normal,
    ]);
    await settings.setMetronomeSoundEnabled(false);
    await settings.setMetronomeVisualEnabled(false);
    await settings.setTunerSensitivity(TunerSensitivity.sensitive);

    final restored = AppSettings(preferences: SharedPreferencesAsync());
    await restored.load();

    expect(restored.metronomeTimeSignature, const TimeSignature(3, 4));
    expect(restored.metronomeSubdivision, Subdivision.triplet);
    expect(restored.metronomeAccents, <BeatAccent>[
      BeatAccent.accent,
      BeatAccent.muted,
      BeatAccent.normal,
    ]);
    expect(restored.metronomeSoundEnabled, isFalse);
    expect(restored.metronomeVisualEnabled, isFalse);
    expect(restored.tunerSensitivity, TunerSensitivity.sensitive);
    expect(restored.minimumPitchConfidence, 0.58);
  });
}
