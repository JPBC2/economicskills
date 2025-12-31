import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:economicskills/app/res/responsive.res.dart';
import 'package:economicskills/app/view_models/theme_mode.vm.dart';
import 'package:economicskills/app/view_models/locale.vm.dart';
import 'package:economicskills/main.dart'; // contains supabase
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:economicskills/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class TopNav extends ConsumerWidget implements PreferredSizeWidget {
  const TopNav({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isWide = MediaQuery.of(context).size.width > ScreenSizes.md;
    final ThemeModeVM themeModeVM = ref.watch(themeModeProvider);
    final LocaleVM localeVM = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;
    
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color buttonTextColor = isDark ? Colors.white : Colors.black;
    final Color appBarColor = isDark ? Colors.grey.shade900 : Colors.white70;

    // Language items
    final List<Map<String, dynamic>> languages = [
      {'code': 'en', 'label': 'English'},
      {'code': 'es', 'label': 'Español'},
    ];

    return AppBar(
      backgroundColor: appBarColor,
      title: GestureDetector(
        onTap: () => context.go('/'),
        child: Text(
          l10n.appTitle, // 'Economic skills'
          style: TextStyle(
            fontFamily: 'ContrailOne',
            fontSize: 22,
            fontWeight: FontWeight.normal,
            color: buttonTextColor,
          ),
        ),
      ),
      elevation: kIsWeb ? 0 : null,
      centerTitle: kIsWeb ? false : null,
      actions: isWide
          ? [
        // Content button
        _navButton(
          icon: Icons.menu_book,
          label: l10n.navContent,
          path: '/content',
          color: buttonTextColor,
          context: context,
          l10n: l10n,
          // inDevelopment: true, // Removed assumption, treating as nav
        ),
        // Account PopupMenuButton
        PopupMenuButton(
          offset: const Offset(0, 35.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Row(
              children: [
                Icon(Icons.person, color: buttonTextColor, size: 20),
                const SizedBox(width: 6),
                Text(l10n.navAccount, style: TextStyle(color: buttonTextColor)),
                Icon(Icons.arrow_drop_down, color: buttonTextColor, size: 20),
              ],
            ),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Row(
                children: [
                  const Icon(Icons.logout),
                  const SizedBox(width: 8),
                  Text(l10n.navSignOut),
                ],
              ),
              onTap: () => _signOut(context, l10n),
            ),
          ],
        ),

        // Language Popover
        PopupMenuButton<String>(
          offset: const Offset(0, 35.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Row(
              children: [
                Icon(Icons.language_sharp, color: buttonTextColor, size: 20),
                const SizedBox(width: 6),
                Text(
                  localeVM.locale.languageCode == 'es' ? 'Español' : 'English', 
                  style: TextStyle(color: buttonTextColor)
                ),
                Icon(Icons.arrow_drop_down, color: buttonTextColor, size: 20),
              ],
            ),
          ),
          onSelected: (String languageCode) {
            localeVM.setLocale(Locale(languageCode));
          },
          itemBuilder: (BuildContext context) {
            return languages.map((lang) {
              return PopupMenuItem<String>(
                value: lang['code'],
                child: Text(lang['label']),
              );
            }).toList();
          },
        ),
        
        // Theme Toggle
        Tooltip(
          message: l10n.switchThemeTooltip,
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
                Text(l10n.navTheme, style: TextStyle(color: buttonTextColor)),
              ],
            ),
          ),
        ),
      ]
          : null,
    );
  }

  // _navButton helper
  Widget _navButton({
    required String label,
    required String path,
    required Color color,
    required BuildContext context,
    required AppLocalizations l10n,
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
            SnackBar(
              content: Text(l10n.featureInDevelopment),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          context.go(path);
        }
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

  Future<void> _signOut(BuildContext context, AppLocalizations l10n) async {
    try {
      await supabase.auth.signOut();
      if (context.mounted) {
        context.showSnackBar(l10n.signOutSuccess);
      }
    } catch (error) {
      if (context.mounted) {
        context.showSnackBar(l10n.signOutError, isError: true);
      }
    }
  }

}
