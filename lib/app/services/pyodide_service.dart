import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

/// Service for running Python code in the browser using Pyodide (WebAssembly)
///
/// This service loads Pyodide from CDN and provides methods to:
/// - Execute Python code in the browser
/// - Validate student submissions
/// - Capture output and errors
class PyodideService {
  static final PyodideService _instance = PyodideService._internal();
  factory PyodideService() => _instance;
  PyodideService._internal();

  bool _isInitialized = false;
  bool _isInitializing = false;
  final List<Completer<void>> _initWaiters = [];

  /// Check if Pyodide is loaded and ready
  bool get isInitialized => _isInitialized;

  /// Initialize Pyodide runtime
  /// Loads Pyodide from CDN and sets up Python environment
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (_isInitializing) {
      // Already initializing, wait for it to complete
      final completer = Completer<void>();
      _initWaiters.add(completer);
      return completer.future;
    }

    _isInitializing = true;

    try {
      // Check if Pyodide script is already loaded
      if (!_isPyodideScriptLoaded()) {
        await _loadPyodideScript();
      }

      // Load Pyodide runtime
      await _loadPyodide();

      // Install common packages
      await _installPackages(['micropip']);

      _isInitialized = true;

      // Notify all waiters
      for (final waiter in _initWaiters) {
        waiter.complete();
      }
      _initWaiters.clear();
    } catch (e) {
      // Notify waiters of error
      for (final waiter in _initWaiters) {
        waiter.completeError(e);
      }
      _initWaiters.clear();
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// Load Pyodide script from CDN
  Future<void> _loadPyodideScript() async {
    final completer = Completer<void>();

    final script = web.document.createElement('script') as web.HTMLScriptElement;
    script.src = 'https://cdn.jsdelivr.net/pyodide/v0.29.0/full/pyodide.js';
    script.async = true;

    script.onload = (web.Event event) {
      completer.complete();
    }.toJS;

    script.onerror = (web.Event event) {
      completer.completeError('Failed to load Pyodide script');
    }.toJS;

    web.document.head!.appendChild(script);

    return completer.future;
  }

  /// Check if Pyodide script is already in the DOM
  bool _isPyodideScriptLoaded() {
    final scripts = web.document.querySelectorAll('script');
    for (var i = 0; i < scripts.length; i++) {
      final script = scripts.item(i) as web.HTMLScriptElement?;
      if (script?.src.contains('pyodide.js') ?? false) {
        return true;
      }
    }
    return false;
  }

  /// Load the Pyodide runtime
  Future<void> _loadPyodide() async {
    final result = await _evalJS('''
      (async () => {
        if (typeof loadPyodide === 'undefined') {
          throw new Error('Pyodide not loaded');
        }
        window.pyodide = await loadPyodide({
          indexURL: 'https://cdn.jsdelivr.net/pyodide/v0.29.0/full/'
        });
        return 'loaded';
      })()
    ''');

    if (result != 'loaded') {
      throw Exception('Failed to initialize Pyodide');
    }
  }

  /// Install Python packages via micropip
  Future<void> _installPackages(List<String> packages) async {
    for (final package in packages) {
      await _evalJS('''
        (async () => {
          await window.pyodide.loadPackage('$package');
          return 'installed';
        })()
      ''');
    }
  }

  /// Install additional packages (numpy, pandas, etc.)
  Future<void> installScientificPackages() async {
    if (!_isInitialized) {
      throw Exception('Pyodide not initialized. Call initialize() first.');
    }

    await _evalJS('''
      (async () => {
        await window.pyodide.loadPackage(['numpy', 'pandas', 'matplotlib']);
        return 'installed';
      })()
    ''');
  }

  /// Run Python code and return the output
  Future<PythonExecutionResult> runPython(String code) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final result = await _evalJS('''
        (async () => {
          const output = [];
          const errors = [];

          // Capture stdout
          window.pyodide.runPython(`
import sys
from io import StringIO
sys.stdout = StringIO()
sys.stderr = StringIO()
          `);

          try {
            // Run user code
            await window.pyodide.runPythonAsync(`${_escapeCode(code)}`);

            // Get stdout
            const stdout = window.pyodide.runPython('sys.stdout.getvalue()');
            const stderr = window.pyodide.runPython('sys.stderr.getvalue()');

            return JSON.stringify({
              success: true,
              output: stdout,
              error: stderr || null,
              globals: {}
            });
          } catch (error) {
            return JSON.stringify({
              success: false,
              output: '',
              error: error.toString(),
              globals: {}
            });
          }
        })()
      ''');

      final Map<String, dynamic> resultMap = _parseJSON(result);

      return PythonExecutionResult(
        success: resultMap['success'] as bool,
        output: resultMap['output'] as String? ?? '',
        error: resultMap['error'] as String?,
        globals: resultMap['globals'] as Map<String, dynamic>? ?? {},
      );
    } catch (e) {
      return PythonExecutionResult(
        success: false,
        output: '',
        error: e.toString(),
        globals: {},
      );
    }
  }

  /// Validate Python code against expected results
  Future<ValidationResult> validateCode({
    required String code,
    required Map<String, dynamic> validationConfig,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final validationType = validationConfig['validation_type'] as String? ?? 'simple';
    final steps = validationConfig['steps'] as List<dynamic>? ?? [];

    if (validationType == 'simple') {
      return await _validateSimple(code, steps);
    } else {
      throw UnimplementedError('Validation type $validationType not yet implemented');
    }
  }

  /// Simple validation: check variables, types, and output
  Future<ValidationResult> _validateSimple(String code, List<dynamic> steps) async {
    // First, run the code
    final execution = await runPython(code);

    if (!execution.success) {
      return ValidationResult(
        passed: false,
        feedback: [
          ValidationFeedback(
            step: 0,
            passed: false,
            message: 'Code execution failed: ${execution.error}',
          ),
        ],
      );
    }

    final feedbackList = <ValidationFeedback>[];
    var allPassed = true;

    // Run each validation step
    for (final stepData in steps) {
      final step = stepData as Map<String, dynamic>;
      final stepNum = step['step'] as int;
      final type = step['type'] as String;

      try {
        switch (type) {
          case 'variable_exists':
            final passed = await _checkVariableExists(step['name'] as String);
            feedbackList.add(ValidationFeedback(
              step: stepNum,
              passed: passed,
              message: passed
                  ? 'Variable "${step['name']}" exists ✓'
                  : step['message_en'] as String? ?? 'Variable "${step['name']}" not found',
            ));
            if (!passed) allPassed = false;
            break;

          case 'column_exists':
            // Check if a column exists in a DataFrame
            final dfName = step['dataframe'] as String? ?? 'df';
            final colName = step['name'] as String;
            final passed = await _checkColumnExists(dfName, colName);
            feedbackList.add(ValidationFeedback(
              step: stepNum,
              passed: passed,
              message: passed
                  ? 'Column "$colName" exists in DataFrame ✓'
                  : step['message_en'] as String? ?? 'Column "$colName" not found in DataFrame',
            ));
            if (!passed) allPassed = false;
            break;

          case 'variable_value':
            final result = await _checkVariableValue(
              step['name'] as String,
              step['expected'],
              step['tolerance'] as num? ?? 0.01,
            );
            feedbackList.add(ValidationFeedback(
              step: stepNum,
              passed: result['passed'] as bool,
              message: result['passed'] as bool
                  ? 'Variable "${step['name']}" has correct value ✓'
                  : step['message_en'] as String? ?? result['message'] as String,
            ));
            if (!(result['passed'] as bool)) allPassed = false;
            break;

          case 'variable_type':
            final passed = await _checkVariableType(
              step['name'] as String,
              step['expected_type'] as String,
            );
            feedbackList.add(ValidationFeedback(
              step: stepNum,
              passed: passed,
              message: passed
                  ? 'Variable "${step['name']}" has correct type ✓'
                  : step['message_en'] as String? ?? 'Variable "${step['name']}" has wrong type',
            ));
            if (!passed) allPassed = false;
            break;

          case 'output_contains':
            final pattern = step['pattern'] as String;
            final passed = execution.output.contains(RegExp(pattern));
            feedbackList.add(ValidationFeedback(
              step: stepNum,
              passed: passed,
              message: passed
                  ? 'Output contains expected pattern ✓'
                  : step['message_en'] as String? ?? 'Output does not match expected pattern',
            ));
            if (!passed) allPassed = false;
            break;

          default:
            feedbackList.add(ValidationFeedback(
              step: stepNum,
              passed: false,
              message: 'Unknown validation type: $type',
            ));
            allPassed = false;
        }
      } catch (e) {
        feedbackList.add(ValidationFeedback(
          step: stepNum,
          passed: false,
          message: 'Validation error: $e',
        ));
        allPassed = false;
      }
    }

    return ValidationResult(
      passed: allPassed,
      feedback: feedbackList,
    );
  }

  /// Check if a variable exists in Python globals
  Future<bool> _checkVariableExists(String varName) async {
    final result = await _evalJS('''
      (async () => {
        try {
          const exists = window.pyodide.runPython(`'$varName' in globals()`);
          return exists ? 'true' : 'false';
        } catch (e) {
          return 'false';
        }
      })()
    ''');
    return result == 'true';
  }

  /// Check if a column exists in a DataFrame
  Future<bool> _checkColumnExists(String dfName, String colName) async {
    final result = await _evalJS('''
      (async () => {
        try {
          const exists = window.pyodide.runPython(`'$colName' in $dfName.columns`);
          return exists ? 'true' : 'false';
        } catch (e) {
          return 'false';
        }
      })()
    ''');
    return result == 'true';
  }

  /// Check if a variable has the expected value
  Future<Map<String, dynamic>> _checkVariableValue(
    String varName,
    dynamic expected,
    num tolerance,
  ) async {
    final result = await _evalJS('''
      (async () => {
        try {
          const value = window.pyodide.runPython(`$varName`);
          const expected = $expected;

          // Check if numeric with tolerance
          if (typeof value === 'number' && typeof expected === 'number') {
            const diff = Math.abs(value - expected);
            const relDiff = diff / Math.abs(expected);
            const passed = relDiff <= $tolerance;
            return JSON.stringify({
              passed: passed,
              actual: value,
              expected: expected,
              message: passed ? '' : `Expected $expected, got \${value}`
            });
          }

          // Exact equality for non-numeric
          const passed = value === expected;
          return JSON.stringify({
            passed: passed,
            actual: value,
            expected: expected,
            message: passed ? '' : `Expected $expected, got \${value}`
          });
        } catch (e) {
          return JSON.stringify({
            passed: false,
            message: 'Variable not found or error: ' + e.toString()
          });
        }
      })()
    ''');

    return _parseJSON(result);
  }

  /// Check if a variable has the expected type
  Future<bool> _checkVariableType(String varName, String expectedType) async {
    final result = await _evalJS('''
      (async () => {
        try {
          const typeCheck = window.pyodide.runPython(`
import pandas as pd
import numpy as np

def check_type(var, expected_type):
    if expected_type == 'DataFrame':
        return isinstance(var, pd.DataFrame)
    elif expected_type == 'Series':
        return isinstance(var, pd.Series)
    elif expected_type == 'ndarray':
        return isinstance(var, np.ndarray)
    elif expected_type == 'int':
        return isinstance(var, int)
    elif expected_type == 'float':
        return isinstance(var, float)
    elif expected_type == 'str':
        return isinstance(var, str)
    elif expected_type == 'list':
        return isinstance(var, list)
    elif expected_type == 'dict':
        return isinstance(var, dict)
    else:
        return type(var).__name__ == expected_type

check_type($varName, '$expectedType')
          `);
          return typeCheck ? 'true' : 'false';
        } catch (e) {
          return 'false';
        }
      })()
    ''');
    return result == 'true';
  }

  /// Evaluate JavaScript code and return result as String
  /// Uses dart:js_interop_unsafe with proper Promise handling
  Future<String> _evalJS(String code) async {
    try {
      // Wrap code in an async IIFE that returns a Promise
      final wrappedCode = '''
        (async function() {
          try {
            const result = await ($code);
            return result != null ? String(result) : '';
          } catch (e) {
            throw new Error(e.toString());
          }
        })()
      ''';
      
      // Use globalContext to access the Function constructor
      // This creates a function that returns our async code
      final functionConstructor = globalContext['Function'] as JSFunction;
      
      // Create a function that returns our code execution result
      final evalFunction = functionConstructor.callAsConstructor<JSFunction>(
        'return $wrappedCode'.toJS,
      );
      
      // Call the function to get the Promise
      final result = evalFunction.callAsFunction();
      
      // The result is a Promise, so we need to await it
      if (result != null && result.isA<JSPromise>()) {
        final jsPromise = result as JSPromise<JSAny?>;
        final awaited = await jsPromise.toDart;
        return awaited?.toString() ?? '';
      }
      
      return result?.toString() ?? '';
    } catch (e) {
      throw Exception('JavaScript evaluation failed: $e');
    }
  }

  /// Escape Python code for embedding in JavaScript string
  String _escapeCode(String code) {
    return code
        .replaceAll('\\', '\\\\')
        .replaceAll('`', '\\`')
        .replaceAll('\$', '\\\$')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');
  }

  /// Parse JSON string to Map
  Map<String, dynamic> _parseJSON(String json) {
    // Use dart:convert
    final decoded = jsonDecode(json);
    return decoded as Map<String, dynamic>;
  }
}

/// Result of Python code execution
class PythonExecutionResult {
  final bool success;
  final String output;
  final String? error;
  final Map<String, dynamic> globals;

  PythonExecutionResult({
    required this.success,
    required this.output,
    this.error,
    required this.globals,
  });
}

/// Result of validation
class ValidationResult {
  final bool passed;
  final List<ValidationFeedback> feedback;

  ValidationResult({
    required this.passed,
    required this.feedback,
  });
}

/// Feedback for a single validation step
class ValidationFeedback {
  final int step;
  final bool passed;
  final String message;

  ValidationFeedback({
    required this.step,
    required this.passed,
    required this.message,
  });
}
