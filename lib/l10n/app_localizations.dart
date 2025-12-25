import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Economic Skills'**
  String get appTitle;

  /// Welcome message on home screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to Economic Skills'**
  String get homeWelcome;

  /// Button text to change language
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @sheetsExercisesTitle.
  ///
  /// In en, this message translates to:
  /// **'Interactive Google Sheets Exercises'**
  String get sheetsExercisesTitle;

  /// No description provided for @sheetsExercisesDesc.
  ///
  /// In en, this message translates to:
  /// **'This is where your Google Sheets exercises will be integrated. Students will be able to work on applied economic theory problems with real-time evaluation.'**
  String get sheetsExercisesDesc;

  /// No description provided for @elasticityExerciseBtn.
  ///
  /// In en, this message translates to:
  /// **'Go to Elasticity Exercise'**
  String get elasticityExerciseBtn;

  /// No description provided for @comingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon:'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonSheets.
  ///
  /// In en, this message translates to:
  /// **'Interactive Google Sheets integration'**
  String get comingSoonSheets;

  /// No description provided for @comingSoonEvaluation.
  ///
  /// In en, this message translates to:
  /// **'Real-time input evaluation'**
  String get comingSoonEvaluation;

  /// No description provided for @comingSoonProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress tracking'**
  String get comingSoonProgress;

  /// No description provided for @comingSoonCourse.
  ///
  /// In en, this message translates to:
  /// **'Course management'**
  String get comingSoonCourse;

  /// No description provided for @navContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get navContent;

  /// No description provided for @navAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// No description provided for @navSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get navSignOut;

  /// No description provided for @navTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get navTheme;

  /// No description provided for @navLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get navLanguage;

  /// No description provided for @featureInDevelopment.
  ///
  /// In en, this message translates to:
  /// **'This feature is in development.'**
  String get featureInDevelopment;

  /// No description provided for @signOutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully signed out!'**
  String get signOutSuccess;

  /// No description provided for @signOutError.
  ///
  /// In en, this message translates to:
  /// **'Error signing out'**
  String get signOutError;

  /// No description provided for @switchThemeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Switch theme (dark / light)'**
  String get switchThemeTooltip;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
