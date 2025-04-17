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
      final query = _challengeBox
          .query(ChallengeModel_.dbStatus.equals(ChallengeStatus.pending.index))
          .build();

      final challenges = query.find();
      query.close();

      return challenges;
    } catch (e) {
      developer.log('Error getting pending challenges: $e',
          name: 'ChallengeRepository');
      throw Exception('Failed to get pending challenges: $e');
    }
  }

  // Get all completed challenges
  List<ChallengeModel> getCompletedChallenges() {
    try {
      final query = _challengeBox
          .query(
              ChallengeModel_.dbStatus.equals(ChallengeStatus.completed.index))
          .build();

      final challenges = query.find();
      query.close();

      return challenges;
    } catch (e) {
      developer.log('Error getting completed challenges: $e',
          name: 'ChallengeRepository');
      throw Exception('Failed to get completed challenges: $e');
    }
  }

  // Get challenges by category
  List<ChallengeModel> getChallengesByCategory(ChallengeCategory category) {
    try {
      final query = _challengeBox
          .query(ChallengeModel_.dbCategory.equals(category.index))
          .build();

      final challenges = query.find();
      query.close();

      return challenges;
    } catch (e) {
      developer.log('Error getting challenges by category: $e',
          name: 'ChallengeRepository');
      throw Exception('Failed to get challenges by category: $e');
    }
  }

  // Get challenges by difficulty
  List<ChallengeModel> getChallengesByDifficulty(
      ChallengeDifficulty difficulty) {
    try {
      final query = _challengeBox
          .query(ChallengeModel_.dbDifficulty.equals(difficulty.index))
          .build();

      final challenges = query.find();
      query.close();

      return challenges;
    } catch (e) {
      developer.log('Error getting challenges by difficulty: $e',
          name: 'ChallengeRepository');
      throw Exception('Failed to get challenges by difficulty: $e');
    }
  }

  // Get challenges by status
  List<ChallengeModel> getChallengesByStatus(ChallengeStatus status) {
    try {
      final query = _challengeBox
          .query(ChallengeModel_.dbStatus.equals(status.index))
          .build();

      final challenges = query.find();
      query.close();

      return challenges;
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
    ChallengeDifficulty difficulty = ChallengeDifficulty.medium,
    ChallengeCategory? preferredCategory,
  }) async {
    try {
      // Check if we already have a challenge for today
      final existingChallenge = getTodayChallenge();
      if (existingChallenge != null) {
        return existingChallenge;
      }

      // Choose a category if not specified
      final category = preferredCategory ?? _getRandomCategory();

      // Create a challenge based on category and difficulty
      final challenge = _createChallengeForCategory(category, difficulty);
      challenge.assignedDate = DateTime.now().midnight();

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
  ChallengeCategory _getRandomCategory() {
    final categories = ChallengeCategory.values;
    return categories[
        _random.nextInt(categories.length - 1)]; // Exclude 'custom'
  }

  // Create a challenge based on category and difficulty
  ChallengeModel _createChallengeForCategory(
    ChallengeCategory category,
    ChallengeDifficulty difficulty,
  ) {
    // Points based on difficulty
    final points = switch (difficulty) {
      ChallengeDifficulty.easy => 5,
      ChallengeDifficulty.medium => 10,
      ChallengeDifficulty.hard => 15,
    };

    // Create different challenges based on category
    switch (category) {
      case ChallengeCategory.prayer:
        return _createPrayerChallenge(difficulty, points);
      case ChallengeCategory.quran:
        return _createQuranChallenge(difficulty, points);
      case ChallengeCategory.dhikr:
        return _createDhikrChallenge(difficulty, points);
      case ChallengeCategory.selfImprovement:
        return _createSelfImprovementChallenge(difficulty, points);
      case ChallengeCategory.charity:
        return _createCharityChallenge(difficulty, points);
      case ChallengeCategory.knowledge:
        return _createKnowledgeChallenge(difficulty, points);
      case ChallengeCategory.social:
        return _createSocialChallenge(difficulty, points);
      case ChallengeCategory.physical:
        return _createPhysicalChallenge(difficulty, points);
      default:
        return _createDefaultChallenge(difficulty, points);
    }
  }

  // Create prayer-related challenges
  ChallengeModel _createPrayerChallenge(
      ChallengeDifficulty difficulty, int points) {
    return switch (difficulty) {
      ChallengeDifficulty.easy => ChallengeModel(
          title: 'On-Time Salah',
          description:
              'Pray at least 3 of your daily prayers exactly on time today.',
          category: ChallengeCategory.prayer,
          difficulty: difficulty,
          assignedDate: DateTime.now(),
          pointValue: points,
          verificationSteps: 'Mark each prayer you completed on time.',
        ),
      ChallengeDifficulty.medium => ChallengeModel(
          title: 'Extended Prayer',
          description:
              'Add an extra sunnah prayer to each of your obligatory prayers today.',
          category: ChallengeCategory.prayer,
          difficulty: difficulty,
          assignedDate: DateTime.now(),
          pointValue: points,
          verificationSteps:
              'Complete the challenge if you managed to pray all sunnah prayers.',
        ),
      ChallengeDifficulty.hard => ChallengeModel(
          title: 'Night Prayer',
          description:
              'Wake up for Tahajjud prayer tonight and pray for at least 15 minutes.',
          category: ChallengeCategory.prayer,
          difficulty: difficulty,
          assignedDate: DateTime.now(),
          pointValue: points,
          verificationSteps:
              'Set an alarm, wake up, and track your prayer time.',
        ),
    };
  }

  // Create Quran-related challenges
  ChallengeModel _createQuranChallenge(
      ChallengeDifficulty difficulty, int points) {
    return switch (difficulty) {
      ChallengeDifficulty.easy => ChallengeModel(
          title: 'Daily Quran',
          description:
              'Read at least 1 page of the Quran today with understanding.',
          category: ChallengeCategory.quran,
          difficulty: difficulty,
          assignedDate: DateTime.now(),
          pointValue: points,
          verificationSteps:
              'Track which page you read and one thing you learned.',
        ),
      ChallengeDifficulty.medium => ChallengeModel(
          title: 'Surah Memorization',
          description:
              'Memorize a short surah or three verses from the Quran today.',
          category: ChallengeCategory.quran,
          difficulty: difficulty,
          assignedDate: DateTime.now(),
          pointValue: points,
          verificationSteps: 'Write down which verses you memorized.',
        ),
      ChallengeDifficulty.hard => ChallengeModel(
          title: 'Quran Reflection',
          description: 'Read Surah Yusuf and reflect on 3 lessons learned.',
          category: ChallengeCategory.quran,
          difficulty: difficulty,
          assignedDate: DateTime.now(),
          pointValue: points,
          verificationSteps: 'Write down 3 key insights from your reading.',
        ),
    };
  }

  // Create dhikr-related challenges
  ChallengeModel _createDhikrChallenge(
      ChallengeDifficulty difficulty, int points) {
    return switch (difficulty) {
      ChallengeDifficulty.easy => ChallengeModel(
          title: 'Morning Adhkar',
          description: 'Recite the morning adhkar after Fajr prayer.',
          category: ChallengeCategory.dhikr,
          difficulty: difficulty,
          assignedDate: DateTime.now(),
          pointValue: points,
          verificationSteps: 'Check off after completing the morning adhkar.',
        ),
      ChallengeDifficulty.medium => ChallengeModel(
          title: 'Istighfar 100x',
          description:
              'Recite "Astaghfirullah" (I seek forgiveness from Allah) 100 times today.',
          category: ChallengeCategory.dhikr,
          difficulty: difficulty,
          assignedDate: DateTime.now(),
          pointValue: points,
          verificationSteps: 'Use a counter or tasbeeh to keep track.',
        ),
      ChallengeDifficulty.hard => ChallengeModel(
          title: 'Constant Remembrance',
          description: 'Maintain dhikr for 30 minutes continuously today.',
          category: ChallengeCategory.dhikr,
          difficulty: difficulty,
          assignedDate: DateTime.now(),
          pointValue: points,
          verificationSteps:
              'Set a timer and focus on remembrance of Allah for 30 minutes.',
        ),
    };
  }

  // Create self-improvement challenges
  ChallengeModel _createSelfImprovementChallenge(
      ChallengeDifficulty difficulty, int points) {
    return switch (difficulty) {
      ChallengeDifficulty.easy => ChallengeModel(
          title: 'Positive Thinking',
          description: 'Write down 3 things you\'re grateful for today.',
          category: ChallengeCategory.selfImprovement,
          difficulty: difficulty,
          assignedDate: DateTime.now(),
          pointValue: points,
          verificationSteps: 'List your 3 items of gratitude.',
        ),
      ChallengeDifficulty.medium => ChallengeModel(
          title: 'Habit Breaking',
          description:
              'Identify a bad habit and make a concrete plan to change it.',
          category: ChallengeCategory.selfImprovement,
          difficulty: difficulty,
          assignedDate: DateTime.now(),
          pointValue: points,
          verificationSteps: 'Document the habit and your action plan.',
        ),
      ChallengeDifficulty.hard => ChallengeModel(
          title: 'Digital Detox',
          description:
              'Stay away from all non-essential technology for 6 hours today.',
          category: ChallengeCategory.selfImprovement,
          difficulty: difficulty,
          assignedDate: DateTime.now(),
          pointValue: points,
          verificationSteps:
              'Track your start and end time, and what you did instead.',
        ),
    };
  }

  // Create charity-related challenges
  ChallengeModel _createCharityChallenge(
      ChallengeDifficulty difficulty, int points) {
    return switch (difficulty) {
      ChallengeDifficulty.easy => ChallengeModel(
          title: 'Kind Words',
          description: 'Give a sincere compliment to 3 different people today.',
          category: ChallengeCategory.charity,
          difficulty: difficulty,
          assignedDate: DateTime.now(),
          pointValue: points,
          verificationSteps:
              'Note down who you complimented and their reaction.',
        ),
      ChallengeDifficulty.medium => ChallengeModel(
          title: 'Secret Charity',
          description:
              'Do an act of charity today without anyone knowing it was you.',
          category: ChallengeCategory.charity,
          difficulty: difficulty,
          assignedDate: DateTime.now(),
          pointValue: points,
          verificationSteps:
              'Record what you did without revealing specifics that could identify you.',
        ),
      ChallengeDifficulty.hard => ChallengeModel(
          title: 'Community Service',
          description:
              'Volunteer for at least 2 hours at a local charity or community service.',
          category: ChallengeCategory.charity,
          difficulty: difficulty,
          assignedDate: DateTime.now(),
          pointValue: points,
          verificationSteps: 'Document where you volunteered and what you did.',
        ),
    };
  }

  // Create knowledge-related challenges
  ChallengeModel _createKnowledgeChallenge(
      ChallengeDifficulty difficulty, int points) {
    return switch (difficulty) {
      ChallengeDifficulty.easy => ChallengeModel(
          title: 'Islamic Learning',
          description: 'Learn the meaning of 5 new Islamic terms or concepts.',
          category: ChallengeCategory.knowledge,
          difficulty: difficulty,
          assignedDate: DateTime.now(),
          pointValue: points,
          verificationSteps: 'List the terms/concepts and their meanings.',
        ),
      ChallengeDifficulty.medium => ChallengeModel(
          title: 'Hadith Study',
          description:
              'Study a hadith with its explanation and how to apply it today.',
          category: ChallengeCategory.knowledge,
          difficulty: difficulty,
          assignedDate: DateTime.now(),
          pointValue: points,
          verificationSteps:
              'Write down the hadith and how you can apply it in your life.',
        ),
      ChallengeDifficulty.hard => ChallengeModel(
          title: 'Islamic Book',
          description:
              'Read one chapter from an Islamic book on self-improvement.',
          category: ChallengeCategory.knowledge,
          difficulty: difficulty,
          assignedDate: DateTime.now(),
          pointValue: points,
          verificationSteps:
              'Share the book title, chapter, and key insights gained.',
        ),
    };
  }

  // Create social challenges
  ChallengeModel _createSocialChallenge(
      ChallengeDifficulty difficulty, int points) {
    return switch (difficulty) {
      ChallengeDifficulty.easy => ChallengeModel(
          title: 'Family Connection',
          description:
              'Have a meaningful conversation with a family member today.',
          category: ChallengeCategory.social,
          difficulty: difficulty,
          assignedDate: DateTime.now(),
          pointValue: points,
          verificationSteps: 'Note who you talked with and what you discussed.',
        ),
      ChallengeDifficulty.medium => ChallengeModel(
          title: 'Reconciliation',
          description: 'Reach out to someone you\'ve had a disagreement with.',
          category: ChallengeCategory.social,
          difficulty: difficulty,
          assignedDate: DateTime.now(),
          pointValue: points,
          verificationSteps: 'Document how you reached out and the outcome.',
        ),
      ChallengeDifficulty.hard => ChallengeModel(
          title: 'Community Engagement',
          description:
              'Attend an Islamic event or gathering at a local masjid.',
          category: ChallengeCategory.social,
          difficulty: difficulty,
          assignedDate: DateTime.now(),
          pointValue: points,
          verificationSteps:
              'Share what event you attended and what you learned.',
        ),
    };
  }

  // Create physical well-being challenges
  ChallengeModel _createPhysicalChallenge(
      ChallengeDifficulty difficulty, int points) {
    return switch (difficulty) {
      ChallengeDifficulty.easy => ChallengeModel(
          title: 'Healthy Day',
          description: 'Drink 8 glasses of water and avoid junk food all day.',
          category: ChallengeCategory.physical,
          difficulty: difficulty,
          assignedDate: DateTime.now(),
          pointValue: points,
          verificationSteps:
              'Track your water intake and food choices throughout the day.',
        ),
      ChallengeDifficulty.medium => ChallengeModel(
          title: 'Exercise Session',
          description: 'Complete a 30-minute workout or physical activity.',
          category: ChallengeCategory.physical,
          difficulty: difficulty,
          assignedDate: DateTime.now(),
          pointValue: points,
          verificationSteps: 'Record what exercise you did and for how long.',
        ),
      ChallengeDifficulty.hard => ChallengeModel(
          title: 'Fasting Day',
          description: 'Fast today following the Sunnah (if not in Ramadan).',
          category: ChallengeCategory.physical,
          difficulty: difficulty,
          assignedDate: DateTime.now(),
          pointValue: points,
          verificationSteps:
              'Document your fasting experience and reflections.',
        ),
    };
  }

  // Default challenge if category selection fails
  ChallengeModel _createDefaultChallenge(
      ChallengeDifficulty difficulty, int points) {
    return ChallengeModel(
      title: 'Personal Growth',
      description: 'Spend 20 minutes today on meaningful self-reflection.',
      category: ChallengeCategory.selfImprovement,
      difficulty: difficulty,
      assignedDate: DateTime.now(),
      pointValue: points,
      verificationSteps: 'Write down your reflections and insights.',
    );
  }

  // Get all active challenges (assigned but not completed)
  List<ChallengeModel> getActiveChallenges() {
    try {
      final query = _challengeBox
          .query(ChallengeModel_.dbStatus.equals(ChallengeStatus.pending.index))
          .build();

      final challenges = query.find();
      query.close();

      return challenges;
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
