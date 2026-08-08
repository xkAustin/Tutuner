import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tutuner/core/dsp/frequency_smoother.dart';
import 'package:tutuner/core/dsp/yin_pitch_detector.dart';

Float64List sineWave(
  double frequency, {
  int sampleRate = 48000,
  int length = 8192,
  double amplitude = 0.8,
}) {
  return Float64List.fromList(
    List<double>.generate(
      length,
      (index) =>
          amplitude * math.sin(2 * math.pi * frequency * index / sampleRate),
    ),
  );
}

void main() {
  group('YIN detector', () {
    const detector = YinPitchDetector();

    for (final frequency in <double>[
      82.4069,
      110,
      196,
      329.6276,
      880,
      1396.91,
    ]) {
      test('detects $frequency Hz synthetic input', () {
        final result = detector.detect(sineWave(frequency), 48000);
        expect(result, isNotNull);
        expect(result!.frequency, closeTo(frequency, frequency * 0.003));
        expect(result.confidence, greaterThan(0.9));
      });
    }

    test('rejects silence below the noise gate', () {
      final result = detector.detect(Float64List(8192), 48000);
      expect(result, isNull);
    });
  });

  test('smoother suppresses octave jumps and reports stability', () {
    final smoother = FrequencySmoother();
    smoother.add(110);
    smoother.add(110.1);
    smoother.add(220);
    final result = smoother.add(109.9);
    expect(result.frequency, closeTo(110, 0.2));
    expect(result.isStable, isTrue);
  });
}
