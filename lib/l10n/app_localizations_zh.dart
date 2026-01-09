// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Economic skills';

  @override
  String get homeWelcome => '欢迎来到 Economic skills';

  @override
  String get changeLanguage => '更改语言';

  @override
  String get sheetsExercisesTitle => '互动练习';

  @override
  String get sheetsExercisesDesc =>
      '通过我们的Google Sheets和Python互动练习，掌握经济学概念。完成应用经济理论问题，获得实时评估和即时反馈。';

  @override
  String get elasticityExerciseBtn => '前往弹性练习';

  @override
  String get comingSoonTitle => '即将推出：';

  @override
  String get comingSoonSheets => 'Google Sheets 互动集成';

  @override
  String get comingSoonEvaluation => '实时输入评估';

  @override
  String get comingSoonProgress => '进度跟踪';

  @override
  String get comingSoonCourse => '课程管理';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navContent => '内容';

  @override
  String get navAccount => '账户';

  @override
  String get navSignIn => '登录';

  @override
  String get navSignOut => '退出登录';

  @override
  String get navTheme => '主题';

  @override
  String get navLanguage => '语言';

  @override
  String get featureInDevelopment => '此功能正在开发中。';

  @override
  String get signOutSuccess => '成功退出登录！';

  @override
  String get signOutError => '退出登录时出错';

  @override
  String get switchThemeTooltip => '切换主题（深色/浅色）';
}
