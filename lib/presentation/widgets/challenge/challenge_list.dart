import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/challenge_providers.dart';
import 'challenge_card.dart';

class ChallengeList extends ConsumerWidget {
  const ChallengeList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(activeChallengesProvider);

    return challengesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (challenges) {
        if (challenges.isEmpty) {
          return const Center(
            child: Text('No challenges yet. Create one to get started!'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            final challenge = challenges[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ChallengeCard(challenge: challenge),
            );
          },
        );
      },
    );
  }
}
