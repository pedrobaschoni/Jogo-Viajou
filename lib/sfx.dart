import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Efeitos sonoros curtos (assets/sfx/*.wav).
class Sfx {
  static bool muted = false;

  static Future<void> play(String name, {double volume = 1.0}) async {
    if (muted) return;
    try {
      final p = AudioPlayer();
      p.onPlayerComplete.listen((_) => p.dispose());
      await p.play(AssetSource('sfx/$name.wav'), volume: volume);
    } catch (e) {
      debugPrint('Som $name falhou: $e');
    }
  }
}
