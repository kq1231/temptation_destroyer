import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/usecases/auth/get_user_status_usecase.dart';
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/auth/set_password_usecase.dart';
import '../../domain/usecases/auth/manage_api_key_usecase.dart';
import '../../domain/usecases/auth/recovery_codes_usecase.dart';
import '../../data/models/user_model.dart';

part 'auth_provider_refactored.g.dart';

/// Provider for the authentication repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Provider for the login use case
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUseCase(repository);
});

/// Provider for the set password use case
final setPasswordUseCaseProvider = Provider<SetPasswordUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SetPasswordUseCase(repository);
});

/// Provider for the manage API key use case
final manageApiKeyUseCaseProvider = Provider<ManageApiKeyUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ManageApiKeyUseCase(repository);
});

/// Provider for the get user status use case
final getUserStatusUseCaseProvider = Provider<GetUserStatusUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetUserStatusUseCase(repository);
});

/// Provider for the recovery codes use case
final recoveryCodesUseCaseProvider = Provider<RecoveryCodesUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return RecoveryCodesUseCase(repository);
});

/// Authentication state
class AuthState {
  final User? user;
  final AuthStatus status;
  final bool isLoading;
  final String? errorMessage;

  /// Constructor
  AuthState({
    this.user,
    this.status = AuthStatus.newUser,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Create a copy of the state with updated values
  AuthState copyWith({
    User? user,
    AuthStatus? status,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier for authentication state using AsyncNotifier
@riverpod
class AuthNotifier extends _$AuthNotifier {
  late final LoginUseCase _loginUseCase;
  late final SetPasswordUseCase _setPasswordUseCase;
  late final ManageApiKeyUseCase _manageApiKeyUseCase;
  late final GetUserStatusUseCase _getUserStatusUseCase;
  late final RecoveryCodesUseCase _recoveryCodesUseCase;

  @override
  Future<AuthState> build() async {
    // Initialize use cases
    _loginUseCase = ref.watch(loginUseCaseProvider);
    _setPasswordUseCase = ref.watch(setPasswordUseCaseProvider);
    _manageApiKeyUseCase = ref.watch(manageApiKeyUseCaseProvider);
    _getUserStatusUseCase = ref.watch(getUserStatusUseCaseProvider);
    _recoveryCodesUseCase = ref.watch(recoveryCodesUseCaseProvider);

    // Initialize auth state
    try {
      final status = await _getUserStatusUseCase.execute();
      final user = await _getUserStatusUseCase.getUser();

      return AuthState(
        user: user,
        status: status,
        isLoading: false,
      );
    } catch (e) {
      return AuthState(
        status: AuthStatus.error,
        isLoading: false,
        errorMessage: 'Failed to initialize authentication: $e',
      );
    }
  }

  /// Attempt to login with password
  Future<bool> login(String password) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true, errorMessage: null));

    try {
      final success = await _loginUseCase.execute(password);

      if (success) {
        final user = await _getUserStatusUseCase.getUser();
        state = AsyncValue.data(state.value!.copyWith(
          user: user,
          status: AuthStatus.authenticated,
          isLoading: false,
        ));
      } else {
        state = AsyncValue.data(state.value!.copyWith(
          isLoading: false,
          errorMessage: 'Invalid password',
        ));
      }

      return success;
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        errorMessage: 'Login failed: $e',
      ));
      return false;
    }
  }

  /// Set initial password for a new user
  Future<bool> setInitialPassword(String password) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true, errorMessage: null));

    try {
      final success = await _setPasswordUseCase.execute(password);

      if (success) {
        final user = await _getUserStatusUseCase.getUser();
        state = AsyncValue.data(state.value!.copyWith(
          user: user,
          status: AuthStatus.authenticated,
          isLoading: false,
        ));
      } else {
        state = AsyncValue.data(state.value!.copyWith(
          isLoading: false,
          errorMessage: 'Failed to set password',
        ));
      }

      return success;
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        errorMessage: 'Failed to set password: $e',
      ));
      return false;
    }
  }

  /// Update existing password
  Future<bool> updatePassword(String oldPassword, String newPassword) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true, errorMessage: null));

    try {
      final success =
          await _setPasswordUseCase.updatePassword(oldPassword, newPassword);

      if (success) {
        final user = await _getUserStatusUseCase.getUser();
        state = AsyncValue.data(state.value!.copyWith(
          user: user,
          isLoading: false,
        ));
      } else {
        state = AsyncValue.data(state.value!.copyWith(
          isLoading: false,
          errorMessage: 'Failed to update password',
        ));
      }

      return success;
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update password: $e',
      ));
      return false;
    }
  }

  /// Save API key
  Future<bool> saveApiKey(String apiKey, String serviceType) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true, errorMessage: null));

    try {
      final success =
          await _manageApiKeyUseCase.saveApiKey(apiKey, serviceType);

      if (success) {
        final user = await _getUserStatusUseCase.getUser();
        state = AsyncValue.data(state.value!.copyWith(
          user: user,
          isLoading: false,
        ));
      } else {
        state = AsyncValue.data(state.value!.copyWith(
          isLoading: false,
          errorMessage: 'Failed to save API key',
        ));
      }

      return success;
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save API key: $e',
      ));
      return false;
    }
  }

  /// Get API key
  Future<String?> getApiKey() async {
    return await _manageApiKeyUseCase.getApiKey();
  }

  /// Get API service type
  Future<String?> getApiServiceType() async {
    return await _manageApiKeyUseCase.getApiServiceType();
  }

  /// Clear API key
  Future<bool> clearApiKey() async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true, errorMessage: null));

    try {
      final success = await _manageApiKeyUseCase.clearApiKey();

      if (success) {
        final user = await _getUserStatusUseCase.getUser();
        state = AsyncValue.data(state.value!.copyWith(
          user: user,
          isLoading: false,
        ));
      } else {
        state = AsyncValue.data(state.value!.copyWith(
          isLoading: false,
          errorMessage: 'Failed to clear API key',
        ));
      }

      return success;
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        errorMessage: 'Failed to clear API key: $e',
      ));
      return false;
    }
  }

  /// Generate recovery codes for the user
  Future<List<String>> generateRecoveryCodes({int count = 5}) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true, errorMessage: null));

    try {
      final codes =
          await _recoveryCodesUseCase.generateRecoveryCodes(count: count);
      state = AsyncValue.data(state.value!.copyWith(isLoading: false));
      return codes;
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        errorMessage: 'Failed to generate recovery codes: $e',
      ));
      return [];
    }
  }

  /// Reset password using a recovery code
  Future<Map<String, dynamic>> resetPasswordWithRecoveryCode(
      String recoveryCode, String newPassword) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true, errorMessage: null));

    try {
      final result = await _recoveryCodesUseCase.resetPasswordWithRecoveryCode(
        recoveryCode,
        newPassword,
      );

      if (result['success']) {
        final user = await _getUserStatusUseCase.getUser();
        state = AsyncValue.data(state.value!.copyWith(
          user: user,
          status: AuthStatus.authenticated,
          isLoading: false,
        ));
      } else {
        state = AsyncValue.data(state.value!.copyWith(
          isLoading: false,
          errorMessage: result['message'],
        ));
      }

      return result;
    } catch (e) {
      final errorMessage = 'Failed to reset password: $e';
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        errorMessage: errorMessage,
      ));
      return {'success': false, 'rateLimited': false, 'message': errorMessage};
    }
  }

  /// Check if the user has recovery codes set up
  Future<bool> hasRecoveryCodes() async {
    return await _recoveryCodesUseCase.hasRecoveryCodes();
  }

  /// Check if user is authenticated
  bool get isAuthenticated => state.value?.status == AuthStatus.authenticated;

  /// Check if user is new
  bool get isNewUser => state.value?.status == AuthStatus.newUser;
}
