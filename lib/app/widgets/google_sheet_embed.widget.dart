import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// A reusable widget that embeds a Google Sheet into the app using a WebView.
///
/// This widget takes a [sheetUrl] that must point to a publicly editable Google
/// Sheet (e.g. a link ending in `/edit?usp=sharing`). It displays the sheet
/// inside a [WebView] with full spreadsheet functionality, including the cell
/// grid and formula bar. The [height] parameter controls the vertical space
/// allocated for the embedded sheet.
// A widget that embeds a Google Sheet inside a WebView. Uses WebViewController
// from the webview_flutter package (v4+) to configure JavaScript mode and
// loading. It recreates a new controller on each build so that the sheet
// refreshes when this widget is rebuilt.
class GoogleSheetEmbed extends StatelessWidget {
  /// The URL of the Google Sheet to embed. This should be a share link with
  /// editor access so that anyone can modify the sheet without signing in.
  final String sheetUrl;

  /// The height, in logical pixels, to allocate for the embedded sheet. By
  /// default, the sheet occupies 500 pixels of vertical space.
  final double height;

  const GoogleSheetEmbed({
    super.key,
    required this.sheetUrl,
    this.height = 500.0 // Default
  });

  @override
  Widget build(BuildContext context) {
    // Create a new controller for each build. This causes the WebView to
    // reload when this widget rebuilds (for example, if its key changes).
    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(sheetUrl));

    return SizedBox(
      height: height,
      child: WebViewWidget(
        key: UniqueKey(),
        controller: controller,
      ),
    );
  }
}