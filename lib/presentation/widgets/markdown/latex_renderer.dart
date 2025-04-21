import 'package:flutter/material.dart';

/// A simple LaTeX renderer that doesn't require external packages
/// This is a placeholder that formats LaTeX nicely but doesn't render the actual equations
class LaTeXRenderer extends StatelessWidget {
  /// The LaTeX expression
  final String latex;

  /// Whether this is inline or block LaTeX
  final bool isInline;

  /// Text style for the LaTeX
  final TextStyle? style;

  const LaTeXRenderer({
    Key? key,
    required this.latex,
    this.isInline = true,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: isInline ? 15 : 16,
      color: Theme.of(context).colorScheme.onSurface,
    );

    final textStyle = style?.copyWith(
          fontFamily: 'monospace',
        ) ??
        defaultStyle;

    if (isInline) {
      return Text(
        '($latex)',
        style: textStyle,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            latex,
            style: textStyle,
            textAlign: TextAlign.center,
          ),
          const Divider(),
          const Text(
            'LaTeX equation (rendered as text)',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
