// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get appTitle => 'Economic skills';

  @override
  String get homeWelcome => 'Bine ați venit la Economic Skills';

  @override
  String get changeLanguage => 'Schimbă Limba';

  @override
  String get sheetsExercisesTitle => 'Exerciții Interactive cu Google Sheets';

  @override
  String get sheetsExercisesDesc =>
      'Aici vor fi integrate exercițiile cu Google Sheets. Studenții vor putea lucra la probleme de teorie economică aplicată cu evaluare în timp real.';

  @override
  String get elasticityExerciseBtn => 'Mergi la Exercițiul de Elasticitate';

  @override
  String get comingSoonTitle => 'În curând:';

  @override
  String get comingSoonSheets => 'Integrare interactivă cu Google Sheets';

  @override
  String get comingSoonEvaluation => 'Evaluare a datelor în timp real';

  @override
  String get comingSoonProgress => 'Urmărirea progresului';

  @override
  String get comingSoonCourse => 'Gestionarea cursurilor';

  @override
  String get navDashboard => 'Panou';

  @override
  String get navContent => 'Conținut';

  @override
  String get navAccount => 'Cont';

  @override
  String get navSignIn => 'Autentificare';

  @override
  String get navSignOut => 'Deconectare';

  @override
  String get navTheme => 'Temă';

  @override
  String get navLanguage => 'Limbă';

  @override
  String get featureInDevelopment => 'Această funcție este în dezvoltare.';

  @override
  String get signOutSuccess => 'Deconectare reușită!';

  @override
  String get signOutError => 'Eroare la deconectare';

  @override
  String get switchThemeTooltip => 'Schimbă tema (întuneric / luminos)';
}
