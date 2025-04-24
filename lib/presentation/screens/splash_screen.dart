import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../providers/auth_provider_refactored.dart';
import '../../domain/usecases/auth/get_user_status_usecase.dart';

/// A splash screen that is shown while the app is initializing
class SplashScreen extends ConsumerStatefulWidget {
  /// Constructor
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // No need to explicitly initialize - the AsyncNotifier will handle it
  }

  @override
  Widget build(BuildContext context) {
    final asyncAuthState = ref.watch(authNotifierProvider);

    // Handle the AsyncValue state
    return asyncAuthState.when(
      loading: () => _buildLoadingScreen(true),
      error: (error, stackTrace) => _buildErrorScreen(error),
      data: (authState) {
        // Redirect based on auth status once initialization is complete
        if (!authState.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (authState.status == AuthStatus.newUser) {
              Navigator.of(context).pushReplacementNamed('/password-setup');
            } else if (authState.status == AuthStatus.authenticated) {
              Navigator.of(context).pushReplacementNamed('/home');
            } else {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          });
        }

        return _buildLoadingScreen(authState.isLoading);
      },
    );
  }

  // Build the loading screen UI
  Widget _buildLoadingScreen(bool isLoading) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 204), // 0.8 * 255 = 204
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo
              const Icon(
                Icons.shield,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 24),

              // App name
              const Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              // App slogan
              const Text(
                AppStrings.appSlogan,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 48),

              // Loading animation
              LoadingAnimationWidget.staggeredDotsWave(
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(height: 24),

              // Loading text
              Text(
                isLoading ? 'Loading...' : 'Ready',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build the error screen UI
  Widget _buildErrorScreen(Object error) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 204), // 0.8 * 255 = 204
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 24),

              // App name
              const Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Error message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Error: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Retry button
              ElevatedButton(
                onPressed: () {
                  // Refresh the auth provider
                  ref.invalidate(authNotifierProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
