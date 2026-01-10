import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:economicskills/app/widgets/top_nav.widget.dart';
import 'package:economicskills/app/widgets/hiding_scaffold.widget.dart';
import 'package:economicskills/app/widgets/drawer_nav.widget.dart';
import 'package:economicskills/app/res/responsive.res.dart';
import 'package:economicskills/app/services/webr_service.dart';

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
  Set<String> _completedSectionIds = {}; // Track completed sections for check marks
  Map<String, String> _sectionCompletedWith = {}; // Track which tool(s) completed: 'spreadsheet', 'python', 'both'
  Map<String, int> _sectionXpEarned = {}; // Track XP earned per section

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
        String searchTitle = widget.courseSlug.replaceAll('-', '%');
        courseData = await supabase
            .from('courses')
            .select()
            .ilike('title', '%$searchTitle%')
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
      final unitsList = unitsResponse;

      // Load user progress if authenticated
      Set<String> completedSections = {};
      Map<String, String> completedWith = {};
      Map<String, int> xpEarned = {};
      final user = supabase.auth.currentUser;
      if (user != null) {
        try {
          final progressResponse = await supabase
              .from('user_progress')
              .select('section_id, completed_with, xp_earned')
              .eq('user_id', user.id)
              .eq('is_completed', true);

          for (final p in progressResponse) {
            final sectionId = p['section_id'] as String;
            completedSections.add(sectionId);
            if (p['completed_with'] != null) {
              completedWith[sectionId] = p['completed_with'] as String;
            }
            if (p['xp_earned'] != null) {
              xpEarned[sectionId] = p['xp_earned'] as int;
            }
          }
                } catch (e) {
          print('Error loading user progress: $e');
        }
      }

      setState(() {
        _course = course;
        _units = unitsList.map((u) => Unit.fromJson(u as Map<String, dynamic>)).toList();
        _completedSectionIds = completedSections;
        _sectionCompletedWith = completedWith;
        _sectionXpEarned = xpEarned;
        _isLoading = false;
      });
      
      // Preload WebR if any section supports R
      final hasRContent = _units.any((unit) =>
          unit.lessons?.any((lesson) =>
              lesson.exercises?.any((exercise) =>
                  exercise.sections?.any((section) => section.supportsR) ?? false
              ) ?? false
          ) ?? false
      );
      if (hasRContent) {
        WebRService.instance.preload();
      }
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

  /// Check if a section is completed
  bool _isSectionCompleted(Section section) {
    return _completedSectionIds.contains(section.id);
  }

  /// Check if all sections in an exercise are completed
  bool _isExerciseCompleted(Exercise exercise) {
    if (exercise.sections == null || exercise.sections!.isEmpty) {
      return false;
    }
    return exercise.sections!.every((section) => _isSectionCompleted(section));
  }

  /// Check if all exercises (and their sections) under a lesson are completed
  bool _isLessonCompleted(Lesson lesson) {
    if (lesson.exercises == null || lesson.exercises!.isEmpty) {
      return false;
    }
    return lesson.exercises!.every((exercise) => _isExerciseCompleted(exercise));
  }

  /// Build a check mark icon for completed items
  /// Build XP chip with color coding based on completion status
  /// - Default: Not completed (grey)
  /// - Green: Spreadsheet assignment completed
  /// - Purple: Python assignment completed
  /// - Gold/Yellow: Both assignments completed
  Widget _buildXpChip(Section section, ColorScheme colorScheme) {
    final completedWith = _sectionCompletedWith[section.id];
    final xpEarned = _sectionXpEarned[section.id] ?? 0;

    // Calculate total possible XP (sum of both tools if both supported)
    int totalPossibleXp = 0;
    if (section.supportsSpreadsheet) {
      totalPossibleXp += section.getXpRewardForTool('spreadsheet');
    }
    if (section.supportsPython) {
      totalPossibleXp += section.getXpRewardForTool('python');
    }
    // Fallback to legacy xpReward if tool-specific not set
    if (totalPossibleXp == 0) {
      totalPossibleXp = section.xpReward;
    }

    // Determine color and text based on completion status
    Color chipColor;
    Color textColor;
    String xpText;

    if (completedWith == 'both') {
      // Both completed - gold/yellow
      chipColor = Colors.amber.shade100;
      textColor = Colors.amber.shade900;
      xpText = '$xpEarned/$totalPossibleXp XP';
    } else if (completedWith == 'spreadsheet') {
      // Spreadsheet completed - green
      chipColor = Colors.green.shade100;
      textColor = Colors.green.shade800;
      xpText = '$xpEarned/$totalPossibleXp XP';
    } else if (completedWith == 'python') {
      // Python completed - purple
      chipColor = Colors.deepPurple.shade100;
      textColor = Colors.deepPurple.shade800;
      xpText = '$xpEarned/$totalPossibleXp XP';
    } else {
      // Not completed - default
      chipColor = colorScheme.surfaceContainerHighest;
      textColor = colorScheme.onSurface;
      xpText = '$totalPossibleXp XP';
    }

    // Add tool indicators if both are supported
    List<Widget> chipContent = [
      Text(xpText, style: TextStyle(fontSize: 11, color: textColor)),
    ];

    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: chipContent,
      ),
      backgroundColor: chipColor,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildCheckMark() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.check, color: Colors.green.shade700, size: 14),
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
    final isCompleted = _isLessonCompleted(lesson);
    final isAuthenticated = Supabase.instance.client.auth.currentUser != null;

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
          title: Row(
            children: [
              Expanded(
                child: Text(lesson.title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              ),
              if (isAuthenticated && isCompleted) ...[
                const SizedBox(width: 8),
                _buildCheckMark(),
              ],
            ],
          ),
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
            // Use slug if available and not empty, otherwise fallback to ID
            // Normalize to use hyphens for SEO
            final identifier = lesson.slug.isNotEmpty 
                ? lesson.slug.replaceAll('_', '-') 
                : lesson.id;
            context.go('/lessons/$identifier');
          },
        ),
        // Exercises under this lesson
        if (lesson.exercises != null && lesson.exercises!.isNotEmpty)
          ...lesson.exercises!.map((exercise) => _buildExerciseTile(exercise, theme, colorScheme)),
      ],
    );
  }

  Widget _buildExerciseTile(Exercise exercise, ThemeData theme, ColorScheme colorScheme) {
    final isCompleted = _isExerciseCompleted(exercise);
    final isAuthenticated = Supabase.instance.client.auth.currentUser != null;

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
      title: Row(
        children: [
          Expanded(
            child: Text(exercise.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          ),
          if (isAuthenticated && isCompleted) ...[
            const SizedBox(width: 8),
            _buildCheckMark(),
          ],
        ],
      ),
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
    final isCompleted = _isSectionCompleted(section);
    final isAuthenticated = Supabase.instance.client.auth.currentUser != null;

    return ListTile(
      contentPadding: const EdgeInsets.only(left: 80, right: 16),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isCompleted ? Colors.green.shade200 : Colors.green.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          isCompleted ? Icons.check : Icons.table_chart,
          color: Colors.green.shade700,
          size: 18,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(section.title, style: theme.textTheme.bodySmall),
          ),
          if (isAuthenticated && isCompleted) ...[
            const SizedBox(width: 4),
            _buildCheckMark(),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildXpChip(section, colorScheme),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: () {
              // Navigate using slug (title converted to URL-friendly format)
              var slug = section.title.toLowerCase().replaceAll(' ', '-').replaceAll(RegExp(r'[^a-z0-9-]'), '');
              // Remove existing tool suffixes to avoid double suffixes
              if (slug.endsWith('-spreadsheet')) {
                slug = slug.substring(0, slug.length - '-spreadsheet'.length);
              } else if (slug.endsWith('-python')) {
                slug = slug.substring(0, slug.length - '-python'.length);
              }
              // Add appropriate suffix based on what the section supports
              final suffix = section.supportsSpreadsheet ? '-spreadsheet' : '-python';
              context.go('/sections/$slug$suffix');
            },
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
            child: const Text('Start', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
