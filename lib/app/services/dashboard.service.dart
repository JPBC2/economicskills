import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/shared.dart';

/// Service for fetching dashboard data including profile, XP, and progress
class DashboardService {
  final SupabaseClient _supabase;

  DashboardService(this._supabase);

  /// Get the current user's profile
  Future<UserProfile?> getProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  /// Get the current user's XP balance
  Future<UserXP?> getUserXP() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('user_xp')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return UserXP.fromJson(response);
    } catch (e) {
      print('Error fetching user XP: $e');
      return null;
    }
  }

  /// Get dashboard statistics (completion counts)
  Future<DashboardStats> getDashboardStats() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return DashboardStats.empty();

    try {
      // Get XP data
      final xpResponse = await _supabase
          .from('user_xp')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      int totalXpEarned = 0;
      int totalXpSpent = 0;
      if (xpResponse != null) {
        totalXpEarned = xpResponse['total_xp_earned'] as int? ?? 0;
        totalXpSpent = xpResponse['total_xp_spent'] as int? ?? 0;
      }

      // Get completed lessons count from user_progress
      final progressResponse = await _supabase
          .from('user_progress')
          .select('section_id, is_completed')
          .eq('user_id', userId)
          .eq('is_completed', true);

      final completedSections = (progressResponse as List).length;

      // Get total lessons/units/courses structure for calculation
      // For now, estimate: each lesson has ~1 section on average
      final lessonsCompleted = completedSections;

      // Calculate units completed (all lessons in unit done)
      // This requires joining with course structure - simplified for now
      final unitsCompleted = (lessonsCompleted / 3).floor(); // ~3 lessons per unit
      final coursesCompleted = (unitsCompleted / 10).floor(); // ~10 units per course

      return DashboardStats(
        totalXpEarned: totalXpEarned,
        totalXpSpent: totalXpSpent,
        availableXp: totalXpEarned - totalXpSpent,
        coursesCompleted: coursesCompleted,
        unitsCompleted: unitsCompleted,
        lessonsCompleted: lessonsCompleted,
      );
    } catch (e) {
      print('Error fetching dashboard stats: $e');
      return DashboardStats.empty();
    }
  }

  /// Get courses in progress with detailed progress info
  Future<List<CourseProgress>> getCoursesInProgress() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // Get all user progress
      final progressResponse = await _supabase
          .from('user_progress')
          .select('section_id, is_completed, xp_earned')
          .eq('user_id', userId);

      final completedSectionIds = <String>{};
      final sectionXpMap = <String, int>{};
      for (final p in progressResponse as List) {
        if (p['is_completed'] == true) {
          completedSectionIds.add(p['section_id'] as String);
          sectionXpMap[p['section_id'] as String] = p['xp_earned'] as int? ?? 0;
        }
      }

      // Get user's unit unlocks
      final unlocksResponse = await _supabase
          .from('unit_unlocks')
          .select('unit_id')
          .eq('user_id', userId);

      final unlockedUnitIds = <String>{};
      for (final u in unlocksResponse as List) {
        unlockedUnitIds.add(u['unit_id'] as String);
      }

      // Get all courses with nested structure
      final coursesResponse = await _supabase
          .from('courses')
          .select('''
            id, title, display_order,
            units:units(
              id, title, display_order, is_premium, unlock_cost,
              lessons:lessons(
                id, title, display_order,
                sections:sections(id)
              )
            )
          ''')
          .eq('is_active', true)
          .order('display_order');

      final coursesInProgress = <CourseProgress>[];

      for (final courseJson in coursesResponse as List) {
        final units = courseJson['units'] as List? ?? [];
        if (units.isEmpty) continue;

        int courseTotalLessons = 0;
        int courseCompletedLessons = 0;
        final unitProgresses = <UnitProgress>[];

        for (final unitJson in units) {
          final lessons = unitJson['lessons'] as List? ?? [];
          int unitTotalLessons = lessons.length;
          int unitCompletedLessons = 0;
          final lessonProgresses = <LessonProgress>[];

          for (final lessonJson in lessons) {
            final sections = lessonJson['sections'] as List? ?? [];
            
            // A lesson is completed if all its sections are completed
            bool lessonCompleted = sections.isNotEmpty &&
                sections.every((s) => completedSectionIds.contains(s['id']));
            
            int lessonXp = 0;
            for (final s in sections) {
              lessonXp += sectionXpMap[s['id'] as String] ?? 0;
            }

            if (lessonCompleted) {
              unitCompletedLessons++;
              courseCompletedLessons++;
            }

            lessonProgresses.add(LessonProgress(
              lessonId: lessonJson['id'] as String,
              lessonTitle: lessonJson['title'] as String,
              isCompleted: lessonCompleted,
              xpEarned: lessonXp,
            ));

            courseTotalLessons++;
          }

          unitProgresses.add(UnitProgress(
            unitId: unitJson['id'] as String,
            unitTitle: unitJson['title'] as String,
            isPremium: unitJson['is_premium'] as bool? ?? false,
            isUnlocked: unlockedUnitIds.contains(unitJson['id']),
            unlockCost: unitJson['unlock_cost'] as int? ?? 150,
            completedLessons: unitCompletedLessons,
            totalLessons: unitTotalLessons,
            lessons: lessonProgresses,
          ));
        }

        // Only include courses that have been started (at least one completed lesson)
        if (courseCompletedLessons > 0) {
          coursesInProgress.add(CourseProgress(
            courseId: courseJson['id'] as String,
            courseTitle: courseJson['title'] as String,
            completedLessons: courseCompletedLessons,
            totalLessons: courseTotalLessons,
            units: unitProgresses,
          ));
        }
      }

      return coursesInProgress;
    } catch (e) {
      print('Error fetching courses in progress: $e');
      return [];
    }
  }

  /// Update profile visibility
  Future<bool> updateProfileVisibility(bool isPublic) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await _supabase
          .from('profiles')
          .update({'public_profile_visible': isPublic})
          .eq('user_id', userId);
      return true;
    } catch (e) {
      print('Error updating profile visibility: $e');
      return false;
    }
  }

  /// Get a public profile by user ID
  Future<UserProfile?> getPublicProfile(String profileUserId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', profileUserId)
          .eq('public_profile_visible', true)
          .maybeSingle();

      if (response == null) return null;
      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error fetching public profile: $e');
      return null;
    }
  }
}
