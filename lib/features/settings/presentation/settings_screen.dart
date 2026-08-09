import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutuner/app/localization/app_strings.dart';
import 'package:tutuner/core/audio/audio_output_service.dart';
import 'package:tutuner/core/music/note.dart';
import 'package:tutuner/core/settings/app_settings.dart';
import 'package:tutuner/shared/widgets/liquid_glass.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final settings = context.watch<AppSettings>();
    return SafeArea(
      child: Column(
        children: <Widget>[
          GlassPageHeader(title: strings.settings),
          Expanded(
            child: GlassPageBody(
              maxWidth: 1160,
              child: _SettingsGrid(
                children: <Widget>[
                  _SectionCard(
                    title: strings.text('调音器', 'Tuner'),
                    children: <Widget>[
                      _SliderSetting(
                        title: strings.text('A4 参考频率', 'A4 reference pitch'),
                        valueLabel:
                            '${settings.referencePitch.toStringAsFixed(1)} Hz',
                        value: settings.referencePitch,
                        min: 430,
                        max: 450,
                        divisions: 40,
                        onChanged: settings.setReferencePitch,
                      ),
                      _SliderSetting(
                        title: strings.text('输入音量门限', 'Input noise gate'),
                        valueLabel: settings.inputThreshold.toStringAsFixed(3),
                        value: settings.inputThreshold,
                        min: 0.001,
                        max: 0.05,
                        divisions: 49,
                        onChanged: settings.setInputThreshold,
                      ),
                      _SliderSetting(
                        title: strings.text('准确范围', 'In-tune range'),
                        valueLabel:
                            '±${settings.inTuneCents.toStringAsFixed(0)} cents',
                        value: settings.inTuneCents,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        onChanged: settings.setInTuneCents,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(strings.text('调音灵敏度', 'Tuner sensitivity')),
                        subtitle: Text(
                          strings.text(
                            '灵敏模式响应更多弱信号；稳定模式使用更严格的置信度门限',
                            'Sensitive responds to more weak signals; Stable uses a stricter confidence threshold',
                          ),
                        ),
                        trailing: GlassDropdown<TunerSensitivity>(
                          value: settings.tunerSensitivity,
                          items: TunerSensitivity.values
                              .map(
                                (value) => DropdownMenuItem<TunerSensitivity>(
                                  value: value,
                                  child: Text(
                                    _sensitivityLabel(strings, value),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              settings.setTunerSensitivity(value);
                            }
                          },
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(strings.text('音名显示', 'Note spelling')),
                        trailing: GlassDropdown<NoteSpelling>(
                          value: settings.noteSpelling,
                          items: <DropdownMenuItem<NoteSpelling>>[
                            DropdownMenuItem<NoteSpelling>(
                              value: NoteSpelling.sharps,
                              child: Text(strings.text('升号 ♯', 'Sharps ♯')),
                            ),
                            DropdownMenuItem<NoteSpelling>(
                              value: NoteSpelling.flats,
                              child: Text(strings.text('降号 ♭', 'Flats ♭')),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              settings.setNoteSpelling(value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  _SectionCard(
                    title: strings.text('节拍器', 'Metronome'),
                    children: <Widget>[
                      _SliderSetting(
                        title: strings.text('节拍音量', 'Click volume'),
                        valueLabel:
                            '${(settings.metronomeVolume * 100).round()}%',
                        value: settings.metronomeVolume,
                        min: 0,
                        max: 1,
                        divisions: 20,
                        onChanged: settings.setMetronomeVolume,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(strings.text('节拍音效', 'Click sound')),
                        trailing: GlassDropdown<MetronomeSoundPack>(
                          value: settings.metronomeSoundPack,
                          items: MetronomeSoundPack.values
                              .map(
                                (pack) => DropdownMenuItem<MetronomeSoundPack>(
                                  value: pack,
                                  child: Text(_soundPackLabel(strings, pack)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              settings.setMetronomeSoundPack(value);
                            }
                          },
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(strings.text('振动', 'Vibration')),
                        subtitle: Text(
                          strings.text(
                            '移动设备支持时在主拍提供触觉反馈',
                            'Haptic feedback on primary beats when supported',
                          ),
                        ),
                        value: settings.vibrationEnabled,
                        onChanged: settings.setVibrationEnabled,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          strings.text('播放时防止休眠', 'Keep screen awake'),
                        ),
                        value: settings.keepAwake,
                        onChanged: settings.setKeepAwake,
                      ),
                    ],
                  ),
                  _SectionCard(
                    title: strings.text('外观与语言', 'Appearance & language'),
                    children: <Widget>[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(strings.text('主题', 'Theme')),
                        trailing: GlassDropdown<ThemeMode>(
                          value: settings.themeMode,
                          items: <DropdownMenuItem<ThemeMode>>[
                            DropdownMenuItem<ThemeMode>(
                              value: ThemeMode.system,
                              child: Text(strings.text('跟随系统', 'System')),
                            ),
                            DropdownMenuItem<ThemeMode>(
                              value: ThemeMode.light,
                              child: Text(strings.text('浅色', 'Light')),
                            ),
                            DropdownMenuItem<ThemeMode>(
                              value: ThemeMode.dark,
                              child: Text(strings.text('深色', 'Dark')),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              settings.setThemeMode(value);
                            }
                          },
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(strings.text('语言', 'Language')),
                        trailing: GlassDropdown<String>(
                          value: settings.languageMode,
                          items: <DropdownMenuItem<String>>[
                            DropdownMenuItem<String>(
                              value: 'system',
                              child: Text(strings.text('跟随系统', 'System')),
                            ),
                            const DropdownMenuItem<String>(
                              value: 'zh',
                              child: Text('中文'),
                            ),
                            const DropdownMenuItem<String>(
                              value: 'en',
                              child: Text('English'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              settings.setLanguageMode(value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  _SectionCard(
                    title: strings.text('关于', 'About'),
                    children: <Widget>[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.info_outline_rounded),
                        title: const Text('Tutuner'),
                        subtitle: Text(
                          strings.text(
                            '完全离线、无账号、无广告 · 版本 1.0.0',
                            'Offline, account-free, ad-free · Version 1.0.0',
                          ),
                        ),
                        onTap: () => showAboutDialog(
                          context: context,
                          applicationName: 'Tutuner',
                          applicationVersion: '1.0.0',
                          applicationLegalese:
                              'Copyright © 2026 Tutuner contributors',
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.description_outlined),
                        title: Text(
                          strings.text('第三方许可证', 'Third-party licenses'),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => showLicensePage(
                          context: context,
                          applicationName: 'Tutuner',
                          applicationVersion: '1.0.0',
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.restart_alt_rounded),
                        title: Text(strings.text('重置设置', 'Reset settings')),
                        textColor: Theme.of(context).colorScheme.error,
                        iconColor: Theme.of(context).colorScheme.error,
                        onTap: () => _confirmReset(context, settings),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _soundPackLabel(AppStrings strings, MetronomeSoundPack pack) {
    return switch (pack) {
      MetronomeSoundPack.classic => strings.text('经典', 'Classic'),
      MetronomeSoundPack.wood => strings.text('木质', 'Wood'),
      MetronomeSoundPack.digital => strings.text('电子', 'Digital'),
    };
  }

  String _sensitivityLabel(AppStrings strings, TunerSensitivity sensitivity) {
    return switch (sensitivity) {
      TunerSensitivity.stable => strings.text('稳定', 'Stable'),
      TunerSensitivity.balanced => strings.text('平衡', 'Balanced'),
      TunerSensitivity.sensitive => strings.text('灵敏', 'Sensitive'),
    };
  }

  Future<void> _confirmReset(BuildContext context, AppSettings settings) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.text('重置所有设置？', 'Reset all settings?')),
        content: Text(
          strings.text(
            '参考音高、调音灵敏度、外观和节拍器设置将恢复默认值。自定义调弦不会被删除。',
            'Reference pitch, tuner sensitivity, appearance and metronome settings will return to defaults. Custom tunings are kept.',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.text('取消', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.text('重置', 'Reset')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await settings.reset();
    }
  }
}

class _SettingsGrid extends StatelessWidget {
  const _SettingsGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    assert(children.length == 4);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            children: <Widget>[
              for (var index = 0; index < children.length; index++) ...<Widget>[
                if (index > 0) const SizedBox(height: 16),
                children[index],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                children: <Widget>[
                  children[0],
                  const SizedBox(height: 16),
                  children[2],
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: <Widget>[
                  children[1],
                  const SizedBox(height: 16),
                  children[3],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _SliderSetting extends StatelessWidget {
  const _SliderSetting({
    required this.title,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String title;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(title)),
              Text(
                valueLabel,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          Slider(
            min: min,
            max: max,
            divisions: divisions,
            value: value,
            label: valueLabel,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
