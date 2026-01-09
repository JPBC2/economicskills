import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../main.dart';
import '../../widgets/translation_tabs.widget.dart';

/// Section Editor with multilingual support (11 languages)
/// Links spreadsheet templates, Python starter code, and configures validation
/// Supports sections with Spreadsheet, Python, or both tools
class SectionEditorScreen extends StatefulWidget {
  final Exercise exercise;
  final Section? section;
  final String sectionType; // 'python', 'spreadsheet', or 'both' (for new sections)

  const SectionEditorScreen({
    super.key,
    required this.exercise,
    this.section,
    this.sectionType = 'spreadsheet', // Default to spreadsheet for backwards compatibility
  });

  @override
  State<SectionEditorScreen> createState() => _SectionEditorScreenState();
}

class _SectionEditorScreenState extends State<SectionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayOrderController = TextEditingController(text: '1');
  final _xpRewardController = TextEditingController(text: '10');
  final _templateUrlController = TextEditingController();
  final _solutionUrlController = TextEditingController();
  final _validationRangeController = TextEditingController();
  final _pythonSolutionCodeController = TextEditingController();
  final _pythonValidationConfigController = TextEditingController();

  // Tool-specific controllers
  final _instructionsSpreadsheetController = TextEditingController();
  final _instructionsPythonController = TextEditingController();
  final _instructionsRController = TextEditingController();
  final _hintSpreadsheetController = TextEditingController();
  final _hintPythonController = TextEditingController();
  final _hintRController = TextEditingController();
  final _xpRewardSpreadsheetController = TextEditingController(text: '10');
  final _xpRewardPythonController = TextEditingController(text: '10');
  final _xpRewardRController = TextEditingController(text: '10');
  
  // R-specific controllers
  final _rSolutionCodeController = TextEditingController();
  final _rValidationConfigController = TextEditingController();

  bool _isSaving = false;
  bool _isLoading = true;
  String? _extractedTemplateId;
  String? _extractedSolutionId;

  // Tool support flags (all can be true)
  bool _supportsSpreadsheet = true;
  bool _supportsPython = false;
  bool _supportsR = false;

  // Collapsible section states
  bool _detailsExpanded = true;
  bool _spreadsheetExpanded = true;
  bool _pythonExpanded = true;
  bool _rExpanded = true;
  
  // Supported languages for template URLs
  static const _languages = [
    {'code': 'en', 'label': 'English'},
    {'code': 'es', 'label': 'Español'},
    {'code': 'zh', 'label': '中文'},
    {'code': 'ru', 'label': 'Русский'},
    {'code': 'fr', 'label': 'Français'},
    {'code': 'pt', 'label': 'Português'},
    {'code': 'it', 'label': 'Italiano'},
    {'code': 'ca', 'label': 'Català'},
    {'code': 'ro', 'label': 'Română'},
    {'code': 'de', 'label': 'Deutsch'},
    {'code': 'nl', 'label': 'Nederlands'},
  ];
  
  // Language-specific template and solution URLs
  Map<String, TextEditingController> _templateControllers = {};
  Map<String, TextEditingController> _solutionControllers = {};
  String _selectedSpreadsheetLang = 'en';

  // Language-specific Python starter code
  Map<String, TextEditingController> _pythonStarterCodeControllers = {};
  String _selectedPythonLang = 'en';
  
  // Language-specific R starter code
  Map<String, TextEditingController> _rStarterCodeControllers = {};
  String _selectedRLang = 'en';
  
  Map<String, Map<String, String>> _translations = {};
  late final TranslationService _translationService;

  bool get isEditing => widget.section != null;

  /// Check if spreadsheet tool is enabled
  bool get hasSpreadsheet => _supportsSpreadsheet;

  /// Check if Python tool is enabled
  bool get hasPython => _supportsPython;
  
  /// Check if R tool is enabled
  bool get hasR => _supportsR;

  @override
  void initState() {
    super.initState();
    _translationService = TranslationService(supabase);

    // Initialize controllers for each language
    for (final lang in _languages) {
      final code = lang['code'] as String;
      _templateControllers[code] = TextEditingController();
      _solutionControllers[code] = TextEditingController();
      _pythonStarterCodeControllers[code] = TextEditingController();
      _rStarterCodeControllers[code] = TextEditingController();
    }

    // Set initial tool support based on sectionType parameter
    if (widget.sectionType == 'python') {
      _supportsSpreadsheet = false;
      _supportsPython = true;
      _supportsR = false;
    } else if (widget.sectionType == 'r') {
      _supportsSpreadsheet = false;
      _supportsPython = false;
      _supportsR = true;
    } else if (widget.sectionType == 'both') {
      _supportsSpreadsheet = true;
      _supportsPython = true;
      _supportsR = false;
    } else if (widget.sectionType == 'all') {
      _supportsSpreadsheet = true;
      _supportsPython = true;
      _supportsR = true;
    } else {
      _supportsSpreadsheet = true;
      _supportsPython = false;
      _supportsR = false;
    }

    if (widget.section != null) {
      _displayOrderController.text = widget.section!.displayOrder.toString();
      _xpRewardController.text = widget.section!.xpReward.toString();

      // Load tool support flags from existing section
      _supportsSpreadsheet = widget.section!.supportsSpreadsheet;
      _supportsPython = widget.section!.supportsPython;
      _supportsR = widget.section!.supportsR;

      // Load legacy template URL (backward compatibility)
      if (widget.section!.templateSpreadsheetId != null) {
        _templateUrlController.text = 'https://docs.google.com/spreadsheets/d/${widget.section!.templateSpreadsheetId}/edit';
        _extractedTemplateId = widget.section!.templateSpreadsheetId;
      }

      // Load language-specific templates and solutions
      for (final lang in _languages) {
        final code = lang['code'] as String;
        final templateId = widget.section!.templateSpreadsheets[code];
        final solutionId = widget.section!.solutionSpreadsheets[code];
        if (templateId != null && templateId.isNotEmpty) {
          _templateControllers[code]!.text = 'https://docs.google.com/spreadsheets/d/$templateId/edit';
        }
        if (solutionId != null && solutionId.isNotEmpty) {
          _solutionControllers[code]!.text = 'https://docs.google.com/spreadsheets/d/$solutionId/edit';
        }
      }

      // Load Python solution code
      if (widget.section!.pythonSolutionCode != null) {
        _pythonSolutionCodeController.text = widget.section!.pythonSolutionCode!;
      }

      // Load Python starter code for each language
      for (final lang in _languages) {
        final code = lang['code'] as String;
        final starterCode = widget.section!.pythonStarterCode[code];
        if (starterCode != null && starterCode.isNotEmpty) {
          _pythonStarterCodeControllers[code]!.text = starterCode;
        }
      }

      // Load Python validation config
      if (widget.section!.pythonValidationConfig != null) {
        try {
          final jsonString = const JsonEncoder.withIndent('  ')
              .convert(widget.section!.pythonValidationConfig);
          _pythonValidationConfigController.text = jsonString;
        } catch (e) {
          _pythonValidationConfigController.text = '';
        }
      }

      // Load tool-specific fields
      if (widget.section!.instructionsSpreadsheet != null) {
        _instructionsSpreadsheetController.text = widget.section!.instructionsSpreadsheet!;
      }
      if (widget.section!.instructionsPython != null) {
        _instructionsPythonController.text = widget.section!.instructionsPython!;
      }
      if (widget.section!.instructionsR != null) {
        _instructionsRController.text = widget.section!.instructionsR!;
      }
      if (widget.section!.hintSpreadsheet != null) {
        _hintSpreadsheetController.text = widget.section!.hintSpreadsheet!;
      }
      if (widget.section!.hintPython != null) {
        _hintPythonController.text = widget.section!.hintPython!;
      }
      if (widget.section!.hintR != null) {
        _hintRController.text = widget.section!.hintR!;
      }
      _xpRewardSpreadsheetController.text = widget.section!.xpRewardSpreadsheet.toString();
      _xpRewardPythonController.text = widget.section!.xpRewardPython.toString();
      _xpRewardRController.text = widget.section!.xpRewardR.toString();
      
      // Load R solution code
      if (widget.section!.rSolutionCode != null) {
        _rSolutionCodeController.text = widget.section!.rSolutionCode!;
      }
      
      // Load R starter code for each language
      for (final lang in _languages) {
        final code = lang['code'] as String;
        final starterCode = widget.section!.rStarterCode[code];
        if (starterCode != null && starterCode.isNotEmpty) {
          _rStarterCodeControllers[code]!.text = starterCode;
        }
      }
      
      // Load R validation config
      if (widget.section!.rValidationConfig != null) {
        try {
          final jsonString = const JsonEncoder.withIndent('  ')
              .convert(widget.section!.rValidationConfig);
          _rValidationConfigController.text = jsonString;
        } catch (e) {
          _rValidationConfigController.text = '';
        }
      }

      _loadTranslations();
      _loadValidationRule(); // Load existing validation rule
    } else {
      _loadNextDisplayOrder();
      _translations = {'en': {'title': '', 'explanation': '', 'instructions': '', 'hint': ''}};
      _isLoading = false;
    }
  }

  Future<void> _loadValidationRule() async {
    try {
      final rule = await supabase
          .from('validation_rules')
          .select()
          .eq('section_id', widget.section!.id)
          .maybeSingle();
      
      if (rule != null && mounted) {
        final config = rule['rule_config'] as Map<String, dynamic>?;
        if (config != null) {
          final solutionId = config['solution_spreadsheet_id'] as String?;
          final range = config['range'] as String?;
          if (solutionId != null) {
            _solutionUrlController.text = 'https://docs.google.com/spreadsheets/d/$solutionId/edit';
            _extractedSolutionId = solutionId;
          }
          if (range != null) {
            _validationRangeController.text = range;
          }
          setState(() {});
        }
      }
    } catch (e) {
      // Ignore errors loading validation rule
    }
  }

  Future<void> _loadNextDisplayOrder() async {
    try {
      final response = await supabase
          .from('sections')
          .select('display_order')
          .eq('exercise_id', widget.exercise.id)
          .order('display_order', ascending: false)
          .limit(1);
      if (response.isNotEmpty) {
        _displayOrderController.text = ((response[0]['display_order'] as int) + 1).toString();
      }
    } catch (e) {}
  }

  Future<void> _loadTranslations() async {
    final translations = await _translationService.getTranslations(
      entityType: TranslatableEntityTypes.section,
      entityId: widget.section!.id,
    );
    
    if (translations.isEmpty || translations['en'] == null) {
      translations['en'] = {
        'title': widget.section!.title,
        'explanation': widget.section!.explanation ?? '',
        'instructions': widget.section!.instructions ?? '',
        'hint': widget.section!.hint ?? '',
      };
    }
    
    setState(() {
      _translations = translations;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _displayOrderController.dispose();
    _xpRewardController.dispose();
    _templateUrlController.dispose();
    _solutionUrlController.dispose();
    _validationRangeController.dispose();
    _pythonSolutionCodeController.dispose();
    _pythonValidationConfigController.dispose();
    // Dispose tool-specific controllers
    _instructionsSpreadsheetController.dispose();
    _instructionsPythonController.dispose();
    _hintSpreadsheetController.dispose();
    _hintPythonController.dispose();
    _xpRewardSpreadsheetController.dispose();
    _xpRewardPythonController.dispose();
    for (final controller in _templateControllers.values) {
      controller.dispose();
    }
    for (final controller in _solutionControllers.values) {
      controller.dispose();
    }
    for (final controller in _pythonStarterCodeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _extractSpreadsheetId(String url) {
    if (url.isEmpty) return null;
    final regex = RegExp(r'/spreadsheets/d/([a-zA-Z0-9-_]+)');
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  void _onTemplateUrlChanged(String value) {
    setState(() => _extractedTemplateId = _extractSpreadsheetId(value));
  }

  void _onSolutionUrlChanged(String value) {
    setState(() => _extractedSolutionId = _extractSpreadsheetId(value));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final englishTitle = _translations['en']?['title']?.trim() ?? '';
    if (englishTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('English title is required'), backgroundColor: Colors.red),
      );
      return;
    }
    
    // Check if at least one tool is selected
    if (!_supportsSpreadsheet && !_supportsPython && !_supportsR) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable at least one tool (Spreadsheet, Python, or R)'), backgroundColor: Colors.red),
      );
      return;
    }

    // Check if at least one template is provided (only required if spreadsheet is enabled)
    if (_supportsSpreadsheet) {
      final hasAnyTemplate = _extractedTemplateId != null ||
          _templateControllers.values.any((c) => _extractSpreadsheetId(c.text) != null);
      if (!hasAnyTemplate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter at least one template spreadsheet URL'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    // Validate Python validation config JSON if provided
    Map<String, dynamic>? validationConfig;
    if (_supportsPython && _pythonValidationConfigController.text.trim().isNotEmpty) {
      try {
        validationConfig = jsonDecode(_pythonValidationConfigController.text.trim()) as Map<String, dynamic>;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid JSON in Python Validation Config'), backgroundColor: Colors.red),
        );
        return;
      }
    }
    
    // Validate R validation config JSON if provided
    Map<String, dynamic>? rValidationConfig;
    if (_supportsR && _rValidationConfigController.text.trim().isNotEmpty) {
      try {
        rValidationConfig = jsonDecode(_rValidationConfigController.text.trim()) as Map<String, dynamic>;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid JSON in R Validation Config'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final englishInstructions = _translations['en']?['instructions']?.trim() ?? '';
      final englishExplanation = _translations['en']?['explanation']?.trim() ?? '';
      final englishHint = _translations['en']?['hint']?.trim() ?? '';
      
      // Determine section_type for backwards compatibility
      String sectionType;
      if (_supportsSpreadsheet && _supportsPython && _supportsR) {
        sectionType = 'all';
      } else if (_supportsSpreadsheet && _supportsPython) {
        sectionType = 'both';
      } else if (_supportsR) {
        sectionType = 'r';
      } else if (_supportsPython) {
        sectionType = 'python';
      } else {
        sectionType = 'spreadsheet';
      }

      final data = <String, dynamic>{
        'exercise_id': widget.exercise.id,
        'title': englishTitle,
        'explanation': englishExplanation.isEmpty ? null : englishExplanation,
        'instructions': englishInstructions.isEmpty ? null : englishInstructions,
        'hint': englishHint.isEmpty ? null : englishHint,
        'display_order': int.tryParse(_displayOrderController.text) ?? 1,
        'xp_reward': int.tryParse(_xpRewardController.text) ?? 10,
        'section_type': sectionType,
        'supports_python': _supportsPython,
        'supports_spreadsheet': _supportsSpreadsheet,
        // Tool-specific Instructions, Hint, and XP fields
        'instructions_spreadsheet': _instructionsSpreadsheetController.text.trim().isEmpty ? null : _instructionsSpreadsheetController.text.trim(),
        'instructions_python': _instructionsPythonController.text.trim().isEmpty ? null : _instructionsPythonController.text.trim(),
        'hint_spreadsheet': _hintSpreadsheetController.text.trim().isEmpty ? null : _hintSpreadsheetController.text.trim(),
        'hint_python': _hintPythonController.text.trim().isEmpty ? null : _hintPythonController.text.trim(),
        'xp_reward_spreadsheet': int.tryParse(_xpRewardSpreadsheetController.text) ?? 10,
        'xp_reward_python': int.tryParse(_xpRewardPythonController.text) ?? 10,
        'supports_r': _supportsR,
        'instructions_r': _instructionsRController.text.trim().isEmpty ? null : _instructionsRController.text.trim(),
        'hint_r': _hintRController.text.trim().isEmpty ? null : _hintRController.text.trim(),
        'xp_reward_r': int.tryParse(_xpRewardRController.text) ?? 10,
      };

      // Add spreadsheet-specific fields if spreadsheet is enabled
      if (_supportsSpreadsheet) {
        data['template_spreadsheet_id'] = _extractedTemplateId;

        // Add language-specific template and solution IDs
        for (final lang in _languages) {
          final code = lang['code'] as String;
          final templateId = _extractSpreadsheetId(_templateControllers[code]?.text ?? '');
          final solutionId = _extractSpreadsheetId(_solutionControllers[code]?.text ?? '');
          data['template_spreadsheet_$code'] = templateId;
          data['solution_spreadsheet_$code'] = solutionId;
        }
      }

      // Add Python-specific fields if Python is enabled
      if (_supportsPython) {
        data['python_solution_code'] = _pythonSolutionCodeController.text.trim().isEmpty
            ? null
            : _pythonSolutionCodeController.text.trim();

        // Add Python starter code for each language
        for (final lang in _languages) {
          final code = lang['code'] as String;
          final starterCode = _pythonStarterCodeControllers[code]?.text.trim();
          data['python_starter_code_$code'] = (starterCode?.isEmpty ?? true) ? null : starterCode;
        }

        // Add Python validation config
        data['python_validation_config'] = validationConfig;
      }
      
      // Add R-specific fields if R is enabled
      if (_supportsR) {
        data['r_solution_code'] = _rSolutionCodeController.text.trim().isEmpty
            ? null
            : _rSolutionCodeController.text.trim();
        
        // Add R starter code for each language
        for (final lang in _languages) {
          final code = lang['code'] as String;
          final starterCode = _rStarterCodeControllers[code]?.text.trim();
          data['r_starter_code_$code'] = (starterCode?.isEmpty ?? true) ? null : starterCode;
        }
        
        // Add R validation config
        data['r_validation_config'] = rValidationConfig;
      }

      String sectionId;
      
      if (isEditing) {
        await supabase.from('sections').update(data).eq('id', widget.section!.id);
        sectionId = widget.section!.id;
      } else {
        final result = await supabase.from('sections').insert(data).select().single();
        sectionId = result['id'] as String;
      }

      await _translationService.saveTranslations(
        entityType: TranslatableEntityTypes.section,
        entityId: sectionId,
        translations: _translations,
      );

      // Save validation rule if configured
      if (_extractedSolutionId != null && _validationRangeController.text.trim().isNotEmpty) {
        await _saveValidationRule(sectionId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Section updated!' : 'Section created!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _saveValidationRule(String sectionId) async {
    final existing = await supabase
        .from('validation_rules')
        .select('id')
        .eq('section_id', sectionId)
        .maybeSingle();

    final ruleData = {
      'section_id': sectionId,
      'rule_type': 'cell_range_values',
      'rule_config': {
        'range': _validationRangeController.text.trim(),
        'solution_spreadsheet_id': _extractedSolutionId,
        'tolerance': 0.01,
      },
      'display_order': 1,
      'error_message': 'Your answers do not match the expected values.',
    };

    if (existing != null) {
      await supabase.from('validation_rules').update(ruleData).eq('id', existing['id']);
    } else {
      await supabase.from('validation_rules').insert(ruleData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Build section type label
    String sectionTypeLabel;
    if (_supportsSpreadsheet && _supportsPython && _supportsR) {
      sectionTypeLabel = 'Spreadsheet + Python + R';
    } else if (_supportsSpreadsheet && _supportsPython) {
      sectionTypeLabel = 'Spreadsheet + Python';
    } else if (_supportsSpreadsheet && _supportsR) {
      sectionTypeLabel = 'Spreadsheet + R';
    } else if (_supportsPython && _supportsR) {
      sectionTypeLabel = 'Python + R';
    } else if (_supportsR) {
      sectionTypeLabel = 'R';
    } else if (_supportsPython) {
      sectionTypeLabel = 'Python';
    } else {
      sectionTypeLabel = 'Spreadsheet';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing
            ? 'Edit Section'
            : 'New $sectionTypeLabel Section'),
        actions: [
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(isEditing ? 'Save' : 'Create'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                        // Exercise info
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(Icons.assignment, size: 20, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Exercise: ${widget.exercise.title}',
                                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tool Selection Card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Exercise Tools', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(
                                  'Select which tools students can use to complete this section. You can enable both.',
                                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CheckboxListTile(
                                        value: _supportsSpreadsheet,
                                        onChanged: (value) {
                                          setState(() => _supportsSpreadsheet = value ?? false);
                                        },
                                        title: Row(
                                          children: [
                                            Icon(Icons.table_chart, color: Colors.green.shade700, size: 20),
                                            const SizedBox(width: 8),
                                            const Text('Google Sheets'),
                                          ],
                                        ),
                                        subtitle: const Text('Spreadsheet exercises'),
                                        controlAffinity: ListTileControlAffinity.leading,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    Expanded(
                                      child: CheckboxListTile(
                                        value: _supportsPython,
                                        onChanged: (value) {
                                          setState(() => _supportsPython = value ?? false);
                                        },
                                        title: Row(
                                          children: [
                                            Icon(Icons.code, color: Colors.deepPurple.shade700, size: 20),
                                            const SizedBox(width: 8),
                                            const Text('Python'),
                                          ],
                                        ),
                                        subtitle: const Text('Code exercises'),
                                        controlAffinity: ListTileControlAffinity.leading,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    Expanded(
                                      child: CheckboxListTile(
                                        value: _supportsR,
                                        onChanged: (value) {
                                          setState(() => _supportsR = value ?? false);
                                        },
                                        title: Row(
                                          children: [
                                            Icon(Icons.analytics, color: Colors.blue.shade700, size: 20),
                                            const SizedBox(width: 8),
                                            const Text('R'),
                                          ],
                                        ),
                                        subtitle: const Text('R exercises'),
                                        controlAffinity: ListTileControlAffinity.leading,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Section Details (Title, Explanation) - collapsible
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: ExpansionTile(
                            initiallyExpanded: _detailsExpanded,
                            onExpansionChanged: (expanded) => setState(() => _detailsExpanded = expanded),
                            leading: Icon(Icons.info_outline, color: colorScheme.primary),
                            title: Text('Section Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            subtitle: Text('Title, explanation, and display order', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TranslationTabs(
                                      fields: const [
                                        TranslationField(key: 'title', label: 'Title', isRequired: true, hint: 'e.g., Cashflows'),
                                        TranslationField(key: 'explanation', label: 'Explanation', maxLines: 4, isResizable: true, hint: 'Brief explanation of the topic'),
                                      ],
                                      translations: _translations,
                                      onChanged: (t) => setState(() => _translations = t),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _displayOrderController,
                                      decoration: const InputDecoration(
                                        labelText: 'Display Order',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // SPREADSHEET: Configuration (collapsible, shown if spreadsheet is enabled)
                        if (_supportsSpreadsheet) ...[
                          const SizedBox(height: 16),
                          Card(
                            clipBehavior: Clip.antiAlias,
                            child: ExpansionTile(
                              initiallyExpanded: _spreadsheetExpanded,
                              onExpansionChanged: (expanded) => setState(() => _spreadsheetExpanded = expanded),
                              leading: Icon(Icons.table_chart, color: Colors.green.shade700),
                              title: Text('Spreadsheet Configuration', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              subtitle: Text('Instructions, hint, XP, templates, and validation', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Spreadsheet Instructions
                                      TextFormField(
                                        controller: _instructionsSpreadsheetController,
                                        maxLines: 5,
                                        decoration: const InputDecoration(
                                          labelText: 'Instructions (Spreadsheet)',
                                          border: OutlineInputBorder(),
                                          alignLabelWithHint: true,
                                          hintText: 'Step-by-step instructions for completing the spreadsheet exercise...',
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Spreadsheet Hint
                                      TextFormField(
                                        controller: _hintSpreadsheetController,
                                        maxLines: 3,
                                        decoration: const InputDecoration(
                                          labelText: 'Hint (Spreadsheet) - reduces XP by 30%',
                                          border: OutlineInputBorder(),
                                          alignLabelWithHint: true,
                                          hintText: 'Help text shown when student clicks "Take a hint"...',
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Spreadsheet XP Reward
                                      TextFormField(
                                        controller: _xpRewardSpreadsheetController,
                                        decoration: const InputDecoration(
                                          labelText: 'XP Reward (Spreadsheet)',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.star, color: Colors.amber),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                      const SizedBox(height: 24),
                                      const Divider(),
                                      const SizedBox(height: 16),
                                      // Template & Solution Spreadsheets header
                                      Text('Template & Solution Spreadsheets', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Configure spreadsheet templates for each language.',
                                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                      ),
                                      const SizedBox(height: 16),
                                      // Language selector
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _languages.map((lang) {
                                          final code = lang['code'] as String;
                                          final label = lang['label'] as String;
                                          final hasTemplate = _extractSpreadsheetId(_templateControllers[code]?.text ?? '') != null;
                                          return ChoiceChip(
                                            label: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(label),
                                                if (hasTemplate) ...[
                                                  const SizedBox(width: 4),
                                                  Icon(Icons.check, size: 14, color: Colors.green.shade700),
                                                ],
                                              ],
                                            ),
                                            selected: _selectedSpreadsheetLang == code,
                                            onSelected: (_) => setState(() => _selectedSpreadsheetLang = code),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _templateControllers[_selectedSpreadsheetLang],
                                        decoration: InputDecoration(
                                          labelText: 'Template Spreadsheet URL (${_languages.firstWhere((l) => l['code'] == _selectedSpreadsheetLang)['label']})',
                                          border: const OutlineInputBorder(),
                                          prefixIcon: const Icon(Icons.link),
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _solutionControllers[_selectedSpreadsheetLang],
                                        decoration: InputDecoration(
                                          labelText: 'Solution Spreadsheet URL (${_languages.firstWhere((l) => l['code'] == _selectedSpreadsheetLang)['label']}) - Optional',
                                          border: const OutlineInputBorder(),
                                          prefixIcon: const Icon(Icons.verified),
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                      const SizedBox(height: 24),
                                      const Divider(),
                                      const SizedBox(height: 16),
                                      // Validation Settings
                                      Text('Validation Settings', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _validationRangeController,
                                        decoration: const InputDecoration(
                                          labelText: 'Validation Range',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.grid_on),
                                          hintText: 'e.g., O3:O102',
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Warning card
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.warning_amber, size: 20, color: Colors.amber.shade700),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Share the template spreadsheet with your service account email.',
                                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.amber.shade900),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        // PYTHON: Configuration (collapsible, shown if Python is enabled)
                        if (_supportsPython) ...[
                          const SizedBox(height: 16),
                          Card(
                            clipBehavior: Clip.antiAlias,
                            child: ExpansionTile(
                              initiallyExpanded: _pythonExpanded,
                              onExpansionChanged: (expanded) => setState(() => _pythonExpanded = expanded),
                              leading: Icon(Icons.code, color: Colors.deepPurple.shade700),
                              title: Text('Python Configuration', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              subtitle: Text('Instructions, hint, XP, starter code, and validation', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Python Instructions
                                      TextFormField(
                                        controller: _instructionsPythonController,
                                        maxLines: 5,
                                        decoration: const InputDecoration(
                                          labelText: 'Instructions (Python)',
                                          border: OutlineInputBorder(),
                                          alignLabelWithHint: true,
                                          hintText: 'Step-by-step instructions for completing the Python exercise...',
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Python Hint
                                      TextFormField(
                                        controller: _hintPythonController,
                                        maxLines: 3,
                                        decoration: const InputDecoration(
                                          labelText: 'Hint (Python) - reduces XP by 30%',
                                          border: OutlineInputBorder(),
                                          alignLabelWithHint: true,
                                          hintText: 'Help text shown when student clicks "Take a hint"...',
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Python XP Reward
                                      TextFormField(
                                        controller: _xpRewardPythonController,
                                        decoration: const InputDecoration(
                                          labelText: 'XP Reward (Python)',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.star, color: Colors.amber),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                      const SizedBox(height: 24),
                                      const Divider(),
                                      const SizedBox(height: 16),
                                      // Python Starter Code (multilingual)
                                      Text('Starter Code', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Text(
                                        'The initial code students see when they start the exercise. Include comments with TODO instructions.',
                                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                      ),
                                      const SizedBox(height: 16),
                                      // Language selector for Python starter code
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _languages.map((lang) {
                                          final code = lang['code'] as String;
                                          final label = lang['label'] as String;
                                          final hasCode = _pythonStarterCodeControllers[code]?.text.trim().isNotEmpty ?? false;
                                          return ChoiceChip(
                                            label: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(label),
                                                if (hasCode) ...[
                                                  const SizedBox(width: 4),
                                                  Icon(Icons.check, size: 14, color: Colors.deepPurple.shade700),
                                                ],
                                              ],
                                            ),
                                            selected: _selectedPythonLang == code,
                                            onSelected: (_) => setState(() => _selectedPythonLang = code),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _pythonStarterCodeControllers[_selectedPythonLang],
                                        maxLines: 15,
                                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                                        decoration: InputDecoration(
                                          labelText: 'Starter Code (${_languages.firstWhere((l) => l['code'] == _selectedPythonLang)['label']})',
                                          border: const OutlineInputBorder(),
                                          alignLabelWithHint: true,
                                          hintText: '# Import libraries\nimport pandas as pd\n\n# TODO: Load the data\n# df = pd.read_csv(...)\n\n# TODO: Calculate the result\n# result = ...',
                                          hintStyle: TextStyle(color: Colors.grey.shade400, fontFamily: 'monospace'),
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                      const SizedBox(height: 24),
                                      const Divider(),
                                      const SizedBox(height: 16),
                                      // Python Solution Code
                                      Text('Solution Code', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Text(
                                        'The correct Python code. Shown when "Show Answer" is clicked (-50% XP).',
                                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _pythonSolutionCodeController,
                                        maxLines: 12,
                                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                                        decoration: InputDecoration(
                                          labelText: 'Solution Code',
                                          border: const OutlineInputBorder(),
                                          alignLabelWithHint: true,
                                          hintText: '# Complete Python solution...\nimport pandas as pd\n\ndf = pd.read_csv(...)\nresult = df["column"].mean()',
                                          hintStyle: TextStyle(color: Colors.grey.shade400, fontFamily: 'monospace'),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      const Divider(),
                                      const SizedBox(height: 16),
                                      // Python Validation Config
                                      Text('Validation Configuration', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Text(
                                        'JSON configuration for validating student code. Defines what variables, values, or outputs to check.',
                                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _pythonValidationConfigController,
                                        maxLines: 12,
                                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                        decoration: InputDecoration(
                                          labelText: 'Validation Config (JSON)',
                                          border: const OutlineInputBorder(),
                                          alignLabelWithHint: true,
                                          hintText: '''{
  "validation_type": "simple",
  "steps": [
    {
      "step": 1,
      "type": "variable_exists",
      "name": "df",
      "expected_type": "DataFrame",
      "message_en": "Create a DataFrame called df"
    },
    {
      "step": 2,
      "type": "variable_value",
      "name": "result",
      "expected": 42.5,
      "tolerance": 0.01,
      "message_en": "Calculate the result"
    }
  ]
}''',
                                          hintStyle: TextStyle(color: Colors.grey.shade400, fontFamily: 'monospace'),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Validation type help
                                      ExpansionTile(
                                        title: Text('Validation Types Reference', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary)),
                                        tilePadding: EdgeInsets.zero,
                                        childrenPadding: const EdgeInsets.only(bottom: 8),
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('• variable_exists: Check if a variable exists with expected type', style: theme.textTheme.bodySmall),
                                                Text('• variable_value: Check if a variable equals expected value (±tolerance)', style: theme.textTheme.bodySmall),
                                                Text('• column_exists: Check if a DataFrame has a specific column', style: theme.textTheme.bodySmall),
                                                Text('• output_contains: Check if print output matches a regex pattern', style: theme.textTheme.bodySmall),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // R: Configuration (collapsible, shown if R is enabled)
                          if (_supportsR) ...[
                            const SizedBox(height: 16),
                            Card(
                              clipBehavior: Clip.antiAlias,
                              child: ExpansionTile(
                                initiallyExpanded: _rExpanded,
                                onExpansionChanged: (expanded) => setState(() => _rExpanded = expanded),
                                leading: Icon(Icons.analytics, color: Colors.blue.shade700),
                                title: Text('R Configuration', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                subtitle: Text('Instructions, hint, XP, starter code, and validation', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // R Instructions
                                        TextFormField(
                                          controller: _instructionsRController,
                                          maxLines: 5,
                                          decoration: const InputDecoration(
                                            labelText: 'Instructions (R)',
                                            border: OutlineInputBorder(),
                                            alignLabelWithHint: true,
                                            hintText: 'Step-by-step instructions for completing the R exercise...',
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        // R Hint
                                        TextFormField(
                                          controller: _hintRController,
                                          maxLines: 3,
                                          decoration: const InputDecoration(
                                            labelText: 'Hint (R) - reduces XP by 30%',
                                            border: OutlineInputBorder(),
                                            alignLabelWithHint: true,
                                            hintText: 'Help text shown when student clicks "Take a hint"...',
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        // R XP Reward
                                        TextFormField(
                                          controller: _xpRewardRController,
                                          decoration: const InputDecoration(
                                            labelText: 'XP Reward (R)',
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(Icons.star, color: Colors.amber),
                                          ),
                                          keyboardType: TextInputType.number,
                                        ),
                                        const SizedBox(height: 24),
                                        const Divider(),
                                        const SizedBox(height: 16),
                                        // R Starter Code (multilingual)
                                        Text('Starter Code', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        Text(
                                          'The initial R code students see when they start the exercise. Include comments with TODO instructions.',
                                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                        ),
                                        const SizedBox(height: 16),
                                        // Language selector for R starter code
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: _languages.map((lang) {
                                            final code = lang['code'] as String;
                                            final label = lang['label'] as String;
                                            final hasCode = _rStarterCodeControllers[code]?.text.trim().isNotEmpty ?? false;
                                            return ChoiceChip(
                                              label: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(label),
                                                  if (hasCode) ...[
                                                    const SizedBox(width: 4),
                                                    Icon(Icons.check, size: 14, color: Colors.blue.shade700),
                                                  ],
                                                ],
                                              ),
                                              selected: _selectedRLang == code,
                                              onSelected: (_) => setState(() => _selectedRLang = code),
                                            );
                                          }).toList(),
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: _rStarterCodeControllers[_selectedRLang],
                                          maxLines: 15,
                                          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                                          decoration: InputDecoration(
                                            labelText: 'Starter Code (${_languages.firstWhere((l) => l['code'] == _selectedRLang)['label']})',
                                            border: const OutlineInputBorder(),
                                            alignLabelWithHint: true,
                                            hintText: '# Load libraries\nlibrary(dplyr)\nlibrary(ggplot2)\n\n# TODO: Load the data\n# df <- read.csv(...)\n\n# TODO: Calculate the result\n# result <- ...',
                                            hintStyle: TextStyle(color: Colors.grey.shade400, fontFamily: 'monospace'),
                                          ),
                                          onChanged: (_) => setState(() {}),
                                        ),
                                        const SizedBox(height: 24),
                                        const Divider(),
                                        const SizedBox(height: 16),
                                        // R Solution Code
                                        Text('Solution Code', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        Text(
                                          'The correct R code. Shown when "Show Answer" is clicked (-50% XP).',
                                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: _rSolutionCodeController,
                                          maxLines: 12,
                                          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                                          decoration: InputDecoration(
                                            labelText: 'Solution Code',
                                            border: const OutlineInputBorder(),
                                            alignLabelWithHint: true,
                                            hintText: '# Complete R solution...\nlibrary(dplyr)\n\ndf <- read.csv(...)\nresult <- df %>% summarize(mean_value = mean(column))',
                                            hintStyle: TextStyle(color: Colors.grey.shade400, fontFamily: 'monospace'),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        const Divider(),
                                        const SizedBox(height: 16),
                                        // R Validation Config
                                        Text('Validation Configuration', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        Text(
                                          'JSON configuration for validating student R code. Defines what variables, values, or outputs to check.',
                                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: _rValidationConfigController,
                                          maxLines: 12,
                                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                          decoration: InputDecoration(
                                            labelText: 'Validation Config (JSON)',
                                            border: const OutlineInputBorder(),
                                            alignLabelWithHint: true,
                                            hintText: '{\n  "type": "variable_exists",\n  "variable": "result",\n  "expected": 42.5\n}',
                                            hintStyle: TextStyle(color: Colors.grey.shade400, fontFamily: 'monospace'),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // R Validation type help
                                        ExpansionTile(
                                          title: Text('Validation Types Reference', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary)),
                                          tilePadding: EdgeInsets.zero,
                                          childrenPadding: const EdgeInsets.only(bottom: 8),
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('• output_contains: Check if output contains expected strings', style: theme.textTheme.bodySmall),
                                                  Text('• variable_exists: Check if a variable exists', style: theme.textTheme.bodySmall),
                                                  Text('• variable_equals: Check if a variable equals expected value', style: theme.textTheme.bodySmall),
                                                  Text('• function_result: Check if a function returns expected result', style: theme.textTheme.bodySmall),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          // Test in Browser button
                          if (isEditing) ...[
                            const SizedBox(height: 16),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(Icons.open_in_browser, color: colorScheme.primary),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Test Section', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                          Text('Open this section in the web app to test', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                                        ],
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        var slug = widget.section!.title.toLowerCase()
                                            .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
                                            .replaceAll(RegExp(r'^-|-$'), '');
                                        // Remove existing tool suffix before adding
                                        if (slug.endsWith('-spreadsheet')) {
                                          slug = slug.substring(0, slug.length - '-spreadsheet'.length);
                                        } else if (slug.endsWith('-python')) {
                                          slug = slug.substring(0, slug.length - '-python'.length);
                                        } else if (slug.endsWith('-r')) {
                                          slug = slug.substring(0, slug.length - '-r'.length);
                                        }
                                        final url = 'http://localhost:3000/#/sections/$slug-python';
                                        if (await canLaunchUrl(Uri.parse(url))) {
                                          await launchUrl(Uri.parse(url));
                                        }
                                      },
                                      icon: Icon(Icons.code, color: Colors.deepPurple.shade700),
                                      label: const Text('Test Python'),
                                    ),
                                    if (_supportsSpreadsheet) ...[
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        onPressed: () async {
                                          var slug = widget.section!.title.toLowerCase()
                                              .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
                                              .replaceAll(RegExp(r'^-|-$'), '');
                                          if (slug.endsWith('-spreadsheet')) {
                                            slug = slug.substring(0, slug.length - '-spreadsheet'.length);
                                          } else if (slug.endsWith('-python')) {
                                            slug = slug.substring(0, slug.length - '-python'.length);
                                          } else if (slug.endsWith('-r')) {
                                            slug = slug.substring(0, slug.length - '-r'.length);
                                          }
                                          final url = 'http://localhost:3000/#/sections/$slug-spreadsheet';
                                          if (await canLaunchUrl(Uri.parse(url))) {
                                            await launchUrl(Uri.parse(url));
                                          }
                                        },
                                        icon: Icon(Icons.table_chart, color: Colors.green.shade700),
                                        label: const Text('Test Spreadsheet'),
                                      ),
                                    ],
                                    if (_supportsR) ...[
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        onPressed: () async {
                                          var slug = widget.section!.title.toLowerCase()
                                              .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
                                              .replaceAll(RegExp(r'^-|-$'), '');
                                          if (slug.endsWith('-spreadsheet')) {
                                            slug = slug.substring(0, slug.length - '-spreadsheet'.length);
                                          } else if (slug.endsWith('-python')) {
                                            slug = slug.substring(0, slug.length - '-python'.length);
                                          } else if (slug.endsWith('-r')) {
                                            slug = slug.substring(0, slug.length - '-r'.length);
                                          }
                                          final url = 'http://localhost:3000/#/sections/$slug-r';
                                          if (await canLaunchUrl(Uri.parse(url))) {
                                            await launchUrl(Uri.parse(url));
                                          }
                                        },
                                        icon: Icon(Icons.analytics, color: Colors.blue.shade700),
                                        label: const Text('Test R'),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
            ),
    );
  }
}
