import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/ai_service_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../../data/models/ai_models.dart' as models;
import '../../../core/security/secure_storage_service.dart';
import '../../providers/settings_provider.dart';

class AISettingsScreen extends ConsumerWidget {
  const AISettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiServiceState = ref.watch(aiServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Service Settings'),
      ),
      body: aiServiceState.isLoading
          ? const Center(child: LoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildServiceTypeSelector(context, ref),
                  const SizedBox(height: 24),
                  _buildApiKeySection(context, ref, aiServiceState),
                  const SizedBox(height: 24),
                  _buildSettingsSection(context, ref, aiServiceState),
                  const SizedBox(height: 24),
                  _buildAdvancedSettingsSection(context, ref, aiServiceState),
                  const SizedBox(height: 24),
                  _buildSoundSettingsSection(context, ref),
                  const SizedBox(height: 24),
                  _buildVoiceAISection(context, ref),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildServiceTypeSelector(BuildContext context, WidgetRef ref) {
    final currentType = ref.watch(
      aiServiceProvider.select((state) => state.config.serviceType),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Select AI Service',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildServiceOption(
          context,
          ref,
          models.AIServiceType.openAI,
          'OpenAI',
          'Access GPT-3.5, GPT-4, and more...',
          currentType == models.AIServiceType.openAI,
        ),
        _buildServiceOption(
          context,
          ref,
          models.AIServiceType.anthropic,
          'Anthropic',
          'Access Claude models',
          currentType == models.AIServiceType.anthropic,
        ),
        _buildServiceOption(
          context,
          ref,
          models.AIServiceType.openRouter,
          'OpenRouter',
          'Access multiple AI providers',
          currentType == models.AIServiceType.openRouter,
        ),
        _buildServiceOption(
          context,
          ref,
          models.AIServiceType.offline,
          'Offline Mode',
          'Basic guidance without AI',
          currentType == models.AIServiceType.offline,
        ),
      ],
    );
  }

  Widget _buildServiceOption(
    BuildContext context,
    WidgetRef ref,
    String type,
    String title,
    String subtitle,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () async {
        if (isSelected) return; // Don't refresh if already selected
        await ref.read(aiServiceProvider.notifier).setServiceType(type);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIconForServiceType(type),
                size: 24,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isSelected ? Colors.blue : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForServiceType(String type) {
    if (type == models.AIServiceType.openAI) {
      return Icons.smart_toy;
    } else if (type == models.AIServiceType.anthropic) {
      return Icons.psychology;
    } else if (type == models.AIServiceType.openRouter) {
      return Icons.router;
    } else if (type == models.AIServiceType.offline) {
      return Icons.wifi_off;
    } else {
      return Icons.question_mark;
    }
  }

  Widget _buildApiKeySection(
    BuildContext context,
    WidgetRef ref,
    AIServiceState state,
  ) {
    if (state.config.serviceType == models.AIServiceType.offline) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'API Key',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _getApiKeyInstructions(state.config.serviceType),
              style: const TextStyle(fontSize: 14),
              softWrap: true,
            ),
            const SizedBox(height: 16),
            if (state.config.apiKey != null && state.config.apiKey!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('API Key is set'),
                subtitle: const Text('Your key is securely stored'),
                trailing: TextButton(
                  onPressed: () {
                    _showChangeApiKeyDialog(context, ref, state);
                  },
                  child: const Text('Change'),
                ),
              )
            else
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    _showChangeApiKeyDialog(context, ref, state);
                  },
                  child: const Text('Set API Key'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getApiKeyInstructions(String serviceType) {
    if (serviceType == models.AIServiceType.openAI) {
      return 'You need an OpenAI API key. Get one from https://platform.openai.com';
    } else if (serviceType == models.AIServiceType.anthropic) {
      return 'You need an Anthropic API key. Get one from https://console.anthropic.com';
    } else if (serviceType == models.AIServiceType.openRouter) {
      return 'You need an OpenRouter API key. Get one from https://openrouter.ai';
    } else if (serviceType == models.AIServiceType.offline) {
      return 'No API key required for offline mode.';
    } else {
      return 'Unknown';
    }
  }

  void _showChangeApiKeyDialog(
    BuildContext context,
    WidgetRef ref,
    AIServiceState state,
  ) {
    final secureStorage = SecureStorageService.instance;

    // We'll use FutureBuilder to first retrieve the current API key
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<String?>(
          future: secureStorage.getKey(state.config.serviceType.toString()),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                title: Text('Loading API Key'),
                content: Center(
                  heightFactor: 2,
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final apiKeyController = TextEditingController(text: snapshot.data);

            return AlertDialog(
              title: Text(
                  'Enter ${_getServiceName(state.config.serviceType)} API Key'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: apiKeyController,
                    decoration: const InputDecoration(
                      labelText: 'API Key',
                      hintText: 'Enter your API key',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getApiKeyInstructions(state.config.serviceType),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final apiKey = apiKeyController.text.trim();
                    if (apiKey.isNotEmpty) {
                      // First close the dialog to avoid UI blocking
                      Navigator.of(context).pop();

                      // Show a loading indicator
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Saving API key...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }

                      // Store the API key securely with the service type as identifier
                      await secureStorage.storeKey(
                        state.config.serviceType.toString(),
                        apiKey,
                      );

                      // Update the provider state
                      ref.read(aiServiceProvider.notifier).setApiKey(apiKey);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${_getServiceName(state.config.serviceType)} API key saved successfully',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          }),
    );
  }

  String _getServiceName(String type) {
    if (type == models.AIServiceType.openAI) {
      return 'OpenAI';
    } else if (type == models.AIServiceType.anthropic) {
      return 'Anthropic';
    } else if (type == models.AIServiceType.openRouter) {
      return 'OpenRouter';
    } else if (type == models.AIServiceType.offline) {
      return 'Offline';
    } else {
      return 'Offline';
    }
  }

  Widget _buildSettingsSection(
    BuildContext context,
    WidgetRef ref,
    AIServiceState state,
  ) {
    if (state.config.serviceType == models.AIServiceType.offline) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text(
                  'Model Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StatefulBuilder(builder: (context, setState) {
              return SwitchListTile(
                title: const Text('Allow data training'),
                subtitle: const Text(
                  'Allow the AI provider to use your conversations for improving their models',
                  softWrap: true,
                ),
                value: state.config.allowDataTraining,
                onChanged: (value) {
                  // Update local state immediately for visual feedback
                  setState(() {});
                  ref.read(aiServiceProvider.notifier).toggleDataTraining();
                },
              );
            }),
            const SizedBox(height: 8),
            if (state.config.serviceType == models.AIServiceType.openRouter)
              _buildModelSelectionArea(ref, state)
            else ...[
              const Text('Preferred Model:'),
              const SizedBox(height: 8),
              StatefulBuilder(builder: (context, setState) {
                final modelValue = _getValidModelValue(
                    state.config.preferredModel, state.config.serviceType);

                return DropdownButtonFormField<String>(
                  value: modelValue,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  items: _getModelOptions(state.config.serviceType)
                      .map((model) => DropdownMenuItem(
                            value: model.value,
                            child: Text(
                              model.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      // Update local state immediately
                      setState(() {});
                      ref
                          .read(aiServiceProvider.notifier)
                          .setPreferredModel(value);
                    }
                  },
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSettingsSection(
    BuildContext context,
    WidgetRef ref,
    AIServiceState state,
  ) {
    if (state.config.serviceType == models.AIServiceType.offline) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text(
                  'Advanced Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Temperature slider
            const Text(
              'Temperature:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'Controls randomness in responses. Lower values are more focused, higher values more creative.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('0.0', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: StatefulBuilder(builder: (context, setState) {
                    return Slider(
                      value: state.config.temperature,
                      min: 0.0,
                      max: 2.0,
                      divisions: 20,
                      label: state.config.temperature.toStringAsFixed(1),
                      onChanged: (value) {
                        // Update local state immediately for visual feedback
                        setState(() {});
                        ref
                            .read(aiServiceProvider.notifier)
                            .setTemperature(value);
                      },
                    );
                  }),
                ),
                const Text('2.0', style: TextStyle(fontSize: 12)),
              ],
            ),

            const SizedBox(height: 16),

            // Max tokens slider
            const Text(
              'Maximum Response Length:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'Limits the length of AI responses. Higher values allow longer answers.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('512', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: StatefulBuilder(builder: (context, setState) {
                    return Slider(
                      value: state.config.maxTokens.toDouble(),
                      min: 512,
                      max: 4096,
                      divisions: 14,
                      label: state.config.maxTokens.toString(),
                      onChanged: (value) {
                        // Update local state immediately for visual feedback
                        setState(() {});
                        ref
                            .read(aiServiceProvider.notifier)
                            .setMaxTokens(value.toInt());
                      },
                    );
                  }),
                ),
                const Text('4096', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<ModelOption> _getModelOptions(String serviceType) {
    final defaultOption = ModelOption('default', 'Default (recommended)');

    if (serviceType == models.AIServiceType.openAI) {
      return [
        defaultOption,
        ModelOption('gpt-4o', 'GPT-4o (newest)'),
        ModelOption('gpt-4', 'GPT-4 (standard)'),
        ModelOption('gpt-4-turbo', 'GPT-4 Turbo (fast)'),
        ModelOption('gpt-3.5-turbo', 'GPT-3.5 Turbo (cheaper)'),
        ModelOption('gpt-3', 'GPT-3 (legacy)'),
        ModelOption('gpt-3-mini', 'GPT-3 Mini (lightweight)'),
        ModelOption('gpt-4o-mini', 'GPT-4o Mini (compact)'),
      ];
    } else if (serviceType == models.AIServiceType.anthropic) {
      return [
        defaultOption,
        ModelOption('claude-3-opus', 'Claude 3 Opus (best quality)'),
        ModelOption('claude-3-sonnet', 'Claude 3 Sonnet (balanced)'),
        ModelOption('claude-3-haiku', 'Claude 3 Haiku (fastest)'),
      ];
    } else if (serviceType == models.AIServiceType.openRouter) {
      return [
        defaultOption,
        ModelOption('meta/llama-3', 'Llama 3'),
        ModelOption('anthropic/claude-3-opus', 'Claude 3 Opus'),
        ModelOption('openai/gpt-4o', 'GPT-4o'),
        ModelOption('google/gemini-pro', 'Gemini Pro'),
      ];
    } else if (serviceType == models.AIServiceType.offline) {
      return [defaultOption];
    } else {
      return [defaultOption];
    }
  }

  Widget _buildModelSelectionArea(WidgetRef ref, AIServiceState state) {
    // Only show for OpenRouter
    if (state.config.serviceType != models.AIServiceType.openRouter) {
      return const SizedBox.shrink();
    }

    final currentModelId =
        state.config.preferredModel ?? openRouterModels[0]['id'];
    final modelInfo = models.modelInfoMap[currentModelId];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Model',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose a model that best fits your needs. More capable models may be more expensive but provide better guidance.',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 16),
        StatefulBuilder(builder: (context, setState) {
          // Local reference to make sure we're using the most current value
          final currentValue =
              ref.watch(aiServiceProvider).config.preferredModel ??
                  openRouterModels[0]['id'];

          return DropdownButtonFormField<String>(
            value: openRouterModels.any((m) => m['id'] == currentValue)
                ? currentValue
                : openRouterModels[0]['id'],
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'AI Model',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            items: openRouterModels.map((model) {
              return DropdownMenuItem<String>(
                value: model['id'],
                child: Text(
                  model['name']!,
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                // Update local state for immediate feedback
                setState(() {});
                ref.read(aiServiceProvider.notifier).setPreferredModel(value);
              }
            },
          );
        }),
        if (modelInfo != null) ...[
          const SizedBox(height: 24),
          _buildModelInfoCard(modelInfo),
        ],
      ],
    );
  }

  Widget _buildModelInfoCard(models.ModelInfo info) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              info.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              info.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildPricingSection(info.pricing),
            const SizedBox(height: 16),
            _buildPerformanceSection(info.performance),
            const SizedBox(height: 16),
            _buildRecommendationSection(info.usageRecommendation),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection(models.ModelPricing pricing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pricing',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildPriceInfoCard(
                'Input',
                '\$${pricing.promptPricePerToken.toStringAsFixed(4)}',
                'per 1K tokens',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPriceInfoCard(
                'Output',
                '\$${pricing.completionPricePerToken.toStringAsFixed(4)}',
                'per 1K tokens',
              ),
            ),
          ],
        ),
        if (pricing.contextWindow != null) ...[
          const SizedBox(height: 8),
          Text(
            'Context Window: ${pricing.contextWindow} tokens',
            style: const TextStyle(fontSize: 12),
          ),
        ],
        if (pricing.notes != null) ...[
          const SizedBox(height: 4),
          Text(
            pricing.notes!,
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriceInfoCard(String title, String price, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection(models.ModelPerformance performance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildPerformanceMetric(
                'Response Time',
                '${performance.averageResponseTime}s',
                Icons.timer,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPerformanceMetric(
                'Quality',
                '${performance.qualityRating}/5',
                Icons.star,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildStrengthsLimitations(
          performance.strengths,
          performance.limitations,
        ),
      ],
    );
  }

  Widget _buildPerformanceMetric(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthsLimitations(String strengths, String limitations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                strengths,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.info, color: Colors.orange, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                limitations,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecommendationSection(String recommendation) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              recommendation,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getValidModelValue(String? currentValue, String serviceType) {
    final modelOptions = _getModelOptions(serviceType);
    final validValues = modelOptions.map((option) => option.value).toList();
    return validValues.contains(currentValue) ? currentValue! : 'default';
  }

  Widget _buildSoundSettingsSection(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sound Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            settingsAsync.when(
              data: (settings) => SwitchListTile(
                title: const Text('Enable Sound Effects'),
                subtitle:
                    const Text('Play sounds for messages and notifications'),
                value: settings.soundEnabled,
                onChanged: (_) {
                  ref.read(settingsProvider.notifier).toggleSound();
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceAISection(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Voice AI Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Configure your VAPI credentials for voice chat functionality. You can get your VAPI key at https://vapi.ai',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.mic),
              label: const Text('Configure VAPI Key'),
              onPressed: () {
                _showVapiKeyDialog(context);
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/voice-chat');
              },
              child: const Text('Open Voice Chat'),
            ),
          ],
        ),
      ),
    );
  }

  void _showVapiKeyDialog(BuildContext context) {
    final keyController = TextEditingController();
    final secureStorage = SecureStorageService.instance;

    // Fetch current key if available
    secureStorage.getKey('vapi_public_key').then((currentKey) {
      keyController.text = currentKey ?? '';

      if (context.mounted) {
        showDialog<void>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('VAPI Key Setup'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Please enter your VAPI public key for voice AI features.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: keyController,
                      decoration: const InputDecoration(
                        labelText: 'VAPI Public Key',
                        border: OutlineInputBorder(),
                        hintText: 'Enter VAPI public key',
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
                      // Store the key securely
                      await secureStorage.storeKey('vapi_public_key', key);

                      if (context.mounted) {
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('VAPI key saved successfully')),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      }
    });
  }

  // Expanded list of popular models for OpenRouter
  static const List<Map<String, String>> openRouterModels = [
    {'id': 'meta/llama3-70b-instruct', 'name': 'Meta Llama 3 70B'},
    {'id': 'anthropic/claude-3-opus', 'name': 'Claude 3 Opus'},
    {'id': 'anthropic/claude-3-sonnet', 'name': 'Claude 3 Sonnet'},
    {'id': 'anthropic/claude-3.5-haiku', 'name': 'Claude 3 Haiku'},
    {'id': 'mistralai/mistral-7b-instruct', 'name': 'Mistral 7B'},
    {'id': 'google/gemma-7b-it', 'name': 'Google Gemma 7B'},
    {'id': 'openai/gpt-4', 'name': 'GPT-4'},
    {'id': 'openai/gpt-4-turbo', 'name': 'GPT-4 Turbo'},
    {'id': 'openai/gpt-3.5-turbo', 'name': 'GPT-3.5 Turbo'},
    {'id': 'cohere/command-r', 'name': 'Cohere Command-R'},
    {'id': 'meta/llama3-8b-instruct', 'name': 'Meta Llama 3 8B'},
  ];
}

class ModelOption {
  final String value;
  final String label;

  ModelOption(this.value, this.label);
}
