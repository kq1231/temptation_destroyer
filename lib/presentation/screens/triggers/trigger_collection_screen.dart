import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/trigger_model.dart';
import '../../providers/trigger_provider_refactored.dart';
import 'trigger_detail_screen.dart';
import 'trigger_form_screen.dart';
import '../../widgets/common/loading_indicator.dart';

/// Screen that displays a collection of triggers
class TriggerCollectionScreen extends ConsumerStatefulWidget {
  /// Constructor
  const TriggerCollectionScreen({super.key});

  @override
  ConsumerState<TriggerCollectionScreen> createState() =>
      _TriggerCollectionScreenState();
}

class _TriggerCollectionScreenState
    extends ConsumerState<TriggerCollectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchMode = false;
  bool _isMultiSelectMode = false;
  String? _currentFilter;

  @override
  void initState() {
    super.initState();
    // No need to explicitly load triggers - the AsyncNotifier will handle it
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.filter),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Triggers'),
              leading: Radio<String?>(
                value: null,
                groupValue: _currentFilter,
                onChanged: (value) {
                  Navigator.of(context).pop();
                  setState(() {
                    _currentFilter = value;
                  });
                  ref
                      .read(triggerNotifierProvider.notifier)
                      .filterByType(value);
                },
              ),
            ),
            ...TriggerType.values.map((type) => ListTile(
                  title: Text(_getTriggerTypeLabel(type)),
                  leading: Radio<String?>(
                    value: type,
                    groupValue: _currentFilter,
                    onChanged: (value) {
                      Navigator.of(context).pop();
                      setState(() {
                        _currentFilter = value;
                      });
                      ref
                          .read(triggerNotifierProvider.notifier)
                          .filterByType(value);
                    },
                  ),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
        ],
      ),
    );
  }

  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) {
        _searchController.clear();
        ref.read(triggerNotifierProvider.notifier).filterByType(_currentFilter);
      }
    });
  }

  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        ref.read(triggerNotifierProvider.notifier).clearSelection();
      }
    });
  }

  void _onSearchTextChanged(String text) {
    ref.read(triggerNotifierProvider.notifier).searchTriggers(text);
  }

  void _addTrigger() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TriggerFormScreen(),
      ),
    );
  }

  void _editTrigger(Trigger trigger) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TriggerFormScreen(trigger: trigger),
      ),
    );
  }

  void _viewTriggerDetails(Trigger trigger) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TriggerDetailScreen(trigger: trigger),
      ),
    );
  }

  void _deleteTrigger(int triggerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteTrigger),
        content: const Text('Are you sure you want to delete this trigger?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(triggerNotifierProvider.notifier)
                  .deleteTrigger(triggerId);
            },
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }

  void _deleteSelectedTriggers() {
    final triggerState = ref.watch(triggerNotifierProvider);

    // Handle the AsyncValue state
    if (triggerState is AsyncLoading) {
      return; // Don't proceed if still loading
    }

    if (triggerState is AsyncError) {
      // Handle error state if needed
      return;
    }

    // Safely unwrap the value
    final state = triggerState.value;
    if (state == null) return;

    final selectedCount = state.selectedTriggerIds.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteTrigger),
        content: Text(
            'Are you sure you want to delete $selectedCount selected triggers?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(triggerNotifierProvider.notifier)
                  .deleteSelectedTriggers();
              _toggleMultiSelectMode();
            },
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }

  Color _getTriggerTypeColor(String type) {
    if (type == TriggerType.emotional) return AppColors.emotionalTrigger;
    if (type == TriggerType.situational) return AppColors.socialTrigger;
    if (type == TriggerType.temporal) return AppColors.timeTrigger;
    if (type == TriggerType.physical) return AppColors.locationTrigger;
    if (type == TriggerType.custom) return AppColors.customTrigger;
    return Colors.grey; // Fallback
  }

  String _getTriggerTypeLabel(String type) {
    if (type == TriggerType.emotional) return AppStrings.triggerEmotion;
    if (type == TriggerType.situational) return AppStrings.triggerSocial;
    if (type == TriggerType.temporal) return AppStrings.triggerTime;
    if (type == TriggerType.physical) return AppStrings.triggerLocation;
    if (type == TriggerType.custom) return AppStrings.triggerCustom;
    return type; // Fallback
  }

  @override
  Widget build(BuildContext context) {
    final asyncTriggerState = ref.watch(triggerNotifierProvider);

    return asyncTriggerState.when(
      loading: () => const Scaffold(
        body: Center(child: LoadingIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text('Error loading triggers: $error'),
        ),
      ),
      data: (triggerState) {
        return Scaffold(
          appBar: AppBar(
            title: _isSearchMode
                ? TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: AppStrings.search,
                      border: InputBorder.none,
                    ),
                    onChanged: _onSearchTextChanged,
                    autofocus: true,
                  )
                : const Text(AppStrings.triggers),
            actions: [
              // Search action
              IconButton(
                icon: Icon(_isSearchMode ? Icons.close : Icons.search),
                onPressed: _toggleSearchMode,
              ),
              // Filter action
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog,
              ),
              // Multi-select action
              IconButton(
                icon:
                    Icon(_isMultiSelectMode ? Icons.cancel : Icons.select_all),
                onPressed: _toggleMultiSelectMode,
              ),
              // Delete selected action (only in multi-select mode)
              if (_isMultiSelectMode &&
                  triggerState.selectedTriggerIds.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteSelectedTriggers,
                ),
            ],
          ),
          body: triggerState.isLoading
              ? const Center(child: LoadingIndicator())
              : triggerState.filteredTriggers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            AppStrings.noTriggersAdded,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            AppStrings.addFirstTrigger,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _addTrigger,
                            icon: const Icon(Icons.add),
                            label: const Text(AppStrings.addTrigger),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: triggerState.filteredTriggers.length,
                      itemBuilder: (context, index) {
                        final trigger = triggerState.filteredTriggers[index];
                        final isSelected = triggerState.selectedTriggerIds
                            .contains(trigger.id);

                        return ListTile(
                          leading: _isMultiSelectMode
                              ? Checkbox(
                                  value: isSelected,
                                  onChanged: (value) {
                                    ref
                                        .read(triggerNotifierProvider.notifier)
                                        .toggleTriggerSelection(trigger.id);
                                  },
                                )
                              : Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: _getTriggerTypeColor(
                                        trigger.triggerType),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                          title: Text(trigger.description),
                          subtitle:
                              Text(_getTriggerTypeLabel(trigger.triggerType)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Intensity: ${trigger.intensity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (!_isMultiSelectMode) ...[
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editTrigger(trigger),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteTrigger(trigger.id),
                                ),
                              ]
                            ],
                          ),
                          onTap: _isMultiSelectMode
                              ? () {
                                  ref
                                      .read(triggerNotifierProvider.notifier)
                                      .toggleTriggerSelection(trigger.id);
                                }
                              : () => _viewTriggerDetails(trigger),
                        );
                      },
                    ),
          floatingActionButton: !_isMultiSelectMode
              ? FloatingActionButton(
                  onPressed: _addTrigger,
                  tooltip: AppStrings.addTrigger,
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }
}
