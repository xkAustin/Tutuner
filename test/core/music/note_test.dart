import 'package:flutter_test/flutter_test.dart';
import 'package:tutuner/core/music/note.dart';
import 'package:tutuner/core/music/temperament.dart';

void main() {
  group('music model', () {
    test('parses sharp and flat notes consistently', () {
      expect(MusicalNote.parse('C♯4'), MusicalNote.parse('Db4'));
      expect(MusicalNote.parse('E2').midi, 40);
      expect(MusicalNote.parse('B♭3').label(NoteSpelling.flats), 'B♭3');
    });

    test('calculates reference-relative twelve tone frequencies', () {
      expect(twelveTetFrequency(MusicalNote.parse('A4')), 440);
      expect(
        twelveTetFrequency(MusicalNote.parse('E2')),
        closeTo(82.4069, 0.001),
      );
      expect(twelveTetFrequency(MusicalNote.parse('A4'), a4: 442), 442);
    });

    test('finds quarter-tone targets at 50-cent intervals', () {
      final a4 = twentyFourTet.nearest(440);
      final aQuarterSharp = twentyFourTet.targetForStep(a4.step + 1);
      expect(a4.label, 'A4');
      expect(aQuarterSharp.label, 'A4↑');
      expect(
        centsBetween(aQuarterSharp.frequency, a4.frequency),
        closeTo(50, 1e-8),
      );
      expect(
        twentyFourTet.nearest(aQuarterSharp.frequency).step,
        aQuarterSharp.step,
      );
    });
  });
}
