import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

/// A reusable loading indicator widget
class LoadingIndicator extends StatelessWidget {
  /// Whether to show the loading text
  final bool showText;

  /// The size of the loading indicator
  final double size;

  /// The text to display below the indicator
  final String? text;

  /// Constructor
  const LoadingIndicator({
    super.key,
    this.showText = true,
    this.size = 40.0,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          if (showText) ...[
            const SizedBox(height: 16),
            Text(
              text ?? AppStrings.loading,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
