import 'dart:collection';
import 'dart:math' as math;

class SmoothedPitch {
  const SmoothedPitch({
    required this.frequency,
    required this.isStable,
    required this.spreadCents,
  });

  final double frequency;
  final bool isStable;
  final double spreadCents;
}

class FrequencySmoother {
  FrequencySmoother({
    this.windowSize = 5,
    this.alpha = 0.45,
    this.stableSpreadCents = 5,
  });

  final int windowSize;
  final double alpha;
  final double stableSpreadCents;
  final Queue<double> _window = Queue<double>();
  double? _smoothed;

  SmoothedPitch add(double frequency) {
    if (frequency <= 0) {
      throw ArgumentError.value(frequency, 'frequency', 'Must be positive');
    }

    var candidate = frequency;
    final previous = _smoothed;
    if (previous != null) {
      final ratio = candidate / previous;
      if (ratio > 1.85 && ratio < 2.15) {
        candidate /= 2;
      } else if (ratio > 0.46 && ratio < 0.54) {
        candidate *= 2;
      }
    }

    _window.add(candidate);
    while (_window.length > windowSize) {
      _window.removeFirst();
    }
    final sorted = _window.toList()..sort();
    final median = sorted[sorted.length ~/ 2];
    _smoothed = previous == null
        ? median
        : previous + alpha * (median - previous);

    final cents = _window
        .map((value) => 1200 * math.log(value / _smoothed!) / math.ln2)
        .toList();
    final spread = cents.length < 2
        ? double.infinity
        : cents.reduce(math.max) - cents.reduce(math.min);
    return SmoothedPitch(
      frequency: _smoothed!,
      isStable: _window.length >= 3 && spread <= stableSpreadCents,
      spreadCents: spread,
    );
  }

  void reset() {
    _window.clear();
    _smoothed = null;
  }
}
