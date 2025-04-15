import '../../../data/repositories/auth_repository.dart';
import 'dart:developer' as dev;

/// Use case for managing API keys for AI services
class ManageApiKeyUseCase {
  final AuthRepository _repository;

  /// Constructor for dependency injection
  ManageApiKeyUseCase(this._repository);

  /// Save an API key for AI services
  ///
  /// [apiKey] - The API key to save
  /// [serviceType] - The type of AI service (e.g., 'openai', 'anthropic', 'openrouter')
  /// Returns true if the API key was successfully saved, false otherwise
  Future<bool> saveApiKey(String apiKey, String serviceType) async {
    try {
      return await _repository.saveApiKey(apiKey, serviceType);
    } catch (e) {
      dev.log('Error saving API key: $e');
      return false;
    }
  }

  /// Get the saved API key
  ///
  /// Returns the API key if one exists, null otherwise
  Future<String?> getApiKey() async {
    try {
      return await _repository.getApiKey();
    } catch (e) {
      dev.log('Error getting API key: $e');
      return null;
    }
  }

  /// Get the API service type
  ///
  /// Returns the service type if set, null otherwise
  Future<String?> getApiServiceType() async {
    try {
      return await _repository.getApiServiceType();
    } catch (e) {
      dev.log('Error getting API service type: $e');
      return null;
    }
  }

  /// Clear the saved API key
  ///
  /// Returns true if the API key was successfully cleared, false otherwise
  Future<bool> clearApiKey() async {
    try {
      return await _repository.saveApiKey('', '');
    } catch (e) {
      dev.log('Error clearing API key: $e');
      return false;
    }
  }
}
