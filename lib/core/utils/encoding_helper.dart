import 'dart:convert';
import 'package:http/http.dart' as http;

/// Helper class for handling encoding issues in API responses
class EncodingHelper {
  /// Safely decode HTTP response to JSON with proper UTF-8 handling
  static dynamic decodeResponse(http.Response response) {
    // Check if the response has a content-type header
    final contentType = response.headers['content-type'];

    // First try to decode using the response's charset if available
    if (contentType != null && contentType.contains('charset=')) {
      final charset =
          RegExp(r'charset=([^\s;]+)').firstMatch(contentType)?.group(1);
      if (charset != null && charset.toLowerCase() != 'utf-8') {
        // If a non-UTF-8 charset is specified, handle accordingly
        try {
          // For specific charsets, you might need custom handling
          return json.decode(utf8.decode(response.bodyBytes));
        } catch (e) {
          // Fallback to direct UTF-8 decoding
          return _fallbackDecode(response);
        }
      }
    }

    // Default UTF-8 decoding
    return _fallbackDecode(response);
  }

  /// Fallback decoding method that handles common encoding issues
  static dynamic _fallbackDecode(http.Response response) {
    try {
      // Try standard UTF-8 decoding first
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      // If that fails, try Latin-1 (ISO-8859-1) decoding
      // This is a common fallback for incorrectly encoded responses
      try {
        return json.decode(latin1.decode(response.bodyBytes));
      } catch (e) {
        // Last resort: try to decode the raw string and normalize it
        try {
          final rawString = response.body;
          final normalizedString = _normalizeText(rawString);
          return json.decode(normalizedString);
        } catch (e) {
          // If all decoding attempts fail, return an error object
          return {'error': 'Failed to decode response', 'raw': response.body};
        }
      }
    }
  }

  /// Normalize text to fix common encoding issues
  /// This is similar to the function in message_bubble.dart but focused on JSON strings
  static String _normalizeText(String text) {
    String normalized = text;

    // Fix apostrophes (single quotes)
    normalized = normalized.replaceAll('Â\'', '\'');
    normalized = normalized.replaceAll('â€™', '\'');
    normalized = normalized.replaceAll('â ', '\'');
    normalized = normalized.replaceAll('â', '\'');

    // Fix apostrophes with extra spaces (like "it'       s")
    final apostropheSpacePattern = RegExp(r"'(\s+)");
    normalized = normalized.replaceAllMapped(apostropheSpacePattern, (match) {
      return "'"; // Replace apostrophe followed by spaces with just apostrophe
    });

    // Fix contractions with spaces
    final contractionPattern = RegExp(r"(\w)'(\s+)(\w)");
    normalized = normalized.replaceAllMapped(contractionPattern, (match) {
      return "${match.group(1)}'${match.group(3)}"; // e.g., "it' s" -> "it's"
    });

    // Fix common contractions specifically
    normalized = normalized.replaceAll("it' s", "it's");
    normalized = normalized.replaceAll("don' t", "don't");
    normalized = normalized.replaceAll("isn' t", "isn't");
    normalized = normalized.replaceAll("wasn' t", "wasn't");
    normalized = normalized.replaceAll("wouldn' t", "wouldn't");
    normalized = normalized.replaceAll("couldn' t", "couldn't");
    normalized = normalized.replaceAll("shouldn' t", "shouldn't");
    normalized = normalized.replaceAll("won' t", "won't");
    normalized = normalized.replaceAll("can' t", "can't");
    normalized = normalized.replaceAll("that' s", "that's");
    normalized = normalized.replaceAll("there' s", "there's");
    normalized = normalized.replaceAll("he' s", "he's");
    normalized = normalized.replaceAll("she' s", "she's");
    normalized = normalized.replaceAll("what' s", "what's");
    normalized = normalized.replaceAll("let' s", "let's");

    // Fix any remaining apostrophe issues with multiple spaces
    final multiSpacePattern = RegExp(r"'(\s{2,})");
    normalized = normalized.replaceAllMapped(multiSpacePattern, (match) {
      return "'";
    });

    // Fix double quotes that might break JSON parsing
    normalized = normalized.replaceAll('â€œ', '"');
    normalized = normalized.replaceAll('â€', '"');

    // Fix other common special characters
    normalized = normalized.replaceAll('Â', '');
    normalized = normalized.replaceAll('â€"', '-');
    normalized = normalized.replaceAll('â€"', '-');

    // Fix accented characters
    normalized = normalized.replaceAll('Ã©', 'é');
    normalized = normalized.replaceAll('Ã¨', 'è');
    normalized = normalized.replaceAll('Ã¢', 'â');
    normalized = normalized.replaceAll('Ã´', 'ô');
    normalized = normalized.replaceAll('Ã»', 'û');
    normalized = normalized.replaceAll('Ã§', 'ç');

    return normalized;
  }

  /// Encode text to ensure proper UTF-8 encoding when sending to APIs
  static String encodeText(String text) {
    // First normalize any problematic characters
    final normalized = _normalizeText(text);

    // Then ensure proper UTF-8 encoding
    final bytes = utf8.encode(normalized);
    return utf8.decode(bytes);
  }
}
