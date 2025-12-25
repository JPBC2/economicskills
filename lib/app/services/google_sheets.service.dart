import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.model.dart';

/// Service for Google Sheets operations
/// 
/// This service handles:
/// - Copying template spreadsheets for students
/// - Managing spreadsheet permissions
/// - Deleting spreadsheets (for reset functionality)
/// 
/// NOTE: For production Flutter Web, Google Sheets operations should go through
/// a backend (Supabase Edge Functions or Cloud Functions) to keep service account
/// credentials secure. This implementation uses Supabase RPC calls.
class GoogleSheetsService {
  final SupabaseClient _client;

  GoogleSheetsService(this._client);

  /// Copy a template spreadsheet for a user
  /// 
  /// This calls a Supabase Edge Function that:
  /// 1. Uses service account to copy the template
  /// 2. Sets permissions (only user can access)
  /// 3. Returns the new spreadsheet ID and URL
  Future<UserSpreadsheet?> copySpreadsheet({
    required String templateSpreadsheetId,
    required String sectionId,
    required String userId,
    required String newName,
  }) async {
    try {
      // Call Supabase Edge Function to copy spreadsheet
      final response = await _client.functions.invoke(
        'copy-spreadsheet',
        body: {
          'template_id': templateSpreadsheetId,
          'section_id': sectionId,
          'user_id': userId,
          'new_name': newName,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to copy spreadsheet: ${response.data}');
      }

      final data = response.data as Map<String, dynamic>;
      
      // Save the spreadsheet record to database
      final saved = await _client.from('user_spreadsheets').insert({
        'user_id': userId,
        'section_id': sectionId,
        'spreadsheet_id': data['spreadsheet_id'],
        'spreadsheet_url': data['spreadsheet_url'],
      }).select().single();

      return UserSpreadsheet.fromJson(saved);
    } catch (e) {
      print('Error copying spreadsheet: $e');
      return null;
    }
  }

  /// Delete a user's spreadsheet (for reset functionality)
  Future<bool> deleteSpreadsheet(String spreadsheetId) async {
    try {
      final response = await _client.functions.invoke(
        'delete-spreadsheet',
        body: {
          'spreadsheet_id': spreadsheetId,
        },
      );

      return response.status == 200;
    } catch (e) {
      print('Error deleting spreadsheet: $e');
      return false;
    }
  }

  /// Reset exercise - delete current spreadsheet and create new copy
  Future<UserSpreadsheet?> resetExercise({
    required String currentSpreadsheetId,
    required String templateSpreadsheetId,
    required String sectionId,
    required String userId,
    required String newName,
  }) async {
    // Delete current spreadsheet
    await deleteSpreadsheet(currentSpreadsheetId);

    // Delete database record
    await _client
        .from('user_spreadsheets')
        .delete()
        .eq('user_id', userId)
        .eq('section_id', sectionId);

    // Reset progress (keep attempt count)
    await _client
        .from('user_progress')
        .update({'is_completed': false, 'xp_earned': 0})
        .eq('user_id', userId)
        .eq('section_id', sectionId);

    // Create new copy
    return copySpreadsheet(
      templateSpreadsheetId: templateSpreadsheetId,
      sectionId: sectionId,
      userId: userId,
      newName: newName,
    );
  }

  /// Get the embed URL for a spreadsheet
  String getEmbedUrl(String spreadsheetId) {
    return 'https://docs.google.com/spreadsheets/d/$spreadsheetId/edit?embedded=true';
  }

  /// Get the direct edit URL for a spreadsheet
  String getEditUrl(String spreadsheetId) {
    return 'https://docs.google.com/spreadsheets/d/$spreadsheetId/edit';
  }
}
