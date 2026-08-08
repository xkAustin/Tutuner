import 'dart:math' as math;
import 'dart:typed_data';

class NoiseGate {
  const NoiseGate({this.rmsThreshold = 0.008});

  final double rmsThreshold;

  double rms(Float64List samples) {
    if (samples.isEmpty) {
      return 0;
    }
    var energy = 0.0;
    for (final sample in samples) {
      energy += sample * sample;
    }
    return math.sqrt(energy / samples.length);
  }

  bool isOpen(Float64List samples) => rms(samples) >= rmsThreshold;
}
