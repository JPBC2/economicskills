import 'package:flutter/material.dart';
import 'package:economicskills/app/view_models/theme_mode.vm.dart';
import 'package:economicskills/app/view_models/locale.vm.dart';
import 'app/routes/app_route_parser.router.dart';
import 'app/routes/router_delegate.router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:economicskills/l10n/app_localizations.dart';
import 'app/config/theme.dart';

// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /* await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );*/

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://pwailhwgnxgfwpgrysao.supabase.co',
    anonKey: 'sb_publishable_irGCGTJdFV9D8iUknklA2g_ZpaevBHG',
  );

  await Hive.initFlutter();

  runApp(ProviderScope(child: MyApp()));
}

// Global Supabase client instance
final supabase = Supabase.instance.client;

final routerDelegate = AppRouterDelegate();

class MyApp extends StatelessWidget {
  final _routeParser = AppRouteInformationParser();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final themeModeVM = ref.watch(themeModeProvider);
      final localeVM = ref.watch(localeProvider);

      return AnimatedBuilder(
        animation: Listenable.merge([themeModeVM, localeVM]),
        builder: (context, child) {
          return MaterialApp.router(
            title: 'Economic Skills',
            debugShowCheckedModeBanner: false,
            
            // Theme Configuration
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeModeVM.themeMode,

            // Localization
            locale: localeVM.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('es'), // Spanish
            ],

            // Routing & SEO
            routerDelegate: routerDelegate,
            routeInformationParser: _routeParser,
            routeInformationProvider: PlatformRouteInformationProvider(
              initialRouteInformation: RouteInformation(
                uri: WidgetsBinding.instance.platformDispatcher.defaultRouteName != '/' 
                  ? Uri.parse(WidgetsBinding.instance.platformDispatcher.defaultRouteName)
                  : Uri.parse('/'),
              ),
            ),
          );
        },
      );
    });
  }
}


// Extension for showing snackbars (useful for authentication feedback)
extension ContextExtension on BuildContext {
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError 
          ? Theme.of(this).colorScheme.error 
          : Theme.of(this).snackBarTheme.backgroundColor,
      ),
    );
  }
}