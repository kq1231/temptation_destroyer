import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temptation_destroyer/core/constants/app_colors.dart';
import 'package:temptation_destroyer/presentation/providers/auth_provider.dart';

class RecoveryCodesScreen extends ConsumerStatefulWidget {
  const RecoveryCodesScreen({super.key});

  @override
  ConsumerState<RecoveryCodesScreen> createState() =>
      _RecoveryCodesScreenState();
}

class _RecoveryCodesScreenState extends ConsumerState<RecoveryCodesScreen> {
  final int _codesCount = 5;
  List<String> _recoveryCodes = [];
  bool _isLoading = false;
  bool _codesGenerated = false;
  bool _hasConfirmed = false;
  final TextEditingController _confirmController = TextEditingController();

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _generateRecoveryCodes() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final codes = await ref.read(authProvider.notifier).generateRecoveryCodes(
            count: _codesCount,
          );

      setState(() {
        _recoveryCodes = codes;
        _codesGenerated = codes.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate recovery codes: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _copyToClipboard() async {
    final formattedCodes = _recoveryCodes.map((code) => '• $code').join('\n');
    await Clipboard.setData(ClipboardData(text: formattedCodes));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recovery codes copied to clipboard'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _confirmUnderstanding() {
    if (_confirmController.text.trim().toLowerCase() == 'i understand') {
      setState(() {
        _hasConfirmed = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please type "I understand" to confirm'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recovery Codes'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.security,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Account Recovery',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _codesGenerated
                  ? _buildRecoveryCodes()
                  : _hasConfirmed
                      ? _buildGenerateCodesSection()
                      : _buildSecurityWarning(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityWarning() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Card(
          color: Color(0xFFFFF3E0),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Important Security Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Recovery codes provide a way to access your account if you forget your password. Keep these codes safe and secure.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  '• Each code can only be used once',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  '• Store these codes in a secure place',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  '• Without these codes or your password, your data cannot be recovered',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _confirmController,
          decoration: const InputDecoration(
            labelText: 'Type "I understand" to continue',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed:
              _confirmController.text.trim().toLowerCase() == 'i understand'
                  ? _confirmUnderstanding
                  : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'I Understand',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateCodesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Generate recovery codes to use if you forget your password. You will receive ${5} codes that you should store securely.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _generateRecoveryCodes,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Generate Recovery Codes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRecoveryCodes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Card(
          color: Color(0xFFE8F5E9),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Save Your Recovery Codes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'These codes will only be shown once. Write them down or save them somewhere secure.',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.grey, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._recoveryCodes.map((code) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.vpn_key, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          code,
                          style: const TextStyle(
                            fontSize: 18,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          icon: const Icon(Icons.copy),
          label: const Text('Copy All Codes'),
          onPressed: _copyToClipboard,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Important: These codes will not be shown again. If you lose these codes and forget your password, your data cannot be recovered.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
