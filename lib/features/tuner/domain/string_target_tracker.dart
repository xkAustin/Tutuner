import 'package:tutuner/core/music/note.dart';
import 'package:tutuner/core/music/tuning.dart';

/// Chooses a guitar string from pitch while resisting rapid changes near the
/// midpoint between two strings.
class StringTargetTracker {
  StringTargetTracker({
    this.confirmationFrames = 3,
    this.switchAdvantageCents = 20,
  });

  final int confirmationFrames;
  final double switchAdvantageCents;

  int? currentStringNumber;
  int? _candidateStringNumber;
  int _candidateFrames = 0;

  TuningString select(
    List<TuningString> strings,
    double frequency, {
    required double a4,
  }) {
    if (strings.isEmpty) {
      throw ArgumentError.value(strings, 'strings', 'Must not be empty.');
    }

    final nearest = strings.reduce((left, right) {
      return _distance(frequency, left, a4) <= _distance(frequency, right, a4)
          ? left
          : right;
    });
    final current = _find(strings, currentStringNumber);
    if (current == null) {
      currentStringNumber = nearest.number;
      _clearCandidate();
      return nearest;
    }
    if (nearest.number == current.number) {
      _clearCandidate();
      return current;
    }

    final advantage =
        _distance(frequency, current, a4) - _distance(frequency, nearest, a4);
    if (advantage < switchAdvantageCents) {
      _clearCandidate();
      return current;
    }

    if (_candidateStringNumber == nearest.number) {
      _candidateFrames++;
    } else {
      _candidateStringNumber = nearest.number;
      _candidateFrames = 1;
    }
    if (_candidateFrames >= confirmationFrames) {
      currentStringNumber = nearest.number;
      _clearCandidate();
      return nearest;
    }
    return current;
  }

  void reset() {
    currentStringNumber = null;
    _clearCandidate();
  }

  double _distance(double frequency, TuningString string, double a4) {
    return centsBetween(
      frequency,
      twelveTetFrequency(string.note, a4: a4),
    ).abs();
  }

  TuningString? _find(List<TuningString> strings, int? number) {
    if (number == null) {
      return null;
    }
    for (final string in strings) {
      if (string.number == number) {
        return string;
      }
    }
    return null;
  }

  void _clearCandidate() {
    _candidateStringNumber = null;
    _candidateFrames = 0;
  }
}
