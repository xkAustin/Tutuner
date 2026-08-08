import 'package:tutuner/core/metronome/time_signature.dart';

enum Subdivision {
  quarter(1),
  eighth(2),
  triplet(3),
  sixteenth(4);

  const Subdivision(this.partsPerBeat);
  final int partsPerBeat;
}

enum BeatAccent { muted, normal, accent }

class ScheduledBeat {
  const ScheduledBeat({
    required this.index,
    required this.dueMicros,
    required this.beatInBar,
    required this.subdivisionInBeat,
    required this.accent,
  });

  final int index;
  final int dueMicros;
  final int beatInBar;
  final int subdivisionInBeat;
  final BeatAccent accent;
}

/// A drift-free timeline: every due time is derived from one fixed anchor.
class BeatTimeline {
  BeatTimeline({
    required this.anchorMicros,
    required this.bpm,
    required this.timeSignature,
    required this.subdivision,
    List<BeatAccent>? accents,
  }) : assert(bpm >= 30 && bpm <= 300),
       accents =
           accents ??
           List<BeatAccent>.generate(
             timeSignature.numerator,
             (index) => index == 0 ? BeatAccent.accent : BeatAccent.normal,
           ),
       assert(
         accents == null || accents.length == timeSignature.numerator,
         'There must be one accent value per beat.',
       );

  final int anchorMicros;
  final int bpm;
  final TimeSignature timeSignature;
  final Subdivision subdivision;
  final List<BeatAccent> accents;

  double get eventIntervalMicros => 60000000 / bpm / subdivision.partsPerBeat;

  ScheduledBeat eventAt(int index) {
    final parts = subdivision.partsPerBeat;
    final beatInBar = (index ~/ parts) % timeSignature.numerator;
    final subdivisionInBeat = index % parts;
    final accent = subdivisionInBeat == 0
        ? accents[beatInBar]
        : BeatAccent.normal;
    return ScheduledBeat(
      index: index,
      dueMicros: anchorMicros + (index * eventIntervalMicros).round(),
      beatInBar: beatInBar,
      subdivisionInBeat: subdivisionInBeat,
      accent: accent,
    );
  }

  int firstIndexAtOrAfter(int nowMicros) {
    if (nowMicros <= anchorMicros) {
      return 0;
    }
    return ((nowMicros - anchorMicros) / eventIntervalMicros).ceil();
  }
}
