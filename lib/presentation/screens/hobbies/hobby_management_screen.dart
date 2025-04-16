import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temptation_destroyer/data/models/hobby_model.dart';
import 'package:temptation_destroyer/presentation/providers/hobby_provider.dart';
import 'package:temptation_destroyer/presentation/widgets/app_loading_indicator.dart';

class HobbyManagementScreen extends ConsumerStatefulWidget {
  static const routeName = '/hobbies';

  const HobbyManagementScreen({super.key});

  @override
  ConsumerState<HobbyManagementScreen> createState() =>
      _HobbyManagementScreenState();
}

class _HobbyManagementScreenState extends ConsumerState<HobbyManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Create tab controller for the different hobby categories
    _tabController =
        TabController(length: HobbyCategory.values.length + 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      // Load hobbies when the screen first loads
      Future.microtask(() => ref.read(hobbyProvider.notifier).loadHobbies());
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hobbyState = ref.watch(hobbyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Hobbies'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add_check),
            onPressed: () => _importPresetHobbies(context),
            tooltip: 'Import preset hobbies',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            const Tab(text: 'All'),
            ...HobbyCategory.values.map((category) => Tab(
                  text: _getCategoryName(category),
                ))
          ],
        ),
      ),
      body: hobbyState.isLoading
          ? const AppLoadingIndicator()
          : _buildBody(hobbyState),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddHobby(context),
        tooltip: 'Add new hobby',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(HobbyState state) {
    if (state.errorMessage != null) {
      return Center(
        child: Text(
          'Error: ${state.errorMessage}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (state.hobbies.isEmpty) {
      return const Center(
        child: Text(
          'No hobbies yet. Add some to get started!',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        // All hobbies
        _buildHobbyList(state.hobbies),

        // Categorized hobbies
        ...HobbyCategory.values.map((category) {
          final hobbiesInCategory = state.hobbies
              .where((hobby) => hobby.category == category)
              .toList();
          return _buildHobbyList(hobbiesInCategory);
        }),
      ],
    );
  }

  Widget _buildHobbyList(List<HobbyModel> hobbies) {
    if (hobbies.isEmpty) {
      return const Center(
        child: Text(
          'No hobbies in this category',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: hobbies.length,
      itemBuilder: (context, index) {
        final hobby = hobbies[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            title: Text(
              hobby.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hobby.description != null && hobby.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(hobby.description!),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Chip(
                        label: Text(_getCategoryName(hobby.category!)),
                        backgroundColor: _getCategoryColor(hobby.category!)
                            .withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: _getCategoryColor(hobby.category!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (hobby.durationGoalMinutes != null)
                        Chip(
                          label: Text('${hobby.durationGoalMinutes} min'),
                          backgroundColor: Colors.blue.withValues(alpha: 0.1),
                          labelStyle: const TextStyle(color: Colors.blue),
                        ),
                    ],
                  ),
                ),
                if (hobby.lastPracticedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Last practiced: ${_formatDate(hobby.lastPracticedAt!)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _navigateToEditHobby(context, hobby),
                  tooltip: 'Edit hobby',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeleteHobby(context, hobby),
                  tooltip: 'Delete hobby',
                ),
              ],
            ),
            onTap: () => _navigateToHobbyDetails(context, hobby),
          ),
        );
      },
    );
  }

  void _navigateToAddHobby(BuildContext context) {
    // Navigate to add hobby screen
    // Will implement this screen next
    Navigator.of(context).pushNamed('/hobbies/add');
  }

  void _navigateToEditHobby(BuildContext context, HobbyModel hobby) {
    // Navigate to edit hobby screen
    // Will implement this screen next
    Navigator.of(context).pushNamed('/hobbies/edit', arguments: hobby);
  }

  void _navigateToHobbyDetails(BuildContext context, HobbyModel hobby) {
    // Navigate to hobby details screen
    // Will implement this screen next
    Navigator.of(context).pushNamed('/hobbies/details', arguments: hobby);
  }

  void _confirmDeleteHobby(BuildContext context, HobbyModel hobby) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Hobby'),
        content: Text('Are you sure you want to delete "${hobby.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(hobbyProvider.notifier).deleteHobby(hobby.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${hobby.name} deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _importPresetHobbies(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Preset Hobbies'),
        content: const Text(
          'This will add a collection of predefined hobbies to your list. '
          'Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(hobbyProvider.notifier).importPresetHobbies();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preset hobbies imported')),
              );
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(HobbyCategory category) {
    switch (category) {
      case HobbyCategory.physical:
        return 'Physical';
      case HobbyCategory.mental:
        return 'Mental';
      case HobbyCategory.social:
        return 'Social';
      case HobbyCategory.spiritual:
        return 'Spiritual';
      case HobbyCategory.creative:
        return 'Creative';
      case HobbyCategory.productive:
        return 'Productive';
      case HobbyCategory.relaxing:
        return 'Relaxing';
    }
  }

  Color _getCategoryColor(HobbyCategory category) {
    switch (category) {
      case HobbyCategory.physical:
        return Colors.green;
      case HobbyCategory.mental:
        return Colors.purple;
      case HobbyCategory.social:
        return Colors.orange;
      case HobbyCategory.spiritual:
        return Colors.indigo;
      case HobbyCategory.creative:
        return Colors.pink;
      case HobbyCategory.productive:
        return Colors.teal;
      case HobbyCategory.relaxing:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    // Simple date formatting
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
