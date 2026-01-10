import 'package:flutter/material.dart';
import 'package:shared/models/course.model.dart';
import '../services/pyodide_service.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/python.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';

/// Widget for interactive Python code exercises
///
/// Provides:
/// - Code editor with Python syntax
/// - Run button to execute code
/// - Submit button to validate and earn XP
/// - Output console
/// - Validation feedback
class PythonExerciseWidget extends StatefulWidget {
  final Section section;
  final String languageCode;
  final Function(bool passed, int xpEarned) onComplete;
  final bool showAnswer;  // Whether to show the solution tab
  final VoidCallback? onShowAnswer;  // Callback when user clicks Show Answer
  final String? initialCode;  // Restore code from previous session
  final String? initialOutput;  // Restore output from previous session
  final bool hintUsed;  // Whether hint was used (for XP calculation)
  final bool answerUsed;  // Whether answer was used (for XP calculation)

  const PythonExerciseWidget({
    super.key,
    required this.section,
    required this.languageCode,
    required this.onComplete,
    this.showAnswer = false,
    this.onShowAnswer,
    this.initialCode,
    this.initialOutput,
    this.hintUsed = false,
    this.answerUsed = false,
  });

  @override
  State<PythonExerciseWidget> createState() => PythonExerciseWidgetState();
}

class PythonExerciseWidgetState extends State<PythonExerciseWidget> with SingleTickerProviderStateMixin {
  late CodeController _codeController;
  late CodeController _solutionController;
  final PyodideService _pyodideService = PyodideService();
  late TabController _tabController;

  bool _isInitializing = false;
  bool _isRunning = false;
  bool _isValidating = false;
  String _output = '';
  String? _error;
  ValidationResult? _validationResult;
  bool _hintUsed = false;
  final bool _answerUsed = false;  // Track if answer was revealed
  bool? _wordWrapOverride; // null = use responsive default, true/false = user override

  @override
  void initState() {
    super.initState();

    // Initialize code controllers with Python syntax highlighting
    _codeController = CodeController(
      language: python,
    );
    _solutionController = CodeController(
      language: python,
    );
    // Initialize tab controller with 2 tabs: User Code, Solution
    _tabController = TabController(length: 2, vsync: this);
    _loadStarterCode();
    _loadSolutionCode();
    _initializePyodide();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _solutionController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PythonExerciseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When Show Answer is clicked, switch to Solution tab and reload solution
    if (widget.showAnswer && !oldWidget.showAnswer) {
      _loadSolutionCode(); // Reload from database in case user modified it
      _tabController.animateTo(1);
    }
  }

  /// Reload solution from database (called when Show Answer is clicked again)
  void reloadSolution() {
    _loadSolutionCode();
    _tabController.animateTo(1);
  }

  /// Get current code in the editor
  String getCurrentCode() => _codeController.text;

  /// Get current output
  String getCurrentOutput() => _output;

  /// Load solution code if available
  void _loadSolutionCode() {
    final solutionCode = widget.section.pythonSolutionCode;
    if (solutionCode != null && solutionCode.isNotEmpty) {
      _solutionController.text = solutionCode;
    }
  }

  /// Load the starter code for the current language, or restore from initial code
  void _loadStarterCode() {
    // If we have initial code (restored from tab switch), use that
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      _codeController.text = widget.initialCode!;
      if (widget.initialOutput != null) {
        _output = widget.initialOutput!;
      }
      return;
    }

    // Otherwise load the starter code
    final starterCode = widget.section.getPythonStarterCodeForLanguage(widget.languageCode);
    if (starterCode != null) {
      _codeController.text = starterCode;
    }
  }

  /// Initialize Pyodide runtime
  Future<void> _initializePyodide() async {
    if (_pyodideService.isInitialized) return;

    setState(() {
      _isInitializing = true;
    });

    try {
      await _pyodideService.initialize();

      // Install scientific packages if validation config requires them
      final config = widget.section.pythonValidationConfig;
      if (config != null) {
        final needsPackages = _checkIfNeedsScientificPackages(config);
        if (needsPackages) {
          await _pyodideService.installScientificPackages();
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize Python environment: $e';
      });
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  /// Check if validation requires scientific packages
  bool _checkIfNeedsScientificPackages(Map<String, dynamic> config) {
    final code = _codeController.text.toLowerCase();
    return code.contains('pandas') ||
        code.contains('numpy') ||
        code.contains('matplotlib') ||
        code.contains('scipy');
  }

  /// Run the Python code and show output
  Future<void> _runCode() async {
    setState(() {
      _isRunning = true;
      _output = '';
      _error = null;
      _validationResult = null;
    });

    try {
      final result = await _pyodideService.runPython(_codeController.text);

      setState(() {
        _output = result.output;
        _error = result.error;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  /// Validate the code and award XP if correct
  Future<void> _submitCode() async {
    final config = widget.section.pythonValidationConfig;
    if (config == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No validation configured for this exercise')),
      );
      return;
    }

    setState(() {
      _isValidating = true;
      _validationResult = null;
    });

    try {
      // Determine which code to submit based on active tab
      final codeToSubmit = (widget.showAnswer && _tabController.index == 1)
          ? _solutionController.text
          : _codeController.text;

      // First run the code
      final execution = await _pyodideService.runPython(codeToSubmit);

      setState(() {
        _output = execution.output;
        _error = execution.error;
      });

      if (!execution.success) {
        setState(() {
          _validationResult = ValidationResult(
            passed: false,
            feedback: [
              ValidationFeedback(
                step: 0,
                passed: false,
                message: 'Code execution failed. Fix errors before submitting.',
              ),
            ],
          );
        });
        return;
      }

      // Run validation
      final validation = await _pyodideService.validateCode(
        code: codeToSubmit,
        validationConfig: config,
      );

      setState(() {
        _validationResult = validation;
      });

      if (validation.passed) {
        // Calculate XP with penalties (answer -50% takes precedence over hint -30%)
        // Use widget.answerUsed and widget.hintUsed which come from parent's per-tool state
        final baseXP = widget.section.getXpRewardForTool('python');
        final xpEarned = widget.answerUsed
            ? (baseXP * 0.5).round()
            : widget.hintUsed ? (baseXP * 0.7).round() : baseXP;

        widget.onComplete(true, xpEarned);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Excellent! You earned $xpEarned XP!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isValidating = false;
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
    if (widget.section.hint == null) return;

    setState(() {
      _hintUsed = true;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hint'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.section.hint!),
            const SizedBox(height: 16),
            const Text(
              'Note: Using hints reduces XP reward by 30%',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Reset the code to starter code (force reload, ignoring initial code)
  void _resetCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Code?'),
        content: const Text('This will replace your code with the starter code. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Force reload starter code from section, not from initial code
              final starterCode = widget.section.getPythonStarterCodeForLanguage(widget.languageCode);
              if (starterCode != null) {
                _codeController.text = starterCode;
              }
              setState(() {
                _output = '';
                _error = null;
                _validationResult = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Loading Python environment...'),
            const SizedBox(height: 8),
            Text(
              'This may take a few seconds on first load',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    // Determine if solution tab should be visible
    final hasSolution = widget.section.pythonSolutionCode != null && 
                        widget.section.pythonSolutionCode!.isNotEmpty;
    final showSolutionTab = widget.showAnswer && hasSolution;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toolbar
        _buildToolbar(),

        const SizedBox(height: 8),

        // Tab bar (only if solution is available and shown)
        if (showSolutionTab)
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
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

        const SizedBox(height: 8),

        // Output and Validation
        Expanded(
          flex: 2,
          child: _buildOutputPanel(),
        ),
      ],
    );
  }

  /// Build toolbar with Run, Submit, Hint buttons
  Widget _buildToolbar() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: _isRunning || _isValidating ? null : _runCode,
            icon: _isRunning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: const Text('Run'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _isRunning || _isValidating ? null : _submitCode,
            icon: _isValidating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: const Text('Submit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          if (widget.section.hint != null)
            OutlinedButton.icon(
              onPressed: _showHint,
              icon: Icon(
                Icons.lightbulb_outline,
                color: _hintUsed ? Colors.amber : null,
              ),
              label: Text(_hintUsed ? 'Hint Used' : 'Hint'),
            ),
          const Spacer(),
          // Word wrap toggle
          Builder(
            builder: (context) {
              final effectiveWrap = _getEffectiveWordWrap(context);
              return IconButton(
                onPressed: () => setState(() => _wordWrapOverride = !effectiveWrap),
                icon: Icon(
                  effectiveWrap ? Icons.wrap_text : Icons.segment,
                  color: effectiveWrap ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
                tooltip: effectiveWrap ? 'Disable word wrap' : 'Enable word wrap',
              );
            },
          ),
          IconButton(
            onPressed: _resetCode,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset to starter code',
          ),
        ],
      ),
    );
  }

  /// Build code editor with Python syntax highlighting
  Widget _buildCodeEditor() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = isDark ? atomOneDarkTheme : atomOneLightTheme;
    final wordWrap = _getEffectiveWordWrap(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CodeTheme(
          data: CodeThemeData(styles: theme),
          child: CodeField(
            controller: _codeController,
            textStyle: const TextStyle(
              fontFamily: 'Fira Code',
              fontSize: 14,
              height: 1.5,
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
      ),
    );
  }

  /// Build solution code editor with Python syntax highlighting
  Widget _buildSolutionEditor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = isDark ? atomOneDarkTheme : atomOneLightTheme;
    final wordWrap = _getEffectiveWordWrap(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: isDark ? Colors.deepPurple.shade300 : Colors.deepPurple.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            CodeTheme(
              data: CodeThemeData(styles: theme),
              child: CodeField(
                controller: _solutionController,
                textStyle: const TextStyle(
                  fontFamily: 'Fira Code',
                  fontSize: 14,
                  height: 1.5,
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
                  color: Colors.deepPurple.shade600,
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
      ),
    );
  }

  /// Build output panel with console output and validation feedback
  Widget _buildOutputPanel() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: const Text(
              'Output',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Validation feedback
                  if (_validationResult != null) ...[
                    _buildValidationFeedback(),
                    const Divider(height: 32),
                  ],

                  // Error
                  if (_error != null) ...[
                    Text(
                      'Error:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _error!,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Output
                  if (_output.isNotEmpty) ...[
                    const Text(
                      'Console Output:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _output,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ],

                  // Empty state
                  if (_output.isEmpty && _error == null && _validationResult == null)
                    const Text(
                      'Run your code to see output here...',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
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
    final result = _validationResult!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              result.passed ? Icons.check_circle : Icons.error,
              color: result.passed ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(
              result.passed ? 'All tests passed!' : 'Some tests failed',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: result.passed ? Colors.green[700] : Colors.orange[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...result.feedback.map((feedback) => Padding(
              padding: const EdgeInsets.only(left: 32, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    feedback.passed ? Icons.check : Icons.close,
                    size: 16,
                    color: feedback.passed ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Step ${feedback.step}: ${feedback.message}',
                      style: TextStyle(
                        fontSize: 13,
                        color: feedback.passed ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
