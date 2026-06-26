import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

class BeepService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> beep() async {
    await _player.play(BytesSource(_generateBeepWav()));
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
    writeU32(sampleRate * 2); // byte rate
    writeU16(2); // block align
    writeU16(16); // bits per sample
    writeStr('data');
    writeU32(dataSize);

    const fadeFrames = 150;
    for (int i = 0; i < numSamples; i++) {
      double env = 1.0;
      if (i < fadeFrames) env = i / fadeFrames;
      if (i > numSamples - fadeFrames) env = (numSamples - i) / fadeFrames;
      final sample = (sin(2 * pi * frequency * i / sampleRate) * 28000 * env).round();
      buffer.setInt16(offset, sample.clamp(-32768, 32767), Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }
}
