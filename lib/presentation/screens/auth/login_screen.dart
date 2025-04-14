import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';

/// Screen for user login
class LoginScreen extends ConsumerStatefulWidget {
  /// Constructor
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _hasPasswordText = false;

  @override
  void initState() {
    super.initState();
    // Add listener to update button state when text changes
    _passwordController.addListener(_updatePasswordState);
  }

  void _updatePasswordState() {
    final hasText = _passwordController.text.isNotEmpty;
    if (hasText != _hasPasswordText) {
      setState(() {
        _hasPasswordText = hasText;
      });
    }
  }

  @override
  void dispose() {
    _passwordController.removeListener(_updatePasswordState);
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.login),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App logo or icon
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Icon(
                  Icons.shield,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),
            ),

            // App title and welcome message
            Center(
              child: Column(
                children: [
                  Text(
                    AppStrings.appName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.appSlogan,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Password field
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: AppStrings.enterPassword,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_passwordVisible,
              onSubmitted: (_) => _login(),
              onChanged: (_) => _updatePasswordState(),
            ),

            const SizedBox(height: 16),

            if (authState.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  authState.errorMessage!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // Login button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canLogin() ? _login : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        AppStrings.login,
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Forgot password link
            Center(
              child: TextButton(
                onPressed: () {
                  // Navigate to forgot password screen
                  Navigator.of(context).pushNamed('/forgot-password');
                },
                child: const Text(AppStrings.forgotPassword),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Check if login can be attempted
  bool _canLogin() {
    return !_isLoading && _hasPasswordText;
  }

  /// Attempt to login
  Future<void> _login() async {
    if (!_canLogin()) return;

    setState(() {
      _isLoading = true;
    });

    final success =
        await ref.read(authProvider.notifier).login(_passwordController.text);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Navigate to the home screen
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }
}
