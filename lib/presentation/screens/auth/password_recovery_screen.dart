import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temptation_destroyer/core/constants/app_colors.dart';
import 'package:temptation_destroyer/presentation/providers/auth_provider.dart';

class PasswordRecoveryScreen extends ConsumerStatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  ConsumerState<PasswordRecoveryScreen> createState() =>
      _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState
    extends ConsumerState<PasswordRecoveryScreen> {
  final TextEditingController _recoveryCodeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _recoveryCodeFocusNode = FocusNode();
  final FocusNode _newPasswordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  bool _isPasswordVisible = false;
  bool _isRecoveryInProgress = false;
  bool _isStrongPassword = false;

  @override
  void dispose() {
    _recoveryCodeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _recoveryCodeFocusNode.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  bool _passwordsMatch() {
    return _newPasswordController.text == _confirmPasswordController.text &&
        _newPasswordController.text.isNotEmpty;
  }

  bool _validatePassword() {
    final password = _newPasswordController.text;

    if (password.length < 8) {
      return false;
    }

    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters =
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    // Password is strong if it has at least two of: uppercase, digits, special chars
    int count = 0;
    if (hasUppercase) count++;
    if (hasDigits) count++;
    if (hasSpecialCharacters) count++;

    _isStrongPassword = count >= 2;
    return true;
  }

  Color _getPasswordStrengthColor() {
    if (_newPasswordController.text.isEmpty) {
      return Colors.grey;
    }
    if (!_validatePassword()) {
      return Colors.red;
    }
    return _isStrongPassword ? Colors.green : Colors.orange;
  }

  String _getPasswordStrengthText() {
    if (_newPasswordController.text.isEmpty) {
      return '';
    }
    if (!_validatePassword()) {
      return 'Password must be at least 8 characters';
    }
    return _isStrongPassword ? 'Strong password' : 'Moderate password';
  }

  bool _canSubmit() {
    return _recoveryCodeController.text.isNotEmpty &&
        _validatePassword() &&
        _passwordsMatch() &&
        !_isRecoveryInProgress;
  }

  Future<void> _recoverPassword() async {
    if (!_canSubmit()) return;

    setState(() {
      _isRecoveryInProgress = true;
    });

    try {
      final result =
          await ref.read(authProvider.notifier).resetPasswordWithRecoveryCode(
                _recoveryCodeController.text.trim(),
                _newPasswordController.text,
              );

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successful. You can now log in.'),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.of(context).pushReplacementNamed('/login');
      } else if (result['rateLimited']) {
        // User is rate limited
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        // Other error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRecoveryInProgress = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final hasError = authState.errorMessage != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Recovery'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.restore,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Reset Your Password',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your recovery code and a new password.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _recoveryCodeController,
                focusNode: _recoveryCodeFocusNode,
                decoration: InputDecoration(
                  labelText: 'Recovery Code',
                  hintText: 'Enter your recovery code',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.vpn_key),
                  errorText: hasError ? authState.errorMessage : null,
                ),
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                focusNode: _newPasswordFocusNode,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  hintText: 'Enter new password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isPasswordVisible,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _getPasswordStrengthColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getPasswordStrengthText(),
                    style: TextStyle(
                      color: _getPasswordStrengthColor(),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                focusNode: _confirmPasswordFocusNode,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Confirm your new password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  errorText: _confirmPasswordController.text.isNotEmpty &&
                          !_passwordsMatch()
                      ? 'Passwords do not match'
                      : null,
                ),
                obscureText: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _canSubmit() ? _recoverPassword : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isRecoveryInProgress
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Reset Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
