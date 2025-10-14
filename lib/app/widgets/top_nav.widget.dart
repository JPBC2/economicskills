import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:economicskills/app/res/responsive.res.dart';
import 'package:economicskills/app/view_models/theme_mode.vm.dart';
import 'package:economicskills/main.dart'; // contains routerDelegate
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TopNav extends ConsumerWidget implements PreferredSizeWidget {
  const TopNav({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isWide = MediaQuery.of(context).size.width > ScreenSizes.md;
    final ThemeModeVM themeModeVM = ref.watch(themeModeProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color buttonTextColor = isDark ? Colors.white : Colors.black;
    final Color appBarColor = isDark ? Colors.grey.shade900 : Colors.white70;

    // Language items for the popover
    final List<String> languageItems = [
      'Español' /*, 'Français', 'Русский', '中文', 'العربية' */
    ];

    return AppBar(
      backgroundColor: appBarColor,
      title: GestureDetector(
        onTap: () => routerDelegate.go('/'),
        child: Text(
          'Economic skills',
          style: TextStyle(
            fontFamily: 'ContrailOne',
            color: buttonTextColor,
          ),
        ),
      ),
      elevation: kIsWeb ? 0 : null,
      centerTitle: kIsWeb ? false : null,
      actions: isWide
          ? [
        // Content button
        Tooltip(
          message: 'This feature is in development.',
          child: _navButton(
            icon: Icons.menu_book,
            label: 'Content',
            path: '/content',
            color: buttonTextColor,
            context: context,
            inDevelopment: true,
          ),
        ),
        // Access button with tooltip and SnackBar
        Tooltip(
          message: 'This feature is in development.',
          child: _navButton(
            icon: Icons.person,
            label: 'Access',
            path: '/access',
            color: buttonTextColor,
            context: context,
            inDevelopment: true,
          ),
        ),
        // English Popover with tooltip and SnackBar
        Tooltip(
          message: 'This feature is in development.',
          child: PopupMenuButton(
            offset: const Offset(0, 35.0), // Adjusted offset for tighter spacing
            onOpened: () {
              // Show SnackBar when dropdown is opened
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This feature is in development.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // Match _navButton padding
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.language_sharp, color: buttonTextColor, size: 20),
                  const SizedBox(width: 6),
                  Text('English', style: TextStyle(color: buttonTextColor)),
                  Icon(Icons.arrow_drop_down, color: buttonTextColor, size: 20),
                ],
              ),
            ),
            onSelected: (String language) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This feature is in development.'),
                  duration: Duration(seconds: 2),
                ),
              );
              print('Selected language: $language');
              // Placeholder: Implement language change logic
            },
            itemBuilder: (BuildContext context) {
              return languageItems.map((String language) {
                return PopupMenuItem(
                  value: language,
                  child: Tooltip(
                    message: 'This feature is in development.',
                    child: Text(language),
                  ),
                );
              }).toList();
            },
          ),
        ),
        // Theme Toggle
        Tooltip(
          message: 'Switch theme (dark / light)', //Cambiar tema (claro/oscuro)
          child: TextButton(
            style: TextButton.styleFrom(
                foregroundColor: buttonTextColor,
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0)),
            onPressed: themeModeVM.toggleThemeMode,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  themeModeVM.themeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                  size: 20,
                  color: buttonTextColor,
                ),
                const SizedBox(width: 6),
                Text('Theme', style: TextStyle(color: buttonTextColor)),
              ],
            ),
          ),
        ),
      ]
          : null,
    );
  }

  // _navButton helper modified to support SnackBar for "Access" button
  Widget _navButton({
    required String label,
    required String path,
    required Color color,
    required BuildContext context,
    IconData? icon,
    bool inDevelopment = false,
  }) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      ),
      onPressed: () {
        if (inDevelopment) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This feature is in development.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        routerDelegate.go(path);
      },
      child: icon == null
          ? Text(label)
          : Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}
