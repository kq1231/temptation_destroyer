import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/hadith_model.dart';
import '../../data/repositories/hadith_repository.dart';

class HadithManagementScreen extends ConsumerStatefulWidget {
  const HadithManagementScreen({super.key});

  @override
  ConsumerState<HadithManagementScreen> createState() =>
      _HadithManagementScreenState();
}

class _HadithManagementScreenState extends ConsumerState<HadithManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _importPresetHadiths() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Replace with actual preset hadiths
      final presetHadiths = [
        HadithModel(
          text:
              "The best among you is the one who learns the Qur'an and teaches it.",
          narrator: "Uthman ibn Affan",
          source: "Sahih al-Bukhari",
          reference: "5027",
          translation: "خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ",
          explanation:
              "This hadith emphasizes the importance of learning and teaching the Quran.",
        ),
        // Add more preset hadiths here
      ];

      await ref
          .read(hadithRepositoryProvider)
          .importPresetHadiths(presetHadiths);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully imported preset hadiths')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing hadiths: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hadith Collection'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Hadiths'),
            Tab(text: 'Favorites'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _HadithList(
                future: ref.watch(hadithRepositoryProvider).getAllHadiths(),
                emptyMessage: 'No hadiths available',
              ),
              _HadithList(
                future:
                    ref.watch(hadithRepositoryProvider).getFavoriteHadiths(),
                emptyMessage: 'No favorite hadiths yet',
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _importPresetHadiths,
        icon: const Icon(Icons.add),
        label: const Text('Import Presets'),
      ),
    );
  }
}

class _HadithList extends StatelessWidget {
  final Future<List<HadithModel>> future;
  final String emptyMessage;

  const _HadithList({
    required this.future,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<HadithModel>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          );
        }

        final hadiths = snapshot.data ?? [];
        if (hadiths.isEmpty) {
          return Center(
            child: Text(
              emptyMessage,
              style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: hadiths.length,
          itemBuilder: (context, index) {
            final hadith = hadiths[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ExpansionTile(
                title: Text(
                  hadith.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
                subtitle: Text(
                  'Narrated by ${hadith.narrator}',
                  style: theme.textTheme.bodySmall,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hadith.text,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        if (hadith.translation != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            hadith.translation!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          '${hadith.source} - ${hadith.reference}',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (hadith.explanation != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Explanation:',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hadith.explanation!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
