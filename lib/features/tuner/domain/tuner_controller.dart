import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:tutuner/core/audio/audio_input_service.dart';
import 'package:tutuner/core/dsp/frequency_smoother.dart';
import 'package:tutuner/core/dsp/noise_gate.dart';
import 'package:tutuner/core/dsp/pitch_detector.dart';
import 'package:tutuner/core/dsp/yin_pitch_detector.dart';
import 'package:tutuner/core/music/note.dart';
import 'package:tutuner/core/music/temperament.dart';
import 'package:tutuner/core/music/tuning.dart';
import 'package:tutuner/core/settings/app_settings.dart';
import 'package:tutuner/features/tuner/domain/string_target_tracker.dart';

enum TunerMode { twentyFourTet, guitar }

enum TunerInputState {
  idle,
  starting,
  listening,
  permissionDenied,
  interrupted,
  error,
}

enum IntonationStatus { waiting, veryLow, low, inTune, high, veryHigh }

class TunerReading {
  const TunerReading({
    required this.inputFrequency,
    required this.targetFrequency,
    required this.targetLabel,
    required this.cents,
    required this.confidence,
    required this.signalStrength,
    required this.isStable,
    required this.status,
    this.stringNumber,
  });

  final double inputFrequency;
  final double targetFrequency;
  final String targetLabel;
  final double cents;
  final double confidence;
  final double signalStrength;
  final bool isStable;
  final IntonationStatus status;
  final int? stringNumber;
}

class _AnalysisRequest {
  const _AnalysisRequest({
    required this.samples,
    required this.sampleRate,
    required this.rmsThreshold,
  });

  final Float64List samples;
  final int sampleRate;
  final double rmsThreshold;
}

PitchEstimate? _analyzeFrame(_AnalysisRequest request) {
  return YinPitchDetector(
    noiseGate: NoiseGate(rmsThreshold: request.rmsThreshold),
  ).detect(request.samples, request.sampleRate);
}

class TunerController extends ChangeNotifier {
  TunerController({
    required AppSettings settings,
    AudioInputService? audioInput,
  }) : _settings = settings,
       _audioInput = audioInput ?? RecordAudioInputService() {
    _uiClock.start();
    _recordStateSubscription = _audioInput.stateChanges.listen(
      _handleRecordState,
    );
  }

  static const _frameSize = 8192;
  static const _hopSize = 2048;

  final AppSettings _settings;
  final AudioInputService _audioInput;
  final FrequencySmoother _smoother = FrequencySmoother();
  final StringTargetTracker _stringTracker = StringTargetTracker();
  final Stopwatch _uiClock = Stopwatch();
  final List<double> _sampleBuffer = <double>[];
  StreamSubscription<Float64List>? _sampleSubscription;
  StreamSubscription<RecordState>? _recordStateSubscription;
  Float64List? _pendingFrame;
  Future<void> _audioTransition = Future<void>.value();
  bool _analysisInProgress = false;
  bool _isDisposed = false;
  int _captureGeneration = 0;
  int _invalidFrames = 0;
  int _lastUiUpdateMicros = 0;

  TunerMode mode = TunerMode.guitar;
  TunerInputState inputState = TunerInputState.idle;
  TunerReading? reading;
  TuningPreset? tuning;
  bool automaticString = true;
  int? lockedStringNumber;
  String? errorMessage;

  int? get selectedStringNumber => automaticString
      ? reading?.stringNumber ?? _stringTracker.currentStringNumber
      : lockedStringNumber;

  Future<void> start() {
    if (_isDisposed) {
      return Future<void>.value();
    }
    if (inputState == TunerInputState.starting ||
        inputState == TunerInputState.listening) {
      return Future<void>.value();
    }
    final generation = ++_captureGeneration;
    inputState = TunerInputState.starting;
    errorMessage = null;
    notifyListeners();
    return _enqueueAudioTransition(() => _startCapture(generation));
  }

  Future<void> _startCapture(int generation) async {
    if (!_isCurrentCapture(generation)) {
      return;
    }
    try {
      final stream = await _audioInput.start();
      if (!_isCurrentCapture(generation)) {
        await _audioInput.stop();
        return;
      }
      await _sampleSubscription?.cancel();
      if (!_isCurrentCapture(generation)) {
        await _audioInput.stop();
        return;
      }
      _sampleSubscription = stream.listen(
        (samples) => _onSamples(samples, generation),
        onError: (Object error, StackTrace stackTrace) {
          if (!_isCurrentCapture(generation)) {
            return;
          }
          inputState = TunerInputState.error;
          errorMessage = error.toString();
          notifyListeners();
        },
        onDone: () {
          if (_isCurrentCapture(generation) &&
              inputState == TunerInputState.listening) {
            inputState = TunerInputState.interrupted;
            notifyListeners();
          }
        },
      );
      if (!_isCurrentCapture(generation)) {
        await _sampleSubscription?.cancel();
        _sampleSubscription = null;
        await _audioInput.stop();
        return;
      }
      inputState = TunerInputState.listening;
      notifyListeners();
    } on AudioInputPermissionException {
      if (!_isCurrentCapture(generation)) {
        return;
      }
      inputState = TunerInputState.permissionDenied;
      notifyListeners();
    } on Object catch (error) {
      if (!_isCurrentCapture(generation)) {
        return;
      }
      inputState = TunerInputState.error;
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> stop({bool interrupted = false}) {
    if (_isDisposed) {
      return Future<void>.value();
    }
    final generation = ++_captureGeneration;
    _sampleBuffer.clear();
    _pendingFrame = null;
    _smoother.reset();
    _stringTracker.reset();
    _invalidFrames = 0;
    reading = null;
    errorMessage = null;
    inputState = interrupted
        ? TunerInputState.interrupted
        : TunerInputState.idle;
    notifyListeners();
    return _enqueueAudioTransition(() => _stopCapture(generation));
  }

  Future<void> _stopCapture(int generation) async {
    try {
      await _sampleSubscription?.cancel();
      _sampleSubscription = null;
      await _audioInput.stop();
    } on Object catch (error) {
      if (_isCurrentCapture(generation)) {
        inputState = TunerInputState.error;
        errorMessage = error.toString();
        notifyListeners();
      }
    }
  }

  void setMode(TunerMode value) {
    mode = value;
    reading = null;
    _smoother.reset();
    _stringTracker.reset();
    notifyListeners();
  }

  void setTuning(TuningPreset value) {
    tuning = value;
    lockedStringNumber = null;
    reading = null;
    _stringTracker.reset();
    notifyListeners();
  }

  void setAutomaticString(bool value) {
    final previouslySelected = selectedStringNumber;
    automaticString = value;
    if (value) {
      lockedStringNumber = null;
      _stringTracker.reset();
    } else {
      lockedStringNumber ??= previouslySelected ?? tuning?.strings.last.number;
    }
    notifyListeners();
  }

  void lockString(int stringNumber) {
    automaticString = false;
    lockedStringNumber = stringNumber;
    reading = null;
    notifyListeners();
  }

  void _onSamples(Float64List samples, int generation) {
    if (!_isCurrentCapture(generation) ||
        inputState != TunerInputState.listening) {
      return;
    }
    _sampleBuffer.addAll(samples);
    while (_sampleBuffer.length >= _frameSize) {
      _pendingFrame = Float64List.fromList(
        _sampleBuffer.take(_frameSize).toList(growable: false),
      );
      _sampleBuffer.removeRange(0, _hopSize);
    }
    if (!_analysisInProgress && _pendingFrame != null) {
      unawaited(_processPendingFrame(generation));
    }
  }

  Future<void> _processPendingFrame(int generation) async {
    _analysisInProgress = true;
    try {
      while (_pendingFrame != null && _isCurrentCapture(generation)) {
        final frame = _pendingFrame!;
        _pendingFrame = null;
        final estimate = await compute(
          _analyzeFrame,
          _AnalysisRequest(
            samples: frame,
            sampleRate: _audioInput.sampleRate,
            rmsThreshold: _settings.inputThreshold,
          ),
        );
        if (!_isCurrentCapture(generation)) {
          return;
        }
        if (estimate == null) {
          _invalidFrames++;
          if (_invalidFrames >= 4) {
            reading = null;
            _notifyAtUiRate();
          }
          continue;
        }
        _invalidFrames = 0;
        final smoothed = _smoother.add(estimate.frequency);
        reading = _makeReading(estimate, smoothed);
        _notifyAtUiRate();
      }
    } finally {
      _analysisInProgress = false;
      if (_pendingFrame != null &&
          !_isDisposed &&
          inputState == TunerInputState.listening) {
        unawaited(_processPendingFrame(_captureGeneration));
      }
    }
  }

  bool _isCurrentCapture(int generation) {
    return !_isDisposed && generation == _captureGeneration;
  }

  Future<void> _enqueueAudioTransition(Future<void> Function() operation) {
    final result = _audioTransition.then((_) => operation());
    _audioTransition = result.then<void>((_) {}, onError: (_, _) {});
    return result;
  }

  TunerReading _makeReading(PitchEstimate estimate, SmoothedPitch smoothed) {
    if (mode == TunerMode.twentyFourTet || tuning == null) {
      final target = twentyFourTet.nearest(
        smoothed.frequency,
        a4: _settings.referencePitch,
      );
      final cents = centsBetween(smoothed.frequency, target.frequency);
      return TunerReading(
        inputFrequency: smoothed.frequency,
        targetFrequency: target.frequency,
        targetLabel: target.label,
        cents: cents,
        confidence: estimate.confidence,
        signalStrength: (estimate.rms / 0.25).clamp(0, 1),
        isStable: smoothed.isStable,
        status: _statusFor(cents),
      );
    }

    final available = tuning!.strings;
    TuningString targetString;
    if (!automaticString && lockedStringNumber != null) {
      targetString = available.firstWhere(
        (string) => string.number == lockedStringNumber,
        orElse: () => available.first,
      );
    } else {
      targetString = _stringTracker.select(
        available,
        smoothed.frequency,
        a4: _settings.referencePitch,
      );
    }
    final targetFrequency = twelveTetFrequency(
      targetString.note,
      a4: _settings.referencePitch,
    );
    final cents = centsBetween(smoothed.frequency, targetFrequency);
    return TunerReading(
      inputFrequency: smoothed.frequency,
      targetFrequency: targetFrequency,
      targetLabel: targetString.note.label(_settings.noteSpelling),
      cents: cents,
      confidence: estimate.confidence,
      signalStrength: (estimate.rms / 0.25).clamp(0, 1),
      isStable: smoothed.isStable,
      status: _statusFor(cents),
      stringNumber: targetString.number,
    );
  }

  IntonationStatus _statusFor(double cents) {
    final magnitude = cents.abs();
    if (magnitude <= _settings.inTuneCents) {
      return IntonationStatus.inTune;
    }
    if (magnitude <= 10) {
      return cents < 0 ? IntonationStatus.low : IntonationStatus.high;
    }
    return cents < 0 ? IntonationStatus.veryLow : IntonationStatus.veryHigh;
  }

  void _notifyAtUiRate() {
    if (_isDisposed) {
      return;
    }
    final now = _uiClock.elapsedMicroseconds;
    if (now - _lastUiUpdateMicros >= 50000 || reading == null) {
      _lastUiUpdateMicros = now;
      notifyListeners();
    }
  }

  void _handleRecordState(RecordState state) {
    if (!_isDisposed &&
        state == RecordState.pause &&
        inputState == TunerInputState.listening) {
      inputState = TunerInputState.interrupted;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _captureGeneration++;
    _sampleBuffer.clear();
    _pendingFrame = null;
    unawaited(_recordStateSubscription?.cancel());
    unawaited(
      _enqueueAudioTransition(() async {
        await _sampleSubscription?.cancel();
        _sampleSubscription = null;
        await _audioInput.stop();
        await _audioInput.dispose();
      }),
    );
    super.dispose();
  }
}
