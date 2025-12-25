import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.model.dart';

/// Service for user-related operations (progress, XP, spreadsheets)
/// Requires authentication for all operations
class UserService {
  final SupabaseClient _client;

  UserService(this._client);

  String? get currentUserId => _client.auth.currentUser?.id;

  /// Check if user is authenticated
  bool get isAuthenticated => _client.auth.currentUser != null;

  /// Get current user's profile
  Future<UserProfile?> getCurrentProfile() async {
    if (!isAuthenticated) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('user_id', currentUserId!)
        .single();

    return UserProfile.fromJson(response);
  }

  /// Get current user's XP balance
  Future<UserXP?> getCurrentXP() async {
    if (!isAuthenticated) return null;

    final response = await _client
        .from('user_xp')
        .select()
        .eq('user_id', currentUserId!)
        .single();

    return UserXP.fromJson(response);
  }

  /// Get user's spreadsheet for a specific section
  Future<UserSpreadsheet?> getSpreadsheetForSection(String sectionId) async {
    if (!isAuthenticated) return null;

    final response = await _client
        .from('user_spreadsheets')
        .select()
        .eq('user_id', currentUserId!)
        .eq('section_id', sectionId)
        .maybeSingle();

    if (response == null) return null;
    return UserSpreadsheet.fromJson(response);
  }

  /// Save a new spreadsheet record
  Future<UserSpreadsheet> saveSpreadsheet({
    required String sectionId,
    required String spreadsheetId,
    required String spreadsheetUrl,
  }) async {
    final response = await _client.from('user_spreadsheets').insert({
      'user_id': currentUserId,
      'section_id': sectionId,
      'spreadsheet_id': spreadsheetId,
      'spreadsheet_url': spreadsheetUrl,
    }).select().single();

    return UserSpreadsheet.fromJson(response);
  }

  /// Mark a spreadsheet as completed
  Future<void> markSpreadsheetCompleted(String spreadsheetRecordId) async {
    await _client.from('user_spreadsheets').update({
      'is_completed': true,
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', spreadsheetRecordId);
  }

  /// Get user's progress for a section
  Future<UserProgress?> getProgressForSection(String sectionId) async {
    if (!isAuthenticated) return null;

    final response = await _client
        .from('user_progress')
        .select()
        .eq('user_id', currentUserId!)
        .eq('section_id', sectionId)
        .maybeSingle();

    if (response == null) return null;
    return UserProgress.fromJson(response);
  }

  /// Record an attempt for a section
  Future<void> recordAttempt(String sectionId) async {
    if (!isAuthenticated) return;

    final existing = await getProgressForSection(sectionId);

    if (existing == null) {
      // First attempt
      await _client.from('user_progress').insert({
        'user_id': currentUserId,
        'section_id': sectionId,
        'attempt_count': 1,
        'first_attempt_at': DateTime.now().toIso8601String(),
        'last_attempt_at': DateTime.now().toIso8601String(),
      });
    } else {
      // Increment attempts
      await _client.from('user_progress').update({
        'attempt_count': existing.attemptCount + 1,
        'last_attempt_at': DateTime.now().toIso8601String(),
      }).eq('id', existing.id);
    }
  }

  /// Mark a section as completed and award XP
  Future<void> completeSection(String sectionId, int xpReward) async {
    if (!isAuthenticated) return;

    final progress = await getProgressForSection(sectionId);

    // Only award XP if not already completed
    if (progress != null && progress.isCompleted) {
      return; // Already completed, no additional XP
    }

    // Update progress
    if (progress == null) {
      await _client.from('user_progress').insert({
        'user_id': currentUserId,
        'section_id': sectionId,
        'is_completed': true,
        'xp_earned': xpReward,
        'completed_at': DateTime.now().toIso8601String(),
      });
    } else {
      await _client.from('user_progress').update({
        'is_completed': true,
        'xp_earned': xpReward,
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', progress.id);
    }

    // Award XP
    await _client.rpc('increment_user_xp', params: {
      'user_id_param': currentUserId,
      'xp_amount': xpReward,
    });
  }

  /// Check if user has unlocked a premium unit
  Future<bool> hasUnlockedUnit(String unitId) async {
    if (!isAuthenticated) return false;

    final response = await _client
        .from('unit_unlocks')
        .select()
        .eq('user_id', currentUserId!)
        .eq('unit_id', unitId)
        .maybeSingle();

    return response != null;
  }

  /// Unlock a premium unit with XP
  Future<bool> unlockUnit(String unitId, int xpCost) async {
    if (!isAuthenticated) return false;

    final xp = await getCurrentXP();
    if (xp == null || xp.availableXp < xpCost) {
      return false; // Not enough XP
    }

    // Create unlock record
    await _client.from('unit_unlocks').insert({
      'user_id': currentUserId,
      'unit_id': unitId,
      'xp_cost': xpCost,
    });

    // Deduct XP
    await _client.from('user_xp').update({
      'total_xp_spent': xp.totalXpSpent + xpCost,
    }).eq('user_id', currentUserId!);

    return true;
  }

  /// Get all user's progress records
  Future<List<UserProgress>> getAllProgress() async {
    if (!isAuthenticated) return [];

    final response = await _client
        .from('user_progress')
        .select()
        .eq('user_id', currentUserId!);

    return (response as List).map((p) => UserProgress.fromJson(p)).toList();
  }

  /// Get completed sections count
  Future<int> getCompletedSectionsCount() async {
    if (!isAuthenticated) return 0;

    final response = await _client
        .from('user_progress')
        .select()
        .eq('user_id', currentUserId!)
        .eq('is_completed', true);

    return (response as List).length;
  }
}
