import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:economicskills/app/config/spacing.dart';
import 'package:economicskills/app/view_models/theme_mode.vm.dart';
import 'package:economicskills/app/view_models/locale.vm.dart';
import 'package:economicskills/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class GuestDrawerNav extends ConsumerStatefulWidget {
  const GuestDrawerNav({super.key});

  @override
  ConsumerState<GuestDrawerNav> createState() => _GuestDrawerNavState();
}

class _GuestDrawerNavState extends ConsumerState<GuestDrawerNav> {
  final ExpansibleController _languageController = ExpansibleController();

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

  @override
  Widget build(BuildContext context) {
    final themeModeVM = ref.watch(themeModeProvider);
    final localeVM = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Using design tokens for consistent styling
    final headerTextStyle = AppTextStyles.drawerHeader();
    final itemColor = isDark ? AppColors.textOnDark : AppColors.textOnLight;
    final itemTextStyle = AppTextStyles.navItem(color: itemColor);
    final subItemTextStyle = AppTextStyles.navSubItem(color: itemColor);

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

          // Language ExpansionTile
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

          // Theme toggle
          Tooltip(
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
          ),
        ],
      ),
    );
  }
}
