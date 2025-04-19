import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VoiceChatControls extends ConsumerWidget {
  final VoidCallback onStartCall;
  final VoidCallback onStopCall;
  final ValueChanged<bool> onMuteToggle;
  final bool isMuted;
  final bool isCallActive;
  final bool isLoading;

  const VoiceChatControls({
    super.key,
    required this.onStartCall,
    required this.onStopCall,
    required this.onMuteToggle,
    required this.isMuted,
    required this.isCallActive,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Start/Stop Call Button
            _buildStartStopButton(),
            // Mute Button
            _buildMuteButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStartStopButton() {
    return SizedBox(
      width: 56,
      height: 56,
      child: isLoading
          ? const CircularProgressIndicator()
          : FloatingActionButton(
              heroTag: 'startStopButton',
              onPressed:
                  isLoading ? null : (isCallActive ? onStopCall : onStartCall),
              backgroundColor: isCallActive ? Colors.red : Colors.green,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  isCallActive ? Icons.stop : Icons.play_arrow,
                  key: ValueKey<bool>(isCallActive),
                  color: Colors.white,
                ),
              ),
            ),
    );
  }

  Widget _buildMuteButton() {
    return SizedBox(
      width: 56,
      height: 56,
      child: FloatingActionButton(
        heroTag: 'muteButton',
        onPressed:
            isLoading || !isCallActive ? null : () => onMuteToggle(!isMuted),
        backgroundColor: isCallActive
            ? (isMuted ? Colors.red.shade200 : Colors.blue)
            : Colors.grey,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return RotationTransition(
              turns: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: Icon(
            isMuted ? Icons.mic_off : Icons.mic,
            key: ValueKey<bool>(isMuted),
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
