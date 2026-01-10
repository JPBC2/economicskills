import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:economicskills/app/config/spacing.dart';
import 'package:economicskills/app/view_models/theme_mode.vm.dart';
import 'package:economicskills/app/view_models/locale.vm.dart';
import 'package:economicskills/main.dart';
import 'package:economicskills/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:economicskills/app/routes/app_router.dart' show isPublicRoutePath;

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
    {'code': 'zh', 'label': '中文'},
    {'code': 'ru', 'label': 'Русский'},
    {'code': 'es', 'label': 'Español'},
    {'code': 'fr', 'label': 'Français'},
    {'code': 'pt', 'label': 'Português'},
    {'code': 'it', 'label': 'Italiano'},
    {'code': 'ca', 'label': 'Català'},
    {'code': 'ro', 'label': 'Română'},
    {'code': 'de', 'label': 'Deutsch'},
    {'code': 'nl', 'label': 'Nederlands'},
    {'code': 'af', 'label': 'Afrikaans'},
    {'code': 'ja', 'label': '日本語'},
    {'code': 'ko', 'label': '한국어'},
    {'code': 'id', 'label': 'Bahasa Indonesia'},
    {'code': 'ms', 'label': 'Bahasa Melayu'},
    {'code': 'tl', 'label': 'Tagalog'},
    {'code': 'vi', 'label': 'Tiếng Việt'},
    {'code': 'tr', 'label': 'Türkçe'},
    {'code': 'ar', 'label': 'العربية'},
    {'code': 'ur', 'label': 'اردو'},
    {'code': 'hi', 'label': 'हिन्दी'},
    {'code': 'bn', 'label': 'বাংলা'},
  ];

  Future<void> _signOut(BuildContext context, AppLocalizations l10n) async {
    // Get current route before signing out
    final currentPath = GoRouterState.of(context).matchedLocation;
    final isOnPublicPage = isPublicRoutePath(currentPath);

    try {
      await supabase.auth.signOut();
      if (context.mounted) {
        context.showSnackBar(l10n.signOutSuccess);

        // Redirect: stay on public pages, go to landing from protected pages
        if (isOnPublicPage) {
          // Refresh the current page state
          context.go(currentPath);
        } else {
          // Redirect to landing page from protected pages (like dashboard)
          context.go('/');
        }
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

          // Dashboard (only for authenticated users)
          Builder(
            builder: (context) {
              final user = supabase.auth.currentUser;
              if (user != null) {
                return ListTile(
                  leading: Icon(Icons.dashboard, color: itemColor),
                  title: Text(l10n.navDashboard, style: itemTextStyle),
                  onTap: () {
                    context.go('/dashboard');
                    Navigator.pop(context);
                  },
                );
              }
              return const SizedBox.shrink();
            },
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

          // Account / Sign In (auth-aware)
          Builder(
            builder: (context) {
              final user = supabase.auth.currentUser;
              final bool isAuthenticated = user != null;
              
              if (isAuthenticated) {
                // Authenticated: Show Account ExpansionTile with Sign Out
                return ExpansionTile(
                  controller: _accountController,
                  leading: Icon(Icons.person, color: itemColor),
                  title: Text(l10n.navAccount, style: itemTextStyle),
                  subtitle: Text(
                    user.email ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkTheme 
                          ? Colors.grey[400] 
                          : Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
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
                );
              } else {
                // Guest: Show Sign In ListTile
                return ListTile(
                  leading: Icon(Icons.login, color: itemColor),
                  title: Text(l10n.navSignIn, style: itemTextStyle),
                  onTap: () {
                    final currentPath = GoRouterState.of(context).uri.toString();
                    context.go('/login?returnTo=${Uri.encodeComponent(currentPath)}');
                    Navigator.pop(context);
                  },
                );
              }
            },
          ),

          // Language Popover
          ExpansionTile(
            controller: _languageController,
            leading: Icon(Icons.language_sharp, color: itemColor),
            title: Text(
              _languages.firstWhere((l) => l['code'] == localeVM.locale.languageCode, orElse: () => _languages.first)['label'],
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
