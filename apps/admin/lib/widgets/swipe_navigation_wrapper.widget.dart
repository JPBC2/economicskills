import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A wrapper widget that enables keyboard shortcuts for navigation.
/// Alt+Left Arrow = Navigate Back
class KeyboardNavigationWrapper extends StatelessWidget {
  final Widget child;

  const KeyboardNavigationWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        // Alt + Left Arrow = Back
        SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): NavigateBackIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          NavigateBackIntent: _NavigateBackAction(),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}

/// Intent for navigating back
class NavigateBackIntent extends Intent {
  const NavigateBackIntent();
}

/// Action to handle back navigation
class _NavigateBackAction extends Action<NavigateBackIntent> {
  @override
  Object? invoke(NavigateBackIntent intent) {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus == null) return null;
    
    final context = primaryFocus.context;
    if (context == null) return null;
    
    try {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      }
    } catch (_) {
      // Silently ignore if navigator not found
    }
    
    return null;
  }
}
