import 'dart:ui';

import 'package:flutter/material.dart';

class GlassPageHeader extends StatelessWidget {
  const GlassPageHeader({
    required this.title,
    this.leading,
    this.actions = const <Widget>[],
    super.key,
  });

  final String title;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 8),
      child: SizedBox(
        height: 44,
        child: Row(
          children: <Widget>[
            if (leading != null) ...<Widget>[
              leading!,
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

class GlassPageBody extends StatelessWidget {
  const GlassPageBody({
    required this.child,
    this.maxWidth = 1120,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 24),
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, viewport) {
        final minimumHeight = (viewport.maxHeight - padding.vertical).clamp(
          0.0,
          double.infinity,
        );
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minimumHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class GlassPill extends StatelessWidget {
  const GlassPill({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    this.selected = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: selected
                  ? <Color>[
                      scheme.primary.withValues(alpha: dark ? 0.34 : 0.22),
                      scheme.primaryContainer.withValues(
                        alpha: dark ? 0.22 : 0.42,
                      ),
                    ]
                  : <Color>[
                      scheme.surface.withValues(alpha: dark ? 0.44 : 0.66),
                      scheme.surface.withValues(alpha: dark ? 0.24 : 0.38),
                    ],
            ),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.42)
                  : Colors.white.withValues(alpha: dark ? 0.13 : 0.62),
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class GlassDropdown<T> extends StatelessWidget {
  const GlassDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    super.key,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassPill(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isDense: true,
          borderRadius: BorderRadius.circular(18),
          dropdownColor: Theme.of(
            context,
          ).colorScheme.surface.withValues(alpha: 0.96),
        ),
      ),
    );
  }
}

class LiquidBackground extends StatelessWidget {
  const LiquidBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const <Color>[
                  Color(0xFF08111E),
                  Color(0xFF111827),
                  Color(0xFF0B1324),
                ]
              : const <Color>[
                  Color(0xFFF4F9FF),
                  Color(0xFFEAF4FF),
                  Color(0xFFF8F4FF),
                ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const Positioned(
            top: -140,
            right: -80,
            child: _LiquidOrb(
              size: 380,
              colors: <Color>[Color(0x6634C8FF), Color(0x0034C8FF)],
            ),
          ),
          const Positioned(
            bottom: -180,
            left: -110,
            child: _LiquidOrb(
              size: 420,
              colors: <Color>[Color(0x665E5CE6), Color(0x005E5CE6)],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _LiquidOrb extends StatelessWidget {
  const _LiquidOrb({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    required this.child,
    this.padding,
    this.radius = 28,
    this.tint,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(radius);
    final base = tint ?? theme.colorScheme.surface;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.30 : 0.10),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: dark ? 0.04 : 0.40),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  base.withValues(alpha: dark ? 0.54 : 0.72),
                  base.withValues(alpha: dark ? 0.32 : 0.46),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: dark ? 0.14 : 0.72),
              ),
            ),
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 16,
                  right: 16,
                  top: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: dark ? 0.10 : 0.62),
                    ),
                  ),
                ),
                Padding(padding: padding ?? EdgeInsets.zero, child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GlassNavigationSurface extends StatelessWidget {
  const GlassNavigationSurface({
    required this.child,
    this.borderSide = GlassBorderSide.top,
    super.key,
  });

  final Widget child;
  final GlassBorderSide borderSide;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: dark ? 0.60 : 0.68),
            border: Border(
              top: borderSide == GlassBorderSide.top
                  ? BorderSide(
                      color: Colors.white.withValues(alpha: dark ? 0.12 : 0.70),
                    )
                  : BorderSide.none,
              right: borderSide == GlassBorderSide.right
                  ? BorderSide(
                      color: Colors.white.withValues(alpha: dark ? 0.12 : 0.70),
                    )
                  : BorderSide.none,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

enum GlassBorderSide { top, right }
