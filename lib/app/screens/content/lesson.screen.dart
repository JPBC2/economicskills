import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:shared/shared.dart' hide UserService;
import 'package:economicskills/app/services/user.service.dart';
import 'package:economicskills/app/widgets/top_nav.widget.dart';
import 'package:economicskills/app/widgets/hiding_scaffold.widget.dart';
import 'package:economicskills/app/widgets/drawer_nav.widget.dart';
import 'package:economicskills/app/res/responsive.res.dart';
import 'package:economicskills/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// Lesson Screen - PUBLIC content (text/video), PROTECTED exercises
/// 
/// - Text explanations: PUBLIC
/// - YouTube videos: PUBLIC  
/// - Google Sheets exercises: REQUIRES LOGIN
class LessonScreen extends StatefulWidget {
  final String lessonId;

  const LessonScreen({super.key, required this.lessonId});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final CourseService _courseService;
  late final UserService _userService;
  Lesson? _lesson;
  bool _isLoading = true;
  String? _error;
  YoutubePlayerController? _youtubeController;
  bool _isExplanationExpanded = false;
  bool _isExerciseExpanded = false;

  @override
  void initState() {
    super.initState();
    _courseService = CourseService(Supabase.instance.client);
    _userService = UserService(Supabase.instance.client);
    _loadLesson();
  }

  Future<void> _loadLesson() async {
    try {
      final lesson = await _courseService.getLessonWithExercise(widget.lessonId);
      setState(() {
        _lesson = lesson;
        _isLoading = false;
      });

      // Initialize YouTube player if video exists
      if (lesson?.youtubeVideoId != null) {
        _youtubeController = YoutubePlayerController.fromVideoId(
          videoId: lesson!.youtubeVideoId!,
          autoPlay: false,
          params: const YoutubePlayerParams(
            showFullscreenButton: true,
            mute: false,
          ),
        );
      }
    } catch (e) {
      print('Error loading lesson: $e'); // Debug print
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _youtubeController?.close();
    super.dispose();
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
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_lesson == null)
            _buildNotFound(theme)
          else
            _buildLessonContent(theme),
      ],
    );
  }

  Widget _buildNotFound(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Lesson not found', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            SelectableText(
              'ID: ${widget.lessonId}\nError: ${_error ?? "Unknown error"}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/courses'),
              child: const Text('Back to Courses'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonContent(ThemeData theme) {
    final lesson = _lesson!;
    final colorScheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lesson Title
              Text(
                lesson.title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),

              // YouTube Video (PUBLIC)
              if (_youtubeController != null) ...[
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: YoutubePlayer(
                      controller: _youtubeController!,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Explanation Text (PUBLIC) - Collapsible
              Card(
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  initiallyExpanded: _isExplanationExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() => _isExplanationExpanded = expanded);
                  },
                  leading: Icon(Icons.menu_book, color: colorScheme.primary),
                  title: Text(
                    'Explanation',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
                      child: SelectableText(
                        lesson.explanationText,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Source References (PUBLIC)
              if (lesson.sourceReferences != null && lesson.sourceReferences!.isNotEmpty) ...[
                Card(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.link, color: colorScheme.secondary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'References',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lesson.sourceReferences!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Exercise Section (REQUIRES LOGIN)
              if (lesson.exercises != null && lesson.exercises!.isNotEmpty) 
                _buildExerciseSection(lesson.exercises!.first, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseSection(Exercise exercise, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final isAuthenticated = _userService.isAuthenticated;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: _isExerciseExpanded,
        onExpansionChanged: (expanded) {
          setState(() => _isExerciseExpanded = expanded);
        },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.edit_document, color: colorScheme.primary),
        ),
        title: Text(
          'Exercise',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          exercise.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: !isAuthenticated 
            ? Chip(
                label: const Text('Login Required'),
                backgroundColor: colorScheme.secondaryContainer,
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.instructions,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
                const SizedBox(height: 24),
                if (isAuthenticated)
                  _buildExerciseButtons(exercise, theme)
                else
                  OutlinedButton.icon(
                    onPressed: () {
                      context.go('/login');
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Sign in to Start Exercise'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build exercise buttons based on what tools the sections support
  Widget _buildExerciseButtons(Exercise exercise, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final sections = exercise.sections ?? [];

    // Check which tools are supported across all sections
    final hasSpreadsheetSection = sections.any((s) => s.supportsSpreadsheet);
    final hasPythonSection = sections.any((s) => s.supportsPython);

    // Find the first section that supports each tool for navigation
    final spreadsheetSection = sections.cast<Section?>().firstWhere(
      (s) => s?.supportsSpreadsheet == true,
      orElse: () => null,
    );
    final pythonSection = sections.cast<Section?>().firstWhere(
      (s) => s?.supportsPython == true,
      orElse: () => null,
    );

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        if (hasSpreadsheetSection && spreadsheetSection != null)
          ElevatedButton.icon(
            onPressed: () {
              // Build slug from section title and append -spreadsheet
              final slug = spreadsheetSection.title
                  .toLowerCase()
                  .replaceAll(' ', '-')
                  .replaceAll(RegExp(r'[^a-z0-9-]'), '');
              context.go('/sections/$slug-spreadsheet');
            },
            icon: const Icon(Icons.table_chart),
            label: const Text('Start Spreadsheet Exercise'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
          ),
        if (hasPythonSection && pythonSection != null)
          ElevatedButton.icon(
            onPressed: () {
              // Build slug from section title and append -python
              final slug = pythonSection.title
                  .toLowerCase()
                  .replaceAll(' ', '-')
                  .replaceAll(RegExp(r'[^a-z0-9-]'), '');
              context.go('/sections/$slug-python');
            },
            icon: const Icon(Icons.code),
            label: const Text('Start Python Exercise'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }
}
