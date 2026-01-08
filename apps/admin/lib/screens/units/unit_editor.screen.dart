import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import '../../main.dart';
import '../../widgets/translation_tabs.widget.dart';

/// Unit Editor with multilingual support (6 languages)
/// Allows creating/editing units with translations
class UnitEditorScreen extends StatefulWidget {
  final Course course;
  final Unit? unit;

  const UnitEditorScreen({super.key, required this.course, this.unit});

  @override
  State<UnitEditorScreen> createState() => _UnitEditorScreenState();
}

class _UnitEditorScreenState extends State<UnitEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayOrderController = TextEditingController(text: '1');
  final _unlockCostController = TextEditingController(text: '150');
  
  bool _isActive = true;
  bool _isPremium = false;
  bool _isSaving = false;
  bool _isLoading = true;
  
  Map<String, Map<String, String>> _translations = {};
  late final TranslationService _translationService;

  bool get isEditing => widget.unit != null;

  @override
  void initState() {
    super.initState();
    _translationService = TranslationService(supabase);
    
    if (widget.unit != null) {
      _displayOrderController.text = widget.unit!.displayOrder.toString();
      _unlockCostController.text = widget.unit!.unlockCost.toString();
      _isActive = widget.unit!.isActive;
      _isPremium = widget.unit!.isPremium;
      _loadTranslations();
    } else {
      _loadNextDisplayOrder();
      _translations = {'en': {'title': '', 'description': ''}};
      _isLoading = false;
    }
  }

  Future<void> _loadNextDisplayOrder() async {
    try {
      final response = await supabase
          .from('units')
          .select('display_order')
          .eq('course_id', widget.course.id)
          .order('display_order', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        final lastOrder = response[0]['display_order'] as int;
        _displayOrderController.text = (lastOrder + 1).toString();
      }
    } catch (e) {
      // Ignore errors, use default
    }
  }

  Future<void> _loadTranslations() async {
    final translations = await _translationService.getTranslations(
      entityType: TranslatableEntityTypes.unit,
      entityId: widget.unit!.id,
    );
    
    if (translations.isEmpty || translations['en'] == null) {
      translations['en'] = {
        'title': widget.unit!.title,
        'description': widget.unit!.description ?? '',
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
    _unlockCostController.dispose();
    super.dispose();
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

    setState(() => _isSaving = true);

    try {
      final data = {
        'course_id': widget.course.id,
        'title': englishTitle,
        'description': _translations['en']?['description']?.trim(),
        'display_order': int.tryParse(_displayOrderController.text) ?? 1,
        'is_active': _isActive,
        'is_premium': _isPremium,
        'unlock_cost_xp': int.tryParse(_unlockCostController.text) ?? 150,
      };

      String unitId;
      
      if (isEditing) {
        await supabase.from('units').update(data).eq('id', widget.unit!.id);
        unitId = widget.unit!.id;
      } else {
        final result = await supabase.from('units').insert(data).select().single();
        unitId = result['id'] as String;
      }

      await _translationService.saveTranslations(
        entityType: TranslatableEntityTypes.unit,
        entityId: unitId,
        translations: _translations,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Unit updated!' : 'Unit created!')),
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
        title: Text(isEditing ? 'Edit Unit' : 'New Unit'),
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
                    // Course context card
                    Card(
                      color: colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.school, size: 20, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text('Course: ${widget.course.title}',
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Content (Title, Description)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Content', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            TranslationTabs(
                              fields: const [
                                TranslationField(key: 'title', label: 'Title', isRequired: true, hint: 'e.g., Fundamentals'),
                                TranslationField(key: 'description', label: 'Description', maxLines: 4, isResizable: true),
                              ],
                              translations: _translations,
                              onChanged: (t) => setState(() => _translations = t),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Settings (moved from right pane)
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
                                  child: SwitchListTile(
                                    title: const Text('Active'),
                                    subtitle: const Text('Visible to students'),
                                    value: _isActive,
                                    onChanged: (v) => setState(() => _isActive = v),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: SwitchListTile(
                                    title: const Text('Premium Unit'),
                                    subtitle: const Text('Requires XP to unlock'),
                                    value: _isPremium,
                                    onChanged: (v) => setState(() => _isPremium = v),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                if (_isPremium) ...[
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _unlockCostController, 
                                      decoration: const InputDecoration(
                                        labelText: 'Unlock Cost (XP)', 
                                        border: OutlineInputBorder(), 
                                        prefixIcon: Icon(Icons.star),
                                      ), 
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
