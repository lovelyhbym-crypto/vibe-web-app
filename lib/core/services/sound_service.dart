import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();

  factory SoundService() {
    return _instance;
  }

  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();

  // Cache players for low latency on repeated sounds (like chips)
  final List<AudioPlayer> _chipPlayers = [];
  int _chipPlayerIndex = 0;
  static const int _chipPoolSize = 5;

  Future<void> initialize() async {
    // Initialize pool for chip sounds
    for (int i = 0; i < _chipPoolSize; i++) {
      final player = AudioPlayer();
      await player.setPlayerMode(PlayerMode.lowLatency);
      _chipPlayers.add(player);
    }
  }

  /// P0: Casino Chip Sound (Tactile Feedback)
  Future<void> playChip() async {
    try {
      if (_chipPlayers.isEmpty) await initialize();

      // Round-robin for overlapping sounds
      final player = _chipPlayers[_chipPlayerIndex];
      _chipPlayerIndex = (_chipPlayerIndex + 1) % _chipPoolSize;

      await player.play(AssetSource('audio/chip.mp3'), volume: 1.0);
    } catch (e) {
      debugPrint('Error playing chip sound: $e');
    }
  }

  /// P1: Glass Shatter Sound (Emotional Penalty)
  Future<void> playShatter() async {
    try {
      // Single instance is fine for rare events
      await _player.play(AssetSource('audio/shatter.mp3'), volume: 1.0);
    } catch (e) {
      debugPrint('Error playing shatter sound: $e');
    }
  }

  /// P2: Firework/Jackpot Sound (Auditory Reward)
  Future<void> playFirework() async {
    try {
      await _player.play(AssetSource('audio/firework.mp3'), volume: 0.8);
    } catch (e) {
      debugPrint('Error playing firework sound: $e');
    }
  }
}
