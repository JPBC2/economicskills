import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:economicskills/app/view_models/theme_mode.vm.dart';

class GuestDrawerNav extends ConsumerWidget {
  const GuestDrawerNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeVM = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemColor = isDark ? Colors.white : Colors.black;
    final textTheme = Theme.of(context).textTheme;

    final headerTextStyle = textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontFamily: 'ContrailOne',
        ) ??
        const TextStyle(
          color: Colors.white,
          fontFamily: 'ContrailOne',
          fontSize: 22,
        );

    final itemTextStyle = textTheme.titleMedium?.copyWith(color: itemColor) ??
        TextStyle(color: itemColor, fontSize: 16, fontWeight: FontWeight.w500);

    return Drawer(
      child: ListView(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [Colors.blue.shade900, Colors.blue.shade700]
                    : [Colors.lightBlue.shade900, Colors.cyanAccent.shade700],
              ),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Text("Economic skills", style: headerTextStyle),
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
