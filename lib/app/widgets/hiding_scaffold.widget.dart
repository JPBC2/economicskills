import 'package:flutter/material.dart';

/// A scaffold that provides "hide on scroll down, show on scroll up" navigation.
/// Uses SliverAppBar with floating and snap behavior for smooth transitions.
class HidingScaffold extends StatelessWidget {
  /// The app bar to display (typically TopNav or GuestTopNav)
  final PreferredSizeWidget appBar;
  
  /// The main content widgets (will be wrapped in a SliverList)
  final List<Widget> body;
  
  /// Optional drawer for mobile navigation
  final Widget? drawer;
  
  /// Optional floating action button
  final Widget? floatingActionButton;

  const HidingScaffold({
    super.key,
    required this.appBar,
    required this.body,
    this.drawer,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,  // Shows when scrolling up
            snap: true,      // Snaps fully visible when partially shown
            pinned: false,   // Hides completely when scrolling down
            toolbarHeight: appBar.preferredSize.height,
            automaticallyImplyLeading: false,
            backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
            elevation: 0,
            flexibleSpace: appBar,
          ),
          SliverList(
            delegate: SliverChildListDelegate(body),
          ),
        ],
      ),
    );
  }
}
