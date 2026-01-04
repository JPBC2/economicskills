/// Content translation model for multilingual support
class ContentTranslation {
  final String id;
  final String entityType;
  final String entityId;
  final String language;
  final String field;
  final String value;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ContentTranslation({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.language,
    required this.field,
    required this.value,
    this.createdAt,
    this.updatedAt,
  });

  factory ContentTranslation.fromJson(Map<String, dynamic> json) {
    return ContentTranslation(
      id: json['id'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      language: json['language'] as String,
      field: json['field'] as String,
      value: json['value'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'language': language,
      'field': field,
      'value': value,
    };
  }

  /// Create a new translation for upserting
  static Map<String, dynamic> createUpsert({
    required String entityType,
    required String entityId,
    required String language,
    required String field,
    required String value,
  }) {
    return {
      'entity_type': entityType,
      'entity_id': entityId,
      'language': language,
      'field': field,
      'value': value,
    };
  }
}

/// Supported languages configuration
class SupportedLanguages {
  /// Language codes in display order
  static const List<String> codes = ['en', 'es', 'fr', 'zh', 'ru', 'pt'];

  /// Language names in their native form
  static const Map<String, String> names = {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'zh': '中文',
    'ru': 'Русский',
    'pt': 'Português',
  };

  /// Language names in English
  static const Map<String, String> englishNames = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'zh': 'Chinese (Simplified)',
    'ru': 'Russian',
    'pt': 'Portuguese',
  };

  /// Flag emoji for each language (for visual identification)
  static const Map<String, String> flags = {
    'en': '🇺🇸',
    'es': '🇪🇸',
    'fr': '🇫🇷',
    'zh': '🇨🇳',
    'ru': '🇷🇺',
    'pt': '🇧🇷',
  };

  /// Default language
  static const String defaultLanguage = 'en';

  /// Get display name with flag
  static String getDisplayName(String code) {
    final flag = flags[code] ?? '';
    final name = names[code] ?? code;
    return '$flag $name';
  }

  /// Check if a language code is valid
  static bool isValid(String code) => codes.contains(code);
}

/// Entity types that support translations
class TranslatableEntityTypes {
  static const String course = 'course';
  static const String unit = 'unit';
  static const String lesson = 'lesson';
  static const String exercise = 'exercise';
  static const String section = 'section';

  static const List<String> all = [course, unit, lesson, exercise, section];
}

/// Common translatable fields
class TranslatableFields {
  static const String title = 'title';
  static const String description = 'description';
  static const String instructions = 'instructions';
  static const String explanationText = 'explanation_text';
  static const String sourceReferences = 'source_references';
}
