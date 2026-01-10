import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared/models/course.model.dart';
import '../services/webr_service.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/r.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';

/// Widget for interactive R code exercises using WebR
///
/// Provides:
/// - Code editor with R syntax highlighting
/// - Run button to execute code
/// - Submit button to validate and earn XP
/// - Output console
/// - Validation feedback
class RExerciseWidget extends StatefulWidget {
  final Section section;
  final String languageCode;
  final bool showAnswer;
  final String? initialCode;
  final String? initialOutput;
  final bool hintUsed;
  final bool answerUsed;
  final Function(bool passed, int xpEarned)? onComplete;

  const RExerciseWidget({
    super.key,
    required this.section,
    this.languageCode = 'en',
    this.showAnswer = false,
    this.initialCode,
    this.initialOutput,
    this.hintUsed = false,
    this.answerUsed = false,
    this.onComplete,
  });

  @override
  State<RExerciseWidget> createState() => RExerciseWidgetState();
}

class RExerciseWidgetState extends State<RExerciseWidget> with SingleTickerProviderStateMixin {
  late CodeController _codeController;
  late CodeController _solutionController;
  late TabController _tabController;

  final WebRService _webR = WebRService.instance;

  bool _isInitializing = true;
  bool _isRunning = false;
  bool _isSubmitting = false;
  String _output = '';
  String? _error;
  RValidationResult? _validationResult;
  bool _hintUsed = false;
  bool? _wordWrapOverride; // null = use responsive default, true/false = user override
  
  @override
  void initState() {
    super.initState();
    _hintUsed = widget.hintUsed;
    _tabController = TabController(length: 2, vsync: this);

    _codeController = CodeController(
      text: '',
      language: r,
    );

    _solutionController = CodeController(
      text: '',
      language: r,
    );
    
    _loadStarterCode();
    _loadSolutionCode();
    _initializeWebR();
    
    // Restore initial output if provided
    if (widget.initialOutput != null) {
      _output = widget.initialOutput!;
    }
  }
  
  @override
  void dispose() {
    _codeController.dispose();
    _solutionController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(RExerciseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When Show Answer is clicked, switch to Solution tab and reload solution
    if (widget.showAnswer && !oldWidget.showAnswer) {
      _loadSolutionCode();
      _tabController.animateTo(1);
    }
  }
  
  /// Reload solution from database (called when Show Answer is clicked again)
  void reloadSolution() {
    _loadSolutionCode();
  }
  
  /// Get current code in the editor
  String getCurrentCode() => _codeController.text;
  
  /// Get current output
  String getCurrentOutput() => _output;
  
  /// Load solution code if available
  void _loadSolutionCode() {
    final solutionCode = widget.section.rSolutionCode;
    if (solutionCode != null && solutionCode.isNotEmpty) {
      _solutionController.text = solutionCode;
    }
  }
  
  /// Load the starter code for the current language
  void _loadStarterCode() {
    // Use initial code if provided (for restoring state)
    if (widget.initialCode != null) {
      _codeController.text = widget.initialCode!;
      return;
    }
    
    // Get R starter code for the current language
    final starterCode = widget.section.getRStarterCodeForLanguage(widget.languageCode);
    if (starterCode != null && starterCode.isNotEmpty) {
      _codeController.text = starterCode;
    } else {
      // Default R starter code
      _codeController.text = '''# Write your R code here
# Use print() to display output

# Example:
# print("Hello, R!")
''';
    }
  }
  
  /// Initialize WebR runtime
  Future<void> _initializeWebR() async {
    setState(() => _isInitializing = true);
    
    try {
      // Initialize with common statistics packages
      await _webR.initialize(packages: [
        'dplyr',
        'readr',  // for read_csv
        'ggplot2',
        'tidyr',
      ]);
      
      setState(() {
        _isInitializing = false;
        _output = 'R environment ready.\n';
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _error = 'Failed to initialize R: $e';
        _output = 'Error: Failed to initialize R environment.\n$e';
      });
    }
  }
  
  /// Run the R code and show output
  Future<void> _runCode() async {
    if (_isRunning || !_webR.isReady) return;
    
    setState(() {
      _isRunning = true;
      _output = 'Running...\n';
      _error = null;
    });
    
    try {
      // Inject common CSV files into WebR filesystem before running
      await _injectDataFiles();
      
      final result = await _webR.runCode(_codeController.text);
      setState(() {
        _isRunning = false;
        if (result.success) {
          _output = result.output.isEmpty ? '(No output)' : result.output;
        } else {
          _output = 'Error: ${result.error}';
          _error = result.error;
        }
      });
    } catch (e) {
      setState(() {
        _isRunning = false;
        _output = 'Error: $e';
        _error = e.toString();
      });
    }
  }
  
  /// Inject data files (CSV) into WebR's virtual filesystem
  Future<void> _injectDataFiles() async {
    // List of data files to load from assets
    const dataFiles = [
      '2020_periodic_dividends_per_share.csv',
    ];
    
    for (final filename in dataFiles) {
      try {
        final content = await rootBundle.loadString('assets/data/$filename');
        await _webR.writeFile(filename, content);
      } catch (e) {
        // File not found - this is okay, not all sections use all files
        print('Note: Could not load $filename: $e');
      }
    }
  }
  
  /// Validate the code and award XP if correct
  Future<void> _submitCode() async {
    if (_isSubmitting || !_webR.isReady) return;

    setState(() {
      _isSubmitting = true;
      _output = 'Validating...\n';
      _validationResult = null;
    });

    try {
      // Inject data files before validation (same as _runCode)
      await _injectDataFiles();

      // Get R validation config
      final validationConfig = widget.section.rValidationConfig ?? {};

      final result = await _webR.validateCode(
        _codeController.text,
        validationConfig,
      );
      
      setState(() {
        _isSubmitting = false;
        _validationResult = result;
        if (result.passed) {
          _output = 'Success! Your code is correct.\n';
        } else {
          _output = 'Validation failed: ${result.message}';
        }
      });
      
      // Award XP if passed
      if (result.passed && widget.onComplete != null) {
        // Calculate XP with penalties
        int xpReward = widget.section.getXpRewardForTool('r');
        if (widget.answerUsed) {
          xpReward = (xpReward * 0.5).floor();
        } else if (_hintUsed) {
          xpReward = (xpReward * 0.7).floor();
        }
        
        widget.onComplete!(true, xpReward);
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _output = 'Validation error: $e';
        _validationResult = RValidationResult(
          passed: false,
          message: e.toString(),
          details: [],
        );
      });
    }
  }
  
  /// Get effective word wrap setting based on screen size or user override
  /// Mobile (< 600px): wrap by default for better readability
  /// Desktop (>= 600px): no wrap by default, show horizontal scrollbar
  bool _getEffectiveWordWrap(BuildContext context) {
    if (_wordWrapOverride != null) return _wordWrapOverride!;
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 600; // Mobile breakpoint
  }

  /// Show hint and mark as used
  void _showHint() {
    final hint = widget.section.getHintForTool('r') ?? widget.section.hint;
    if (hint == null || hint.isEmpty) return;
    
    setState(() => _hintUsed = true);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.amber),
            SizedBox(width: 8),
            Text('Hint'),
          ],
        ),
        content: Text(hint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
  
  /// Reset the code to starter code
  void _resetCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Code'),
        content: const Text('This will reset your code to the starter template. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                // Force reload starter code
                final starterCode = widget.section.getRStarterCodeForLanguage(widget.languageCode);
                if (starterCode != null && starterCode.isNotEmpty) {
                  _codeController.text = starterCode;
                } else {
                  _codeController.text = '''# Write your R code here
# Use print() to display output
''';
                }
                _output = '';
                _error = null;
                _validationResult = null;
              });
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Show loading state while WebR initializes
    if (_isInitializing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _webR.loadingStatus.isNotEmpty ? _webR.loadingStatus : 'Loading R environment...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a moment on first load',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }
    
    // Show error state if WebR failed to initialize
    if (!_webR.isReady && _error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'R Environment Failed to Load',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'WebR requires loading WASM files which may fail on some browsers or networks.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _error = null;
                  });
                  _initializeWebR();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Check if we should show solution tab
    final hasSolution = widget.section.rSolutionCode != null &&
                        widget.section.rSolutionCode!.isNotEmpty;
    final showSolutionTab = widget.showAnswer && hasSolution;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toolbar
        _buildToolbar(),
        
        // Tab bar (if solution is available)
        if (showSolutionTab)
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              indicatorColor: colorScheme.primary,
              tabs: const [
                Tab(text: 'Your Code'),
                Tab(text: 'Solution'),
              ],
            ),
          ),
        
        // Code Editor (with or without tabs)
        Expanded(
          flex: 3,
          child: showSolutionTab
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCodeEditor(),
                    _buildSolutionEditor(),
                  ],
                )
              : _buildCodeEditor(),
        ),
        
        // Output Panel
        Expanded(
          flex: 2,
          child: _buildOutputPanel(),
        ),
      ],
    );
  }
  
  /// Build toolbar with Run, Submit, Hint buttons
  Widget _buildToolbar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasHint = widget.section.getHintForTool('r')?.isNotEmpty == true ||
                    widget.section.hint?.isNotEmpty == true;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          // R indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.code, size: 14, color: Colors.blue.shade800),
                const SizedBox(width: 4),
                Text('R', style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                )),
              ],
            ),
          ),
          const SizedBox(width: 8),
          
          // Run button
          FilledButton.icon(
            onPressed: _isRunning || !_webR.isReady ? null : _runCode,
            icon: _isRunning 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.play_arrow, size: 18),
            label: const Text('Run'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const SizedBox(width: 8),
          
          // Submit button
          FilledButton.icon(
            onPressed: _isSubmitting || !_webR.isReady ? null : _submitCode,
            icon: _isSubmitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check, size: 18),
            label: const Text('Submit'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          
          const Spacer(),
          
          // Hint button
          if (hasHint)
            TextButton.icon(
              onPressed: _showHint,
              icon: Icon(
                _hintUsed ? Icons.lightbulb : Icons.lightbulb_outline,
                size: 18,
                color: Colors.amber.shade700,
              ),
              label: Text(
                _hintUsed ? 'Hint' : 'Hint (-30%)',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          
          // Word wrap toggle
          Builder(
            builder: (context) {
              final effectiveWrap = _getEffectiveWordWrap(context);
              return IconButton(
                onPressed: () => setState(() => _wordWrapOverride = !effectiveWrap),
                icon: Icon(
                  effectiveWrap ? Icons.wrap_text : Icons.segment,
                  size: 18,
                  color: effectiveWrap ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
                tooltip: effectiveWrap ? 'Disable word wrap' : 'Enable word wrap',
              );
            },
          ),

          // Reset button
          IconButton(
            onPressed: _resetCode,
            icon: const Icon(Icons.refresh, size: 18),
            tooltip: 'Reset code',
          ),
        ],
      ),
    );
  }
  
  /// Build code editor with R syntax highlighting
  Widget _buildCodeEditor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final editorTheme = isDark ? atomOneDarkTheme : githubTheme;
    final backgroundColor = isDark ? const Color(0xFF282c34) : Colors.grey.shade100;
    final wordWrap = _getEffectiveWordWrap(context);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: CodeTheme(
        data: CodeThemeData(styles: editorTheme),
        child: CodeField(
          controller: _codeController,
          textStyle: TextStyle(
            fontFamily: 'Fira Code',
            fontSize: 14,
            height: 1.5,
            color: isDark ? Colors.white : Colors.black87,
          ),
          gutterStyle: GutterStyle(
            width: 48,
            showErrors: false,
            showFoldingHandles: false,
            textStyle: TextStyle(
              fontFamily: 'Fira Code',
              fontSize: 12,
              height: 1.5,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
            ),
          ),
          expands: true,
          wrap: wordWrap,
        ),
      ),
    );
  }

  /// Build solution code editor with R syntax highlighting
  Widget _buildSolutionEditor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final editorTheme = isDark ? atomOneDarkTheme : githubTheme;
    final backgroundColor = isDark ? const Color(0xFF1a3a1a) : Colors.green.shade50;
    final wordWrap = _getEffectiveWordWrap(context);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Stack(
        children: [
          CodeTheme(
            data: CodeThemeData(styles: editorTheme),
            child: CodeField(
              controller: _solutionController,
              textStyle: TextStyle(
                fontFamily: 'Fira Code',
                fontSize: 14,
                height: 1.5,
                color: isDark ? Colors.white : Colors.black87,
              ),
              gutterStyle: GutterStyle(
                width: 48,
                showErrors: false,
                showFoldingHandles: false,
                textStyle: TextStyle(
                  fontFamily: 'Fira Code',
                  fontSize: 12,
                  height: 1.5,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                ),
              ),
              expands: true,
              wrap: wordWrap,
              readOnly: true,
            ),
          ),
          // Solution label
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'SOLUTION',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build output panel with console output and validation feedback
  Widget _buildOutputPanel() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    // Theme-aware console colors
    final backgroundColor = isDark ? Colors.grey.shade900 : Colors.grey.shade100;
    final headerColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final textColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final outputColor = _error != null 
        ? (isDark ? Colors.red.shade300 : Colors.red.shade700)
        : (isDark ? Colors.green.shade300 : Colors.green.shade700);
    
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Output header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: headerColor,
            ),
            child: Row(
              children: [
                Icon(Icons.terminal, size: 16, color: textColor),
                const SizedBox(width: 8),
                Text(
                  'Console',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Output content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Console output
                  SelectableText(
                    _output.isEmpty ? '# Output will appear here...' : _output,
                    style: TextStyle(
                      fontFamily: 'Fira Code',
                      fontSize: 13,
                      color: outputColor,
                    ),
                  ),
                  
                  // Validation result
                  if (_validationResult != null)
                    _buildValidationFeedback(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build validation feedback display
  Widget _buildValidationFeedback() {
    if (_validationResult == null) return const SizedBox.shrink();
    
    final result = _validationResult!;
    final isPassed = result.passed;
    
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPassed ? Colors.green.shade900 : Colors.red.shade900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPassed ? Colors.green.shade600 : Colors.red.shade600,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPassed ? Icons.check_circle : Icons.error,
                color: isPassed ? Colors.green.shade300 : Colors.red.shade300,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isPassed ? 'Correct!' : 'Not quite right',
                style: TextStyle(
                  color: isPassed ? Colors.green.shade100 : Colors.red.shade100,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (result.message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              result.message,
              style: TextStyle(
                color: isPassed ? Colors.green.shade200 : Colors.red.shade200,
              ),
            ),
          ],
          if (result.details.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...result.details.map((detail) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '• $detail',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }
}
