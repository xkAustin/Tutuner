import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutuner/core/music/tuning.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'built-in asset contains the required fourteen immutable tunings',
    () async {
      final source = await rootBundle.loadString(
        'assets/tunings/built_in_tunings.json',
      );
      final tunings = (jsonDecode(source) as List<dynamic>)
          .map(
            (dynamic item) =>
                TuningPreset.fromJson(item as Map<String, dynamic>),
          )
          .toList();
      expect(tunings, hasLength(14));
      expect(tunings.every((tuning) => tuning.isBuiltIn), isTrue);
      expect(
        tunings.map((tuning) => tuning.id),
        containsAll(<String>[
          'standard',
          'half-step-down',
          'd-standard',
          'c-sharp-standard',
          'c-standard',
          'drop-d',
          'double-drop-d',
          'drop-c',
          'drop-b',
          'dadgad',
          'open-d',
          'open-e',
          'open-g',
          'open-c',
        ]),
      );
      expect(
        tunings.firstWhere((tuning) => tuning.id == 'standard').stringCount,
        6,
      );
    },
  );
}
