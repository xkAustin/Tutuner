import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutuner/app/localization/app_strings.dart';
import 'package:tutuner/core/music/note.dart';
import 'package:tutuner/core/music/tuning.dart';
import 'package:tutuner/core/music/tuning_repository.dart';
import 'package:tutuner/core/settings/app_settings.dart';
import 'package:tutuner/features/tuner/domain/tuner_controller.dart';
import 'package:tutuner/features/tuner/presentation/tuning_library_screen.dart';
import 'package:tutuner/shared/widgets/liquid_glass.dart';

class TunerScreen extends StatefulWidget {
  const TunerScreen({super.key});

  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final controller = context.read<TunerController>();
      if (controller.tuning == null) {
        final presets = context.read<TuningRepository>().all;
        controller.setTuning(
          presets.firstWhere(
            (tuning) => tuning.id == 'standard',
            orElse: () => presets.first,
          ),
        );
      }
      controller.start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TunerController>();
    final strings = AppStrings.of(context);
    return SafeArea(
      child: Column(
        children: <Widget>[
          GlassPageHeader(
            title: strings.tuner,
            actions: <Widget>[
              IconButton(
                tooltip: strings.text('调弦库', 'Tuning library'),
                onPressed: () => _openTuningLibrary(context),
                icon: const Icon(Icons.library_music_outlined),
              ),
            ],
          ),
          Expanded(
            child: GlassPageBody(
              maxWidth: 1160,
              child: Column(
                children: <Widget>[
                  SegmentedButton<TunerMode>(
                    segments: <ButtonSegment<TunerMode>>[
                      ButtonSegment<TunerMode>(
                        value: TunerMode.guitar,
                        icon: const Icon(Icons.music_note_rounded),
                        label: Text(strings.text('吉他调弦', 'Guitar')),
                      ),
                      ButtonSegment<TunerMode>(
                        value: TunerMode.twentyFourTet,
                        icon: const Icon(Icons.blur_on_rounded),
                        label: Text(strings.text('24 平均律', '24-TET')),
                      ),
                    ],
                    selected: <TunerMode>{controller.mode},
                    onSelectionChanged: (selection) {
                      controller.setMode(selection.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  if (controller.inputState ==
                          TunerInputState.permissionDenied ||
                      controller.inputState == TunerInputState.error ||
                      controller.inputState == TunerInputState.interrupted)
                    _InputIssueCard(controller: controller),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final reading = _ReadingCard(controller: controller);
                      final controls = _TunerControls(controller: controller);
                      if (constraints.maxWidth >= 660) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(flex: 3, child: reading),
                            const SizedBox(width: 16),
                            Expanded(flex: 2, child: controls),
                          ],
                        );
                      }
                      return Column(
                        children: <Widget>[
                          reading,
                          const SizedBox(height: 16),
                          controls,
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

  Future<void> _openTuningLibrary(BuildContext context) async {
    final selected = await Navigator.of(context).push(
      MaterialPageRoute<dynamic>(builder: (_) => const TuningLibraryScreen()),
    );
    if (selected != null && context.mounted) {
      context.read<TunerController>().setTuning(selected);
    }
  }
}

class _InputIssueCard extends StatelessWidget {
  const _InputIssueCard({required this.controller});

  final TunerController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isPermission =
        controller.inputState == TunerInputState.permissionDenied;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassPanel(
        tint: Theme.of(context).colorScheme.errorContainer,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Icon(isPermission ? Icons.mic_off_outlined : Icons.info_outline),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isPermission
                    ? strings.text(
                        'Tutuner 需要麦克风权限来分析音高。请允许权限后重试；若系统已永久拒绝，请在系统设置中为 Tutuner 开启麦克风。',
                        'Tutuner needs microphone access to analyze pitch. Allow it and retry. If access was permanently denied, enable the microphone for Tutuner in system settings.',
                      )
                    : controller.errorMessage ??
                          strings.text(
                            '音频输入已中断，请检查设备后重新开始。',
                            'Audio input was interrupted. Check the device and restart.',
                          ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: controller.start,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(strings.text('重试', 'Retry')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({required this.controller});

  final TunerController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final reading = controller.reading;
    final status = _statusLabel(strings, reading?.status);
    final color = _statusColor(context, reading?.status);
    final maxCents = controller.mode == TunerMode.twentyFourTet ? 25.0 : 50.0;
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Column(
        children: <Widget>[
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              reading?.targetLabel ?? '—',
              key: ValueKey<String?>(reading?.targetLabel),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 72,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(_statusIcon(reading?.status), color: color),
              const SizedBox(width: 8),
              Text(
                status,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 96,
            width: double.infinity,
            child: CustomPaint(
              painter: _TuningGaugePainter(
                cents: reading?.cents,
                maxCents: maxCents,
                color: color,
                outline: Theme.of(context).colorScheme.outlineVariant,
                textColor: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 28,
            runSpacing: 12,
            children: <Widget>[
              _Metric(
                label: strings.text('输入频率', 'Input'),
                value: reading == null
                    ? '— Hz'
                    : '${reading.inputFrequency.toStringAsFixed(2)} Hz',
              ),
              _Metric(
                label: strings.text('目标频率', 'Target'),
                value: reading == null
                    ? '— Hz'
                    : '${reading.targetFrequency.toStringAsFixed(2)} Hz',
              ),
              _Metric(
                label: strings.text('偏差', 'Offset'),
                value: reading == null
                    ? '— cent'
                    : '${reading.cents >= 0 ? '+' : ''}${reading.cents.toStringAsFixed(1)} cent',
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: <Widget>[
              const Icon(Icons.graphic_eq_rounded, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: LinearProgressIndicator(
                  value: reading?.signalStrength ?? 0,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                reading == null
                    ? strings.waiting
                    : reading.confidence < 0.82
                    ? strings.text('置信度较低', 'Low confidence')
                    : reading.isStable
                    ? strings.text('信号稳定', 'Stable signal')
                    : strings.text('正在稳定', 'Stabilizing'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(AppStrings strings, IntonationStatus? status) {
    return switch (status) {
      IntonationStatus.veryLow => strings.low,
      IntonationStatus.low => strings.closeLow,
      IntonationStatus.inTune => strings.inTune,
      IntonationStatus.high => strings.closeHigh,
      IntonationStatus.veryHigh => strings.high,
      _ => strings.waiting,
    };
  }

  Color _statusColor(BuildContext context, IntonationStatus? status) {
    final scheme = Theme.of(context).colorScheme;
    return switch (status) {
      IntonationStatus.inTune => const Color(0xFF18A36F),
      IntonationStatus.low || IntonationStatus.high => const Color(0xFFD18B00),
      IntonationStatus.veryLow || IntonationStatus.veryHigh => scheme.error,
      _ => scheme.onSurfaceVariant,
    };
  }

  IconData _statusIcon(IntonationStatus? status) {
    return switch (status) {
      IntonationStatus.veryLow ||
      IntonationStatus.low => Icons.arrow_back_rounded,
      IntonationStatus.inTune => Icons.check_circle_rounded,
      IntonationStatus.high ||
      IntonationStatus.veryHigh => Icons.arrow_forward_rounded,
      _ => Icons.mic_rounded,
    };
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 3),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _TunerControls extends StatelessWidget {
  const _TunerControls({required this.controller});

  final TunerController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    if (controller.mode == TunerMode.twentyFourTet) {
      return GlassPanel(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              strings.text('24 平均律自由调音', '24-TET chromatic tuning'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              strings.text(
                '每个八度分为 24 个等距音级，相邻音级相差 50 cents。↑ 表示比普通十二平均律音高高 50 cents。',
                'Each octave is divided into 24 equal steps, 50 cents apart. ↑ marks a pitch 50 cents above its twelve-tone note.',
              ),
            ),
            const SizedBox(height: 18),
            const Row(
              children: <Widget>[
                Icon(Icons.arrow_back_rounded),
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('±25 cents'),
                ),
                Expanded(child: Divider()),
                Icon(Icons.arrow_forward_rounded),
              ],
            ),
          ],
        ),
      );
    }
    final tuning = controller.tuning;
    return GlassPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            strings.text('当前调弦', 'Current tuning'),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Text(
            tuning == null
                ? '—'
                : strings.isChinese
                ? tuning.nameZh
                : tuning.nameEn,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              segments: <ButtonSegment<bool>>[
                ButtonSegment<bool>(
                  value: true,
                  icon: const Icon(Icons.radar_rounded),
                  label: Text(strings.text('自动检测', 'Auto detect')),
                ),
                ButtonSegment<bool>(
                  value: false,
                  icon: const Icon(Icons.touch_app_rounded),
                  label: Text(strings.text('手动选弦', 'Manual')),
                ),
              ],
              selected: <bool>{controller.automaticString},
              onSelectionChanged: (selection) {
                controller.setAutomaticString(selection.first);
              },
            ),
          ),
          const SizedBox(height: 14),
          if (tuning != null) ...<Widget>[
            _DetectionStatus(
              controller: controller,
              stringCount: tuning.stringCount,
            ),
            const SizedBox(height: 10),
            _GuitarStringDiagram(
              strings: tuning.strings,
              selectedStringNumber: controller.selectedStringNumber,
              automatic: controller.automaticString,
              spelling: context.watch<AppSettings>().noteSpelling,
              onSelected: controller.lockString,
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final selected = await Navigator.of(context).push(
                  MaterialPageRoute<dynamic>(
                    builder: (_) => const TuningLibraryScreen(),
                  ),
                );
                if (selected != null && context.mounted) {
                  controller.setTuning(selected);
                }
              },
              icon: const Icon(Icons.swap_horiz_rounded),
              label: Text(strings.text('切换调弦预设', 'Change tuning')),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetectionStatus extends StatelessWidget {
  const _DetectionStatus({required this.controller, required this.stringCount});

  final TunerController controller;
  final int stringCount;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final selected = controller.selectedStringNumber;
    final automatic = controller.automaticString;
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.primary.withValues(
            alpha: selected == null ? 0.18 : 0.4,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            automatic ? Icons.graphic_eq_rounded : Icons.lock_rounded,
            color: scheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              selected == null
                  ? strings.text(
                      '请拨动一根琴弦，正在等待识别',
                      'Pluck a string to begin detection',
                    )
                  : automatic
                  ? strings.text(
                      '检测到第 $selected 弦（共 $stringCount 弦）',
                      'Detected string $selected of $stringCount',
                    )
                  : strings.text(
                      '已锁定第 $selected 弦，点击图中的琴弦可切换',
                      'String $selected locked; tap the diagram to change',
                    ),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuitarStringDiagram extends StatelessWidget {
  const _GuitarStringDiagram({
    required this.strings,
    required this.selectedStringNumber,
    required this.automatic,
    required this.spelling,
    required this.onSelected,
  });

  final List<TuningString> strings;
  final int? selectedStringNumber;
  final bool automatic;
  final NoteSpelling spelling;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const height = 188.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: ColoredBox(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.30),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = strings.length <= 6
                  ? constraints.maxWidth
                  : strings.length * 46.0 + 24;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: strings.length <= 6
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                child: SizedBox(
                  width: contentWidth,
                  height: height,
                  child: Stack(
                    children: <Widget>[
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _FretboardPainter(
                            stringCount: strings.length,
                            selectedIndex: strings.indexWhere(
                              (string) => string.number == selectedStringNumber,
                            ),
                            lineColor: scheme.onSurfaceVariant,
                            selectedColor: scheme.primary,
                            surfaceColor: scheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                      for (var index = 0; index < strings.length; index++)
                        Positioned(
                          left: contentWidth * index / strings.length,
                          top: 0,
                          bottom: 0,
                          width: contentWidth / strings.length,
                          child: _StringDiagramColumn(
                            key: ValueKey<int>(strings[index].number),
                            number: strings[index].number,
                            noteLabel: strings[index].note.label(spelling),
                            selected:
                                strings[index].number == selectedStringNumber,
                            automatic: automatic,
                            onTap: () => onSelected(strings[index].number),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StringDiagramColumn extends StatelessWidget {
  const _StringDiagramColumn({
    required this.number,
    required this.noteLabel,
    required this.selected,
    required this.automatic,
    required this.onTap,
    super.key,
  });

  final int number;
  final String noteLabel;
  final bool selected;
  final bool automatic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
          child: Column(
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? scheme.primary
                      : scheme.surface.withValues(alpha: 0.78),
                  border: Border.all(
                    color: selected ? scheme.primary : scheme.outlineVariant,
                  ),
                ),
                child: Text(
                  number.toString(),
                  style: TextStyle(
                    color: selected
                        ? scheme.onPrimary
                        : scheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                constraints: const BoxConstraints(minWidth: 38),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? scheme.primaryContainer
                      : scheme.surface.withValues(alpha: 0.84),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? scheme.primary : scheme.outlineVariant,
                  ),
                  boxShadow: selected
                      ? <BoxShadow>[
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.28),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (selected)
                      Icon(
                        automatic ? Icons.radar_rounded : Icons.lock_rounded,
                        size: 12,
                        color: scheme.primary,
                      ),
                    Text(
                      noteLabel,
                      maxLines: 1,
                      style: TextStyle(
                        color: selected ? scheme.primary : scheme.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FretboardPainter extends CustomPainter {
  const _FretboardPainter({
    required this.stringCount,
    required this.selectedIndex,
    required this.lineColor,
    required this.selectedColor,
    required this.surfaceColor,
  });

  final int stringCount;
  final int selectedIndex;
  final Color lineColor;
  final Color selectedColor;
  final Color surfaceColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (stringCount == 0) {
      return;
    }
    final board = RRect.fromRectAndRadius(
      Rect.fromLTRB(8, 34, size.width - 8, size.height - 37),
      const Radius.circular(20),
    );
    canvas.drawRRect(
      board,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            surfaceColor.withValues(alpha: 0.72),
            surfaceColor.withValues(alpha: 0.30),
          ],
        ).createShader(board.outerRect),
    );

    for (var fret = 0; fret <= 4; fret++) {
      final y = 48 + fret * 22.0;
      canvas.drawLine(
        Offset(10, y),
        Offset(size.width - 10, y),
        Paint()
          ..color = lineColor.withValues(alpha: fret == 0 ? 0.40 : 0.13)
          ..strokeWidth = fret == 0 ? 3 : 1,
      );
    }

    for (var index = 0; index < stringCount; index++) {
      final x = size.width * (index + 0.5) / stringCount;
      final selected = index == selectedIndex;
      if (selected) {
        canvas.drawLine(
          Offset(x, 29),
          Offset(x, size.height - 31),
          Paint()
            ..color = selectedColor.withValues(alpha: 0.18)
            ..strokeWidth = 13
            ..strokeCap = StrokeCap.round,
        );
      }
      canvas.drawLine(
        Offset(x, 29),
        Offset(x, size.height - 31),
        Paint()
          ..color = selected ? selectedColor : lineColor.withValues(alpha: 0.56)
          ..strokeWidth = selected ? 3.2 : 1.1 + (stringCount - index) * 0.18
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        Offset(x, 103),
        selected ? 5 : 2.5,
        Paint()
          ..color = selected
              ? selectedColor
              : lineColor.withValues(alpha: 0.30),
      );
    }
  }

  @override
  bool shouldRepaint(_FretboardPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.stringCount != stringCount ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.selectedColor != selectedColor ||
        oldDelegate.surfaceColor != surfaceColor;
  }
}

class _TuningGaugePainter extends CustomPainter {
  const _TuningGaugePainter({
    required this.cents,
    required this.maxCents,
    required this.color,
    required this.outline,
    required this.textColor,
  });

  final double? cents;
  final double maxCents;
  final Color color;
  final Color outline;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height * 0.62;
    final trackPaint = Paint()
      ..color = outline
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.06, centerY),
      Offset(size.width * 0.94, centerY),
      trackPaint,
    );
    for (var tick = -5; tick <= 5; tick++) {
      final x = size.width * (0.5 + tick * 0.088);
      final height = tick == 0
          ? 26.0
          : tick.isEven
          ? 18.0
          : 11.0;
      canvas.drawLine(
        Offset(x, centerY - height / 2),
        Offset(x, centerY + height / 2),
        trackPaint..strokeWidth = tick == 0 ? 4 : 2,
      );
    }
    final normalized = ((cents ?? 0) / maxCents).clamp(-1.0, 1.0);
    final x = size.width * (0.5 + normalized * 0.44);
    final needle = Paint()
      ..color = color
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x, 8), Offset(x, centerY - 18), needle);
    final path = Path()
      ..moveTo(x - 8, centerY - 19)
      ..lineTo(x + 8, centerY - 19)
      ..lineTo(x, centerY - 7)
      ..close();
    canvas.drawPath(path, needle);
  }

  @override
  bool shouldRepaint(_TuningGaugePainter oldDelegate) {
    return oldDelegate.cents != cents ||
        oldDelegate.maxCents != maxCents ||
        oldDelegate.color != color;
  }
}
