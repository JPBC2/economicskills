// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Economic skills';

  @override
  String get homeWelcome => 'مرحباً بكم في المهارات الاقتصادية';

  @override
  String get changeLanguage => 'تغيير اللغة';

  @override
  String get sheetsExercisesTitle => 'تمارين تفاعلية';

  @override
  String get sheetsExercisesDesc =>
      'أتقن المفاهيم الاقتصادية من خلال الممارسة العملية مع تمارين Google Sheets و Python التفاعلية. اعمل على مسائل النظرية الاقتصادية التطبيقية مع التقييم الفوري والتغذية الراجعة الفورية.';

  @override
  String get elasticityExerciseBtn => 'انتقل إلى تمرين المرونة';

  @override
  String get comingSoonTitle => 'قريباً:';

  @override
  String get comingSoonSheets => 'تكامل جداول بيانات Google التفاعلية';

  @override
  String get comingSoonEvaluation => 'تقييم المدخلات في الوقت الفعلي';

  @override
  String get comingSoonProgress => 'تتبع التقدم';

  @override
  String get comingSoonCourse => 'إدارة الدورات';

  @override
  String get navDashboard => 'لوحة التحكم';

  @override
  String get navContent => 'المحتوى';

  @override
  String get navAccount => 'الحساب';

  @override
  String get navSignIn => 'تسجيل الدخول';

  @override
  String get navSignOut => 'تسجيل الخروج';

  @override
  String get navTheme => 'المظهر';

  @override
  String get navLanguage => 'اللغة';

  @override
  String get featureInDevelopment => 'هذه الميزة قيد التطوير.';

  @override
  String get signOutSuccess => 'تم تسجيل الخروج بنجاح!';

  @override
  String get signOutError => 'خطأ في تسجيل الخروج';

  @override
  String get switchThemeTooltip => 'تبديل المظهر (داكن / فاتح)';
}
