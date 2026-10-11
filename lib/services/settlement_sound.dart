import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Plays the settlement confirmation chime and fires haptic feedback.
///
/// Designed for open-air markets: the sound must be loud enough to be heard
/// over ambient noise (typically 60-80 dB). MonCash's SMS chime succeeded
/// because it was loud and immediate; we replicate that ergonomic.
class SettlementSound {
  SettlementSound._();
  static final SettlementSound instance = SettlementSound._();

  /// Synchronous hook called whenever a settlement chime is triggered.
  void Function()? onPlay;

  /// Custom player override for testing.
  Future<void> Function()? playOverride;

  int playCount = 0;

  Future<void> play() async {
    playCount++;
    onPlay?.call();

    if (playOverride != null) {
      await playOverride!();
      return;
    }

    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}

    try {
      final player = AudioPlayer();
      await player.setVolume(1.0);
      await player.play(AssetSource('sounds/settlement.mp3'));
    } catch (e) {
      // A failed chime must NEVER block a transaction.
      debugPrint('SettlementSound: playback failed ($e)');
    }
  }
}
