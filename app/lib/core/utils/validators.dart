class Validators {
  Validators._();

  /// Validate URL format
  static bool isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  /// Validate text is not empty and within length limits
  static String? validateRequired(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate text length
  static String? validateLength(
    String? value, {
    int minLength = 1,
    int maxLength = 500,
    String fieldName = 'Field',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    if (value.trim().length > maxLength) {
      return '$fieldName must be at most $maxLength characters';
    }
    return null;
  }

  /// Validate URL input for KB items
  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'URL is required';
    }
    if (!isValidUrl(value.trim())) {
      return 'Please enter a valid URL (e.g., https://example.com)';
    }
    return null;
  }

  /// Check if file size is within limit (in bytes)
  static bool isFileSizeValid(int sizeInBytes, {int maxMB = 50}) {
    return sizeInBytes <= maxMB * 1024 * 1024;
  }
}
