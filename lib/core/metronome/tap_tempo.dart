class TapTempoResult {
  const TapTempoResult({
    required this.bpm,
    required this.tapCount,
    required this.startedNewSequence,
  });

  final int? bpm;
  final int tapCount;
  final bool startedNewSequence;
}

class TapTempo {
  TapTempo({
    this.maximumSamples = 7,
    this.resetAfter = const Duration(seconds: 2),
  });

  final int maximumSamples;
  final Duration resetAfter;
  final List<int> _intervals = <int>[];
  int? _lastTapMicros;
  double? _smoothedBpm;

  TapTempoResult addTap(int monotonicMicros) {
    final previousTap = _lastTapMicros;
    if (previousTap == null ||
        monotonicMicros - previousTap > resetAfter.inMicroseconds) {
      reset();
      _lastTapMicros = monotonicMicros;
      return const TapTempoResult(
        bpm: null,
        tapCount: 1,
        startedNewSequence: true,
      );
    }

    final interval = monotonicMicros - previousTap;
    // Ignore accidental double taps without shifting the reference tap.
    if (interval < 180000) {
      return TapTempoResult(
        bpm: _smoothedBpm?.round(),
        tapCount: _intervals.length + 1,
        startedNewSequence: false,
      );
    }

    _lastTapMicros = monotonicMicros;
    _intervals.add(interval);
    while (_intervals.length > maximumSamples) {
      _intervals.removeAt(0);
    }

    final sorted = List<int>.of(_intervals)..sort();
    final median = sorted[sorted.length ~/ 2];
    final filtered = _intervals
        .where((value) => value >= median * 0.72 && value <= median * 1.28)
        .toList(growable: false);
    if (filtered.isEmpty) {
      return TapTempoResult(
        bpm: _smoothedBpm?.round(),
        tapCount: _intervals.length + 1,
        startedNewSequence: false,
      );
    }

    var weightedTotal = 0.0;
    var totalWeight = 0.0;
    for (var index = 0; index < filtered.length; index++) {
      final weight = (index + 1).toDouble();
      weightedTotal += filtered[index] * weight;
      totalWeight += weight;
    }
    final mean = weightedTotal / totalWeight;
    final rawBpm = (60000000 / mean).clamp(30, 300).toDouble();
    _smoothedBpm = _smoothedBpm == null
        ? rawBpm
        : _smoothedBpm! * 0.25 + rawBpm * 0.75;
    return TapTempoResult(
      bpm: _smoothedBpm!.round(),
      tapCount: _intervals.length + 1,
      startedNewSequence: false,
    );
  }

  void reset() {
    _intervals.clear();
    _lastTapMicros = null;
    _smoothedBpm = null;
  }
}
