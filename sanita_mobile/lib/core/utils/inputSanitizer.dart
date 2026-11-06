class InputSanitizer {
  InputSanitizer._();

  static final RegExp _htmlTagPattern = RegExp(r'<[^>]*>');

  /// Strips HTML tags and script content to prevent Cross-Site Scripting (XSS)
  static String sanitize(String input) {
    if (input.isEmpty) return '';
    final withoutTags = input.replaceAll(_htmlTagPattern, '').trim();
    return withoutTags
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Alias for sanitize
  static String sanitizeText(String input) => sanitize(input);

  /// Validates location text
  static bool isValidLocation(String location) {
    final trimmed = location.trim();
    return trimmed.length >= 2 && trimmed.length <= 100;
  }

  /// Validates description text
  static bool isValidDescription(String desc) {
    final trimmed = desc.trim();
    return trimmed.length >= 5 && trimmed.length <= 1000;
  }
}