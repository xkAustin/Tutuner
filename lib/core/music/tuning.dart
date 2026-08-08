import 'package:tutuner/core/music/note.dart';

enum TuningCategory { standard, dropped, open, modal, custom }

class TuningString {
  const TuningString({required this.number, required this.note});

  factory TuningString.fromJson(Map<String, dynamic> json) {
    return TuningString(
      number: json['number'] as int,
      note: MusicalNote.parse(json['note'] as String),
    );
  }

  final int number;
  final MusicalNote note;

  Map<String, Object> toJson() => <String, Object>{
    'number': number,
    'note': note.label(NoteSpelling.sharps),
  };
}

class TuningPreset {
  const TuningPreset({
    required this.id,
    required this.nameZh,
    required this.nameEn,
    required this.category,
    required this.strings,
    required this.isBuiltIn,
    this.isFavorite = false,
  });

  factory TuningPreset.fromJson(Map<String, dynamic> json) {
    return TuningPreset(
      id: json['id'] as String,
      nameZh: json['nameZh'] as String,
      nameEn: json['nameEn'] as String,
      category: TuningCategory.values.byName(json['category'] as String),
      strings: (json['strings'] as List<dynamic>)
          .map(
            (dynamic item) =>
                TuningString.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
    );
  }

  final String id;
  final String nameZh;
  final String nameEn;
  final TuningCategory category;
  final List<TuningString> strings;
  final bool isBuiltIn;
  final bool isFavorite;

  int get stringCount => strings.length;

  TuningPreset copyWith({
    String? id,
    String? nameZh,
    String? nameEn,
    TuningCategory? category,
    List<TuningString>? strings,
    bool? isBuiltIn,
    bool? isFavorite,
  }) {
    return TuningPreset(
      id: id ?? this.id,
      nameZh: nameZh ?? this.nameZh,
      nameEn: nameEn ?? this.nameEn,
      category: category ?? this.category,
      strings: strings ?? this.strings,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, Object> toJson() => <String, Object>{
    'id': id,
    'nameZh': nameZh,
    'nameEn': nameEn,
    'category': category.name,
    'strings': strings.map((string) => string.toJson()).toList(),
    'isBuiltIn': isBuiltIn,
  };
}
