import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../../core/constants/app_colors.dart';

/// A reusable loading overlay widget that can be used throughout the app
class LoadingOverlay extends StatelessWidget {
  /// Whether to show the loading overlay
  final bool isLoading;

  /// The child widget to display behind the loading overlay
  final Widget child;

  /// The message to display below the loading indicator
  final String? message;

  /// The type of loading animation to display
  final LoadingAnimationType animationType;

  /// The size of the loading indicator
  final double size;

  /// The color of the loading indicator
  final Color? color;

  /// Constructor
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.animationType = LoadingAnimationType.staggeredDotsWave,
    this.size = 40.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The main content
        child,

        // The loading overlay
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 77), // 0.3 * 255 = 77
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLoadingAnimation(context),
                  if (message != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black
                            .withValues(alpha: 179), // 0.7 * 255 = 179
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        message!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Build the loading animation based on the animation type
  Widget _buildLoadingAnimation(BuildContext context) {
    final loadingColor = color ?? AppColors.primary;

    switch (animationType) {
      case LoadingAnimationType.staggeredDotsWave:
        return LoadingAnimationWidget.staggeredDotsWave(
          color: loadingColor,
          size: size,
        );
      case LoadingAnimationType.waveDots:
        return LoadingAnimationWidget.waveDots(
          color: loadingColor,
          size: size,
        );
      case LoadingAnimationType.inkDrop:
        return LoadingAnimationWidget.inkDrop(
          color: loadingColor,
          size: size,
        );
      case LoadingAnimationType.threeArchedCircle:
        return LoadingAnimationWidget.threeArchedCircle(
          color: loadingColor,
          size: size,
        );
      case LoadingAnimationType.fourRotatingDots:
        return LoadingAnimationWidget.fourRotatingDots(
          color: loadingColor,
          size: size,
        );
      case LoadingAnimationType.fallingDot:
        return LoadingAnimationWidget.fallingDot(
          color: loadingColor,
          size: size,
        );
      case LoadingAnimationType.progressiveDots:
        return LoadingAnimationWidget.progressiveDots(
          color: loadingColor,
          size: size,
        );
      case LoadingAnimationType.discreteCircle:
        return LoadingAnimationWidget.discreteCircle(
          color: loadingColor,
          size: size,
          secondRingColor:
              loadingColor.withValues(alpha: 128), // 0.5 * 255 = 128
          thirdRingColor: loadingColor.withValues(alpha: 51), // 0.2 * 255 = 51
        );
      case LoadingAnimationType.horizontalRotatingDots:
        return LoadingAnimationWidget.horizontalRotatingDots(
          color: loadingColor,
          size: size,
        );
      case LoadingAnimationType.newtonCradle:
        return LoadingAnimationWidget.newtonCradle(
          color: loadingColor,
          size: size,
        );
      case LoadingAnimationType.stretchedDots:
        return LoadingAnimationWidget.stretchedDots(
          color: loadingColor,
          size: size,
        );
      case LoadingAnimationType.halfTriangleDot:
        return LoadingAnimationWidget.halfTriangleDot(
          color: loadingColor,
          size: size,
        );
      case LoadingAnimationType.dotsTriangle:
        return LoadingAnimationWidget.dotsTriangle(
          color: loadingColor,
          size: size,
        );
      case LoadingAnimationType.flickr:
        return LoadingAnimationWidget.flickr(
          leftDotColor: loadingColor,
          rightDotColor: loadingColor.withValues(alpha: 128), // 0.5 * 255 = 128
          size: size,
        );
      case LoadingAnimationType.hexagonDots:
        return LoadingAnimationWidget.hexagonDots(
          color: loadingColor,
          size: size,
        );
      case LoadingAnimationType.beat:
        return LoadingAnimationWidget.beat(
          color: loadingColor,
          size: size,
        );
      case LoadingAnimationType.twoRotatingArc:
        return LoadingAnimationWidget.twoRotatingArc(
          color: loadingColor,
          size: size,
        );
      case LoadingAnimationType.threeRotatingDots:
        return LoadingAnimationWidget.threeRotatingDots(
          color: loadingColor,
          size: size,
        );
      case LoadingAnimationType.bouncingBall:
        return LoadingAnimationWidget.bouncingBall(
          color: loadingColor,
          size: size,
        );
    }
  }
}

/// The type of loading animation to display
enum LoadingAnimationType {
  staggeredDotsWave,
  waveDots,
  inkDrop,
  threeArchedCircle,
  fourRotatingDots,
  fallingDot,
  progressiveDots,
  discreteCircle,
  horizontalRotatingDots,
  newtonCradle,
  stretchedDots,
  halfTriangleDot,
  dotsTriangle,
  flickr,
  hexagonDots,
  beat,
  twoRotatingArc,
  threeRotatingDots,
  bouncingBall,
}
