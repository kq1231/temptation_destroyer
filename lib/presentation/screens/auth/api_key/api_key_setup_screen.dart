import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temptation_destroyer/core/constants/app_colors.dart';
import 'package:temptation_destroyer/core/constants/app_strings.dart';
import 'package:temptation_destroyer/presentation/providers/auth_provider.dart';

class ApiKeySetupScreen extends ConsumerStatefulWidget {
  const ApiKeySetupScreen({super.key});

  @override
  ConsumerState<ApiKeySetupScreen> createState() => _ApiKeySetupScreenState();
}

class _ApiKeySetupScreenState extends ConsumerState<ApiKeySetupScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final FocusNode _apiFocusNode = FocusNode();
  bool _isLoading = false;
  String _selectedProvider = 'anthropic';

  final Map<String, String> _providers = {
    'anthropic': 'Anthropic (Claude)',
    'openai': 'OpenAI (GPT)',
    'openrouter': 'Open Router',
  };

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiFocusNode.dispose();
    super.dispose();
  }

  bool _canSaveApiKey() {
    return _apiKeyController.text.isNotEmpty && !_isLoading;
  }

  Future<void> _saveApiKey() async {
    if (!_canSaveApiKey()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authProvider.notifier).saveApiKey(
            _apiKeyController.text.trim(),
            _selectedProvider,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${_providers[_selectedProvider]} API key saved successfully'),
          backgroundColor: AppColors.success,
        ),
      );

      // Clear the field after successful save
      _apiKeyController.clear();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save API key: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearApiKey() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authProvider.notifier).clearApiKey();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_providers[_selectedProvider]} API key removed'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove API key: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final hasError = authState.errorMessage != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Service Setup'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Icon(
              Icons.api,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Configure AI Service',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your API key for the selected AI service provider.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'AI Service Provider',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cloud),
              ),
              value: _selectedProvider,
              items: _providers.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedProvider = value;
                    // Clear the API key field when switching providers
                    _apiKeyController.clear();
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              focusNode: _apiFocusNode,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: 'Enter your ${_providers[_selectedProvider]} API key',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.key),
                errorText: hasError ? authState.errorMessage : null,
              ),
              obscureText: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Text(
              'Your API key is stored securely on your device and is only used to communicate with the AI service.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _canSaveApiKey() ? _saveApiKey : null,
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
                            'Save API Key',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _clearApiKey,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Clear'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // Navigate to documentation or help
              },
              child: const Text('How to get an API key?'),
            ),
            const Expanded(child: SizedBox()),
            Text(
              AppStrings.appVersionText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
