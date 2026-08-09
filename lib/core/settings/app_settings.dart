import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutuner/core/audio/audio_output_service.dart';
import 'package:tutuner/core/metronome/beat_scheduler.dart';
import 'package:tutuner/core/metronome/time_signature.dart';
import 'package:tutuner/core/music/note.dart';

enum TunerSensitivity { stable, balanced, sensitive }

class AppSettings extends ChangeNotifier {
  AppSettings({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  AppSettings.inMemory() : _preferences = null;

  final SharedPreferencesAsync? _preferences;

  double referencePitch = 440;
  double inputThreshold = 0.008;
  double inTuneCents = 3;
  TunerSensitivity tunerSensitivity = TunerSensitivity.balanced;
  double metronomeVolume = 0.8;
  int bpm = 120;
  ThemeMode themeMode = ThemeMode.system;
  String languageMode = 'system';
  NoteSpelling noteSpelling = NoteSpelling.sharps;
  MetronomeSoundPack metronomeSoundPack = MetronomeSoundPack.classic;
  TimeSignature metronomeTimeSignature = const TimeSignature(4, 4);
  Subdivision metronomeSubdivision = Subdivision.quarter;
  List<BeatAccent> metronomeAccents = _defaultAccents(4);
  bool metronomeSoundEnabled = true;
  bool metronomeVisualEnabled = true;
  bool vibrationEnabled = false;
  bool keepAwake = true;
  bool isLoaded = false;

  Locale? get locale => languageMode == 'system' ? null : Locale(languageMode);

  double get minimumPitchConfidence => switch (tunerSensitivity) {
    TunerSensitivity.stable => 0.82,
    TunerSensitivity.balanced => 0.70,
    TunerSensitivity.sensitive => 0.58,
  };

  Future<void> load() async {
    final preferences = _preferences;
    if (preferences == null) {
      isLoaded = true;
      notifyListeners();
      return;
    }
    referencePitch = await preferences.getDouble('reference_pitch') ?? 440;
    inputThreshold = await preferences.getDouble('input_threshold') ?? 0.008;
    inTuneCents = await preferences.getDouble('in_tune_cents') ?? 3;
    tunerSensitivity = _enumByNameOr(
      TunerSensitivity.values,
      await preferences.getString('tuner_sensitivity'),
      TunerSensitivity.balanced,
    );
    metronomeVolume = await preferences.getDouble('metronome_volume') ?? 0.8;
    bpm = await preferences.getInt('bpm') ?? 120;
    themeMode = ThemeMode.values.byName(
      await preferences.getString('theme_mode') ?? ThemeMode.system.name,
    );
    languageMode =
        await preferences.getString('language_mode') ??
        await preferences.getString('locale') ??
        'system';
    noteSpelling = NoteSpelling.values.byName(
      await preferences.getString('note_spelling') ?? NoteSpelling.sharps.name,
    );
    metronomeSoundPack = MetronomeSoundPack.values.byName(
      await preferences.getString('metronome_sound_pack') ??
          MetronomeSoundPack.classic.name,
    );
    final timeSignatureNumerator =
        await preferences.getInt('metronome_time_signature_numerator') ?? 4;
    final timeSignatureDenominator =
        await preferences.getInt('metronome_time_signature_denominator') ?? 4;
    metronomeTimeSignature = _validTimeSignature(
      timeSignatureNumerator,
      timeSignatureDenominator,
    );
    metronomeSubdivision = _enumByNameOr(
      Subdivision.values,
      await preferences.getString('metronome_subdivision'),
      Subdivision.quarter,
    );
    final savedAccents = await preferences.getStringList('metronome_accents');
    metronomeAccents =
        savedAccents != null &&
            savedAccents.length == metronomeTimeSignature.numerator
        ? savedAccents
              .map(
                (name) =>
                    _enumByNameOr(BeatAccent.values, name, BeatAccent.normal),
              )
              .toList()
        : _defaultAccents(metronomeTimeSignature.numerator);
    metronomeSoundEnabled =
        await preferences.getBool('metronome_sound_enabled') ?? true;
    metronomeVisualEnabled =
        await preferences.getBool('metronome_visual_enabled') ?? true;
    vibrationEnabled = await preferences.getBool('vibration_enabled') ?? false;
    keepAwake = await preferences.getBool('keep_awake') ?? true;
    isLoaded = true;
    notifyListeners();
  }

  Future<void> setReferencePitch(double value) async {
    referencePitch = value.clamp(430, 450);
    await _preferences?.setDouble('reference_pitch', referencePitch);
    notifyListeners();
  }

  Future<void> setInputThreshold(double value) async {
    inputThreshold = value.clamp(0.001, 0.05);
    await _preferences?.setDouble('input_threshold', inputThreshold);
    notifyListeners();
  }

  Future<void> setInTuneCents(double value) async {
    inTuneCents = value.clamp(1, 10);
    await _preferences?.setDouble('in_tune_cents', inTuneCents);
    notifyListeners();
  }

  Future<void> setTunerSensitivity(TunerSensitivity value) async {
    tunerSensitivity = value;
    await _preferences?.setString('tuner_sensitivity', value.name);
    notifyListeners();
  }

  Future<void> setMetronomeVolume(double value) async {
    metronomeVolume = value.clamp(0, 1);
    await _preferences?.setDouble('metronome_volume', metronomeVolume);
    notifyListeners();
  }

  Future<void> setBpm(int value) async {
    bpm = value.clamp(30, 300);
    await _preferences?.setInt('bpm', bpm);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    themeMode = value;
    await _preferences?.setString('theme_mode', value.name);
    notifyListeners();
  }

  Future<void> setLanguageMode(String value) async {
    if (value != 'system' && value != 'zh' && value != 'en') {
      throw ArgumentError.value(value, 'value', 'Unsupported language mode');
    }
    languageMode = value;
    await _preferences?.setString('language_mode', value);
    notifyListeners();
  }

  Future<void> setNoteSpelling(NoteSpelling value) async {
    noteSpelling = value;
    await _preferences?.setString('note_spelling', value.name);
    notifyListeners();
  }

  Future<void> setMetronomeSoundPack(MetronomeSoundPack value) async {
    metronomeSoundPack = value;
    await _preferences?.setString('metronome_sound_pack', value.name);
    notifyListeners();
  }

  Future<void> setMetronomeTimeSignature(TimeSignature value) async {
    metronomeTimeSignature = value;
    metronomeAccents = _defaultAccents(value.numerator);
    final preferences = _preferences;
    if (preferences != null) {
      await Future.wait(<Future<void>>[
        preferences.setInt(
          'metronome_time_signature_numerator',
          value.numerator,
        ),
        preferences.setInt(
          'metronome_time_signature_denominator',
          value.denominator,
        ),
        preferences.setStringList(
          'metronome_accents',
          metronomeAccents.map((accent) => accent.name).toList(),
        ),
      ]);
    }
    notifyListeners();
  }

  Future<void> setMetronomeSubdivision(Subdivision value) async {
    metronomeSubdivision = value;
    await _preferences?.setString('metronome_subdivision', value.name);
    notifyListeners();
  }

  Future<void> setMetronomeAccents(List<BeatAccent> value) async {
    if (value.length != metronomeTimeSignature.numerator) {
      throw ArgumentError.value(
        value,
        'value',
        'There must be one accent value per beat.',
      );
    }
    metronomeAccents = List<BeatAccent>.of(value);
    await _preferences?.setStringList(
      'metronome_accents',
      value.map((accent) => accent.name).toList(),
    );
    notifyListeners();
  }

  Future<void> setMetronomeSoundEnabled(bool value) async {
    metronomeSoundEnabled = value;
    await _preferences?.setBool('metronome_sound_enabled', value);
    notifyListeners();
  }

  Future<void> setMetronomeVisualEnabled(bool value) async {
    metronomeVisualEnabled = value;
    await _preferences?.setBool('metronome_visual_enabled', value);
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool value) async {
    vibrationEnabled = value;
    await _preferences?.setBool('vibration_enabled', value);
    notifyListeners();
  }

  Future<void> setKeepAwake(bool value) async {
    keepAwake = value;
    await _preferences?.setBool('keep_awake', value);
    notifyListeners();
  }

  Future<void> reset() async {
    await _preferences?.clear(
      allowList: <String>{
        'reference_pitch',
        'input_threshold',
        'in_tune_cents',
        'tuner_sensitivity',
        'metronome_volume',
        'bpm',
        'theme_mode',
        'language_mode',
        'locale',
        'note_spelling',
        'metronome_sound_pack',
        'metronome_time_signature_numerator',
        'metronome_time_signature_denominator',
        'metronome_subdivision',
        'metronome_accents',
        'metronome_sound_enabled',
        'metronome_visual_enabled',
        'vibration_enabled',
        'keep_awake',
      },
    );
    referencePitch = 440;
    inputThreshold = 0.008;
    inTuneCents = 3;
    tunerSensitivity = TunerSensitivity.balanced;
    metronomeVolume = 0.8;
    bpm = 120;
    themeMode = ThemeMode.system;
    languageMode = 'system';
    noteSpelling = NoteSpelling.sharps;
    metronomeSoundPack = MetronomeSoundPack.classic;
    metronomeTimeSignature = const TimeSignature(4, 4);
    metronomeSubdivision = Subdivision.quarter;
    metronomeAccents = _defaultAccents(4);
    metronomeSoundEnabled = true;
    metronomeVisualEnabled = true;
    vibrationEnabled = false;
    keepAwake = true;
    notifyListeners();
  }
}

TimeSignature _validTimeSignature(int numerator, int denominator) {
  const validDenominators = <int>{2, 4, 8, 16};
  if (numerator < 1 ||
      numerator > 16 ||
      !validDenominators.contains(denominator)) {
    return const TimeSignature(4, 4);
  }
  return TimeSignature(numerator, denominator);
}

List<BeatAccent> _defaultAccents(int numerator) => List<BeatAccent>.generate(
  numerator,
  (index) => index == 0 ? BeatAccent.accent : BeatAccent.normal,
);

T _enumByNameOr<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  return fallback;
}
