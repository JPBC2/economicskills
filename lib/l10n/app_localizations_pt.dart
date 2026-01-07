// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Economic skills';

  @override
  String get homeWelcome => 'Bem-vindo ao Economic skills';

  @override
  String get changeLanguage => 'Alterar idioma';

  @override
  String get sheetsExercisesTitle => 'Exercícios Interativos do Google Sheets';

  @override
  String get sheetsExercisesDesc =>
      'É aqui que seus exercícios do Google Sheets serão integrados. Os alunos poderão trabalhar em problemas de teoria econômica aplicada com avaliação em tempo real.';

  @override
  String get elasticityExerciseBtn => 'Ir para o Exercício de Elasticidade';

  @override
  String get comingSoonTitle => 'Em breve:';

  @override
  String get comingSoonSheets => 'Integração interativa do Google Sheets';

  @override
  String get comingSoonEvaluation => 'Avaliação de entrada em tempo real';

  @override
  String get comingSoonProgress => 'Acompanhamento do progresso';

  @override
  String get comingSoonCourse => 'Gerenciamento de cursos';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navContent => 'Conteúdo';

  @override
  String get navAccount => 'Conta';

  @override
  String get navSignIn => 'Entrar';

  @override
  String get navSignOut => 'Sair';

  @override
  String get navTheme => 'Tema';

  @override
  String get navLanguage => 'Idioma';

  @override
  String get featureInDevelopment => 'Este recurso está em desenvolvimento.';

  @override
  String get signOutSuccess => 'Você saiu com sucesso!';

  @override
  String get signOutError => 'Erro ao sair';

  @override
  String get switchThemeTooltip => 'Alternar tema (escuro / claro)';
}
