import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course.model.dart';

/// Service for fetching course content from Supabase
/// All course content (courses, units, lessons) is PUBLIC - no auth required to view
class CourseService {
  final SupabaseClient _client;

  CourseService(this._client);

  /// Expose client for direct operations (delete, update order, etc.)
  SupabaseClient get client => _client;

  /// Fetch all active courses
  Future<List<Course>> getCourses() async {
    final response = await _client
        .from('courses')
        .select()
        .eq('is_active', true)
        .order('display_order', ascending: true);

    return (response as List).map((c) => Course.fromJson(c)).toList();
  }

  /// Fetch a single course with its units
  Future<Course?> getCourseWithUnits(String courseId) async {
    final response = await _client
        .from('courses')
        .select('''
          *,
          units:units(*)
        ''')
        .eq('id', courseId)
        .eq('is_active', true)
        .single();

    return Course.fromJson(response);
  }

  /// Fetch all units for a course
  Future<List<Unit>> getUnitsForCourse(String courseId) async {
    final response = await _client
        .from('units')
        .select()
        .eq('course_id', courseId)
        .eq('is_active', true)
        .order('display_order');

    return (response as List).map((u) => Unit.fromJson(u)).toList();
  }

  /// Fetch a single unit with its lessons
  Future<Unit?> getUnitWithLessons(String unitId) async {
    final response = await _client
        .from('units')
        .select('''
          *,
          lessons:lessons(*)
        ''')
        .eq('id', unitId)
        .eq('is_active', true)
        .single();

    return Unit.fromJson(response);
  }

  /// Fetch all lessons for a unit
  Future<List<Lesson>> getLessonsForUnit(String unitId) async {
    final response = await _client
        .from('lessons')
        .select()
        .eq('unit_id', unitId)
        .eq('is_active', true)
        .order('display_order');

    return (response as List).map((l) => Lesson.fromJson(l)).toList();
  }

  /// Fetch a single lesson with its exercise and sections
  /// Accepts either UUID or slug (with hyphens or underscores)
  Future<Lesson?> getLessonWithExercise(String identifier) async {
    final isUuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false)
        .hasMatch(identifier);

    final query = _client.from('lessons').select('''
          *,
          exercises:exercises(
            *,
            sections:sections(*)
          )
        ''');

    // Convert hyphens to underscores for database lookup (slugs stored with underscores)
    final dbSlug = identifier.replaceAll('-', '_');
    
    final response = await (isUuid 
        ? query.eq('id', identifier)
        : query.eq('slug', dbSlug))
        .eq('is_active', true)
        .single();

    return Lesson.fromJson(response);
  }

  /// Fetch full course hierarchy (Course > Units > Lessons > Exercises > Sections)
  /// Useful for Admin CMS hierarchy navigation
  Future<Course?> getFullCourseHierarchy(String courseId) async {
    final response = await _client
        .from('courses')
        .select('''
          *,
          units:units(
            *,
            lessons:lessons(
              *,
              exercises:exercises(
                *,
                sections:sections(*)
              )
            )
          )
        ''')
        .eq('id', courseId)
        .single();

    return Course.fromJson(response);
  }

  /// Search courses by title (for future search feature)
  Future<List<Course>> searchCourses(String query) async {
    final response = await _client
        .from('courses')
        .select()
        .eq('is_active', true)
        .ilike('title', '%$query%')
        .order('display_order');

    return (response as List).map((c) => Course.fromJson(c)).toList();
  }
}
