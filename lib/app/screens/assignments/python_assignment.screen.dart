import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:economicskills/app/widgets/top_nav.widget.dart';
import 'package:economicskills/app/widgets/hiding_scaffold.widget.dart';
import 'package:economicskills/app/widgets/drawer_nav.widget.dart';
import 'package:economicskills/app/widgets/python_exercise_widget.dart';
import 'package:economicskills/app/widgets/assignment_instructions_panel.dart';
import 'package:economicskills/app/res/responsive.res.dart';

/// Python Assignment Screen - Focused screen for Python exercises
class PythonAssignmentScreen extends StatefulWidget {
  final String sectionSlug;

  const PythonAssignmentScreen({super.key, required this.sectionSlug});

  @override
  State<PythonAssignmentScreen> createState() => _PythonAssignmentScreenState();
}

class _PythonAssignmentScreenState extends State<PythonAssignmentScreen> {
  Section? _section;
  String? _courseSlug;

  bool _isLoading = true;
  String? _error;

  // Progress state
  AssignmentProgress _progress = const AssignmentProgress();
  bool _showAnswer = false;

  // Panel layout
  double _leftPanelWidth = 0.35;
  bool _isLeftPanelCollapsed = false;

  // Python exercise key for accessing widget state
  final GlobalKey<PythonExerciseWidgetState> _pythonExerciseKey = GlobalKey<PythonExerciseWidgetState>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final supabase = Supabase.instance.client;

      // Parse slug (remove -python suffix)
      String slug = widget.sectionSlug;
      if (slug.endsWith('-python')) {
        slug = slug.substring(0, slug.length - '-python'.length);
      }

      // Load section by slug
      final isUuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false)
          .hasMatch(slug);

      dynamic sectionData;
      if (isUuid) {
        sectionData = await supabase
            .from('sections')
            .select('*, exercises(*)')
            .eq('id', slug)
            .single();
      } else {
        String searchTitle = slug.replaceAll('-', '%');
        sectionData = await supabase
            .from('sections')
            .select('*, exercises(*)')
            .ilike('title', '%$searchTitle%')
            .limit(1)
            .single();
      }

      final section = Section.fromJson(sectionData);

      // Load user progress for this tool if authenticated
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final progressData = await supabase
            .from('user_progress')
            .select()
            .eq('user_id', userId)
            .eq('section_id', section.id)
            .maybeSingle();

        if (progressData != null) {
          _progress = AssignmentProgress(
            isCompleted: progressData['completed_python'] ?? false,
            hintUsed: progressData['hint_used_python'] ?? false,
            answerUsed: progressData['answer_used_python'] ?? false,
            xpEarned: progressData['xp_earned_python'] ?? 0,
          );
        }
      }

      // Trace hierarchy for back navigation
      String? courseSlug;
      try {
        final exerciseId = section.exerciseId;
        final lessonData = await supabase
            .from('lessons')
            .select('unit_id')
            .eq('id', (await supabase.from('exercises').select('lesson_id').eq('id', exerciseId).single())['lesson_id'])
            .single();

        final unitData = await supabase
            .from('units')
            .select('course_id')
            .eq('id', lessonData['unit_id'])
            .single();

        final courseData = await supabase
            .from('courses')
            .select('title')
            .eq('id', unitData['course_id'])
            .single();

        courseSlug = (courseData['title'] as String).toLowerCase().replaceAll(' ', '-');
      } catch (_) {}

      setState(() {
        _section = section;
        _courseSlug = courseSlug;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProgress(int xpEarned) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || _section == null) return;

    await Supabase.instance.client.from('user_progress').upsert(
      {
        'user_id': userId,
        'section_id': _section!.id,
        'completed_python': true,
        'hint_used_python': _progress.hintUsed,
        'answer_used_python': _progress.answerUsed,
        'xp_earned_python': xpEarned,
      },
      onConflict: 'user_id,section_id',
    );

    // Award XP
    await Supabase.instance.client.from('xp_transactions').insert({
      'user_id': userId,
      'amount': xpEarned,
      'source': 'section_completion',
      'source_id': _section!.id,
      'description': 'Completed Python: ${_section!.title}',
    });
  }

  void _onProgressChanged(AssignmentProgress newProgress) {
    setState(() => _progress = newProgress);

    // Persist hint/answer usage to database
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null && _section != null) {
      Supabase.instance.client.from('user_progress').upsert(
        {
          'user_id': userId,
          'section_id': _section!.id,
          'hint_used_python': newProgress.hintUsed,
          'answer_used_python': newProgress.answerUsed,
        },
        onConflict: 'user_id,section_id',
      );
    }
  }

  void _onPythonComplete(bool passed, int xpEarned) async {
    if (passed) {
      await _saveProgress(xpEarned);
      setState(() {
        _progress = _progress.copyWith(
          isCompleted: true,
          xpEarned: xpEarned,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 900;

    if (_isLoading) {
      return Scaffold(
        appBar: const TopNav(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: const TopNav(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colorScheme.error),
              const SizedBox(height: 16),
              Text('Error loading section', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: colorScheme.error)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
                label: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    }

    if (_section == null) {
      return Scaffold(
        appBar: const TopNav(),
        body: const Center(child: Text('Section not found')),
      );
    }

    if (isWideScreen) {
      return Scaffold(
        appBar: const TopNav(),
        drawer: screenWidth > ScreenSizes.md ? null : const DrawerNav(),
        body: _buildDesktopLayout(theme, colorScheme),
      );
    }

    return HidingScaffold(
      appBar: const TopNav(),
      drawer: screenWidth > ScreenSizes.md ? null : const DrawerNav(),
      body: [_buildMobileLayout(theme, colorScheme)],
    );
  }

  Widget _buildDesktopLayout(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        // Left panel - Instructions
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _isLeftPanelCollapsed ? 48 : MediaQuery.of(context).size.width * _leftPanelWidth,
          child: _isLeftPanelCollapsed
              ? _buildCollapsedPanel(colorScheme)
              : Stack(
                  children: [
                    AssignmentInstructionsPanel(
                      section: _section!,
                      tool: 'python',
                      progress: _progress,
                      onProgressChanged: _onProgressChanged,
                      courseSlug: _courseSlug,
                      onBackPressed: () {
                        if (_courseSlug != null) {
                          context.go('/courses/$_courseSlug');
                        } else {
                          context.go('/');
                        }
                      },
                      onShowAnswer: () {
                        setState(() => _showAnswer = true);
                        _pythonExerciseKey.currentState?.reloadSolution();
                      },
                    ),
                    // Collapse button
                    Positioned(
                      top: 12,
                      right: 12,
                      child: IconButton(
                        onPressed: () => setState(() => _isLeftPanelCollapsed = true),
                        icon: const Icon(Icons.chevron_left, size: 20),
                        tooltip: 'Collapse panel',
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(32, 32),
                        ),
                      ),
                    ),
                  ],
                ),
        ),

        // Resize handle
        if (!_isLeftPanelCollapsed) _buildResizeHandle(colorScheme),

        // Right panel - Python exercise
        Expanded(
          child: _buildPythonPanel(theme, colorScheme),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(ThemeData theme, ColorScheme colorScheme) {
    final languageCode = Localizations.localeOf(context).languageCode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          TextButton.icon(
            onPressed: () {
              if (_courseSlug != null) {
                context.go('/courses/$_courseSlug');
              } else {
                context.go('/');
              }
            },
            icon: Icon(Icons.arrow_back, size: 18, color: colorScheme.primary),
            label: Text('Back', style: TextStyle(color: colorScheme.primary)),
          ),

          const SizedBox(height: 16),

          // Instructions panel content (inline)
          AssignmentInstructionsPanel(
            section: _section!,
            tool: 'python',
            progress: _progress,
            onProgressChanged: _onProgressChanged,
            onShowAnswer: () {
              setState(() => _showAnswer = true);
              _pythonExerciseKey.currentState?.reloadSolution();
            },
          ),

          const SizedBox(height: 24),

          // Sign-in prompt for unauthenticated users
          if (Supabase.instance.client.auth.currentUser == null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sign in with Google to save your progress and complete the exercise.',
                      style: TextStyle(color: Colors.blue.shade800),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ),

          // Python exercise card
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Python editor
                SizedBox(
                  height: 500,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: PythonExerciseWidget(
                      key: _pythonExerciseKey,
                      section: _section!,
                      languageCode: languageCode,
                      showAnswer: _showAnswer,
                      hintUsed: _progress.hintUsed,
                      answerUsed: _progress.answerUsed,
                      onComplete: _onPythonComplete,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedPanel(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          const SizedBox(height: 16),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() => _isLeftPanelCollapsed = false),
            tooltip: 'Expand panel',
          ),
        ],
      ),
    );
  }

  Widget _buildResizeHandle(ColorScheme colorScheme) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            final newWidth = _leftPanelWidth + details.delta.dx / MediaQuery.of(context).size.width;
            _leftPanelWidth = newWidth.clamp(0.2, 0.5);
          });
        },
        child: Container(
          width: 8,
          color: colorScheme.surfaceContainerHighest,
          child: Center(
            child: Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPythonPanel(ThemeData theme, ColorScheme colorScheme) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final isAuthenticated = Supabase.instance.client.auth.currentUser != null;

    return Container(
      color: colorScheme.surfaceContainerLowest,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sign-in prompt for unauthenticated users
          if (!isAuthenticated)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sign in with Google to save your progress and complete the exercise.',
                      style: TextStyle(color: Colors.blue.shade800),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ),
          // Python exercise widget
          Expanded(
            child: PythonExerciseWidget(
              key: _pythonExerciseKey,
              section: _section!,
              languageCode: languageCode,
              showAnswer: _showAnswer,
              hintUsed: _progress.hintUsed,
              answerUsed: _progress.answerUsed,
              onComplete: _onPythonComplete,
            ),
          ),
        ],
      ),
    );
  }
}
