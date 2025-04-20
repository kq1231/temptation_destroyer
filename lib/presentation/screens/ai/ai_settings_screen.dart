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
                  _buildHistorySection(context, ref, aiServiceState),
                  const SizedBox(height: 24),
                  _buildSoundSettingsSection(context, ref),
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
        const Text(
          'Select AI Service',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildServiceOption(
          context,
          ref,
          models.AIServiceType.openAI,
          'OpenAI',
          'Access GPT-3.5 and GPT-4',
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
    models.AIServiceType type,
    String title,
    String subtitle,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () {
        ref.read(aiServiceProvider.notifier).setServiceType(type);
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

  IconData _getIconForServiceType(models.AIServiceType type) {
    switch (type) {
      case models.AIServiceType.openAI:
        return Icons.smart_toy;
      case models.AIServiceType.anthropic:
        return Icons.psychology;
      case models.AIServiceType.openRouter:
        return Icons.router;
      case models.AIServiceType.offline:
        return Icons.wifi_off;
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

    final hasApiKey =
        state.config.apiKey != null && state.config.apiKey!.isNotEmpty;

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
            if (hasApiKey)
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

  String _getApiKeyInstructions(models.AIServiceType serviceType) {
    final type = models.AIServiceType.values[serviceType.index];
    switch (type) {
      case models.AIServiceType.openAI:
        return 'You need an OpenAI API key. Get one from https://platform.openai.com';
      case models.AIServiceType.anthropic:
        return 'You need an Anthropic API key. Get one from https://console.anthropic.com';
      case models.AIServiceType.openRouter:
        return 'You need an OpenRouter API key. Get one from https://openrouter.ai';
      case models.AIServiceType.offline:
        return 'No API key required for offline mode.';
    }
  }

  void _showChangeApiKeyDialog(
    BuildContext context,
    WidgetRef ref,
    AIServiceState state,
  ) {
    final apiKeyController = TextEditingController(text: state.config.apiKey);
    final secureStorage = SecureStorageService.instance;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text('Enter ${_getServiceName(state.config.serviceType)} API Key'),
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
                // Store the API key securely with the service type as identifier
                // Not awaiting this to avoid blocking the UI
                // Very important for smooth user experience
                secureStorage.storeKey(
                  state.config.serviceType.toString(),
                  apiKey,
                );

                // Update the provider state
                ref.read(aiServiceProvider.notifier).setApiKey(apiKey);

                if (context.mounted) {
                  Navigator.of(context).pop();

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
      ),
    );
  }

  String _getServiceName(models.AIServiceType type) {
    switch (type) {
      case models.AIServiceType.openAI:
        return 'OpenAI';
      case models.AIServiceType.anthropic:
        return 'Anthropic';
      case models.AIServiceType.openRouter:
        return 'OpenRouter';
      case models.AIServiceType.offline:
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
            const Text(
              'Model Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Allow data training'),
              subtitle: const Text(
                'Allow the AI provider to use your conversations for improving their models',
                softWrap: true,
              ),
              value: state.config.allowDataTraining,
              onChanged: (value) {
                ref.read(aiServiceProvider.notifier).toggleDataTraining();
              },
            ),
            const SizedBox(height: 8),
            if (state.config.serviceType == models.AIServiceType.openRouter)
              _buildModelSelectionArea(ref, state)
            else ...[
              const Text('Preferred Model:'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _getValidModelValue(state.config.preferredModel),
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
                    ref
                        .read(aiServiceProvider.notifier)
                        .setPreferredModel(value);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<ModelOption> _getModelOptions(models.AIServiceType serviceType) {
    final type = models.AIServiceType.values[serviceType.index];
    final defaultOption = ModelOption('default', 'Default (recommended)');

    switch (type) {
      case models.AIServiceType.openAI:
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
      case models.AIServiceType.anthropic:
        return [
          defaultOption,
          ModelOption('claude-3-opus', 'Claude 3 Opus (best quality)'),
          ModelOption('claude-3-sonnet', 'Claude 3 Sonnet (balanced)'),
          ModelOption('claude-3-haiku', 'Claude 3 Haiku (fastest)'),
        ];
      case models.AIServiceType.openRouter:
        return [
          defaultOption,
          ModelOption('meta/llama-3', 'Llama 3'),
          ModelOption('anthropic/claude-3-opus', 'Claude 3 Opus'),
          ModelOption('openai/gpt-4o', 'GPT-4o'),
          ModelOption('google/gemini-pro', 'Gemini Pro'),
        ];
      case models.AIServiceType.offline:
        return [defaultOption];
    }
  }

  Widget _buildHistorySection(
    BuildContext context,
    WidgetRef ref,
    AIServiceState state,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chat History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Store chat history'),
              subtitle: const Text(
                'If enabled, your chat history will be stored on your device only',
                softWrap: true,
              ),
              value: state.config.settings.storeChatHistory,
              onChanged: (value) {
                ref
                    .read(aiServiceProvider.notifier)
                    .updateStoreChatHistory(value);
              },
            ),
            if (state.config.settings.storeChatHistory) ...[
              const SizedBox(height: 8),
              const Text('Auto-delete after:'),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: state.config.settings.autoDeleteAfterDays,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                items: [
                  DropdownMenuItem(value: 7, child: Text('7 days')),
                  DropdownMenuItem(value: 30, child: Text('30 days')),
                  DropdownMenuItem(value: 90, child: Text('90 days')),
                  DropdownMenuItem(value: 365, child: Text('1 year')),
                  DropdownMenuItem(value: -1, child: Text('Never')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(aiServiceProvider.notifier)
                        .updateAutoDeleteDays(value);
                  }
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showClearHistoryConfirmation(context, ref);
                  },
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Clear All Chat History'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showClearHistoryConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Chat History'),
        content: const Text(
          'Are you sure you want to delete all of your chat history? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              ref.read(aiServiceProvider.notifier).clearChatHistory();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chat history cleared'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );
  }

  // Expanded list of popular models for OpenRouter
  static const List<Map<String, String>> openRouterModels = [
    {'id': 'meta/llama3-70b-instruct', 'name': 'Meta Llama 3 70B'},
    {'id': 'anthropic/claude-3-opus', 'name': 'Claude 3 Opus'},
    {'id': 'anthropic/claude-3-sonnet', 'name': 'Claude 3 Sonnet'},
    {'id': 'anthropic/claude-3-haiku', 'name': 'Claude 3 Haiku'},
    {'id': 'mistralai/mistral-7b-instruct', 'name': 'Mistral 7B'},
    {'id': 'google/gemma-7b-it', 'name': 'Google Gemma 7B'},
    {'id': 'openai/gpt-4', 'name': 'GPT-4'},
    {'id': 'openai/gpt-4-turbo', 'name': 'GPT-4 Turbo'},
    {'id': 'openai/gpt-3.5-turbo', 'name': 'GPT-3.5 Turbo'},
    {'id': 'cohere/command-r', 'name': 'Cohere Command-R'},
    {'id': 'meta/llama3-8b-instruct', 'name': 'Meta Llama 3 8B'},
  ];

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
        DropdownButtonFormField<String>(
          value: openRouterModels.any((m) => m['id'] == currentModelId)
              ? currentModelId
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
              ref.read(aiServiceProvider.notifier).setPreferredModel(value);
            }
          },
        ),
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

  String _getValidModelValue(String? currentValue) {
    final modelOptions = _getModelOptions(models.AIServiceType.openAI);
    final validValues = modelOptions.map((option) => option.value).toList();
    return validValues.contains(currentValue) ? currentValue! : 'default';
  }

  Widget _buildSoundSettingsSection(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

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
            SwitchListTile(
              title: const Text('Enable Sound Effects'),
              subtitle:
                  const Text('Play sounds for messages and notifications'),
              value: settings.soundEnabled,
              onChanged: (_) {
                ref.read(settingsProvider.notifier).toggleSound();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ModelOption {
  final String value;
  final String label;

  ModelOption(this.value, this.label);
}
