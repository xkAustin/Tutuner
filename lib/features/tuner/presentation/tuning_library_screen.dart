import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutuner/app/localization/app_strings.dart';
import 'package:tutuner/core/music/note.dart';
import 'package:tutuner/core/music/tuning.dart';
import 'package:tutuner/core/music/tuning_repository.dart';
import 'package:tutuner/core/settings/app_settings.dart';
import 'package:tutuner/shared/widgets/liquid_glass.dart';

class TuningLibraryScreen extends StatefulWidget {
  const TuningLibraryScreen({super.key});

  @override
  State<TuningLibraryScreen> createState() => _TuningLibraryScreenState();
}

class _TuningLibraryScreenState extends State<TuningLibraryScreen> {
  final TextEditingController _search = TextEditingController();
  bool _favoritesOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final repository = context.watch<TuningRepository>();
    final spelling = context.watch<AppSettings>().noteSpelling;
    final values = repository
        .search(_search.text)
        .where((tuning) => !_favoritesOnly || tuning.isFavorite)
        .toList(growable: false);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LiquidBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              GlassPageHeader(
                title: strings.text('调弦库', 'Tuning library'),
                leading: IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                actions: <Widget>[
                  IconButton(
                    tooltip: strings.text('自定义调弦', 'Custom tuning'),
                    onPressed: () => _editCustom(context),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: SearchBar(
                                  controller: _search,
                                  hintText: strings.text(
                                    '搜索名称或音符',
                                    'Search name or notes',
                                  ),
                                  leading: const Icon(Icons.search_rounded),
                                  trailing: _search.text.isEmpty
                                      ? const <Widget>[]
                                      : <Widget>[
                                          IconButton(
                                            onPressed: () {
                                              _search.clear();
                                              setState(() {});
                                            },
                                            icon: const Icon(
                                              Icons.clear_rounded,
                                            ),
                                          ),
                                        ],
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                selected: _favoritesOnly,
                                onSelected: (value) {
                                  setState(() => _favoritesOnly = value);
                                },
                                avatar: const Icon(Icons.star_rounded),
                                label: Text(strings.text('收藏', 'Favorites')),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: values.isEmpty
                              ? Center(
                                  child: Text(
                                    strings.text('没有匹配的调弦', 'No tunings found'),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    24,
                                  ),
                                  itemCount: values.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final tuning = values[index];
                                    return GlassPanel(
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                        onTap: () =>
                                            Navigator.pop(context, tuning),
                                        title: Text(
                                          strings.isChinese
                                              ? tuning.nameZh
                                              : tuning.nameEn,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${tuning.stringCount} · ${tuning.strings.map((string) => string.note.label(spelling)).join('  ')}',
                                        ),
                                        leading: CircleAvatar(
                                          child: Text(
                                            tuning.stringCount.toString(),
                                          ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            IconButton(
                                              tooltip: strings.text(
                                                '收藏',
                                                'Favorite',
                                              ),
                                              onPressed: () => repository
                                                  .toggleFavorite(tuning.id),
                                              icon: Icon(
                                                tuning.isFavorite
                                                    ? Icons.star_rounded
                                                    : Icons.star_border_rounded,
                                              ),
                                            ),
                                            if (!tuning.isBuiltIn)
                                              PopupMenuButton<String>(
                                                onSelected: (action) {
                                                  if (action == 'edit') {
                                                    _editCustom(
                                                      context,
                                                      existing: tuning,
                                                    );
                                                  } else {
                                                    _deleteCustom(
                                                      context,
                                                      tuning,
                                                    );
                                                  }
                                                },
                                                itemBuilder: (context) =>
                                                    <PopupMenuEntry<String>>[
                                                      PopupMenuItem<String>(
                                                        value: 'edit',
                                                        child: Text(
                                                          strings.text(
                                                            '编辑',
                                                            'Edit',
                                                          ),
                                                        ),
                                                      ),
                                                      PopupMenuItem<String>(
                                                        value: 'delete',
                                                        child: Text(
                                                          strings.text(
                                                            '删除',
                                                            'Delete',
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editCustom(
    BuildContext context, {
    TuningPreset? existing,
  }) async {
    final value = await showDialog<TuningPreset>(
      context: context,
      builder: (_) => _CustomTuningDialog(existing: existing),
    );
    if (value != null && context.mounted) {
      await context.read<TuningRepository>().saveCustom(value);
    }
  }

  Future<void> _deleteCustom(BuildContext context, TuningPreset tuning) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.text('删除自定义调弦？', 'Delete custom tuning?')),
        content: Text(
          strings.text(
            '“${tuning.nameZh}”将从此设备移除。',
            '"${tuning.nameEn}" will be removed from this device.',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.text('取消', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.text('删除', 'Delete')),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<TuningRepository>().deleteCustom(tuning.id);
    }
  }
}

class _CustomTuningDialog extends StatefulWidget {
  const _CustomTuningDialog({this.existing});

  final TuningPreset? existing;

  @override
  State<_CustomTuningDialog> createState() => _CustomTuningDialogState();
}

class _CustomTuningDialogState extends State<_CustomTuningDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameZh;
  late final TextEditingController _nameEn;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameZh = TextEditingController(text: existing?.nameZh);
    _nameEn = TextEditingController(text: existing?.nameEn);
    _notes = TextEditingController(
      text:
          existing?.strings
              .map((string) => string.note.label(NoteSpelling.sharps))
              .join(' ') ??
          'E2 A2 D3 G3 B3 E4',
    );
  }

  @override
  void dispose() {
    _nameZh.dispose();
    _nameEn.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? strings.text('创建自定义调弦', 'Create custom tuning')
            : strings.text('编辑自定义调弦', 'Edit custom tuning'),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _nameZh,
                decoration: InputDecoration(
                  labelText: strings.text('中文名称', 'Chinese name'),
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameEn,
                decoration: InputDecoration(
                  labelText: strings.text('英文名称', 'English name'),
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                decoration: InputDecoration(
                  labelText: strings.text(
                    '从最低弦到最高弦的音符',
                    'Notes from lowest to highest string',
                  ),
                  helperText: strings.text(
                    '用空格或逗号分隔，例如 D2 A2 D3 G3 B3 E4',
                    'Separate with spaces or commas, e.g. D2 A2 D3 G3 B3 E4',
                  ),
                ),
                minLines: 2,
                maxLines: 3,
                validator: _validateNotes,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.text('取消', 'Cancel')),
        ),
        FilledButton(onPressed: _save, child: Text(strings.text('保存', 'Save'))),
      ],
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.of(context).text('此项不能为空', 'Required');
    }
    return null;
  }

  List<MusicalNote> _parseNotes() {
    return _notes.text
        .split(RegExp(r'[\s,，]+'))
        .where((value) => value.isNotEmpty)
        .map(MusicalNote.parse)
        .toList(growable: false);
  }

  String? _validateNotes(String? value) {
    try {
      final notes = _parseNotes();
      if (notes.isEmpty || notes.length > 12) {
        return AppStrings.of(
          context,
        ).text('弦数必须为 1 至 12', 'Use 1 to 12 strings');
      }
      return null;
    } on FormatException {
      return AppStrings.of(
        context,
      ).text('包含无法识别的音符', 'Contains an invalid note');
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final notes = _parseNotes();
    final strings = <TuningString>[
      for (var index = 0; index < notes.length; index++)
        TuningString(number: notes.length - index, note: notes[index]),
    ];
    Navigator.pop(
      context,
      TuningPreset(
        id:
            widget.existing?.id ??
            'user-${DateTime.now().microsecondsSinceEpoch}',
        nameZh: _nameZh.text.trim(),
        nameEn: _nameEn.text.trim(),
        category: TuningCategory.custom,
        strings: strings,
        isBuiltIn: false,
        isFavorite: widget.existing?.isFavorite ?? false,
      ),
    );
  }
}
