import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutuner/app/localization/app_strings.dart';
import 'package:tutuner/core/audio/audio_output_service.dart';
import 'package:tutuner/core/metronome/beat_scheduler.dart';
import 'package:tutuner/core/metronome/time_signature.dart';
import 'package:tutuner/core/settings/app_settings.dart';
import 'package:tutuner/features/metronome/domain/metronome_controller.dart';
import 'package:tutuner/shared/widgets/liquid_glass.dart';

class MetronomeScreen extends StatefulWidget {
  const MetronomeScreen({super.key});

  @override
  State<MetronomeScreen> createState() => _MetronomeScreenState();
}

class _MetronomeScreenState extends State<MetronomeScreen> {
  final TextEditingController _bpmController = TextEditingController();
  final FocusNode _bpmFocus = FocusNode();

  @override
  void dispose() {
    _bpmController.dispose();
    _bpmFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MetronomeController>();
    final strings = AppStrings.of(context);
    if (!_bpmFocus.hasFocus &&
        _bpmController.text != controller.bpm.toString()) {
      _bpmController.text = controller.bpm.toString();
    }
    return SafeArea(
      child: Column(
        children: <Widget>[
          GlassPageHeader(title: strings.metronome),
          Expanded(
            child: GlassPageBody(
              maxWidth: 1120,
              child: Column(
                children: <Widget>[
                  if (controller.playbackError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GlassPanel(
                        tint: Theme.of(context).colorScheme.errorContainer,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.volume_off_outlined),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                strings.text(
                                  '声音输出初始化失败，视觉节拍仍可使用：${controller.playbackError}',
                                  'Sound output failed; visual beat remains available: ${controller.playbackError}',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final tempo = _TempoCard(
                        controller: controller,
                        bpmController: _bpmController,
                        bpmFocus: _bpmFocus,
                      );
                      final configuration = _ConfigurationCard(
                        controller: controller,
                      );
                      if (constraints.maxWidth >= 660) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(flex: 3, child: tempo),
                            const SizedBox(width: 16),
                            Expanded(flex: 2, child: configuration),
                          ],
                        );
                      }
                      return Column(
                        children: <Widget>[
                          tempo,
                          const SizedBox(height: 16),
                          configuration,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TempoCard extends StatelessWidget {
  const _TempoCard({
    required this.controller,
    required this.bpmController,
    required this.bpmFocus,
  });

  final MetronomeController controller;
  final TextEditingController bpmController;
  final FocusNode bpmFocus;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return GlassPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(
                controller.timeSignature.numerator,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  width: controller.activeBeat == index ? 28 : 16,
                  height: controller.activeBeat == index ? 28 : 16,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        controller.activeBeat == index &&
                            controller.visualEnabled &&
                            controller.isPlaying
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _RepeatButton(
                icon: Icons.remove_rounded,
                tooltip: strings.text('降低 BPM', 'Decrease BPM'),
                onPressed: () => controller.setBpm(controller.bpm - 1),
              ),
              SizedBox(
                width: 210,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(
                      height: 78,
                      child: TextField(
                        controller: bpmController,
                        focusNode: bpmFocus,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 68,
                            ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (value) {
                          final bpm = int.tryParse(value);
                          if (bpm != null) {
                            controller.setBpm(bpm);
                          }
                          bpmFocus.unfocus();
                        },
                      ),
                    ),
                    Text('BPM', style: Theme.of(context).textTheme.labelLarge),
                  ],
                ),
              ),
              _RepeatButton(
                icon: Icons.add_rounded,
                tooltip: strings.text('提高 BPM', 'Increase BPM'),
                onPressed: () => controller.setBpm(controller.bpm + 1),
              ),
            ],
          ),
          Slider(
            min: 30,
            max: 300,
            divisions: 270,
            value: controller.bpm.toDouble(),
            label: controller.bpm.toString(),
            onChanged: (value) => controller.setBpm(value.round()),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: controller.tap,
                icon: const Icon(Icons.touch_app_rounded),
                label: Text(
                  controller.tapCount <= 1
                      ? strings.text('连续点按测速', 'Tap repeatedly')
                      : strings.text(
                          '${controller.tapCount} 次 · ${controller.tapTempoBpm ?? '—'} BPM',
                          '${controller.tapCount} taps · ${controller.tapTempoBpm ?? '—'} BPM',
                        ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: controller.isPlaying
                    ? controller.pause
                    : controller.isPaused
                    ? controller.resume
                    : controller.start,
                icon: Icon(
                  controller.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
                label: Text(
                  controller.isPlaying
                      ? strings.text('暂停', 'Pause')
                      : controller.isPaused
                      ? strings.text('继续', 'Resume')
                      : strings.text('开始', 'Start'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: strings.text('停止', 'Stop'),
                onPressed: controller.isPlaying || controller.isPaused
                    ? controller.stop
                    : null,
                icon: const Icon(Icons.stop_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              controller.isPlaying
                  ? strings.text(
                      '正在播放 · 第 ${controller.activeBeat < 0 ? 1 : controller.activeBeat + 1} 拍',
                      'Playing · beat ${controller.activeBeat < 0 ? 1 : controller.activeBeat + 1}',
                    )
                  : controller.isPaused
                  ? strings.text(
                      '已暂停 · 保留在第 ${controller.activeBeat < 0 ? 1 : controller.activeBeat + 1} 拍，继续后接下一拍',
                      'Paused at beat ${controller.activeBeat < 0 ? 1 : controller.activeBeat + 1}; resume continues with the next beat',
                    )
                  : strings.text(
                      '已停止 · 下一次从第一拍开始',
                      'Stopped · next start begins at beat one',
                    ),
              key: ValueKey<(bool, bool)>((
                controller.isPlaying,
                controller.isPaused,
              )),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _RepeatButton extends StatefulWidget {
  const _RepeatButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Future<void> Function() onPressed;

  @override
  State<_RepeatButton> createState() => _RepeatButtonState();
}

class _RepeatButtonState extends State<_RepeatButton> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onLongPressStart: (_) {
          widget.onPressed();
          _timer = Timer.periodic(
            const Duration(milliseconds: 90),
            (_) => widget.onPressed(),
          );
        },
        onLongPressEnd: (_) {
          _timer?.cancel();
          _timer = null;
        },
        child: IconButton.filledTonal(
          onPressed: widget.onPressed,
          icon: Icon(widget.icon),
        ),
      ),
    );
  }
}

class _ConfigurationCard extends StatelessWidget {
  const _ConfigurationCard({required this.controller});

  final MetronomeController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final settings = context.watch<AppSettings>();
    return GlassPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            strings.text('拍号', 'Time signature'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<TimeSignature>(
                  initialValue:
                      TimeSignature.presets.contains(controller.timeSignature)
                      ? controller.timeSignature
                      : null,
                  hint: Text(controller.timeSignature.label),
                  items: TimeSignature.presets
                      .map(
                        (signature) => DropdownMenuItem<TimeSignature>(
                          value: signature,
                          child: Text(signature.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.setTimeSignature(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: strings.text('自定义拍号', 'Custom signature'),
                onPressed: () => _customSignature(context),
                icon: const Icon(Icons.edit_rounded),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            strings.text('每拍细分（每拍点击数）', 'Beat subdivision (clicks per beat)'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SegmentedButton<Subdivision>(
            showSelectedIcon: false,
            segments: const <ButtonSegment<Subdivision>>[
              ButtonSegment<Subdivision>(
                value: Subdivision.quarter,
                label: Text('×1'),
              ),
              ButtonSegment<Subdivision>(
                value: Subdivision.eighth,
                label: Text('×2'),
              ),
              ButtonSegment<Subdivision>(
                value: Subdivision.triplet,
                label: Text('×3'),
              ),
              ButtonSegment<Subdivision>(
                value: Subdivision.sixteenth,
                label: Text('×4'),
              ),
            ],
            selected: <Subdivision>{controller.subdivision},
            onSelectionChanged: (value) {
              controller.setSubdivision(value.first);
            },
          ),
          const SizedBox(height: 20),
          Text(
            strings.text('每拍重音', 'Beat accents'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List<Widget>.generate(controller.accents.length, (index) {
              final accent = controller.accents[index];
              return ActionChip(
                avatar: Icon(switch (accent) {
                  BeatAccent.accent => Icons.keyboard_double_arrow_up,
                  BeatAccent.normal => Icons.circle,
                  BeatAccent.muted => Icons.volume_off,
                }, size: 18),
                label: Text('${index + 1}'),
                onPressed: () {
                  final next = BeatAccent
                      .values[(accent.index + 1) % BeatAccent.values.length];
                  controller.setAccent(index, next);
                },
              );
            }),
          ),
          const Divider(height: 32),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.text('节拍音效', 'Click sound')),
            subtitle: Text(
              strings.text('选择预加载的离线音色', 'Choose an offline sound set'),
            ),
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
            title: Text(strings.text('声音节拍', 'Sound')),
            value: controller.soundEnabled,
            onChanged: controller.setSoundEnabled,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.text('视觉节拍', 'Visual')),
            value: controller.visualEnabled,
            onChanged: controller.setVisualEnabled,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.text('振动节拍', 'Vibration')),
            subtitle: Text(
              strings.text(
                '仅在支持触觉反馈的移动设备生效',
                'Effective on mobile devices with haptics',
              ),
            ),
            value: settings.vibrationEnabled,
            onChanged: settings.setVibrationEnabled,
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

  Future<void> _customSignature(BuildContext context) async {
    final strings = AppStrings.of(context);
    var numerator = controller.timeSignature.numerator;
    var denominator = controller.timeSignature.denominator;
    final result = await showDialog<TimeSignature>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(strings.text('自定义拍号', 'Custom time signature')),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButton<int>(
                value: numerator,
                items: List<DropdownMenuItem<int>>.generate(
                  16,
                  (index) => DropdownMenuItem<int>(
                    value: index + 1,
                    child: Text('${index + 1}'),
                  ),
                ),
                onChanged: (value) {
                  setDialogState(() => numerator = value!);
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('/', style: TextStyle(fontSize: 28)),
              ),
              DropdownButton<int>(
                value: denominator,
                items: <int>[2, 4, 8, 16]
                    .map(
                      (value) => DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setDialogState(() => denominator = value!);
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(strings.text('取消', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                TimeSignature(numerator, denominator),
              ),
              child: Text(strings.text('应用', 'Apply')),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      await controller.setTimeSignature(result);
    }
  }
}
