import 'dart:developer' as developer;

import '../models/achievement_model.dart';
import '../../objectbox.g.dart';

class AchievementRepository {
  final Box<AchievementModel> _achievementBox;

  AchievementRepository(Store store)
      : _achievementBox = store.box<AchievementModel>();

  // Get all achievements
  List<AchievementModel> getAllAchievements() {
    try {
      return _achievementBox.getAll();
    } catch (e) {
      developer.log('Error getting all achievements: $e',
          name: 'AchievementRepository');
      throw Exception('Failed to get achievements: $e');
    }
  }

  // Get achievement by ID
  AchievementModel? getAchievementById(int id) {
    try {
      return _achievementBox.get(id);
    } catch (e) {
      developer.log('Error getting achievement by ID: $e',
          name: 'AchievementRepository');
      throw Exception('Failed to get achievement: $e');
    }
  }

  // Save achievement
  int saveAchievement(AchievementModel achievement) {
    try {
      return _achievementBox.put(achievement);
    } catch (e) {
      developer.log('Error saving achievement: $e',
          name: 'AchievementRepository');
      throw Exception('Failed to save achievement: $e');
    }
  }

  // Delete achievement
  bool deleteAchievement(int id) {
    try {
      return _achievementBox.remove(id);
    } catch (e) {
      developer.log('Error deleting achievement: $e',
          name: 'AchievementRepository');
      throw Exception('Failed to delete achievement: $e');
    }
  }

  // Get unlocked achievements
  List<AchievementModel> getUnlockedAchievements() {
    try {
      final query = _achievementBox
          .query(AchievementModel_.isUnlocked.equals(true))
          .build();

      final achievements = query.find();
      query.close();

      return achievements;
    } catch (e) {
      developer.log('Error getting unlocked achievements: $e',
          name: 'AchievementRepository');
      throw Exception('Failed to get unlocked achievements: $e');
    }
  }

  // Get locked achievements
  List<AchievementModel> getLockedAchievements() {
    try {
      final query = _achievementBox
          .query(AchievementModel_.isUnlocked.equals(false))
          .build();

      final achievements = query.find();
      query.close();

      return achievements;
    } catch (e) {
      developer.log('Error getting locked achievements: $e',
          name: 'AchievementRepository');
      throw Exception('Failed to get locked achievements: $e');
    }
  }

  // Get achievements by type
  List<AchievementModel> getAchievementsByType(String type) {
    try {
      final query =
          _achievementBox.query(AchievementModel_.type.equals(type)).build();

      final achievements = query.find();
      query.close();

      return achievements;
    } catch (e) {
      developer.log('Error getting achievements by type: $e',
          name: 'AchievementRepository');
      throw Exception('Failed to get achievements by type: $e');
    }
  }

  // Get achievements by rarity
  List<AchievementModel> getAchievementsByRarity(String rarity) {
    try {
      final query = _achievementBox
          .query(AchievementModel_.rarity.equals(rarity))
          .build();

      final achievements = query.find();
      query.close();

      return achievements;
    } catch (e) {
      developer.log('Error getting achievements by rarity: $e',
          name: 'AchievementRepository');
      throw Exception('Failed to get achievements by rarity: $e');
    }
  }

  // Update achievement progress
  Future<bool> updateAchievementProgress(int id, int newProgress) async {
    try {
      final achievement = getAchievementById(id);
      if (achievement == null) {
        return false;
      }

      final wasUnlocked = achievement.updateProgress(newProgress);
      saveAchievement(achievement);

      return wasUnlocked;
    } catch (e) {
      developer.log('Error updating achievement progress: $e',
          name: 'AchievementRepository');
      throw Exception('Failed to update achievement progress: $e');
    }
  }

  // Increment achievement progress by one
  Future<bool> incrementAchievementProgress(int id) async {
    try {
      final achievement = getAchievementById(id);
      if (achievement == null) {
        return false;
      }

      final wasUnlocked = achievement.incrementProgress();
      saveAchievement(achievement);

      return wasUnlocked;
    } catch (e) {
      developer.log('Error incrementing achievement progress: $e',
          name: 'AchievementRepository');
      throw Exception('Failed to increment achievement progress: $e');
    }
  }

  // Get total achievement points
  int getTotalAchievementPoints() {
    try {
      final unlockedAchievements = getUnlockedAchievements();
      return unlockedAchievements.fold(
          0, (sum, achievement) => sum + achievement.pointValue);
    } catch (e) {
      developer.log('Error getting total achievement points: $e',
          name: 'AchievementRepository');
      throw Exception('Failed to get total achievement points: $e');
    }
  }

  // Get recently unlocked achievements (in the last 7 days)
  List<AchievementModel> getRecentlyUnlockedAchievements() {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final query = _achievementBox
          .query(AchievementModel_.isUnlocked.equals(true).and(AchievementModel_
              .unlockedDate
              .greaterThan(sevenDaysAgo.millisecondsSinceEpoch)))
          .build();

      final achievements = query.find();
      query.close();

      return achievements;
    } catch (e) {
      developer.log('Error getting recently unlocked achievements: $e',
          name: 'AchievementRepository');
      throw Exception('Failed to get recently unlocked achievements: $e');
    }
  }

  // Get next achievements close to unlocking (>50% progress)
  List<AchievementModel> getNextAchievements() {
    try {
      final lockedAchievements = getLockedAchievements();

      // Filter achievements with more than 50% progress
      return lockedAchievements
          .where((achievement) => achievement.progressPercentage > 0.5)
          .toList()
        // Sort by progress percentage (highest first)
        ..sort((a, b) => b.progressPercentage.compareTo(a.progressPercentage));
    } catch (e) {
      developer.log('Error getting next achievements: $e',
          name: 'AchievementRepository');
      throw Exception('Failed to get next achievements: $e');
    }
  }

  // Initialize default achievements
  Future<void> initializeDefaultAchievements() async {
    try {
      // Check if we already have achievements
      final existingAchievements = getAllAchievements();
      if (existingAchievements.isNotEmpty) {
        return;
      }

      // Streak achievements
      final streakAchievements = [
        AchievementModel.createStreakAchievement(
          title: 'First Step',
          description: 'Maintain a 3-day streak',
          iconName: 'streak_3',
          daysRequired: 3,
          pointValue: 10,
          rarity: AchievementRarity.common,
        ),
        AchievementModel.createStreakAchievement(
          title: 'One Week Strong',
          description: 'Maintain a 7-day streak',
          iconName: 'streak_7',
          daysRequired: 7,
          pointValue: 20,
          rarity: AchievementRarity.common,
        ),
        AchievementModel.createStreakAchievement(
          title: 'Fortnight Freedom',
          description: 'Maintain a 14-day streak',
          iconName: 'streak_14',
          daysRequired: 14,
          pointValue: 30,
          rarity: AchievementRarity.uncommon,
        ),
        AchievementModel.createStreakAchievement(
          title: 'Monthly Master',
          description: 'Maintain a 30-day streak',
          iconName: 'streak_30',
          daysRequired: 30,
          pointValue: 50,
          rarity: AchievementRarity.rare,
        ),
        AchievementModel.createStreakAchievement(
          title: 'Quarter Champion',
          description: 'Maintain a 90-day streak',
          iconName: 'streak_90',
          daysRequired: 90,
          pointValue: 100,
          rarity: AchievementRarity.epic,
        ),
        AchievementModel.createStreakAchievement(
          title: 'Half-Year Hero',
          description: 'Maintain a 180-day streak',
          iconName: 'streak_180',
          daysRequired: 180,
          pointValue: 200,
          rarity: AchievementRarity.legendary,
        ),
        AchievementModel.createStreakAchievement(
          title: 'Annual Achiever',
          description: 'Maintain a 365-day streak',
          iconName: 'streak_365',
          daysRequired: 365,
          pointValue: 500,
          rarity: AchievementRarity.legendary,
        ),
      ];

      // Emergency achievements
      final emergencyAchievements = [
        AchievementModel.createEmergencyAchievement(
          title: 'First Victory',
          description: 'Successfully overcome your first emergency',
          iconName: 'emergency_1',
          emergenciesResolved: 1,
          pointValue: 15,
          rarity: AchievementRarity.common,
        ),
        AchievementModel.createEmergencyAchievement(
          title: 'Five Times Fighter',
          description: 'Successfully overcome 5 emergencies',
          iconName: 'emergency_5',
          emergenciesResolved: 5,
          pointValue: 30,
          rarity: AchievementRarity.uncommon,
        ),
        AchievementModel.createEmergencyAchievement(
          title: 'Double Digit Defender',
          description: 'Successfully overcome 10 emergencies',
          iconName: 'emergency_10',
          emergenciesResolved: 10,
          pointValue: 50,
          rarity: AchievementRarity.rare,
        ),
        AchievementModel.createEmergencyAchievement(
          title: 'Quarter Century Champion',
          description: 'Successfully overcome 25 emergencies',
          iconName: 'emergency_25',
          emergenciesResolved: 25,
          pointValue: 100,
          rarity: AchievementRarity.epic,
        ),
        AchievementModel.createEmergencyAchievement(
          title: 'Half Century Hero',
          description: 'Successfully overcome 50 emergencies',
          iconName: 'emergency_50',
          emergenciesResolved: 50,
          pointValue: 150,
          rarity: AchievementRarity.legendary,
        ),
      ];

      // Challenge achievements
      final challengeAchievements = [
        AchievementModel.createChallengeAchievement(
          title: 'Challenge Accepted',
          description: 'Complete your first daily challenge',
          iconName: 'challenge_1',
          challengesCompleted: 1,
          pointValue: 10,
          rarity: AchievementRarity.common,
        ),
        AchievementModel.createChallengeAchievement(
          title: 'Challenge Enthusiast',
          description: 'Complete 5 daily challenges',
          iconName: 'challenge_5',
          challengesCompleted: 5,
          pointValue: 25,
          rarity: AchievementRarity.common,
        ),
        AchievementModel.createChallengeAchievement(
          title: 'Challenge Conqueror',
          description: 'Complete 10 daily challenges',
          iconName: 'challenge_10',
          challengesCompleted: 10,
          pointValue: 50,
          rarity: AchievementRarity.uncommon,
        ),
        AchievementModel.createChallengeAchievement(
          title: 'Challenge Master',
          description: 'Complete 25 daily challenges',
          iconName: 'challenge_25',
          challengesCompleted: 25,
          pointValue: 75,
          rarity: AchievementRarity.rare,
        ),
        AchievementModel.createChallengeAchievement(
          title: 'Challenge Champion',
          description: 'Complete 50 daily challenges',
          iconName: 'challenge_50',
          challengesCompleted: 50,
          pointValue: 100,
          rarity: AchievementRarity.epic,
        ),
        AchievementModel.createChallengeAchievement(
          title: 'Challenge Legend',
          description: 'Complete 100 daily challenges',
          iconName: 'challenge_100',
          challengesCompleted: 100,
          pointValue: 200,
          rarity: AchievementRarity.legendary,
        ),
      ];

      // Other achievements
      final otherAchievements = [
        AchievementModel(
          title: 'Knowledge Seeker',
          description: 'Read 10 Islamic content items',
          iconName: 'knowledge_10',
          pointValue: 20,
          type: AchievementType.knowledge,
          rarity: AchievementRarity.common,
          progressTarget: 10,
        ),
        AchievementModel(
          title: 'Prayer Warrior',
          description: 'Record 30 on-time prayers',
          iconName: 'prayer_30',
          pointValue: 30,
          type: AchievementType.prayer,
          rarity: AchievementRarity.uncommon,
          progressTarget: 30,
        ),
        AchievementModel(
          title: 'Quran Companion',
          description: 'Read Quran for 10 days in a row',
          iconName: 'quran_10',
          pointValue: 40,
          type: AchievementType.quran,
          rarity: AchievementRarity.rare,
          progressTarget: 10,
        ),
        AchievementModel(
          title: 'Community Builder',
          description: 'Participate in 5 community events',
          iconName: 'community_5',
          pointValue: 30,
          type: AchievementType.community,
          rarity: AchievementRarity.uncommon,
          progressTarget: 5,
        ),
        AchievementModel(
          title: 'All-Rounder',
          description: 'Complete at least one challenge from each category',
          iconName: 'allrounder',
          pointValue: 50,
          type: AchievementType.general,
          rarity: AchievementRarity.rare,
          progressTarget: 8,
        ),
      ];

      // Save all the achievements
      final allAchievements = [
        ...streakAchievements,
        ...emergencyAchievements,
        ...challengeAchievements,
        ...otherAchievements,
      ];

      for (final achievement in allAchievements) {
        saveAchievement(achievement);
      }

      developer.log('Initialized default achievements',
          name: 'AchievementRepository');
    } catch (e) {
      developer.log('Error initializing default achievements: $e',
          name: 'AchievementRepository');
      throw Exception('Failed to initialize default achievements: $e');
    }
  }
}
