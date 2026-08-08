import 'dart:math' as math;
import 'dart:typed_data';

import 'package:tutuner/core/dsp/noise_gate.dart';
import 'package:tutuner/core/dsp/pitch_detector.dart';

/// YIN fundamental-frequency detector tuned for monophonic guitar input.
class YinPitchDetector implements PitchDetector {
  const YinPitchDetector({
    this.minimumFrequency = 60,
    this.maximumFrequency = 1400,
    this.threshold = 0.12,
    this.minimumConfidence = 0.70,
    this.noiseGate = const NoiseGate(),
  });

  final double minimumFrequency;
  final double maximumFrequency;
  final double threshold;
  final double minimumConfidence;
  final NoiseGate noiseGate;

  @override
  PitchEstimate? detect(Float64List samples, int sampleRate) {
    if (samples.length < 128 || sampleRate <= 0) {
      return null;
    }
    final rms = noiseGate.rms(samples);
    if (rms < noiseGate.rmsThreshold) {
      return null;
    }

    final minimumTau = math.max(2, (sampleRate / maximumFrequency).floor());
    final maximumTau = math.min(
      samples.length ~/ 2 - 1,
      (sampleRate / minimumFrequency).ceil(),
    );
    if (maximumTau <= minimumTau + 2) {
      return null;
    }

    final difference = Float64List(maximumTau + 1);
    final comparisonLength = samples.length - maximumTau;
    for (var tau = 1; tau <= maximumTau; tau++) {
      var sum = 0.0;
      for (var index = 0; index < comparisonLength; index++) {
        final delta = samples[index] - samples[index + tau];
        sum += delta * delta;
      }
      difference[tau] = sum;
    }

    final normalized = Float64List(maximumTau + 1)..[0] = 1;
    var runningSum = 0.0;
    for (var tau = 1; tau <= maximumTau; tau++) {
      runningSum += difference[tau];
      normalized[tau] = runningSum == 0
          ? 1
          : difference[tau] * tau / runningSum;
    }

    int? selectedTau;
    for (var tau = minimumTau; tau < maximumTau; tau++) {
      if (normalized[tau] < threshold) {
        while (tau + 1 <= maximumTau && normalized[tau + 1] < normalized[tau]) {
          tau++;
        }
        selectedTau = tau;
        break;
      }
    }
    if (selectedTau == null) {
      return null;
    }

    final confidence = 1 - normalized[selectedTau];
    if (confidence < minimumConfidence) {
      return null;
    }

    final refinedTau = _parabolicInterpolation(normalized, selectedTau);
    final frequency = sampleRate / refinedTau;
    if (frequency < minimumFrequency || frequency > maximumFrequency) {
      return null;
    }
    return PitchEstimate(
      frequency: frequency,
      confidence: confidence.clamp(0, 1),
      rms: rms,
    );
  }

  double _parabolicInterpolation(Float64List values, int index) {
    if (index <= 0 || index >= values.length - 1) {
      return index.toDouble();
    }
    final left = values[index - 1];
    final center = values[index];
    final right = values[index + 1];
    final denominator = 2 * (2 * center - right - left);
    if (denominator.abs() < 1e-12) {
      return index.toDouble();
    }
    return index + (right - left) / denominator;
  }
}
