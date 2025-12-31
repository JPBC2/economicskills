import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:economicskills/app/config/spacing.dart';
import 'package:economicskills/app/view_models/theme_mode.vm.dart';

import 'package:go_router/go_router.dart';

class GuestDrawerNav extends ConsumerWidget {
  const GuestDrawerNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeVM = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Using design tokens for consistent styling
    final headerTextStyle = AppTextStyles.drawerHeader();
    final itemColor = isDark ? AppColors.textOnDark : AppColors.textOnLight;
    final itemTextStyle = AppTextStyles.navItem(color: itemColor);

    return Drawer(
      child: ListView(
        children: [
          GestureDetector(
            onTap: () {
              context.go('/');
              Navigator.pop(context);
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: AppGradients.callToAction(isDark: isDark),
              ),
              padding: AppSpacing.drawerHeaderPadding,
              child: Text("Economic skills", style: headerTextStyle),
            ),
          ),
          Tooltip(
            message: 'Switch theme (dark / light)',
            child: ListTile(
              onTap: themeModeVM.toggleThemeMode,
              leading: Icon(
                themeModeVM.themeMode == ThemeMode.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
                color: itemColor,
              ),
              title: Text('Theme', style: itemTextStyle),
            ),
          ),
        ],
      ),
    );
  }
}
