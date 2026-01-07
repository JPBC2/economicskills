// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Economic skills';

  @override
  String get homeWelcome => 'Welcome to Economic Skills';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get sheetsExercisesTitle => 'Interactive Google Sheets Exercises';

  @override
  String get sheetsExercisesDesc =>
      'This is where your Google Sheets exercises will be integrated. Students will be able to work on applied economic theory problems with real-time evaluation.';

  @override
  String get elasticityExerciseBtn => 'Go to Elasticity Exercise';

  @override
  String get comingSoonTitle => 'Coming Soon:';

  @override
  String get comingSoonSheets => 'Interactive Google Sheets integration';

  @override
  String get comingSoonEvaluation => 'Real-time input evaluation';

  @override
  String get comingSoonProgress => 'Progress tracking';

  @override
  String get comingSoonCourse => 'Course management';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navContent => 'Content';

  @override
  String get navAccount => 'Account';

  @override
  String get navSignIn => 'Sign In';

  @override
  String get navSignOut => 'Sign Out';

  @override
  String get navTheme => 'Theme';

  @override
  String get navLanguage => 'Language';

  @override
  String get featureInDevelopment => 'This feature is in development.';

  @override
  String get signOutSuccess => 'Successfully signed out!';

  @override
  String get signOutError => 'Error signing out';

  @override
  String get switchThemeTooltip => 'Switch theme (dark / light)';
}
