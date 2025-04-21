import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/sound_service.dart';

/// Provider for accessing app settings
final settingsProvider =
    AutoDisposeAsyncNotifierProvider<SettingsNotifier, AppSettings>(
        SettingsNotifier.new);

/// App settings state
class AppSettings {
  /// Whether sound effects are enabled
  final bool soundEnabled;

  /// Whether the app is in dark mode
  final bool darkMode;

  /// Default constructor
  const AppSettings({
    this.soundEnabled = true,
    this.darkMode = false,
  });

  /// Create a copy with updated values
  AppSettings copyWith({
    bool? soundEnabled,
    bool? darkMode,
  }) {
    return AppSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      darkMode: darkMode ?? this.darkMode,
    );
  }
}

/// Notifier for app settings
class SettingsNotifier extends AutoDisposeAsyncNotifier<AppSettings> {
  final SoundService _soundService = SoundService();

  @override
  Future<AppSettings> build() async {
    return await _loadSettings();
  }

  /// Load settings from shared preferences
  Future<AppSettings> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final soundEnabled = prefs.getBool('soundEnabled') ?? true;
      final darkMode = prefs.getBool('darkMode') ?? false;

      // Update the sound service
      _soundService.soundEnabled = soundEnabled;

      return AppSettings(
        soundEnabled: soundEnabled,
        darkMode: darkMode,
      );
    } catch (e) {
      // If loading fails, keep default settings
      print('Error loading settings: $e');
      return const AppSettings();
    }
  }

  /// Toggle sound effects
  Future<void> toggleSound() async {
    final current = state.valueOrNull ?? const AppSettings();
    final newValue = !current.soundEnabled;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('soundEnabled', newValue);

      // Update the sound service
      _soundService.soundEnabled = newValue;

      // Play a success sound if turning on
      if (newValue) {
        _soundService.playSound(SoundEffect.success);
      }

      state = AsyncValue.data(current.copyWith(soundEnabled: newValue));
    } catch (e) {
      print('Error toggling sound: $e');
    }
  }

  /// Toggle dark mode
  Future<void> toggleDarkMode() async {
    final current = state.valueOrNull ?? const AppSettings();
    final newValue = !current.darkMode;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('darkMode', newValue);

      state = AsyncValue.data(current.copyWith(darkMode: newValue));
    } catch (e) {
      print('Error toggling dark mode: $e');
    }
  }
}
