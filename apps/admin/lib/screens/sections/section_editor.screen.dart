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

  bool _isSaving = false;
  bool _isLoading = true;
  String? _extractedTemplateId;
  String? _extractedSolutionId;
  
  Map<String, Map<String, String>> _translations = {};
  late final TranslationService _translationService;

  bool get isEditing => widget.section != null;

  @override
  void initState() {
    super.initState();
    _translationService = TranslationService(supabase);
    
    if (widget.section != null) {
      _displayOrderController.text = widget.section!.displayOrder.toString();
      _xpRewardController.text = widget.section!.xpReward.toString();
      _templateUrlController.text = 'https://docs.google.com/spreadsheets/d/${widget.section!.templateSpreadsheetId}/edit';
      _extractedTemplateId = widget.section!.templateSpreadsheetId;
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
    
    if (_extractedTemplateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid Google Sheets URL'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final englishInstructions = _translations['en']?['instructions']?.trim() ?? '';
      final englishExplanation = _translations['en']?['explanation']?.trim() ?? '';
      final englishHint = _translations['en']?['hint']?.trim() ?? '';
      
      final data = {
        'exercise_id': widget.exercise.id,
        'title': englishTitle,
        'explanation': englishExplanation.isEmpty ? null : englishExplanation,
        'instructions': englishInstructions.isEmpty ? null : englishInstructions,
        'hint': englishHint.isEmpty ? null : englishHint,
        'display_order': int.tryParse(_displayOrderController.text) ?? 1,
        'template_spreadsheet_id': _extractedTemplateId,
        'xp_reward': int.tryParse(_xpRewardController.text) ?? 10,
      };

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
                                      Text('Template Spreadsheet', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _templateUrlController,
                                    decoration: const InputDecoration(
                                      labelText: 'Template Spreadsheet URL',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.link),
                                      hintText: 'https://docs.google.com/spreadsheets/d/.../edit',
                                    ),
                                    onChanged: _onTemplateUrlChanged,
                                    validator: (v) => _extractSpreadsheetId(v ?? '') == null ? 'Invalid Google Sheets URL' : null,
                                  ),
                                  if (_extractedTemplateId != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text('ID: $_extractedTemplateId', style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace', color: Colors.green.shade700))),
                                        ],
                                      ),
                                    ),
                                  ],
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
                                      Icon(Icons.check_circle_outline, color: Colors.blue.shade700),
                                      const SizedBox(width: 8),
                                      Text('Validation Settings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _solutionUrlController,
                                    decoration: const InputDecoration(
                                      labelText: 'Solution Spreadsheet URL (Optional)',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.verified),
                                    ),
                                    onChanged: _onSolutionUrlChanged,
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
