import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:economicskills/app/config/spacing.dart';
import 'package:economicskills/app/res/responsive.res.dart';
import 'package:economicskills/app/view_models/theme_mode.vm.dart';
import 'package:economicskills/app/view_models/locale.vm.dart';
import 'package:economicskills/main.dart'; // contains supabase
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:economicskills/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:economicskills/app/routes/app_router.dart' show isPublicRoutePath;
import 'package:pointer_interceptor/pointer_interceptor.dart';

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
    
    // Using design tokens for consistent styling
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color buttonTextColor = isDark ? AppColors.textOnDark : AppColors.textOnLight;
    final Color appBarColor = isDark ? AppColors.appBarDark : AppColors.appBarLight;

    // Language items - 11 supported languages
    final List<Map<String, dynamic>> languages = [
      {'code': 'en', 'label': 'English'},
      {'code': 'es', 'label': 'Español'},
      {'code': 'zh', 'label': '中文'},
      {'code': 'ru', 'label': 'Русский'},
      {'code': 'fr', 'label': 'Français'},
      {'code': 'pt', 'label': 'Português'},
      {'code': 'it', 'label': 'Italiano'},
      {'code': 'ca', 'label': 'Català'},
      {'code': 'ro', 'label': 'Română'},
      {'code': 'de', 'label': 'Deutsch'},
      {'code': 'nl', 'label': 'Nederlands'},
    ];

    return AppBar(
      backgroundColor: appBarColor,
      title: GestureDetector(
        onTap: () => context.go('/'),
        child: Text(
          'Economic skills', // App name - never translated
          style: AppTextStyles.appBarTitle(color: buttonTextColor),
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
        // Account / Sign In button (auth-aware)
        Builder(
          builder: (context) {
            final user = supabase.auth.currentUser;
            final bool isAuthenticated = user != null;
            
            if (isAuthenticated) {
              // Authenticated: Show Account dropdown with Sign Out
              return PopupMenuButton(
                offset: const Offset(0, 35.0),
                elevation: 8,
                color: Theme.of(context).colorScheme.surface,
                surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
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
                itemBuilder: (context) => <PopupMenuEntry<dynamic>>[
                  // Display user email (non-interactive)
                  PopupMenuItem(
                    enabled: false,
                    child: PointerInterceptor(
                      child: Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              user.email ?? 'User',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const PopupMenuDivider(),
                  // Sign Out option
                  PopupMenuItem(
                    child: PointerInterceptor(
                      child: Row(
                        children: [
                          const Icon(Icons.logout),
                          const SizedBox(width: 8),
                          Text(l10n.navSignOut),
                        ],
                      ),
                    ),
                    onTap: () => _signOut(context, l10n),
                  ),
                ],
              );
            } else {
              // Guest: Show Sign In button
              return TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: buttonTextColor,
                  padding: AppSpacing.buttonPadding,
                ),
                onPressed: () {
                  final currentPath = GoRouterState.of(context).uri.toString();
                  context.go('/login?returnTo=${Uri.encodeComponent(currentPath)}');
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.login, size: 20, color: buttonTextColor),
                    const SizedBox(width: 6),
                    Text(l10n.navSignIn, style: TextStyle(color: buttonTextColor)),
                  ],
                ),
              );
            }
          },
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
                  languages.firstWhere((l) => l['code'] == localeVM.locale.languageCode, orElse: () => languages.first)['label'], 
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
                padding: AppSpacing.buttonPadding),
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
        padding: AppSpacing.buttonPadding,
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
    // Get current route before signing out
    final currentPath = GoRouterState.of(context).matchedLocation;
    final isOnPublicPage = isPublicRoutePath(currentPath);
    
    try {
      await supabase.auth.signOut();
      if (context.mounted) {
        context.showSnackBar(l10n.signOutSuccess);
        
        // Smart redirect: stay on public pages, redirect from protected pages
        if (isOnPublicPage) {
          // Refresh the current page state by replacing with same route
          context.go(currentPath);
        } else {
          // Redirect to home from protected pages
          context.go('/');
        }
      }
    } catch (error) {
      if (context.mounted) {
        context.showSnackBar(l10n.signOutError, isError: true);
      }
    }
  }

}
