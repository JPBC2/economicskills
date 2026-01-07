import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Reusable widget for translation tabs with fields
/// Supports 6 languages: English, Spanish, French, Chinese, Russian, Portuguese
class TranslationTabs extends StatefulWidget {
  /// Fields to display for translation (e.g., ['title', 'description'])
  final List<TranslationField> fields;

  /// Current translations: { language: { field: value } }
  final Map<String, Map<String, String>> translations;

  /// Callback when translations change
  final ValueChanged<Map<String, Map<String, String>>> onChanged;

  /// Currently selected language (optional, manages state internally if not provided)
  final String? selectedLanguage;

  /// Callback when language selection changes
  final ValueChanged<String>? onLanguageChanged;

  const TranslationTabs({
    super.key,
    required this.fields,
    required this.translations,
    required this.onChanged,
    this.selectedLanguage,
    this.onLanguageChanged,
  });

  @override
  State<TranslationTabs> createState() => _TranslationTabsState();
}

class _TranslationTabsState extends State<TranslationTabs> {
  late String _selectedLanguage;
  late Map<String, Map<String, TextEditingController>> _controllers;
  final Map<String, double> _fieldHeights = {}; // Track heights for resizable fields

  @override
  void initState() {
    super.initState();
    _selectedLanguage =
        widget.selectedLanguage ?? SupportedLanguages.defaultLanguage;
    _initControllers();
  }

  void _initControllers() {
    _controllers = {};
    for (final lang in SupportedLanguages.codes) {
      _controllers[lang] = {};
      for (final field in widget.fields) {
        final value = widget.translations[lang]?[field.key] ?? '';
        _controllers[lang]![field.key] = TextEditingController(text: value);
        // Initialize default heights for resizable fields
        if (field.isResizable && !_fieldHeights.containsKey(field.key)) {
          _fieldHeights[field.key] = 56.0 + (field.maxLines - 1) * 24.0;
        }
      }
    }
  }

  @override
  void didUpdateWidget(TranslationTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedLanguage != null &&
        widget.selectedLanguage != _selectedLanguage) {
      _selectedLanguage = widget.selectedLanguage!;
    }
    // Update controller values if translations changed externally
    if (widget.translations != oldWidget.translations) {
      for (final lang in SupportedLanguages.codes) {
        for (final field in widget.fields) {
          final value = widget.translations[lang]?[field.key] ?? '';
          if (_controllers[lang]?[field.key]?.text != value) {
            _controllers[lang]?[field.key]?.text = value;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    for (final langControllers in _controllers.values) {
      for (final controller in langControllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  void _onFieldChanged() {
    // Build updated translations map
    final Map<String, Map<String, String>> newTranslations = {};
    for (final lang in SupportedLanguages.codes) {
      newTranslations[lang] = {};
      for (final field in widget.fields) {
        final value = _controllers[lang]?[field.key]?.text ?? '';
        if (value.isNotEmpty) {
          newTranslations[lang]![field.key] = value;
        }
      }
    }
    widget.onChanged(newTranslations);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Language selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: SupportedLanguages.codes.map((code) {
              final isSelected = code == _selectedLanguage;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(SupportedLanguages.getDisplayName(code)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedLanguage = code);
                      widget.onLanguageChanged?.call(code);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        // Fields for selected language
        ...widget.fields.map((field) {
          final controller = _controllers[_selectedLanguage]![field.key]!;
          
          if (field.isResizable) {
            final height = _fieldHeights[field.key] ?? 100.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: height,
                    child: TextFormField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText:
                            '${field.label} (${SupportedLanguages.names[_selectedLanguage]})',
                        border: const OutlineInputBorder(),
                        alignLabelWithHint: true,
                        hintText: field.hint,
                      ),
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      onChanged: (_) => _onFieldChanged(),
                      validator: field.isRequired && _selectedLanguage == 'en'
                          ? (value) =>
                              value?.isEmpty == true ? 'Required in English' : null
                          : null,
                    ),
                  ),
                  // Drag handle
                  MouseRegion(
                    cursor: SystemMouseCursors.resizeUpDown,
                    child: GestureDetector(
                      onVerticalDragUpdate: (details) {
                        setState(() {
                          _fieldHeights[field.key] = (height + details.delta.dy).clamp(56.0, 400.0);
                        });
                      },
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                        ),
                        child: Center(
                          child: Container(
                            width: 32,
                            height: 3,
                            decoration: BoxDecoration(
                              color: colorScheme.outline.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText:
                    '${field.label} (${SupportedLanguages.names[_selectedLanguage]})',
                border: const OutlineInputBorder(),
                alignLabelWithHint: field.maxLines > 1,
                hintText: field.hint,
              ),
              maxLines: field.maxLines,
              onChanged: (_) => _onFieldChanged(),
              validator: field.isRequired && _selectedLanguage == 'en'
                  ? (value) =>
                      value?.isEmpty == true ? 'Required in English' : null
                  : null,
            ),
          );
        }),
      ],
    );
  }
}

/// Configuration for a translatable field
class TranslationField {
  /// Field key (e.g., 'title', 'description')
  final String key;

  /// Display label
  final String label;

  /// Number of lines for the text field (or min lines if resizable)
  final int maxLines;

  /// Whether this field is required (checked for English)
  final bool isRequired;

  /// Hint text
  final String? hint;

  /// Whether the field can be resized (expanded beyond maxLines)
  final bool isResizable;

  const TranslationField({
    required this.key,
    required this.label,
    this.maxLines = 1,
    this.isRequired = false,
    this.hint,
    this.isResizable = false,
  });
}

/// Common field configurations
class CommonTranslationFields {
  static const title = TranslationField(
    key: 'title',
    label: 'Title',
    isRequired: true,
  );

  static const description = TranslationField(
    key: 'description',
    label: 'Description',
    maxLines: 4,
  );

  static const instructions = TranslationField(
    key: 'instructions',
    label: 'Instructions',
    maxLines: 8,
    isRequired: true,
  );

  static const explanationText = TranslationField(
    key: 'explanation_text',
    label: 'Explanation',
    maxLines: 8,
    isRequired: true,
  );

  static const sourceReferences = TranslationField(
    key: 'source_references',
    label: 'Source References',
    maxLines: 4,
  );
}
