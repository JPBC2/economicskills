import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:economicskills/app/config/theme.dart';
import 'package:economicskills/app/config/gradients.dart';
import 'package:economicskills/app/config/spacing.dart';
import 'package:economicskills/app/config/text_styles.dart';
import 'package:economicskills/app/view_models/theme_mode.vm.dart';
import 'package:economicskills/app/view_models/locale.vm.dart';
import 'package:economicskills/main.dart';
import 'package:economicskills/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class DrawerNav extends ConsumerStatefulWidget {
  const DrawerNav({super.key});

  @override
  ConsumerState<DrawerNav> createState() => _DrawerNavState();
}

class _DrawerNavState extends ConsumerState<DrawerNav> {
  // Controller for the language ExpansionTile
  final ExpansibleController _languageController = ExpansibleController();
  // Controller for the Account ExpansionTile
  final ExpansibleController _accountController = ExpansibleController();

  final List<Map<String, dynamic>> _languages = [
    {'code': 'en', 'label': 'English'},
    {'code': 'es', 'label': 'Español'},
  ];

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

  @override
  Widget build(BuildContext context) {
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final localeVM = ref.watch(localeProvider);
    
    // Style for the Drawer Header (using design tokens)
    final TextStyle headerTextStyle = AppTextStyles.drawerHeader();

    // Common color and text style for drawer items (using design tokens)
    final Color itemColor = isDarkTheme ? AppColors.textOnDark : AppColors.textOnLight;
    final TextStyle itemTextStyle = AppTextStyles.navItem(color: itemColor);
    final TextStyle subItemTextStyle = AppTextStyles.navSubItem(color: itemColor);

    return Drawer(
      child: ListView(
        children: [
          // App name header
          GestureDetector(
            onTap: () {
              context.go('/');
              Navigator.pop(context);
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: AppGradients.drawerHeader(isDark: isDarkTheme),
              ),
              padding: AppSpacing.drawerHeaderPadding,
              child: Text('Economic skills', style: headerTextStyle), // App name - never translated
            ),
          ),

          // Content button
          ListTile(
            leading: Icon(Icons.menu_book, color: itemColor),
            title: Text(l10n.navContent, style: itemTextStyle),
            onTap: () {
              context.go('/content');
              Navigator.pop(context);
            },
          ),

          // Account
          ExpansionTile(
            controller: _accountController,
            leading: Icon(Icons.person, color: itemColor),
            title: Text(l10n.navAccount, style: itemTextStyle),
            iconColor: itemColor,
            collapsedIconColor: itemColor,
            children: [
              ListTile(
                leading: Icon(Icons.logout, color: itemColor),
                title: Text(l10n.navSignOut, style: subItemTextStyle),
                onTap: () {
                  _signOut(context, l10n);
                  _accountController.collapse();
                  Navigator.pop(context);
                },
              ),
            ],
          ),

          // Language Popover
          ExpansionTile(
            controller: _languageController,
            leading: Icon(Icons.language_sharp, color: itemColor),
            title: Text(
              localeVM.locale.languageCode == 'es' ? 'Español' : 'English',
              style: itemTextStyle
            ),
            iconColor: itemColor,
            collapsedIconColor: itemColor,
            children: _languages.map((lang) {
              return ListTile(
                contentPadding: AppSpacing.navItemPadding,
                title: Text(lang['label'], style: subItemTextStyle),
                onTap: () {
                  localeVM.setLocale(Locale(lang['code']));
                  _languageController.collapse(); 
                  Navigator.pop(context); 
                },
              );
            }).toList(),
          ),

          // Theme toggle button at the very bottom
          Consumer(
            builder: (context, ref, _) {
              final themeModeVM = ref.watch(themeModeProvider);
              // itemColor is already defined above and matches the theme

              return Tooltip(
                message: l10n.switchThemeTooltip,
                child: ListTile(
                  onTap: themeModeVM.toggleThemeMode,
                  leading: Icon(
                    themeModeVM.themeMode == ThemeMode.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    color: itemColor,
                  ),
                  title: Text(l10n.navTheme, style: itemTextStyle),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
