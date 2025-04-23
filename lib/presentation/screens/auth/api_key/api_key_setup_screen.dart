import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temptation_destroyer/core/constants/app_colors.dart';
import 'package:temptation_destroyer/core/constants/app_strings.dart';
import 'package:temptation_destroyer/core/utils/logger.dart';
import 'package:temptation_destroyer/data/models/ai_models.dart';
import 'package:temptation_destroyer/data/repositories/ai_repository.dart';
import 'package:temptation_destroyer/presentation/providers/auth_provider.dart';
import 'package:temptation_destroyer/core/security/secure_storage_service.dart';

class ApiKeySetupScreen extends ConsumerStatefulWidget {
  const ApiKeySetupScreen({super.key});

  @override
  ConsumerState<ApiKeySetupScreen> createState() => _ApiKeySetupScreenState();
}

class _ApiKeySetupScreenState extends ConsumerState<ApiKeySetupScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _vapiPrivateKeyController =
      TextEditingController();
  final FocusNode _apiFocusNode = FocusNode();
  final FocusNode _vapiPrivateFocusNode = FocusNode();
  bool _isLoading = false;
  bool _isObscured = true;
  bool _isPrivateKeyObscured = true;
  String _selectedProvider = 'openai';
  bool _hasStoredKey = false;
  bool _hasStoredPrivateKey = false;

  late final AIRepository _repository;

  final Map<String, String> _providers = {
    'openai': 'OpenAI (GPT)',
    'anthropic': 'Anthropic (Claude)',
    'openrouter': 'Open Router',
    'vapi': 'VAPI (Voice AI)',
  };

  final Map<String, String> _serviceTypeMap = {
    'openai': AIServiceType.openAI,
    'anthropic': AIServiceType.anthropic,
    'openrouter': AIServiceType.openRouter,
    'vapi': AIServiceType.vapiPublic, // Public key for VAPI
  };

  // Special map for private VAPI key
  final Map<String, String> _vapiPrivateKeyMap = {
    'vapi': AIServiceType.vapiPrivate,
  };

  @override
  void initState() {
    super.initState();
    _repository = AIRepository(ref);
    _checkForExistingKeys();
  }

  Future<void> _checkForExistingKeys() async {
    setState(() => _isLoading = true);

    try {
      final secureStorage = SecureStorageService.instance;

      // Check if there's a key for the selected provider
      final apiKey =
          await secureStorage.getKey(_serviceTypeMap[_selectedProvider]!);

      // If VAPI is selected, also check for private key
      String? privateKey;
      if (_selectedProvider == 'vapi') {
        privateKey =
            await secureStorage.getKey(_vapiPrivateKeyMap[_selectedProvider]!);
      }

      AppLogger.debug(
          "SERVICE TYPE FROM THE _checkForExistingKeys METHOD INSIDE THE api_key_setup_screen.dart: ${_serviceTypeMap[_selectedProvider]}");
      AppLogger.debug(
          "API KEY FROM THE _checkForExistingKeys METHOD INSIDE THE api_key_setup_screen.dart: $apiKey");

      if (_selectedProvider == 'vapi') {
        AppLogger.debug(
            "PRIVATE KEY EXISTS: ${privateKey != null && privateKey.isNotEmpty}");
      }

      setState(() {
        _hasStoredKey = apiKey != null && apiKey.isNotEmpty;

        if (_hasStoredKey && apiKey != null) {
          // Display a masked version of the API key
          _apiKeyController.text = apiKey.replaceRange(
              4, apiKey.length - 4, '•' * (apiKey.length - 8));
        } else {
          _hasStoredKey = false;
          _apiKeyController.clear();
        }

        // Handle private key for VAPI if needed
        if (_selectedProvider == 'vapi') {
          _hasStoredPrivateKey = privateKey != null && privateKey.isNotEmpty;

          if (_hasStoredPrivateKey && privateKey != null) {
            _vapiPrivateKeyController.text = privateKey.replaceRange(
                4, privateKey.length - 4, '•' * (privateKey.length - 8));
          } else {
            _hasStoredPrivateKey = false;
            _vapiPrivateKeyController.clear();
          }
        }
      });
    } catch (e) {
      AppLogger.debug('Error checking for existing keys: $e');
      setState(() {
        _hasStoredKey = false;
        _apiKeyController.clear();

        if (_selectedProvider == 'vapi') {
          _hasStoredPrivateKey = false;
          _vapiPrivateKeyController.clear();
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiFocusNode.dispose();
    _vapiPrivateKeyController.dispose();
    _vapiPrivateFocusNode.dispose();
    super.dispose();
  }

  bool _canSaveApiKey() {
    if (_selectedProvider == 'vapi') {
      // For VAPI, we need at least one key (either public or private)
      return (_apiKeyController.text.isNotEmpty ||
              _vapiPrivateKeyController.text.isNotEmpty) &&
          !_isLoading;
    }
    return _apiKeyController.text.isNotEmpty && !_isLoading;
  }

  Future<void> _saveApiKey() async {
    if (!_canSaveApiKey()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final secureStorage = SecureStorageService.instance;

      // Save public/main API key for the selected service
      final apiKey = _apiKeyController.text.trim();
      final serviceType = _serviceTypeMap[_selectedProvider]!;

      if (apiKey.isNotEmpty) {
        // Store the API key securely using the service type as the key
        await secureStorage.storeKey(serviceType, apiKey);
      }

      // Get current config and update it
      final config = _repository.getServiceConfig();
      final updatedConfig = config.copyWith(
        serviceType: serviceType,
        apiKey: apiKey.isNotEmpty
            ? apiKey
            : null, // We still keep this in config for immediate use
      );

      // Save to repository
      _repository.saveServiceConfig(updatedConfig);

      // For VAPI, also save the private key if provided
      if (_selectedProvider == 'vapi') {
        final privateKey = _vapiPrivateKeyController.text.trim();
        final privateKeyType = _vapiPrivateKeyMap[_selectedProvider]!;

        if (privateKey.isNotEmpty) {
          await secureStorage.storeKey(privateKeyType, privateKey);
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${_providers[_selectedProvider]} API key(s) saved successfully'),
          backgroundColor: AppColors.success,
        ),
      );

      setState(() {
        _hasStoredKey = apiKey.isNotEmpty;

        // Update private key storage state if VAPI
        if (_selectedProvider == 'vapi') {
          _hasStoredPrivateKey = _vapiPrivateKeyController.text.isNotEmpty;
        }
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
      final secureStorage = SecureStorageService.instance;
      final serviceType = _serviceTypeMap[_selectedProvider]!;

      // Delete the API key from secure storage using the service type
      await secureStorage.deleteKey(serviceType);

      // For VAPI, also delete the private key if it exists
      if (_selectedProvider == 'vapi') {
        final privateKeyType = _vapiPrivateKeyMap[_selectedProvider]!;
        await secureStorage.deleteKey(privateKeyType);
      }

      // Get current config and clear the API key if it's the current service
      final config = _repository.getServiceConfig();
      if (config.serviceType == serviceType) {
        final updatedConfig = config.copyWith(
          apiKey: null,
        );
        // Save to repository
        _repository.saveServiceConfig(updatedConfig);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_providers[_selectedProvider]} API key(s) removed'),
          backgroundColor: AppColors.success,
        ),
      );

      setState(() {
        _hasStoredKey = false;
        _apiKeyController.clear();

        if (_selectedProvider == 'vapi') {
          _hasStoredPrivateKey = false;
          _vapiPrivateKeyController.clear();
        }
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
    final isVapiSelected = _selectedProvider == 'vapi';

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Service Setup'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading && !mounted
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
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
                        AppLogger.debug(
                            "VALUE FROM THE onChanged METHOD INSIDE THE api_key_setup_screen.dart: $value");
                        if (value != null && value != _selectedProvider) {
                          setState(() {
                            _selectedProvider = value;
                            AppLogger.debug(
                                "SET STATE FROM THE onChanged METHOD INSIDE THE api_key_setup_screen.dart: $_selectedProvider");
                            _isLoading = true; // Show loading indicator
                          });

                          // When changing provider, check if we have a key for it
                          _checkForExistingKeys().then((_) {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Public Key Field - For all services
                    TextField(
                      controller: _apiKeyController,
                      focusNode: _apiFocusNode,
                      decoration: InputDecoration(
                        labelText:
                            isVapiSelected ? 'Public API Key' : 'API Key',
                        hintText: _hasStoredKey
                            ? 'API key saved - edit to change'
                            : isVapiSelected
                                ? 'Enter your VAPI public key (starts with vok_ or vapk_)'
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

                    // VAPI Private Key Field - Only shown when VAPI is selected
                    if (isVapiSelected) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _vapiPrivateKeyController,
                        focusNode: _vapiPrivateFocusNode,
                        decoration: InputDecoration(
                          labelText: 'Private API Key',
                          hintText: _hasStoredPrivateKey
                              ? 'Private key saved - edit to change'
                              : 'Enter your VAPI private key (starts with vsk_ or vspk_)',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.vpn_key),
                          suffixIcon: IconButton(
                            icon: Icon(_isPrivateKeyObscured
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () {
                              setState(() => _isPrivateKeyObscured =
                                  !_isPrivateKeyObscured);
                            },
                          ),
                        ),
                        obscureText: _isPrivateKeyObscured,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'VAPI requires both keys: public key for accessing assistants and private key for creating calls.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],

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
                                    isVapiSelected
                                        ? (_hasStoredKey ||
                                                _hasStoredPrivateKey)
                                            ? 'Update Keys'
                                            : 'Save Keys'
                                        : _hasStoredKey
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
                            onPressed: (isVapiSelected
                                        ? (_hasStoredKey ||
                                            _hasStoredPrivateKey)
                                        : _hasStoredKey) &&
                                    !_isLoading
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
                    const SizedBox(height: 24),
                    Text(
                      AppStrings.appVersionText,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
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
      case 'vapi':
        return 'To get VAPI API keys:\n\n'
            '1. Go to app.vapi.ai\n'
            '2. Create an account or log in\n'
            '3. Go to Settings → API Keys section\n'
            '4. You need two keys:\n'
            '   - PUBLIC KEY (starts with vok_ or vapk_): For accessing assistant information\n'
            '   - PRIVATE KEY (starts with vsk_ or vspk_): For creating calls and WebSocket connections\n'
            '5. Copy each key to the appropriate field';
      default:
        return 'Please go to the provider\'s website and obtain an API key.';
    }
  }
}
