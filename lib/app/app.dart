import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:tutuner/app/localization/app_strings.dart';
import 'package:tutuner/app/theme/app_theme.dart';
import 'package:tutuner/core/audio/audio_session_service.dart';
import 'package:tutuner/core/settings/app_settings.dart';
import 'package:tutuner/features/metronome/domain/metronome_controller.dart';
import 'package:tutuner/features/metronome/presentation/metronome_screen.dart';
import 'package:tutuner/features/settings/presentation/settings_screen.dart';
import 'package:tutuner/features/tuner/domain/tuner_controller.dart';
import 'package:tutuner/features/tuner/presentation/tuner_screen.dart';
import 'package:tutuner/shared/widgets/liquid_glass.dart';

bool shouldSuspendAudio(AppLifecycleState state) {
  return state != AppLifecycleState.resumed;
}

class TutunerApp extends StatefulWidget {
  const TutunerApp({super.key});

  @override
  State<TutunerApp> createState() => _TutunerAppState();
}

class _TutunerAppState extends State<TutunerApp> with WidgetsBindingObserver {
  final AudioSessionService _audioSession = AudioSessionService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _audioSession.initialize(
        onInterrupted: _interruptAudio,
        onDeviceDisconnected: _interruptAudio,
      );
    });
  }

  void _interruptAudio() {
    if (!mounted) {
      return;
    }
    context.read<TunerController>().stop(interrupted: true);
    context.read<MetronomeController>().pause();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (shouldSuspendAudio(state)) {
      context.read<TunerController>().stop(interrupted: true);
      context.read<MetronomeController>().pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioSession.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tutuner',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AdaptiveShell(),
    );
  }
}

class AdaptiveShell extends StatefulWidget {
  const AdaptiveShell({this.pages, super.key});

  final List<Widget>? pages;

  @override
  State<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends State<AdaptiveShell> {
  int _index = 0;

  static const _pages = <Widget>[
    TunerScreen(),
    MetronomeScreen(),
    SettingsScreen(),
  ];

  List<Widget> get _activePages => widget.pages ?? _pages;

  void _select(int value) {
    if (_index == 0 && value != 0) {
      context.read<TunerController>().stop();
    } else if (_index != 0 && value == 0) {
      context.read<TunerController>().start();
    }
    setState(() => _index = value);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final destinations = <NavigationDestination>[
      NavigationDestination(
        icon: const Icon(Icons.graphic_eq_rounded),
        label: strings.tuner,
      ),
      NavigationDestination(
        icon: const Icon(Icons.av_timer_rounded),
        label: strings.metronome,
      ),
      NavigationDestination(
        icon: const Icon(Icons.tune_rounded),
        label: strings.settings,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final stableMacLayout = defaultTargetPlatform == TargetPlatform.macOS;
        final useRail = stableMacLayout || constraints.maxWidth >= 840;
        final extendRail = !stableMacLayout && constraints.maxWidth >= 1120;
        return Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          body: LiquidBackground(
            child: Row(
              children: <Widget>[
                if (useRail)
                  GlassNavigationSurface(
                    borderSide: GlassBorderSide.right,
                    child: SafeArea(
                      child: NavigationRail(
                        extended: extendRail,
                        selectedIndex: _index,
                        onDestinationSelected: _select,
                        leading: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Icon(Icons.music_note_rounded, size: 30),
                              if (extendRail) ...<Widget>[
                                const SizedBox(width: 10),
                                Text(
                                  strings.appName,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ],
                          ),
                        ),
                        destinations: destinations
                            .map(
                              (item) => NavigationRailDestination(
                                icon: item.icon,
                                label: Text(item.label),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                Expanded(
                  child: IndexedStack(index: _index, children: _activePages),
                ),
              ],
            ),
          ),
          bottomNavigationBar: useRail
              ? null
              : GlassNavigationSurface(
                  child: NavigationBar(
                    selectedIndex: _index,
                    onDestinationSelected: _select,
                    destinations: destinations,
                  ),
                ),
        );
      },
    );
  }
}
