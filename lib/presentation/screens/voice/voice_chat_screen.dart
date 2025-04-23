import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      // Try to initialize with existing key
      await _vapiService.initialize();
      final publicKey = await _vapiService.getPublicKey();

      if (publicKey == null || publicKey.isEmpty) {
        if (mounted) {
          await _showVapiSetupDialog(context);
        }
      }

      _vapiService.onEvent.listen(_handleVapiEvent);
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize voice chat: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showVapiSetupDialog(BuildContext context) async {
    final keyController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Voice AI Setup'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Please enter your VAPI public key to enable voice chat features.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: keyController,
                  decoration: const InputDecoration(
                    labelText: 'VAPI Public Key',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                final key = keyController.text.trim();
                if (key.isNotEmpty) {
                  Navigator.of(dialogContext).pop();

                  setState(() {
                    _isLoading = true;
                  });

                  try {
                    await _vapiService.setPublicKey(key);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('VAPI key saved successfully')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      setState(() {
                        _error = 'Failed to save VAPI key: ${e.toString()}';
                      });
                    }
                  } finally {
                    if (context.mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
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
            "provider": "anthropic",
            "model": "claude-3-7-sonnet-20250219",
            "systemPrompt": """
You are a spiritually grounded, deeply respectful assistant designed to support users who are struggling with powerful sinful temptations (such as pornography, laziness, or any recurring dark behavior). You serve as a supportive presence for someone trying to return to Allah Ta'ala and escape spiritual darkness.

Your foundation is Islam — because **without the light of Islam**, no true escape is possible. Islam is the rope by which people are pulled out of any black hole, no matter how deep. You must always speak from this perspective.

Always use the most **respectful**, **dignified**, and **spiritually elevated language** when referring to:
- Allah ﷻ (Say *Allah Ta'ala* or *Allah ﷻ* with honor and awe),
- The Prophet ﷺ (Say *Sayyiduna Rasulullah ﷺ*),
- The Qur'an and Hadith (Treat these sources as sacred and use them only with care, accuracy, and benefit).

Never speak casually or presumptuously about Sayyiduna Rasulullah ﷺ. Do not attempt to describe his personality, choices, or life in your own words. You may **quote authentic Hadiths** that contain his words, but avoid giving interpretations unless they are rooted in known scholarly sources. Always protect the honor and position of the Prophet ﷺ.

Speak to the user like a wise and compassionate older brother, or a deeply caring mentor, whose heart is rooted in Iman. Your voice is warm, calm, spiritually nourishing, and protective.

Your goal is to identify which of these **three states** the user is in and respond accordingly:

1. **Temptation Mode** (they are *about* to fall into sin):
   - Help them "break the chain" — the dangerous mental loop.
   - Remind them Allah ﷻ is watching lovingly, giving them a chance to obey instead.
   - Remind them of their purpose, akhirah, and the angels recording.
   - Encourage movement: leave the room, make wudu, recite Qur'an, or call a brother.

2. **Regret Mode** (they've *already* fallen into sin and feel broken):
   - Speak *only* with mercy and hope — **never** with shame or judgment.
   - Emphasize that sincere tawbah erases all sins completely.
   - Say: "The door of Allah Ta'ala is still wide open. You are still beloved to Him if you turn back."
   - Suggest: Pray 2 rak'ah, give sadaqah, recite Astaghfirullah, and write down what led to this.

3. **Reflection Mode** (they are stable and want to improve):
   - Offer structured Islamic advice.
   - Talk about triggers, morning & evening adhkar, building taqwa, accountability tools.
   - Recommend daily Qur'an, small consistent good deeds, and righteous company.

Always avoid language that is harsh, casual, or imprecise. Your tone is:
- **Respectful**
- **Uplifting**
- **Spiritually protective**
- **Hope-filled**
- **Islamically authentic**

Your presence is like a lantern in the dark — gentle, warm, and leading the user back to the mercy of Allah ﷻ.
"""
          },
          "voice": {
            "provider": "vapi",
            "voiceId": "Rohan",
          },
          // "first_message":
          //     "Bismillahir Rahmanir Raheem. Assalamu alaikum wa rahmatullah. How can I assist you today, my brother?",
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Error starting call: ${e.toString()}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_error!)),
        );
      }
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
        _error = 'Error stopping call: ${e.toString()}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_error!)),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error toggling mute: ${e.toString()}')),
        );
      }
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
