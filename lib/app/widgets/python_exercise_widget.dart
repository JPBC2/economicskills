import 'package:flutter/material.dart';
import 'package:shared/models/course.model.dart';
import '../services/pyodide_service.dart';

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

  const PythonExerciseWidget({
    super.key,
    required this.section,
    required this.languageCode,
    required this.onComplete,
  });

  @override
  State<PythonExerciseWidget> createState() => _PythonExerciseWidgetState();
}

class _PythonExerciseWidgetState extends State<PythonExerciseWidget> {
  final TextEditingController _codeController = TextEditingController();
  final PyodideService _pyodideService = PyodideService();

  bool _isInitializing = false;
  bool _isRunning = false;
  bool _isValidating = false;
  String _output = '';
  String? _error;
  ValidationResult? _validationResult;
  bool _hintUsed = false;

  @override
  void initState() {
    super.initState();
    _loadStarterCode();
    _initializePyodide();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// Load the starter code for the current language
  void _loadStarterCode() {
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
      // First run the code
      final execution = await _pyodideService.runPython(_codeController.text);

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
        code: _codeController.text,
        validationConfig: config,
      );

      setState(() {
        _validationResult = validation;
      });

      if (validation.passed) {
        // Calculate XP (with hint penalty)
        final baseXP = widget.section.xpReward;
        final xpEarned = _hintUsed ? (baseXP * 0.7).round() : baseXP;

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

  /// Reset the code to starter code
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
              _loadStarterCode();
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toolbar
        _buildToolbar(),

        const SizedBox(height: 8),

        // Code Editor
        Expanded(
          flex: 3,
          child: _buildCodeEditor(),
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
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
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
          IconButton(
            onPressed: _resetCode,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset to starter code',
          ),
        ],
      ),
    );
  }

  /// Build code editor (simple TextField for now, can be replaced with CodeMirror)
  Widget _buildCodeEditor() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: TextField(
        controller: _codeController,
        maxLines: null,
        expands: true,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
        ),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.all(16),
          border: InputBorder.none,
          hintText: '# Write your Python code here...',
        ),
      ),
    );
  }

  /// Build output panel with console output and validation feedback
  Widget _buildOutputPanel() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
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
