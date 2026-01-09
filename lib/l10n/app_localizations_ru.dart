// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Economic skills';

  @override
  String get homeWelcome => 'Добро пожаловать в Economic skills';

  @override
  String get changeLanguage => 'Изменить язык';

  @override
  String get sheetsExercisesTitle => 'Интерактивные упражнения';

  @override
  String get sheetsExercisesDesc =>
      'Освойте экономические концепции через практику с нашими интерактивными упражнениями Google Sheets и Python. Решайте задачи прикладной экономической теории с оценкой в реальном времени и мгновенной обратной связью.';

  @override
  String get elasticityExerciseBtn => 'Перейти к упражнению по эластичности';

  @override
  String get comingSoonTitle => 'Скоро:';

  @override
  String get comingSoonSheets => 'Интерактивная интеграция Google Sheets';

  @override
  String get comingSoonEvaluation => 'Оценка ввода в реальном времени';

  @override
  String get comingSoonProgress => 'Отслеживание прогресса';

  @override
  String get comingSoonCourse => 'Управление курсами';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navContent => 'Контент';

  @override
  String get navAccount => 'Аккаунт';

  @override
  String get navSignIn => 'Войти';

  @override
  String get navSignOut => 'Выйти';

  @override
  String get navTheme => 'Тема';

  @override
  String get navLanguage => 'Язык';

  @override
  String get featureInDevelopment => 'Эта функция находится в разработке.';

  @override
  String get signOutSuccess => 'Вы успешно вышли из системы!';

  @override
  String get signOutError => 'Ошибка при выходе из системы';

  @override
  String get switchThemeTooltip => 'Переключить тему (тёмная / светлая)';
}
