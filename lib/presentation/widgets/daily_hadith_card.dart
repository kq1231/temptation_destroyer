import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/hadith_model.dart';
import '../../data/repositories/hadith_repository.dart';
import '../../domain/usecases/get_daily_hadith_usecase.dart';

class DailyHadithCard extends ConsumerWidget {
  const DailyHadithCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return FutureBuilder<HadithModel?>(
      future: ref.watch(getDailyHadithUseCaseProvider).execute(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error loading hadith: ${snapshot.error}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ),
          );
        }

        final hadith = snapshot.data;
        if (hadith == null) {
          return const SizedBox.shrink();
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.format_quote, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Hadith of the Day',
                      style: theme.textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        hadith.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: hadith.isFavorite ? Colors.red : null,
                      ),
                      onPressed: () {
                        ref
                            .read(hadithRepositoryProvider)
                            .toggleFavorite(hadith.id);
                      },
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
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
                  'Narrated by ${hadith.narrator}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${hadith.source} - ${hadith.reference}',
                  style: theme.textTheme.bodySmall,
                ),
                if (hadith.explanation != null) ...[
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: Text(
                      'Explanation',
                      style: theme.textTheme.titleMedium,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          hadith.explanation!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
