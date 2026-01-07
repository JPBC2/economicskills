// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Economic skills';

  @override
  String get homeWelcome => 'Bienvenue à Economic skills';

  @override
  String get changeLanguage => 'Changer de langue';

  @override
  String get sheetsExercisesTitle => 'Exercices interactifs Google Sheets';

  @override
  String get sheetsExercisesDesc =>
      'C\'est ici que vos exercices Google Sheets seront intégrés. Les étudiants pourront travailler sur des problèmes de théorie économique appliquée avec une évaluation en temps réel.';

  @override
  String get elasticityExerciseBtn => 'Aller à l\'exercice d\'élasticité';

  @override
  String get comingSoonTitle => 'Bientôt disponible :';

  @override
  String get comingSoonSheets => 'Intégration interactive de Google Sheets';

  @override
  String get comingSoonEvaluation => 'Évaluation des entrées en temps réel';

  @override
  String get comingSoonProgress => 'Suivi des progrès';

  @override
  String get comingSoonCourse => 'Gestion des cours';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navContent => 'Contenu';

  @override
  String get navAccount => 'Compte';

  @override
  String get navSignIn => 'Se connecter';

  @override
  String get navSignOut => 'Se déconnecter';

  @override
  String get navTheme => 'Thème';

  @override
  String get navLanguage => 'Langue';

  @override
  String get featureInDevelopment =>
      'Cette fonctionnalité est en cours de développement.';

  @override
  String get signOutSuccess => 'Déconnexion réussie !';

  @override
  String get signOutError => 'Erreur lors de la déconnexion';

  @override
  String get switchThemeTooltip => 'Changer de thème (sombre / clair)';
}
