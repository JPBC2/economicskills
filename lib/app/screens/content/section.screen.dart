import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:economicskills/app/services/spreadsheet.service.dart';
import 'package:economicskills/app/widgets/top_nav.widget.dart';
import 'package:economicskills/app/widgets/hiding_scaffold.widget.dart';
import 'package:economicskills/app/widgets/drawer_nav.widget.dart';
import 'package:economicskills/app/widgets/embedded_spreadsheet.widget.dart';
import 'package:economicskills/app/widgets/python_exercise_widget.dart';
import 'package:economicskills/app/res/responsive.res.dart';

/// Section Screen - DataCamp-style split-screen exercise with embedded spreadsheet
class SectionScreen extends StatefulWidget {
  final String sectionSlug;

  const SectionScreen({super.key, required this.sectionSlug});

  @override
  State<SectionScreen> createState() => _SectionScreenState();
}

class _SectionScreenState extends State<SectionScreen> {
  late final SpreadsheetService _spreadsheetService;
  final TextEditingController _spreadsheetIdController = TextEditingController();
  
  Section? _section;
  Exercise? _exercise;
  SectionSpreadsheet? _userSpreadsheet;
  SectionProgress? _progress;
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isValidating = false;
  bool _isResetting = false;
  String? _error;
  ValidationResult? _lastValidation;
  
  // Panel layout state
  double _leftPanelWidth = 0.35;
  bool _isLeftPanelCollapsed = false;
  bool _showHint = false;
  bool _showAnswer = false;  // Track if user has requested the solution
  bool _exerciseExpanded = true;
  bool _instructionsExpanded = true;

  // Exercise tool selection
  String _selectedTool = 'spreadsheet'; // 'spreadsheet' or 'python'

  // Scroll controller for mobile spreadsheet
  final ScrollController _spreadsheetScrollController = ScrollController();
  
  // Key to access PythonExerciseWidget for solution reload
  final GlobalKey<PythonExerciseWidgetState> _pythonExerciseKey = GlobalKey<PythonExerciseWidgetState>();

  @override
  void initState() {
    super.initState();
    _spreadsheetService = SpreadsheetService(Supabase.instance.client);
    _loadData();
  }

  @override
  void dispose() {
    _spreadsheetIdController.dispose();
    _spreadsheetScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final supabase = Supabase.instance.client;
      // Determine if slug is a UUID or a readable slug
      final isUuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false)
          .hasMatch(widget.sectionSlug);

      // Load section with exercise details by ID or title
      dynamic sectionData;
      if (isUuid) {
        sectionData = await supabase
            .from('sections')
            .select('*, exercises(*)')
            .eq('id', widget.sectionSlug)
            .single();
      } else {
        // Search by title with case-insensitive match (underscores become spaces/dots)
        // Handle slugs like "1-annual-nominal-dividends-per-share" matching "1. Annual nominal dividends per share."
        String searchTitle = widget.sectionSlug.replaceAll('-', '%');
        sectionData = await supabase
            .from('sections')
            .select('*, exercises(*)')
            .ilike('title', '%$searchTitle%')
            .limit(1)
            .single();
      }

      final section = Section.fromJson(sectionData);
      Exercise? exercise;
      if (sectionData['exercises'] != null) {
        final exerciseData = sectionData['exercises'];
        if (exerciseData is Map<String, dynamic>) {
          exercise = Exercise.fromJson(exerciseData);
        }
      }

      setState(() {
        _section = section;
        _exercise = exercise;
      });

      // Auto-create spreadsheet copy if authenticated
      final user = supabase.auth.currentUser;
      // Get user's language from app locale
      final userLang = mounted ? Localizations.localeOf(context).languageCode : 'en';
      final templateId = section.getTemplateForLanguage(userLang);
      if (user != null && templateId != null) {
        await _autoCreateSpreadsheet(user.id, section, templateId);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Auto-create a fresh spreadsheet copy using Edge Function
  Future<void> _autoCreateSpreadsheet(String userId, Section section, String templateId) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Get user's Google OAuth access token from session
      final session = supabase.auth.currentSession;
      final userAccessToken = session?.providerToken;
      
      if (userAccessToken == null) {
        debugPrint('No provider token available - user needs to re-login with Google');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please sign out and sign in again with Google to enable spreadsheet features'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(label: 'Sign Out', onPressed: () => supabase.auth.signOut()),
          ),
        );
        return;
      }
      
      // Call the Edge Function to create/get spreadsheet using user's token
      final response = await supabase.functions.invoke(
        'copy-spreadsheet',
        body: {
          'template_id': templateId, // Use language-specific template
          'section_id': section.id,
          'user_id': userId,
          'new_name': 'Exercise: ${section.title}',
          'user_access_token': userAccessToken,
          'fresh': true, // Always create fresh copy
        },
      );

      if (response.status == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final spreadsheetId = data['spreadsheet_id'] as String?;
        final spreadsheetUrl = data['spreadsheet_url'] as String?;

        if (spreadsheetId != null) {
          setState(() {
            _userSpreadsheet = SectionSpreadsheet(
              id: '',
              spreadsheetId: spreadsheetId,
              spreadsheetUrl: spreadsheetUrl ?? '',
            );
            _spreadsheetIdController.text = spreadsheetId;
          });
        }
      }

      // Also load progress
      final progress = await _spreadsheetService.getUserProgress(section.id);
      if (mounted) {
        setState(() {
          _progress = progress;
        });
      }
    } catch (e) {
      debugPrint('Error auto-creating spreadsheet: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create spreadsheet: ${e.toString().replaceAll('Exception:', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
            action: SnackBarAction(label: 'Retry', onPressed: () => _autoCreateSpreadsheet(userId, section, templateId)),
          ),
        );
      }
    }
  }

  /// Reset spreadsheet to original template (fresh copy)
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

    if (shouldReset != true || _section == null) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isResetting = true);

    try {
      // Call auto-create with fresh: true to delete old and create new
      final userLang = Localizations.localeOf(context).languageCode;
      final templateId = _section!.getTemplateForLanguage(userLang);
      if (templateId == null) return;
      await _autoCreateSpreadsheet(user.id, _section!, templateId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Spreadsheet reset to original'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResetting = false);
      }
    }
  }

  Future<void> _openCopyLink() async {
    if (_section?.templateSpreadsheetId == null) return;
    
    final copyUrl = 'https://docs.google.com/spreadsheets/d/${_section!.templateSpreadsheetId}/copy';
    final uri = Uri.parse(copyUrl);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Extracts spreadsheet ID from a Google Sheets URL or returns the input if already an ID
  String? _extractSpreadsheetId(String input) {
    if (input.isEmpty) return null;
    
    // Check if it's a URL containing the spreadsheet ID
    final regex = RegExp(r'/spreadsheets/d/([a-zA-Z0-9-_]+)');
    final match = regex.firstMatch(input);
    if (match != null) {
      return match.group(1);
    }
    
    // If no URL pattern found, assume it's already an ID
    return input;
  }

  Future<void> _saveSpreadsheetId() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      context.go('/login');
      return;
    }

    final input = _spreadsheetIdController.text.trim();
    final spreadsheetId = _extractSpreadsheetId(input);
    if (spreadsheetId == null || spreadsheetId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your spreadsheet URL or ID'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Save to database
      await Supabase.instance.client
          .from('user_spreadsheets')
          .upsert({
            'user_id': user.id,
            'section_id': _section!.id,
            'spreadsheet_id': spreadsheetId,
            'spreadsheet_url': 'https://docs.google.com/spreadsheets/d/$spreadsheetId/edit',
          }, onConflict: 'user_id,section_id');

      setState(() {
        _userSpreadsheet = SectionSpreadsheet(
          id: '',
          spreadsheetId: spreadsheetId,
          spreadsheetUrl: 'https://docs.google.com/spreadsheets/d/$spreadsheetId/edit',
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Spreadsheet saved! You can now submit for validation.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _validateSpreadsheet() async {
    if (_userSpreadsheet == null) return;

    setState(() {
      _isValidating = true;
      _lastValidation = null;
    });

    try {
      final result = await _spreadsheetService.validateSpreadsheet(
        spreadsheetId: _userSpreadsheet!.spreadsheetId,
        sectionId: _section!.id,
        hintUsed: _showHint,
      );

      setState(() {
        _lastValidation = result;
        if (result.isValid) {
          _progress = SectionProgress(
            isCompleted: true,
            attemptCount: (_progress?.attemptCount ?? 0) + 1,
            xpEarned: result.xpEarned,
          );
        }
      });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 900;

    // For split-screen layout, use regular Scaffold (not HidingScaffold)
    // because CustomScrollView doesn't provide bounded height for Row
    if (isWideScreen) {
      return Scaffold(
        appBar: const TopNav(),
        drawer: screenWidth > ScreenSizes.md ? null : const DrawerNav(),
        body: _buildBody(theme, colorScheme, isWideScreen),
      );
    }

    // For mobile, use HidingScaffold
    return HidingScaffold(
      appBar: const TopNav(),
      drawer: screenWidth > ScreenSizes.md ? null : const DrawerNav(),
      body: [_buildBody(theme, colorScheme, isWideScreen)],
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colorScheme, bool isWideScreen) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _section == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text('Section not found', style: theme.textTheme.titleLarge),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/courses'),
              child: const Text('Back to Courses'),
            ),
          ],
        ),
      );
    }

    // Split-screen layout for wide screens, stacked for narrow
    if (isWideScreen) {
      final screenWidth = MediaQuery.of(context).size.width;
      final leftWidth = _isLeftPanelCollapsed ? 0.0 : screenWidth * _leftPanelWidth;
      
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Collapsed expand button
          if (_isLeftPanelCollapsed)
            GestureDetector(
              onTap: () => setState(() => _isLeftPanelCollapsed = false),
              child: Container(
                width: 24,
                color: colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Icon(Icons.chevron_right, size: 20, color: colorScheme.onSurface),
                ),
              ),
            ),
          // Left panel - Instructions
          if (!_isLeftPanelCollapsed)
            SizedBox(
              width: leftWidth,
              child: Stack(
                children: [
                  _buildInstructionsPanel(theme, colorScheme),
                  // Collapse button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: () => setState(() => _isLeftPanelCollapsed = true),
                      icon: const Icon(Icons.chevron_left, size: 20),
                      tooltip: 'Collapse panel',
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Resizable divider
          if (!_isLeftPanelCollapsed)
            GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  final newWidth = (_leftPanelWidth * screenWidth + details.delta.dx) / screenWidth;
                  _leftPanelWidth = newWidth.clamp(0.2, 0.5);
                });
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: Container(
                  width: 6,
                  color: colorScheme.outlineVariant,
                  child: Center(
                    child: Container(
                      width: 2,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.outline,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Right panel - Spreadsheet
          Expanded(
            child: _buildSpreadsheetPanel(theme, colorScheme),
          ),
        ],
      );
    } else {
      // Stacked layout for mobile - show instructions then spreadsheet
      final isAuthenticated = Supabase.instance.client.auth.currentUser != null;
      final isCompleted = _progress?.isCompleted ?? false;
      
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            TextButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back'),
            ),
            const SizedBox(height: 16),

            // Completed status
            if (isCompleted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 16),
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
                      'Completed! +${_progress!.xpEarned} XP',
                      style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

            // Exercise section (collapsible)
            _buildCollapsibleSection(
              title: 'Exercise',
              isExpanded: _exerciseExpanded,
              onToggle: () => setState(() => _exerciseExpanded = !_exerciseExpanded),
              theme: theme,
              colorScheme: colorScheme,
              trailing: null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _section!.title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (_section!.explanation != null && _section!.explanation!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _section!.explanation!,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.6, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Instructions section (collapsible)
            if (_section!.instructions != null && _section!.instructions!.isNotEmpty)
              _buildCollapsibleSection(
                title: 'Instructions',
                isExpanded: _instructionsExpanded,
                onToggle: () => setState(() => _instructionsExpanded = !_instructionsExpanded),
                theme: theme,
                colorScheme: colorScheme,
                trailing: _section!.xpReward > 0
                    ? Chip(
                        avatar: Icon(Icons.star, size: 14, color: Colors.amber.shade600),
                        label: Text(
                          _showAnswer 
                            ? '${(_section!.xpReward * 0.5).floor()} XP'
                            : _showHint 
                              ? '${(_section!.xpReward * 0.7).floor()} XP'
                              : '${_section!.xpReward} XP',
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                        ),
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                        visualDensity: VisualDensity.compact,
                      )
                    : null,
                child: Text(
                  _section!.instructions!,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6, color: colorScheme.onSurface),
                ),
              ),

            // Take a hint button
            if (_section!.hint != null && _section!.hint!.isNotEmpty && isAuthenticated) ...[
              const SizedBox(height: 24),
              _buildHintSection(theme, colorScheme),
            ],

            // Show answer button (below hint)
            if (isAuthenticated) ...[
              const SizedBox(height: 12),
              _buildAnswerSection(theme, colorScheme),
            ],

            const SizedBox(height: 24),
            
            // Spreadsheet
            _buildSpreadsheetCard(theme, colorScheme),
          ],
        ),
      );
    }
  }

  Widget _buildInstructionsPanel(ThemeData theme, ColorScheme colorScheme) {
    final isAuthenticated = Supabase.instance.client.auth.currentUser != null;
    final isCompleted = _progress?.isCompleted ?? false;

    return Container(
      color: colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            OutlinedButton.icon(
              onPressed: () {
                debugPrint('Back button pressed - navigating to /courses');
                context.go('/courses');
              },
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back'),
            ),
            const SizedBox(height: 16),

            // Completed status
            if (isCompleted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 16),
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
                      'Completed! +${_progress!.xpEarned} XP',
                      style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

            // Exercise section (collapsible)
            _buildCollapsibleSection(
              title: 'Exercise',
              isExpanded: _exerciseExpanded,
              onToggle: () => setState(() => _exerciseExpanded = !_exerciseExpanded),
              theme: theme,
              colorScheme: colorScheme,
              trailing: null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _section!.title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (_section!.explanation != null && _section!.explanation!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _section!.explanation!,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.6, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Instructions section (collapsible)
            if (_section!.instructions != null && _section!.instructions!.isNotEmpty)
              _buildCollapsibleSection(
                title: 'Instructions',
                isExpanded: _instructionsExpanded,
                onToggle: () => setState(() => _instructionsExpanded = !_instructionsExpanded),
                theme: theme,
                colorScheme: colorScheme,
                trailing: _section!.xpReward > 0
                    ? Chip(
                        avatar: Icon(Icons.star, size: 14, color: Colors.amber.shade600),
                        label: Text(
                          _showAnswer 
                            ? '${(_section!.xpReward * 0.5).floor()} XP'
                            : _showHint 
                              ? '${(_section!.xpReward * 0.7).floor()} XP'
                              : '${_section!.xpReward} XP',
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                        ),
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                        visualDensity: VisualDensity.compact,
                      )
                    : null,
                child: Text(
                  _section!.instructions!,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6, color: colorScheme.onSurface),
                ),
              ),

            // Take a hint button
            if (_section!.hint != null && _section!.hint!.isNotEmpty && isAuthenticated) ...[
              const SizedBox(height: 24),
              _buildHintSection(theme, colorScheme),
            ],

            // Show answer button (below hint)
            if (isAuthenticated) ...[
              const SizedBox(height: 12),
              _buildAnswerSection(theme, colorScheme),
            ],

            // Authentication required message
            if (!isAuthenticated)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: colorScheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sign in to save your progress',
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                    FilledButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ),

            // Validation result
            if (_lastValidation != null) ...[
              const SizedBox(height: 24),
              _buildValidationResult(theme, colorScheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpreadsheetPanel(ThemeData theme, ColorScheme colorScheme) {
    final isAuthenticated = Supabase.instance.client.auth.currentUser != null;
    final supportsSpreadsheet = _section?.supportsSpreadsheet ?? true;
    final supportsPython = _section?.supportsPython ?? false;
    final showTabs = supportsSpreadsheet && supportsPython;

    // Auto-select the only available tool if only one is supported
    final String effectiveTool;
    if (!supportsSpreadsheet && supportsPython) {
      effectiveTool = 'python';
    } else if (supportsSpreadsheet && !supportsPython) {
      effectiveTool = 'spreadsheet';
    } else {
      effectiveTool = _selectedTool;
    }

    return Container(
      color: colorScheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tool selector tabs (if both tools are supported)
          if (showTabs)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
              ),
              child: Row(
                children: [
                  _buildToolTab(
                    icon: Icons.table_chart,
                    label: 'Google Sheets',
                    isSelected: effectiveTool == 'spreadsheet',
                    onTap: () => setState(() => _selectedTool = 'spreadsheet'),
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(width: 8),
                  _buildToolTab(
                    icon: Icons.code,
                    label: 'Python',
                    isSelected: effectiveTool == 'python',
                    onTap: () => setState(() => _selectedTool = 'python'),
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            ),

          // Exercise content area
          Expanded(
            child: effectiveTool == 'python' && supportsPython
                ? _buildPythonExercise(theme, colorScheme)
                : _buildSpreadsheetExercise(theme, colorScheme),
          ),

          // Bottom action bar (only for spreadsheet)
          if (isAuthenticated && effectiveTool == 'spreadsheet')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
              ),
              child: Row(
                children: [
                  // Loading indicator when spreadsheet is being prepared
                  if (_userSpreadsheet == null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          const SizedBox(width: 8),
                          Text('Preparing...', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  // Reset button
                  IconButton(
                    onPressed: _userSpreadsheet != null && !_isResetting ? _resetSpreadsheet : null,
                    icon: _isResetting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh),
                    tooltip: 'Reset to original',
                    style: IconButton.styleFrom(
                      foregroundColor: colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Open in new tab button
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
            ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_section!.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            if (_exercise != null) ...[
              const SizedBox(height: 12),
              Text(_exercise!.instructions),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpreadsheetCard(ThemeData theme, ColorScheme colorScheme) {
    final isAuthenticated = Supabase.instance.client.auth.currentUser != null;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Horizontally scrollable container with minimum width to force desktop view
            SingleChildScrollView(
              controller: _spreadsheetScrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 900, // Minimum width to force Google Sheets desktop view
                height: 600,
                child: _section?.templateSpreadsheetId != null
                    ? EmbeddedSpreadsheet(
                        spreadsheetId: _userSpreadsheet?.spreadsheetId ?? _section!.templateSpreadsheetId!,
                        isEditable: _userSpreadsheet != null,
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
                        if (states.contains(WidgetState.pressed)) return colorScheme.onSurface.withOpacity(0.12);
                        if (states.contains(WidgetState.hovered)) return colorScheme.onSurface.withOpacity(0.08);
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
                        if (states.contains(WidgetState.pressed)) return colorScheme.onSurface.withOpacity(0.12);
                        if (states.contains(WidgetState.hovered)) return colorScheme.onSurface.withOpacity(0.08);
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
                    onPressed: _userSpreadsheet != null && !_isResetting ? _resetSpreadsheet : null,
                    icon: _isResetting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh),
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
            if (_progress?.isCompleted ?? false) ...[
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
                      'Completed! +${_progress!.xpEarned} XP',
                      style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
            // Validation result (shown after buttons on mobile)
            if (_lastValidation != null) ...[
              const SizedBox(height: 16),
              _buildValidationResult(theme, colorScheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildValidationResult(ThemeData theme, ColorScheme colorScheme) {
    final result = _lastValidation!;
    final isSuccess = result.isValid;

    return Container(
      padding: const EdgeInsets.all(16),
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

  Widget _buildHintSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hint button
        OutlinedButton.icon(
          onPressed: () => setState(() => _showHint = !_showHint),
          icon: Icon(_showHint ? Icons.lightbulb : Icons.lightbulb_outline, 
                     color: Colors.amber.shade700),
          label: Text('Take a hint (-30% XP)', style: TextStyle(color: colorScheme.onSurface)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: colorScheme.outline),
          ),
        ),
        // Hint content (collapsible)
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // XP penalty warning (commented out - info now in button)
                // Row(
                //   children: [
                //     Icon(Icons.warning_amber, size: 18, color: Colors.orange.shade700),
                //     const SizedBox(width: 8),
                //     Text(
                //       'Using hints reduces XP by 30%',
                //       style: TextStyle(
                //         color: Colors.orange.shade800,
                //         fontWeight: FontWeight.w600,
                //         fontSize: 13,
                //       ),
                //     ),
                //   ],
                // ),
                // const SizedBox(height: 12),
                // const Divider(height: 1),
                // const SizedBox(height: 12),
                // Hint text
                Text(
                  _section!.hint!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
          ),
          crossFadeState: _showHint ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildAnswerSection(ThemeData theme, ColorScheme colorScheme) {
    final userLang = Localizations.localeOf(context).languageCode;
    final solutionSpreadsheetUrl = _section?.getSolutionForLanguage(userLang);
    final hasSolution = (solutionSpreadsheetUrl != null && solutionSpreadsheetUrl.isNotEmpty) ||
                        (_section?.pythonSolutionCode != null && _section!.pythonSolutionCode!.isNotEmpty);
    
    if (!hasSolution) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show answer button
        OutlinedButton.icon(
          onPressed: () {
            if (_showAnswer) {
              // Already showing answer - reload the solution
              _pythonExerciseKey.currentState?.reloadSolution();
            } else {
              // First time showing answer
              setState(() => _showAnswer = true);
            }
          },
          icon: Icon(_showAnswer ? Icons.refresh : Icons.visibility_outlined, 
                     color: Colors.deepPurple.shade600),
          label: Text(
            _showAnswer ? 'Reload solution (-50% XP)' : 'Show answer (-50% XP)', 
            style: TextStyle(color: colorScheme.onSurface)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: colorScheme.outline),
          ),
        ),
        // Answer content (collapsible) - only for spreadsheet mode
        if (solutionSpreadsheetUrl != null && solutionSpreadsheetUrl.isNotEmpty)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.deepPurple.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.table_chart, size: 18, color: Colors.deepPurple.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Solution Spreadsheet',
                        style: TextStyle(
                          color: Colors.deepPurple.shade800,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Embedded solution spreadsheet
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.deepPurple.shade200),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: EmbeddedSpreadsheet(
                      spreadsheetId: _extractSpreadsheetId(solutionSpreadsheetUrl) ?? solutionSpreadsheetUrl,
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _showAnswer ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
      ],
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  if (trailing != null) ...[
                    trailing,
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          // Content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  /// Build tool selector tab
  Widget _buildToolTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build spreadsheet exercise UI (existing spreadsheet functionality)
  Widget _buildSpreadsheetExercise(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: kIsWeb && _section?.templateSpreadsheetId != null
              ? EmbeddedSpreadsheet(
                  spreadsheetId: _userSpreadsheet?.spreadsheetId ?? _section!.templateSpreadsheetId!,
                  isEditable: _userSpreadsheet != null,
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.table_chart, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('Spreadsheet preview not available', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  /// Build Python exercise UI
  Widget _buildPythonExercise(ThemeData theme, ColorScheme colorScheme) {
    if (_section == null) {
      return const Center(child: Text('Section not found'));
    }

    // Get user's language code
    final languageCode = Localizations.localeOf(context).languageCode;

    return PythonExerciseWidget(
      key: _pythonExerciseKey,
      section: _section!,
      languageCode: languageCode,
      showAnswer: _showAnswer,  // Pass answer state to show solution tab
      onComplete: (passed, xpEarned) async {
        if (passed) {
          // Award XP and mark as completed
          await _awardXPAndComplete(xpEarned, 'python');
        }
      },
    );
  }

  /// Award XP and mark section as completed
  Future<void> _awardXPAndComplete(int xpEarned, String completedWith) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Update user progress (upsert with conflict handling)
      await Supabase.instance.client.from('user_progress').upsert(
        {
          'user_id': userId,
          'section_id': _section!.id,
          'is_completed': true,
          'completed_with': completedWith,
          'xp_earned': xpEarned,
          'completed_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,section_id',
      );

      // Record XP transaction
      await Supabase.instance.client.from('xp_transactions').insert({
        'user_id': userId,
        'amount': xpEarned,
        'transaction_type': 'earn',
        'source_type': 'section',
        'source_id': _section!.id,
        'description': 'Completed section: ${_section!.title}',
      });

      // Reload progress
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Section completed! You earned $xpEarned XP!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save progress: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
