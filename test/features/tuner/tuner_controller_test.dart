import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';
import 'package:tutuner/core/audio/audio_input_service.dart';
import 'package:tutuner/core/settings/app_settings.dart';
import 'package:tutuner/features/tuner/domain/tuner_controller.dart';

class _DelayedAudioInput implements AudioInputService {
  final Completer<void> startCalled = Completer<void>();
  final Completer<Stream<Float64List>> startResult =
      Completer<Stream<Float64List>>();
  final StreamController<RecordState> states =
      StreamController<RecordState>.broadcast();
  int stopCount = 0;

  @override
  int get sampleRate => 48000;

  @override
  Stream<RecordState> get stateChanges => states.stream;

  @override
  Future<Stream<Float64List>> start() {
    if (!startCalled.isCompleted) {
      startCalled.complete();
    }
    return startResult.future;
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  Future<void> dispose() => states.close();
}

class _ImmediateAudioInput implements AudioInputService {
  final StreamController<RecordState> states =
      StreamController<RecordState>.broadcast();
  final StreamController<Float64List> samples =
      StreamController<Float64List>.broadcast(sync: true);
  final Completer<void> stopCalled = Completer<void>();
  Completer<void>? stopGate;
  int startCount = 0;
  int stopCount = 0;
  bool isRecording = false;

  @override
  int get sampleRate => 48000;

  @override
  Stream<RecordState> get stateChanges => states.stream;

  @override
  Future<Stream<Float64List>> start() async {
    startCount++;
    isRecording = true;
    return samples.stream;
  }

  @override
  Future<void> stop() async {
    stopCount++;
    if (!stopCalled.isCompleted) {
      stopCalled.complete();
    }
    await stopGate?.future;
    isRecording = false;
  }

  @override
  Future<void> dispose() async {
    await states.close();
    await samples.close();
  }
}

void main() {
  test('a stop request invalidates an in-flight microphone start', () async {
    final audioInput = _DelayedAudioInput();
    final controller = TunerController(
      settings: AppSettings.inMemory(),
      audioInput: audioInput,
    );

    final starting = controller.start();
    await audioInput.startCalled.future;
    final stopping = controller.stop();
    audioInput.startResult.complete(const Stream<Float64List>.empty());

    await Future.wait(<Future<void>>[starting, stopping]);

    expect(controller.inputState, TunerInputState.idle);
    expect(audioInput.stopCount, greaterThanOrEqualTo(1));
    controller.dispose();
  });

  test('a rapid restart waits for the previous stop to finish', () async {
    final audioInput = _ImmediateAudioInput();
    final controller = TunerController(
      settings: AppSettings.inMemory(),
      audioInput: audioInput,
    );

    await controller.start();
    audioInput.stopGate = Completer<void>();
    final stopping = controller.stop();
    final restarting = controller.start();
    await audioInput.stopCalled.future;

    expect(audioInput.startCount, 1);
    audioInput.stopGate!.complete();
    await Future.wait(<Future<void>>[stopping, restarting]);

    expect(controller.inputState, TunerInputState.listening);
    expect(audioInput.startCount, 2);
    expect(audioInput.isRecording, isTrue);
    controller.dispose();
  });

  test('an analysis result cannot publish after recording stops', () async {
    final audioInput = _ImmediateAudioInput();
    final controller = TunerController(
      settings: AppSettings.inMemory(),
      audioInput: audioInput,
    );
    await controller.start();
    final samples = Float64List.fromList(
      List<double>.generate(
        8192,
        (index) => 0.3 * math.sin(2 * math.pi * 110 * index / 48000),
      ),
    );

    audioInput.samples.add(samples);
    await controller.stop();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(controller.inputState, TunerInputState.idle);
    expect(controller.reading, isNull);
    controller.dispose();
  });
}
