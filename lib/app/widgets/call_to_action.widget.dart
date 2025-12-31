import 'package:flutter/material.dart';
import 'package:economicskills/app/config/theme.dart';
import 'package:economicskills/app/config/gradients.dart';
import 'package:economicskills/app/config/spacing.dart';
import 'package:economicskills/app/config/text_styles.dart';
import 'package:economicskills/app/res/responsive.res.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CallToAction extends ConsumerWidget {
  const CallToAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Using design tokens for consistent styling
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color callToActionTextColor = AppColors.textOnDark; // Always white on CTA
    final Color buttonTextColor = isDark ? AppColors.textOnDark : Colors.lightBlue.shade900;

    return Container(
      margin: EdgeInsets.only(top: AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: AppGradients.callToAction(isDark: isDark),
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
            const SizedBox(height: AppSpacing.xxl), // Added spacing using design tokens
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
                  style: AppTextStyles.ctaButton(color: buttonTextColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
