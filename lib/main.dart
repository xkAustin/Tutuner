import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:tutuner/app/app.dart';
import 'package:tutuner/core/music/tuning_repository.dart';
import 'package:tutuner/core/settings/app_settings.dart';
import 'package:tutuner/features/metronome/domain/metronome_controller.dart';
import 'package:tutuner/features/tuner/domain/tuner_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = AppSettings();
  final tunings = TuningRepository();
  await Future.wait(<Future<void>>[settings.load(), tunings.load()]);
  runApp(
    MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<AppSettings>.value(value: settings),
        ChangeNotifierProvider<TuningRepository>.value(value: tunings),
        ChangeNotifierProvider<TunerController>(
          create: (_) => TunerController(settings: settings),
        ),
        ChangeNotifierProvider<MetronomeController>(
          create: (_) => MetronomeController(settings: settings),
        ),
      ],
      child: const TutunerApp(),
    ),
  );
}
