import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import '../../main.dart';
import '../../widgets/translation_tabs.widget.dart';

/// Exercise Editor with multilingual support (6 languages)
class ExerciseEditorScreen extends StatefulWidget {
  final Lesson lesson;
  final Exercise? exercise;

  const ExerciseEditorScreen({super.key, required this.lesson, this.exercise});

  @override
  State<ExerciseEditorScreen> createState() => _ExerciseEditorScreenState();
}

class _ExerciseEditorScreenState extends State<ExerciseEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isSaving = false;
  bool _isLoading = true;
  
  Map<String, Map<String, String>> _translations = {};
  late final TranslationService _translationService;

  bool get isEditing => widget.exercise != null;

  @override
  void initState() {
    super.initState();
    _translationService = TranslationService(supabase);
    
    if (widget.exercise != null) {
      _loadTranslations();
    } else {
      _translations = {
        'en': {
          'title': 'Exercise: ${widget.lesson.title}',
          'instructions': '',
        },
      };
      _isLoading = false;
    }
  }

  Future<void> _loadTranslations() async {
    final translations = await _translationService.getTranslations(
      entityType: TranslatableEntityTypes.exercise,
      entityId: widget.exercise!.id,
    );
    
    if (translations.isEmpty || translations['en'] == null) {
      translations['en'] = {
        'title': widget.exercise!.title,
        'instructions': widget.exercise!.instructions,
      };
    }
    
    setState(() {
      _translations = translations;
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final englishTitle = _translations['en']?['title']?.trim() ?? '';
    final englishInstructions = _translations['en']?['instructions']?.trim() ?? '';
    
    if (englishTitle.isEmpty || englishInstructions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('English title and instructions are required'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final data = {
        'lesson_id': widget.lesson.id,
        'title': englishTitle,
        'instructions': englishInstructions,
      };

      String exerciseId;
      
      if (isEditing) {
        await supabase.from('exercises').update(data).eq('id', widget.exercise!.id);
        exerciseId = widget.exercise!.id;
      } else {
        final result = await supabase.from('exercises').insert(data).select().single();
        exerciseId = result['id'] as String;
      }

      await _translationService.saveTranslations(
        entityType: TranslatableEntityTypes.exercise,
        entityId: exerciseId,
        translations: _translations,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Exercise updated!' : 'Exercise created!')),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Exercise' : 'New Exercise'),
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
                                  Icon(Icons.book, size: 20, color: colorScheme.tertiary),
                                  const SizedBox(width: 8),
                                  Text('Lesson ${widget.lesson.displayOrder}: ${widget.lesson.title}',
                                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
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
                                  Text('Exercise Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 16),
                                  TranslationTabs(
                                    fields: const [
                                      TranslationField(key: 'title', label: 'Title', isRequired: true, hint: 'e.g., Calculating the economic profit of investments'),
                                      TranslationField(key: 'instructions', label: 'Overview', maxLines: 10, isRequired: true, isResizable: true, hint: 'Brief explanation of what this exercise covers'),
                                    ],
                                    translations: _translations,
                                    onChanged: (t) => setState(() => _translations = t),
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
                          Text('Information', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Card(
                            color: colorScheme.surfaceContainerHighest,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.info_outline, size: 20, color: colorScheme.primary),
                                      const SizedBox(width: 8),
                                      Text('About Exercises', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'An exercise contains sections with Google Sheets spreadsheets that students must complete.',
                                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'After creating the exercise, add sections to link spreadsheet templates.',
                                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                  ),
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
