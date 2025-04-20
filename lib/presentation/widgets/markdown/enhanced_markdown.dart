import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'latex_renderer.dart';

/// Enhanced markdown widget for better rendering of AI-generated content
class EnhancedMarkdown extends StatelessWidget {
  /// The markdown content to display
  final String data;

  /// Whether this is a user message (affects styling)
  final bool isUserMessage;

  /// Custom text style
  final TextStyle? style;

  const EnhancedMarkdown({
    Key? key,
    required this.data,
    this.isUserMessage = false,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check for LaTeX expressions
    final containsLatex = data.contains(r'\(') || data.contains(r'\[');

    // If it contains LaTeX, we need special handling
    if (containsLatex) {
      return _buildWithLatex(context);
    }

    // Regular markdown rendering
    return _buildMarkdown(context);
  }

  /// Build markdown without LaTeX handling
  Widget _buildMarkdown(BuildContext context) {
    // Apply message-specific styling
    final baseStyle = style ??
        TextStyle(
          color: isUserMessage
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface,
          fontSize: 15,
        );

    // Create the markdown styling
    final markdownStyleSheet = MarkdownStyleSheet(
      // Regular text
      p: baseStyle,

      // Bold text
      strong: baseStyle.copyWith(
        fontWeight: FontWeight.bold,
      ),

      // Italic text
      em: baseStyle.copyWith(
        fontStyle: FontStyle.italic,
      ),

      // Strikethrough
      del: baseStyle.copyWith(
        decoration: TextDecoration.lineThrough,
      ),

      // Links
      a: baseStyle.copyWith(
        color: isUserMessage ? Colors.white70 : Theme.of(context).primaryColor,
        decoration: TextDecoration.underline,
      ),

      // Headings
      h1: baseStyle.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        height: 1.5,
      ),
      h2: baseStyle.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ),
      h3: baseStyle.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
      h4: baseStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
      h5: baseStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        height: 1.1,
      ),
      h6: baseStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        height: 1.0,
      ),

      // Blockquotes
      blockquote: baseStyle,
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isUserMessage
                ? Colors.white70
                : Theme.of(context).primaryColor.withOpacity(0.7),
            width: 4,
          ),
        ),
        color: isUserMessage
            ? Colors.white.withOpacity(0.1)
            : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      blockquotePadding:
          const EdgeInsets.only(left: 16, top: 8, bottom: 8, right: 8),

      // Lists
      listBullet: baseStyle,
      listIndent: 24,

      // Tables
      tableHead: baseStyle.copyWith(fontWeight: FontWeight.bold),
      tableBody: baseStyle,
      tableBorder: TableBorder.all(
        color: isUserMessage
            ? Colors.white30
            : Theme.of(context).colorScheme.outline.withOpacity(0.5),
        width: 1,
      ),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

      // Code blocks
      code: baseStyle.copyWith(
        fontFamily: 'monospace',
        backgroundColor: isUserMessage
            ? Colors.white.withOpacity(0.1)
            : Theme.of(context).primaryColor.withOpacity(0.1),
        color: isUserMessage ? Colors.white : Theme.of(context).primaryColor,
      ),
      codeblockDecoration: BoxDecoration(
        color: isUserMessage
            ? Colors.white10
            : Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      codeblockPadding: const EdgeInsets.all(8),

      // Horizontal rule
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isUserMessage
                ? Colors.white30
                : Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
      ),
    );

    return MarkdownBody(
      data: _preprocessMarkdown(data),
      styleSheet: markdownStyleSheet,
      selectable: !isUserMessage, // Allow selection for AI messages
      onTapLink: (text, href, title) => _handleLinkTap(context, href),
      listItemCrossAxisAlignment: MarkdownListItemCrossAxisAlignment.start,
      softLineBreak: true,
      shrinkWrap: true,
    );
  }

  /// Build a widget that handles LaTeX expressions
  Widget _buildWithLatex(BuildContext context) {
    // Split the content based on LaTeX delimiters
    final parts = <Widget>[];
    String remaining = data;

    // Process inline LaTeX: \( ... \)
    while (remaining.contains(r'\(') && remaining.contains(r'\)')) {
      final startIndex = remaining.indexOf(r'\(');

      // Add text before LaTeX if there's any
      if (startIndex > 0) {
        parts.add(_buildSimpleMarkdown(context,
            markdown: remaining.substring(0, startIndex)));
      }

      // Extract the LaTeX
      final endIndex = remaining.indexOf(r'\)', startIndex);
      if (endIndex > startIndex) {
        final latex = remaining.substring(startIndex + 2, endIndex);
        parts.add(LaTeXRenderer(
          latex: latex,
          isInline: true,
          style: TextStyle(
            color: isUserMessage
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
        ));

        // Continue with the rest
        remaining = remaining.substring(endIndex + 2);
      } else {
        // If no closing delimiter, break to avoid infinite loop
        break;
      }
    }

    // Process block LaTeX: \[ ... \]
    while (remaining.contains(r'\[') && remaining.contains(r'\]')) {
      final startIndex = remaining.indexOf(r'\[');

      // Add text before LaTeX if there's any
      if (startIndex > 0) {
        parts.add(_buildSimpleMarkdown(context,
            markdown: remaining.substring(0, startIndex)));
      }

      // Extract the LaTeX
      final endIndex = remaining.indexOf(r'\]', startIndex);
      if (endIndex > startIndex) {
        final latex = remaining.substring(startIndex + 2, endIndex);
        parts.add(LaTeXRenderer(
          latex: latex,
          isInline: false,
          style: TextStyle(
            color: isUserMessage
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
        ));

        // Continue with the rest
        remaining = remaining.substring(endIndex + 2);
      } else {
        // If no closing delimiter, break to avoid infinite loop
        break;
      }
    }

    // Add remaining text if any
    if (remaining.isNotEmpty) {
      parts.add(_buildSimpleMarkdown(context, markdown: remaining));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts,
    );
  }

  // Create a markdown widget for a specific text segment
  Widget _buildSimpleMarkdown(BuildContext context,
      {required String markdown}) {
    // Apply message-specific styling
    final baseStyle = style ??
        TextStyle(
          color: isUserMessage
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface,
          fontSize: 15,
        );

    // Create the markdown styling
    final markdownStyleSheet = MarkdownStyleSheet(
      p: baseStyle,
      strong: baseStyle.copyWith(fontWeight: FontWeight.bold),
      em: baseStyle.copyWith(fontStyle: FontStyle.italic),
      a: baseStyle.copyWith(
        color: isUserMessage ? Colors.white70 : Theme.of(context).primaryColor,
        decoration: TextDecoration.underline,
      ),
      code: baseStyle.copyWith(
        fontFamily: 'monospace',
        backgroundColor: isUserMessage
            ? Colors.white.withOpacity(0.1)
            : Theme.of(context).primaryColor.withOpacity(0.1),
      ),
    );

    return MarkdownBody(
      data: _preprocessMarkdown(markdown),
      styleSheet: markdownStyleSheet,
      selectable: !isUserMessage,
      onTapLink: (text, href, title) => _handleLinkTap(context, href),
      listItemCrossAxisAlignment: MarkdownListItemCrossAxisAlignment.start,
      softLineBreak: true,
      shrinkWrap: true,
    );
  }

  // Handle link taps
  void _handleLinkTap(BuildContext context, String? href) {
    if (href != null && href.isNotEmpty) {
      try {
        final uri = Uri.parse(href);
        launcher.launchUrl(
          uri,
          mode: launcher.LaunchMode.externalApplication,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Preprocess markdown to fix common issues
  String _preprocessMarkdown(String markdown) {
    String processed = markdown;

    // Fix checkbox syntax
    processed = processed.replaceAll(RegExp(r'\[ \]'), '- [ ]');
    processed = processed.replaceAll(RegExp(r'\[x\]'), '- [x]');

    // Convert emoji shortcodes
    processed = _convertEmojiShortcodes(processed);

    return processed;
  }

  // Simple emoji shortcode converter
  String _convertEmojiShortcodes(String text) {
    // Map of common emoji shortcodes
    const emojiMap = {
      ':smile:': '😊',
      ':laughing:': '😄',
      ':blush:': '😊',
      ':smiley:': '😃',
      ':relaxed:': '☺️',
      ':smirk:': '😏',
      ':heart:': '❤️',
      ':thumbsup:': '👍',
      ':thumbsdown:': '👎',
      ':check:': '✅',
      ':x:': '❌',
    };

    String result = text;
    emojiMap.forEach((shortcode, emoji) {
      result = result.replaceAll(shortcode, emoji);
    });

    return result;
  }
}
