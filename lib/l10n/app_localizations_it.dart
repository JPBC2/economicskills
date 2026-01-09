// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Economic skills';

  @override
  String get homeWelcome => 'Benvenuto a Economic Skills';

  @override
  String get changeLanguage => 'Cambia Lingua';

  @override
  String get sheetsExercisesTitle => 'Esercizi Interattivi';

  @override
  String get sheetsExercisesDesc =>
      'Padroneggia i concetti economici attraverso la pratica con i nostri esercizi interattivi di Google Sheets e Python. Lavora su problemi di teoria economica applicata con valutazione in tempo reale e feedback istantaneo.';

  @override
  String get elasticityExerciseBtn => 'Vai all\'Esercizio sull\'Elasticità';

  @override
  String get comingSoonTitle => 'Prossimamente:';

  @override
  String get comingSoonSheets => 'Integrazione interattiva con Google Sheets';

  @override
  String get comingSoonEvaluation => 'Valutazione degli input in tempo reale';

  @override
  String get comingSoonProgress => 'Monitoraggio dei progressi';

  @override
  String get comingSoonCourse => 'Gestione dei corsi';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navContent => 'Contenuti';

  @override
  String get navAccount => 'Account';

  @override
  String get navSignIn => 'Accedi';

  @override
  String get navSignOut => 'Esci';

  @override
  String get navTheme => 'Tema';

  @override
  String get navLanguage => 'Lingua';

  @override
  String get featureInDevelopment => 'Questa funzione è in sviluppo.';

  @override
  String get signOutSuccess => 'Disconnessione effettuata con successo!';

  @override
  String get signOutError => 'Errore durante la disconnessione';

  @override
  String get switchThemeTooltip => 'Cambia tema (scuro / chiaro)';
}
