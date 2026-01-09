// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Economic skills';

  @override
  String get homeWelcome => 'Economic Skills에 오신 것을 환영합니다';

  @override
  String get changeLanguage => '언어 변경';

  @override
  String get sheetsExercisesTitle => '대화형 연습';

  @override
  String get sheetsExercisesDesc =>
      'Google 스프레드시트와 Python 대화형 연습을 통해 경제 개념을 마스터하세요. 실시간 평가와 즉각적인 피드백으로 응용 경제 이론 문제를 풀어보세요.';

  @override
  String get elasticityExerciseBtn => '탄력성 연습으로 이동';

  @override
  String get comingSoonTitle => '곧 제공:';

  @override
  String get comingSoonSheets => '대화형 Google 스프레드시트 통합';

  @override
  String get comingSoonEvaluation => '실시간 입력 평가';

  @override
  String get comingSoonProgress => '진행 상황 추적';

  @override
  String get comingSoonCourse => '과정 관리';

  @override
  String get navDashboard => '대시보드';

  @override
  String get navContent => '콘텐츠';

  @override
  String get navAccount => '계정';

  @override
  String get navSignIn => '로그인';

  @override
  String get navSignOut => '로그아웃';

  @override
  String get navTheme => '테마';

  @override
  String get navLanguage => '언어';

  @override
  String get featureInDevelopment => '이 기능은 개발 중입니다.';

  @override
  String get signOutSuccess => '성공적으로 로그아웃되었습니다!';

  @override
  String get signOutError => '로그아웃 오류';

  @override
  String get switchThemeTooltip => '테마 전환 (다크 / 라이트)';
}
