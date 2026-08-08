import 'dart:math' as math;

enum NoteSpelling { sharps, flats }

const _sharpNames = <String>[
  'C',
  'C♯',
  'D',
  'D♯',
  'E',
  'F',
  'F♯',
  'G',
  'G♯',
  'A',
  'A♯',
  'B',
];

const _flatNames = <String>[
  'C',
  'D♭',
  'D',
  'E♭',
  'E',
  'F',
  'G♭',
  'G',
  'A♭',
  'A',
  'B♭',
  'B',
];

/// A twelve-tone note represented by its MIDI number.
class MusicalNote {
  const MusicalNote(this.midi);

  final int midi;

  int get pitchClass => midi % 12;
  int get octave => midi ~/ 12 - 1;

  String name(NoteSpelling spelling) {
    return spelling == NoteSpelling.sharps
        ? _sharpNames[pitchClass]
        : _flatNames[pitchClass];
  }

  String label(NoteSpelling spelling) => '${name(spelling)}$octave';

  static MusicalNote parse(String value) {
    final normalized = value.trim().replaceAll('#', '♯').replaceAll('b', '♭');
    final match = RegExp(r'^([A-Ga-g])([♯♭]?)(-?\d+)$').firstMatch(normalized);
    if (match == null) {
      throw FormatException('Invalid note: $value');
    }

    const naturalPitchClasses = <String, int>{
      'C': 0,
      'D': 2,
      'E': 4,
      'F': 5,
      'G': 7,
      'A': 9,
      'B': 11,
    };
    final letter = match.group(1)!.toUpperCase();
    final accidental = match.group(2);
    final octave = int.parse(match.group(3)!);
    var pitchClass = naturalPitchClasses[letter]!;
    if (accidental == '♯') {
      pitchClass++;
    } else if (accidental == '♭') {
      pitchClass--;
    }
    pitchClass = (pitchClass + 12) % 12;
    return MusicalNote((octave + 1) * 12 + pitchClass);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MusicalNote && midi == other.midi;

  @override
  int get hashCode => midi.hashCode;
}

double twelveTetFrequency(MusicalNote note, {double a4 = 440}) {
  return a4 * math.pow(2, (note.midi - 69) / 12).toDouble();
}

double centsBetween(double frequency, double targetFrequency) {
  if (frequency <= 0 || targetFrequency <= 0) {
    throw ArgumentError('Frequencies must be positive.');
  }
  return 1200 * (math.log(frequency / targetFrequency) / math.ln2);
}
