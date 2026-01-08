import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import '../../main.dart';
import '../../widgets/translation_tabs.widget.dart';

/// Lesson Editor with multilingual support (6 languages)
class LessonEditorScreen extends StatefulWidget {
  final Unit unit;
  final Lesson? lesson;

  const LessonEditorScreen({super.key, required this.unit, this.lesson});

  @override
  State<LessonEditorScreen> createState() => _LessonEditorScreenState();
}

class _LessonEditorScreenState extends State<LessonEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayOrderController = TextEditingController(text: '1');
  final _youtubeUrlController = TextEditingController();
  
  bool _isActive = true;
  bool _isSaving = false;
  bool _isLoading = true;
  
  Map<String, Map<String, String>> _translations = {};
  late final TranslationService _translationService;

  bool get isEditing => widget.lesson != null;

  @override
  void initState() {
    super.initState();
    _translationService = TranslationService(supabase);
    
    if (widget.lesson != null) {
      _displayOrderController.text = widget.lesson!.displayOrder.toString();
      _youtubeUrlController.text = widget.lesson!.youtubeVideoUrl ?? '';
      _isActive = widget.lesson!.isActive;
      _loadTranslations();
    } else {
      _loadNextDisplayOrder();
      _translations = {'en': {'title': '', 'explanation_text': '', 'source_references': ''}};
      _isLoading = false;
    }
  }

  Future<void> _loadNextDisplayOrder() async {
    try {
      final response = await supabase
          .from('lessons')
          .select('display_order')
          .eq('unit_id', widget.unit.id)
          .order('display_order', ascending: false)
          .limit(1);
      if (response.isNotEmpty) {
        _displayOrderController.text = ((response[0]['display_order'] as int) + 1).toString();
      }
    } catch (e) {}
  }

  Future<void> _loadTranslations() async {
    final translations = await _translationService.getTranslations(
      entityType: TranslatableEntityTypes.lesson,
      entityId: widget.lesson!.id,
    );
    
    if (translations.isEmpty || translations['en'] == null) {
      translations['en'] = {
        'title': widget.lesson!.title,
        'explanation_text': widget.lesson!.explanationText,
        'source_references': widget.lesson!.sourceReferences ?? '',
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
    _youtubeUrlController.dispose();
    super.dispose();
  }

  String? _extractYoutubeId(String url) {
    if (url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.host.contains('youtu.be')) return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    if (uri.host.contains('youtube.com')) return uri.queryParameters['v'];
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final englishTitle = _translations['en']?['title']?.trim() ?? '';
    final englishExplanation = _translations['en']?['explanation_text']?.trim() ?? '';
    
    if (englishTitle.isEmpty || englishExplanation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('English title and explanation are required'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final data = {
        'unit_id': widget.unit.id,
        'title': englishTitle,
        'explanation_text': englishExplanation,
        'display_order': int.tryParse(_displayOrderController.text) ?? 1,
        'youtube_video_url': _youtubeUrlController.text.trim().isEmpty ? null : _youtubeUrlController.text.trim(),
        'source_references': _translations['en']?['source_references']?.trim(),
        'is_active': _isActive,
      };

      String lessonId;
      
      if (isEditing) {
        await supabase.from('lessons').update(data).eq('id', widget.lesson!.id);
        lessonId = widget.lesson!.id;
      } else {
        final result = await supabase.from('lessons').insert(data).select().single();
        lessonId = result['id'] as String;
      }

      await _translationService.saveTranslations(
        entityType: TranslatableEntityTypes.lesson,
        entityId: lessonId,
        translations: _translations,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Lesson updated!' : 'Lesson created!')),
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
    final youtubeId = _extractYoutubeId(_youtubeUrlController.text);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Lesson' : 'New Lesson'),
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
                        // Unit context card
                        Card(
                          color: colorScheme.surfaceContainerHighest,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(Icons.folder, size: 20, color: colorScheme.secondary),
                                const SizedBox(width: 8),
                                Text('Unit ${widget.unit.displayOrder}: ${widget.unit.title}',
                                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Content (Title, Explanation, Source References)
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
                                    TranslationField(key: 'title', label: 'Title', isRequired: true, hint: 'e.g., Scarcity'),
                                    TranslationField(key: 'explanation_text', label: 'Explanation', maxLines: 8, isRequired: true),
                                    TranslationField(key: 'source_references', label: 'Source References', maxLines: 4),
                                  ],
                                  translations: _translations,
                                  onChanged: (t) => setState(() => _translations = t),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Media
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Media', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _youtubeUrlController,
                                  decoration: const InputDecoration(
                                    labelText: 'YouTube Video URL',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.play_circle_outline),
                                    hintText: 'https://www.youtube.com/watch?v=...',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                                if (youtubeId != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                        const SizedBox(width: 8),
                                        Text('Valid YouTube URL (ID: $youtubeId)', style: const TextStyle(color: Colors.green)),
                                      ],
                                    ),
                                  ),
                                ],
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
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ),
    );
  }
}
