import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:economicskills/app/config/spacing.dart';
import 'package:economicskills/app/view_models/theme_mode.vm.dart';
import 'package:economicskills/app/view_models/locale.vm.dart';
import 'package:economicskills/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class GuestTopNav extends ConsumerWidget implements PreferredSizeWidget {
  const GuestTopNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeVM = ref.watch(themeModeProvider);
    final localeVM = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;

    // Using design tokens for consistent styling
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonTextColor = isDark ? AppColors.textOnDark : AppColors.textOnLight;
    final appBarColor = isDark ? AppColors.appBarDark : AppColors.appBarLight;
    final isWide = MediaQuery.of(context).size.width > 600;

    // Language items - 23 supported languages
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
      {'code': 'ar', 'label': 'العربية'},
      {'code': 'id', 'label': 'Bahasa Indonesia'},
      {'code': 'ko', 'label': '한국어'},
      {'code': 'ja', 'label': '日本語'},
      {'code': 'af', 'label': 'Afrikaans'},
      {'code': 'hi', 'label': 'हिन्दी'},
      {'code': 'bn', 'label': 'বাংলা'},
      {'code': 'ur', 'label': 'اردو'},
      {'code': 'tr', 'label': 'Türkçe'},
      {'code': 'vi', 'label': 'Tiếng Việt'},
      {'code': 'tl', 'label': 'Tagalog'},
      {'code': 'ms', 'label': 'Bahasa Melayu'},
    ];

    return AppBar(
      backgroundColor: appBarColor,
      title: GestureDetector(
        onTap: () => context.go('/'),
        child: Text(
          'Economic skills',
          style: AppTextStyles.appBarTitle(color: buttonTextColor),
        ),
      ),
      elevation: kIsWeb ? 0 : null,
      centerTitle: kIsWeb ? false : null,
      actions: isWide
          ? [
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
                    padding: AppSpacing.buttonPadding,
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
                      Text(l10n.navTheme, style: TextStyle(color: buttonTextColor)),
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
