import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import '../../main.dart';
import '../../widgets/translation_tabs.widget.dart';

/// Section Editor with multilingual support (6 languages)
/// Links spreadsheet templates and configures validation
class SectionEditorScreen extends StatefulWidget {
  final Exercise exercise;
  final Section? section;

  const SectionEditorScreen({super.key, required this.exercise, this.section});

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
    
    // Check if at least one template is provided (either legacy or language-specific)
    final hasAnyTemplate = _extractedTemplateId != null || 
        _templateControllers.values.any((c) => _extractSpreadsheetId(c.text) != null);
    if (!hasAnyTemplate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least one template spreadsheet URL'), backgroundColor: Colors.red),
      );
      return;
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
        'template_spreadsheet_id': _extractedTemplateId,
        'xp_reward': int.tryParse(_xpRewardController.text) ?? 10,
        'python_solution_code': _pythonSolutionCodeController.text.trim().isEmpty 
            ? null 
            : _pythonSolutionCodeController.text.trim(),
      };
      
      // Add language-specific template and solution IDs
      for (final lang in _languages) {
        final code = lang['code'] as String;
        final templateId = _extractSpreadsheetId(_templateControllers[code]?.text ?? '');
        final solutionId = _extractSpreadsheetId(_solutionControllers[code]?.text ?? '');
        data['template_spreadsheet_$code'] = templateId;
        data['solution_spreadsheet_$code'] = solutionId;
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

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Section' : 'New Section'),
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
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            color: colorScheme.surfaceContainerHighest,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(Icons.assignment, size: 20, color: Colors.orange.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text('Exercise: ${widget.exercise.title}',
                                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
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
                                      TranslationField(key: 'explanation', label: 'Explanation', maxLines: 4, isResizable: true, hint: 'Brief explanation of the topic (e.g., "Companies pay dividends throughout the year")'),
                                      TranslationField(key: 'instructions', label: 'Instructions', maxLines: 6, isResizable: true, hint: 'Step-by-step instructions for students to follow'),
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
                                    'Configure spreadsheet templates for each language. Students will see the template matching their selected language.',
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
                                  // Template URL for selected language
                                  TextFormField(
                                    controller: _templateControllers[_selectedSpreadsheetLang],
                                    decoration: InputDecoration(
                                      labelText: 'Template Spreadsheet URL (${_languages.firstWhere((l) => l['code'] == _selectedSpreadsheetLang)['label']})',
                                      border: const OutlineInputBorder(),
                                      prefixIcon: const Icon(Icons.link),
                                      hintText: 'https://docs.google.com/spreadsheets/d/.../edit',
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  const SizedBox(height: 16),
                                  // Solution URL for selected language
                                  TextFormField(
                                    controller: _solutionControllers[_selectedSpreadsheetLang],
                                    decoration: InputDecoration(
                                      labelText: 'Solution Spreadsheet URL (${_languages.firstWhere((l) => l['code'] == _selectedSpreadsheetLang)['label']}) - Optional',
                                      border: const OutlineInputBorder(),
                                      prefixIcon: const Icon(Icons.verified),
                                      hintText: 'https://docs.google.com/spreadsheets/d/.../edit',
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  const SizedBox(height: 12),
                                  // Show extracted IDs
                                  Builder(builder: (context) {
                                    final templateId = _extractSpreadsheetId(_templateControllers[_selectedSpreadsheetLang]?.text ?? '');
                                    final solutionId = _extractSpreadsheetId(_solutionControllers[_selectedSpreadsheetLang]?.text ?? '');
                                    if (templateId == null && solutionId == null) return const SizedBox.shrink();
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (templateId != null)
                                            Row(
                                              children: [
                                                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                                const SizedBox(width: 6),
                                                Text('Template: ', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                                                Expanded(child: Text(templateId, style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'))),
                                              ],
                                            ),
                                          if (solutionId != null) ...[
                                            if (templateId != null) const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.check_circle, color: Colors.blue, size: 16),
                                                const SizedBox(width: 6),
                                                Text('Solution: ', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                                                Expanded(child: Text(solutionId, style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'))),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Legacy template (for backward compatibility)
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Text('Legacy Template (Optional)', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                            children: [
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('This is the fallback template used when no language-specific template is available.', style: theme.textTheme.bodySmall),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _templateUrlController,
                                        decoration: const InputDecoration(
                                          labelText: 'Legacy Template URL',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.link),
                                        ),
                                        onChanged: _onTemplateUrlChanged,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
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
                          // Python Solution Code
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
                                      labelText: 'Python Solution Code (Optional)',
                                      border: const OutlineInputBorder(),
                                      alignLabelWithHint: true,
                                      hintText: '# Complete Python solution...\nimport pandas as pd\n\n# Load data...',
                                      hintStyle: TextStyle(color: Colors.grey.shade400, fontFamily: 'monospace'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 300,
                    decoration: BoxDecoration(border: Border(left: BorderSide(color: colorScheme.outlineVariant))),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Settings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          TextFormField(controller: _displayOrderController, decoration: const InputDecoration(labelText: 'Display Order', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                          const SizedBox(height: 16),
                          TextFormField(controller: _xpRewardController, decoration: const InputDecoration(labelText: 'XP Reward', border: OutlineInputBorder(), prefixIcon: Icon(Icons.star)), keyboardType: TextInputType.number),
                          const SizedBox(height: 24),
                          Card(
                            color: Colors.amber.withValues(alpha: 0.1),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.warning_amber, size: 20, color: Colors.amber.shade700),
                                      const SizedBox(width: 8),
                                      Text('Important', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.amber.shade800)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text('Share the template spreadsheet with your service account email.',
                                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.amber.shade900)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
