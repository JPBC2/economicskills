import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import '../../main.dart';

/// Course Editor with multilingual support
/// Allows creating/editing courses with translations
class CourseEditorScreen extends StatefulWidget {
  final Course? course;

  const CourseEditorScreen({super.key, this.course});

  @override
  State<CourseEditorScreen> createState() => _CourseEditorScreenState();
}

class _CourseEditorScreenState extends State<CourseEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // English fields
  final _titleEnController = TextEditingController();
  final _descriptionEnController = TextEditingController();
  
  // Spanish fields
  final _titleEsController = TextEditingController();
  final _descriptionEsController = TextEditingController();
  
  final _displayOrderController = TextEditingController(text: '0');
  bool _isActive = true;
  bool _isSaving = false;
  String _selectedLanguage = 'en';

  bool get isEditing => widget.course != null;

  @override
  void initState() {
    super.initState();
    if (widget.course != null) {
      _titleEnController.text = widget.course!.title;
      _descriptionEnController.text = widget.course!.description ?? '';
      _displayOrderController.text = widget.course!.displayOrder.toString();
      _isActive = widget.course!.isActive;
      // TODO: Load translations from separate table
    }
  }

  @override
  void dispose() {
    _titleEnController.dispose();
    _descriptionEnController.dispose();
    _titleEsController.dispose();
    _descriptionEsController.dispose();
    _displayOrderController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final data = {
        'title': _titleEnController.text.trim(),
        'description': _descriptionEnController.text.trim(),
        'display_order': int.tryParse(_displayOrderController.text) ?? 0,
        'is_active': _isActive,
      };

      if (isEditing) {
        await supabase
            .from('courses')
            .update(data)
            .eq('id', widget.course!.id);
      } else {
        await supabase.from('courses').insert(data);
      }

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
      body: Form(
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
                    // Language tabs
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
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'en',
                                  label: Text('English'),
                                  icon: Icon(Icons.language),
                                ),
                                ButtonSegment(
                                  value: 'es',
                                  label: Text('Español'),
                                  icon: Icon(Icons.language),
                                ),
                              ],
                              selected: {_selectedLanguage},
                              onSelectionChanged: (value) {
                                setState(() => _selectedLanguage = value.first);
                              },
                            ),
                            const SizedBox(height: 24),
                            if (_selectedLanguage == 'en') ...[
                              TextFormField(
                                controller: _titleEnController,
                                decoration: const InputDecoration(
                                  labelText: 'Title (English)',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) =>
                                    value?.isEmpty == true ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _descriptionEnController,
                                decoration: const InputDecoration(
                                  labelText: 'Description (English)',
                                  border: OutlineInputBorder(),
                                  alignLabelWithHint: true,
                                ),
                                maxLines: 4,
                              ),
                            ] else ...[
                              TextFormField(
                                controller: _titleEsController,
                                decoration: const InputDecoration(
                                  labelText: 'Title (Español)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _descriptionEsController,
                                decoration: const InputDecoration(
                                  labelText: 'Description (Español)',
                                  border: OutlineInputBorder(),
                                  alignLabelWithHint: true,
                                ),
                                maxLines: 4,
                              ),
                            ],
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
                          // TODO: Navigate to units editor
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
