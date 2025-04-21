import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service for playing sound effects in the app
class SoundService {
  static final SoundService _instance = SoundService._internal();

  /// Singleton instance
  factory SoundService() => _instance;

  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool soundEnabled = true;

  /// Initialize the sound service
  Future<void> initialize() async {
    try {
      // Set global settings
      await _player.setReleaseMode(ReleaseMode.release);
      await _player.setSourceAsset('sounds/message_sent.mp3');
    } catch (e) {
      debugPrint('Error initializing sound service: $e');
    }
  }

  /// Play a sound effect
  Future<void> playSound(SoundEffect effect) async {
    if (!soundEnabled) return;

    try {
      String assetPath;

      switch (effect) {
        case SoundEffect.messageSent:
          assetPath = 'sounds/message_sent.mp3';
          break;
        case SoundEffect.messageReceived:
          assetPath = 'sounds/message_received.mp3';
          break;
        case SoundEffect.notification:
          assetPath = 'sounds/notification.mp3';
          break;
        case SoundEffect.success:
          assetPath = 'sounds/success.mp3';
          break;
        case SoundEffect.error:
          assetPath = 'sounds/error.mp3';
          break;
      }

      await _player.stop();
      await _player.setSourceAsset(assetPath);
      await _player.resume();
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  /// Dispose of resources
  void dispose() {
    _player.dispose();
  }
}

/// Types of sound effects
enum SoundEffect {
  /// Sound played when a message is sent
  messageSent,

  /// Sound played when a message is received
  messageReceived,

  /// Sound played for notifications
  notification,

  /// Sound played for success operations
  success,

  /// Sound played for errors
  error,
}
