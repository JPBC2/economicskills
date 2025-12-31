// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Habilidades Económicas';

  @override
  String get homeWelcome => 'Bienvenido a Habilidades Económicas';

  @override
  String get changeLanguage => 'Cambiar Idioma';

  @override
  String get sheetsExercisesTitle => 'Ejercicios Interactivos de Google Sheets';

  @override
  String get sheetsExercisesDesc =>
      'Aquí es donde se integrarán sus ejercicios de Google Sheets. Los estudiantes podrán trabajar en problemas de teoría económica aplicada con evaluación en tiempo real.';

  @override
  String get elasticityExerciseBtn => 'Ir al Ejercicio de Elasticidad';

  @override
  String get comingSoonTitle => 'Próximamente:';

  @override
  String get comingSoonSheets => 'Integración interactiva de Google Sheets';

  @override
  String get comingSoonEvaluation => 'Evaluación de entrada en tiempo real';

  @override
  String get comingSoonProgress => 'Seguimiento del progreso';

  @override
  String get comingSoonCourse => 'Gestión del curso';

  @override
  String get navContent => 'Contenido';

  @override
  String get navAccount => 'Cuenta';

  @override
  String get navSignIn => 'Iniciar Sesión';

  @override
  String get navSignOut => 'Cerrar Sesión';

  @override
  String get navTheme => 'Tema';

  @override
  String get navLanguage => 'Idioma';

  @override
  String get featureInDevelopment => 'Esta función está en desarrollo.';

  @override
  String get signOutSuccess => '¡Sesión cerrada exitosamente!';

  @override
  String get signOutError => 'Error al cerrar sesión';

  @override
  String get switchThemeTooltip => 'Cambiar tema (claro / oscuro)';
}
