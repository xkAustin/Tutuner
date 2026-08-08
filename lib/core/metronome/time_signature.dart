class TimeSignature {
  const TimeSignature(this.numerator, this.denominator)
    : assert(numerator >= 1 && numerator <= 16),
      assert(
        denominator == 2 ||
            denominator == 4 ||
            denominator == 8 ||
            denominator == 16,
      );

  final int numerator;
  final int denominator;

  String get label => '$numerator/$denominator';

  static const presets = <TimeSignature>[
    TimeSignature(2, 4),
    TimeSignature(3, 4),
    TimeSignature(4, 4),
    TimeSignature(5, 4),
    TimeSignature(6, 8),
    TimeSignature(7, 8),
    TimeSignature(9, 8),
    TimeSignature(12, 8),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSignature &&
          numerator == other.numerator &&
          denominator == other.denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);
}
