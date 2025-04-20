import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/security/secure_storage_service.dart';
import '../../core/config/ai_service_config.dart';
import '../../data/models/ai_models.dart';

/// Provider to store and manage AI service settings
final aiServiceSettingsProvider =
    StateNotifierProvider<AIServiceSettingsNotifier, AIServiceConfig>((ref) {
  return AIServiceSettingsNotifier();
});

/// Notifier to manage AI service settings state
class AIServiceSettingsNotifier extends StateNotifier<AIServiceConfig> {
  final SecureStorageService _secureStorage = SecureStorageService.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AIServiceSettingsNotifier()
      : super(const AIServiceConfig(serviceType: AIServiceType.offline)) {
    // Initialize settings from secure storage
    _loadSettings();
  }

  /// Load settings from secure storage
  Future<void> _loadSettings() async {
    try {
      // Get saved service type
      final savedType = await _storage.read(key: 'selectedAIService');
      final serviceType = savedType != null
          ? AIServiceType.values.firstWhere(
              (type) => type.toString() == savedType,
              orElse: () => AIServiceType.offline,
            )
          : AIServiceType.offline;

      // Get API key for the service type
      final apiKey = await _secureStorage.getKey(serviceType.toString());

      // Get other settings
      final preferredModel = await _storage.read(key: 'preferredModel');
      final allowDataTraining =
          (await _storage.read(key: 'allowDataTraining')) == 'true';
      final temperature =
          double.tryParse(await _storage.read(key: 'temperature') ?? '') ?? 0.7;
      final maxTokens =
          int.tryParse(await _storage.read(key: 'maxTokens') ?? '') ?? 8096;

      // Update state with loaded settings
      state = AIServiceConfig(
        serviceType: serviceType,
        apiKey: apiKey,
        preferredModel: preferredModel,
        allowDataTraining: allowDataTraining,
        temperature: temperature,
        maxTokens: maxTokens,
      );
    } catch (e) {
      print('Error loading AI service settings: $e');
      // Keep default offline state on error
    }
  }

  /// Set the service type and save it
  Future<void> setServiceType(AIServiceType type) async {
    try {
      await _storage.write(key: 'selectedAIService', value: type.toString());

      // Get the API key for this service type if it exists
      final apiKey = await _secureStorage.getKey(type.toString());

      state = state.copyWith(
        serviceType: type,
        apiKey: apiKey, // Use existing API key if available
      );
    } catch (e) {
      print('Error setting service type: $e');
    }
  }

  /// Set and save the API key for the current service
  Future<void> setApiKey(String apiKey) async {
    try {
      await _secureStorage.storeKey(state.serviceType.toString(), apiKey);
      state = state.copyWith(apiKey: apiKey);
    } catch (e) {
      print('Error setting API key: $e');
    }
  }

  /// Set and save the preferred model
  Future<void> setPreferredModel(String? model) async {
    try {
      if (model != null) {
        await _storage.write(key: 'preferredModel', value: model);
      } else {
        await _storage.delete(key: 'preferredModel');
      }
      state = state.copyWith(preferredModel: model);
    } catch (e) {
      print('Error setting preferred model: $e');
    }
  }

  /// Toggle and save data training permission
  Future<void> setAllowDataTraining(bool allow) async {
    try {
      await _storage.write(key: 'allowDataTraining', value: allow.toString());
      state = state.copyWith(allowDataTraining: allow);
    } catch (e) {
      print('Error setting data training permission: $e');
    }
  }

  /// Set and save temperature
  Future<void> setTemperature(double temperature) async {
    try {
      await _storage.write(key: 'temperature', value: temperature.toString());
      state = state.copyWith(temperature: temperature);
    } catch (e) {
      print('Error setting temperature: $e');
    }
  }

  /// Set and save max tokens
  Future<void> setMaxTokens(int maxTokens) async {
    try {
      await _storage.write(key: 'maxTokens', value: maxTokens.toString());
      state = state.copyWith(maxTokens: maxTokens);
    } catch (e) {
      print('Error setting max tokens: $e');
    }
  }
}
