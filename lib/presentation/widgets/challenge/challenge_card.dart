import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/challenge_model.dart';
import '../../providers/challenge_providers.dart';

class ChallengeCard extends ConsumerWidget {
  final ChallengeModel challenge;

  const ChallengeCard({
    super.key,
    required this.challenge,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    challenge.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              challenge.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildCategoryChip(),
                const SizedBox(width: 8),
                _buildDifficultyChip(),
              ],
            ),
            if (!challenge.isCompleted && !challenge.isSkipped) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      ref
                          .read(challengeRepositoryProvider)
                          .skipChallenge(challenge.id);
                    },
                    child: const Text('Skip'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      ref
                          .read(challengeRepositoryProvider)
                          .completeChallenge(challenge.id);
                    },
                    child: const Text('Complete'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color backgroundColor;
    String label;

    if (challenge.isCompleted) {
      backgroundColor = Colors.green;
      label = 'Completed';
    } else if (challenge.isSkipped) {
      backgroundColor = Colors.grey;
      label = 'Skipped';
    } else {
      backgroundColor = Colors.blue;
      label = 'Active';
    }

    return Chip(
      backgroundColor: backgroundColor.withValues(alpha: 0.1),
      side: BorderSide(color: backgroundColor),
      label: Text(
        label,
        style: TextStyle(color: backgroundColor),
      ),
    );
  }

  Widget _buildCategoryChip() {
    return Chip(
      backgroundColor: Colors.purple.withValues(alpha: 0.1),
      side: const BorderSide(color: Colors.purple),
      label: Text(
        challenge.category.toString().split('.').last,
        style: const TextStyle(color: Colors.purple),
      ),
    );
  }

  Widget _buildDifficultyChip() {
    Color color;
    switch (challenge.difficulty) {
      case ChallengeDifficulty.easy:
        color = Colors.green;
        break;
      case ChallengeDifficulty.medium:
        color = Colors.orange;
        break;
      case ChallengeDifficulty.hard:
        color = Colors.red;
        break;
    }

    return Chip(
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color),
      label: Text(
        challenge.difficulty.toString().split('.').last,
        style: TextStyle(color: color),
      ),
    );
  }
}
