import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

class BeepService {
  // Private constructor — callers use the singleton instance.
  BeepService._();
  static final BeepService _instance = BeepService._();
  static BeepService get instance => _instance;

  final AudioPlayer _player = AudioPlayer();
  final Uint8List _cachedWav = _generateBeepWav();
  bool _disposed = false;

  Future<void> beep() async {
    if (_disposed) return;
    try {
      await _player.play(BytesSource(_cachedWav));
    } catch (_) {
      // Audio session may be unavailable (silent mode, focus denied). Ignore.
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await _player.dispose();
  }

  static Uint8List _generateBeepWav({
    int frequency = 880,
    double durationSec = 0.12,
    int sampleRate = 22050,
  }) {
    final numSamples = (sampleRate * durationSec).round();
    final dataSize = numSamples * 2;
    final buffer = ByteData(44 + dataSize);
    var offset = 0;

    void writeStr(String s) {
      for (final c in s.codeUnits) {
        buffer.setUint8(offset++, c);
      }
    }

    void writeU32(int v) {
      buffer.setUint32(offset, v, Endian.little);
      offset += 4;
    }

    void writeU16(int v) {
      buffer.setUint16(offset, v, Endian.little);
      offset += 2;
    }

    writeStr('RIFF');
    writeU32(36 + dataSize);
    writeStr('WAVE');
    writeStr('fmt ');
    writeU32(16);
    writeU16(1); // PCM
    writeU16(1); // mono
    writeU32(sampleRate);
    writeU32(sampleRate * 2);
    writeU16(2);
    writeU16(16);
    writeStr('data');
    writeU32(dataSize);

    const fadeFrames = 150;
    for (int i = 0; i < numSamples; i++) {
      double env = 1.0;
      if (i < fadeFrames) env = i / fadeFrames;
      if (i > numSamples - fadeFrames) env = (numSamples - i) / fadeFrames;
      final sample =
          (sin(2 * pi * frequency * i / sampleRate) * 28000 * env).round();
      buffer.setInt16(offset, sample.clamp(-32768, 32767), Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }
}
