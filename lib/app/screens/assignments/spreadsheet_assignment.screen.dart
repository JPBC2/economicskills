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

  @override
  void initState() {
    super.initState();
    _spreadsheetService = SpreadsheetService(Supabase.instance.client);
    _loadData();
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
    final userLang = Localizations.localeOf(context).languageCode;
    final solutionUrl = _section?.getSolutionForLanguage(userLang);
    final solutionId = solutionUrl != null ? _extractSpreadsheetId(solutionUrl) : null;

    // Show solution spreadsheet if answer is requested
    final spreadsheetId = (_showAnswer && solutionId != null && solutionId.isNotEmpty)
        ? solutionId
        : _userSpreadsheet?.spreadsheetId;

    return Container(
      color: colorScheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Spreadsheet
          Expanded(
            child: spreadsheetId != null
                ? EmbeddedSpreadsheet(
                    spreadsheetId: spreadsheetId,
                    isEditable: true,
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

          // Bottom action bar
          if (Supabase.instance.client.auth.currentUser != null)
            _buildActionBar(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildSpreadsheetCard(ThemeData theme, ColorScheme colorScheme) {
    final userLang = Localizations.localeOf(context).languageCode;
    final solutionUrl = _section?.getSolutionForLanguage(userLang);
    final solutionId = solutionUrl != null ? _extractSpreadsheetId(solutionUrl) : null;

    final spreadsheetId = (_showAnswer && solutionId != null && solutionId.isNotEmpty)
        ? solutionId
        : _userSpreadsheet?.spreadsheetId;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.table_chart, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  _showAnswer ? 'Solution Spreadsheet' : 'Your Spreadsheet',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),

          // Spreadsheet iframe
          SizedBox(
            height: 400,
            child: spreadsheetId != null
                ? EmbeddedSpreadsheet(spreadsheetId: spreadsheetId, isEditable: true)
                : const Center(child: CircularProgressIndicator()),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _userSpreadsheet != null && !_isValidating ? _validateSpreadsheet : null,
                    icon: _isValidating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check),
                    label: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ),

          // Validation result
          if (_lastValidation != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _buildValidationResult(_lastValidation!, theme),
            ),
        ],
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
