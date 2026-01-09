import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:economicskills/app/view_models/theme_mode.vm.dart';
import 'package:economicskills/app/view_models/locale.vm.dart';
import 'app/routes/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:economicskills/l10n/app_localizations.dart';
import 'package:shared/shared.dart';
import 'package:universal_html/html.dart' as html;

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

  // Handle OAuth callback - check if URL has auth code
  if (kIsWeb) {
    final uri = Uri.parse(html.window.location.href);
    if (uri.queryParameters.containsKey('code')) {
      print('OAuth code detected in URL, session should be established');
      
      // Check for returnTo in localStorage and redirect
      final returnTo = html.window.localStorage['returnTo'];
      if (returnTo != null && returnTo.isNotEmpty) {
        html.window.localStorage.remove('returnTo');
        // Use hash-based routing redirect
        html.window.location.href = '${uri.origin}/#$returnTo';
        return; // Stop execution, page will reload
      }
      
      // Clear the code from URL to avoid issues on refresh
      final cleanUrl = uri.removeFragment().replace(queryParameters: {});
      html.window.history.replaceState(null, '', cleanUrl.toString());
    }
  }

  runApp(ProviderScope(child: MyApp()));
}

// Global Supabase client instance
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final themeModeVM = ref.watch(themeModeProvider);
      final localeVM = ref.watch(localeProvider);

      return AnimatedBuilder(
        animation: Listenable.merge([themeModeVM, localeVM]),
        builder: (context, child) {
          return MaterialApp.router(
            title: 'Economic skills',
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
              Locale('fr'), // French
              Locale('zh'), // Chinese
              Locale('ru'), // Russian
              Locale('pt'), // Portuguese
              Locale('ar'), // Arabic
              Locale('id'), // Indonesian
              Locale('ko'), // Korean
              Locale('ja'), // Japanese
            ],

            // Routing with go_router
            routerConfig: appRouter,
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