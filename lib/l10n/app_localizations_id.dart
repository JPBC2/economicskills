// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Economic skills';

  @override
  String get homeWelcome => 'Selamat Datang di Economic Skills';

  @override
  String get changeLanguage => 'Ubah Bahasa';

  @override
  String get sheetsExercisesTitle => 'Latihan Interaktif';

  @override
  String get sheetsExercisesDesc =>
      'Kuasai konsep ekonomi melalui praktik langsung dengan latihan interaktif Google Sheets dan Python kami. Kerjakan masalah teori ekonomi terapan dengan evaluasi real-time dan umpan balik instan.';

  @override
  String get elasticityExerciseBtn => 'Pergi ke Latihan Elastisitas';

  @override
  String get comingSoonTitle => 'Segera Hadir:';

  @override
  String get comingSoonSheets => 'Integrasi Google Sheets interaktif';

  @override
  String get comingSoonEvaluation => 'Evaluasi input real-time';

  @override
  String get comingSoonProgress => 'Pelacakan kemajuan';

  @override
  String get comingSoonCourse => 'Manajemen kursus';

  @override
  String get navDashboard => 'Dasbor';

  @override
  String get navContent => 'Konten';

  @override
  String get navAccount => 'Akun';

  @override
  String get navSignIn => 'Masuk';

  @override
  String get navSignOut => 'Keluar';

  @override
  String get navTheme => 'Tema';

  @override
  String get navLanguage => 'Bahasa';

  @override
  String get featureInDevelopment => 'Fitur ini sedang dalam pengembangan.';

  @override
  String get signOutSuccess => 'Berhasil keluar!';

  @override
  String get signOutError => 'Gagal keluar';

  @override
  String get switchThemeTooltip => 'Ganti tema (gelap / terang)';
}
