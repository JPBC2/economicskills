import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:economicskills/app/services/spreadsheet.service.dart';
import 'package:economicskills/app/widgets/top_nav.widget.dart';
import 'package:economicskills/app/widgets/hiding_scaffold.widget.dart';
import 'package:economicskills/app/widgets/drawer_nav.widget.dart';
import 'package:economicskills/app/widgets/embedded_spreadsheet.widget.dart';
import 'package:economicskills/app/widgets/assignment_instructions_panel.dart';
import 'package:economicskills/app/res/responsive.res.dart';
import 'package:url_launcher/url_launcher.dart';

/// Spreadsheet Assignment Screen - Focused screen for Google Sheets exercises
class SpreadsheetAssignmentScreen extends StatefulWidget {
  final String sectionSlug;

  const SpreadsheetAssignmentScreen({super.key, required this.sectionSlug});

  @override
  State<SpreadsheetAssignmentScreen> createState() => _SpreadsheetAssignmentScreenState();
}

class _SpreadsheetAssignmentScreenState extends State<SpreadsheetAssignmentScreen> {
  late final SpreadsheetService _spreadsheetService;

  Section? _section;
  Exercise? _exercise;
  SectionSpreadsheet? _userSpreadsheet;
  String? _courseSlug;

  bool _isLoading = true;
  bool _isValidating = false;
  String? _error;
  ValidationResult? _lastValidation;

  // Progress state
  AssignmentProgress _progress = const AssignmentProgress();
  bool _showAnswer = false;

  // Panel layout
  double _leftPanelWidth = 0.35;
  bool _isLeftPanelCollapsed = false;
  
  // Scroll controller for mobile spreadsheet
  final ScrollController _spreadsheetScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _spreadsheetService = SpreadsheetService(Supabase.instance.client);
    _loadData();
  }

  @override
  void dispose() {
    _spreadsheetScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final supabase = Supabase.instance.client;

      // Parse slug (remove -spreadsheet suffix)
      String slug = widget.sectionSlug;
      if (slug.endsWith('-spreadsheet')) {
        slug = slug.substring(0, slug.length - '-spreadsheet'.length);
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

      // Load exercise if available
      Exercise? exercise;
      if (sectionData['exercises'] != null) {
        final exerciseData = sectionData['exercises'];
        if (exerciseData is Map<String, dynamic>) {
          exercise = Exercise.fromJson(exerciseData);
        }
      }

      // Load user's spreadsheet if authenticated
      SectionSpreadsheet? userSpreadsheet;
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        userSpreadsheet = await _spreadsheetService.getOrCreateSpreadsheet(
          sectionId: section.id,
          userId: userId,
        );

        // Load user progress for this tool
        final progressData = await supabase
            .from('user_progress')
            .select()
            .eq('user_id', userId)
            .eq('section_id', section.id)
            .maybeSingle();

        if (progressData != null) {
          _progress = AssignmentProgress(
            isCompleted: progressData['completed_spreadsheet'] ?? false,
            hintUsed: progressData['hint_used_spreadsheet'] ?? false,
            answerUsed: progressData['answer_used_spreadsheet'] ?? false,
            xpEarned: progressData['xp_earned_spreadsheet'] ?? 0,
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
        _exercise = exercise;
        _userSpreadsheet = userSpreadsheet;
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

  Future<void> _validateSpreadsheet() async {
    final userLang = Localizations.localeOf(context).languageCode;
    final solutionUrl = _section?.getSolutionForLanguage(userLang);
    final solutionId = solutionUrl != null ? _extractSpreadsheetId(solutionUrl) : null;

    String? spreadsheetIdToValidate;
    if (_showAnswer && solutionId != null && solutionId.isNotEmpty) {
      spreadsheetIdToValidate = solutionId;
    } else if (_userSpreadsheet != null) {
      spreadsheetIdToValidate = _userSpreadsheet!.spreadsheetId;
    }

    if (spreadsheetIdToValidate == null) return;

    setState(() {
      _isValidating = true;
      _lastValidation = null;
    });

    try {
      final result = await _spreadsheetService.validateSpreadsheet(
        spreadsheetId: spreadsheetIdToValidate,
        sectionId: _section!.id,
        hintUsed: _progress.hintUsed,
        answerUsed: _progress.answerUsed,
      );

      setState(() => _lastValidation = result);

      if (result.isValid) {
        await _saveProgress(result.xpEarned);
        setState(() {
          _progress = _progress.copyWith(
            isCompleted: true,
            xpEarned: result.xpEarned,
          );
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Completed! You earned ${result.xpEarned} XP!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isValidating = false);
    }
  }

  Future<void> _saveProgress(int xpEarned) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || _section == null) return;

    await Supabase.instance.client.from('user_progress').upsert(
      {
        'user_id': userId,
        'section_id': _section!.id,
        'completed_spreadsheet': true,
        'hint_used_spreadsheet': _progress.hintUsed,
        'answer_used_spreadsheet': _progress.answerUsed,
        'xp_earned_spreadsheet': xpEarned,
      },
      onConflict: 'user_id,section_id',
    );

    // Award XP
    await Supabase.instance.client.from('xp_transactions').insert({
      'user_id': userId,
      'amount': xpEarned,
      'source': 'section_completion',
      'source_id': _section!.id,
      'description': 'Completed spreadsheet: ${_section!.title}',
    });
  }

  Future<void> _resetSpreadsheet() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Spreadsheet?'),
        content: const Text('This will replace your current work with a fresh copy of the template. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (shouldReset != true || _section == null || _userSpreadsheet == null) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // Delete the existing spreadsheet first
      await _spreadsheetService.deleteSpreadsheet(
        spreadsheetId: _userSpreadsheet!.spreadsheetId,
        sectionId: _section!.id,
      );

      // Create a new spreadsheet from the template
      final newSpreadsheet = await _spreadsheetService.getOrCreateSpreadsheet(
        sectionId: _section!.id,
        userId: user.id,
      );

      if (newSpreadsheet != null) {
        setState(() {
          _userSpreadsheet = newSpreadsheet;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Spreadsheet reset to original'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resetting: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String? _extractSpreadsheetId(String? url) {
    if (url == null) return null;
    final regex = RegExp(r'/spreadsheets/d/([a-zA-Z0-9-_]+)');
    final match = regex.firstMatch(url);
    return match?.group(1);
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
          'hint_used_spreadsheet': newProgress.hintUsed,
          'answer_used_spreadsheet': newProgress.answerUsed,
        },
        onConflict: 'user_id,section_id',
      );
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
              : AssignmentInstructionsPanel(
                  section: _section!,
                  tool: 'spreadsheet',
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
                  onShowAnswer: () => setState(() => _showAnswer = true),
                ),
        ),

        // Resize handle
        _buildResizeHandle(colorScheme),

        // Right panel - Spreadsheet
        Expanded(
          child: _buildSpreadsheetPanel(theme, colorScheme),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(ThemeData theme, ColorScheme colorScheme) {
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
            tool: 'spreadsheet',
            progress: _progress,
            onProgressChanged: _onProgressChanged,
            onShowAnswer: () => setState(() => _showAnswer = true),
          ),

          const SizedBox(height: 24),

          // Spreadsheet card
          _buildSpreadsheetCard(theme, colorScheme),
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

  Widget _buildSpreadsheetPanel(ThemeData theme, ColorScheme colorScheme) {
    final isAuthenticated = Supabase.instance.client.auth.currentUser != null;
    final userLang = Localizations.localeOf(context).languageCode;
    final solutionUrl = _section?.getSolutionForLanguage(userLang);
    final solutionId = solutionUrl != null ? _extractSpreadsheetId(solutionUrl) : null;

    // Show solution spreadsheet if answer is requested, otherwise user's copy or template
    final spreadsheetId = (_showAnswer && solutionId != null && solutionId.isNotEmpty)
        ? solutionId
        : _userSpreadsheet?.spreadsheetId ?? _section?.templateSpreadsheetId;

    return Container(
      color: colorScheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sign-in prompt for unauthenticated users
          if (!isAuthenticated)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(8),
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
                      'Sign in with Google to get your own copy of this spreadsheet and complete the exercise.',
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
          // Spreadsheet
          Expanded(
            child: spreadsheetId != null
                ? EmbeddedSpreadsheet(
                    spreadsheetId: spreadsheetId,
                    isEditable: _userSpreadsheet != null,
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text('Preparing your spreadsheet...', style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  ),
          ),

          // Bottom action bar (only for authenticated users)
          if (isAuthenticated)
            _buildActionBar(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildSpreadsheetCard(ThemeData theme, ColorScheme colorScheme) {
    final isAuthenticated = Supabase.instance.client.auth.currentUser != null;
    final userLang = Localizations.localeOf(context).languageCode;
    final solutionUrl = _section?.getSolutionForLanguage(userLang);
    final solutionId = solutionUrl != null ? _extractSpreadsheetId(solutionUrl) : null;

    // If answer is shown and we have a solution, show solution spreadsheet
    String? spreadsheetIdToShow;
    bool isEditable = false;

    if (_showAnswer && solutionId != null && solutionId.isNotEmpty) {
      spreadsheetIdToShow = solutionId;
      isEditable = true;
    } else {
      spreadsheetIdToShow = _userSpreadsheet?.spreadsheetId ?? _section?.templateSpreadsheetId;
      isEditable = _userSpreadsheet != null;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner when viewing solution
            if (_showAnswer && solutionId != null && solutionId.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.visibility, size: 18, color: Colors.deepPurple.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Viewing Solution Spreadsheet',
                      style: TextStyle(
                        color: Colors.deepPurple.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            // Sign-in prompt for unauthenticated users
            if (!isAuthenticated)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
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
                        'Sign in with Google to get your own copy and complete the exercise.',
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
            // Horizontally scrollable container with minimum width to force desktop view
            SingleChildScrollView(
              controller: _spreadsheetScrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 900, // Minimum width to force Google Sheets desktop view
                height: 600,
                child: spreadsheetIdToShow != null
                    ? EmbeddedSpreadsheet(
                        spreadsheetId: spreadsheetIdToShow,
                        isEditable: isEditable,
                      )
                    : const Center(child: Text('No spreadsheet available')),
              ),
            ),
            const SizedBox(height: 8),
            // Scroll buttons row
            Row(
              children: [
                // Scroll left button - full width responsive
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      _spreadsheetScrollController.animateTo(
                        (_spreadsheetScrollController.offset - 200).clamp(0, _spreadsheetScrollController.position.maxScrollExtent),
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.surface,
                      foregroundColor: colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.pressed)) return colorScheme.onSurface.withAlpha(31);
                        if (states.contains(WidgetState.hovered)) return colorScheme.onSurface.withAlpha(20);
                        return null;
                      }),
                    ),
                    child: const Icon(Icons.chevron_left, size: 32),
                  ),
                ),
                const SizedBox(width: 12),
                // Scroll right button - full width responsive
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      _spreadsheetScrollController.animateTo(
                        (_spreadsheetScrollController.offset + 200).clamp(0, _spreadsheetScrollController.position.maxScrollExtent),
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.surface,
                      foregroundColor: colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.pressed)) return colorScheme.onSurface.withAlpha(31);
                        if (states.contains(WidgetState.hovered)) return colorScheme.onSurface.withAlpha(20);
                        return null;
                      }),
                    ),
                    child: const Icon(Icons.chevron_right, size: 32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action buttons row
            if (isAuthenticated)
              Row(
                children: [
                  // Reset button
                  IconButton(
                    onPressed: _userSpreadsheet != null ? _resetSpreadsheet : null,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Reset to original',
                    style: IconButton.styleFrom(foregroundColor: colorScheme.error),
                  ),
                  const SizedBox(width: 8),
                  // Open in new tab
                  OutlinedButton.icon(
                    onPressed: () async {
                      final id = _userSpreadsheet?.spreadsheetId ?? _section?.templateSpreadsheetId;
                      if (id != null) {
                        final uri = Uri.parse('https://docs.google.com/spreadsheets/d/$id/edit');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      }
                    },
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open in new tab'),
                  ),
                  const Spacer(),
                  // Submit button
                  FilledButton.icon(
                    onPressed: _userSpreadsheet != null && !_isValidating ? _validateSpreadsheet : null,
                    icon: _isValidating
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle),
                    label: const Text('Submit answer'),
                  ),
                ],
              ),
            // Completed status (shown after buttons on mobile)
            if (_progress.isCompleted) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Completed! +${_progress.xpEarned} XP',
                      style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
            // Validation result (shown after buttons on mobile)
            if (_lastValidation != null) ...[
              const SizedBox(height: 16),
              _buildValidationResult(_lastValidation!, theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          if (_userSpreadsheet == null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 8),
                  Text('Preparing...', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _userSpreadsheet != null && !_isValidating ? _validateSpreadsheet : null,
            icon: _isValidating
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check),
            label: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationResult(ValidationResult result, ThemeData theme) {
    final isSuccess = result.score >= 100;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSuccess ? Colors.green.shade200 : Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.warning,
                color: isSuccess ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.message,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isSuccess ? Colors.green.shade800 : Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: result.score / 100,
            backgroundColor: Colors.grey.shade300,
            color: isSuccess ? Colors.green : Colors.orange,
          ),
          const SizedBox(height: 8),
          Text(
            '${result.correctCells}/${result.totalCells} correct (${result.score}%)',
            style: TextStyle(color: isSuccess ? Colors.green.shade900 : Colors.orange.shade900),
          ),
        ],
      ),
    );
  }
}
