import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/loading_overlay.dart';

/// Screen for setting up the initial password
class PasswordSetupScreen extends ConsumerStatefulWidget {
  /// Constructor
  const PasswordSetupScreen({super.key});

  @override
  ConsumerState<PasswordSetupScreen> createState() =>
      _PasswordSetupScreenState();
}

class _PasswordSetupScreenState extends ConsumerState<PasswordSetupScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _typeToConfirmController = TextEditingController();

  bool _passwordsMatch = true;
  bool _passwordIsStrong = true;
  bool _isLoading = false;
  bool _isConfirmed = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _typeToConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state for loading and errors
    final authState = ref.watch(authProvider);

    return LoadingOverlay(
        isLoading: authState.isLoading || _isLoading,
        message: 'Setting up your password...',
        animationType: LoadingAnimationType.staggeredDotsWave,
        child: Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.createPassword),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Password setup explanation
                const Card(
                  color: AppColors.secondary,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.securityWarning,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.text,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          AppStrings.securityWarningMessage,
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Password field
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: AppStrings.password,
                    errorText:
                        !_passwordIsStrong ? AppStrings.passwordTooShort : null,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_passwordVisible,
                  onChanged: (_) => _validatePasswords(),
                ),

                const SizedBox(height: 16),

                // Confirm password field
                TextField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: AppStrings.confirmPassword,
                    errorText:
                        !_passwordsMatch ? AppStrings.passwordMismatch : null,
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: !_passwordVisible,
                  onChanged: (_) => _validatePasswords(),
                ),

                const SizedBox(height: 24),

                // Type to confirm field
                TextField(
                  controller: _typeToConfirmController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.typeToConfirm,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _isConfirmed = value.toLowerCase() == 'i understand';
                    });
                  },
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

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canSubmit() ? _setPassword : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            AppStrings.createPassword,
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  /// Validate passwords match and are strong enough
  void _validatePasswords() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _passwordsMatch = password == confirmPassword || confirmPassword.isEmpty;
      _passwordIsStrong = password.length >= 6 || password.isEmpty;
    });
  }

  /// Check if the form can be submitted
  bool _canSubmit() {
    return !_isLoading &&
        _passwordsMatch &&
        _passwordIsStrong &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _isConfirmed;
  }

  /// Set the password and navigate to the next screen
  Future<void> _setPassword() async {
    if (!_canSubmit()) return;

    setState(() {
      _isLoading = true;
    });

    final success = await ref
        .read(authProvider.notifier)
        .setInitialPassword(_passwordController.text);

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
