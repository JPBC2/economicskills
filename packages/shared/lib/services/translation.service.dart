import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/translation.model.dart';

/// Service for managing content translations
class TranslationService {
  final SupabaseClient _client;

  TranslationService(this._client);

  /// Get all translations for an entity
  /// Returns a map: { language: { field: value } }
  Future<Map<String, Map<String, String>>> getTranslations({
    required String entityType,
    required String entityId,
  }) async {
    try {
      final response = await _client
          .from('content_translations')
          .select()
          .eq('entity_type', entityType)
          .eq('entity_id', entityId);

      final Map<String, Map<String, String>> result = {};

      for (final row in response as List) {
        final language = row['language'] as String;
        final field = row['field'] as String;
        final value = row['value'] as String;

        result[language] ??= {};
        result[language]![field] = value;
      }

      return result;
    } catch (e) {
      print('Error loading translations: $e');
      return {};
    }
  }

  /// Get translations for a specific language
  Future<Map<String, String>> getTranslationsForLanguage({
    required String entityType,
    required String entityId,
    required String language,
  }) async {
    try {
      final response = await _client
          .from('content_translations')
          .select()
          .eq('entity_type', entityType)
          .eq('entity_id', entityId)
          .eq('language', language);

      final Map<String, String> result = {};
      for (final row in response as List) {
        result[row['field'] as String] = row['value'] as String;
      }
      return result;
    } catch (e) {
      print('Error loading translations for $language: $e');
      return {};
    }
  }

  /// Save translations for an entity
  /// Accepts a map: { language: { field: value } }
  Future<bool> saveTranslations({
    required String entityType,
    required String entityId,
    required Map<String, Map<String, String>> translations,
  }) async {
    try {
      // Build upsert records
      final records = <Map<String, dynamic>>[];

      for (final langEntry in translations.entries) {
        final language = langEntry.key;
        final fields = langEntry.value;

        for (final fieldEntry in fields.entries) {
          final field = fieldEntry.key;
          final value = fieldEntry.value;

          // Skip empty values
          if (value.trim().isEmpty) continue;

          records.add({
            'entity_type': entityType,
            'entity_id': entityId,
            'language': language,
            'field': field,
            'value': value.trim(),
          });
        }
      }

      if (records.isEmpty) return true;

      // Upsert all translations
      await _client.from('content_translations').upsert(
            records,
            onConflict: 'entity_type,entity_id,language,field',
          );

      return true;
    } catch (e) {
      print('Error saving translations: $e');
      return false;
    }
  }

  /// Delete all translations for an entity
  Future<bool> deleteTranslations({
    required String entityType,
    required String entityId,
  }) async {
    try {
      await _client
          .from('content_translations')
          .delete()
          .eq('entity_type', entityType)
          .eq('entity_id', entityId);
      return true;
    } catch (e) {
      print('Error deleting translations: $e');
      return false;
    }
  }

  /// Get translated content for display
  /// Falls back to English if translation not found
  Future<String?> getTranslatedField({
    required String entityType,
    required String entityId,
    required String field,
    required String language,
  }) async {
    final translations = await getTranslationsForLanguage(
      entityType: entityType,
      entityId: entityId,
      language: language,
    );

    // Try requested language first
    if (translations.containsKey(field) && translations[field]!.isNotEmpty) {
      return translations[field];
    }

    // Fall back to English
    if (language != SupportedLanguages.defaultLanguage) {
      final englishTranslations = await getTranslationsForLanguage(
        entityType: entityType,
        entityId: entityId,
        language: SupportedLanguages.defaultLanguage,
      );
      return englishTranslations[field];
    }

    return null;
  }
}
