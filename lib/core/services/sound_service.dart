import 'dart:io' show Platform, Process, File, Directory;
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';
import 'package:audioplayers/audioplayers.dart' as audio_players;
import 'package:just_audio/just_audio.dart';
import 'dart:async';

/// Service for playing sound effects and real-time audio in the app
class SoundService {
  static final SoundService _instance = SoundService._internal();

  /// Singleton instance
  factory SoundService() => _instance;

  SoundService._internal();

  final _effectPlayer = audio_players.AudioPlayer(); // For sound effects
  final _streamPlayer = AudioPlayer(); // For real-time audio from just_audio
  bool soundEnabled = true;

  // Buffer for accumulating audio data
  final List<int> _audioBuffer = [];
  static const int _bufferSize = 16000; // 1 second of 16kHz audio
  Timer? _playbackTimer;

  /// Initialize the sound service
  Future<void> initialize() async {
    try {
      // Set global settings for sound effects
      await _effectPlayer.setReleaseMode(audio_players.ReleaseMode.release);
      await _effectPlayer.setSourceAsset('sounds/message_sent.mp3');
    } catch (e) {
      AppLogger.error('Error initializing sound service', e);
    }
  }

  /// Play binary audio data (for real-time streaming)
  Future<void> playBinaryAudio(dynamic audioData) async {
    if (!soundEnabled) return;

    try {
      if (audioData is List<int>) {
        // Add data to buffer
        _audioBuffer.addAll(audioData);

        // If we have enough data, start playback
        if (_audioBuffer.length >= _bufferSize) {
          // Convert to WAV format (16-bit PCM, 16kHz, mono)
          final wavData = _createWavHeader(_audioBuffer);

          // Create a temporary file to store the WAV data
          final tempDir = await Directory.systemTemp.createTemp('audio');
          final tempFile = File('${tempDir.path}/temp.wav');
          await tempFile.writeAsBytes(wavData);

          if (Platform.isLinux) {
            // Use aplay for playback
            await Process.run('aplay', [tempFile.path]);
          } else {
            // Use just_audio for other platforms
            await _streamPlayer.setAudioSource(AudioSource.file(tempFile.path));
            await _streamPlayer.play();
          }

          // Clear the buffer
          _audioBuffer.clear();

          // Clean up temp file after playback
          _playbackTimer?.cancel();
          _playbackTimer = Timer(const Duration(seconds: 1), () {
            tempFile.delete();
            tempDir.delete();
          });
        }
      }
    } catch (e) {
      AppLogger.error('Error playing binary audio', e);
    }
  }

  /// Create a WAV header for raw PCM data
  Uint8List _createWavHeader(List<int> pcmData) {
    const sampleRate = 16000;
    const numChannels = 1;
    const bitsPerSample = 16;
    const byteRate = (sampleRate * numChannels * bitsPerSample) ~/ 8;
    const blockAlign = (numChannels * bitsPerSample) ~/ 8;
    final subchunk2Size = pcmData.length;
    final chunkSize = 36 + subchunk2Size;

    final header = ByteData(44); // WAV header is 44 bytes

    // "RIFF" chunk descriptor
    header.setUint32(0, 0x52494646, Endian.big); // "RIFF"
    header.setUint32(4, chunkSize, Endian.little);
    header.setUint32(8, 0x57415645, Endian.big); // "WAVE"

    // "fmt " sub-chunk
    header.setUint32(12, 0x666D7420, Endian.big); // "fmt "
    header.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    header.setUint16(20, 1, Endian.little); // AudioFormat (1 for PCM)
    header.setUint16(22, numChannels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);

    // "data" sub-chunk
    header.setUint32(36, 0x64617461, Endian.big); // "data"
    header.setUint32(40, subchunk2Size, Endian.little);

    // Combine header with PCM data
    final wavData = Uint8List(44 + pcmData.length);
    wavData.setRange(0, 44, header.buffer.asUint8List());
    wavData.setRange(44, wavData.length, pcmData);

    return wavData;
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

      await _effectPlayer.stop();
      await _effectPlayer.setSourceAsset(assetPath);
      await _effectPlayer.resume();
    } catch (e) {
      AppLogger.error('Error playing sound', e);
    }
  }

  /// Stop any currently playing audio
  Future<void> stopAudio() async {
    try {
      await _streamPlayer.stop();
      await _effectPlayer.stop();
      _audioBuffer.clear();
      _playbackTimer?.cancel();
    } catch (e) {
      AppLogger.error('Error stopping audio', e);
    }
  }

  /// Dispose of resources
  void dispose() {
    _streamPlayer.dispose();
    _effectPlayer.dispose();
    _playbackTimer?.cancel();
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
