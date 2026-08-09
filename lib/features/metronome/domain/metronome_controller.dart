import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tutuner/core/audio/audio_output_service.dart';
import 'package:tutuner/core/metronome/beat_scheduler.dart';
import 'package:tutuner/core/metronome/tap_tempo.dart';
import 'package:tutuner/core/metronome/time_signature.dart';
import 'package:tutuner/core/settings/app_settings.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class MetronomeController extends ChangeNotifier {
  MetronomeController({
    required AppSettings settings,
    AudioOutputService? audioOutput,
  }) : _settings = settings,
       _audioOutput = audioOutput ?? SoloudAudioOutputService() {
    _clock.start();
    bpm = settings.bpm;
    timeSignature = settings.metronomeTimeSignature;
    subdivision = settings.metronomeSubdivision;
    accents = List<BeatAccent>.of(settings.metronomeAccents);
    soundEnabled = settings.metronomeSoundEnabled;
    visualEnabled = settings.metronomeVisualEnabled;
  }

  final AppSettings _settings;
  final AudioOutputService _audioOutput;
  final Stopwatch _clock = Stopwatch();
  final TapTempo _tapTempo = TapTempo();
  Timer? _timer;
  BeatTimeline? _timeline;
  int _nextEventIndex = 0;
  bool _wakeLockActive = false;

  late int bpm;
  late TimeSignature timeSignature;
  late Subdivision subdivision;
  late List<BeatAccent> accents;
  bool isPlaying = false;
  bool isPaused = false;
  late bool soundEnabled;
  late bool visualEnabled;
  int activeBeat = -1;
  int activeSubdivision = -1;
  int tapCount = 0;
  int? tapTempoBpm;
  Object? playbackError;

  Future<void> start() async {
    if (isPaused) {
      return resume();
    }
    if (isPlaying) {
      return;
    }
    playbackError = null;
    try {
      await _audioOutput.initialize();
    } on Object catch (error) {
      playbackError = error;
    }
    _nextEventIndex = 0;
    activeBeat = -1;
    activeSubdivision = -1;
    _timeline = _timelineWithNextEventAt(
      _nextEventIndex,
      _clock.elapsedMicroseconds + 80000,
    );
    isPlaying = true;
    isPaused = false;
    if (_settings.keepAwake) {
      await WakelockPlus.enable();
      _wakeLockActive = true;
    }
    notifyListeners();
    _scheduleNext();
  }

  Future<void> pause() async {
    if (!isPlaying) {
      return;
    }
    _timer?.cancel();
    isPlaying = false;
    isPaused = true;
    await _releaseWakeLock();
    notifyListeners();
  }

  Future<void> stop() async {
    _timer?.cancel();
    isPlaying = false;
    isPaused = false;
    _timeline = null;
    _nextEventIndex = 0;
    activeBeat = -1;
    activeSubdivision = -1;
    await _releaseWakeLock();
    notifyListeners();
  }

  Future<void> resume() async {
    if (!isPaused || isPlaying) {
      return;
    }
    playbackError = null;
    try {
      await _audioOutput.initialize();
    } on Object catch (error) {
      playbackError = error;
    }
    _timeline = _timelineWithNextEventAt(
      _nextEventIndex,
      _clock.elapsedMicroseconds + 80000,
    );
    isPlaying = true;
    isPaused = false;
    if (_settings.keepAwake) {
      await WakelockPlus.enable();
      _wakeLockActive = true;
    }
    notifyListeners();
    _scheduleNext();
  }

  Future<void> setBpm(int value) async {
    bpm = value.clamp(30, 300);
    await _settings.setBpm(bpm);
    await _restartAtBoundaryIfPlaying();
    notifyListeners();
  }

  Future<void> tap() async {
    final result = _tapTempo.addTap(_clock.elapsedMicroseconds);
    tapCount = result.tapCount;
    tapTempoBpm = result.bpm;
    notifyListeners();
    if (result.bpm != null) {
      await setBpm(result.bpm!);
    }
  }

  Future<void> setTimeSignature(TimeSignature value) async {
    await _settings.setMetronomeTimeSignature(value);
    timeSignature = _settings.metronomeTimeSignature;
    accents = List<BeatAccent>.of(_settings.metronomeAccents);
    await _restartAtBoundaryIfPlaying();
    notifyListeners();
  }

  Future<void> setSubdivision(Subdivision value) async {
    await _settings.setMetronomeSubdivision(value);
    subdivision = _settings.metronomeSubdivision;
    await _restartAtBoundaryIfPlaying();
    notifyListeners();
  }

  Future<void> setAccent(int beat, BeatAccent value) async {
    accents = List<BeatAccent>.of(accents)..[beat] = value;
    await _settings.setMetronomeAccents(accents);
    await _restartAtBoundaryIfPlaying();
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    await _settings.setMetronomeSoundEnabled(value);
    soundEnabled = _settings.metronomeSoundEnabled;
    notifyListeners();
  }

  Future<void> setVisualEnabled(bool value) async {
    await _settings.setMetronomeVisualEnabled(value);
    visualEnabled = _settings.metronomeVisualEnabled;
    notifyListeners();
  }

  Future<void> _restartAtBoundaryIfPlaying() async {
    if (!isPlaying) {
      return;
    }
    _timer?.cancel();
    _timeline = _timelineWithNextEventAt(
      _nextEventIndex,
      _clock.elapsedMicroseconds + 50000,
    );
    _scheduleNext();
  }

  BeatTimeline _timelineWithNextEventAt(int index, int dueMicros) {
    final interval = 60000000 / bpm / subdivision.partsPerBeat;
    return BeatTimeline(
      anchorMicros: dueMicros - (index * interval).round(),
      bpm: bpm,
      timeSignature: timeSignature,
      subdivision: subdivision,
      accents: accents,
    );
  }

  Future<void> _releaseWakeLock() async {
    if (!_wakeLockActive) {
      return;
    }
    _wakeLockActive = false;
    await WakelockPlus.disable();
  }

  void _scheduleNext() {
    if (!isPlaying || _timeline == null) {
      return;
    }
    var event = _timeline!.eventAt(_nextEventIndex);
    final now = _clock.elapsedMicroseconds;
    if (event.dueMicros < now - 20000) {
      _nextEventIndex = _timeline!.firstIndexAtOrAfter(now);
      event = _timeline!.eventAt(_nextEventIndex);
    }
    final remaining = event.dueMicros - now;
    _timer = Timer(
      Duration(microseconds: remaining.clamp(0, 10000000).toInt()),
      () => _fireOrReschedule(event),
    );
  }

  void _fireOrReschedule(ScheduledBeat event) {
    if (!isPlaying) {
      return;
    }
    final remaining = event.dueMicros - _clock.elapsedMicroseconds;
    if (remaining > 500) {
      _timer = Timer(
        Duration(microseconds: remaining),
        () => _fireOrReschedule(event),
      );
      return;
    }
    _emit(event);
    _nextEventIndex = event.index + 1;
    _scheduleNext();
  }

  void _emit(ScheduledBeat event) {
    activeBeat = event.beatInBar;
    activeSubdivision = event.subdivisionInBeat;
    if (soundEnabled && event.accent != BeatAccent.muted) {
      final sound = event.subdivisionInBeat != 0
          ? MetronomeSound.subdivision
          : event.accent == BeatAccent.accent
          ? MetronomeSound.accent
          : MetronomeSound.beat;
      _audioOutput.play(
        sound,
        pack: _settings.metronomeSoundPack,
        volume: _settings.metronomeVolume,
      );
    }
    if (_settings.vibrationEnabled && event.subdivisionInBeat == 0) {
      unawaited(HapticFeedback.selectionClick());
    }
    if (visualEnabled) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_releaseWakeLock());
    unawaited(_audioOutput.dispose());
    super.dispose();
  }
}
