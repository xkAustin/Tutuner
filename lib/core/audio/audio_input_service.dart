import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

class AudioInputPermissionException implements Exception {
  const AudioInputPermissionException();

  @override
  String toString() => 'Microphone permission was denied.';
}

abstract interface class AudioInputService {
  int get sampleRate;
  Stream<RecordState> get stateChanges;

  Future<Stream<Float64List>> start();
  Future<void> stop();
  Future<void> dispose();
}

class RecordAudioInputService implements AudioInputService {
  RecordAudioInputService({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  @override
  int get sampleRate => 48000;

  @override
  Stream<RecordState> get stateChanges => _recorder.onStateChanged();

  @override
  Future<Stream<Float64List>> start() async {
    if (!await _recorder.hasPermission()) {
      throw const AudioInputPermissionException();
    }
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    final bytes = await _recorder.startStream(
      RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
        audioInterruption: AudioInterruptionMode.pause,
        streamBufferSize: 4096,
      ),
    );
    return _decodePcm16(bytes);
  }

  Stream<Float64List> _decodePcm16(Stream<Uint8List> source) async* {
    int? carry;
    await for (final chunk in source) {
      final usableLength = (chunk.length + (carry == null ? 0 : 1)) ~/ 2 * 2;
      if (usableLength == 0) {
        carry = chunk.isEmpty ? null : chunk.first;
        continue;
      }
      final combined = Uint8List(usableLength);
      var offset = 0;
      if (carry != null) {
        combined[0] = carry;
        offset = 1;
      }
      final copyLength = usableLength - offset;
      combined.setRange(offset, usableLength, chunk.take(copyLength));
      final consumedFromChunk = copyLength;
      carry = consumedFromChunk < chunk.length
          ? chunk[consumedFromChunk]
          : null;

      final data = ByteData.sublistView(combined);
      final samples = Float64List(combined.length ~/ 2);
      for (var index = 0; index < samples.length; index++) {
        samples[index] = data.getInt16(index * 2, Endian.little) / 32768.0;
      }
      yield samples;
    }
  }

  @override
  Future<void> stop() async {
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  @override
  Future<void> dispose() => _recorder.dispose();
}
