// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Economic skills';

  @override
  String get homeWelcome => 'Welkom bij Economic Skills';

  @override
  String get changeLanguage => 'Taal wijzigen';

  @override
  String get sheetsExercisesTitle => 'Interactieve Google Sheets Oefeningen';

  @override
  String get sheetsExercisesDesc =>
      'Hier worden uw Google Sheets oefeningen geïntegreerd. Studenten kunnen werken aan toegepaste economische theorieproblemen met real-time evaluatie.';

  @override
  String get elasticityExerciseBtn => 'Ga naar Elasticiteitsoefening';

  @override
  String get comingSoonTitle => 'Binnenkort:';

  @override
  String get comingSoonSheets => 'Interactieve Google Sheets integratie';

  @override
  String get comingSoonEvaluation => 'Real-time invoerevaluatie';

  @override
  String get comingSoonProgress => 'Voortgang bijhouden';

  @override
  String get comingSoonCourse => 'Cursusbeheer';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navContent => 'Inhoud';

  @override
  String get navAccount => 'Account';

  @override
  String get navSignIn => 'Inloggen';

  @override
  String get navSignOut => 'Uitloggen';

  @override
  String get navTheme => 'Thema';

  @override
  String get navLanguage => 'Taal';

  @override
  String get featureInDevelopment => 'Deze functie is in ontwikkeling.';

  @override
  String get signOutSuccess => 'Succesvol uitgelogd!';

  @override
  String get signOutError => 'Fout bij uitloggen';

  @override
  String get switchThemeTooltip => 'Thema wisselen (donker / licht)';
}
