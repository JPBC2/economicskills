import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course.model.dart';

/// Service for fetching course content from Supabase
/// All course content (courses, units, lessons) is PUBLIC - no auth required to view
class CourseService {
  final SupabaseClient _client;

  CourseService(this._client);

  /// Fetch all active courses
  Future<List<Course>> getCourses() async {
    final response = await _client
        .from('courses')
        .select()
        .eq('is_active', true)
        .order('display_order');

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
  /// This is the main method for displaying a lesson page
  Future<Lesson?> getLessonWithExercise(String lessonId) async {
    final response = await _client
        .from('lessons')
        .select('''
          *,
          exercises:exercises(
            *,
            sections:sections(*)
          )
        ''')
        .eq('id', lessonId)
        .eq('is_active', true)
        .single();

    return Lesson.fromJson(response);
  }

  /// Fetch full course hierarchy (Course > Units > Lessons)
  /// Useful for course detail page and navigation
  Future<Course?> getFullCourseHierarchy(String courseId) async {
    final response = await _client
        .from('courses')
        .select('''
          *,
          units:units(
            *,
            lessons:lessons(*)
          )
        ''')
        .eq('id', courseId)
        .eq('is_active', true)
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
