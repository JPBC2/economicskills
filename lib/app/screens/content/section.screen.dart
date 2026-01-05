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
  String? _error;
  ValidationResult? _lastValidation;

  @override
  void initState() {
    super.initState();
    _spreadsheetService = SpreadsheetService(Supabase.instance.client);
    _loadData();
  }

  @override
  void dispose() {
    _spreadsheetIdController.dispose();
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

      // Load user's spreadsheet and progress if authenticated
      if (supabase.auth.currentUser != null) {
        final spreadsheet = await _spreadsheetService.getUserSpreadsheet(_section!.id);
        final progress = await _spreadsheetService.getUserProgress(_section!.id);
        
        setState(() {
          _userSpreadsheet = spreadsheet;
          _progress = progress;
          if (spreadsheet != null) {
            _spreadsheetIdController.text = spreadsheet.spreadsheetId;
          }
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left panel - Instructions (35%)
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.35,
            child: _buildInstructionsPanel(theme, colorScheme),
          ),
          // Divider
          Container(width: 1, color: colorScheme.outlineVariant),
          // Right panel - Spreadsheet (65%)
          Expanded(
            child: _buildSpreadsheetPanel(theme, colorScheme),
          ),
        ],
      );
    } else {
      // Stacked layout for mobile
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstructionsCard(theme, colorScheme),
            const SizedBox(height: 16),
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

            // Section title with status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green.shade100 : colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle : Icons.table_chart,
                    size: 24,
                    color: isCompleted ? Colors.green : colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _section!.title,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (isCompleted)
                        Text(
                          'Completed! +${_progress!.xpEarned} XP',
                          style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // XP Reward chip
            if (_section!.xpReward > 0)
              Chip(
                avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
                label: Text('${_section!.xpReward} XP'),
                backgroundColor: Colors.amber.shade50,
              ),
            const SizedBox(height: 24),

            // Section instructions
            if (_section!.instructions != null && _section!.instructions!.isNotEmpty) ...[
              Text('Instructions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  _section!.instructions!,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
              ),
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
          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
            ),
            child: Row(
              children: [
                Icon(Icons.table_chart, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text('Spreadsheet', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                // Copy button
                OutlinedButton.icon(
                  onPressed: _openCopyLink,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Make a Copy'),
                ),
                const SizedBox(width: 8),
                // Open in new tab
                IconButton(
                  onPressed: () async {
                    final id = _userSpreadsheet?.spreadsheetId ?? _section?.templateSpreadsheetId;
                    if (id != null) {
                      final uri = Uri.parse('https://docs.google.com/spreadsheets/d/$id/edit');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  tooltip: 'Open in new tab',
                ),
              ],
            ),
          ),

          // Embedded spreadsheet
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Spreadsheet ID input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _spreadsheetIdController,
                          decoration: InputDecoration(
                            labelText: 'Your Spreadsheet URL',
                            hintText: 'Paste the URL from your copied spreadsheet',
                            prefixIcon: const Icon(Icons.link),
                            border: const OutlineInputBorder(),
                            helperText: _userSpreadsheet != null ? 'Connected' : 'Copy the spreadsheet first, then paste your URL here',
                            helperStyle: TextStyle(
                              color: _userSpreadsheet != null ? Colors.green : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.tonal(
                        onPressed: _isSaving ? null : _saveSpreadsheetId,
                        child: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Save'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Submit button
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _userSpreadsheet != null && !_isValidating ? _validateSpreadsheet : null,
                      icon: _isValidating
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle),
                      label: const Text('Submit for Validation'),
                    ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Spreadsheet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 400,
              child: _section?.templateSpreadsheetId != null
                  ? EmbeddedSpreadsheet(spreadsheetId: _section!.templateSpreadsheetId!)
                  : const Center(child: Text('No spreadsheet available')),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _openCopyLink,
              icon: const Icon(Icons.copy),
              label: const Text('Make a Copy'),
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
}
