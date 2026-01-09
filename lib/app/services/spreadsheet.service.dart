import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for spreadsheet operations via Edge Functions
class SpreadsheetService {
  final SupabaseClient _supabase;

  SpreadsheetService(this._supabase);

  /// Get existing spreadsheet or create a new one by copying the template
  /// Returns the user's spreadsheet (existing or newly created)
  Future<SectionSpreadsheet?> getOrCreateSpreadsheet({
    required String sectionId,
    required String userId,
  }) async {
    // First, check if user already has a spreadsheet for this section
    final existing = await getUserSpreadsheet(sectionId);
    if (existing != null) {
      return existing;
    }

    // Load section to get template spreadsheet ID and title
    final sectionData = await _supabase
        .from('sections')
        .select('template_spreadsheet_id, title')
        .eq('id', sectionId)
        .maybeSingle();

    if (sectionData == null) return null;

    final templateId = sectionData['template_spreadsheet_id'] as String?;
    if (templateId == null || templateId.isEmpty) return null;

    final sectionTitle = sectionData['title'] as String? ?? 'Exercise';

    // Copy the template spreadsheet
    try {
      final result = await copySpreadsheet(
        templateId: templateId,
        sectionId: sectionId,
        newName: '$sectionTitle - Your Copy',
      );

      return SectionSpreadsheet(
        id: sectionId,
        spreadsheetId: result.spreadsheetId,
        spreadsheetUrl: result.spreadsheetUrl,
      );
    } catch (e) {
      // If copy fails, return null
      return null;
    }
  }

  /// Copy a template spreadsheet for the current user
  /// Returns the new spreadsheet URL or throws an error
  Future<SpreadsheetResult> copySpreadsheet({
    required String templateId,
    required String sectionId,
    required String newName,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await _supabase.functions.invoke(
      'copy-spreadsheet',
      body: {
        'template_id': templateId,
        'section_id': sectionId,
        'user_id': user.id,
        'new_name': newName,
      },
    );

    if (response.status != 200) {
      final error = response.data?['error'] ?? 'Unknown error';
      throw Exception('Failed to copy spreadsheet: $error');
    }

    return SpreadsheetResult(
      spreadsheetId: response.data['spreadsheet_id'],
      spreadsheetUrl: response.data['spreadsheet_url'],
      message: response.data['message'] ?? 'Spreadsheet ready',
    );
  }

  /// Validate the user's spreadsheet against the solution
  Future<ValidationResult> validateSpreadsheet({
    required String spreadsheetId,
    required String sectionId,
    bool hintUsed = false,
    bool answerUsed = false,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await _supabase.functions.invoke(
      'validate-spreadsheet',
      body: {
        'user_spreadsheet_id': spreadsheetId,
        'section_id': sectionId,
        'user_id': user.id,
        'hint_used': hintUsed,
        'answer_used': answerUsed,
      },
    );

    if (response.status != 200) {
      final error = response.data?['error'] ?? 'Unknown error';
      throw Exception('Validation failed: $error');
    }

    return ValidationResult(
      isValid: response.data['is_valid'] ?? false,
      score: response.data['score'] ?? 0,
      totalCells: response.data['total_cells'] ?? 0,
      correctCells: response.data['correct_cells'] ?? 0,
      errors: (response.data['errors'] as List?)
              ?.map((e) => ValidationError(
                    cell: e['cell'] ?? '',
                    expected: e['expected'] ?? '',
                    actual: e['actual'] ?? '',
                  ))
              .toList() ??
          [],
      xpEarned: response.data['xp_earned'] ?? 0,
      message: response.data['message'] ?? '',
    );
  }

  /// Delete a spreadsheet and reset progress
  Future<void> deleteSpreadsheet({
    required String spreadsheetId,
    required String sectionId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await _supabase.functions.invoke(
      'delete-spreadsheet',
      body: {
        'spreadsheet_id': spreadsheetId,
        'section_id': sectionId,
        'user_id': user.id,
      },
    );

    if (response.status != 200) {
      final error = response.data?['error'] ?? 'Unknown error';
      throw Exception('Failed to delete spreadsheet: $error');
    }
  }

  /// Get user's existing spreadsheet for a section (if any)
  Future<SectionSpreadsheet?> getUserSpreadsheet(String sectionId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('user_spreadsheets')
        .select()
        .eq('user_id', user.id)
        .eq('section_id', sectionId)
        .maybeSingle();

    if (response == null) return null;

    return SectionSpreadsheet(
      id: response['id'],
      spreadsheetId: response['spreadsheet_id'],
      spreadsheetUrl: response['spreadsheet_url'],
    );
  }

  /// Get user's progress for a section
  Future<SectionProgress?> getUserProgress(String sectionId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('user_progress')
        .select()
        .eq('user_id', user.id)
        .eq('section_id', sectionId)
        .maybeSingle();

    if (response == null) return null;

    return SectionProgress(
      isCompleted: response['is_completed'] ?? false,
      attemptCount: response['attempt_count'] ?? 0,
      xpEarned: response['xp_earned'] ?? 0,
    );
  }
}

/// Result of copying a spreadsheet
class SpreadsheetResult {
  final String spreadsheetId;
  final String spreadsheetUrl;
  final String message;

  SpreadsheetResult({
    required this.spreadsheetId,
    required this.spreadsheetUrl,
    required this.message,
  });
}

/// Result of validating a spreadsheet
class ValidationResult {
  final bool isValid;
  final int score;
  final int totalCells;
  final int correctCells;
  final List<ValidationError> errors;
  final int xpEarned;
  final String message;

  ValidationResult({
    required this.isValid,
    required this.score,
    required this.totalCells,
    required this.correctCells,
    required this.errors,
    required this.xpEarned,
    required this.message,
  });
}

/// A single validation error
class ValidationError {
  final String cell;
  final String expected;
  final String actual;

  ValidationError({
    required this.cell,
    required this.expected,
    required this.actual,
  });
}

/// User's spreadsheet record for a section
class SectionSpreadsheet {
  final String id;
  final String spreadsheetId;
  final String spreadsheetUrl;

  SectionSpreadsheet({
    required this.id,
    required this.spreadsheetId,
    required this.spreadsheetUrl,
  });
}

/// User's progress on a section
class SectionProgress {
  final bool isCompleted;
  final int attemptCount;
  final int xpEarned;

  SectionProgress({
    required this.isCompleted,
    required this.attemptCount,
    required this.xpEarned,
  });
}
