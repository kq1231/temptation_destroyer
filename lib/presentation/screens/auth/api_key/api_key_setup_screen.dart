import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temptation_destroyer/core/constants/app_colors.dart';
import 'package:temptation_destroyer/core/constants/app_strings.dart';
import 'package:temptation_destroyer/data/models/ai_models.dart';
import 'package:temptation_destroyer/data/repositories/ai_repository.dart';
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
  bool _isObscured = true;
  String _selectedProvider = 'openai';
  bool _hasStoredKey = false;

  late final AIRepository _repository;

  final Map<String, String> _providers = {
    'openai': 'OpenAI (GPT)',
    'anthropic': 'Anthropic (Claude)',
    'openrouter': 'Open Router',
  };

  final Map<String, AIServiceType> _serviceTypeMap = {
    'openai': AIServiceType.openAI,
    'anthropic': AIServiceType.anthropic,
    'openrouter': AIServiceType.openRouter,
  };

  @override
  void initState() {
    super.initState();
    _repository = AIRepository();
    _checkForExistingKeys();
  }

  Future<void> _checkForExistingKeys() async {
    setState(() => _isLoading = true);

    try {
      // Get current service config
      final config = _repository.getServiceConfig();

      // Set the initial provider selection based on the current config
      if (config.serviceType != AIServiceType.offline) {
        for (final entry in _serviceTypeMap.entries) {
          if (entry.value == config.serviceType) {
            setState(() => _selectedProvider = entry.key);
            break;
          }
        }
      }

      // Check if there's a key for the selected provider
      // Use the existing config to check for an API key
      final apiKey = config.apiKey;

      setState(() {
        _hasStoredKey = apiKey != null && apiKey.isNotEmpty;
        if (_hasStoredKey) {
          // Display a masked version of the API key
          _apiKeyController.text = apiKey!
              .replaceRange(4, apiKey.length - 4, '•' * (apiKey.length - 8));
        }
      });
    } catch (e) {
      print('Error checking for existing keys: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
      final apiKey = _apiKeyController.text.trim();
      final serviceType = _serviceTypeMap[_selectedProvider]!;

      // Get current config and update it
      final config = _repository.getServiceConfig();
      final updatedConfig = config.copyWith(
        serviceType: serviceType,
        apiKey: apiKey,
      );

      // Save to repository
      _repository.saveServiceConfig(updatedConfig);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${_providers[_selectedProvider]} API key saved successfully'),
          backgroundColor: AppColors.success,
        ),
      );

      setState(() {
        _hasStoredKey = true;
      });
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
      // Get current config and clear the API key
      final config = _repository.getServiceConfig();
      final updatedConfig = config.copyWith(
        apiKey: null,
      );

      // Save to repository
      _repository.saveServiceConfig(updatedConfig);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_providers[_selectedProvider]} API key removed'),
          backgroundColor: AppColors.success,
        ),
      );

      setState(() {
        _hasStoredKey = false;
        _apiKeyController.clear();
      });
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
      body: _isLoading && !mounted
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                        });
                        // When changing provider, check if we have a key for it
                        _checkForExistingKeys();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _apiKeyController,
                    focusNode: _apiFocusNode,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      hintText: _hasStoredKey
                          ? 'API key saved - edit to change'
                          : 'Enter your ${_providers[_selectedProvider]} API key',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.key),
                      suffixIcon: IconButton(
                        icon: Icon(_isObscured
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () {
                          setState(() => _isObscured = !_isObscured);
                        },
                      ),
                      errorText: hasError ? authState.errorMessage : null,
                    ),
                    obscureText: _isObscured,
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
                              : Text(
                                  _hasStoredKey
                                      ? 'Update API Key'
                                      : 'Save API Key',
                                  style: const TextStyle(
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
                          onPressed: _hasStoredKey && !_isLoading
                              ? _clearApiKey
                              : null,
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
                      _showApiKeyHelp();
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

  void _showApiKeyHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Get ${_providers[_selectedProvider]} API Key'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_getApiKeyInstructions()),
              const SizedBox(height: 16),
              const Text(
                  'Your API key will be stored securely on your device.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getApiKeyInstructions() {
    switch (_selectedProvider) {
      case 'openai':
        return 'To get an OpenAI API key:\n\n'
            '1. Go to platform.openai.com\n'
            '2. Create an account or log in\n'
            '3. Go to API Keys section\n'
            '4. Click "Create new secret key"\n'
            '5. Copy the key and paste it here';
      case 'anthropic':
        return 'To get an Anthropic API key:\n\n'
            '1. Go to console.anthropic.com\n'
            '2. Create an account or log in\n'
            '3. Go to API Keys section\n'
            '4. Create a new API key\n'
            '5. Copy the key and paste it here';
      case 'openrouter':
        return 'To get an OpenRouter API key:\n\n'
            '1. Go to openrouter.ai\n'
            '2. Create an account or log in\n'
            '3. Go to Keys section in your dashboard\n'
            '4. Create a new API key\n'
            '5. Copy the key and paste it here';
      default:
        return 'Please go to the provider\'s website and obtain an API key.';
    }
  }
}
