import 'package:flutter/material.dart';
import 'package:economicskills/app/view_models/theme_mode.vm.dart';
import 'app/routes/app_route_parser.router.dart';
import 'app/routes/router_delegate.router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  /* await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
   );*/
  await Hive.initFlutter();
  runApp(ProviderScope(child: MyApp()));
}

final routerDelegate = AppRouterDelegate();

class MyApp extends StatelessWidget {
  final _routeParser = AppRouteInformationParser();

  MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final themeModeVM = ref.watch(themeModeProvider);
      return AnimatedBuilder(
          animation: themeModeVM,
          builder: (context, child) {
            return MaterialApp.router(
              title: 'Economic skills',
              debugShowCheckedModeBanner: false,

              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: Brightness.light,
                  surface: Colors.white,
                ),
                scaffoldBackgroundColor: Colors.white,
                useMaterial3: true,
              ),



              darkTheme: ThemeData.dark().copyWith(
                primaryColor: Colors.blue,
              ),
              themeMode: themeModeVM.themeMode,
              routerDelegate: routerDelegate,
              routeInformationParser: _routeParser,
            );
          });
    });
  }
}
