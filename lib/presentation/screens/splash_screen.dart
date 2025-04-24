import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../providers/auth_provider.dart';
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
    // Initialize the auth provider after the build is complete
    Future.microtask(() {
      _initializeApp();
    });
  }

  /// Initialize the app and navigate to the appropriate screen
  Future<void> _initializeApp() async {
    // Wait for the auth provider to initialize
    await ref.read(authProvider.notifier).initialize();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

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
                authState.isLoading ? 'Loading...' : 'Ready',
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
}
