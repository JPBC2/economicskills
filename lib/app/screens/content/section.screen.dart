import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:economicskills/app/services/spreadsheet.service.dart';
import 'package:economicskills/app/widgets/top_nav.widget.dart';
import 'package:economicskills/app/widgets/hiding_scaffold.widget.dart';
import 'package:economicskills/app/widgets/drawer_nav.widget.dart';
import 'package:economicskills/app/widgets/embedded_spreadsheet.widget.dart';
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
  bool _exerciseExpanded = true;
  bool _instructionsExpanded = true;
  
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
        // Handle slugs like "1_annual_nominal_dividends_per_share" matching "1. Annual nominal dividends per share."
        String searchTitle = widget.sectionSlug.replaceAll('_', '%');
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
      if (user != null && section.templateSpreadsheetId != null) {
        await _autoCreateSpreadsheet(user.id, section);
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
  Future<void> _autoCreateSpreadsheet(String userId, Section section) async {
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
          'template_id': section.templateSpreadsheetId,
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
            action: SnackBarAction(label: 'Retry', onPressed: () => _autoCreateSpreadsheet(userId, section)),
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
      await _autoCreateSpreadsheet(user.id, _section!);
      
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
                          _showHint 
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
                          _showHint 
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

    return Container(
      color: colorScheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Embedded spreadsheet (no header - more space)
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

          // Bottom action bar
          if (isAuthenticated)
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
          Text('${result.correctCells}/${result.totalCells} correct (${result.score}%)'),
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
}
