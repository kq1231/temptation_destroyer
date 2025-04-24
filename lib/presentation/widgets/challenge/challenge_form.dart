import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/challenge_model.dart';
import '../../providers/challenge_providers.dart';

class ChallengeForm extends ConsumerStatefulWidget {
  const ChallengeForm({super.key});

  @override
  ConsumerState<ChallengeForm> createState() => _ChallengeFormState();
}

class _ChallengeFormState extends ConsumerState<ChallengeForm> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _description;
  late int _pointValue;
  late String _verificationSteps;
  String _category = ChallengeCategory.custom;
  String _difficulty = ChallengeDifficulty.medium;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final challenge = ChallengeModel(
        title: _title,
        description: _description,
        category: _category,
        difficulty: _difficulty,
        assignedDate: DateTime.now(),
        pointValue: _pointValue,
        verificationSteps: _verificationSteps,
        isCustom: true,
      );

      // Save challenge using provider
      ref.read(challengeRepositoryProvider).saveChallenge(challenge);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create Custom Challenge',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
              onSaved: (value) => _title = value!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
              onSaved: (value) => _description = value!,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              value: _category,
              items: ChallengeCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.split('.').last),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _category = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Difficulty',
                border: OutlineInputBorder(),
              ),
              value: _difficulty,
              items: ChallengeDifficulty.values.map((difficulty) {
                return DropdownMenuItem(
                  value: difficulty,
                  child: Text(difficulty.split('.').last),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _difficulty = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Point Value',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter point value';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
              onSaved: (value) => _pointValue = int.parse(value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Verification Steps',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter verification steps';
                }
                return null;
              },
              onSaved: (value) => _verificationSteps = value!,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submit,
              child: const Text('Create Challenge'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
