import 'package:flutter/material.dart';
import 'package:economicskills/app/res/responsive.res.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CallToAction extends ConsumerWidget {
  const CallToAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color callToActionTextColor = Colors.white; // Simplified as it's always white in your code
    final Color buttonTextColor = isDark ? Colors.white : Colors.lightBlue.shade900; // Modified for light theme

    return Container(
      margin: const EdgeInsets.only(top: 40.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [Colors.blue.shade900, Colors.blue.shade700]
              : [Colors.lightBlue.shade900, Colors.cyanAccent.shade700],
        ),
      ),
      constraints: const BoxConstraints(minHeight: 400.0), // Modified height to minHeight
      alignment: Alignment.center,
      child: ConstrainedBox( // Added ConstrainedBox
        constraints: const BoxConstraints(maxWidth: 650.0), // Set maxWidth
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              flex: 8,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  "Applied economic theory for decision making with Google Sheets.",
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: callToActionTextColor,
                        fontFamily: 'ContrailOne',
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 40.0), // Added spacing
            Flexible(
              flex: 1, // Consider adjusting flex or using SizedBox for better height control if needed
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  fixedSize: MediaQuery.of(context).size.width > ScreenSizes.md
                      ? const Size(120, 56)
                      : const Size(120, 56),
                ),
                onPressed: () {
                  // Navigate using go_router
                  context.go('/exercises/elasticity');
                },
                child: Text(
                  "Start",
                  style: TextStyle(
                      color: buttonTextColor,
                      fontSize: 19,
                      fontFamily: 'ContrailOne'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
