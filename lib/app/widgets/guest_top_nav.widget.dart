import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:economicskills/app/view_models/theme_mode.vm.dart';

class GuestTopNav extends ConsumerWidget implements PreferredSizeWidget {
  const GuestTopNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeVM = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonTextColor = isDark ? Colors.white : Colors.black;
    final appBarColor = isDark ? Colors.grey.shade900 : Colors.white70;
    final isWide = MediaQuery.of(context).size.width > 600; // Example breakpoint

    return AppBar(
      backgroundColor: appBarColor,
      title: Text(
        'Economic skills ',
        style: TextStyle(
          fontFamily: 'ContrailOne',
          color: buttonTextColor,
        ),
      ),
      elevation: kIsWeb ? 0 : null,
      centerTitle: kIsWeb ? false : null,
      actions: isWide
          ? [
              Tooltip(
                message: 'Switch theme (dark / light)',
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: buttonTextColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  ),
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

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
