import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../main.dart';
import '../../widgets/translation_tabs.widget.dart';

/// Section Editor with multilingual support (6 languages)
/// Links spreadsheet templates and configures validation
/// Supports two section types: 'python' and 'spreadsheet'
class SectionEditorScreen extends StatefulWidget {
  final Exercise exercise;
  final Section? section;
  final String sectionType; // 'python' or 'spreadsheet'

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
  final _pythonSolutionCodeController = TextEditingController();  // Python solution code

  bool _isSaving = false;
  bool _isLoading = true;
  String? _extractedTemplateId;
  String? _extractedSolutionId;
  
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
  
  Map<String, Map<String, String>> _translations = {};
  late final TranslationService _translationService;

  bool get isEditing => widget.section != null;
  
  /// Get the effective section type (from existing section when editing, or from widget param for new)
  String get effectiveSectionType => widget.section?.sectionType ?? widget.sectionType;
  
  /// Check if this is a Python section
  bool get isPythonSection => effectiveSectionType == 'python';

  @override
  void initState() {
    super.initState();
    _translationService = TranslationService(supabase);
    
    // Initialize controllers for each language
    for (final lang in _languages) {
      final code = lang['code'] as String;
      _templateControllers[code] = TextEditingController();
      _solutionControllers[code] = TextEditingController();
    }
    
    if (widget.section != null) {
      _displayOrderController.text = widget.section!.displayOrder.toString();
      _xpRewardController.text = widget.section!.xpReward.toString();
      
      // Load legacy template URL (backward compatibility)
      if (widget.section!.templateSpreadsheetId != null) {
        _templateUrlController.text = 'https://docs.google.com/spreadsheets/d/${widget.section!.templateSpreadsheetId}/edit';
        _extractedTemplateId = widget.section!.templateSpreadsheetId;
      }
      
      // Load language-specific templates
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
    for (final controller in _templateControllers.values) {
      controller.dispose();
    }
    for (final controller in _solutionControllers.values) {
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
    
    // Check if at least one template is provided (only required for spreadsheet sections)
    if (!isPythonSection) {
      final hasAnyTemplate = _extractedTemplateId != null || 
          _templateControllers.values.any((c) => _extractSpreadsheetId(c.text) != null);
      if (!hasAnyTemplate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter at least one template spreadsheet URL'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final englishInstructions = _translations['en']?['instructions']?.trim() ?? '';
      final englishExplanation = _translations['en']?['explanation']?.trim() ?? '';
      final englishHint = _translations['en']?['hint']?.trim() ?? '';
      
      final data = <String, dynamic>{
        'exercise_id': widget.exercise.id,
        'title': englishTitle,
        'explanation': englishExplanation.isEmpty ? null : englishExplanation,
        'instructions': englishInstructions.isEmpty ? null : englishInstructions,
        'hint': englishHint.isEmpty ? null : englishHint,
        'display_order': int.tryParse(_displayOrderController.text) ?? 1,
        'xp_reward': int.tryParse(_xpRewardController.text) ?? 10,
        'section_type': effectiveSectionType,
        'supports_python': isPythonSection,
        'supports_spreadsheet': !isPythonSection,
      };
      
      // Add spreadsheet-specific fields only for spreadsheet sections
      if (!isPythonSection) {
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
      
      // Add Python-specific fields only for Python sections
      if (isPythonSection) {
        data['python_solution_code'] = _pythonSolutionCodeController.text.trim().isEmpty 
            ? null 
            : _pythonSolutionCodeController.text.trim();
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
    final sectionTypeLabel = isPythonSection ? 'Python' : 'Spreadsheet';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing 
            ? 'Edit $sectionTypeLabel Section' 
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
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section type indicator
                        Card(
                          color: isPythonSection 
                              ? Colors.deepPurple.shade50 
                              : Colors.green.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(
                                  isPythonSection ? Icons.code : Icons.table_chart,
                                  size: 20, 
                                  color: isPythonSection 
                                      ? Colors.deepPurple.shade700 
                                      : Colors.green.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isPythonSection ? 'Python Section' : 'Spreadsheet Section',
                                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        'Exercise: ${widget.exercise.title}',
                                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Section Details (Title, Explanation, Instructions, Hint)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Section Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                TranslationTabs(
                                  fields: const [
                                    TranslationField(key: 'title', label: 'Title', isRequired: true, hint: 'e.g., Cashflows'),
                                    TranslationField(key: 'explanation', label: 'Explanation', maxLines: 4, isResizable: true, hint: 'Brief explanation of the topic'),
                                    TranslationField(key: 'instructions', label: 'Instructions', maxLines: 6, isResizable: true, hint: 'Step-by-step instructions for students'),
                                    TranslationField(key: 'hint', label: 'Hint', maxLines: 4, isResizable: true, hint: 'Help text shown when student clicks "Take a hint" (reduces XP by 30%)'),
                                  ],
                                  translations: _translations,
                                  onChanged: (t) => setState(() => _translations = t),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Settings (Display Order, XP Reward) - moved here after Hint
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Settings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _displayOrderController, 
                                        decoration: const InputDecoration(
                                          labelText: 'Display Order', 
                                          border: OutlineInputBorder(),
                                        ), 
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _xpRewardController, 
                                        decoration: const InputDecoration(
                                          labelText: 'XP Reward', 
                                          border: OutlineInputBorder(), 
                                          prefixIcon: Icon(Icons.star),
                                        ), 
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // SPREADSHEET-ONLY: Template & Solution Spreadsheets
                        if (!isPythonSection) ...[
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.table_chart, color: Colors.green.shade700),
                                      const SizedBox(width: 8),
                                      Text('Template & Solution Spreadsheets', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
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
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Validation Settings
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.check_circle_outline, color: Colors.blue.shade700),
                                      const SizedBox(width: 8),
                                      Text('Validation Settings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
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
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Warning card for spreadsheet sections
                          Card(
                            color: Colors.amber.withValues(alpha: 0.1),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
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
                          ),
                        ],
                        
                        // PYTHON-ONLY: Python Solution Code
                        if (isPythonSection) ...[
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.code, color: Colors.deepPurple.shade700),
                                      const SizedBox(width: 8),
                                      Text('Python Solution Code', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'The correct Python code that students should write. Shown when "Show Answer" is clicked (-50% XP).',
                                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _pythonSolutionCodeController,
                                    maxLines: 12,
                                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                                    decoration: InputDecoration(
                                      labelText: 'Python Solution Code',
                                      border: const OutlineInputBorder(),
                                      alignLabelWithHint: true,
                                      hintText: '# Complete Python solution...\nimport pandas as pd\n\n# Load data...',
                                      hintStyle: TextStyle(color: Colors.grey.shade400, fontFamily: 'monospace'),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Test in Browser button
                                  if (isEditing)
                                    Tooltip(
                                      message: 'Opens the section in your web browser to test the solution code',
                                      child: OutlinedButton.icon(
                                        onPressed: () async {
                                          final title = widget.section!.title.toLowerCase()
                                              .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
                                              .replaceAll(RegExp(r'^-|-$'), '');
                                          final url = 'http://localhost:3000/#/sections/$title';
                                          if (await canLaunchUrl(Uri.parse(url))) {
                                            await launchUrl(Uri.parse(url));
                                          }
                                        },
                                        icon: const Icon(Icons.open_in_browser),
                                        label: const Text('Test in Browser'),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
