import 'package:flutter/material.dart';

/// A text field with a draggable bottom border to resize the height
class ResizableTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final int minLines;
  final int initialMaxLines;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final InputDecoration? decoration;

  const ResizableTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.minLines = 1,
    this.initialMaxLines = 4,
    this.validator,
    this.onChanged,
    this.decoration,
  });

  @override
  State<ResizableTextField> createState() => _ResizableTextFieldState();
}

class _ResizableTextFieldState extends State<ResizableTextField> {
  late double _height;
  final double _minHeight = 56.0;
  final double _lineHeight = 24.0;

  @override
  void initState() {
    super.initState();
    _height = _minHeight + (widget.initialMaxLines - 1) * _lineHeight;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _height,
          child: TextFormField(
            controller: widget.controller,
            validator: widget.validator,
            onChanged: widget.onChanged,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: widget.decoration ?? InputDecoration(
              labelText: widget.labelText,
              hintText: widget.hintText,
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
        ),
        // Drag handle
        MouseRegion(
          cursor: SystemMouseCursors.resizeUpDown,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              setState(() {
                _height = (_height + details.delta.dy).clamp(_minHeight, 400.0);
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
    );
  }
}
