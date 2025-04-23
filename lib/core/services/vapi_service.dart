import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:temptation_destroyer/data/models/ai_models.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:permission_handler/permission_handler.dart';
import '../security/secure_storage_service.dart';
import './sound_service.dart';
import '../utils/logger.dart';

/// Custom implementation of VapiEvent
class VapiEvent {
  final String label;
  final dynamic value;

  VapiEvent(this.label, [this.value]);
}

/// Service class to handle VAPI (Voice AI) integration with custom implementation
/// instead of using the vapi package
class VapiService {
  static const String _publicKeyType = AIServiceType.vapiPublic;
  static const String _privateKeyType = AIServiceType.vapiPrivate;
  static const String _apiBaseUrl = 'https://api.vapi.ai';

  final _streamController = StreamController<VapiEvent>();
  final _soundService = SoundService();
  String? _publicKey;
  String? _privateKey;
  WebSocketChannel? _channel;
  bool _isMuted = false;
  bool _isCallActive = false;
  Process? _arecordProcess;
  StreamSubscription<List<int>>? _audioSub;

  Stream<VapiEvent> get onEvent => _streamController.stream;

  VapiService() {
    _initializeSoundService();
  }

  Future<void> _initializeSoundService() async {
    await _soundService.initialize();
  }

  /// Initialize VAPI with stored keys
  Future<void> initialize() async {
    final publicKey = await getPublicKey();
    final privateKey = await getPrivateKey();

    if (publicKey != null) {
      _publicKey = publicKey;
      _debugApiKey(publicKey, isPublic: true);
    }

    if (privateKey != null) {
      _privateKey = privateKey;
      _debugApiKey(privateKey, isPublic: false);
    }
  }

  /// Store the VAPI public key securely
  Future<void> setPublicKey(String publicKey) async {
    // Trim the key to remove any accidental whitespace
    final trimmedKey = publicKey.trim();
    await SecureStorageService.instance.storeKey(_publicKeyType, trimmedKey);
    _publicKey = trimmedKey;
    _debugApiKey(trimmedKey, isPublic: true);
  }

  /// Store the VAPI private key securely
  Future<void> setPrivateKey(String privateKey) async {
    // Trim the key to remove any accidental whitespace
    final trimmedKey = privateKey.trim();
    await SecureStorageService.instance.storeKey(_privateKeyType, trimmedKey);
    _privateKey = trimmedKey;
    _debugApiKey(trimmedKey, isPublic: false);
  }

  /// Debug the API key format
  void _debugApiKey(String key, {required bool isPublic}) {
    // Mask the key for security but show portions for debugging
    String maskedKey = key;
    if (key.length > 10) {
      maskedKey = "${key.substring(0, 6)}...${key.substring(key.length - 4)}";
    }

    String keyType = isPublic ? "PUBLIC" : "PRIVATE";
    AppLogger.debug('API $keyType Key Format:');
    AppLogger.debug('  - Length: ${key.length}');
    AppLogger.debug('  - Masked Key: $maskedKey');
    AppLogger.debug('  - Has whitespace at start/end: ${key != key.trim()}');
    AppLogger.debug(
        '  - Contains newlines: ${key.contains('\n') || key.contains('\r')}');

    // Check key format patterns (common in API keys)
    bool isVapiPublicKey = key.startsWith('vok_') || key.startsWith('vapk_');
    bool isVapiPrivateKey = key.startsWith('vsk_') || key.startsWith('vspk_');

    if (isPublic && isVapiPublicKey) {
      AppLogger.info(
          '  - ✅ Correct format for a Vapi PUBLIC key (starts with vok_ or vapk_)');
    } else if (!isPublic && isVapiPrivateKey) {
      AppLogger.info(
          '  - ✅ Correct format for a Vapi PRIVATE key (starts with vsk_ or vspk_)');
    } else if (isPublic && isVapiPrivateKey) {
      AppLogger.warning(
          '  - ❌ WARNING! You provided a PRIVATE key but stored it as PUBLIC');
      AppLogger.warning(
          '  - Vapi public keys typically start with vok_ or vapk_');
    } else if (!isPublic && isVapiPublicKey) {
      AppLogger.warning(
          '  - ❌ WARNING! You provided a PUBLIC key but stored it as PRIVATE');
      AppLogger.warning(
          '  - Vapi private keys typically start with vsk_ or vspk_');
    } else {
      AppLogger.warning('  - ❓ Unknown key format. Check Vapi documentation.');
    }

    // Test API connection only for public key
    if (isPublic) {
      _testApiConnection(key);
    }
  }

  /// Test the API connection using the provided key
  Future<void> _testApiConnection(String key) async {
    try {
      var url = Uri.parse('$_apiBaseUrl/assistants');

      // First test with just the key as-is against a simpler endpoint
      var headers = {
        'Authorization': 'Bearer $key',
        'Content-Type': 'application/json',
      };

      AppLogger.debug('Testing API connection with PUBLIC key...');
      var response = await http.get(url, headers: headers);

      AppLogger.debug('API test response: ${response.statusCode}');
      if (response.statusCode == 200) {
        AppLogger.info('PUBLIC key is VALID! Successfully accessed Vapi API');
      } else {
        AppLogger.debug('API test response body: ${response.body}');
      }

      if (response.statusCode == 401) {
        // If we got 401, try with a different format just to be sure
        AppLogger.debug('Trying alternative key formats...');

        // Try without Bearer prefix (in case it's already embedded)
        headers = {
          'Authorization': key,
          'Content-Type': 'application/json',
        };
        response = await http.get(url, headers: headers);
        AppLogger.debug(
            'API test (without Bearer) response: ${response.statusCode}');

        // If key has Bearer embedded, try extracting just the token
        if (key.toLowerCase().startsWith('bearer ')) {
          String extractedKey = key.substring(7).trim();
          headers = {
            'Authorization': 'Bearer $extractedKey',
            'Content-Type': 'application/json',
          };
          response = await http.get(url, headers: headers);
          AppLogger.debug(
              'API test (extracted Bearer) response: ${response.statusCode}');
        }
      }
    } catch (e) {
      AppLogger.error('API test error', e);
    }
  }

  /// Get the stored VAPI public key
  Future<String?> getPublicKey() async {
    return await SecureStorageService.instance.getKey(_publicKeyType);
  }

  /// Get the stored VAPI private key
  Future<String?> getPrivateKey() async {
    return await SecureStorageService.instance.getKey(_privateKeyType);
  }

  /// Start a voice call with an AI assistant
  Future<void> startCall({
    String? assistantId,
    Map<String, dynamic>? assistant,
    Map<String, dynamic>? assistantOverrides = const {},
  }) async {
    // For creating calls, we need the PRIVATE key
    if (_privateKey == null) {
      throw Exception('VAPI private key not initialized. Please set it first.');
    }

    if (_isCallActive) {
      throw Exception('Call already in progress');
    }

    if (assistantId == null && assistant == null) {
      throw ArgumentError('Either assistantId or assistant must be provided');
    }

    // Only check permissions on Android or iOS
    if (Platform.isAndroid || Platform.isIOS) {
      AppLogger.info("Vapi - Requesting Mic Permission...");
      var microphoneStatus = await Permission.microphone.request();
      if (microphoneStatus.isDenied) {
        microphoneStatus = await Permission.microphone.request();
        if (microphoneStatus.isPermanentlyDenied) {
          openAppSettings();
          return;
        }
      }
      AppLogger.info("Vapi - Mic Permission Granted");
    }

    // Verify API public key is valid first (if available)
    if (_publicKey != null) {
      try {
        final verifyUrl = Uri.parse('$_apiBaseUrl/assistants');
        final verifyHeaders = {
          'Authorization': 'Bearer ${_publicKey!.trim()}',
          'Content-Type': 'application/json',
        };

        AppLogger.debug('Verifying API public key validity...');
        final verifyResponse =
            await http.get(verifyUrl, headers: verifyHeaders);

        if (verifyResponse.statusCode != 200) {
          AppLogger.warning(
              'API public key verification failed: ${verifyResponse.statusCode}');
        } else {
          AppLogger.info('API public key verified successfully!');
        }
      } catch (e) {
        AppLogger.error('Error during key verification', e);
      }
    }

    var url = Uri.parse('$_apiBaseUrl/call');

    // Clean private key (remove any Bearer prefix if accidentally included)
    String cleanKey = _privateKey!.trim();
    if (cleanKey.toLowerCase().startsWith('bearer ')) {
      cleanKey = cleanKey.substring(7).trim();
      AppLogger.debug('Removed "Bearer " prefix from key');
    }

    var headers = {
      'Authorization': 'Bearer $cleanKey',
      'Content-Type': 'application/json',
    };

    // Log headers for debugging (with masked key)
    String maskedKey = cleanKey;
    if (maskedKey.length > 10) {
      maskedKey =
          "${maskedKey.substring(0, 6)}...${maskedKey.substring(maskedKey.length - 4)}";
    }
    AppLogger.debug('Headers:');
    AppLogger.debug('  - Authorization: Bearer $maskedKey (PRIVATE key)');
    AppLogger.debug('  - Content-Type: application/json');

    // Create request body according to the VAPI WebSocket transport documentation
    var requestBody = <String, dynamic>{
      'transport': {'provider': 'vapi.websocket'},
    };

    // Add assistantOverrides if provided and not empty
    if (assistantOverrides != null && assistantOverrides.isNotEmpty) {
      requestBody['assistantOverrides'] = assistantOverrides;
    }

    // Handle assistant according to the docs format
    if (assistantId != null) {
      // Format: "assistant": { "assistantId": "YOUR_ASSISTANT_ID" }
      requestBody['assistant'] = {'assistantId': assistantId};
    } else if (assistant != null) {
      // If assistant is a full object, use it directly
      requestBody['assistant'] = assistant;
    }

    AppLogger.info("Vapi - Preparing WebSocket Call...");
    AppLogger.debug("Request Body: ${jsonEncode(requestBody)}");

    var response =
        await http.post(url, headers: headers, body: jsonEncode(requestBody));

    AppLogger.debug('VAPI API response: ${response.body}');
    AppLogger.debug('Response Status Code: ${response.statusCode}');
    AppLogger.debug('Response Headers: ${response.headers}');

    if (response.statusCode == 201) {
      AppLogger.info("Vapi - Vapi WebSocket Call Ready");
      var data = jsonDecode(response.body);

      var wsUrl = data['transport']?['websocketCallUrl'];
      if (wsUrl == null) {
        AppLogger.debug(
            '🆘 ${DateTime.now()}: Vapi - WebSocket transport URL not found');
        emit(VapiEvent("call-error", "WebSocket transport URL not found"));
        return;
      }

      AppLogger.debug(
          "🔄 ${DateTime.now()}: Vapi - Connecting to WebSocket: $wsUrl");
      try {
        await _connectWebSocketWithRetry(wsUrl);

        // Start arecord if on Linux
        if (Platform.isLinux) {
          await _startArecordAndStream();
        }
      } catch (e) {
        AppLogger.debug(
            "🆘 ${DateTime.now()}: Vapi - All WebSocket connection attempts failed: $e");
        emit(VapiEvent("call-error",
            "Failed to establish WebSocket connection after multiple attempts"));
      }
    } else {
      AppLogger.debug(
          '🆘 ${DateTime.now()}: Vapi - Failed to create Vapi Call. Error: ${response.body}');

      // Special handling for 401 errors
      if (response.statusCode == 401) {
        AppLogger.debug('DEBUG - 401 Unauthorized Error. This likely means:');
        AppLogger.debug('  1. Your PRIVATE key is incorrect or expired');
        AppLogger.debug(
            '  2. You might be using a public key instead of a private key');
        AppLogger.debug(
            '  3. Your account might not have permission for this operation');
        AppLogger.debug('  4. Your Vapi subscription might have expired');

        AppLogger.debug('DEBUG - Please try the following:');
        AppLogger.debug(
            '  - Go to the Vapi dashboard and verify your PRIVATE key');
        AppLogger.debug(
            '  - Check that your account has permissions for WebSocket transport');
        AppLogger.debug('  - Generate a new key and try again');
        AppLogger.debug(
            '  - Make sure you\'re using a PRIVATE key (starts with vsk_ or vspk_)');
      }
      // Special handling for 400 errors
      else if (response.statusCode == 400) {
        AppLogger.debug(
            'DEBUG - 400 Bad Request Error. This means your request format is incorrect.');
        try {
          final errorData = jsonDecode(response.body);
          final errorMessages = errorData['message'];

          AppLogger.debug('DEBUG - Error details:');
          if (errorMessages is List) {
            for (final msg in errorMessages) {
              AppLogger.debug('  - $msg');

              // Check for audioFormat errors
              if (msg.toString().contains('audioFormat')) {
                AppLogger.debug('DEBUG - AudioFormat Error! Recommended fix:');
                AppLogger.debug(
                    '  Use exactly this format for the transport section:');
                AppLogger.debug('''
                "transport": {
                  "provider": "vapi.websocket"
                }''');
              }
            }
          } else if (errorMessages is String) {
            AppLogger.debug('  - $errorMessages');
          }

          // Try with a simplified request body as a fallback
          AppLogger.debug(
              'DEBUG - Attempting fallback with simplified request...');
          var fallbackBody = <String, dynamic>{
            'assistant':
                assistantId != null ? {'assistantId': assistantId} : assistant,
            'transport': {'provider': 'vapi.websocket'}
          };

          AppLogger.debug(
              'DEBUG - Fallback request body: ${jsonEncode(fallbackBody)}');
          var fallbackResponse = await http.post(url,
              headers: headers, body: jsonEncode(fallbackBody));
          AppLogger.debug(
              'DEBUG - Fallback response: ${fallbackResponse.statusCode}');
          AppLogger.debug(
              'DEBUG - Fallback response body: ${fallbackResponse.body}');

          if (fallbackResponse.statusCode == 201) {
            AppLogger.debug(
                "🆗 ${DateTime.now()}: Vapi - Fallback request successful!");
            var data = jsonDecode(fallbackResponse.body);
            var wsUrl = data['transport']?['websocketCallUrl'];
            if (wsUrl != null) {
              AppLogger.debug(
                  "🔄 ${DateTime.now()}: Vapi - Connecting to WebSocket: $wsUrl");
              _connectWebSocket(wsUrl);
              if (Platform.isLinux) {
                await _startArecordAndStream();
              }
              return; // Success with fallback, exit early
            }
          }
        } catch (e) {
          AppLogger.debug('DEBUG - Error parsing error details: $e');
        }
      }

      emit(VapiEvent("call-error", response.body));
      return;
    }
  }

  Future<void> _connectWebSocketWithRetry(String wsUrl,
      {int maxRetries = 3}) async {
    int retryCount = 0;
    Duration retryDelay = const Duration(seconds: 1);

    while (retryCount < maxRetries) {
      try {
        AppLogger.debug(
            "DEBUG - WebSocket connection attempt ${retryCount + 1}/$maxRetries");

        // Create a timeout for the connection attempt
        final completer = Completer<void>();

        // Attempt the connection
        _connectWebSocket(wsUrl);

        // Set up a timeout
        Timer(const Duration(seconds: 10), () {
          if (!completer.isCompleted) {
            completer.completeError(
                TimeoutException('WebSocket connection timeout'));
          }
        });

        // Wait for either success or timeout
        try {
          await completer.future;
          AppLogger.debug("DEBUG - WebSocket connection successful");
          return;
        } on TimeoutException {
          AppLogger.debug("DEBUG - WebSocket connection timed out");
          throw TimeoutException('WebSocket connection timeout');
        }
      } catch (e, stackTrace) {
        retryCount++;
        if (retryCount == maxRetries) {
          AppLogger.debug("DEBUG - Max retries reached, giving up");
          rethrow;
        }

        AppLogger.debug(
            "DEBUG - Connection failed, retrying in ${retryDelay.inSeconds} seconds");
        AppLogger.debug("DEBUG - Error details:");
        AppLogger.debug("  - Error type: ${e.runtimeType}");
        AppLogger.debug("  - Error message: $e");
        AppLogger.debug("  - Stack trace: $stackTrace");

        await Future.delayed(retryDelay);
        retryDelay *= 2; // Exponential backoff
      }
    }
  }

  void _connectWebSocket(String wsUrl) {
    try {
      AppLogger.debug("DEBUG - Attempting WebSocket connection to: $wsUrl");

      final uri = Uri.parse(wsUrl);
      AppLogger.debug("DEBUG - Parsed WebSocket URI:");
      AppLogger.debug("  - Scheme: ${uri.scheme}");
      AppLogger.debug("  - Host: ${uri.host}");
      AppLogger.debug("  - Path: ${uri.path}");
      AppLogger.debug("  - Query Parameters: ${uri.queryParameters}");

      _channel = WebSocketChannel.connect(uri);
      _isCallActive = true;
      emit(VapiEvent("call-start"));

      _channel!.stream.listen(
        (msg) {
          if (msg is String) {
            AppLogger.debug("DEBUG - Received text message from WebSocket");
            _onJsonMessage(msg);
          } else {
            AppLogger.debug(
                "DEBUG - Received binary audio data from WebSocket");
            // Play the audio using SoundService
            _soundService.playBinaryAudio(msg);
            emit(VapiEvent("audio", msg));
          }
        },
        onDone: () {
          AppLogger.debug(
              "⏹️ ${DateTime.now()}: Vapi - WebSocket connection closed");
          AppLogger.debug("DEBUG - WebSocket connection closed normally");
          _isCallActive = false;
          _soundService.stopAudio();
          emit(VapiEvent("call-end"));
          _stopArecord();
        },
        onError: (e, stackTrace) {
          AppLogger.debug("🆘 ${DateTime.now()}: Vapi - WebSocket error: $e");
          AppLogger.debug("DEBUG - WebSocket error details:");
          AppLogger.debug("  - Error type: ${e.runtimeType}");
          AppLogger.debug("  - Error message: $e");
          AppLogger.debug("  - Stack trace: $stackTrace");
          _isCallActive = false;
          _soundService.stopAudio();
          emit(VapiEvent("call-error", e.toString()));
          _stopArecord();
        },
      );
    } catch (e, stackTrace) {
      AppLogger.debug(
          "🆘 ${DateTime.now()}: Vapi - Failed to connect to WebSocket: $e");
      AppLogger.debug("DEBUG - Connection error details:");
      AppLogger.debug("  - Error type: ${e.runtimeType}");
      AppLogger.debug("  - Error message: $e");
      AppLogger.debug("  - Stack trace: $stackTrace");
      _soundService.stopAudio();
      emit(VapiEvent("call-error", "Failed to connect to WebSocket: $e"));
    }
  }

  Future<void> _startArecordAndStream() async {
    try {
      // 16-bit little-endian, 16kHz, mono, device pulse
      _arecordProcess = await Process.start(
        'arecord',
        ['-D', 'pulse', '-f', 'S16_LE', '-r', '16000', '-c', '1'],
        mode: ProcessStartMode.detachedWithStdio,
      );
      _audioSub = _arecordProcess!.stdout.listen((List<int> audioData) {
        // Send raw audio data as binary to the WebSocket
        if (_channel != null && _isCallActive && !_isMuted) {
          _channel!.sink.add(audioData);
        }
      });
      AppLogger.debug(
          '🟢 ${DateTime.now()}: Vapi - arecord started and streaming audio');
    } catch (e) {
      AppLogger.debug(
          '🛑 ${DateTime.now()}: Vapi - Failed to start arecord: $e');
      emit(VapiEvent("call-error", 'Failed to start arecord: $e'));
    }
  }

  void _stopArecord() {
    _audioSub?.cancel();
    _audioSub = null;
    _arecordProcess?.kill(ProcessSignal.sigint);
    _arecordProcess = null;
    AppLogger.debug('🛑 ${DateTime.now()}: Vapi - arecord stopped');
  }

  /// Send a message during an active call
  Future<void> sendMessage(String role, String content) async {
    if (_channel == null) {
      throw Exception('No active call. Please start a call first.');
    }
    final msg = jsonEncode({
      "type": "add-message",
      "message": {
        "role": role,
        "content": content,
      },
    });
    _channel!.sink.add(msg);
  }

  void _onJsonMessage(String msg) {
    try {
      var parsedMessage = jsonDecode(msg);
      emit(VapiEvent("message", parsedMessage));
    } catch (parseError) {
      AppLogger.debug("Error parsing message data: $parseError");
    }
  }

  /// Stop the current call
  Future<void> stopCall() async {
    if (_channel == null) {
      throw Exception('No call in progress');
    }

    // Send hangup message as specified in docs
    _channel!.sink.add(jsonEncode({"type": "hangup"}));

    // Small delay to allow the hangup message to be sent
    await Future.delayed(const Duration(milliseconds: 500));

    await _channel!.sink.close();
    _isCallActive = false;
    emit(VapiEvent("call-end"));
    _stopArecord();
  }

  /// Mute/unmute the microphone (no-op for pure WebSocket, but you can send a message if API supports it)
  Future<void> setMuted(bool muted) async {
    _isMuted = muted;
    // If Vapi API supports mute via WebSocket, send a message here
    // Example: _channel?.sink.add(jsonEncode({"type": "mute", "muted": muted}));
  }

  /// Check if the microphone is muted
  bool isMuted() {
    return _isMuted;
  }

  void emit(VapiEvent event) {
    _streamController.add(event);
  }

  /// Dispose of resources
  void dispose() {
    if (_channel != null) {
      // Try to send hangup message if possible
      try {
        _channel!.sink.add(jsonEncode({"type": "hangup"}));
      } catch (_) {}
      _channel!.sink.close();
    }
    _isCallActive = false;
    _soundService.stopAudio();
    _stopArecord();
    _streamController.close();
  }
}
