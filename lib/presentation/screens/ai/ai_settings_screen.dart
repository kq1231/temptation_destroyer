import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/ai_service_provider.dart';
import '../../widgets/common/loading_indicator.dart';

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
                  _buildServiceTypeSelector(context, ref, aiServiceState),
                  const SizedBox(height: 24),
                  _buildApiKeySection(context, ref, aiServiceState),
                  const SizedBox(height: 24),
                  _buildSettingsSection(context, ref, aiServiceState),
                  const SizedBox(height: 24),
                  _buildHistorySection(context, ref, aiServiceState),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildServiceTypeSelector(
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
              'AI Service Provider',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose which AI service to use for generating guidance:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AIServiceType>(
              value: state.config.serviceType,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              items: [
                DropdownMenuItem(
                  value: AIServiceType.openAI,
                  child: _buildServiceOption(
                    'OpenAI',
                    'GPT models (ChatGPT, GPT-4)',
                    Icons.smart_toy,
                  ),
                ),
                DropdownMenuItem(
                  value: AIServiceType.anthropic,
                  child: _buildServiceOption(
                    'Anthropic',
                    'Claude models',
                    Icons.psychology,
                  ),
                ),
                DropdownMenuItem(
                  value: AIServiceType.openRouter,
                  child: _buildServiceOption(
                    'Open Router',
                    'Multiple models through one API',
                    Icons.router,
                  ),
                ),
                DropdownMenuItem(
                  value: AIServiceType.offline,
                  child: _buildServiceOption(
                    'Offline Mode',
                    'No API key required',
                    Icons.wifi_off,
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(aiServiceProvider.notifier).updateServiceType(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceOption(String title, String subtitle, IconData icon) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
    );
  }

  Widget _buildApiKeySection(
    BuildContext context,
    WidgetRef ref,
    AIServiceState state,
  ) {
    if (state.config.serviceType == AIServiceType.offline) {
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

  String _getApiKeyInstructions(AIServiceType serviceType) {
    switch (serviceType) {
      case AIServiceType.openAI:
        return 'You need an OpenAI API key. Get one from https://platform.openai.com';
      case AIServiceType.anthropic:
        return 'You need an Anthropic API key. Get one from https://console.anthropic.com';
      case AIServiceType.openRouter:
        return 'You need an OpenRouter API key. Get one from https://openrouter.ai';
      case AIServiceType.offline:
        return 'No API key required for offline mode.';
    }
  }

  void _showChangeApiKeyDialog(
    BuildContext context,
    WidgetRef ref,
    AIServiceState state,
  ) {
    final TextEditingController controller = TextEditingController();
    if (state.config.apiKey != null) {
      controller.text = state.config.apiKey!;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Enter ${state.config.serviceType.name} API Key'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'API Key',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('CANCEL'),
            ),
            if (state.config.apiKey != null && state.config.apiKey!.isNotEmpty)
              TextButton(
                onPressed: () {
                  ref.read(aiServiceProvider.notifier).updateApiKey('');
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('API key removed'),
                    ),
                  );
                },
                child: const Text('REMOVE'),
              ),
            TextButton(
              onPressed: () {
                final apiKey = controller.text.trim();
                if (apiKey.isNotEmpty) {
                  ref.read(aiServiceProvider.notifier).updateApiKey(apiKey);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('API key saved'),
                    ),
                  );
                }
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    WidgetRef ref,
    AIServiceState state,
  ) {
    if (state.config.serviceType == AIServiceType.offline) {
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
                ref
                    .read(aiServiceProvider.notifier)
                    .updateAllowDataTraining(value);
              },
            ),
            const SizedBox(height: 8),
            const Text('Preferred Model:'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: state.config.preferredModel ?? 'default',
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
                      .updatePreferredModel(value == 'default' ? null : value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  List<ModelOption> _getModelOptions(AIServiceType serviceType) {
    final defaultOption = ModelOption('default', 'Default (recommended)');

    switch (serviceType) {
      case AIServiceType.openAI:
        return [
          defaultOption,
          ModelOption('gpt-4o', 'GPT-4o (newest)'),
          ModelOption('gpt-4-turbo', 'GPT-4 Turbo'),
          ModelOption('gpt-3.5-turbo', 'GPT-3.5 Turbo (cheaper)'),
        ];
      case AIServiceType.anthropic:
        return [
          defaultOption,
          ModelOption('claude-3-opus', 'Claude 3 Opus (best quality)'),
          ModelOption('claude-3-sonnet', 'Claude 3 Sonnet (balanced)'),
          ModelOption('claude-3-haiku', 'Claude 3 Haiku (fastest)'),
        ];
      case AIServiceType.openRouter:
        return [
          defaultOption,
          ModelOption('meta/llama-3', 'Llama 3'),
          ModelOption('anthropic/claude-3-opus', 'Claude 3 Opus'),
          ModelOption('openai/gpt-4o', 'GPT-4o'),
          ModelOption('google/gemini-pro', 'Gemini Pro'),
        ];
      case AIServiceType.offline:
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
}

class ModelOption {
  final String value;
  final String label;

  ModelOption(this.value, this.label);
}
