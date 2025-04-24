import 'dart:developer' as developer;
import 'dart:math';

import '../models/islamic_content_model.dart';
import '../../objectbox.g.dart';

class IslamicContentRepository {
  final Box<IslamicContentModel> _contentBox;
  final Random _random = Random();

  IslamicContentRepository(Store store)
      : _contentBox = store.box<IslamicContentModel>();

  // Get all content items
  List<IslamicContentModel> getAllContent() {
    try {
      return _contentBox.getAll();
    } catch (e) {
      developer.log('Error getting all content: $e',
          name: 'IslamicContentRepository');
      throw Exception('Failed to get content: $e');
    }
  }

  // Get content by ID
  IslamicContentModel? getContentById(int id) {
    try {
      return _contentBox.get(id);
    } catch (e) {
      developer.log('Error getting content by ID: $e',
          name: 'IslamicContentRepository');
      throw Exception('Failed to get content: $e');
    }
  }

  // Save content
  int saveContent(IslamicContentModel content) {
    try {
      return _contentBox.put(content);
    } catch (e) {
      developer.log('Error saving content: $e',
          name: 'IslamicContentRepository');
      throw Exception('Failed to save content: $e');
    }
  }

  // Delete content
  bool deleteContent(int id) {
    try {
      return _contentBox.remove(id);
    } catch (e) {
      developer.log('Error deleting content: $e',
          name: 'IslamicContentRepository');
      throw Exception('Failed to delete content: $e');
    }
  }

  // Get content by type
  List<IslamicContentModel> getContentByType(String type) {
    try {
      final query = _contentBox
          .query(IslamicContentModel_.contentType.equals(type))
          .build();

      final content = query.find();
      query.close();

      return content;
    } catch (e) {
      developer.log('Error getting content by type: $e',
          name: 'IslamicContentRepository');
      throw Exception('Failed to get content by type: $e');
    }
  }

  // Get content by category
  List<IslamicContentModel> getContentByCategory(String category) {
    try {
      final query = _contentBox
          .query(IslamicContentModel_.category.equals(category))
          .build();

      final content = query.find();
      query.close();

      return content;
    } catch (e) {
      developer.log('Error getting content by category: $e',
          name: 'IslamicContentRepository');
      throw Exception('Failed to get content by category: $e');
    }
  }

  // Get content by type and category
  List<IslamicContentModel> getContentByTypeAndCategory(
      String type, String category) {
    try {
      final query = _contentBox
          .query(IslamicContentModel_.contentType
              .equals(type)
              .and(IslamicContentModel_.category.equals(category)))
          .build();

      final content = query.find();
      query.close();

      return content;
    } catch (e) {
      developer.log('Error getting content by type and category: $e',
          name: 'IslamicContentRepository');
      throw Exception('Failed to get content by type and category: $e');
    }
  }

  // Get favorite content
  List<IslamicContentModel> getFavoriteContent() {
    try {
      final query = _contentBox
          .query(IslamicContentModel_.isFavorite.equals(true))
          .build();

      final content = query.find();
      query.close();

      return content;
    } catch (e) {
      developer.log('Error getting favorite content: $e',
          name: 'IslamicContentRepository');
      throw Exception('Failed to get favorite content: $e');
    }
  }

  // Search content
  List<IslamicContentModel> searchContent(String searchTerm) {
    try {
      // Case-insensitive search in content and translation fields
      final contentQuery = _contentBox
          .query(IslamicContentModel_.content
              .contains(searchTerm, caseSensitive: false)
              .or(IslamicContentModel_.translation
                  .contains(searchTerm, caseSensitive: false))
              .or(IslamicContentModel_.explanation
                  .contains(searchTerm, caseSensitive: false))
              .or(IslamicContentModel_.tags
                  .contains(searchTerm, caseSensitive: false)))
          .build();

      final content = contentQuery.find();
      contentQuery.close();

      return content;
    } catch (e) {
      developer.log('Error searching content: $e',
          name: 'IslamicContentRepository');
      throw Exception('Failed to search content: $e');
    }
  }

  // Get content by tags
  List<IslamicContentModel> getContentByTag(String tag) {
    try {
      final query = _contentBox
          .query(IslamicContentModel_.tags.contains(tag, caseSensitive: false))
          .build();

      final content = query.find();
      query.close();

      return content;
    } catch (e) {
      developer.log('Error getting content by tag: $e',
          name: 'IslamicContentRepository');
      throw Exception('Failed to get content by tag: $e');
    }
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(int id) async {
    try {
      final content = getContentById(id);
      if (content == null) {
        return false;
      }

      content.toggleFavorite();
      saveContent(content);
      return true;
    } catch (e) {
      developer.log('Error toggling favorite: $e',
          name: 'IslamicContentRepository');
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  // Get daily content
  IslamicContentModel getDailyContent({String? type, String? category}) {
    try {
      List<IslamicContentModel> candidates;

      // Filter by type and/or category if provided
      if (type != null && category != null) {
        candidates = getContentByTypeAndCategory(type, category);
      } else if (type != null) {
        candidates = getContentByType(type);
      } else if (category != null) {
        candidates = getContentByCategory(category);
      } else {
        candidates = getAllContent();
      }

      if (candidates.isEmpty) {
        // If no content is found, create a default item
        return _createDefaultContent();
      }

      // Sort by last displayed (oldest first) and display count (lowest first)
      candidates.sort((a, b) {
        // If neither has been displayed, sort by id to ensure consistent results
        if (a.lastDisplayed == null && b.lastDisplayed == null) {
          return a.id.compareTo(b.id);
        }

        // Items never displayed take priority
        if (a.lastDisplayed == null) return -1;
        if (b.lastDisplayed == null) return 1;

        // Then sort by date (oldest displayed first)
        final dateCompare = a.lastDisplayed!.compareTo(b.lastDisplayed!);
        if (dateCompare != 0) return dateCompare;

        // Finally, sort by display count (least displayed first)
        return a.displayCount.compareTo(b.displayCount);
      });

      // Get the first item (least recently displayed)
      final selectedContent = candidates.first;

      // Update display tracking
      selectedContent.markDisplayed();
      saveContent(selectedContent);

      return selectedContent;
    } catch (e) {
      developer.log('Error getting daily content: $e',
          name: 'IslamicContentRepository');

      // Return a default item in case of error
      return _createDefaultContent();
    }
  }

  // Get random content
  IslamicContentModel getRandomContent({String? type, String? category}) {
    try {
      List<IslamicContentModel> candidates;

      // Filter by type and/or category if provided
      if (type != null && category != null) {
        candidates = getContentByTypeAndCategory(type, category);
      } else if (type != null) {
        candidates = getContentByType(type);
      } else if (category != null) {
        candidates = getContentByCategory(category);
      } else {
        candidates = getAllContent();
      }

      if (candidates.isEmpty) {
        // If no content is found, create a default item
        return _createDefaultContent();
      }

      // Select a random item
      final selectedContent = candidates[_random.nextInt(candidates.length)];

      // Update display tracking
      selectedContent.markDisplayed();
      saveContent(selectedContent);

      return selectedContent;
    } catch (e) {
      developer.log('Error getting random content: $e',
          name: 'IslamicContentRepository');

      // Return a default item in case of error
      return _createDefaultContent();
    }
  }

  // Create default content (fallback)
  IslamicContentModel _createDefaultContent() {
    return IslamicContentModel(
      content:
          "Whoever wants to purify his heart, then let him prefer Allah to his desires.",
      source: "Ibn al-Qayyim",
      reference: "al-Fawaid",
      translation:
          "Whoever wants to purify his heart, then let him prefer Allah to his desires.",
      contentType: ContentType.quote,
      category: ContentCategory.purification,
      tags: "heart,purification,desires",
    );
  }

  // Initialize with default content
  Future<void> initializeDefaultContent() async {
    try {
      // Check if we already have content
      final existingContent = getAllContent();
      if (existingContent.isNotEmpty) {
        return;
      }

      // Add default hadiths
      final hadiths = [
        IslamicContentModel.createHadith(
          content:
              "لَا يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لِأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ",
          source: "Sahih al-Bukhari",
          reference: "13",
          translation:
              "None of you will have faith until he loves for his brother what he loves for himself.",
          category: ContentCategory.general,
          tags: ["faith", "brotherhood", "love"],
        ),
        IslamicContentModel.createHadith(
          content: "الطُّهُورُ شَطْرُ الْإِيمَانِ",
          source: "Sahih Muslim",
          reference: "223",
          translation: "Cleanliness is half of faith.",
          category: ContentCategory.purification,
          tags: ["cleanliness", "faith", "purity"],
        ),
        IslamicContentModel.createHadith(
          content:
              "مَنْ حَافَظَ عَلَى أَرْبَعٍ قَبْلَ الظُّهْرِ وَأَرْبَعٍ بَعْدَهَا حَرَّمَهُ اللَّهُ عَلَى النَّارِ",
          source: "Sunan al-Tirmidhi",
          reference: "428",
          translation:
              "Whoever consistently performs four rakahs before Dhuhr prayer and four after it, Allah will forbid him from the Hellfire.",
          category: ContentCategory.discipline,
          tags: ["prayer", "consistency", "discipline"],
        ),
        IslamicContentModel.createHadith(
          content:
              "بِحَسْبِ امْرِئٍ مِنَ الشَّرِّ أَنْ يَحْقِرَ أَخَاهُ الْمُسْلِمَ",
          source: "Sahih Muslim",
          reference: "2564",
          translation:
              "It is enough evil for a person to look down upon his Muslim brother.",
          category: ContentCategory.forgiveness,
          tags: ["brotherhood", "humility", "respect"],
        ),
        IslamicContentModel.createHadith(
          content: "مَا نَقَصَ مَالٌ مِنْ صَدَقَةٍ",
          source: "Sunan al-Tirmidhi",
          reference: "2325",
          translation: "Wealth is not diminished by giving charity.",
          category: ContentCategory.charity,
          tags: ["charity", "wealth", "giving"],
        ),
      ];

      // Add default Quran verses
      final quranVerses = [
        IslamicContentModel.createQuranVerse(
          content:
              "فَإِنَّ مَعَ الْعُسْرِ يُسْرًا إِنَّ مَعَ الْعُسْرِ يُسْرًا",
          reference: "94:5-6",
          translation:
              "For indeed, with hardship [will be] ease. Indeed, with hardship [will be] ease.",
          category: ContentCategory.patience,
          tags: ["hardship", "ease", "patience"],
        ),
        IslamicContentModel.createQuranVerse(
          content:
              "وَلَا تَهِنُوا وَلَا تَحْزَنُوا وَأَنتُمُ الْأَعْلَوْنَ إِن كُنتُم مُّؤْمِنِينَ",
          reference: "3:139",
          translation:
              "Do not be weak and do not grieve, and you will be superior if you are [true] believers.",
          category: ContentCategory.strength,
          tags: ["strength", "faith", "perseverance"],
        ),
        IslamicContentModel.createQuranVerse(
          content:
              "وَاسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ ۚ وَإِنَّهَا لَكَبِيرَةٌ إِلَّا عَلَى الْخَاشِعِينَ",
          reference: "2:45",
          translation:
              "And seek help through patience and prayer, and indeed, it is difficult except for the humbly submissive [to Allah].",
          category: ContentCategory.discipline,
          tags: ["prayer", "patience", "discipline"],
        ),
        IslamicContentModel.createQuranVerse(
          content:
              "وَلَا تَيْأَسُوا مِن رَّوْحِ اللَّهِ ۖ إِنَّهُ لَا يَيْأَسُ مِن رَّوْحِ اللَّهِ إِلَّا الْقَوْمُ الْكَافِرُونَ",
          reference: "12:87",
          translation:
              "And do not despair of relief from Allah. Indeed, no one despairs of relief from Allah except the disbelieving people.",
          category: ContentCategory.hope,
          tags: ["hope", "mercy", "relief"],
        ),
        IslamicContentModel.createQuranVerse(
          content:
              "وَلَمَن صَبَرَ وَغَفَرَ إِنَّ ذَٰلِكَ لَمِنْ عَزْمِ الْأُمُورِ",
          reference: "42:43",
          translation:
              "And whoever is patient and forgives - indeed, that is of the matters [requiring] determination.",
          category: ContentCategory.forgiveness,
          tags: ["patience", "forgiveness", "determination"],
        ),
      ];

      // Add default duas
      final duas = [
        IslamicContentModel.createDua(
          content:
              "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ",
          source: "Quran",
          reference: "2:201",
          translation:
              "Our Lord, give us in this world [that which is] good and in the Hereafter [that which is] good and protect us from the punishment of the Fire.",
          category: ContentCategory.general,
          tags: ["dua", "success", "protection"],
        ),
        IslamicContentModel.createDua(
          content:
              "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْبُخْلِ وَالْجُبْنِ، وَضَلَعِ الدَّيْنِ وَغَلَبَةِ الرِّجَالِ",
          source: "Sahih al-Bukhari",
          reference: "6369",
          translation:
              "O Allah, I seek refuge in You from worry and grief, from helplessness and laziness, from cowardice and stinginess, and from being heavily in debt and from being overcome by men.",
          category: ContentCategory.strength,
          tags: ["protection", "strength", "anxiety"],
        ),
        IslamicContentModel.createDua(
          content: "رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي",
          source: "Quran",
          reference: "20:25-26",
          translation:
              "My Lord, expand for me my breast [with assurance] and ease for me my task.",
          category: ContentCategory.discipline,
          tags: ["ease", "difficulty", "help"],
        ),
        IslamicContentModel.createDua(
          content:
              "اللَّهُمَّ أَصْلِحْ لِي دِينِي الَّذِي هُوَ عِصْمَةُ أَمْرِي، وَأَصْلِحْ لِي دُنْيَايَ الَّتِي فِيهَا مَعَاشِي، وَأَصْلِحْ لِي آخِرَتِي الَّتِي فِيهَا مَعَادِي، وَاجْعَلِ الْحَيَاةَ زِيَادَةً لِي فِي كُلِّ خَيْرٍ، وَاجْعَلِ الْمَوْتَ رَاحَةً لِي مِنْ كُلِّ شَرٍّ",
          source: "Sahih Muslim",
          reference: "2720",
          translation:
              "O Allah, rectify for me my religion, which is the safeguard of my affairs. And rectify for me my worldly affairs, wherein is my living. And rectify for me my Hereafter, to which is my return. And make life for me a means of increase for every good. And make death a relief for me from every evil.",
          category: ContentCategory.general,
          tags: ["wellbeing", "faith", "worldly affairs"],
        ),
        IslamicContentModel.createDua(
          content:
              "رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِن لَّدُنكَ رَحْمَةً ۚ إِنَّكَ أَنتَ الْوَهَّابُ",
          source: "Quran",
          reference: "3:8",
          translation:
              "Our Lord, let not our hearts deviate after You have guided us and grant us from Yourself mercy. Indeed, You are the Bestower.",
          category: ContentCategory.guidance,
          tags: ["guidance", "mercy", "steadfastness"],
        ),
      ];

      // Save all the content
      for (final hadith in hadiths) {
        saveContent(hadith);
      }

      for (final verse in quranVerses) {
        saveContent(verse);
      }

      for (final dua in duas) {
        saveContent(dua);
      }

      developer.log('Initialized default Islamic content',
          name: 'IslamicContentRepository');
    } catch (e) {
      developer.log('Error initializing default content: $e',
          name: 'IslamicContentRepository');
      throw Exception('Failed to initialize default content: $e');
    }
  }
}
