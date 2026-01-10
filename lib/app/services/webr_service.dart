import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

/// Service for executing R code in the browser using WebR
/// WebR compiles R to WebAssembly for client-side execution
class WebRService {
  static WebRService? _instance;
  static WebRService get instance => _instance ??= WebRService._();
  
  WebRService._();
  
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _initError;
  
  /// Check if WebR is initialized and ready
  bool get isReady => _isInitialized;
  
  /// Check if initialization is in progress
  bool get isInitializing => _isInitializing;
  
  /// Get initialization error if any
  String? get initError => _initError;

  /// Initialize WebR runtime
  /// This loads the WebR WASM module and sets up the R environment
  Future<void> initialize({
    List<String> packages = const ['dplyr', 'readr'],
  }) async {
    if (_isInitialized) return;
    if (_isInitializing) {
      // Wait for initialization to complete
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }
    
    _isInitializing = true;
    _initError = null;
    
    try {
      // Load WebR from CDN
      await _loadWebRScript();
      
      // Initialize WebR with packages
      await _initializeWebR(packages: packages);
      
      _isInitialized = true;
    } catch (e) {
      _initError = e.toString();
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }
  
  /// Load WebR script from CDN
  Future<void> _loadWebRScript() async {
    final completer = Completer<void>();
    
    // Check if WebR is already loaded
    if (_hasWebR()) {
      completer.complete();
      return completer.future;
    }
    
    // Create script element to load WebR
    final script = web.document.createElement('script') as web.HTMLScriptElement;
    script.src = 'https://webr.r-wasm.org/latest/webr.mjs';
    script.type = 'module';
    
    script.onload = ((web.Event event) {
      completer.complete();
    }).toJS;
    
    script.onerror = ((web.Event event) {
      completer.completeError('Failed to load WebR script');
    }).toJS;
    
    web.document.head?.appendChild(script);
    
    return completer.future;
  }
  
  /// Check if WebR is loaded on window
  bool _hasWebR() {
    try {
      // Check if WebR constructor exists on window
      final jsWindow = web.window as JSObject;
      final webR = jsWindow.getProperty('WebR'.toJS);
      return webR != null && !webR.isUndefinedOrNull;
    } catch (_) {
      return false;
    }
  }
  
  /// Initialize WebR instance
  Future<void> _initializeWebR({List<String> packages = const []}) async {
    // WebR initialization script - creates window.webR and installs packages
    final packagesJson = packages.map((p) => '"$p"').join(', ');
    final initScript = '''
      (async function() {
        const { WebR } = await import('https://webr.r-wasm.org/latest/webr.mjs');
        window.webR = new WebR();
        await window.webR.init();
        
        // Install packages using WebR's package manager
        ${packages.isNotEmpty ? '''
        console.log('Installing R packages: ${packages.join(', ')}...');
        await window.webR.installPackages([$packagesJson]);
        console.log('R packages installed successfully');
        ''' : ''}
        
        return true;
      })()
    ''';
    
    try {
      await _evalJsAsync(initScript);
    } catch (e) {
      throw Exception('Failed to initialize WebR: $e');
    }
  }
  
  /// Execute R code and return the result
  Future<RExecutionResult> runCode(String code) async {
    if (!isReady) {
      return RExecutionResult(
        output: '',
        error: 'WebR is not initialized. Please wait for initialization.',
        success: false,
      );
    }
    
    try {
      final result = await _evalR(code);
      return RExecutionResult(
        output: result,
        error: null,
        success: true,
      );
    } catch (e) {
      return RExecutionResult(
        output: '',
        error: e.toString(),
        success: false,
      );
    }
  }
  
  /// Validate R code against expected criteria
  Future<RValidationResult> validateCode(
    String code,
    Map<String, dynamic> validationConfig,
  ) async {
    if (!isReady) {
      return RValidationResult(
        passed: false,
        message: 'WebR is not initialized',
        details: [],
      );
    }
    
    try {
      // Run the user's code first
      final execResult = await runCode(code);
      if (!execResult.success) {
        return RValidationResult(
          passed: false,
          message: 'Code execution failed: ${execResult.error}',
          details: [],
        );
      }
      
      // Perform validation based on config
      final validationType = validationConfig['type'] as String?;
      
      switch (validationType) {
        case 'output_contains':
          return _validateOutputContains(execResult.output, validationConfig);
        case 'variable_exists':
          return await _validateVariableExists(validationConfig);
        case 'variable_equals':
          return await _validateVariableEquals(validationConfig);
        case 'function_result':
          return await _validateFunctionResult(validationConfig);
        default:
          // If no specific validation, just check that code runs without error
          return RValidationResult(
            passed: true,
            message: 'Code executed successfully',
            details: [],
          );
      }
    } catch (e) {
      return RValidationResult(
        passed: false,
        message: 'Validation error: $e',
        details: [],
      );
    }
  }
  
  /// Install an R package
  Future<void> installPackage(String packageName) async {
    if (!isReady) return;
    
    try {
      await _evalR('webr::install("$packageName")');
    } catch (_) {
      // Package installation errors are non-fatal - silently continue
    }
  }
  
  // Private helper methods
  
  Future<String> _evalJsAsync(String script) async {
    final completer = Completer<String>();
    
    try {
      // Use js_interop_unsafe to call eval on window
      final windowObj = web.window as JSObject;
      
      // Wrap script to return a Promise that we can await
      final wrappedScript = '''
        (async function() {
          try {
            return await (async function() { return $script })();
          } catch(e) {
            throw e;
          }
        })()
      ''';
      
      // Call eval on window using callMethod from js_interop_unsafe
      final result = windowObj.callMethod('eval'.toJS, wrappedScript.toJS);
      
      if (result != null && result.isA<JSPromise>()) {
        final awaited = await (result as JSPromise).toDart;
        completer.complete(awaited?.toString() ?? '');
      } else {
        completer.complete(result?.toString() ?? '');
      }
    } catch (e) {
      completer.completeError(e);
    }
    
    return completer.future;
  }
  
  Future<String> _evalR(String code) async {
    // Escape the R code for JavaScript
    final escapedCode = code
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '');
    
    final script = '''
      (async function() {
        const result = await window.webR.evalR('$escapedCode');
        const output = await result.toArray();
        return output.join('\\n');
      })()
    ''';
    
    return await _evalJsAsync(script);
  }
  
  RValidationResult _validateOutputContains(String output, Map<String, dynamic> config) {
    final expectedStrings = config['expected'] as List<dynamic>? ?? [];
    final missingStrings = <String>[];
    
    for (final expected in expectedStrings) {
      if (!output.contains(expected.toString())) {
        missingStrings.add(expected.toString());
      }
    }
    
    if (missingStrings.isEmpty) {
      return RValidationResult(
        passed: true,
        message: 'Output contains all expected values',
        details: [],
      );
    } else {
      return RValidationResult(
        passed: false,
        message: 'Output is missing expected values',
        details: missingStrings.map((s) => 'Missing: $s').toList(),
      );
    }
  }
  
  Future<RValidationResult> _validateVariableExists(Map<String, dynamic> config) async {
    final variableName = config['variable'] as String?;
    if (variableName == null) {
      return RValidationResult(passed: false, message: 'No variable specified', details: []);
    }
    
    try {
      final result = await _evalR('exists("$variableName")');
      final exists = result.toLowerCase().contains('true');
      
      return RValidationResult(
        passed: exists,
        message: exists ? 'Variable "$variableName" exists' : 'Variable "$variableName" not found',
        details: [],
      );
    } catch (e) {
      return RValidationResult(passed: false, message: 'Error checking variable: $e', details: []);
    }
  }
  
  Future<RValidationResult> _validateVariableEquals(Map<String, dynamic> config) async {
    final variableName = config['variable'] as String?;
    final expectedValue = config['expected'];
    
    if (variableName == null) {
      return RValidationResult(passed: false, message: 'No variable specified', details: []);
    }
    
    try {
      final result = await _evalR('print($variableName)');
      final matches = result.contains(expectedValue.toString());
      
      return RValidationResult(
        passed: matches,
        message: matches 
            ? 'Variable "$variableName" has the correct value'
            : 'Variable "$variableName" does not match expected value',
        details: [if (!matches) 'Expected: $expectedValue, Got: $result'],
      );
    } catch (e) {
      return RValidationResult(passed: false, message: 'Error checking variable: $e', details: []);
    }
  }
  
  Future<RValidationResult> _validateFunctionResult(Map<String, dynamic> config) async {
    final functionCall = config['function'] as String?;
    final expectedResult = config['expected'];
    
    if (functionCall == null) {
      return RValidationResult(passed: false, message: 'No function specified', details: []);
    }
    
    try {
      final result = await _evalR(functionCall);
      final matches = result.contains(expectedResult.toString());
      
      return RValidationResult(
        passed: matches,
        message: matches ? 'Function returned correct result' : 'Function result incorrect',
        details: [if (!matches) 'Expected: $expectedResult, Got: $result'],
      );
    } catch (e) {
      return RValidationResult(passed: false, message: 'Error executing function: $e', details: []);
    }
  }
}

// JS interop extension for global eval
@JS('Function')
extension type JSFunction._(JSObject _) implements JSObject {
  external factory JSFunction(String code);
  external JSAny? callAsFunction([JSAny? thisArg]);
}

/// Result of R code execution
class RExecutionResult {
  final String output;
  final String? error;
  final bool success;
  
  RExecutionResult({
    required this.output,
    this.error,
    required this.success,
  });
}

/// Result of R code validation
class RValidationResult {
  final bool passed;
  final String message;
  final List<String> details;
  
  RValidationResult({
    required this.passed,
    required this.message,
    required this.details,
  });
}
