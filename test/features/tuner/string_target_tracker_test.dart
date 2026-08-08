import 'package:flutter_test/flutter_test.dart';
import 'package:tutuner/core/music/note.dart';
import 'package:tutuner/core/music/tuning.dart';
import 'package:tutuner/features/tuner/domain/string_target_tracker.dart';

void main() {
  const strings = <TuningString>[
    TuningString(number: 6, note: MusicalNote(40)),
    TuningString(number: 5, note: MusicalNote(45)),
    TuningString(number: 4, note: MusicalNote(50)),
    TuningString(number: 3, note: MusicalNote(55)),
    TuningString(number: 2, note: MusicalNote(59)),
    TuningString(number: 1, note: MusicalNote(64)),
  ];

  test('automatically chooses the nearest guitar string', () {
    final tracker = StringTargetTracker();

    expect(tracker.select(strings, 82.41, a4: 440).number, 6);
    expect(tracker.currentStringNumber, 6);
  });

  test('requires stable evidence before changing strings', () {
    final tracker = StringTargetTracker(confirmationFrames: 3);
    tracker.select(strings, 82.41, a4: 440);

    expect(tracker.select(strings, 110, a4: 440).number, 6);
    expect(tracker.select(strings, 110, a4: 440).number, 6);
    expect(tracker.select(strings, 110, a4: 440).number, 5);
  });

  test('does not oscillate around the boundary between strings', () {
    final tracker = StringTargetTracker();
    tracker.select(strings, 82.41, a4: 440);

    for (final frequency in <double>[94.9, 95.2, 94.8, 95.1, 94.9]) {
      expect(tracker.select(strings, frequency, a4: 440).number, 6);
    }
  });
}
