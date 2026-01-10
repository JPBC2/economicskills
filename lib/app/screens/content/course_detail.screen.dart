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
  
  // Per-tool completion tracking
  Set<String> _completedSpreadsheet = {}; // Section IDs where spreadsheet is completed
  Set<String> _completedPython = {};      // Section IDs where Python is completed
  Set<String> _completedR = {};           // Section IDs where R is completed
  
  // Per-tool XP tracking
  Map<String, int> _xpEarnedSpreadsheet = {};
  Map<String, int> _xpEarnedPython = {};
  Map<String, int> _xpEarnedR = {};

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
      Set<String> completedSpreadsheet = {};
      Set<String> completedPython = {};
      Set<String> completedR = {};
      Map<String, int> xpSpreadsheet = {};
      Map<String, int> xpPython = {};
      Map<String, int> xpR = {};
      
      final user = supabase.auth.currentUser;
      if (user != null) {
        try {
          final progressResponse = await supabase
              .from('user_progress')
              .select('section_id, completed_spreadsheet, completed_python, completed_r, xp_earned_spreadsheet, xp_earned_python, xp_earned_r')
              .eq('user_id', user.id);

          for (final p in progressResponse) {
            final sectionId = p['section_id'] as String;
            
            if (p['completed_spreadsheet'] == true) {
              completedSpreadsheet.add(sectionId);
              if (p['xp_earned_spreadsheet'] != null) {
                xpSpreadsheet[sectionId] = p['xp_earned_spreadsheet'] as int;
              }
            }
            if (p['completed_python'] == true) {
              completedPython.add(sectionId);
              if (p['xp_earned_python'] != null) {
                xpPython[sectionId] = p['xp_earned_python'] as int;
              }
            }
            if (p['completed_r'] == true) {
              completedR.add(sectionId);
              if (p['xp_earned_r'] != null) {
                xpR[sectionId] = p['xp_earned_r'] as int;
              }
            }
          }
        } catch (e) {
          print('Error loading user progress: $e');
        }
      }

      setState(() {
        _course = course;
        _units = unitsList.map((u) => Unit.fromJson(u as Map<String, dynamic>)).toList();
        _completedSpreadsheet = completedSpreadsheet;
        _completedPython = completedPython;
        _completedR = completedR;
        _xpEarnedSpreadsheet = xpSpreadsheet;
        _xpEarnedPython = xpPython;
        _xpEarnedR = xpR;
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

  /// Check if a section is completed (ANY tool completed counts)
  bool _isSectionCompleted(Section section) {
    return _completedSpreadsheet.contains(section.id) ||
           _completedPython.contains(section.id) ||
           _completedR.contains(section.id);
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
    
    // Build slug for navigation
    var slug = section.title.toLowerCase().replaceAll(' ', '-').replaceAll(RegExp(r'[^a-z0-9-]'), '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(left: 80, right: 16, top: 8, bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  section.title,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              if (isAuthenticated && isCompleted)
                _buildCheckMark(),
            ],
          ),
        ),
        // Assignment rows for each supported tool
        if (section.supportsSpreadsheet)
          _buildAssignmentRow(
            section: section,
            tool: 'spreadsheet',
            slug: slug,
            icon: Icons.table_chart,
            color: Colors.green,
            label: 'Google Sheets',
            isCompleted: _completedSpreadsheet.contains(section.id),
            xpEarned: _xpEarnedSpreadsheet[section.id],
            xpPossible: section.getXpRewardForTool('spreadsheet'),
            theme: theme,
            colorScheme: colorScheme,
          ),
        if (section.supportsPython)
          _buildAssignmentRow(
            section: section,
            tool: 'python',
            slug: slug,
            icon: Icons.code,
            color: Colors.deepPurple,
            label: 'Python',
            isCompleted: _completedPython.contains(section.id),
            xpEarned: _xpEarnedPython[section.id],
            xpPossible: section.getXpRewardForTool('python'),
            theme: theme,
            colorScheme: colorScheme,
          ),
        if (section.supportsR)
          _buildAssignmentRow(
            section: section,
            tool: 'r',
            slug: slug,
            icon: Icons.analytics,
            color: Colors.blue,
            label: 'R',
            isCompleted: _completedR.contains(section.id),
            xpEarned: _xpEarnedR[section.id],
            xpPossible: section.getXpRewardForTool('r'),
            theme: theme,
            colorScheme: colorScheme,
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildAssignmentRow({
    required Section section,
    required String tool,
    required String slug,
    required IconData icon,
    required Color color,
    required String label,
    required bool isCompleted,
    required int? xpEarned,
    required int xpPossible,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    final isAuthenticated = Supabase.instance.client.auth.currentUser != null;
    final isDark = theme.brightness == Brightness.dark;

    // Adjust colors for dark theme to improve contrast
    // Python (deepPurple) needs much more lightness in dark mode
    // Google Sheets (green) needs moderate lightness increase
    
    // In dark theme, lighten the color for better contrast
    // Python (purple) needs extra lightness to be readable
    final double lightness = (tool == 'python' && isDark) ? 0.7 : (isDark ? 0.4 : 0.0);
    final displayColor = isDark ? Color.lerp(color, Colors.white, lightness)! : color;
    
    return Padding(
      padding: const EdgeInsets.only(left: 96, right: 16, top: 4, bottom: 4),
      child: Row(
        children: [
          // Tool icon
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: displayColor.withValues(alpha: isCompleted ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, size: 16, color: displayColor),
          ),
          const SizedBox(width: 8),
          // Tool label
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isCompleted ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
              ),
            ),
          ),
          // XP chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isCompleted ? displayColor.withValues(alpha: 0.15) : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isCompleted ? '${xpEarned ?? xpPossible} XP' : '$xpPossible XP',
              style: TextStyle(
                fontSize: 11,
                color: isCompleted ? displayColor : colorScheme.onSurfaceVariant,
                fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Checkmark or Start button
          if (isAuthenticated && isCompleted)
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: displayColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.check, color: displayColor, size: 14),
            )
          else
            SizedBox(
              height: 28,
              child: FilledButton.tonal(
                onPressed: () => context.go('/sections/$slug-$tool'),
                style: ButtonStyle(
                  padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 12)),
                  backgroundColor: MaterialStateProperty.all(displayColor.withValues(alpha: 0.1)),
                  foregroundColor: MaterialStateProperty.resolveWith((states) {
                    if (isDark) return displayColor;
                    
                    // In light theme:
                    if (states.contains(MaterialState.hovered)) {
                      // On hover: Make text white to contrast with dark background
                      return Colors.white; 
                    }
                    // Default: Darker text for readability
                    // User specifically requested darker green for Sheets
                    if (tool == 'spreadsheet') return Colors.green.shade900;
                    if (tool == 'python') return Colors.deepPurple.shade800;
                    if (tool == 'r') return Colors.blue.shade900;
                    return color;
                  }),
                ),
                child: Text(isCompleted ? 'Review' : 'Start', style: const TextStyle(fontSize: 11)),
              ),
            ),
        ],
      ),
    );
  }
}
