import 'dart:math' as math;

import 'package:tutuner/core/music/note.dart';

abstract interface class Temperament {
  int get divisionsPerOctave;
  String get id;

  PitchTarget nearest(double frequency, {double a4 = 440});
  PitchTarget targetForStep(int step, {double a4 = 440});
}

class PitchTarget {
  const PitchTarget({
    required this.step,
    required this.frequency,
    required this.label,
  });

  final int step;
  final double frequency;
  final String label;
}

class EqualTemperament implements Temperament {
  const EqualTemperament({
    required this.divisionsPerOctave,
    this.spelling = NoteSpelling.sharps,
  }) : assert(divisionsPerOctave > 0);

  @override
  final int divisionsPerOctave;
  final NoteSpelling spelling;

  @override
  String get id => '${divisionsPerOctave}tet';

  int get _a4Step => divisionsPerOctave * 69 ~/ 12;

  @override
  PitchTarget nearest(double frequency, {double a4 = 440}) {
    if (frequency <= 0) {
      throw ArgumentError.value(frequency, 'frequency', 'Must be positive');
    }
    final relative = divisionsPerOctave * math.log(frequency / a4) / math.ln2;
    return targetForStep(_a4Step + relative.round(), a4: a4);
  }

  @override
  PitchTarget targetForStep(int step, {double a4 = 440}) {
    final frequency =
        a4 * math.pow(2, (step - _a4Step) / divisionsPerOctave).toDouble();
    return PitchTarget(
      step: step,
      frequency: frequency,
      label: _labelForStep(step),
    );
  }

  String _labelForStep(int step) {
    if (divisionsPerOctave == 12) {
      return MusicalNote(step).label(spelling);
    }
    if (divisionsPerOctave == 24) {
      final midi = step ~/ 2;
      final isQuarterSharp = step.isOdd;
      return '${MusicalNote(midi).label(spelling)}${isQuarterSharp ? '↑' : ''}';
    }
    return 'EDO $step';
  }
}

const twelveTet = EqualTemperament(divisionsPerOctave: 12);
const twentyFourTet = EqualTemperament(divisionsPerOctave: 24);
