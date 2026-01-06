import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:economicskills/app/widgets/top_nav.widget.dart';
import 'package:economicskills/app/widgets/hiding_scaffold.widget.dart';
import 'package:economicskills/app/widgets/drawer_nav.widget.dart';
import 'package:economicskills/app/res/responsive.res.dart';

/// Course Detail Screen - Shows units, lessons, and exercises for a course
class CourseDetailScreen extends StatefulWidget {
  final String courseSlug;

  const CourseDetailScreen({super.key, required this.courseSlug});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  Course? _course;
  List<Unit> _units = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCourseData();
  }

  Future<void> _loadCourseData() async {
    try {
      final supabase = Supabase.instance.client;

      // Determine if slug is a UUID or a readable slug
      final isUuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false)
          .hasMatch(widget.courseSlug);

      // Load course by ID or by slug (title converted to slug)
      dynamic courseData;
      if (isUuid) {
        courseData = await supabase
            .from('courses')
            .select()
            .eq('id', widget.courseSlug)
            .single();
      } else {
        // Search by title with case-insensitive match
        final slug = widget.courseSlug.toLowerCase().replaceAll('-', ' ');
        courseData = await supabase
            .from('courses')
            .select()
            .ilike('title', '%$slug%')
            .single();
      }

      final course = Course.fromJson(courseData);

      // Load units with nested lessons, exercises, sections
      final unitsResponse = await supabase
          .from('units')
          .select('''
            *,
            lessons (
              *,
              exercises (
                *,
                sections (*)
              )
            )
          ''')
          .eq('course_id', course.id)
          .order('display_order');

      // Debug: Print what we got
      print('Units response type: ${unitsResponse.runtimeType}');
      print('Units response: $unitsResponse');

      // Ensure we have a list
      final unitsList = unitsResponse is List ? unitsResponse : [unitsResponse];

      setState(() {
        _course = course;
        _units = unitsList.map((u) => Unit.fromJson(u as Map<String, dynamic>)).toList();
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error loading course: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return HidingScaffold(
      appBar: const TopNav(),
      drawer: MediaQuery.of(context).size.width > ScreenSizes.md
          ? null
          : const DrawerNav(),
      body: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildContent(theme, colorScheme),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text('Error loading course', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_error!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/courses'),
              child: const Text('Back to Courses'),
            ),
          ],
        ),
      );
    }

    if (_course == null) {
      return const Center(child: Text('Course not found'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        TextButton.icon(
          onPressed: () => context.go('/courses'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to Courses'),
        ),
        const SizedBox(height: 16),

        // Course header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.auto_stories, size: 32, color: colorScheme.primary),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _course!.title,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_course!.description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _course!.description!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Units list
        Text(
          'Course Content',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        if (_units.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'No units available yet',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
        else
          ..._units.map((unit) => _buildUnitCard(unit, theme, colorScheme)),
      ],
    );
  }

  Widget _buildUnitCard(Unit unit, ThemeData theme, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.folder, color: colorScheme.secondary),
        ),
        title: Text(
          'Unit ${unit.displayOrder}: ${unit.title}',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: unit.description != null
            ? Text(
                unit.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        children: [
          if (unit.lessons == null || unit.lessons!.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No lessons available',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...unit.lessons!.map((lesson) => _buildLessonTile(lesson, theme, colorScheme)),
        ],
      ),
    );
  }

  Widget _buildLessonTile(Lesson lesson, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lesson row with play icon
        ListTile(
          contentPadding: const EdgeInsets.only(left: 32, right: 16),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.play_circle_filled, color: colorScheme.primary, size: 24),
          ),
          title: Text(lesson.title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          subtitle: lesson.explanationText.isNotEmpty 
              ? Text(
                  lesson.explanationText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSurfaceVariant),
          onTap: () {
            context.go('/lessons/${lesson.id}');
          },
        ),
        // Exercises under this lesson
        if (lesson.exercises != null && lesson.exercises!.isNotEmpty)
          ...lesson.exercises!.map((exercise) => _buildExerciseTile(exercise, theme, colorScheme)),
      ],
    );
  }

  Widget _buildExerciseTile(Exercise exercise, ThemeData theme, ColorScheme colorScheme) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.only(left: 56, right: 16),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(Icons.assignment, color: Colors.orange.shade700, size: 20),
      ),
      title: Text(exercise.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      subtitle: Text(
        exercise.instructions,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      children: [
        if (exercise.sections == null || exercise.sections!.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 80, right: 16, bottom: 16),
            child: Text(
              'No sections available',
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          )
        else
          ...exercise.sections!.map((section) => _buildSectionTile(section, theme, colorScheme)),
      ],
    );
  }

  Widget _buildSectionTile(Section section, ThemeData theme, ColorScheme colorScheme) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 80, right: 16),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(Icons.table_chart, color: Colors.green.shade700, size: 18),
      ),
      title: Text(section.title, style: theme.textTheme.bodySmall),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: Text('${section.xpReward} XP', style: TextStyle(fontSize: 11, color: colorScheme.onSurface)),
            backgroundColor: colorScheme.surfaceContainerHighest,
            padding: EdgeInsets.zero,
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: () {
              // Navigate using slug (title converted to URL-friendly format)
              final slug = section.title.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
              context.go('/sections/$slug');
            },
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
            child: const Text('Start', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
