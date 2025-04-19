import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vapi/Vapi.dart';

/// Service class to handle VAPI (Voice AI) integration
class VapiService {
  static const String _vapiKeyKey = 'vapi_public_key';

  final FlutterSecureStorage _secureStorage;
  Vapi? _vapi;
  bool _isMuted = false;
  Stream<VapiEvent>? _eventStream;

  VapiService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Initialize VAPI with the stored public key
  Future<void> initialize() async {
    final publicKey = await getPublicKey();
    if (publicKey != null) {
      _vapi = Vapi(publicKey);
      _eventStream = _vapi?.onEvent;
    }
  }

  /// Store the VAPI public key securely
  Future<void> setPublicKey(String publicKey) async {
    await _secureStorage.write(key: _vapiKeyKey, value: publicKey);
    _vapi = Vapi(publicKey);
    _eventStream = _vapi?.onEvent;
  }

  /// Get the stored VAPI public key
  Future<String?> getPublicKey() async {
    return await _secureStorage.read(key: _vapiKeyKey);
  }

  /// Start a voice call with an AI assistant
  Future<void> startCall({
    String? assistantId,
    Map<String, dynamic>? assistant,
    Map<String, dynamic>? assistantOverrides,
  }) async {
    if (_vapi == null) {
      throw Exception('VAPI not initialized. Please set public key first.');
    }

    if (assistantId != null) {
      await _vapi!.start(
        assistantId: assistantId,
        assistantOverrides: assistantOverrides,
      );
    } else if (assistant != null) {
      await _vapi!.start(assistant: assistant);
    } else {
      throw ArgumentError('Either assistantId or assistant must be provided');
    }
  }

  /// Send a message during an active call
  Future<void> sendMessage(String role, String content) async {
    if (_vapi == null) {
      throw Exception('VAPI not initialized. Please set public key first.');
    }
    await _vapi!.send({
      "type": "add-message",
      "message": {
        "role": role,
        "content": content,
      },
    });
  }

  /// Stop the current call
  Future<void> stopCall() async {
    if (_vapi == null) {
      throw Exception('VAPI not initialized. Please set public key first.');
    }
    await _vapi!.stop();
  }

  /// Mute/unmute the microphone
  Future<void> setMuted(bool muted) async {
    if (_vapi == null) {
      throw Exception('VAPI not initialized. Please set public key first.');
    }
    _vapi!.setMuted(muted);
    _isMuted = muted;
  }

  /// Check if the microphone is muted
  bool isMuted() {
    return _isMuted;
  }

  /// Listen to VAPI events
  Stream<VapiEvent>? get onEvent => _eventStream;

  /// Dispose of the VAPI instance
  void dispose() {
    _vapi?.dispose();
    _vapi = null;
    _eventStream = null;
  }
}
