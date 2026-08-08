import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutuner/core/music/note.dart';
import 'package:tutuner/core/music/tuning.dart';

class TuningRepository extends ChangeNotifier {
  TuningRepository({
    SharedPreferencesAsync? preferences,
    AssetBundle? assetBundle,
  }) : _preferences = preferences ?? SharedPreferencesAsync(),
       _assetBundle = assetBundle ?? rootBundle;

  static const _customKey = 'custom_tunings_v1';
  static const _favoritesKey = 'favorite_tunings_v1';

  final SharedPreferencesAsync _preferences;
  final AssetBundle _assetBundle;
  final List<TuningPreset> _tunings = <TuningPreset>[];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<TuningPreset> get all => List<TuningPreset>.unmodifiable(_tunings);

  Future<void> load() async {
    final builtInJson = await _assetBundle.loadString(
      'assets/tunings/built_in_tunings.json',
    );
    final builtIns = (jsonDecode(builtInJson) as List<dynamic>)
        .map(
          (dynamic item) => TuningPreset.fromJson(item as Map<String, dynamic>),
        )
        .toList();
    final customJson = await _preferences.getString(_customKey);
    final custom = customJson == null
        ? <TuningPreset>[]
        : (jsonDecode(customJson) as List<dynamic>)
              .map(
                (dynamic item) =>
                    TuningPreset.fromJson(item as Map<String, dynamic>),
              )
              .toList();
    final favorites =
        (await _preferences.getStringList(_favoritesKey) ?? <String>[]).toSet();

    _tunings
      ..clear()
      ..addAll(
        <TuningPreset>[...builtIns, ...custom].map(
          (tuning) =>
              tuning.copyWith(isFavorite: favorites.contains(tuning.id)),
        ),
      );
    _isLoaded = true;
    notifyListeners();
  }

  List<TuningPreset> search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return all;
    }
    return _tunings
        .where(
          (tuning) =>
              tuning.nameEn.toLowerCase().contains(normalized) ||
              tuning.nameZh.contains(normalized) ||
              tuning.strings.any(
                (string) => string.note
                    .label(NoteSpelling.sharps)
                    .toLowerCase()
                    .contains(normalized),
              ),
        )
        .toList(growable: false);
  }

  Future<void> toggleFavorite(String id) async {
    final index = _tunings.indexWhere((tuning) => tuning.id == id);
    if (index == -1) {
      return;
    }
    _tunings[index] = _tunings[index].copyWith(
      isFavorite: !_tunings[index].isFavorite,
    );
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> saveCustom(TuningPreset value) async {
    if (value.isBuiltIn) {
      throw ArgumentError('A custom tuning cannot be marked as built in.');
    }
    final index = _tunings.indexWhere((tuning) => tuning.id == value.id);
    if (index == -1) {
      _tunings.add(value);
    } else if (_tunings[index].isBuiltIn) {
      throw StateError('Built-in tunings cannot be edited.');
    } else {
      _tunings[index] = value.copyWith(isFavorite: _tunings[index].isFavorite);
    }
    await _saveCustomTunings();
    notifyListeners();
  }

  Future<void> deleteCustom(String id) async {
    final index = _tunings.indexWhere((tuning) => tuning.id == id);
    if (index == -1) {
      return;
    }
    if (_tunings[index].isBuiltIn) {
      throw StateError('Built-in tunings cannot be deleted.');
    }
    _tunings.removeAt(index);
    await Future.wait(<Future<void>>[_saveCustomTunings(), _saveFavorites()]);
    notifyListeners();
  }

  Future<void> _saveCustomTunings() {
    final values = _tunings
        .where((tuning) => !tuning.isBuiltIn)
        .map((tuning) => tuning.toJson())
        .toList();
    return _preferences.setString(_customKey, jsonEncode(values));
  }

  Future<void> _saveFavorites() {
    return _preferences.setStringList(
      _favoritesKey,
      _tunings
          .where((tuning) => tuning.isFavorite)
          .map((tuning) => tuning.id)
          .toList(),
    );
  }
}
