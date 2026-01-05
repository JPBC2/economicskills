import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Web-specific imports (conditional)
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
// ignore: depend_on_referenced_packages
import 'package:web/web.dart' as web;

/// Widget to embed Google Sheets in a Flutter web app
/// Only works on web platform - shows fallback on mobile
class EmbeddedSpreadsheet extends StatefulWidget {
  final String spreadsheetId;
  final bool isEditable;
  final double? height;

  const EmbeddedSpreadsheet({
    super.key,
    required this.spreadsheetId,
    this.isEditable = false,
    this.height,
  });

  @override
  State<EmbeddedSpreadsheet> createState() => _EmbeddedSpreadsheetState();
}

class _EmbeddedSpreadsheetState extends State<EmbeddedSpreadsheet> {
  late String _viewId;
  bool _isLoading = true;
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _viewId = 'google-sheet-${widget.spreadsheetId.hashCode}-${DateTime.now().millisecondsSinceEpoch}';
    if (kIsWeb) {
      _registerView();
    }
  }

  @override
  void didUpdateWidget(EmbeddedSpreadsheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spreadsheetId != widget.spreadsheetId) {
      _viewId = 'google-sheet-${widget.spreadsheetId.hashCode}-${DateTime.now().millisecondsSinceEpoch}';
      _isRegistered = false;
      if (kIsWeb) {
        _registerView();
      }
    }
  }

  void _registerView() {
    if (_isRegistered) return;

    setState(() => _isLoading = true);

    // Build the embed URL
    final editMode = widget.isEditable ? 'edit' : 'preview';
    final embedUrl = 'https://docs.google.com/spreadsheets/d/${widget.spreadsheetId}/$editMode?embedded=true&rm=minimal';

    // Register the iframe view factory
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) {
        final iframe = web.HTMLIFrameElement()
          ..src = embedUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
        
        iframe.onLoad.listen((_) {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        });
        
        return iframe;
      },
    );

    _isRegistered = true;

    // Small delay to ensure registration completes
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      // Fallback for non-web platforms
      return _buildFallback(context);
    }

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (_isRegistered)
            HtmlElementView(viewType: _viewId),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading spreadsheet...'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    return Container(
      height: widget.height ?? 400,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_chart, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Spreadsheet viewer not available on this platform',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
