import 'dart:typed_data';

class PitchEstimate {
  const PitchEstimate({
    required this.frequency,
    required this.confidence,
    required this.rms,
  });

  final double frequency;
  final double confidence;
  final double rms;
}

abstract interface class PitchDetector {
  PitchEstimate? detect(Float64List samples, int sampleRate);
}
