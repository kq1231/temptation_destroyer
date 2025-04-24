import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temptation_destroyer/data/models/aspiration_model.dart';
import 'package:temptation_destroyer/presentation/providers/aspiration_provider.dart';
import 'package:temptation_destroyer/presentation/screens/aspirations/aspiration_entry_screen.dart';
import 'package:temptation_destroyer/presentation/widgets/app_loading_indicator.dart';
import 'package:temptation_destroyer/presentation/widgets/aspirations/category_selector.dart';
import 'package:temptation_destroyer/presentation/widgets/aspirations/goals_list.dart';

class AspirationsManagementScreen extends ConsumerStatefulWidget {
  static const routeName = '/aspirations';

  const AspirationsManagementScreen({super.key});

  @override
  ConsumerState<AspirationsManagementScreen> createState() =>
      _AspirationsManagementScreenState();
}

class _AspirationsManagementScreenState
    extends ConsumerState<AspirationsManagementScreen> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      // Load aspirations when the screen first loads
      Future.microtask(
          () => ref.read(aspirationProvider.notifier).loadAspirations());
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final aspirationState = ref.watch(aspirationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aspirations & Duas'),
        actions: [
          // Status filter button
          PopupMenuButton<bool?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by status',
            onSelected: (value) {
              ref.read(aspirationProvider.notifier).filterByStatus(value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All'),
              ),
              const PopupMenuItem(
                value: true,
                child: Text('Achieved'),
              ),
              const PopupMenuItem(
                value: false,
                child: Text('Not Achieved'),
              ),
            ],
          ),
          // Import presets button
          IconButton(
            icon: const Icon(Icons.playlist_add_check),
            onPressed: () => _importPresetAspirations(context),
            tooltip: 'Import preset aspirations',
          ),
        ],
      ),
      body: aspirationState.isLoading
          ? const AppLoadingIndicator()
          : _buildBody(aspirationState),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddAspiration(context),
        tooltip: 'Add new aspiration',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(AspirationState state) {
    if (state.errorMessage != null) {
      return Center(
        child: Text(
          'Error: ${state.errorMessage}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return Column(
      children: [
        // Achievement stats card
        if (state.achievementStats != null)
          _buildStatsCard(state.achievementStats!),

        // Category filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: CategorySelector(
            selectedCategory: state.currentFilter,
            onCategorySelected: (category) {
              ref.read(aspirationProvider.notifier).filterByCategory(category);
            },
          ),
        ),

        // Aspirations list
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: GoalsList(
              aspirations: state.filteredAspirations,
              onTap: (aspiration) => _viewAspiration(context, aspiration),
              onToggleAchieved: (aspiration) {
                ref
                    .read(aspirationProvider.notifier)
                    .toggleAchievementStatus(aspiration.id);
              },
              onEdit: (aspiration) =>
                  _navigateToEditAspiration(context, aspiration),
              onDelete: (aspiration) =>
                  _confirmDeleteAspiration(context, aspiration),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> stats) {
    final achievedCount = stats['achievedCount'] as int;
    final totalCount = stats['totalCount'] as int;
    final achievementRate = stats['achievementRate'] as double;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Progress: $achievedCount/$totalCount',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: totalCount > 0 ? achievedCount / totalCount : 0,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 8),
            Text(
              '${achievementRate.toStringAsFixed(1)}% Complete',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddAspiration(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AspirationEntryScreen(),
      ),
    );
  }

  void _navigateToEditAspiration(
      BuildContext context, AspirationModel aspiration) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AspirationEntryScreen(aspiration: aspiration),
      ),
    );
  }

  void _viewAspiration(BuildContext context, AspirationModel aspiration) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                aspiration.isAchieved ? 'Achieved Aspiration' : 'Aspiration',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),

              // Content
              Text(
                aspiration.dua,
                style: const TextStyle(fontSize: 18, height: 1.5),
                textDirection: _containsArabic(aspiration.dua)
                    ? TextDirection.rtl
                    : TextDirection.ltr,
              ),
              const SizedBox(height: 16),

              // Category
              Row(
                children: [
                  const Icon(Icons.category, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Category: ${_getCategoryName(aspiration.category)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Target date if available
              if (aspiration.targetDate != null)
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Target date: ${_formatDate(aspiration.targetDate!)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),

              // Achievement date if achieved
              if (aspiration.isAchieved && aspiration.achievedDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          size: 20, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Achieved on: ${_formatDate(aspiration.achievedDate!)}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

              // Note if available
              if (aspiration.note != null && aspiration.note!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notes:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        aspiration.note!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Toggle achievement status
                  ElevatedButton.icon(
                    icon: Icon(
                      aspiration.isAchieved ? Icons.cancel : Icons.check_circle,
                    ),
                    label: Text(
                      aspiration.isAchieved
                          ? 'Mark as Not Achieved'
                          : 'Mark as Achieved',
                    ),
                    onPressed: () {
                      ref
                          .read(aspirationProvider.notifier)
                          .toggleAchievementStatus(aspiration.id);
                      Navigator.pop(context);
                    },
                  ),

                  // Edit button
                  TextButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToEditAspiration(context, aspiration);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteAspiration(
      BuildContext context, AspirationModel aspiration) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Aspiration'),
        content: Text(
          'Are you sure you want to delete this aspiration?\n\n"${aspiration.dua}"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(aspirationProvider.notifier)
                  .deleteAspiration(aspiration.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Aspiration deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _importPresetAspirations(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Preset Aspirations'),
        content: const Text(
          'Do you want to import the preset aspirations and duas? These include common Islamic duas and personal growth aspirations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(aspirationProvider.notifier).importPresetAspirations();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preset aspirations imported')),
              );
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  /// Format date as readable string
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Get a user-friendly name for a category
  String _getCategoryName(String category) {
    if (category == AspirationCategory.personal) return 'Personal';
    if (category == AspirationCategory.family) return 'Family';
    if (category == AspirationCategory.career) return 'Career';
    if (category == AspirationCategory.spiritual) return 'Spiritual';
    if (category == AspirationCategory.health) return 'Health';
    if (category == AspirationCategory.social) return 'Social';
    if (category == AspirationCategory.financial) return 'Financial';
    if (category == AspirationCategory.customized) return 'Custom';
    return category; // Fallback
  }

  /// Check if text contains Arabic characters
  bool _containsArabic(String text) {
    // Unicode range for Arabic characters
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(text);
  }
}
