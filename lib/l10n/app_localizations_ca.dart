// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class AppLocalizationsCa extends AppLocalizations {
  AppLocalizationsCa([String locale = 'ca']) : super(locale);

  @override
  String get appTitle => 'Economic skills';

  @override
  String get homeWelcome => 'Benvingut a Economic Skills';

  @override
  String get changeLanguage => 'Canvia l\'Idioma';

  @override
  String get sheetsExercisesTitle => 'Exercicis Interactius';

  @override
  String get sheetsExercisesDesc =>
      'Domina els conceptes econòmics a través de la pràctica amb els nostres exercicis interactius de Google Sheets i Python. Treballa en problemes de teoria econòmica aplicada amb avaluació en temps real i retroalimentació instantània.';

  @override
  String get elasticityExerciseBtn => 'Anar a l\'Exercici d\'Elasticitat';

  @override
  String get comingSoonTitle => 'Properament:';

  @override
  String get comingSoonSheets => 'Integració interactiva amb Google Sheets';

  @override
  String get comingSoonEvaluation => 'Avaluació d\'entrades en temps real';

  @override
  String get comingSoonProgress => 'Seguiment del progrés';

  @override
  String get comingSoonCourse => 'Gestió de cursos';

  @override
  String get navDashboard => 'Tauler';

  @override
  String get navContent => 'Contingut';

  @override
  String get navAccount => 'Compte';

  @override
  String get navSignIn => 'Inicia sessió';

  @override
  String get navSignOut => 'Tanca sessió';

  @override
  String get navTheme => 'Tema';

  @override
  String get navLanguage => 'Idioma';

  @override
  String get featureInDevelopment => 'Aquesta funció està en desenvolupament.';

  @override
  String get signOutSuccess => 'Sessió tancada correctament!';

  @override
  String get signOutError => 'Error en tancar la sessió';

  @override
  String get switchThemeTooltip => 'Canvia el tema (fosc / clar)';
}
