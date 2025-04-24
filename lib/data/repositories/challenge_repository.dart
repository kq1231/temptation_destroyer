import 'dart:developer' as developer;
import 'dart:math';

import '../models/challenge_model.dart';
import '../../objectbox.g.dart';

class ChallengeRepository {
  final Box<ChallengeModel> _challengeBox;
  final Random _random = Random();

  ChallengeRepository(Store store)
      : _challengeBox = store.box<ChallengeModel>();

  // Get all challenges
  List<ChallengeModel> getAllChallenges() {
    try {
      return _challengeBox.getAll();
    } catch (e) {
      developer.log('Error getting all challenges: $e',
          name: 'ChallengeRepository');
      throw Exception('Failed to get challenges: $e');
    }
  }

  // Get challenge by ID
  ChallengeModel? getChallengeById(int id) {
    try {
      return _challengeBox.get(id);
    } catch (e) {
      developer.log('Error getting challenge by ID: $e',
          name: 'ChallengeRepository');
      throw Exception('Failed to get challenge: $e');
    }
  }

  // Save a challenge
  int saveChallenge(ChallengeModel challenge) {
    try {
      return _challengeBox.put(challenge);
    } catch (e) {
      developer.log('Error saving challenge: $e', name: 'ChallengeRepository');
      throw Exception('Failed to save challenge: $e');
    }
  }

  // Delete a challenge
  bool deleteChallenge(int id) {
    try {
      return _challengeBox.remove(id);
    } catch (e) {
      developer.log('Error deleting challenge: $e',
          name: 'ChallengeRepository');
      throw Exception('Failed to delete challenge: $e');
    }
  }

  // Get active challenge for today
  ChallengeModel? getTodayChallenge() {
    try {
      final today = DateTime.now().midnight();

      final query = _challengeBox
          .query(ChallengeModel_.assignedDate.between(
            today.millisecondsSinceEpoch,
            today.add(const Duration(days: 1)).millisecondsSinceEpoch - 1,
          ))
          .build();

      final challenges = query.find();
      query.close();

      return challenges.isNotEmpty ? challenges.first : null;
    } catch (e) {
      developer.log('Error getting today\'s challenge: $e',
          name: 'ChallengeRepository');
      throw Exception('Failed to get today\'s challenge: $e');
    }
  }

  // Get all pending challenges
  List<ChallengeModel> getPendingChallenges() {
    try {
      final query = _challengeBox.query().build();
      final allChallenges = query.find();
      query.close();

      return allChallenges
          .where((c) => c.status == ChallengeStatus.pending)
          .toList();
    } catch (e) {
      developer.log('Error getting pending challenges: $e',
          name: 'ChallengeRepository');
      throw Exception('Failed to get pending challenges: $e');
    }
  }

  // Get all completed challenges
  List<ChallengeModel> getCompletedChallenges() {
    try {
      final query = _challengeBox.query().build();
      final allChallenges = query.find();
      query.close();

      return allChallenges
          .where((c) => c.status == ChallengeStatus.completed)
          .toList();
    } catch (e) {
      developer.log('Error getting completed challenges: $e',
          name: 'ChallengeRepository');
      throw Exception('Failed to get completed challenges: $e');
    }
  }

  // Get challenges by category
  List<ChallengeModel> getChallengesByCategory(String category) {
    try {
      final query = _challengeBox.query().build();
      final allChallenges = query.find();
      query.close();

      return allChallenges.where((c) => c.category == category).toList();
    } catch (e) {
      developer.log('Error getting challenges by category: $e',
          name: 'ChallengeRepository');
      throw Exception('Failed to get challenges by category: $e');
    }
  }

  // Get challenges by difficulty
  List<ChallengeModel> getChallengesByDifficulty(String difficulty) {
    try {
      final query = _challengeBox.query().build();
      final allChallenges = query.find();
      query.close();

      return allChallenges.where((c) => c.difficulty == difficulty).toList();
    } catch (e) {
      developer.log('Error getting challenges by difficulty: $e',
          name: 'ChallengeRepository');
      throw Exception('Failed to get challenges by difficulty: $e');
    }
  }

  // Get challenges by status
  List<ChallengeModel> getChallengesByStatus(String status) {
    try {
      final query = _challengeBox.query().build();
      final allChallenges = query.find();
      query.close();

      return allChallenges.where((c) => c.status == status).toList();
    } catch (e) {
      developer.log('Error getting challenges by status: $e',
          name: 'ChallengeRepository');
      throw Exception('Failed to get challenges by status: $e');
    }
  }

  // Get challenges for a date range
  List<ChallengeModel> getChallengesInDateRange(
      DateTime startDate, DateTime endDate) {
    try {
      final query = _challengeBox
          .query(ChallengeModel_.assignedDate.between(
            startDate.millisecondsSinceEpoch,
            endDate.millisecondsSinceEpoch,
          ))
          .build();

      final challenges = query.find();
      query.close();

      return challenges;
    } catch (e) {
      developer.log('Error getting challenges in date range: $e',
          name: 'ChallengeRepository');
      throw Exception('Failed to get challenges in date range: $e');
    }
  }

  // Create and assign a new daily challenge if none exists for today
  Future<ChallengeModel> createDailyChallenge({
    String difficulty = ChallengeDifficulty.medium,
    String? preferredCategory,
  }) async {
    try {
      // Check if we already have a challenge for today
      final existingChallenge = getTodayChallenge();
      if (existingChallenge != null) {
        return existingChallenge;
      }

      // Choose a category if not specified
      final category = preferredCategory ?? _getRandomCategory();

      // Determine point value based on difficulty
      int pointValue = 10;
      if (difficulty == ChallengeDifficulty.easy) {
        pointValue = 5;
      } else if (difficulty == ChallengeDifficulty.medium) {
        pointValue = 10;
      } else if (difficulty == ChallengeDifficulty.hard) {
        pointValue = 15;
      }

      // Create a default challenge
      final challenge = ChallengeModel(
        title: 'Personal Growth',
        description: 'Spend 20 minutes today on meaningful self-reflection.',
        category: category,
        difficulty: difficulty,
        assignedDate: DateTime.now().midnight(),
        pointValue: pointValue,
        verificationSteps: 'Write down your reflections and insights.',
      );

      // Save the challenge
      final id = saveChallenge(challenge);
      challenge.id = id;

      return challenge;
    } catch (e) {
      developer.log('Error creating daily challenge: $e',
          name: 'ChallengeRepository');
      throw Exception('Failed to create daily challenge: $e');
    }
  }

  // Mark a challenge as completed
  Future<bool> completeChallenge(int id) async {
    try {
      final challenge = getChallengeById(id);
      if (challenge == null) {
        return false;
      }

      challenge.complete();
      saveChallenge(challenge);
      return true;
    } catch (e) {
      developer.log('Error completing challenge: $e',
          name: 'ChallengeRepository');
      throw Exception('Failed to complete challenge: $e');
    }
  }

  // Mark a challenge as failed
  Future<bool> failChallenge(int id) async {
    try {
      final challenge = getChallengeById(id);
      if (challenge == null) {
        return false;
      }

      challenge.fail();
      saveChallenge(challenge);
      return true;
    } catch (e) {
      developer.log('Error failing challenge: $e', name: 'ChallengeRepository');
      throw Exception('Failed to mark challenge as failed: $e');
    }
  }

  // Skip a challenge
  Future<bool> skipChallenge(int id) async {
    try {
      final challenge = getChallengeById(id);
      if (challenge == null) {
        return false;
      }

      challenge.skip();
      saveChallenge(challenge);
      return true;
    } catch (e) {
      developer.log('Error skipping challenge: $e',
          name: 'ChallengeRepository');
      throw Exception('Failed to skip challenge: $e');
    }
  }

  // Reset a challenge to pending
  Future<bool> resetChallenge(int id) async {
    try {
      final challenge = getChallengeById(id);
      if (challenge == null) {
        return false;
      }

      challenge.reset();
      saveChallenge(challenge);
      return true;
    } catch (e) {
      developer.log('Error resetting challenge: $e',
          name: 'ChallengeRepository');
      throw Exception('Failed to reset challenge: $e');
    }
  }

  // Get a random category
  String _getRandomCategory() {
    final categories = ChallengeCategory.values;
    return categories[
        _random.nextInt(categories.length - 1)]; // Exclude 'custom'
  }

  // Get all active challenges (assigned but not completed)
  List<ChallengeModel> getActiveChallenges() {
    try {
      final query = _challengeBox.query().build();
      final allChallenges = query.find();
      query.close();

      // Filter for pending challenges
      return allChallenges
          .where((c) => c.status == ChallengeStatus.pending)
          .toList();
    } catch (e) {
      developer.log('Error getting active challenges: $e',
          name: 'ChallengeRepository');
      throw Exception('Failed to get active challenges: $e');
    }
  }
}

// Extension to get midnight of a date
extension DateTimeExtension on DateTime {
  DateTime midnight() {
    return DateTime(year, month, day);
  }
}
