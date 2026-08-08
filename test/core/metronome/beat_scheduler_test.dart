import 'package:flutter_test/flutter_test.dart';
import 'package:tutuner/core/metronome/beat_scheduler.dart';
import 'package:tutuner/core/metronome/tap_tempo.dart';
import 'package:tutuner/core/metronome/time_signature.dart';

void main() {
  test('timeline derives every beat from a fixed anchor without drift', () {
    final timeline = BeatTimeline(
      anchorMicros: 1000,
      bpm: 137,
      timeSignature: const TimeSignature(4, 4),
      subdivision: Subdivision.sixteenth,
    );
    final interval = 60000000 / 137 / 4;
    for (var index = 0; index < 10000; index += 997) {
      expect(
        timeline.eventAt(index).dueMicros,
        1000 + (index * interval).round(),
      );
    }
  });

  test('resume skips missed events instead of replaying them', () {
    final timeline = BeatTimeline(
      anchorMicros: 0,
      bpm: 120,
      timeSignature: const TimeSignature(4, 4),
      subdivision: Subdivision.quarter,
    );
    expect(timeline.firstIndexAtOrAfter(1250000), 3);
    expect(timeline.eventAt(3).dueMicros, 1500000);
  });

  test('tap tempo ignores an obvious outlier', () {
    final tapTempo = TapTempo();
    var time = 0;
    int? bpm;
    for (final delta in <int>[0, 500000, 500000, 900000, 500000, 500000]) {
      time += delta;
      bpm = tapTempo.addTap(time).bpm ?? bpm;
    }
    expect(bpm, closeTo(120, 2));
  });

  test('tap tempo starts a fresh sequence after a long pause', () {
    final tapTempo = TapTempo();
    expect(tapTempo.addTap(1000000).tapCount, 1);
    expect(tapTempo.addTap(1500000).bpm, 120);
    final restarted = tapTempo.addTap(4000001);
    expect(restarted.startedNewSequence, isTrue);
    expect(restarted.tapCount, 1);
    expect(restarted.bpm, isNull);
  });

  test('tap tempo ignores accidental double taps', () {
    final tapTempo = TapTempo();
    tapTempo.addTap(1000000);
    final accidental = tapTempo.addTap(1100000);
    expect(accidental.bpm, isNull);
    expect(tapTempo.addTap(1500000).bpm, 120);
  });
}
