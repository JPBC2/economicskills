import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import '../../main.dart';
import '../../widgets/translation_tabs.widget.dart';
import '../../widgets/course_hierarchy_tree.widget.dart';

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
  bool _contentExpanded = false; // Content section collapsed by default
  
  // Translations: { language: { field: value } }
  Map<String, Map<String, String>> _translations = {};
  
  late final TranslationService _translationService;
  late final CourseService _courseService;

  bool get isEditing => widget.course != null;

  @override
  void initState() {
    super.initState();
    _translationService = TranslationService(supabase);
    _courseService = CourseService(supabase);
    
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Collapsible Content section
                    Card(
                      child: ExpansionTile(
                        initiallyExpanded: _contentExpanded,
                        onExpansionChanged: (expanded) => setState(() => _contentExpanded = expanded),
                        title: Text(
                          (_translations['en']?['title']?.isNotEmpty == true)
                              ? _translations['en']!['title']!
                              : 'Content',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: Icon(_contentExpanded ? Icons.expand_less : Icons.expand_more),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                      isResizable: true,
                                    ),
                                  ],
                                  translations: _translations,
                                  onChanged: (translations) {
                                    setState(() => _translations = translations);
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Inline Settings
                                const Divider(),
                                const SizedBox(height: 8),
                                Text('Settings', style: theme.textTheme.labelLarge),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SwitchListTile(
                                        title: const Text('Active'),
                                        subtitle: const Text('Visible to students'),
                                        value: _isActive,
                                        onChanged: (value) => setState(() => _isActive = value),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    SizedBox(
                                      width: 150,
                                      child: TextFormField(
                                        controller: _displayOrderController,
                                        decoration: const InputDecoration(
                                          labelText: 'Display Order',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                        keyboardType: TextInputType.number,
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
                    // Course Hierarchy - below Content card
                    if (isEditing) ...[
                      const SizedBox(height: 24),
                      CourseHierarchyTree(
                        course: widget.course!,
                        courseService: _courseService,
                        onRefresh: () => setState(() {}),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
