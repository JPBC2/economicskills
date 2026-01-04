import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import '../../main.dart';
import '../../widgets/translation_tabs.widget.dart';
import '../units/units_list.screen.dart';

/// Course Editor with multilingual support (6 languages)
/// Allows creating/editing courses with translations
class CourseEditorScreen extends StatefulWidget {
  final Course? course;

  const CourseEditorScreen({super.key, this.course});

  @override
  State<CourseEditorScreen> createState() => _CourseEditorScreenState();
}

class _CourseEditorScreenState extends State<CourseEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayOrderController = TextEditingController(text: '0');
  
  bool _isActive = true;
  bool _isSaving = false;
  bool _isLoading = true;
  
  // Translations: { language: { field: value } }
  Map<String, Map<String, String>> _translations = {};
  
  late final TranslationService _translationService;

  bool get isEditing => widget.course != null;

  @override
  void initState() {
    super.initState();
    _translationService = TranslationService(supabase);
    
    if (widget.course != null) {
      _displayOrderController.text = widget.course!.displayOrder.toString();
      _isActive = widget.course!.isActive;
      _loadTranslations();
    } else {
      // Initialize with English title from course (for new courses)
      _translations = {
        'en': {'title': '', 'description': ''},
      };
      _isLoading = false;
    }
  }

  Future<void> _loadTranslations() async {
    if (!isEditing) {
      setState(() => _isLoading = false);
      return;
    }
    
    final translations = await _translationService.getTranslations(
      entityType: TranslatableEntityTypes.course,
      entityId: widget.course!.id,
    );
    
    // Initialize with English defaults from the course record
    if (translations.isEmpty || translations['en'] == null) {
      translations['en'] = {
        'title': widget.course!.title,
        'description': widget.course!.description ?? '',
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
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate English title is present
    final englishTitle = _translations['en']?['title']?.trim() ?? '';
    if (englishTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('English title is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final data = {
        'title': englishTitle,
        'description': _translations['en']?['description']?.trim() ?? '',
        'display_order': int.tryParse(_displayOrderController.text) ?? 0,
        'is_active': _isActive,
      };

      String courseId;
      
      if (isEditing) {
        await supabase
            .from('courses')
            .update(data)
            .eq('id', widget.course!.id);
        courseId = widget.course!.id;
      } else {
        final result = await supabase
            .from('courses')
            .insert(data)
            .select()
            .single();
        courseId = result['id'] as String;
      }

      // Save translations
      await _translationService.saveTranslations(
        entityType: TranslatableEntityTypes.course,
        entityId: courseId,
        translations: _translations,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Course updated!' : 'Course created!')),
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
        title: Text(isEditing ? 'Edit Course' : 'New Course'),
        actions: [
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
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
                  // Main content
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Translation tabs
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Content',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TranslationTabs(
                                    fields: const [
                                      TranslationField(
                                        key: 'title',
                                        label: 'Title',
                                        isRequired: true,
                                        hint: 'e.g., Microeconomics',
                                      ),
                                      TranslationField(
                                        key: 'description',
                                        label: 'Description',
                                        maxLines: 4,
                                        hint: 'Brief description of the course',
                                      ),
                                    ],
                                    translations: _translations,
                                    onChanged: (translations) {
                                      setState(() => _translations = translations);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Sidebar
                  Container(
                    width: 300,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: colorScheme.outlineVariant),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Settings',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Active'),
                            subtitle: const Text('Visible to students'),
                            value: _isActive,
                            onChanged: (value) {
                              setState(() => _isActive = value);
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _displayOrderController,
                            decoration: const InputDecoration(
                              labelText: 'Display Order',
                              border: OutlineInputBorder(),
                              helperText: 'Lower numbers appear first',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 24),
                          if (isEditing) ...[
                            const Divider(),
                            const SizedBox(height: 16),
                            Text(
                              'Units',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Manage units and lessons for this course',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UnitsListScreen(
                                      course: widget.course!,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.folder_open),
                              label: const Text('Manage Units'),
                            ),
                          ],
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
