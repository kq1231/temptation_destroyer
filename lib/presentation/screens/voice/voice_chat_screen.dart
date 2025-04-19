import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vapi/Vapi.dart';
import '../../../core/services/vapi_service.dart';
import '../../widgets/voice/voice_chat_controls.dart';
import '../../widgets/voice/voice_chat_messages.dart';

class VoiceChatScreen extends ConsumerStatefulWidget {
  const VoiceChatScreen({super.key});

  @override
  ConsumerState<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends ConsumerState<VoiceChatScreen> {
  final List<VapiEvent> _messages = [];
  bool _isCallActive = false;
  bool _isMuted = false;
  bool _isLoading = false;
  bool _isProcessing = false;
  bool _isInitialized = false;
  String? _error;

  late final VapiService _vapiService;

  @override
  void initState() {
    super.initState();
    _vapiService = VapiService();
    _initializeVapi();
  }

  Future<void> _initializeVapi() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _vapiService.initialize();
      _vapiService.onEvent?.listen(_handleVapiEvent);
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize voice chat: \${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleVapiEvent(VapiEvent event) {
    setState(() {
      if (event.label == 'call-start') {
        _isCallActive = true;
        _isProcessing = false;
      } else if (event.label == 'call-end') {
        _isCallActive = false;
        _isProcessing = false;
      } else if (event.label == 'message' || event.label == 'transcript') {
        _messages.insert(0, event);
        _isProcessing = false;
      } else if (event.label == 'processing') {
        _isProcessing = true;
      }
    });
  }

  Future<void> _startCall() async {
    if (!_isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice chat is not initialized yet')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _vapiService.startCall(
        assistant: {
          "model": {
            "provider": "openai",
            "model": "gpt-3.5-turbo",
            "systemPrompt":
                "You are a helpful Islamic assistant, providing guidance with wisdom and compassion. Always begin your responses with 'Bismillah' and end with a relevant dua or words of encouragement."
          },
          "voice": {
            "provider": "11labs",
            "voiceId": "josh",
          },
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Error starting call: \${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_error!)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _stopCall() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _vapiService.stopCall();
    } catch (e) {
      setState(() {
        _error = 'Error stopping call: \${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_error!)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleMute(bool muted) async {
    try {
      await _vapiService.setMuted(muted);
      setState(() {
        _isMuted = muted;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error toggling mute: \${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Voice Guidance')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeVapi,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Guidance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Voice Chat Help'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• Press Play to start a voice chat'),
                      Text('• Use the Mute button to toggle your microphone'),
                      Text('• Press Stop to end the conversation'),
                      Text('• Your voice will be transcribed automatically'),
                      Text('• The AI will respond with voice and text'),
                      Text(
                          '• The AI assistant is configured to provide Islamic guidance'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            VoiceChatMessages(
              messages: _messages,
              isCallActive: _isCallActive,
              isProcessing: _isProcessing,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: VoiceChatControls(
                onStartCall: _startCall,
                onStopCall: _stopCall,
                onMuteToggle: _toggleMute,
                isMuted: _isMuted,
                isCallActive: _isCallActive,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _vapiService.dispose();
    super.dispose();
  }
}
